#!/usr/bin/env bash

terraform apply \
  -var-file=config/${ENV}/env.tfvars