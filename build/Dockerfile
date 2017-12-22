FROM centos:7

ADD [ "build-*.sh", "/root/bin/" ]

RUN chown --recursive root:root /root/bin/*.sh \
 && chmod 755 /root/bin/*.sh \
 && mkdir --parents /eucalyptus \
 && chown --recursive root:root /eucalyptus \
 && /root/bin/build-eucalyptus-cloud-libs-rpm.sh setup \
 && /root/bin/build-eucalyptus-rpms.sh setup \
 && /root/bin/build-eucalyptus-selinux-rpm.sh setup \
 && yum -y clean all \
 && rm -rf /var/cache/yum

ENV PATH=/root/bin:$PATH \
    RPM_OUT="/eucalyptus/rpms"
WORKDIR /eucalyptus
VOLUME /eucalyptus

