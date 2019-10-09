#! /bin/bash
BOOTSTRAP_SALT_CHECKSUM='46fb5e4b7815efafd69fd703f033fe86e7b584b6770f7e0b936995bcae1cedd8'
SALT_VERSION='v2019.2.0'

curl -o bootstrap-salt.sh -L https://bootstrap.saltstack.com
echo "$BOOTSTRAP_SALT_CHECKSUM bootstrap-salt.sh" | sha256sum -c
if [ $? != 0 ]; then
  echo 'bootstrap-salt checksum is not valid'
  exit 1
fi

sh bootstrap-salt.sh git $SALT_VERSION
salt-call state.highstate

