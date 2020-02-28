#!/bin/bash
# Build all eucalyptus rpms
set -e

if [ "${1:-}" = "setupenv" ] ; then
  cat > "${HOME}/.autom4te.cfg" <<"AUTOCONF"
begin-language: "Autoconf-without-aclocal-m4"
args: --no-cache
end-language: "Autoconf-without-aclocal-m4"
AUTOCONF
  exit 0
fi

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
./build-eucalyptus-console-rpm.sh
./build-eucalyptus-console-selinux-rpm.sh
./build-eucalyptus-cloud-libs-rpm.sh
./build-eucalyptus-rpms.sh
./build-eucalyptus-selinux-rpm.sh
./build-eucalyptus-sim-imaging-worker-rpm.sh
./build-eucalyptus-sim-load-balancer-servo-rpm.sh
./build-eucalyptus-service-image-rpm.sh
./build-eucalyptus-sosreport-plugins-rpm.sh

#
rm -rf "${RPMBUILD}"
rm -rf "${EUCALYPTUS_BUILD_REPO_DIR}"
find "${RPM_OUT}"
echo "Build complete"
