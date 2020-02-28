#!/bin/bash
# Build eucalyptus rpms on CentOS/RHEL 7

# config
MODE="${1:-build}" # setup build build-only
YUM_OPTS="${YUM_OPTS:--y}"
EUCA_BRANCH="${EUCA_BRANCH:-master}"
EUCA_REPO="${EUCA_REPO:-https://github.com/corymbia/eucalyptus.git}"
EUCA_PATH="${EUCA_PATH:-${PWD}/eucalyptus}"
REQUIRE=(
    "ant"
    "ant-apache-regexp"
    "apache-ivy"
    "autoconf"
    "curl-devel"
    "gcc"
    "gengetopt"
    "git"
    "java-1.8.0-openjdk-devel"
    "jpackage-utils"
    "json-c-devel"
    "libuuid-devel"
    "libvirt-devel"
    "libxml2-devel"
    "libxslt-devel"
    "make"
    "m2crypto"
    "openssl-devel"
    "python-devel"
    "python-setuptools"
    "rpm-build"
    "swig"
    "xalan-j2"
    "xalan-j2-xsltc"
    "yum"
)
# once 5.0 is released these dependencies should use the "5" repository
REQUIRE_EUCA=(
    "http://downloads.eucalyptus.cloud/software/eucalyptus/4.4/rhel/7/x86_64/annogen-0.1.0-8.el7.noarch.rpm"
    "http://downloads.eucalyptus.cloud/software/eucalyptus/4.4/rhel/7/x86_64/axiom-1.2.12-11.el7.noarch.rpm"
    "http://downloads.eucalyptus.cloud/software/eucalyptus/4.4/rhel/7/x86_64/axis2-1.4.1-0.2.el7.noarch.rpm"
    "http://downloads.eucalyptus.cloud/software/eucalyptus/4.4/rhel/7/x86_64/axis2c-devel-1.6.0-0.8.el7.x86_64.rpm"
    "http://downloads.eucalyptus.cloud/software/eucalyptus/4.4/rhel/7/x86_64/axis2c-1.6.0-0.8.el7.x86_64.rpm"
    "http://downloads.eucalyptus.cloud/software/eucalyptus/4.4/rhel/7/x86_64/glassfish-servlet-api-3.1.0-9.el7.noarch.rpm"
    "http://downloads.eucalyptus.cloud/software/eucalyptus/4.4/rhel/7/x86_64/neethi-3.0.1-10.el7.noarch.rpm"
    "http://downloads.eucalyptus.cloud/software/eucalyptus/4.4/rhel/7/x86_64/rampartc-1.3.0-0.6.el7.x86_64.rpm"
    "http://downloads.eucalyptus.cloud/software/eucalyptus/4.4/rhel/7/x86_64/rampartc-devel-1.3.0-0.6.el7.x86_64.rpm"
    "http://downloads.eucalyptus.cloud/software/eucalyptus/4.4/rhel/7/x86_64/woden-1.0-0.11.M9.el7.1.noarch.rpm"
    "http://downloads.eucalyptus.cloud/software/eucalyptus/4.4/rhel/7/x86_64/XmlSchema-1.4.7-11.el7.noarch.rpm"
)
set -ex

# dependencies
if [ "${MODE}" != "build-only" ] ; then
  yum ${YUM_OPTS} erase 'eucalyptus-*' || true

  yum ${YUM_OPTS} install epel-release || true # for gengetopt

  yum ${YUM_OPTS} install "${REQUIRE[@]}"

  yum ${YUM_OPTS} install "${REQUIRE_EUCA[@]}" || yum ${YUM_OPTS} upgrade "${REQUIRE_EUCA[@]}"
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
cp -fv "${EUCA_PATH}/rpm/eucalyptus.spec" "${RPMBUILD}/SPECS"

# setup deps rpm for group build
if [ -f "${RPMBUILD}"/RPMS/noarch/eucalyptus-java-deps-*.noarch.rpm ] ; then
  yum ${YUM_OPTS} install "${RPMBUILD}"/RPMS/noarch/eucalyptus-java-deps-*.noarch.rpm
fi

# generate source tars, get commit info
pushd "${EUCA_PATH}"
EUCA_VERSION=$(<VERSION)
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
RPMBUILD_OPTS="${RPMBUILD_OPTS}"
RPM_DIST="${RPM_DIST:-el7}"
RPM_VERSION="${RPM_VERSION:-$(date -u +%Y%m%d%H%M)}"
RPM_BUILD_ID="${RPM_BUILD_ID:-${RPM_VERSION}git${EUCA_GIT_SHORT}}"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define 'tarball_basedir eucalyptus' \
    --define "version ${EUCA_VERSION}" \
    --define "dist ${RPM_DIST}" \
    --define "build_id ${RPM_BUILD_ID}." \
    ${RPMBUILD_OPTS} \
    -ba "${RPMBUILD}/SPECS/eucalyptus.spec"

yum ${YUM_OPTS} erase 'eucalyptus-*' || true

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

if [ ! -z "${RPM_OUT}" ] && [ -d "${RPM_OUT}" ] ; then
    cp -pv "${RPMBUILD}/RPMS"/*/*.rpm "${RPM_OUT}"
fi

echo "Build complete"

