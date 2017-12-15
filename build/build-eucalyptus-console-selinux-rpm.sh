#!/bin/bash
# Build eucalyptus console selinux rpm on CentOS/RHEL 7

# config
EUCA_CON_SE_BRANCH="master"
EUCA_CON_SE_REPO="https://github.com/eucalyptus/eucaconsole-selinux.git"
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
yum erase -y 'eucaconsole-*'

yum -y install "${REQUIRE[@]}"

yum -y groupinstall development

# clone repositories
[ ! -d "eucaconsole-selinux" ] || rm -rf "eucaconsole-selinux"
git clone --depth 1 --branch "${EUCA_CON_SE_BRANCH}" "${EUCA_CON_SE_REPO}"

# setup rpmbuild
mkdir -p "${RPMBUILD}/SPECS"
mkdir -p "${RPMBUILD}/SOURCES"

[ ! -f "${RPMBUILD}/SPECS/eucaconsole-selinux.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/eucaconsole-selinux.spec"
ln -fs "$(pwd)/eucaconsole-selinux/eucaconsole-selinux.spec" \
  "${RPMBUILD}/SPECS"

# generate source tars, get commit info
pushd "eucaconsole-selinux"
EUCA_CON_SE_GIT_SHORT=$(git rev-parse --short HEAD)
EUCA_CON_SE_VERSION=$(spectool -l "eucaconsole-selinux.spec" | grep -oP 'eucaconsole-selinux-\K[.0-9]*(?=.tar.xz)')
popd
tar -cvJf "${RPMBUILD}/SOURCES/eucaconsole-selinux-${EUCA_CON_SE_VERSION}.tar.xz" \
    --transform "s|^eucaconsole-selinux|eucaconsole-selinux-${EUCA_CON_SE_VERSION}|" \
    --exclude ".git*" \
    --exclude "eucaconsole-selinux.spec" \
    "eucaconsole-selinux"

# build rpms
RPM_VERSION="$(date -u +%Y%m%d)git"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define "dist .${RPM_VERSION}${EUCA_CON_SE_GIT_SHORT}.el7" \
    -ba "${RPMBUILD}/SPECS/eucaconsole-selinux.spec"

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

echo "Build complete"

