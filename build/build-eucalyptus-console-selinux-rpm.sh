#!/bin/bash
# Build eucalyptus console selinux rpm on CentOS/RHEL 7

# config
MODE="${1:-build}" # setup build build-only
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

# dependencies
if [ "${MODE}" != "build-only" ] ; then
  yum erase -y 'eucaconsole-*'

  yum -y install "${REQUIRE[@]}"

  yum -y groupinstall development
fi

[ "${MODE}" != "setup" ] || exit 0

# clone repositories
if [ "${MODE}" != "build-only" ] ; then
  [ ! -d "eucaconsole-selinux" ] || rm -rf "eucaconsole-selinux"
  git clone --depth 1 --branch "${EUCA_CON_SE_BRANCH}" "${EUCA_CON_SE_REPO}"
fi

# setup rpmbuild
RPMBUILD=${RPMBUILD:-$(mktemp -td "rpmbuild.XXXXXXXXXX")}
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
RPMBUILD_OPTS="${RPMBUILD_OPTS}"
RPM_DIST="${RPM_DIST:-el7}"
RPM_VERSION="$(date -u +%Y%m%d)git"
RPM_BUILD_ID="${RPM_BUILD_ID:-${RPM_VERSION}${EUCA_CON_SE_GIT_SHORT}}"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define "dist .${RPM_BUILD_ID}.${RPM_DIST}" \
    ${RPMBUILD_OPTS} \
    -ba "${RPMBUILD}/SPECS/eucaconsole-selinux.spec"

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

if [ ! -z "${RPM_OUT}" ] && [ -d "${RPM_OUT}" ] ; then
    cp -pv "${RPMBUILD}/RPMS"/*/*.rpm "${RPM_OUT}"
fi

echo "Build complete"

