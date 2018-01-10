#!/bin/bash
# Free a reserved host
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "--initialize" == "${1:-}" ] ; then
  shift
  for HOST in "$@" ; do
    "${SCRIPT_DIR}/host-command.sh" ${HOST} \
      'rm -fv "/root/.reservation"; mkdir "/root/.reservation"' || true
  done
fi

for HOST in "$@" ; do
  "${SCRIPT_DIR}/host-command.sh" ${HOST} \
    flock "/root/.reservation" bash -c \
    '"{ rm -f /root/.reservation/* || true ; } && echo -n free > /root/.reservation/status"' || \
      echo "Failed to free ${HOST}"
done

exit 0
