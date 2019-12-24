FROM centos:7.7.1908

RUN yum install -y ansible openssh-clients \
 && yum clean all

ADD ["*.yml", "/eucalyptus/"]
ADD ["roles", "/eucalyptus/roles/"]

WORKDIR /eucalyptus

CMD ["/usr/bin/ansible-playbook"]
