#!/bin/bash
# Build eucalyptus selinux rpm on CentOS/RHEL 7

# config
EUCA_SE_BRANCH="master"
EUCA_SE_REPO="https://github.com/eucalyptus/eucalyptus-selinux.git"
REQUIRE=(
    "git"
    "libselinux-utils"
    "policycoreutils"
    "rpmdevtools" # for spectool
    "selinux-policy-base"
    "selinux-policy-devel"
    "yum-utils"
)
set -ex
RPMBUILD=$(mktemp -td "rpmbuild.XXXXXXXXXX")

# dependencies
yum erase -y 'eucalyptus-*'

yum -y install "${REQUIRE[@]}"

yum -y groupinstall development

# clone repositories
[ ! -d "eucalyptus-selinux" ] || rm -rf "eucalyptus-selinux"
git clone --depth 1 --branch "${EUCA_SE_BRANCH}" "${EUCA_SE_REPO}"

# setup rpmbuild
mkdir -p "${RPMBUILD}/SPECS"
mkdir -p "${RPMBUILD}/SOURCES"

[ ! -f "${RPMBUILD}/SPECS/eucalyptus-selinux.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/eucalyptus-selinux.spec"
ln -fs "$(pwd)/eucalyptus-selinux/eucalyptus-selinux.spec" \
  "${RPMBUILD}/SPECS"

# generate source tars, get commit info
pushd eucalyptus-selinux
EUCA_SE_GIT_SHORT=$(git rev-parse --short HEAD)
EUCA_SE_VERSION=$(spectool -l eucalyptus-selinux.spec | grep -oP 'eucalyptus-selinux-\K[.0-9]*(?=.tar.xz)')
popd
tar -cvJf "${RPMBUILD}/SOURCES/eucalyptus-selinux-${EUCA_SE_VERSION}.tar.xz" \
    --transform "s|^eucalyptus-selinux|eucalyptus-selinux-${EUCA_SE_VERSION}|" \
    --exclude ".git*" \
    --exclude "eucalyptus-selinux.spec" \
    "eucalyptus-selinux"

# build rpms
RPM_VERSION="$(date -u +%Y%m%d)git"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define "dist .${RPM_VERSION}${EUCA_SE_GIT_SHORT}.el7" \
    -ba "${RPMBUILD}/SPECS/eucalyptus-selinux.spec"

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

echo "Build complete"

