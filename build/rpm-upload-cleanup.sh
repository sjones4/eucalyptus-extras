#!/bin/bash
# Remove outdated eucalyptus rpms from bintray

# setup
BINTRAY_API="${BINTRAY_API:-https://api.bintray.com}"
BINTRAY_SUB="${BINTRAY_SUB:-sjones4}"
BINTRAY_RPO="${BINTRAY_RPO:-eucalyptus-devel-5}"

# checks
if [ -z "${BINTRAY_APIKEY}" ] ; then
  echo "BINTRAY_APIKEY key is not defined" >&2
  exit 1
fi

# find packages
PACKAGES=$(curl \
  --user ${BINTRAY_SUB}:${BINTRAY_APIKEY} \
  "${BINTRAY_API}/repos/${BINTRAY_SUB}/${BINTRAY_RPO}/packages" \
  2>/dev/null | \
  json_reformat | grep '"name":' | cut -d '"' -f 4 )

# cleanup
for PACKAGE in ${PACKAGES}; do
  echo "Processing package ${PACKAGE}"
  PACKAGE_FILES=$(curl \
    --user ${BINTRAY_SUB}:${BINTRAY_APIKEY} \
    "${BINTRAY_API}/packages/${BINTRAY_SUB}/${BINTRAY_RPO}/${PACKAGE}/files" \
    2>/dev/null | \
    json_reformat | grep '"name":' | cut -d '"' -f 4 | grep '.rpm$' | tail -n +2 )
  for PACKAGE_FILE in ${PACKAGE_FILES}; do
    echo "Deleting package ${PACKAGE} file ${PACKAGE_FILE}"
    curl \
      --user ${BINTRAY_SUB}:${BINTRAY_APIKEY} \
      --request DELETE \
      "${BINTRAY_API}/content/${BINTRAY_SUB}/${BINTRAY_RPO}/${PACKAGE_FILE}"
    echo ""
    echo "Deleting package ${PACKAGE} file ${PACKAGE_FILE}.asc"
    curl \
      --user ${BINTRAY_SUB}:${BINTRAY_APIKEY} \
      --request DELETE \
      "${BINTRAY_API}/content/${BINTRAY_SUB}/${BINTRAY_RPO}/${PACKAGE_FILE}.asc"
    echo ""
  done
done

