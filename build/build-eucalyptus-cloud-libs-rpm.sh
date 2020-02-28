#!/bin/bash
# Build eucalyptus-java-deps rpm on CentOS/RHEL 7

# config
MODE="${1:-build}" # setup build build-only
YUM_OPTS="${YUM_OPTS:--y}"
EUCA_LIBS_BRANCH="${EUCA_LIBS_BRANCH:-master}"
EUCA_LIBS_REPO="${EUCA_LIBS_REPO:-https://github.com/corymbia/eucalyptus-cloud-libs.git}"
EUCA_LIBS_PATH="${EUCA_LIBS_PATH:-${PWD}/eucalyptus-cloud-libs}"
REQUIRE=(
    "autoconf"
    "git"
    "rpm-build"
    "yum"
)
set -ex

# dependencies
if [ "${MODE}" != "build-only" ] ; then
  yum ${YUM_OPTS} erase 'eucalyptus-*' || true

  yum ${YUM_OPTS} install epel-release || true # for gengetopt

  yum ${YUM_OPTS} install "${REQUIRE[@]}"
fi

[ "${MODE}" != "setup" ] || exit 0

# clone repositories
if [ "${MODE}" != "build-only" ] ; then
  [ ! -d "eucalyptus-cloud-libs" ] || rm -rf "eucalyptus-cloud-libs"
  git clone --depth 1 --branch "${EUCA_LIBS_BRANCH}" "${EUCA_LIBS_REPO}"
fi

# setup rpmbuild
RPMBUILD=${RPMBUILD:-$(mktemp -td "rpmbuild.XXXXXXXXXX")}
mkdir -p "${RPMBUILD}/SPECS"
mkdir -p "${RPMBUILD}/SOURCES"

[ ! -f "${RPMBUILD}/SPECS/eucalyptus-java-deps.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/eucalyptus-java-deps.spec"
cp -fv "${EUCA_LIBS_PATH}/eucalyptus-java-deps.spec" \
  "${RPMBUILD}/SPECS"

# generate source tars, get commit info
pushd "${EUCA_LIBS_PATH}"
EUCA_LIBS_GIT_SHORT=$(git rev-parse --short HEAD)
autoconf
popd

tar -cvJf "${RPMBUILD}/SOURCES/eucalyptus-cloud-libs.tar.xz" \
    -C $(dirname "${EUCA_LIBS_PATH}") \
    --exclude ".git*" \
    --exclude "tests" \
    --exclude "*.spec" \
    "eucalyptus-cloud-libs"

# build rpms
RPMBUILD_OPTS="${RPMBUILD_OPTS}"
RPM_DIST="${RPM_DIST:-el7}"
RPM_VERSION="${RPM_VERSION:-$(date -u +%Y%m%d%H%M)}"
RPM_BUILD_ID="${RPM_BUILD_ID:-${RPM_VERSION}git${EUCA_LIBS_GIT_SHORT}}"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define 'tarball_basedir eucalyptus-cloud-libs' \
    --define "dist ${RPM_DIST}" \
    --define "build_id ${RPM_BUILD_ID}." \
    ${RPMBUILD_OPTS} \
    -ba "${RPMBUILD}/SPECS/eucalyptus-java-deps.spec"

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

if [ ! -z "${RPM_OUT}" ] && [ -d "${RPM_OUT}" ] ; then
    cp -pv "${RPMBUILD}/RPMS"/*/*.rpm "${RPM_OUT}"
fi

echo "Build complete"

