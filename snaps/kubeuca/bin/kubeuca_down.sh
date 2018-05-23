#!/bin/bash
# script to stop a rancher kubernetes cluster
set -eu

EUCASTACK="${1:-}"

if [ -z "${EUCASTACK}" ] ; then
  STACKCOUNT=$(euform-describe-stacks | grep -c STACK || true)
  if [ ${STACKCOUNT} -lt 1 ] ; then
    echo "No stacks found"
    echo ""
    echo "Usage kubeuca-down [<STACK>]"
    echo ""
    exit 1
  fi
  if [ ${STACKCOUNT} -gt 1 ] ; then
    echo "Multiple stacks founds, please specify which stack to delete"
    echo ""
    echo "Usage kubeuca.down [<STACK>]"
    echo ""
    euform-describe-stacks | grep STACK
    exit 1
  fi
  EUCASTACK=$(euform-describe-stacks | grep STACK | cut -f 2)
fi

echo "Deleting stack ${EUCASTACK}"
euform-delete-stack "${EUCASTACK}"

echo "Stack deletion in progress, this will take a minute..."

