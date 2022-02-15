#!/bin/bash

TERN_VERSION=2.9.1
INSTALL_DIR=$HOME/.tern

echo "Install attr"
apk add attr

echo "Install python"
apk add --no-cache python3 py3-pip

echo "Install Skopeo"
apk add skopeo

echo "Install jq"
apk add jq

echo "Install fuse"
apk add fuse-overlayfs fuse3

echo "create ternenv"
python3 -m venv ternenv

cd ternenv

echo "activate ternenv"
source bin/activate

echo "Upgrade pip"
python3 -m pip install --upgrade pip

echo "-======================================================-"
echo "Install Tern"
pip install tern==2.9.1

tern --version
