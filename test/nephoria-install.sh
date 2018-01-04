#!/bin/bash
# Install nephoria and n4j on RHEL/CentOS 7 for testing a 4.4 cloud

# local configuration
[ ! -f ~/nephoria-config.sh ] || . ~/nephoria-config.sh
[ ! -f nephoria-config.sh ] || . nephoria-config.sh

# config
NEPHORIA_BASE="${1:-$NEPHORIA_BASE}"
if [ -z "${NEPHORIA_BASE}" ] ; then
  NEPHORIA_BASE="."
fi

# install
echo "Installing nephoria and n4j test suites under ${NEPHORIA_BASE}"
sleep 3

echo "Installing required rpms"
set -ex

sudo -n yum install -y \
  gcc git java-1.8.0-openjdk-devel libffi-devel openssl-devel patch \
  python-devel python-setuptools python-virtualenv readline-devel \
  libyaml

pushd "${NEPHORIA_BASE}"

echo "Setting up virtualenv"
virtualenv nephoria-env
. nephoria-env/bin/activate
pip install --upgrade pip
pip install --upgrade setuptools

echo "Installing adminapi"
git clone --depth 1 https://github.com/eucalyptus/adminapi.git
pushd adminapi
python setup.py install
popd

echo "Installing nephoria"
git clone --depth 1 https://github.com/eucalyptus/nephoria.git
pushd nephoria
python setup.py install
popd

echo "Installing n4j"
git clone --depth 1 --branch devel-4.4 https://github.com/sjones4/n4j.git

popd

