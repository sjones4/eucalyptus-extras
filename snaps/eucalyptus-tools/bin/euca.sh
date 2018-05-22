#!/bin/sh
#
# Entry point for euca2ools commands
#
#  as, autoscaling    -> euscale
#  cf, cloudformation -> euform
#  cw, cloudwatch     -> euwatch
#  ec2                -> euca
#  elb                -> eulb
#  iam                -> euare
#  version            -> euca-version
#  *                  -> *
#
set -eu

COMMAND_PREFIX="${1:-}"
COMMAND_NAME="${2:-}"
COMMAND_SHIFT="2"

case "$COMMAND_PREFIX" in
  as|autoscaling)
    COMMAND_PREFIX="euscale"
    ;;
  cf|cloudformation)
    COMMAND_PREFIX="euform"
    ;;
  cw|cloudwatch)
    COMMAND_PREFIX="euwatch"
    ;;
  ec2)
    COMMAND_PREFIX="euca"
    ;;
  elb)
    COMMAND_PREFIX="eulb"
    ;;
  iam)
    COMMAND_PREFIX="euare"
    ;;
  version|--version)
    COMMAND_PREFIX="euca"
    COMMAND_NAME="version"
    COMMAND_SHIFT="1"
    ;;
  help|--help)
    echo "Usage:" >&2
    echo "" >&2
    echo "  euca SERVICE COMMAND [PARAMS]*" >&2
    echo "" >&2
    exit 0
    ;;
esac

if [ -z "${COMMAND_PREFIX}" ] || [ -z "${COMMAND_NAME}" ] ; then
  echo "Usage:" >&2
  echo "" >&2
  echo "  euca SERVICE COMMAND [PARAMS]*" >&2
  echo "" >&2
  exit 1
fi

if [ ! -z "${SNAP_USER_DATA}" ] && \
   [ -d "${SNAP_USER_DATA}/.euca" ] ; then
  export HOME="${SNAP_USER_DATA}"
fi

shift ${COMMAND_SHIFT}
${COMMAND_PREFIX}-${COMMAND_NAME} "${@}"
