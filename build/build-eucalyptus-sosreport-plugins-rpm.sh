#!/bin/bash
# Build eucalyptus sosreport plugins rpm on CentOS/RHEL 7

# config
MODE="${1:-build}" # setup build build-only
YUM_OPTS="${YUM_OPTS:--y}"
EUCA_SOS_BRANCH="${EUCA_SOS_BRANCH:-master}"
EUCA_SOS_REPO="${EUCA_SOS_REPO:-https://github.com/corymbia/eucalyptus-sosreport-plugins.git}"
REQUIRE=(
    "git"
    "python2-devel"
    "python-setuptools"
    "rpm-build"
    "rpmdevtools" # for spectool
    "yum"
)
set -ex

# dependencies
if [ "${MODE}" != "build-only" ] ; then
  yum ${YUM_OPTS} erase 'eucalyptus-*'

  yum ${YUM_OPTS} install "${REQUIRE[@]}"
fi

[ "${MODE}" != "setup" ] || exit 0

# clone repositories
if [ "${MODE}" != "build-only" ] ; then
  [ ! -d "eucalyptus-sosreport-plugins" ] || rm -rf "eucalyptus-sosreport-plugins"
  git clone --depth 1 --branch "${EUCA_SOS_BRANCH}" "${EUCA_SOS_REPO}"
fi

# setup rpmbuild
RPMBUILD=${RPMBUILD:-$(mktemp -td "rpmbuild.XXXXXXXXXX")}
mkdir -p "${RPMBUILD}/SPECS"
mkdir -p "${RPMBUILD}/SOURCES"

[ ! -f "${RPMBUILD}/SPECS/eucalyptus-sos-plugins.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/eucalyptus-sos-plugins.spec"
cp -fv "$(pwd)/eucalyptus-sosreport-plugins/eucalyptus-sos-plugins.spec" \
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
RPMBUILD_OPTS="${RPMBUILD_OPTS}"
RPM_DIST="${RPM_DIST:-el7}"
RPM_VERSION="${RPM_VERSION:-$(date -u +%Y%m%d%H%M)}"
RPM_BUILD_ID="${RPM_BUILD_ID:-${RPM_VERSION}git${EUCA_SOS_GIT_SHORT}}"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define "tarball_basedir eucalyptus-sosreport-plugins" \
    --define "dist .${RPM_BUILD_ID}.${RPM_DIST}" \
    ${RPMBUILD_OPTS} \
    -ba "${RPMBUILD}/SPECS/eucalyptus-sos-plugins.spec"

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

if [ ! -z "${RPM_OUT}" ] && [ -d "${RPM_OUT}" ] ; then
    cp -pv "${RPMBUILD}/RPMS"/*/*.rpm "${RPM_OUT}"
fi

echo "Build complete"

