#!/usr/bin/env bash

cd "${ENV}" || exit

terraform apply \
  -var-file=../config/"${ENV}"/env.tfvars