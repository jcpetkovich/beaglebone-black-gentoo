#!/usr/bin/env bash

sudo chown root:root -R staging
pushd staging
sudo tar cvzpf ../deploy.tar.gz .
popd
sudo chown jcp:jcp deploy.tar.gz
