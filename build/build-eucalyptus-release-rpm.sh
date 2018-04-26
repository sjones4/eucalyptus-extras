#!/bin/bash
# Build eucalyptus release rpm on CentOS/RHEL 7

# config
MODE="${1:-build}" # setup build build-only
YUM_OPTS="${YUM_OPTS:--y}"
EUCA_REL_BRANCH="${EUCA_REL_BRANCH:-master}"
EUCA_REL_REPO="${EUCA_REL_REPO:-https://github.com/sjones4/eucalyptus-release.git}"
EUCA_REL_RPM_REPO_URL="${EUCA_REL_RPM_REPO_URL:-http://downloads.eucalyptus.cloud/software/eucalyptus/4.4/rhel/7/x86_64/}"
REQUIRE=(
    "autoconf"
    "git"
    "rpm-build"
    "yum"
)
set -ex

# dependencies
if [ "${MODE}" != "build-only" ] ; then
  yum ${YUM_OPTS} erase 'eucalyptus-release'

  yum ${YUM_OPTS} install "${REQUIRE[@]}"
fi

[ "${MODE}" != "setup" ] || exit 0

# clone repositories
if [ "${MODE}" != "build-only" ] ; then
  [ ! -d "eucalyptus-release" ] || rm -rf "eucalyptus-release"
  git clone --depth 1 --branch "${EUCA_REL_BRANCH}" "${EUCA_REL_REPO}"
fi

# setup rpmbuild
RPMBUILD=${RPMBUILD:-$(mktemp -td "rpmbuild.XXXXXXXXXX")}
mkdir -p "${RPMBUILD}/SPECS"
mkdir -p "${RPMBUILD}/SOURCES"

[ ! -f "${RPMBUILD}/SPECS/eucalyptus-release.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/eucalyptus-release.spec"
cp -fv "$(pwd)/eucalyptus-release/eucalyptus-release.spec" \
  "${RPMBUILD}/SPECS"

# generate source tars, get commit info
pushd eucalyptus-release
EUCA_REL_GIT_SHORT=$(git rev-parse --short HEAD)
autoconf
popd
tar -cvJf "${RPMBUILD}/SOURCES/eucalyptus-release.tar.xz" \
    --exclude ".git*" \
    "eucalyptus-release"

# build rpms
RPMBUILD_OPTS="${RPMBUILD_OPTS}"
RPM_DIST="${RPM_DIST:-el7}"
RPM_VERSION="${RPM_VERSION:-$(date -u +%Y%m%d%H%M)}"
RPM_BUILD_ID="${RPM_BUILD_ID:-${RPM_VERSION}git${EUCA_REL_GIT_SHORT}}"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define 'tarball_basedir eucalyptus-release' \
    --define "rpm_repo_url ${EUCA_REL_RPM_REPO_URL}" \
    --define "dist .${RPM_BUILD_ID}.${RPM_DIST}" \
    ${RPMBUILD_OPTS} \
    -ba "${RPMBUILD}/SPECS/eucalyptus-release.spec"

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

if [ ! -z "${RPM_OUT}" ] && [ -d "${RPM_OUT}" ] ; then
    cp -pv "${RPMBUILD}/RPMS"/*/*.rpm "${RPM_OUT}"
fi

echo "Build complete"

