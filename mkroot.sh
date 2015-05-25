#!/usr/bin/env bash

pushd staging
sudo tar cvzpf ../deploy.tar.gz .
popd
sudo chown jcp:jcp deploy.tar.gz
