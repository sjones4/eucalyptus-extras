FROM centos:7

RUN yum -y install epel-release \
 && yum -y install gcc make patch git python-devel python2-pip libffi-devel openssl-devel libyaml-devel \
 && pip install --upgrade pip setuptools \
 && easy_install pbr \
 && yum -y install https://packages.chef.io/files/stable/chefdk/0.12.0/el/7/chefdk-0.12.0-1.el7.x86_64.rpm \
 && cd /root \
 && git clone --depth 1 https://github.com/eucalyptus/calyptos \
 && cd calyptos \
 && python setup.py install \
 && mkdir /calyptos \
 && cd /calyptos \
 && git clone --depth 1 --branch euca-4.4 https://github.com/eucalyptus/eucalyptus-cookbook \
 && berks install --berksfile /calyptos/eucalyptus-cookbook/Berksfile \
 && rm -rf /root/calyptos /root/.cache \
 && pip uninstall -y setuptools pip \
 && /opt/chefdk/embedded/bin/gem uninstall -a dep_selector \
 && /opt/chefdk/embedded/bin/gem uninstall -a dep-selector-libgecode \
 && yum -y erase gcc make patch python-devel python-setuptools openssl-devel libyaml-devel *-headers \
 && yum -y clean all

ENV PATH=/calyptos/bin:$PATH

ADD [ "calyptos", "host-*.sh", "template-*.sh", "/calyptos/bin/" ]
ADD [ "templates", "/calyptos/templates/" ]

RUN chown --recursive root:root /calyptos \
 && chmod 755 /calyptos/bin/*

WORKDIR /calyptos
