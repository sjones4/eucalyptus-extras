#!/bin/bash
# Build all eucalyptus rpms for the 4.4 series

# config
export RPMBUILD=$(mktemp -td "rpmbuild.XXXXXXXXXX")
export RPM_OUT="${RPM_OUT:-${PWD}/rpms}"
export EUCALYPTUS_BUILD_REPO_DIR=$(mktemp -td --tmpdir="/var/www/" "eucalyptus-packages.XXXXXXXXXX")
chmod 755 "${EUCALYPTUS_BUILD_REPO_DIR}"

# build
mkdir -pv "${RPM_OUT}"
./build-eucalyptus-console-rpm.sh
./build-eucalyptus-console-selinux-rpm.sh
./build-eucalyptus-rpms.sh
./build-eucalyptus-selinux-rpm.sh
cp -pv "${RPM_OUT}"/*.rpm "${EUCALYPTUS_BUILD_REPO_DIR}"
./build-eucalyptus-service-image-rpm.sh
./build-eucalyptus-sosreport-plugins-rpm.sh

#
rm -rf "${RPMBUILD}"
rm -rf "${EUCALYPTUS_BUILD_REPO_DIR}"
find "${RPM_OUT}"
echo "Build complete"
