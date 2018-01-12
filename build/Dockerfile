FROM centos:7

ADD [ "build-*.sh", "rpm-*.sh", "/root/bin/" ]

ENV PATH=/root/bin:$PATH \
    RPM_OUT="/eucalyptus/rpms"

RUN chown --recursive root:root /root/bin/*.sh \
 && chmod 755 /root/bin/*.sh \
 && mkdir --parents /eucalyptus \
 && chown --recursive root:root /eucalyptus \
 && build-all-rpms-44.sh setupenv \
 && build-eucalyptus-cloud-libs-rpm.sh setup \
 && build-eucalyptus-rpms.sh setup \
 && build-eucalyptus-selinux-rpm.sh setup \
 && build-eucalyptus-console-rpm.sh setup \
 && build-eucalyptus-console-selinux-rpm.sh setup \
 && yum -y install curl gnupg2 rpm-sign which yajl \
 && yum -y clean all

VOLUME /eucalyptus
WORKDIR /eucalyptus

