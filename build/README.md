# Eucalyptus Build Utilities

Environment
------
These build scripts are intended for use with the CentOS 7 image:

```
http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.raw.tar.gz
```

which can be installed using the installer / catalog from this repository.

The build scripts should be run as root.

To build the service image you will want to ensure nested virtualization is enabled:

```
# cat /sys/module/kvm_intel/parameters/nested
Y
```

if not, then to enable you may need to set:

```
# cat /etc/modprobe.d/kvm-nested.conf
options kvm_intel nested=1
```

and enable **_/etc/eucalyptus/eucalyptus.conf_** on the node controllers:

```
USE_CPU_PASSTHROUGH="1"
```

the build for the service image will be slow without nested virtualization.

Build Scripts
------
To build rpms for the latest code in 4.4 branches run:

```
./build-all-rpms-44.sh
```

This will create something like the following in the **_rpms_** directory:

```
# ls -l rpms
total 490936
-rw-r--r--. 1 root root   3895456 Dec 15 10:45 eucaconsole-4.4.2-0.20171215git089ebbb.el7.noarch.rpm
-rw-r--r--. 1 root root     14688 Dec 15 10:47 eucaconsole-selinux-0.1.3-1.20171215giteb823a2.el7.noarch.rpm
-rw-r--r--. 1 root root     99480 Dec 15 11:08 eucalyptus-4.4.2-0.20171215gitcdaadcc.el7.x86_64.rpm
-rw-r--r--. 1 root root     96512 Dec 15 11:09 eucalyptus-admin-tools-4.4.2-0.20171215gitcdaadcc.el7.noarch.rpm
-rw-r--r--. 1 root root    113912 Dec 15 11:08 eucalyptus-axis2c-common-4.4.2-0.20171215gitcdaadcc.el7.x86_64.rpm
-rw-r--r--. 1 root root     31200 Dec 15 11:08 eucalyptus-blockdev-utils-4.4.2-0.20171215gitcdaadcc.el7.x86_64.rpm
-rw-r--r--. 1 root root   2047472 Dec 15 11:09 eucalyptus-cc-4.4.2-0.20171215gitcdaadcc.el7.x86_64.rpm
-rw-r--r--. 1 root root     30960 Dec 15 11:09 eucalyptus-cloud-4.4.2-0.20171215gitcdaadcc.el7.x86_64.rpm
-rw-r--r--. 1 root root     72820 Dec 15 11:08 eucalyptus-common-java-4.4.2-0.20171215gitcdaadcc.el7.x86_64.rpm
-rw-r--r--. 1 root root  13587836 Dec 15 11:09 eucalyptus-common-java-libs-4.4.2-0.20171215gitcdaadcc.el7.x86_64.rpm
-rw-r--r--. 1 root root   9687508 Dec 15 11:09 eucalyptus-debuginfo-4.4.2-0.20171215gitcdaadcc.el7.x86_64.rpm
-rw-r--r--. 1 root root     52768 Dec 15 11:09 eucalyptus-imaging-toolkit-4.4.2-0.20171215gitcdaadcc.el7.x86_64.rpm
-rw-r--r--. 1 root root     43400 Dec 15 11:10 eucalyptus-imaging-worker-0.2.2-0.20171215git24c0324.el7.noarch.rpm
-rw-r--r--. 1 root root  61491232 Dec 15 10:56 eucalyptus-java-deps-4.4-0.20171215git4378667.el7.noarch.rpm
-rw-r--r--. 1 root root    894548 Dec 15 11:09 eucalyptus-nc-4.4.2-0.20171215gitcdaadcc.el7.x86_64.rpm
-rw-r--r--. 1 root root     24128 Dec 15 11:09 eucalyptus-sc-4.4.2-0.20171215gitcdaadcc.el7.x86_64.rpm
-rw-r--r--. 1 root root     23504 Dec 15 11:09 eucalyptus-selinux-0.2.3-1.20171215git79af2dc.el7.noarch.rpm
-rw-r--r--. 1 root root 409998004 Dec 15 11:43 eucalyptus-service-image-3-0.20171215gitae1d2e4.el7.noarch.rpm
-rw-r--r--. 1 root root     30116 Dec 15 11:43 eucalyptus-sos-plugins-0.5.1-0.20171215git27ae229.el7.noarch.rpm
-rw-r--r--. 1 root root     20300 Dec 15 11:09 eucalyptus-walrus-4.4.2-0.20171215gitcdaadcc.el7.x86_64.rpm
-rw-r--r--. 1 root root    336300 Dec 15 11:09 eucanetd-4.4.2-0.20171215gitcdaadcc.el7.x86_64.rpm
-rw-r--r--. 1 root root     84004 Dec 15 11:10 load-balancer-servo-1.4.1-0.20171215git1ddf676.el7.noarch.rpm
```


