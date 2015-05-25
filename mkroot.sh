#!/usr/bin/env bash

pushd staging
sudo tar cvzpf ../deploy.tar.gz .
popd
