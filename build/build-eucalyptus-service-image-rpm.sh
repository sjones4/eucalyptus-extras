#!/bin/bash
# Build eucalyptus service image rpm on CentOS/RHEL 7
#
# Builds using dependency rpms from:
# http://downloads.eucalyptus.com/software/eucalyptus/4.4/rhel/7Server/x86_64/
#
# To build using git snapshot rpms copy to EUCALYPTUS_BUILD_REPO_DIR
# and they will be included in repository.
#
# If building on an instance ensure cpu passthrough is enabled:
#   cat /sys/module/kvm_intel/parameters/nested
#   USE_CPU_PASSTHROUGH="1"

# config
EUCA_IW_BRANCH="maint-0.2"
EUCA_IW_REPO="https://github.com/eucalyptus/eucalyptus-imaging-worker.git"
EUCA_LBS_BRANCH="maint-1.4"
EUCA_LBS_REPO="https://github.com/eucalyptus/load-balancer-servo.git"
EUCA_SIM_BRANCH="maint-3"
EUCA_SIM_REPO="https://github.com/eucalyptus/eucalyptus-service-image"
EUCALYPTUS_MIRROR="http://downloads.eucalyptus.com/software/eucalyptus/4.4/rhel/7/x86_64/"
EUCALYPTUS_BUILD_REPO_DIR="${EUCALYPTUS_BUILD_REPO_DIR:-""}"
EUCALYPTUS_BUILD_REPO_IP=${EUCALYPTUS_BUILD_REPO_IP:-""}
EUCA2OOLS_MIRROR="http://downloads.eucalyptus.com/software/euca2ools/3.3/rhel/7/x86_64/"
REQUIRE=(
    "createrepo"
    "git"
    "httpd"
    "libguestfs-tools-c" # for virt-sparsify virt-sysprep
    "libvirt-daemon-config-network"
    "python-devel"
    "python-setuptools"
    "rpmdevtools" # for spectool
    "systemd"
    "virt-install"
    "yum-utils"
)
set -ex

# dependencies
rm -rf /var/www/eucalyptus-packages.??????????
yum erase -y 'eucalyptus-*' 'load-balancer-servo'

yum -y install "${REQUIRE[@]}"

yum -y groupinstall development

RPMBUILD=${RPMBUILD:-$(mktemp -td "rpmbuild.XXXXXXXXXX")}
if [ -z "${EUCALYPTUS_BUILD_REPO_IP}" ] ; then
  EUCALYPTUS_BUILD_REPO_IP=$(curl "http://169.254.169.254/latest/meta-data/local-ipv4")
  [ ! -z "${EUCALYPTUS_BUILD_REPO_IP}" ] || ( echo "Could not detect ip" && exit 1 )
fi
if [ -z "${EUCALYPTUS_BUILD_REPO_DIR}" ] ; then
  EUCALYPTUS_BUILD_REPO_DIR=$(mktemp -td --tmpdir="/var/www/" "eucalyptus-packages.XXXXXXXXXX")
  chmod 755 "${EUCALYPTUS_BUILD_REPO_DIR}"
fi

# clone repositories
[ ! -d "eucalyptus-imaging-worker" ] || rm -rf "eucalyptus-imaging-worker"
git clone --depth 1 --branch "${EUCA_IW_BRANCH}" "${EUCA_IW_REPO}"

[ ! -d "load-balancer-servo" ] || rm -rf "load-balancer-servo"
git clone --depth 1 --branch "${EUCA_LBS_BRANCH}" "${EUCA_LBS_REPO}"

[ ! -d "eucalyptus-service-image" ] || rm -rf "eucalyptus-service-image"
git clone --depth 1 --branch "${EUCA_SIM_BRANCH}" "${EUCA_SIM_REPO}"

# conf, get commit info
pushd "eucalyptus-imaging-worker"
EUCA_IW_GIT_SHORT=$(git rev-parse --short HEAD)
popd

pushd "load-balancer-servo"
EUCA_LBS_GIT_SHORT=$(git rev-parse --short HEAD)
popd

pushd "eucalyptus-service-image"
EUCA_SIM_GIT_SHORT=$(git rev-parse --short HEAD)
EUCA_SIM_VERSION=$(spectool -l "eucalyptus-service-image.spec" | grep -oP 'eucalyptus-service-image-\K[.0-9]*(?=.tar.xz)')
autoconf
popd

# setup rpmbuild
mkdir -p "${RPMBUILD}/SPECS"
mkdir -p "${RPMBUILD}/SOURCES"

[ ! -f "${RPMBUILD}/SPECS/eucalyptus-imaging-worker.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/eucalyptus-imaging-worker.spec"
ln -fs "$(pwd)/eucalyptus-imaging-worker/eucalyptus-imaging-worker.spec" \
  "${RPMBUILD}/SPECS"

[ ! -f "${RPMBUILD}/SPECS/load-balancer-servo.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/load-balancer-servo.spec"
ln -fs "$(pwd)/load-balancer-servo/load-balancer-servo.spec" \
  "${RPMBUILD}/SPECS"

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
tar -cvJf "${RPMBUILD}/SOURCES/eucalyptus-imaging-worker.tar.xz" \
    --exclude ".git*" \
    --exclude "eucalyptus-imaging-worker.spec" \
    "eucalyptus-imaging-worker"

cp "load-balancer-servo/load-balancer-servo.tmpfiles" "${RPMBUILD}/SOURCES/"
tar -cvJf "${RPMBUILD}/SOURCES/load-balancer-servo.tar.xz" \
    --exclude ".git*" \
    --exclude "load-balancer-servo.spec" \
    "load-balancer-servo"

tar -cvJf "${RPMBUILD}/SOURCES/eucalyptus-service-image-${EUCA_SIM_VERSION}.tar.xz" \
    --transform "s|^eucalyptus-service-image|eucalyptus-service-image-${EUCA_SIM_VERSION}|" \
    --exclude ".git*" \
    --exclude "eucalyptus-service-image.spec" \
    "eucalyptus-service-image"

# build rpms
RPM_VERSION="$(date -u +%Y%m%d)git"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define "tarball_basedir eucalyptus-imaging-worker" \
    --define "dist .${RPM_VERSION}${EUCA_IW_GIT_SHORT}.el7" \
    -ba "${RPMBUILD}/SPECS/eucalyptus-imaging-worker.spec"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define "tarball_basedir load-balancer-servo" \
    --define "dist .${RPM_VERSION}${EUCA_LBS_GIT_SHORT}.el7" \
    -ba "${RPMBUILD}/SPECS/load-balancer-servo.spec"

# build local repository for use in service image build
mkdir -p "${EUCALYPTUS_BUILD_REPO_DIR}"

EUCALYPTUS_BUILD_REPO_YUM_CONF=$(mktemp -t "yum.conf.XXXXXXXXXX")
cat > "${EUCALYPTUS_BUILD_REPO_YUM_CONF}" << HERE
[localeuca]
name=localeuca
baseurl=file://${EUCALYPTUS_BUILD_REPO_DIR}
enabled=1

[mirroreuca]
name=mirroreuca
baseurl=${EUCALYPTUS_MIRROR}
enabled=1
HERE

cp -v "${RPMBUILD}/RPMS"/*/*.rpm "${EUCALYPTUS_BUILD_REPO_DIR}"

createrepo "${EUCALYPTUS_BUILD_REPO_DIR}"

yumdownloader \
  --assumeyes \
  --resolve \
  --config="${EUCALYPTUS_BUILD_REPO_YUM_CONF}" \
  --exclude=euca2ools \
  --destdir "${EUCALYPTUS_BUILD_REPO_DIR}" \
  eucalyptus-imaging-worker load-balancer-servo ec2-net-utils

rm -rf "${EUCALYPTUS_BUILD_REPO_DIR}/repodata"
yum \
  --config="${EUCALYPTUS_BUILD_REPO_YUM_CONF}" \
  --disablerepo=* \
  --enablerepo=localeuca \
  clean all

createrepo "${EUCALYPTUS_BUILD_REPO_DIR}"

cat > "/etc/httpd/conf.d/eucalyptus-local-packages.conf" << HERE
Alias /eucalyptus-local-packages "${EUCALYPTUS_BUILD_REPO_DIR}"

<Directory "${EUCALYPTUS_BUILD_REPO_DIR}">
    SetEnv VIRTUALENV
    Options MultiViews Indexes
    Order allow,deny
    Allow from all
</Directory>

HERE

systemctl restart httpd

echo "EUCALYPTUS_MIRROR=http://${EUCALYPTUS_BUILD_REPO_IP}/eucalyptus-local-packages/"

systemctl start libvirtd

chmod 770 "${RPMBUILD}"
chgrp qemu "${RPMBUILD}"
export DISK=2       # override make defined DISK=2
export MEMORY=2048  # override make defined MEMORY=1024
export EUCA_SIM_CONFIGURE_OPTS="
  --with-eucalyptus-mirror=http://${EUCALYPTUS_BUILD_REPO_IP}/eucalyptus-local-packages/
  --with-euca2ools-mirror=${EUCA2OOLS_MIRROR}
"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define "dist .${RPM_VERSION}${EUCA_SIM_GIT_SHORT}.el7" \
    --define "configure_opts ${EUCA_SIM_CONFIGURE_OPTS//$'\n'/ }" \
    -ba "${RPMBUILD}/SPECS/eucalyptus-service-image.spec"

systemctl stop libvirtd

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

if [ ! -z "${RPM_OUT}" ] && [ -d "${RPM_OUT}" ] ; then
    cp -pv "${RPMBUILD}/RPMS"/*/*.rpm "${RPM_OUT}"
fi

echo "Build complete"

