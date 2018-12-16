FROM fedora:29

WORKDIR /root

RUN dnf install --assumeyes golang \
 && go get github.com/linuxkit/linuxkit/src/cmd/linuxkit \
 && curl https://download.docker.com/linux/static/stable/x86_64/docker-18.09.0.tgz | tar xzf - --strip-components=1 docker/docker

FROM fedora:29

COPY --from=0 /root/go/bin/linuxkit /usr/local/bin/
COPY --from=0 /root/docker /usr/local/bin/

