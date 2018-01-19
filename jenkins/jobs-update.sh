#!/bin/bash
# Update jobs on jenkins via cli
set -euo pipefail

JENKINS_SERVER="${1:-}"
JENKINS_OPTS=${JENKINS_OPTS:-}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${JENKINS_SERVER}" ] ; then
  echo "Usage: ${0} JENKINS_URI" >&2
  exit 1
fi

JENKINS_JAR_TEMP=$(mktemp -t jenkins-cli.jar.XXXXXXXX)
function cleanup {
  [ ! -f "${JENKINS_JAR_TEMP}" ] || rm -f "${JENKINS_JAR_TEMP}"
}
trap cleanup EXIT

echo "Downloading CLI JAR"
curl --insecure \
  --output "${JENKINS_JAR_TEMP}" \
  "${JENKINS_SERVER}/jnlpJars/jenkins-cli.jar"

for JOB_CONFIG in ${SCRIPT_DIR}/*/config.xml; do
  JOB_NAME="${JOB_CONFIG##${SCRIPT_DIR}/}"
  JOB_NAME="${JOB_NAME%%/config.xml}"
  java -jar "${JENKINS_JAR_TEMP}" \
    ${JENKINS_OPTS} \
    -s "${JENKINS_SERVER}" \
    update-job \
    ${JOB_NAME} < "${JOB_CONFIG}"
done

