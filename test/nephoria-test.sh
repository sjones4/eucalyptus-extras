#!/bin/bash
# Run nephoria tests

# local configuration
[ ! -f ~/nephoria-config.sh ] || . ~/nephoria-config.sh
[ ! -f nephoria-config.sh ] || . nephoria-config.sh

# config
CLC_IP="${1:-$CLC_IP}"
IMAGE_BASE_URL="${IMAGE_BASE_URL:-set in nephoria-config.sh}"
NEPHORIA_TESTCASE_MODULE="nephoria.testcases"
NEPHORIA_RESULTS_BASE="$(pwd)/nephoria_results"
NEPHORIA_OPTS="--clc ${CLC_IP} ${NEPHORIA_OPTS}"
NEPHORIA_TESTCASES=(
  "ec2.images.load_hvm_image --image-url ${IMAGE_BASE_URL}/precise-server-cloudimg-amd64-disk1.img"
  "ec2.images.load_pv_image --kernel-image-url ${IMAGE_BASE_URL}/vmlinuz-3.2.0-23-virtual --ramdisk-image-url ${IMAGE_BASE_URL}/initrd.img-3.2.0-23-virtual --disk-image-url ${IMAGE_BASE_URL}/precise-server-cloudimg-amd64-ext3.img"
  "ec2.network.net_tests_classic"
  "ec2.images.load_bfebs_image --image-url ${IMAGE_BASE_URL}/precise-server-cloudimg-amd64-disk1.img"
  "ec2.ebs.block_dev_map_suite --url ${IMAGE_BASE_URL}/precise-server-cloudimg-amd64-disk1.img"
  "ec2.ebs.legacy_ebs_test_suite"
  "ec2.images.import_instance --no-https --image-url ${IMAGE_BASE_URL}/precise-server-cloudimg-amd64-disk1.img"
  "ec2.images.import_instance --no-https --imageformat vmdk --image-url ${IMAGE_BASE_URL}/ubuntu_trusty.vmdk"
  "admintests.instance_migration"
)

# setup
set -o pipefail

# test
echo "Running nephoria tests using:"
echo "CLC_IP=${CLC_IP}"
echo "IMAGE_BASE_URL=${IMAGE_BASE_URL}"
sleep 3
if [ -z "${CLC_IP}" ] ; then
  echo "CLC_IP is required but not configured, exiting"
  exit 1
fi

if [ ! -d "${NEPHORIA_RESULTS_BASE}" ] ; then
  echo "Creating results directory ${NEPHORIA_RESULTS_BASE}"
  mkdir -p "${NEPHORIA_RESULTS_BASE}"
else
  echo "Deleting previous results from ${NEPHORIA_RESULTS_BASE}"
  rm -v "${NEPHORIA_RESULTS_BASE}"/*.log
fi

SUCCESS=0
COUNT=1
TOTAL=${#NEPHORIA_TESTCASES[@]}
for NEPHORIA_TESTCASE in "${NEPHORIA_TESTCASES[@]}"; do
  TESTCASE_SCRIPT_PATH=${NEPHORIA_TESTCASE/ *}
  TESTCASE_SCRIPT=$(basename "${TESTCASE_SCRIPT_PATH}")
  TESTCASE_RESULT="${TESTCASE_SCRIPT_PATH}"
  echo "Running test case ${TESTCASE_SCRIPT}, logging to ${COUNT}_${TESTCASE_RESULT}.log [${COUNT}/${TOTAL}]"
  sleep 3
  python -m ${NEPHORIA_TESTCASE_MODULE}.${NEPHORIA_TESTCASE} ${NEPHORIA_OPTS} 2>&1 | tee "${NEPHORIA_RESULTS_BASE}/${COUNT}_${TESTCASE_RESULT}.log"
  if [ $? -ne 0 ] ; then
    SUCCESS=1
  fi
  COUNT=$((COUNT+1))
done

# dump results summaries
grep -A 1000 -B 1 'TEST RESULTS FOR' "${NEPHORIA_RESULTS_BASE}"/*.log

echo "Exit with code ${SUCCESS}"
exit ${SUCCESS}
