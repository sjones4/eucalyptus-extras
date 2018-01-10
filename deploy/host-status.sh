#!/bin/bash
# Report the reserved status for hosts
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RES_DIR="/root/.reservation"
HOSTS_FILE="${HOSTS_FILE:-hosts.txt}"

HOSTS=""
if [ ! -z "${1:-}" ] ; then
  HOSTS="$@"
else
  if [ -f "${HOSTS_FILE}" ] ; then
    HOSTS=$(<"${HOSTS_FILE}")
  fi
fi

for HOST_PERHAPS_RES in ${HOSTS} ; do
  HOST="${HOST_PERHAPS_RES/_*}"
  echo -n "${HOST} "
  "${SCRIPT_DIR}/host-command.sh" ${HOST} \
    "echo \$(<${RES_DIR}/status) \$(<${RES_DIR}/id) \$(<${RES_DIR}/owner)" 2>/dev/null || echo "unknown"
done

exit 0
