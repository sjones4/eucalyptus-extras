#!/bin/bash
# Sign rpms using key from environment

# setup
GPG_KEY=${GPG_KEY:-"not available"}
GPG_KEY_FILE=$(mktemp -t gpg.key.XXXXXXXX)
GPG_KEYS_DIR=$(mktemp -td gpg.home.XXXXXXXX)

# checks
which rpmsign &>/dev/null
if [ $? -ne 0 ]; then
  echo "rpmsign not found (rpm-sign package not installed?)"
  exit 1
fi
if [ -z "${GPG_KEY}" ] ; then
  echo "GPG_KEY is not defined" >&2
  exit 1
fi

# gpg
echo "-----BEGIN PGP PRIVATE KEY BLOCK-----" > "${GPG_KEY_FILE}"
echo "" >> "${GPG_KEY_FILE}"
echo ${GPG_KEY} | sed "s/ /\n/g" >> "${GPG_KEY_FILE}"
echo "-----END PGP PRIVATE KEY BLOCK-----" >> "${GPG_KEY_FILE}"
gpg --homedir "${GPG_KEYS_DIR}" --import "${GPG_KEY_FILE}"
rm "${GPG_KEY_FILE}"

# detect name if possible
if [ -z "${GPG_KEY_NAME}" ] ; then
  GPG_KEY_NAME=$(gpg --homedir "${GPG_KEYS_DIR}" --list-secret-keys | grep uid | head -n 1 | cut -d ' ' -f 2- | xargs echo)
  if [ -z "${GPG_KEY_NAME}" ] ; then
    echo "GPG_KEY_NAME is not defined and detection failed" >&2
    exit 1
  fi
fi

# sign rpms
for RPM in eucalyptus-*.rpm eucanetd-*.rpm eucaconsole-*.rpm load-balancer-servo-*.rpm; do
  [ -f "${RPM}" ] || continue
  echo "" | setsid rpmsign \
    --define "_gpg_path ${GPG_KEYS_DIR}" \
    --define "_gpg_name ${GPG_KEY_NAME}" \
    --addsign \
    --digest-algo=sha256 \
    "${RPM}"
done

# cleanup
[ -z "${GPG_KEYS_DIR}" ] || rm -rf "${GPG_KEYS_DIR}"

