#!/bin/bash
# Initialize a repository for eucalyptus rpms
#
# To synchronize eucalyptus rpms as well as dependencies use:
#
#   REPO_EXCLUDES=eucalyptus-release ./rpm-repo-init.sh

# setup
EUCALYPTUS_MIRROR="${EUCALYPTUS_MIRROR:-http://downloads.eucalyptuscloud.org/software/eucalyptus/4.4/rhel/7/x86_64/}"
REPO_VERSION="devel-4.4"
REPO_PATH="${REPO_PATH:-eucalyptus-${REPO_VERSION}}"
REPO_DIR="${1:-/var/www/eucalyptus-repos/${REPO_PATH}}"
REPO_HTTP_CONF="${REPO_HTTP_CONF:-/etc/httpd/conf.d/eucalyptus-repos.conf}"
REPO_EXCLUDES="${REPO_EXCLUDES:-eucaconsole*,eucanetd*,load-balancer-servo*,eucalyptus,eucalyptus-admin-tools,eucalyptus-axis2c-common,eucalyptus-blockdev-utils,eucalyptus-cc,eucalyptus-cloud,eucalyptus-common-java,eucalyptus-common-java-libs,eucalyptus-imaging-toolkit,eucalyptus-imaging-worker,eucalyptus-java-deps,eucalyptus-nc,eucalyptus-release,eucalyptus-sc,eucalyptus-selinux,eucalyptus-service-image,eucalyptus-walrus}"
REPO_IP="${REPO_IP:-$(hostname -I 2>/dev/null | awk '{print $1}')}"
REPO_UPDATE_RPM_VERSIONS=${REPO_UPDATE_RPM_VERSIONS:-1}

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

REPO_UPDATE=""
if [ -d "${REPO_DIR}" ] ; then
  REPO_FILES=$(ls "${REPO_DIR}")
  if [ ! -z "${REPO_FILES}" ] ; then
    echo "repository directory ${REPO_DIR} exists and is not empty, will refresh"
    REPO_UPDATE="1"
  fi
fi

# initialize repo
echo "Creating yum repository ${REPO_DIR}"
YUM_TEMP=$(mktemp -t yum.conf.XXXXXXXX)
YUM_RAND=$(echo -n "${YUM_TEMP}" | tail -c 8)
cat > "${YUM_TEMP}" <<EOF
[mirror-${YUM_RAND}]
name=mirror-${YUM_RAND}
baseurl=${EUCALYPTUS_MIRROR}
enabled=1
keepcache=0
throttle=1M
max_connections=1
exclude=${REPO_EXCLUDES}
EOF
[ -d "${REPO_DIR}" ] || mkdir -pv "${REPO_DIR}"
reposync \
  --tempcache \
  --newest-only \
  --norepopath \
  --arch=x86_64 \
  --repoid=mirror-${YUM_RAND} \
  --config="${YUM_TEMP}" \
  --download_path="${REPO_DIR}"
if [ ! -z "${REPO_UPDATE}" ] ; then
  echo "Removing old packages from ${REPO_DIR}"
  repomanage \
    --old \
    --nocheck \
    --keep=${REPO_UPDATE_RPM_VERSIONS} \
    "${REPO_DIR}" | xargs -r rm -fv
fi
echo "Building repository metadata"
createrepo "${REPO_DIR}"

# configure httpd
if [ ! -z "${REPO_HTTP_CONF}" ] &&
   [ ! -f "${REPO_HTTP_CONF}" ] &&
   [ -d "$(dirname "${REPO_HTTP_CONF}")" ] ; then
echo "Creating httpd repository configuration ${REPO_HTTP_CONF}"
cat > "${REPO_HTTP_CONF}" <<EOF
Alias /eucalyptus-repos /var/www/eucalyptus-repos

<Directory "/var/www/eucalyptus-repos">
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
if [ ! -z "${REPO_HTTP_CONF}" ] &&
   [ ! -f "${REPO_HTTP_CONF}" ] ; then
  echo "Httpd configuration not created (httpd not installed?)"
fi

# cleanup
rm -f "${YUM_TEMP}"

# done
echo "Repository created in ${REPO_DIR}"
echo "Repository baseurl http://${REPO_IP:-localhost}/eucalyptus-repos/${REPO_PATH}"

