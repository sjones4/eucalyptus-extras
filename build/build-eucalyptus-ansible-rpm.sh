#!/bin/bash
# Build eucalyptus-ansible rpm on CentOS/RHEL 7

# config
MODE="${1:-build}" # setup build build-only
YUM_OPTS="${YUM_OPTS:--y}"
EUCA_ANSI_BRANCH="${EUCA_ANSI_BRANCH:-master}"
EUCA_ANSI_REPO="${EUCA_ANSI_REPO:-https://github.com/corymbia/eucalyptus-ansible.git}"
EUCA_ANSI_PATH="${EUCA_ANSI_PATH:-${PWD}/eucalyptus-ansible}"
REQUIRE=(
    "autoconf"
    "curl"
    "git"
    "rpm-build"
    "unzip"
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
  [ ! -d "eucalyptus-ansible" ] || rm -rf "eucalyptus-ansible"
  git clone --depth 1 --branch "${EUCA_ANSI_BRANCH}" "${EUCA_ANSI_REPO}"
fi

# setup rpmbuild
RPMBUILD=${RPMBUILD:-$(mktemp -td "rpmbuild.XXXXXXXXXX")}
mkdir -p "${RPMBUILD}/SPECS"
mkdir -p "${RPMBUILD}/SOURCES"

[ ! -f "${RPMBUILD}/SPECS/eucalyptus-ansible.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/eucalyptus-ansible.spec"
cp -fv "${EUCA_ANSI_PATH}/eucalyptus-ansible.spec" \
  "${RPMBUILD}/SPECS"

# generate source tars, get commit info
pushd "${EUCA_ANSI_PATH}"
EUCA_ANSI_GIT_SHORT=$(git rev-parse --short HEAD)
autoconf
./configure
make dist
EUCA_ANSI_DIST=$(ls dist/eucalyptus-ansible-*.tar.xz)
EUCA_ANSI_DIST_BASEDIR="${EUCA_ANSI_DIST%%.tar.xz}"
EUCA_ANSI_DIST_BASEDIR="${EUCA_ANSI_DIST_BASEDIR##dist/}"
cp -v "${EUCA_ANSI_DIST}" "${RPMBUILD}/SOURCES/"
make distclean
popd

# build rpms
RPMBUILD_OPTS="${RPMBUILD_OPTS}"
RPM_DIST="${RPM_DIST:-el7}"
RPM_VERSION="${RPM_VERSION:-$(date -u +%Y%m%d%H%M)}"
RPM_BUILD_ID="${RPM_BUILD_ID:-${RPM_VERSION}git${EUCA_ANSI_GIT_SHORT}}"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define "tarball_basedir ${EUCA_ANSI_DIST_BASEDIR}" \
    --define "dist ${RPM_DIST}" \
    --define "build_id ${RPM_BUILD_ID}." \
    ${RPMBUILD_OPTS} \
    -ba "${RPMBUILD}/SPECS/eucalyptus-ansible.spec"

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

if [ ! -z "${RPM_OUT}" ] && [ -d "${RPM_OUT}" ] ; then
    cp -pv "${RPMBUILD}/RPMS"/*/*.rpm "${RPM_OUT}"
fi

echo "Build complete"

