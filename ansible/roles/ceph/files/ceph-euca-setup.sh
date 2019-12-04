#!/bin/bash
# Configure ceph for eucalyptus use and create eucalyptus deployment
# artifacts
set -euo pipefail

EUCA_POOL_PLACEMENT_GROUPS="${EUCA_POOL_PLACEMENT_GROUPS:-100}"
EUCA_CEPH_ARTIFACTS_DIR="euca-artifacts"

if ! ceph osd pool ls | grep -q euca ; then
    echo "Generating volume and snapshot pools"
    ceph osd pool create eucavolumes ${EUCA_POOL_PLACEMENT_GROUPS}
    ceph osd pool create eucasnapshots ${EUCA_POOL_PLACEMENT_GROUPS}
fi

if [ ! -e "${EUCA_CEPH_ARTIFACTS_DIR}" ] ; then
    echo "Creating eucalyptus artifacts directory"
    mkdir -p "${EUCA_CEPH_ARTIFACTS_DIR}"
fi

if ! ceph auth list 2>&1 | grep -q euca ; then
    echo "Generating S3 user for radosgw"
    ceph auth get-or-create client.eucalyptus \
      mon 'allow r' \
      osd 'allow rwx pool=rbd, allow rwx pool=eucasnapshots, allow rwx pool=eucavolumes, allow x' \
      -o "${EUCA_CEPH_ARTIFACTS_DIR}/ceph.client.eucalyptus.keyring"
fi

if ! radosgw-admin metadata list user | grep -q euca ; then
    echo "Generating radowsgw (rgw) S3 user"
    radosgw-admin user create --uid=eucas3 --display-name="Eucalyptus S3 User" \
      | egrep '(user"|access_key|secret_key)' \
      | sed --expression='1 i\{' --expression='$ a\}' \
      > "${EUCA_CEPH_ARTIFACTS_DIR}/rgw_credentials.json"
fi

if [ ! -e "${EUCA_CEPH_ARTIFACTS_DIR}/ceph.conf" ] ; then
    echo "Copying ceph.conf file"
    cp "/etc/ceph/ceph.conf" "${EUCA_CEPH_ARTIFACTS_DIR}/ceph.conf"
fi
