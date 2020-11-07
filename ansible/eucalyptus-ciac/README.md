# Ansible playbook for Eucalyptus cloud in a container deployment

Deploy a Eucalyptus cloud in a container using podman (podalyptus):

```
ansible-playbook \
  --extra-vars eucalyptus_public_interface=en1 \
  --extra-vars eucalyptus_public_ip_cidr=1.2.3.0/24 \
  --extra-vars eucalyptus_public_ip_range=1.2.3.20-1.2.3.220 \
  --inventory inventory.yml \
  playbook.yml
```

The extra variables are required to route traffic to cloud instances.

The public IP address range must fall within the given CIDR. The public IP address CIDR must be from a network on the given interface.
