FROM alpine:3.7

RUN apk add --no-cache curl

ENV PATH=/root/bin:$PATH

ADD [ "mc", "/root/bin/" ]

RUN chown --recursive root:root /root/bin/* \
 && chmod 755 /root/bin/*

