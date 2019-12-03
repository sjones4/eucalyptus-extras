# Ansible playbook for Eucalyptus Cloud deployment

Create an inventory for your environment:

```
cp inventory_example.yml inventory.yml
vi inventoy.yml
```

to install with EDGE network mode:

```
ansible-playbook -i inventory.yml playbook[_edge].yml
```

to install with VPCMIDO network mode:

```
ansible-playbook -i inventory.yml playbook_vpcmido.yml
```

to remove a eucalyptus installation and main dependencies:

```
ansible-playbook -i inventory.yml playbook_clean.yml
```
