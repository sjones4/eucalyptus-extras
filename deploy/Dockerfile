FROM centos:7

RUN yum -y install epel-release \
 && yum -y install gcc git libffi-devel libyaml-devel make openssl-devel patch python2-pip python-devel \
 && pip install --upgrade pip setuptools \
 && easy_install pbr \
 && yum -y install https://packages.chef.io/files/stable/chefdk/2.5.3/el/7/chefdk-2.5.3-1.el7.x86_64.rpm \
 && cd /root \
 && git clone --depth 1 https://github.com/sjones4/calyptos \
 && cd calyptos \
 && python setup.py install \
 && mkdir /calyptos \
 && cd /calyptos \
 && git clone --depth 1 https://github.com/corymbia/eucalyptus-cookbook.git \
 && sed --in-place '2isolver :ruby' /calyptos/eucalyptus-cookbook/Berksfile \
 && berks install --berksfile /calyptos/eucalyptus-cookbook/Berksfile \
 && rm -rf /root/calyptos /root/.cache \
 && pip uninstall -y setuptools pip \
 && yum -y erase gcc keyutils-libs-develkrb5-devel libcom_err-devel libselinux-devel libsepol-devel libverto-devel libyaml-devel make openssl-devel patch python-devel python-setuptools zlib-devel *-headers \
 && yum -y clean all \
 && rm -rf /var/tmp/* /var/cache/yum/*

ENV PATH=/calyptos/bin:$PATH

ADD [ "calyptos", "host-*.sh", "template-*.sh", "/calyptos/bin/" ]
ADD [ "templates", "/calyptos/templates/" ]

RUN chown --recursive root:root /calyptos \
 && chmod 755 /calyptos/bin/*

WORKDIR /calyptos

