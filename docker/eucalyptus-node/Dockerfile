FROM docker.io/centos:7.9.2009

ADD [ "files", "/" ]

RUN yum install --assumeyes epel-release gettext which \
 && yum install --assumeyes eucalyptus-nc \
 && yum clean all

EXPOSE 8775

ENV LOGLEVEL="INFO" \
    VNET_BRIDGE="br0"

VOLUME /var/lib/eucalyptus/instances
VOLUME /var/lib/eucalyptus/keys
VOLUME /var/log/eucalyptus

CMD ["/usr/local/bin/eucalyptus-node"]
