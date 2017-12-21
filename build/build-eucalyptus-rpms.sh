#!/bin/bash
# Build eucalyptus rpms on CentOS/RHEL 7

# config
MODE="${1:-build}" # setup build build-only
VERSION="4.4"
EUCA_BRANCH="${EUCA_BRANCH:-devel-${VERSION}}"
EUCA_REPO="${EUCA_REPO:-https://github.com/sjones4/eucalyptus.git}"
EUCA_PATH="${EUCA_PATH:-${PWD}/eucalyptus}"
REQUIRE=(
    "git"
    "yum-utils"
    "wget"
    "ant"
    "ant-apache-regexp"
    "apache-ivy"
    "curl-devel"
    "gengetopt"
    "java-1.8.0-openjdk-devel"
    "jpackage-utils"
    "json-c-devel"
    "libuuid-devel"
    "libvirt-devel"
    "libxml2-devel"
    "libxslt-devel"
    "m2crypto"
    "openssl-devel"
    "python-devel"
    "python-setuptools"
    "xalan-j2"
    "xalan-j2-xsltc"
)
REQUIRE_EUCA=(
    "http://downloads.eucalyptus.com/software/eucalyptus/4.4/rhel/7Server/x86_64/annogen-0.1.0-8.el7.noarch.rpm"
    "http://downloads.eucalyptus.com/software/eucalyptus/4.4/rhel/7Server/x86_64/axiom-1.2.12-11.el7.noarch.rpm"
    "http://downloads.eucalyptus.com/software/eucalyptus/4.4/rhel/7Server/x86_64/axis2-1.4.1-0.2.el7.noarch.rpm"
    "http://downloads.eucalyptus.com/software/eucalyptus/4.4/rhel/7Server/x86_64/axis2c-devel-1.6.0-0.8.el7.x86_64.rpm"
    "http://downloads.eucalyptus.com/software/eucalyptus/4.4/rhel/7Server/x86_64/axis2c-1.6.0-0.8.el7.x86_64.rpm"
    "http://downloads.eucalyptus.com/software/eucalyptus/4.4/rhel/7Server/x86_64/glassfish-servlet-api-3.1.0-9.el7.noarch.rpm"
    "http://downloads.eucalyptus.com/software/eucalyptus/4.4/rhel/7Server/x86_64/neethi-3.0.1-10.el7.noarch.rpm"
    "http://downloads.eucalyptus.com/software/eucalyptus/4.4/rhel/7Server/x86_64/rampartc-1.3.0-0.6.el7.x86_64.rpm"
    "http://downloads.eucalyptus.com/software/eucalyptus/4.4/rhel/7Server/x86_64/rampartc-devel-1.3.0-0.6.el7.x86_64.rpm"
    "http://downloads.eucalyptus.com/software/eucalyptus/4.4/rhel/7Server/x86_64/woden-1.0-0.11.M9.el7.1.noarch.rpm"
    "http://downloads.eucalyptus.com/software/eucalyptus/4.4/rhel/7Server/x86_64/XmlSchema-1.4.7-11.el7.noarch.rpm"
)
set -ex

# dependencies
if [ "${MODE}" != "build-only" ] ; then
  yum erase -y 'eucalyptus-*'

  yum -y install epel-release # for gengetopt

  yum -y install "${REQUIRE[@]}"

  yum -y groupinstall development

  yum -y install "${REQUIRE_EUCA[@]}" || yum -y upgrade "${REQUIRE_EUCA[@]}"
fi

[ "${MODE}" != "setup" ] || exit 0

# clone repositories
if [ "${MODE}" != "build-only" ] ; then
  [ ! -d "eucalyptus" ] || rm -rf "eucalyptus"
  git clone --depth 1 --branch "${EUCA_BRANCH}" "${EUCA_REPO}"
fi

# setup rpmbuild
RPMBUILD=${RPMBUILD:-$(mktemp -td "rpmbuild.XXXXXXXXXX")}
mkdir -p "${RPMBUILD}/SPECS"
mkdir -p "${RPMBUILD}/SOURCES"

[ ! -f "${RPMBUILD}/SPECS/eucalyptus.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/eucalyptus.spec"
ln -fs "${EUCA_PATH}/eucalyptus.spec" "${RPMBUILD}/SPECS"

# setup deps rpm for group build
if [ -f "${RPMBUILD}"/RPMS/noarch/eucalyptus-java-deps-*.noarch.rpm ] ; then
  yum -y install "${RPMBUILD}"/RPMS/noarch/eucalyptus-java-deps-*.noarch.rpm
fi

# generate source tars, get commit info
pushd "${EUCA_PATH}"
EUCA_GIT_SHORT=$(git rev-parse --short HEAD)
autoconf
popd
tar -cvJf "${RPMBUILD}/SOURCES/eucalyptus.tar.xz" \
    -C $(dirname "${EUCA_PATH}") \
    --exclude ".git*" \
    --exclude "clc/lib" \
    --exclude "build-info.properties" \
    "eucalyptus"

# build rpms
RPM_DIST="${RPM_DIST:-el7}"
RPM_VERSION="$(date -u +%Y%m%d)git"
RPM_BUILD_ID="${RPM_BUILD_ID:-${RPM_VERSION}${EUCA_GIT_SHORT}}"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define 'tarball_basedir eucalyptus' \
    --define "dist ${RPM_DIST}" \
    --define "build_id ${RPM_BUILD_ID}." \
    -ba "${RPMBUILD}/SPECS/eucalyptus.spec"

yum erase -y 'eucalyptus-*'

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

if [ ! -z "${RPM_OUT}" ] && [ -d "${RPM_OUT}" ] ; then
    cp -pv "${RPMBUILD}/RPMS"/*/*.rpm "${RPM_OUT}"
fi

echo "Build complete"

