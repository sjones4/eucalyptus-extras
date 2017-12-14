#!/bin/bash
# Build eucalyptus service image rpm on CentOS/RHEL 7
#
# Builds using rpms from:
# http://downloads.eucalyptus.com/software/eucalyptus/4.4/rhel/7Server/x86_64/
#
# If building on an instance ensure cpu passthrough is enabled:
#   cat /sys/module/kvm_intel/parameters/nested
#   USE_CPU_PASSTHROUGH="1"

# config
EUCA_SIM_BRANCH="maint-3"
EUCA_SIM_REPO="https://github.com/eucalyptus/eucalyptus-service-image"
REQUIRE=(
    "git"
    "libguestfs-tools-c" # for virt-sparsify virt-sysprep
    "libvirt-daemon-config-network"
    "python-devel"
    "rpmdevtools" # for spectool
    "virt-install"
    "yum-utils"
)
set -ex
RPMBUILD=$(mktemp -td "rpmbuild.XXXXXXXXXX")

# dependencies
yum erase -y 'eucalyptus-*'

yum -y install "${REQUIRE[@]}"

yum -y groupinstall development

# clone repositories
[ ! -d "eucalyptus-service-image" ] || rm -rf "eucalyptus-service-image"
git clone --depth 1 --branch "${EUCA_SIM_BRANCH}" "${EUCA_SIM_REPO}"

# conf, get commit info
pushd eucalyptus-service-image
EUCA_SIM_GIT_SHORT=$(git rev-parse --short HEAD)
EUCA_SIM_VERSION=$(spectool -l "eucalyptus-service-image.spec" | grep -oP 'eucalyptus-service-image-\K[.0-9]*(?=.tar.xz)')
autoconf
popd

# setup rpmbuild
mkdir -p "${RPMBUILD}/SPECS"
mkdir -p "${RPMBUILD}/SOURCES"
[ ! -d "${RPMBUILD}/RPMS" ] || rm -rf "${RPMBUILD}/RPMS"
[ ! -d "${RPMBUILD}/SRPMS" ] || rm -rf "${RPMBUILD}/SRPMS"

[ ! -f "${RPMBUILD}/SPECS/eucalyptus-service-image.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/eucalyptus-service-image.spec"
ln -fs "$(pwd)/eucalyptus-service-image/eucalyptus-service-image.spec" \
  "${RPMBUILD}/SPECS"

# update kickstart create for service package repository as 
# eucalyptus-service-image-release.rpm is not available
head -n -3 "eucalyptus-service-image/eucalyptus-service-image.ks.in" | \
  grep -v eucalyptus-service-image-release > \
  "eucalyptus-service-image/eucalyptus-service-image.ks.in.new"
cat >> "eucalyptus-service-image/eucalyptus-service-image.ks.in.new" << HERE

# Configure service packages repository
cat > /etc/yum.repos.d/eucalyptus-service-image.repo << EOF
[eucalyptus-service-image]
name=Eucalyptus Service Image Packages - $basearch
baseurl=file:///var/lib/eucalyptus-service-image/packages
enabled=1
gpgcheck=0
skip_if_unavailable=1
EOF
HERE
tail -n 3 "eucalyptus-service-image/eucalyptus-service-image.ks.in" >> \
  "eucalyptus-service-image/eucalyptus-service-image.ks.in.new"
mv -f "eucalyptus-service-image/eucalyptus-service-image.ks.in.new" \
  "eucalyptus-service-image/eucalyptus-service-image.ks.in"

# generate source tars
tar -cvJf "${RPMBUILD}/SOURCES/eucalyptus-service-image-${EUCA_SIM_VERSION}.tar.xz" \
    --transform "s|^eucalyptus-service-image|eucalyptus-service-image-${EUCA_SIM_VERSION}|" \
    --exclude ".git*" \
    --exclude "eucalyptus-service-image.spec" \
    "eucalyptus-service-image"

# build rpms
RPM_VERSION="$(date -u +%Y%m%d)git"

systemctl start libvirtd

chmod 770 "${RPMBUILD}"
chgrp qemu "${RPMBUILD}"
export DISK=2       # override make defined DISK=2
export MEMORY=2048  # override make defined MEMORY=1024
rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define "dist .${RPM_VERSION}${EUCA_SIM_GIT_SHORT}.el7" \
    -ba "${RPMBUILD}/SPECS/eucalyptus-service-image.spec"

systemctl stop libvirtd

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

echo "Build complete"

