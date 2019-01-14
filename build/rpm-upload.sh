#!/bin/bash
# Upload eucalyptus rpms to bintray

# setup
BINTRAY_API="${BINTRAY_API:-https://api.bintray.com}"
BINTRAY_SUB="${BINTRAY_SUB:-sjones4}"
BINTRAY_RPO="${BINTRAY_RPO:-eucalyptus-devel-4.4}"
BINTRAY_PUB="${BINTRAY_PUB:-0}"
RPM_PACKAGE_JSON=$(mktemp -t package.json.XXXXXXXX)
PACK_DEFAULT_BRANCH="devel-4.4"
PACK_DEFAULT_REPO="sjones4/eucalyptus"

# meta
declare -A PACK_BRANCH_MAP=(
  ["eucaconsole"]="devel-4.4"
  ["eucaconsole-selinux"]="devel-4.4"
  ["eucalyptus-imaging-worker"]="devel-4.4"
  ["eucalyptus-java-deps"]="devel-4.4"
  ["eucalyptus-selinux"]="devel-4.4"
  ["eucalyptus-service-image"]="devel-4.4"
  ["load-balancer-servo"]="devel-4.4"
)
declare -A PACK_REPO_MAP=(
  ["eucaconsole"]="sjones4/eucaconsole"
  ["eucaconsole-selinux"]="sjones4/eucaconsole-selinux"
  ["eucalyptus-imaging-worker"]="sjones4/eucalyptus-imaging-worker"
  ["eucalyptus-java-deps"]="sjones4/eucalyptus-cloud-libs"
  ["eucalyptus-selinux"]="sjones4/eucalyptus-selinux"
  ["eucalyptus-service-image"]="sjones4/eucalyptus-service-image"
  ["load-balancer-servo"]="sjones4/load-balancer-servo"
)

# checks
if [ -z "${BINTRAY_APIKEY}" ] ; then
  echo "BINTRAY_APIKEY key is not defined" >&2
  exit 1
fi

# upload
for RPM in eucalyptus-*.rpm eucanetd-*.rpm eucaconsole-*.rpm load-balancer-servo-*.rpm; do
  [ -f "${RPM}" ] || continue
  RPM_NAME=$(rpm -qip "${RPM}" 2>/dev/null | grep ^Name    | cut -d : -f 2- | xargs echo)
  RPM_DESC=$(rpm -qip "${RPM}" 2>/dev/null | grep ^Summary | cut -d : -f 2- | xargs echo)
  RPM_VERS=$(rpm -qip "${RPM}" 2>/dev/null | grep ^Version | cut -d : -f 2- | xargs echo)
  RPM_REPO="${PACK_REPO_MAP[$RPM_NAME]:-$PACK_DEFAULT_REPO}"
  RPM_BRCH="${PACK_BRANCH_MAP[$RPM_NAME]:-$PACK_DEFAULT_BRANCH}"
  RPM_WURL="https://github.com/${RPM_REPO}/tree/${RPM_BRCH}"
  RPM_VURL="https://github.com/${RPM_REPO}.git"
  RPM_IURL="https://github.com/${RPM_REPO}/issues"
  echo '{ "name": "'${RPM_NAME}'", "desc": "'${RPM_DESC}'", "licenses": ["BSD 2-Clause"], "website_url": "'${RPM_WURL}'", "vcs_url": "'${RPM_VURL}'", "issue_tracker_url": "'${RPM_IURL}'", "github_repo": "'${RPM_REPO}'", "public_download_numbers": true, "public_stats": true }' | json_reformat -m > ${RPM_PACKAGE_JSON}
  # create package metadata if not present
  curl \
    --data @${RPM_PACKAGE_JSON} \
    --user ${BINTRAY_SUB}:${BINTRAY_APIKEY} \
    --header 'Content-Type: application/json' \
    "${BINTRAY_API}/packages/${BINTRAY_SUB}/${BINTRAY_RPO}"
  # upload package version with optional publish
  curl \
    -T ${RPM} \
    --user ${BINTRAY_SUB}:${BINTRAY_APIKEY} \
    "${BINTRAY_API}/content/${BINTRAY_SUB}/${BINTRAY_RPO}/${RPM_NAME}/${RPM_VERS}/${RPM};publish=${BINTRAY_PUB};override=1"
done

# cleanup
rm ${RPM_PACKAGE_JSON}

