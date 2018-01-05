#!/bin/bash
# Build eucalyptus selinux rpm on CentOS/RHEL 7

# config
MODE="${1:-build}" # setup build build-only
YUM_OPTS="${YUM_OPTS:--y}"
EUCA_SE_BRANCH="${EUCA_SE_BRANCH:-master}"
EUCA_SE_REPO="${EUCA_SE_REPO:-https://github.com/eucalyptus/eucalyptus-selinux.git}"
REQUIRE=(
    "autoconf"
    "git"
    "libselinux-utils"
    "make"
    "policycoreutils"
    "rpm-build"
    "rpmdevtools" # for spectool
    "selinux-policy-base"
    "selinux-policy-devel"
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
  [ ! -d "eucalyptus-selinux" ] || rm -rf "eucalyptus-selinux"
  git clone --depth 1 --branch "${EUCA_SE_BRANCH}" "${EUCA_SE_REPO}"
fi

# setup rpmbuild
RPMBUILD=${RPMBUILD:-$(mktemp -td "rpmbuild.XXXXXXXXXX")}
mkdir -p "${RPMBUILD}/SPECS"
mkdir -p "${RPMBUILD}/SOURCES"

[ ! -f "${RPMBUILD}/SPECS/eucalyptus-selinux.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/eucalyptus-selinux.spec"
cp -fv "$(pwd)/eucalyptus-selinux/eucalyptus-selinux.spec" \
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
RPMBUILD_OPTS="${RPMBUILD_OPTS}"
RPM_DIST="${RPM_DIST:-el7}"
RPM_VERSION="${RPM_VERSION:-$(date -u +%Y%m%d%H%M)}"
RPM_BUILD_ID="${RPM_BUILD_ID:-${RPM_VERSION}git${EUCA_SE_GIT_SHORT}}"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define "dist .${RPM_BUILD_ID}.${RPM_DIST}" \
    ${RPMBUILD_OPTS} \
    -ba "${RPMBUILD}/SPECS/eucalyptus-selinux.spec"

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

if [ ! -z "${RPM_OUT}" ] && [ -d "${RPM_OUT}" ] ; then
    cp -pv "${RPMBUILD}/RPMS"/*/*.rpm "${RPM_OUT}"
fi

echo "Build complete"

