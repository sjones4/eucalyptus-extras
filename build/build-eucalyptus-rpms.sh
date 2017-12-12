#!/bin/bash
# Build eucalyptus rpms on CentOS/RHEL 7

# config
VERSION="4.4"
EUCA_BRANCH="devel-${VERSION}"
EUCA_REPO="https://github.com/sjones4/eucalyptus.git"
EUCA_LIBS_BRANCH="devel-${VERSION}"
EUCA_LIBS_REPO="https://github.com/sjones4/eucalyptus-cloud-libs.git"
EUCA_RPM_BRANCH="maint-${VERSION}"
EUCA_RPM_REPO="https://github.com/eucalyptus/eucalyptus-rpmspec.git"
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
RPMBUILD="$(pwd)/rpmbuild"
set -ex

# dependencies
yum erase -y 'eucalyptus-*'

yum -y install epel-release # for gengetopt

yum -y install "${REQUIRE[@]}"

yum -y groupinstall development

yum -y install "${REQUIRE_EUCA[@]}" || yum -y upgrade "${REQUIRE_EUCA[@]}"

# clone repositories
[ ! -d "eucalyptus" ] || rm -rf "eucalyptus"
git clone --depth 1 --branch "${EUCA_BRANCH}" "${EUCA_REPO}"

[ ! -d "eucalyptus-cloud-libs" ] || rm -rf "eucalyptus-cloud-libs"
git clone --depth 1 --branch "${EUCA_LIBS_BRANCH}" "${EUCA_LIBS_REPO}"

[ ! -d "eucalyptus-rpmspec" ] || rm -rf "eucalyptus-rpmspec"
git clone --depth 1 --branch "${EUCA_RPM_BRANCH}" "${EUCA_RPM_REPO}"

# setup rpmbuild
mkdir -p "${RPMBUILD}/SPECS"
mkdir -p "${RPMBUILD}/SOURCES"
[ ! -d "${RPMBUILD}/RPMS" ] || rm -rf "${RPMBUILD}/RPMS"
[ ! -d "${RPMBUILD}/SRPMS" ] || rm -rf "${RPMBUILD}/SRPMS"

[ ! -f "${RPMBUILD}/SPECS/eucalyptus.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/eucalyptus.spec"
ln -fs "$(pwd)/eucalyptus-rpmspec/eucalyptus.spec" \
  "${RPMBUILD}/SPECS"

[ ! -f "${RPMBUILD}/SPECS/eucalyptus-java-deps.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/eucalyptus-java-deps.spec"
ln -fs "$(pwd)/eucalyptus-cloud-libs/eucalyptus-java-deps.spec" \
  "${RPMBUILD}/SPECS"

# generate source tars, get commit info
pushd eucalyptus
EUCA_GIT_SHORT=$(git rev-parse --short HEAD)
autoconf
popd
tar -cvJf "${RPMBUILD}/SOURCES/eucalyptus.tar.xz" \
    --exclude ".git*" \
    --exclude "clc/lib" \
    --exclude "build-info.properties" \
    "eucalyptus"

pushd eucalyptus-cloud-libs
EUCA_LIBS_GIT_SHORT=$(git rev-parse --short HEAD)
autoconf
popd
tar -cvJf "${RPMBUILD}/SOURCES/eucalyptus-cloud-libs.tar.xz" \
    --exclude ".git*" \
    --exclude "tests" \
    --exclude "*.spec" \
    "eucalyptus-cloud-libs"

# build rpms
RPM_VERSION="$(date -u +%Y%m%d)git"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define 'tarball_basedir eucalyptus-cloud-libs' \
    --define 'dist el7' \
    --define "build_id ${RPM_VERSION}${EUCA_LIBS_GIT_SHORT}." \
    -ba "${RPMBUILD}/SPECS/eucalyptus-java-deps.spec"

yum install -y \
    "${RPMBUILD}/RPMS/noarch/"eucalyptus-java-deps-*.noarch.rpm

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define 'tarball_basedir eucalyptus' \
    --define 'dist el7' \
    --define "build_id ${RPM_VERSION}${EUCA_LIBS_GIT_SHORT}." \
    -ba "${RPMBUILD}/SPECS/eucalyptus.spec"

find rpmbuild/SRPMS/

find rpmbuild/RPMS/

echo "Build complete"

