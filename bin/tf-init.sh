#!/usr/bin/env bash

cd "${ENV}" || exit

terraform init \
  -backend-config=../config/"${ENV}"/backend.tfvars