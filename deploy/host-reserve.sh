#!/bin/bash
# Reserve hosts from a specified pool respecting resource requirements
#
# Reservations are tracked on the hosts in the pool.
#
# A free host has:
#
#   /root/.reservation/status "free"
#
# A reserved host has:
#
#   /root/.reservation/status "reserved"
#   /root/.reservation/id     <reservationid>
#   /root/.reservation/owner  <email>
#   /root/.reservation/hosts  <reservation host set>
#
# If systems are rebuilt then the reservation owner is responsible for
# save / restore of the reservation directory. Only hosts with status
# "free" can be reserved.
#
# Available hosts and their resources are configured in a file, e.g.:
#
#   10.0.0.1_CPUXXXXXXXX_DISKXX_MEMXXXXXXX
#   10.0.0.2_CPUXXXXXXXX_DISKXX_MEMXXXXXXX
#   10.0.0.3_CPUXXXXXXXX_DISKXX_MEMXXXXXXX
#
# resource parameters and quantities do not have predefined meanings,
# all parameters must be present in a reservation request.
#
# example host resource parameter use:
#
#   CPU  - Available cores  X = 4, XX = 8, XXX = 16, XXXX = 32, ...
#   DISK - Available disk   X = 128G, XX = ?
#   MEM  - Available memory X = 8G, XX = 16G, XXX= 32G, XXXX = 64G ...
#
# an example reservation request for this scheme would be:
#
#   CPUXX:DISKX:MEMXXX.
#
# A unique identifier for the reservation must be supplied by the
# caller.
#
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RES_ID="${1:-}"
HOST_OWNER="${2:-}"
HOST_COUNT="${3:-}"
HOST_PARAMS="${4:-CPUX:DISKX:MEMX}"
HOSTS_FILE="${HOSTS_FILE:-hosts.txt}"
RES_DIR="/root/.reservation"

for PARAM in RES_ID HOST_OWNER HOST_COUNT HOST_PARAMS; do
  if [ -z "${!PARAM}" ] ; then
    echo "Missing require parameter: ${PARAM}"  >&2
    echo "Usage ${0} RES_ID HOST_OWNER HOST_COUNT [HOST_PARAMS] " >&2
    exit 1
  fi
done

if [ ${HOST_COUNT} -lt 1 ] || [ ${HOST_COUNT} -gt 10 ] ; then
  echo "Host count out of range (1-10): ${HOST_COUNT}" >&2
  exit 1
fi

if [ ! -f "${HOSTS_FILE}" ] ; then
  echo "Hosts file not found ${HOSTS_FILE}" >&2
  exit 1
fi

HOSTS=$(<"${HOSTS_FILE}")
if [ -z "${HOSTS}" ] ; then
  echo "No hosts defined in ${HOSTS_FILE}" >&2
  exit 1
fi

HOST_RESOURCE_PATTERN=$(echo ${HOST_PARAMS} | sed 's/:/\n/g' | sort -u | xargs echo | sed 's/ /+_/g')
HOSTS_WITH_REQUIRED_RESOURCES=$(echo "${HOSTS}" | grep -P ${HOST_RESOURCE_PATTERN} || true)
if [ -z "${HOSTS_WITH_REQUIRED_RESOURCES}" ] ; then
  echo "No hosts found with require resources: ${HOST_PARAMS}" >&2
fi

RESERVED_COUNT=0
declare -a RESERVED_HOSTS
for HOST_RES in ${HOSTS_WITH_REQUIRED_RESOURCES} ; do
  HOST=${HOST_RES/_*}
  echo "Checking host ${HOST}" >&2
  { "${SCRIPT_DIR}/host-command.sh" ${HOST} \
         flock "/root/.reservation" bash -c \
         '"cat /root/.reservation/status | grep -q ^free && echo -n reserved > /root/.reservation/status"' \
     && RESERVED_HOSTS[RESERVED_COUNT]="${HOST}" \
     && RESERVED_COUNT=$((RESERVED_COUNT + 1)) ; } || true
  if [ ${RESERVED_COUNT} -ge ${HOST_COUNT} ] ; then
    break
  fi
done

if [ ${RESERVED_COUNT} -ne ${HOST_COUNT} ] ; then
  if [ ${RESERVED_COUNT} -gt 0 ] ; then
    echo "Reserved ${RESERVED_COUNT}/${HOST_COUNT}, releasing hosts" >&2
    for HOST in "${RESERVED_HOSTS[@]}" ; do
      "${SCRIPT_DIR}/host-free.sh" "${HOST}" >&2
    done
  fi
  exit 1
fi

echo "Adding metadata for reserved hosts ${RESERVED_HOSTS[@]}" >&2
for HOST in "${RESERVED_HOSTS[@]}" ; do
  echo "Adding metadata for reserved host ${HOST}" >&2
  "${SCRIPT_DIR}/host-command.sh" ${HOST} \
    "echo -n ${RES_ID} > ${RES_DIR}/id && echo -n ${HOST_OWNER} > ${RES_DIR}/owner && echo -n ${RESERVED_HOSTS[@]} > ${RES_DIR}/hosts" \
    || true
done

echo "${RESERVED_HOSTS[*]}"
