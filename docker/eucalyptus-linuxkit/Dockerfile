FROM registry.fedoraproject.org/fedora:29

ENV PATH=$PATH:/root/go/bin

RUN dnf install --assumeyes docker golang \
 && dnf clean all \
 && go get github.com/linuxkit/linuxkit/src/cmd/linuxkit

