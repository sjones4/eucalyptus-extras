FROM registry.fedoraproject.org/fedora:29

EXPOSE 8888

RUN dnf install --assumeyes https://downloads.eucalyptus.cloud/software/eucalyptus/snapshot/4.4/fedora/29/x86_64/eucalyptus-release-4.4-2.12.as.fc29.noarch.rpm \
 && dnf install --assumeyes eucaconsole \
 && rpm --install --verbose --nodeps http://dl.fedoraproject.org/pub/fedora/linux/releases/29/Everything/x86_64/os/Packages/p/pycryptopp-0.6.0.1206569328141510525648634803928199668821045408958-15.fc29.x86_64.rpm \
 && rpm --erase --verbose selinux-policy selinux-policy-minimum checkpolicy python3-policycoreutils policycoreutils-python-utils \
 && rpm --erase --verbose --nodeps libselinux-utils policycoreutils eucaconsole-selinux nginx nginx-filesystem nginx-filesystem nginx-mimetypes \
 && dnf clean all \
 && rm -frv /var/log/anaconda  /var/log/dnf*

COPY etc/console*.ini /etc/eucaconsole/

