#!/bin/bash
# Update eucalyptus rpms in a repository

# setup
REPO_VERSION="devel-4.4"
REPO_PATH="${REPO_PATH:-eucalyptus-${REPO_VERSION}}"
REPO_DIR="${1:-/var/www/eucalyptus-repos/${REPO_PATH}}"
RPM_DIR=${1:-$(pwd)}
RPM_VERSIONS=${RPM_VERSIONS:-1}

# checks
which createrepo &> /dev/null
if [ $? -ne 0 ] ; then
  echo "createrepo not found (createrepo not installed?)"
  exit 1
fi

which repomanage &> /dev/null
if [ $? -ne 0 ] ; then
  echo "repomanage not found (yum-utils not installed?)"
  exit 1
fi

if [ ! -d "${REPO_DIR}" ] ; then
  echo "repository directory ${REPO_DIR} not found"
  exit 1
fi

if [ ! -d "${RPM_DIR}" ] ; then
  echo "rpm directory ${RPM_DIR} not found"
  exit 1
fi

# update
echo "Copying latest packages"
pushd "${RPM_DIR}"
for RPM in eucalyptus-*.rpm eucanetd-*.rpm eucaconsole-*.rpm load-balancer-servo-*.rpm; do
  [ -f "${RPM}" ] || continue
  cp -pv "${RPM}" "${REPO_DIR}/"
done
popd

echo "Removing old packages"
repomanage --old --keep=${RPM_VERSIONS} -c "${REPO_DIR}" | \
  xargs -r rm -fv

echo "Updating repository metadata"
createrepo "${REPO_DIR}"

