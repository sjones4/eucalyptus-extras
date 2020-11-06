FROM centos:7.8.2003

COPY eucalyptus-setup.service /etc/systemd/system/
COPY inventory.yml /root/

RUN yum install --assumeyes --disablerepo=updates* epel-release https://downloads.eucalyptus.cloud/software/eucalyptus/master/rhel/7/x86_64/eucalyptus-release-5-1.15.as.el7.noarch.rpm \
 && yum install --assumeyes --disablerepo=updates* eucalyptus-ansible \
 && ansible-playbook --tags image --skip-tags selinux --inventory /root/inventory.yml /usr/share/eucalyptus-ansible/playbook_vpcmido.yml \
 && systemctl enable eucalyptus-setup.service \
 && yum clean all

EXPOSE 443/tcp
EXPOSE 53/tcp
EXPOSE 53/udp

CMD [ "/sbin/init" ]
