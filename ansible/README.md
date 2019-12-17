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

Tags can be used to control which aspects of the playbook are used:

* `image` : `packages` and generic configuration
* `packages` : installs yum repositories and rpms

Example tag use:

```
ansible-playbook --tags      image -i inventory.yml playbook.yml
ansible-playbook --skip-tags image -i inventory.yml playbook.yml
```

which would run the playbook in two parts, the first installing packages
and non-deployment specific configuration, and the second completing the
deployment.
