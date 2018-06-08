FROM sjones4/euca2ools:3.4

ENV PATH=/root/bin:$PATH

ADD [ "bin", "/root/bin/" ]
ADD [ "templates", "/root/templates/" ]

RUN curl -s https://raw.githubusercontent.com/sjones4/euca2ools/topic-getimpersonationtoken/bin/euare-getimpersonationtoken \
    > /usr/bin/euare-getimpersonationtoken \
 && chmod 755 /usr/bin/euare-getimpersonationtoken \
 && curl -s https://raw.githubusercontent.com/sjones4/euca2ools/topic-getimpersonationtoken/euca2ools/commands/sts/getimpersonationtoken.py \
    > /usr/lib/python2.7/site-packages/euca2ools/commands/sts/getimpersonationtoken.py \
 && python -m compileall /usr/lib/python2.7/site-packages/euca2ools/commands/sts/getimpersonationtoken.py \
 && python -O -m compileall /usr/lib/python2.7/site-packages/euca2ools/commands/sts/getimpersonationtoken.py \
 && chown --recursive root:root /root/bin/* \
 && chmod 755 /root/bin/*

WORKDIR /root/templates
