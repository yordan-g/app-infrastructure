#!/usr/bin/env bash

terraform init \
  -backend-config=config/${ENV}/backend.tfvars