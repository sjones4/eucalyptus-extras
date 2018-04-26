#!/bin/bash
# Build eucalyptus service image load balancer servo rpm on CentOS/RHEL 7

# config
MODE="${1:-build}" # setup build build-only
YUM_OPTS="${YUM_OPTS:--y}"
EUCA_LBS_BRANCH="${EUCA_LBS_BRANCH:-master}"
EUCA_LBS_REPO="${EUCA_LBS_REPO:-https://github.com/eucalyptus/load-balancer-servo.git}"
REQUIRE=(
    "git"
    "python-devel"
    "python-setuptools"
    "rpm-build"
    "systemd"
    "yum"
)
set -ex

# dependencies
if [ "${MODE}" != "build-only" ] ; then
  yum ${YUM_OPTS} erase 'eucalyptus-*' 'load-balancer-servo'

  yum ${YUM_OPTS} install "${REQUIRE[@]}"
fi

[ "${MODE}" != "setup" ] || exit 0

# clone repositories
if [ "${MODE}" != "build-only" ] ; then
  [ ! -d "load-balancer-servo" ] || rm -rf "load-balancer-servo"
  git clone --depth 1 --branch "${EUCA_LBS_BRANCH}" "${EUCA_LBS_REPO}"
fi

# setup rpmbuild
RPMBUILD=${RPMBUILD:-$(mktemp -td "rpmbuild.XXXXXXXXXX")}
mkdir -p "${RPMBUILD}/SPECS"
mkdir -p "${RPMBUILD}/SOURCES"

[ ! -f "${RPMBUILD}/SPECS/load-balancer-servo.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/load-balancer-servo.spec"
cp -fv "$(pwd)/load-balancer-servo/load-balancer-servo.spec" \
  "${RPMBUILD}/SPECS"

# generate source tars, get commit info
pushd "load-balancer-servo"
EUCA_LBS_GIT_SHORT=$(git rev-parse --short HEAD)
popd

cp "load-balancer-servo/load-balancer-servo.tmpfiles" "${RPMBUILD}/SOURCES/"
tar -cvJf "${RPMBUILD}/SOURCES/load-balancer-servo.tar.xz" \
    --exclude ".git*" \
    --exclude "load-balancer-servo.spec" \
    "load-balancer-servo"

# build rpms
RPMBUILD_OPTS="${RPMBUILD_OPTS}"
RPM_DIST="${RPM_DIST:-el7}"
RPM_VERSION="${RPM_VERSION:-$(date -u +%Y%m%d%H%M)}"
RPM_BUILD_ID="${RPM_BUILD_ID:-${RPM_VERSION}git${EUCA_LBS_GIT_SHORT}}"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define "tarball_basedir load-balancer-servo" \
    --define "dist .${RPM_BUILD_ID}.${RPM_DIST}" \
    ${RPMBUILD_OPTS} \
    -ba "${RPMBUILD}/SPECS/load-balancer-servo.spec"

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

if [ ! -z "${RPM_OUT}" ] && [ -d "${RPM_OUT}" ] ; then
    cp -pv "${RPMBUILD}/RPMS"/*/*.rpm "${RPM_OUT}"
fi

echo "Build complete"

