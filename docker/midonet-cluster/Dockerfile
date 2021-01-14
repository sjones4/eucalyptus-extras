FROM docker.io/centos:7.9.2009

ADD [ "files", "/" ]

RUN yum install --assumeyes epel-release java-1.8.0-openjdk-headless \
 && yum install --assumeyes midonet-cluster midonet-tools python-midonetclient which \
 && yum clean all \
 && sed --in-place 's/^HEAP_NEWSIZE=/# HEAP_NEWSIZE=/' /etc/midonet-cluster/midonet-cluster-env.sh \
 && sed --in-place 's/^MAX_HEAP_SIZE=/# MAX_HEAP_SIZE=/' /etc/midonet-cluster/midonet-cluster-env.sh

EXPOSE 8181

ENV AGENT_LOG_LEVEL="INFO" \
    CASSANDRA_ENDPOINTS="127.0.0.1" \
    CASSANDRA_FACTOR="3" \
    ZK_ENDPOINTS="127.0.0.1:2181" \
    UUID=""

VOLUME /var/log/midonet-cluster

CMD ["/usr/local/bin/midonet-cluster"]
