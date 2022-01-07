#!/usr/bin/env bash

cd "${ENV}" || exit

terraform destroy \
  -var-file=../config/"${ENV}"/env.tfvars