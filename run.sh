#!/bin/bash

REPO="WLFM-CS/v2ray-mono"

if [ "$EUID" -ne 0 ]; then
  echo "please run as root user: sudo su"
  exit 0
fi

curl -L https://github.com/$REPO/archive/refs/heads/master.tar.gz -o v2ray.tar.gz
tar -xvf v2ray.tar.gz
rm -rf ./v2ray.tar.gz

rm -rf ./v2ray-install
mv "./$(cut -d'/' -f2 <<<"$REPO")-master" ./v2ray-install
cd ./v2ray-install || exit
chmod +x ./install.sh

./install.sh "$@"

cd ../
rm -rf ./v2ray-install
