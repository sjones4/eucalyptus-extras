FROM docker.io/centos:7.9.2009

ADD [ "files", "/" ]

RUN yum install --assumeyes java-1.8.0-openjdk-headless midolman \
 && yum clean all \
 && sed --in-place 's/^MAX_HEAP_SIZE=/# MAX_HEAP_SIZE=/' /etc/midolman/midolman-env.sh \
 && ln --symbolic --force /dev/stdout /var/log/midolman/upstart-stderr.log

ENV ZK_ENDPOINTS="127.0.0.1:2181" \
    UUID=""

VOLUME /var/log/midolman

CMD ["/usr/local/bin/midonet-agent"]
