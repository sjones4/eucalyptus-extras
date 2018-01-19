#!/bin/bash
# Get metadata for a template
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TEMP_FILE="${1:--}"
TEMP_INFO="${2:-vars}"
TEMP_ALIAS_FILE="${3:-}"

function template_env( ) {
  "${SCRIPT_DIR}/template-env.sh" ${TEMP_INFO}
}

function template_stream( ) {
  cat "${TEMP_FILE}"
}

function template_variables_filter( ) {
  grep -Pzo 'ETP_[A-Z0-9_]{1,128}' | sed 's/ETP_/\nETP_/g' | grep -a ETP | sort -uV
}

if [ "${TEMP_FILE}" != "-" ] && [ ! -f "${TEMP_FILE}" ] ; then
  echo "Template not found: ${TEMP_FILE}" >&2
  exit 1
fi

if [ "${TEMP_INFO}" = "vars" ] ; then
  template_stream | template_variables_filter
elif [ "${TEMP_INFO}" = "required-vars" ] ; then
  template_stream | template_env | template_variables_filter
elif [ "${TEMP_INFO}" = "host-count" ] ; then
  template_stream | template_variables_filter | grep '^ETP_HOST[0-9]*_IP$' | wc -l
else
  echo "Template info not supported: ${TEMP_INFO}" >&2
  exit 1
fi

exit 0
