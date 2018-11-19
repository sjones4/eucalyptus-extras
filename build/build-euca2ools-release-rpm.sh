#!/bin/bash
# Build euca2ools release rpm on CentOS/RHEL 7

# config
MODE="${1:-build}" # setup build build-only
YUM_OPTS="${YUM_OPTS:--y}"
EUCA2OOLS_REL_BRANCH="${EUCA2OOLS_REL_BRANCH:-master}"
EUCA2OOLS_REL_REPO="${EUCA2OOLS_REL_REPO:-https://github.com/sjones4/euca2ools-release.git}"
EUCA2OOLS_REL_RPM_REPO_URL="${EUCA2OOLS_REL_RPM_REPO_URL:-http://downloads.eucalyptus.cloud/software/euca2ools/3.4/rhel/7/x86_64/}"
REQUIRE=(
    "autoconf"
    "git"
    "rpm-build"
    "yum"
)
set -ex

# dependencies
if [ "${MODE}" != "build-only" ] ; then
  yum ${YUM_OPTS} erase 'euca2ools-release' || true

  yum ${YUM_OPTS} install "${REQUIRE[@]}"
fi

[ "${MODE}" != "setup" ] || exit 0

# clone repositories
if [ "${MODE}" != "build-only" ] ; then
  [ ! -d "euca2ools-release" ] || rm -rf "euca2ools-release"
  git clone --depth 1 --branch "${EUCA2OOLS_REL_BRANCH}" "${EUCA2OOLS_REL_REPO}"
fi

# setup rpmbuild
RPMBUILD=${RPMBUILD:-$(mktemp -td "rpmbuild.XXXXXXXXXX")}
mkdir -p "${RPMBUILD}/SPECS"
mkdir -p "${RPMBUILD}/SOURCES"

[ ! -f "${RPMBUILD}/SPECS/euca2ools-release.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/euca2ools-release.spec"
cp -fv "$(pwd)/euca2ools-release/euca2ools-release.spec" \
  "${RPMBUILD}/SPECS"

# generate source tars, get commit info
pushd euca2ools-release
EUCA2OOLS_REL_GIT_SHORT=$(git rev-parse --short HEAD)
autoconf
popd
tar -cvJf "${RPMBUILD}/SOURCES/euca2ools-release.tar.xz" \
    --exclude ".git*" \
    "euca2ools-release"

# build rpms
RPMBUILD_OPTS="${RPMBUILD_OPTS}"
RPM_DIST="${RPM_DIST:-el7}"
RPM_VERSION="${RPM_VERSION:-$(date -u +%Y%m%d%H%M)}"
RPM_BUILD_ID="${RPM_BUILD_ID:-${RPM_VERSION}git${EUCA2OOLS_REL_GIT_SHORT}}"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define 'tarball_basedir euca2ools-release' \
    --define "rpm_repo_url ${EUCA2OOLS_REL_RPM_REPO_URL}" \
    --define "dist .${RPM_BUILD_ID}.${RPM_DIST}" \
    ${RPMBUILD_OPTS} \
    -ba "${RPMBUILD}/SPECS/euca2ools-release.spec"

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

if [ ! -z "${RPM_OUT}" ] && [ -d "${RPM_OUT}" ] ; then
    cp -pv "${RPMBUILD}/RPMS"/*/*.rpm "${RPM_OUT}"
fi

echo "Build complete"

