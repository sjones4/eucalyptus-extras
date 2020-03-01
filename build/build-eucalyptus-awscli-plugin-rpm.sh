#!/bin/bash
# Build eucalyptus-awscli-plugin rpm on CentOS/RHEL 7

# config
MODE="${1:-build}" # setup build build-only
YUM_OPTS="${YUM_OPTS:--y}"
EUCA_AWSCLI_BRANCH="${EUCA_AWSCLI_BRANCH:-master}"
EUCA_AWSCLI_REPO="${EUCA_AWSCLI_REPO:-https://github.com/corymbia/eucalyptus-awscli-plugin.git}"
EUCA_AWSCLI_PATH="${EUCA_AWSCLI_PATH:-${PWD}/eucalyptus-awscli-plugin}"
REQUIRE=(
    "autoconf"
    "git"
    "python2-devel",
    "python-setuptools",
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
  [ ! -d "eucalyptus-awscli-plugin" ] || rm -rf "eucalyptus-awscli-plugin"
  git clone --depth 1 --branch "${EUCA_AWSCLI_BRANCH}" "${EUCA_AWSCLI_REPO}"
fi

# setup rpmbuild
RPMBUILD=${RPMBUILD:-$(mktemp -td "rpmbuild.XXXXXXXXXX")}
mkdir -p "${RPMBUILD}/SPECS"
mkdir -p "${RPMBUILD}/SOURCES"

[ ! -f "${RPMBUILD}/SPECS/eucalyptus-awscli-plugin.spec" ] || rm -f \
  "${RPMBUILD}/SPECS/eucalyptus-awscli-plugin.spec"
cp -fv "${EUCA_AWSCLI_PATH}/eucalyptus-awscli-plugin.spec" \
  "${RPMBUILD}/SPECS"

# generate source tars, get commit info
pushd "${EUCA_AWSCLI_PATH}"
EUCA_AWSCLI_VERSION=$(<VERSION)
EUCA_AWSCLI_GIT_SHORT=$(git rev-parse --short HEAD)
popd

tar -cvJf "${RPMBUILD}/SOURCES/eucalyptus-awscli-plugin.tar.xz" \
    --exclude ".git*" \
    "eucalyptus-awscli-plugin"

# build rpms
RPMBUILD_OPTS="${RPMBUILD_OPTS}"
RPM_DIST="${RPM_DIST:-el7}"
RPM_VERSION="${RPM_VERSION:-$(date -u +%Y%m%d%H%M)}"
RPM_BUILD_ID="${RPM_BUILD_ID:-${RPM_VERSION}git${EUCA_AWSCLI_GIT_SHORT}}"

rpmbuild \
    --define "_topdir ${RPMBUILD}" \
    --define "tarball_basedir eucalyptus-awscli-plugin" \
    --define "version ${EUCA_AWSCLI_VERSION}" \
    --define "dist ${RPM_DIST}" \
    --define "build_id ${RPM_BUILD_ID}." \
    ${RPMBUILD_OPTS} \
    -ba "${RPMBUILD}/SPECS/eucalyptus-awscli-plugin.spec"

find "${RPMBUILD}/SRPMS/"

find "${RPMBUILD}/RPMS/"

if [ ! -z "${RPM_OUT}" ] && [ -d "${RPM_OUT}" ] ; then
    cp -pv "${RPMBUILD}/RPMS"/*/*.rpm "${RPM_OUT}"
fi

echo "Build complete"

