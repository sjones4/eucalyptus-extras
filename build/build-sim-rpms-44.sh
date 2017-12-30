#!/bin/bash
# Build eucalyptus service image rpms for the 4.4 series
set -e

# dependencies
yum -y install "httpd" # create /var/www/

# config
export RPMBUILD=${RPMBUILD:-$(mktemp -td "rpmbuild.XXXXXXXXXX")}
export RPM_OUT="${RPM_OUT:-${PWD}/rpms}"
export RPM_VERSION="${RPM_VERSION:-$(date -u +%Y%m%d%H%M)}"
export EUCALYPTUS_BUILD_REPO_DIR=$(mktemp -td --tmpdir="/var/www/" "eucalyptus-packages.XXXXXXXXXX")
chmod 755 "${EUCALYPTUS_BUILD_REPO_DIR}"

# build
mkdir -pv "${RPM_OUT}"
./build-eucalyptus-cloud-libs-rpm.sh
./build-eucalyptus-rpms.sh
./build-eucalyptus-selinux-rpm.sh
./build-eucalyptus-sim-imaging-worker-rpm.sh
./build-eucalyptus-sim-load-balancer-servo-rpm.sh
./build-eucalyptus-service-image-rpm.sh

#
rm -rf "${RPMBUILD}"
rm -rf "${EUCALYPTUS_BUILD_REPO_DIR}"
find "${RPM_OUT}"
echo "Build complete"
