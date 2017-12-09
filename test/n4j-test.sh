#!/bin/bash
# Run nephoria for java (n4j) tests

# local configuration
[ ! -f ~/nephoria-config.sh ] || . ~/nephoria-config.sh
[ ! -f nephoria-config.sh ] || . nephoria-config.sh

# config
CLC_IP="${1:-$CLC_IP}"
NEPHORIA_BASE="${NEPHORIA_BASE:-.}"
N4J_HOME="${NEPHORIA_BASE}/n4j"
N4J_OPTS="-Dorg.gradle.daemon=${N4J_USE_DAEMON:-false} -Dclcip=${CLC_IP} ${N4J_OPTS}"

# test
echo "Running n4j tests using:"
echo "CLC_IP=${CLC_IP}"
sleep 3
if [ -z "${CLC_IP}" ] ; then
  echo "CLC_IP is required but not configured, exiting"
  exit 1
fi

SUCCESS=0
pushd ${N4J_HOME}
./gradlew ${N4J_OPTS} clean test
popd

echo "Exit with code ${SUCCESS}"
exit ${SUCCESS}

