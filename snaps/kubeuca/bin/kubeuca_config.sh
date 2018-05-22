#!/bin/bash
# setup ~/.kube/config file for a rancher kubernetes cluster
set -euo pipefail

[ ! -z "${1:-}" ] || { echo "Usage: kubeuca.config <SERVER_HOST> [<KUBERNETES_CONFIG_FILE>]"; exit 1; }

KUBECONFIGFILE="${2:-${HOME}/.kube/config}"
RANCHERCLUSTER="${RANCHERCLUSTER:-cluster}"
RANCHERHOST="${1##*://}"
RANCHERUSER="${RANCHERUSER:-admin}"
RANCHERPASS="${RANCHERPASS:-password}"

[ ! -f "${KUBECONFIGFILE}" ] || { echo "Configuration file exists (${KUBECONFIGFILE}), delete or specify another location and try again"; exit 1; }
host "${RANCHERHOST}" &>/dev/null || { echo "Invalid rancher server host (${RANCHERHOST}), check the hostname and try again"; exit 1; }

function postAnonJson {
  wget -O - --quiet --no-check-certificate --header "Content-Type: application/json" --post-data "${1}" "${2}"
}

function getJson {
  wget -O - --quiet --no-check-certificate --header "Authorization: Bearer ${LOGINTOKEN}" "${1}"
}

function postJson {
  wget -O - --quiet --no-check-certificate --header "Content-Type: application/json" --header "Authorization: Bearer ${LOGINTOKEN}"  --post-data "${1}" "${2}"
}

LOGINRESPONSE=$(postAnonJson '{"username":"'${RANCHERUSER}'","password":"'${RANCHERPASS}'"}' "https://${RANCHERHOST}/v3-public/localProviders/local?action=login")
LOGINTOKEN=$(jq -r .token <<< "${LOGINRESPONSE}")
RANCHERUSERID=$(jq -r .userId <<< "${LOGINRESPONSE}")

APIRESPONSE=$(postJson '{"type":"token","description":"automation"}' "https://${RANCHERHOST}/v3/token")
APITOKEN=$(jq -r .token <<< "${APIRESPONSE}")

CLUSTERSRESPONSE=$(getJson "https://${RANCHERHOST}/v3/cluster")
CLUSTERID=$(jq -r .data[0].id <<< "${CLUSTERSRESPONSE}")

SETTINGRESPONSE=$(getJson "https://${RANCHERHOST}/v3/settings/cacerts")
CLUSTERCAD=$(echo "${SETTINGRESPONSE}" | jq -r .value | base64 --wrap=0)

KUBECONFIGDIR=$(dirname "${KUBECONFIGFILE}")
[ -d "${KUBECONFIGDIR}" ] || mkdir -p "${KUBECONFIGDIR}"

cat>"${KUBECONFIGFILE}"<<EOF
apiVersion: v1
kind: Config
clusters:
- name: "${RANCHERCLUSTER}"
  cluster:
    server: "https://${RANCHERHOST}/k8s/clusters/${CLUSTERID}"
    api-version: v1
    certificate-authority-data: "${CLUSTERCAD}"

users:
- name: "${RANCHERUSERID}"
  user:
    token: "${APITOKEN}"

contexts:
- name: "${RANCHERCLUSTER}"
  context:
    user: "${RANCHERUSERID}"
    cluster: "${RANCHERCLUSTER}"

current-context: "${RANCHERCLUSTER}"
EOF

echo "Configuration file written ${KUBECONFIGFILE}" >&2
echo "" >&2
echo "For non-default configuration files, use:" >&2
echo "" >&2
echo '  export KUBECONFIG="'$(realpath "${KUBECONFIGFILE}")'"' >&2
echo "" >&2

