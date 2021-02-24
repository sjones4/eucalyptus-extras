#!/bin/bash
# Install podman and dependencies plus a registry image on the base service image
#
set -euxo pipefail

# Config
IMAGE_PATH="${1:-base-image.raw}"
IMAGE_MOUNT="${IMAGE_MOUNT:-/tmp/image}"
REGISTRY_PATH="${2:-registry.tar}"

# Image setup
LOOP_DEVICE=$(losetup --find)
MAPPER_P1_DEVICE="/dev/mapper/${LOOP_DEVICE##/dev/}p1"

image_post_cleanup ()
{
  umount "${IMAGE_MOUNT}/tmp"             || true
  umount "${IMAGE_MOUNT}/dev"             || true
  umount "${IMAGE_MOUNT}/etc/resolv.conf" || true
  umount "${IMAGE_MOUNT}"                 || true
  kpartx -d "${LOOP_DEVICE}"              || true
  losetup -d "${LOOP_DEVICE}"             || true
}
trap image_post_cleanup EXIT

[ -e "${LOOP_DEVICE}" ] || for N in {0..7}; do mknod /dev/loop$N -m0660 b 7 $N; done
losetup "${LOOP_DEVICE}" "${IMAGE_PATH}"
kpartx -a "${LOOP_DEVICE}"
[ -e "${IMAGE_MOUNT}" ] || mkdir -p "${IMAGE_MOUNT}"
mount "${MAPPER_P1_DEVICE}" "${IMAGE_MOUNT}"
mount -o bind "/dev" "${IMAGE_MOUNT}/dev"
mount -o ro,bind "/etc/resolv.conf" "${IMAGE_MOUNT}/etc/resolv.conf"
mount -t tmpfs -o size=512m tmpfs "${IMAGE_MOUNT}/tmp"

chroot "${IMAGE_MOUNT}" yum install --assumeyes podman
chroot "${IMAGE_MOUNT}" rpm -e --nodeps subscription-manager-rhsm-certificates subscription-manager-rhsm subscription-manager # https://bugs.centos.org/view.php?id=17315

# Configure and enable services
mkdir -pv "${IMAGE_MOUNT}/usr/local/share/registry-container"
cp -fv "${REGISTRY_PATH}" "${IMAGE_MOUNT}/usr/local/share/registry-container/registry.tar"

cat > "${IMAGE_MOUNT}/etc/sysconfig/registry-container" << "EOF"
REGISTRY_HTTP_ADDR=0.0.0.0:5000
REGISTRY_STORAGE=s3
REGISTRY_STORAGE_S3_REGION=eucalyptus
REGISTRY_STORAGE_S3_REGIONENDPOINT=http://s3.internal:8773
REGISTRY_STORAGE_S3_ENCRYPT=false
REGISTRY_STORAGE_S3_MULTIPARTCOPYTHRESHOLDSIZE=5368709120
REGISTRY_STORAGE_S3_SECURE=true
REGISTRY_STORAGE_S3_V4AUTH=true
REGISTRY_STORAGE_CACHE_BLOBDESCRIPTOR=inmemory
EOF

cat > "${IMAGE_MOUNT}/etc/sysconfig/registry-container-bucket" << "EOF"
REGISTRY_STORAGE_S3_BUCKET=NOT_SET
EOF

cat > "${IMAGE_MOUNT}/etc/sysconfig/registry-container-proxy" << "EOF"
REGISTRY_PROXY_REMOTEURL=https://index.docker.io
EOF

cat > "${IMAGE_MOUNT}/etc/sysconfig/registry-container-readonly" << "EOF"
REGISTRY_STORAGE_MAINTENANCE_READONLY={"enabled":true}
REGISTRY_STORAGE_MAINTENANCE_UPLOADPURGING={"enabled":false}
EOF

rm -rf "${IMAGE_MOUNT}/var/lib/yum/uuid"
rm -rf "${IMAGE_MOUNT}/var/cache/yum/"*

