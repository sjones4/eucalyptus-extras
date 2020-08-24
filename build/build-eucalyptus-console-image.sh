#!/bin/bash
# Install eucalyptus console and dependencies on the base service image
#
# The base image should not have any eucalyptus build specific content
# the post step will customize the image.
#
set -euxo pipefail

# Config
IMAGE_PATH="${1:-base-image.raw}"
IMAGE_MOUNT="${IMAGE_MOUNT:-/tmp/image}"
REPO_EUCALYPTUS="${REPO_EUCALYPTUS:-http://downloads.eucalyptus.cloud/software/eucalyptus/master/rhel/7/x86_64/}"

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

# YUM repository and packages
cat > "${IMAGE_MOUNT}/etc/yum.repos.d/eucalyptus.repo" << EOF
[eucalyptus]
name=Eucalyptus 5 - \$basearch
baseurl=${REPO_EUCALYPTUS}
gpgkey=https://downloads.eucalyptus.cloud/software/gpg/eucalyptus-release-key.pub
       https://downloads.eucalyptus.cloud/software/gpg/eucalyptus-release-as-key.pub
enabled=1
gpgcheck=1
fastestmirror_enabled=0
EOF
chroot "${IMAGE_MOUNT}" yum install --assumeyes awscli certbot cloud-utils-growpart eucaconsole

# Configure and enable services
chroot "${IMAGE_MOUNT}" sed --in-place 's/^\(ufshost\|ufsport\|product.url\|pyramid.default_locale_name\|pyramid.locale_negotiator\|aws.enabled\|aws.default.region\) =/#\1/' /etc/eucaconsole/console.ini
chroot "${IMAGE_MOUNT}" sed --in-place 's/use = egg:eucaconsole/use = config:\/etc\/eucaconsole\/console-cloud-config.ini/' /etc/eucaconsole/console.ini

cat > "${IMAGE_MOUNT}/etc/eucaconsole/console-cloud-config.ini" << "EOF"
##############################################
# Eucalyptus Management Console Cloud Config #
##############################################

[app:main]
use = egg:eucaconsole

# Eucalyptus settings
ufshost = ec2.internal
ufsport = 8773

# Branding settings
product.url = https://github.com/Corymbia/eucalyptus/
pyramid.default_locale_name = en
pyramid.locale_negotiator = eucaconsole.i18n.fixed_locale_negotiator

# AWS settings
aws.enabled = false
aws.default.region = us-east-1
EOF

mkdir -p "${IMAGE_MOUNT}/etc/systemd/system/eucaconsole.service.d"
cat > "${IMAGE_MOUNT}/etc/systemd/system/eucaconsole.service.d/eucaconsole-elastic-ip-require.conf" << "EOF"
[Unit]
Requires=eucaconsole-elastic-ip-association.service
EOF

cat > "${IMAGE_MOUNT}/etc/systemd/system/eucaconsole-elastic-ip-association.service" << "EOF"
[Unit]
Description=Eucalyptus Console Elastic IP Address Association
ConditionPathExists=/etc/eucaconsole/elastic-ip-allocation.txt
After=network.target
Before=eucaconsole.service

[Service]
Type=oneshot
ExecStartPre=-/bin/curl --output /run/eucaconsole/instance-id.txt --silent http://169.254.169.254/latest/meta-data/instance-id
ExecStartPre=-/usr/bin/python2 /bin/aws ec2 associate-address \
  --region eucalyptus \
  --endpoint http://ec2.internal:8773/ \
  --allow-reassociation \
  --instance-id file:///run/eucaconsole/instance-id.txt \
  --allocation-id file:///etc/eucaconsole/elastic-ip-allocation.txt
ExecStart=/usr/bin/true

[Install]
WantedBy=multi-user.target
EOF

chroot "${IMAGE_MOUNT}" systemctl enable eucaconsole.service

rm -rf "${IMAGE_MOUNT}/var/lib/yum/uuid"
rm -rf "${IMAGE_MOUNT}/var/cache/yum/"*

