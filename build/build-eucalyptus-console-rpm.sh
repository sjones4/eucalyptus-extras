#!/bin/bash
# Build eucaconsole rpm on CentOS/RHEL 7

# config
VERSION="4.4"
EUCA_CON_BRANCH="maint-${VERSION}"
EUCA_CON_REPO="https://github.com/eucalyptus/eucaconsole.git"
EUCA_CON_RPM_BRANCH="maint-${VERSION}"
EUCA_CON_RPM_REPO="https://github.com/eucalyptus/eucaconsole-rpmspec.git"
REQUIRE=(
    "git"
    "yum-utils"
    "wget"
    "m2crypto"
    "openssl-devel"
    "pycryptopp"
    "python-chameleon"
    "python-dateutil"
    "python-devel"
    "python-eventlet"
    "python-greenlet"
    "python-gunicorn"
    "python-lxml"
    "python-nose"
    "python-pygments"
    "python-pyramid"
    "python-simplejson"
    "python-wtforms"
    "python2-boto"
    "rpmdevtools" # for spectool
)
REQUIRE_EUCA=(
    "http://downloads.eucalyptus.com/software/eucalyptus/4.4/rhel/7Server/x86_64/python-pylibmc-1.2.3-6.1.el7.x86_64.rpm"
    "http://downloads.eucalyptus.com/software/eucalyptus/4.4/rhel/7Server/x86_64/python-pylibmc-debuginfo-1.2.3-6.1.el7.x86_64.rpm"
)
set -ex
RPMBUILD=$(mktemp -td "rpmbuild.XXXXXXXXXX")

# dependencies
yum erase -y 'eucaconsole-*'

yum install -y "epel-release"

yum -y install "${REQUIRE[@]}"

yum -y groupinstall "development"

yum -y install "${REQUIRE_EUCA[@]}" || yum -y upgrade "${REQUIRE_EUCA[@]}"

# clone repositories
[ ! -d "eucaconsole" ] || rm -rf "eucaconsole"
git clone --depth 1 --branch "${EUCA_CON_BRANCH}" "${EUCA_CON_REPO}"

[ ! -d "eucaconsole-rpmspec" ] || rm -rf "eucaconsole-rpmspec"
git clone --depth 1 --branch "${EUCA_CON_RPM_BRANCH}" "${EUCA_CON_RPM_REPO}"

# setup rpmbuild
mkdir -p "${RPMBUILD}/SPECS"
mkdir -p "${RPMBUILD}/SOURCES"

[ ! -f "${RPMBUILD}/SPECS/eucaconsole.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/eucaconsole.spec"
ln -fs "$(pwd)/eucaconsole-rpmspec/eucaconsole.spec" \
  "${RPMBUILD}/SPECS"

# generate source tars, get commit info
pushd "eucaconsole"
EUCA_CON_GIT_SHORT=$(git rev-parse --short HEAD)
popd
tar -cvJf "${RPMBUILD}/SOURCES/eucaconsole.tar.xz" \
    --exclude ".git*" \
    "eucaconsole"

for EUCA_CON_SOURCE in $(spectool -l "eucaconsole-rpmspec/eucaconsole.spec" | awk '{print $2}' | grep -v '%')
do
  cp "eucaconsole-rpmspec/${EUCA_CON_SOURCE}" "${RPMBUILD}/SOURCES/"
done

# build rpms
RPM_VERSION="$(date -u +%Y%m%d)git"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define 'tarball_basedir eucaconsole' \
    --define 'dist el7' \
    --define "build_id ${RPM_VERSION}${EUCA_LIBS_GIT_SHORT}." \
    -ba "${RPMBUILD}/SPECS/eucaconsole.spec"

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

echo "Build complete"

