# Eucalyptus cloud in a container

Eucalyptus container for podman in systemd mode.

Host Setup
----------
Enable podman systemd mode:

```
# setsebool -P container_manage_cgroup true
```

Load the kernel modules required by Eucalyptus:

```
# modprobe openvswitch
# modprobe br_netfilter
```

Enable shared memory for Eucalyptus postgres and network traffic for Eucalyptus instances:

```
# sysctl kernel.sem="250 32000 32 1536"
#
# sysctl net.ipv4.conf.INTERFACE.proxy_arp=1
# sysctl net.ipv4.conf.INTERFACE.forwarding=1
```

`INTERFACE` must be replaced with the public interface of the host, such as `en1`.

Container Configuration
-----------------------
Required configuration items for Eucalyptus:

```
# cat /etc/sysconfig/eucalyptus
EUCALYPTUS_POD_NETNS=cni-82839f3e-0066-4b71-837a-4ae9820896fd
EUCALYPTUS_PUBLIC_INTERFACE=en1
EUCALYPTUS_PUBLIC_IP_CIDR=192.168.169.0/24
EUCALYPTUS_PUBLIC_IP_RANGE=192.168.169.16-192.168.169.216
```

The `EUCALYPTUS_POD_NETNS` can be found using `ip netns list` when the container is running.

The `EUCALYPTUS_PUBLIC_INTERFACE` must be the one with forwarding and arp proxy enabled.

Container Launch
----------------
Create the Eucalytpus container with published ports for dns and https:

```
# podman create \
    --name podalyptus \
    --detach \
    --privileged \
    --publish 443 --publish 53 \
    --sysctl kernel.sem="250 32000 32 1536" \
    --mount type=tmpfs,destination=/tmp,exec \
    --volume /etc/sysconfig/eucalyptus:/etc/sysconfig/eucalyptus \
    --volume /dev:/dev \
    docker.io/sjones4/eucalyptus-ciac:5
```

You can run the container as a systemd service:

```
# podman generate systemd --files --name podalyptus
# cp container-podalyptus.service /etc/systemd/system/podalyptus.service
# systemctl daemon-reload
# systemctl start podalyptus.service
```

Or can run it directly:

```
# podman start podalyptus
```

To monitor the cloud on first start of the container use:

```
# podman exec -it podalyptus journalctl -fu eucalyptus-setup.service
```

Cloud Gateway
-------------
A veth pair is required to connect the host network to the container for instance traffic.

```
# cat /etc/systemd/system/eucalyptus-gateway.service
[Unit]
Description=Eucalyptus Network Gateway
After=network.target

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/eucalyptus
ExecStartPre=-/usr/sbin/ip link add euca-mgw-veth0 type veth peer name euca-mgw-veth1 netns ${EUCALYPTUS_POD_NETNS}
ExecStartPre=-/usr/sbin/ip link set dev euca-mgw-veth0 up
ExecStartPre=-/usr/sbin/ip netns exec ${EUCALYPTUS_POD_NETNS} ip link set dev euca-mgw-veth1 up
ExecStartPre=-/usr/sbin/ip addr add 10.234.234.234/27 dev euca-mgw-veth0
ExecStartPre=-/usr/sbin/ip route add ${EUCALYPTUS_PUBLIC_IP_CIDR} via 10.234.234.235 dev euca-mgw-veth0
ExecStart=/usr/bin/true

[Install]
WantedBy=multi-user.target
```

This systemd service file uses the previously created configuration. To create the gateway run:

```
# systemctl start eucalyptus-gateway.service
```

The gateway should be started after the container is running and after the namespace has been configured in `/etc/sysconfig/eucalyptus`.

Cloud Client
------------
The AWS CLI can be used as a client to access the cloud, to install:

```
# yum install http://downloads.eucalyptus.cloud/software/eucalyptus/master/rhel/7/x86_64/eucalyptus-release-5-1.15.as.el7.noarch.rpm
# yum install eucalyptus-awscli-plugin
```

To configure the client, copy the configuration files from the container:

```
# podman exec -it podalyptus cat /root/.aws/config
# podman exec -it podalyptus cat /root/.aws/credentials
```

To check setup, list regions:

```
# aws ec2 describe-regions
```

Cloud Management Console
------------------------
Since the container cloud does not have dns delegation you have to query for the console ip:

```
# dig +short console.cloud-10-88-0-9.euca.me @10.88.0.9
```

the name and dns server to use are obtained for the container. You can then create a password:

```
# aws iam create-login-profile --user-name admin --password MYPASSWORD
```

and access the console at `https://CONSOLE_IP/` as account `eucalyptus` user `admin`.

