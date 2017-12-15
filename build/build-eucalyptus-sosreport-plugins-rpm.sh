#!/bin/bash
# Build eucalyptus sosreport plugins rpm on CentOS/RHEL 7

# config
EUCA_SOS_BRANCH="maint-0.5"
EUCA_SOS_REPO="https://github.com/eucalyptus/eucalyptus-sosreport-plugins"
REQUIRE=(
    "git"
    "python2-devel"
    "python-setuptools"
    "rpmdevtools" # for spectool
    "yum-utils"
)
set -ex
RPMBUILD=${RPMBUILD:-$(mktemp -td "rpmbuild.XXXXXXXXXX")}

# dependencies
yum erase -y 'eucalyptus-*'

yum -y install "${REQUIRE[@]}"

yum -y groupinstall development

# clone repositories
[ ! -d "eucalyptus-sosreport-plugins" ] || rm -rf "eucalyptus-sosreport-plugins"
git clone --depth 1 --branch "${EUCA_SOS_BRANCH}" "${EUCA_SOS_REPO}"

# setup rpmbuild
mkdir -p "${RPMBUILD}/SPECS"
mkdir -p "${RPMBUILD}/SOURCES"

[ ! -f "${RPMBUILD}/SPECS/eucalyptus-sos-plugins.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/eucalyptus-sos-plugins.spec"
ln -fs "$(pwd)/eucalyptus-sosreport-plugins/eucalyptus-sos-plugins.spec" \
  "${RPMBUILD}/SPECS"

# generate source tars, get commit info
pushd eucalyptus-sosreport-plugins
EUCA_SOS_GIT_SHORT=$(git rev-parse --short HEAD)
popd
tar -cvJf "${RPMBUILD}/SOURCES/eucalyptus-sosreport-plugins.tar.xz" \
    --exclude ".git*" \
    --exclude "eucalyptus-sos-plugins.spec" \
    "eucalyptus-sosreport-plugins"

# build rpms
RPM_VERSION="$(date -u +%Y%m%d)git"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define "tarball_basedir eucalyptus-sosreport-plugins" \
    --define "dist .${RPM_VERSION}${EUCA_SOS_GIT_SHORT}.el7" \
    -ba "${RPMBUILD}/SPECS/eucalyptus-sos-plugins.spec"

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

if [ ! -z "${RPM_OUT}" ] && [ -d "${RPM_OUT}" ] ; then
    cp -pv "${RPMBUILD}/RPMS"/*/*.rpm "${RPM_OUT}"
fi

echo "Build complete"

