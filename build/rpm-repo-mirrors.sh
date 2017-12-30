#!/bin/bash
# Mirror repositories for use with eucalyptus installs

# config
MIRROR_REPO_DIR="${1:-/var/www/eucalyptus-mirror-repos}"
MIRROR_REPO_HTTP_CONF="${MIRROR_REPO_HTTP_CONF:-/etc/httpd/conf.d/eucalyptus-mirror-repos.conf}"
MIRROR_REPO_IP="${MIRROR_REPO_IP:-$(hostname -I 2>/dev/null | awk '{print $1}')}"
MIRROR_REPO_EXCLUDES="${MIRROR_REPO_EXCLUDES:-*-release}"
MIRROR_MAX_CONNECTIONS="${MIRROR_MAX_CONNECTIONS:-3}"
MIRROR_THROTTLE="${MIRROR_THROTTLE:-1M}"
MIRROR_RPM_VERSIONS="${MIRROR_RPM_VERSIONS:-1}"

# meta
declare -A REPO_MAP_BASEURL=(
  ["euca2ools"]="http://downloads.eucalyptus.com/software/euca2ools/3.4/rhel/7Server/x86_64/"
)

declare -A REPO_MAP_MIRRORLIST=(
  ["centos-base"]='http://mirrorlist.centos.org/?release=7&arch=$basearch&repo=os'
  ["centos-updates"]='http://mirrorlist.centos.org/?release=7&arch=$basearch&repo=updates'
)

# checks
which createrepo &> /dev/null
if [ $? -ne 0 ] ; then
  echo "createrepo not found (createrepo not installed?)"
  exit 1
fi

which reposync &> /dev/null
if [ $? -ne 0 ] ; then
  echo "reposync not found (yum-utils not installed?)"
  exit 1
fi

# create or update mirrors
echo "Mirroring repositories under ${MIRROR_REPO_DIR}"
YUM_TEMP=$(mktemp -t yum.conf.XXXXXXXX)
MIRROR_REPOIDS=""
for REPO in ${!REPO_MAP_BASEURL[@]} ; do
cat >> "${YUM_TEMP}" <<EOF
[mirror-${REPO}]
name=mirror-${REPO}
baseurl=${REPO_MAP_BASEURL[$REPO]}
enabled=1
keepcache=0
exclude=${MIRROR_REPO_EXCLUDES}
throttle=${MIRROR_THROTTLE}
max_connections=${MIRROR_MAX_CONNECTIONS}

EOF
done
for REPO in ${!REPO_MAP_MIRRORLIST[@]} ; do
cat >> "${YUM_TEMP}" <<EOF
[mirror-${REPO}]
name=mirror-${REPO}
mirrorlist=${REPO_MAP_MIRRORLIST[$REPO]}
enabled=1
keepcache=0
exclude=${MIRROR_REPO_EXCLUDES}
throttle=${MIRROR_THROTTLE}
max_connections=${MIRROR_MAX_CONNECTIONS}

EOF
done
for REPO in ${!REPO_MAP_MIRRORLIST[@]} ${!REPO_MAP_BASEURL[@]}; do
  [ -d "${MIRROR_REPO_DIR}/mirror-${REPO}" ] || \
    mkdir -pv "${MIRROR_REPO_DIR}/mirror-${REPO}"
  MIRROR_REPOIDS="${MIRROR_REPOIDS} --repoid=mirror-${REPO}"
done
reposync \
  --delete \
  --tempcache \
  --newest-only \
  --arch=x86_64 \
  --downloadcomps \
  ${MIRROR_REPOIDS} \
  --config="${YUM_TEMP}" \
  --download_path="${MIRROR_REPO_DIR}"

for REPO in ${!REPO_MAP_MIRRORLIST[@]} ${!REPO_MAP_BASEURL[@]}; do
  echo "Removing old packages for ${REPO}"
  repomanage \
    --old \
    --nocheck \
    --keep=${MIRROR_RPM_VERSIONS} \
    "${MIRROR_REPO_DIR}/mirror-${REPO}" | xargs -r rm -fv

  MIRROR_REPO_GROUP_OPT=""
  if [ -f "${MIRROR_REPO_DIR}/mirror-${REPO}/comps.xml" ] ; then
    MIRROR_REPO_GROUP_OPT="--groupfile comps.xml"
  fi
  echo "Building repository metadata for ${REPO}"
  createrepo \
    ${MIRROR_REPO_GROUP_OPT} \
    "${MIRROR_REPO_DIR}/mirror-${REPO}"
done

# configure httpd
if [ ! -z "${MIRROR_REPO_HTTP_CONF}" ] &&
   [ ! -f "${MIRROR_REPO_HTTP_CONF}" ] &&
   [ -d "$(dirname "${MIRROR_REPO_HTTP_CONF}")" ] ; then
echo "Creating httpd mirror repository configuration ${MIRROR_REPO_HTTP_CONF}"
cat > "${MIRROR_REPO_HTTP_CONF}" <<EOF
Alias /eucalyptus-mirror-repos ${MIRROR_REPO_DIR}

<Directory "${MIRROR_REPO_DIR}">
    SetEnv VIRTUALENV
    Options Indexes FollowSymLinks
    IndexOptions FancyIndexing NameWidth=* SuppressDescription
    Order allow,deny
    Allow from all
</Directory>
EOF
echo "Reloading httpd configuration"
systemctl reload httpd
fi
if [ ! -z "${MIRROR_REPO_HTTP_CONF}" ] &&
   [ ! -f "${MIRROR_REPO_HTTP_CONF}" ] ; then
  echo "Httpd configuration not created (httpd not installed?)"
fi

# cleanup
rm -f "${YUM_TEMP}"

# done
echo "Repository mirrors created or updated in ${MIRROR_REPO_DIR}"
echo "Repository baseurls: "
for REPO in ${!REPO_MAP_MIRRORLIST[@]} ${!REPO_MAP_BASEURL[@]}; do
  echo "  http://${MIRROR_REPO_IP:-localhost}/eucalyptus-mirror-repos/mirror-${REPO}/"
done


