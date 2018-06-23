FROM centos:7

RUN yum --assumeyes --disablerepo=updates* install ruby git \
 && yum --assumeyes --disablerepo=updates* install https://packages.chef.io/files/stable/chefdk/2.5.3/el/7/chefdk-2.5.3-1.el7.x86_64.rpm \
 && yum --assumeyes --disablerepo=updates* clean all \
 && rm -rf /var/tmp/*

