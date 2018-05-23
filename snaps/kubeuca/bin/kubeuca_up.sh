#!/bin/bash
# script to start a rancher kubernetes cluster
set -eu

EUCAKEYPAIR="${1:-}"
RANCHERCLUSTERSIZE="${2:-1}"
RANCHERIMAGE="${RANCHERIMAGE:-}"
RANCHERHOSTTYPE="${RANCHERHOSTTYPE:-m3.2xlarge}"
RANCHERSERVERTYPE="${RANCHERSERVERTYPE:-m3.2xlarge}"
EUCAACCOUNT="$(euare-getcallerid | grep 'account = ' | cut -d ' ' -f 3)"

if [ -z "${RANCHERIMAGE}" ] ; then
  RANCHERIMAGE="$(euca-describe-images -a \
                    --filter name='rancheros*1*3*' \
                    --filter is-public=true \
                    --filter image-type=machine | head -n 1 | cut -f 2)"
fi
if [ -z "${RANCHERIMAGE}" ] ; then
  echo "RancherOS 1.3 image not found"
  echo "Available images are:"
  euca-describe-images -a
  exit 1
fi

if [ -z "${EUCAKEYPAIR}" ] ; then
  EUCAKEYPAIR="$(euca-describe-keypairs | head -n 1 | cut -f 2)"
fi
if [ -z "$(euca-describe-keypairs ${EUCAKEYPAIR})" ] ; then
  echo "Keypair not found ${EUCAKEYPAIR:-<NONE>}"
  echo ""
  echo "Usage kubeuca.up [<KEYPAIR> [<CLUSTER_HOSTS>]]"
  echo ""
  echo "Available keypairs are:"
  euca-describe-keypairs
  exit 1
fi

echo "Creating stack"
euform-create-stack \
  --template-file ${SNAP}/templates/rancher-kubernetes-template.json \
  -p ClusterHostCount=${RANCHERCLUSTERSIZE} \
  -p ClusterInstanceType=${RANCHERHOSTTYPE} \
  -p ImageId=${RANCHERIMAGE} \
  -p KeyName=${EUCAKEYPAIR} \
  -p ServerInstanceType=${RANCHERSERVERTYPE} \
  rancher-kubernetes-${EUCAACCOUNT}-$RANDOM

echo "For credentials to access kubernetes, see kubeuca-config"
echo ""
echo "To check on stack creation run:"
echo ""
echo "  euform-describe-stacks"
echo ""
echo "Stack creation in progress come back in 15 minutes..."
echo ""

