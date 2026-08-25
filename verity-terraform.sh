#!/usr/bin/env bash

set -euo pipefail

TERRAFORM_DIR="${1:-./terraform}"

echo "Verifying Terraform in: ${TERRAFORM_DIR}"

if ! command -v terraform >/dev/null 2>&1; then
    echo "ERROR: terraform is not installed or not in PATH"
    exit 1
fi

if [ ! -d "${TERRAFORM_DIR}" ]; then
    echo "ERROR: Terraform directory does not exist: ${TERRAFORM_DIR}"
    exit 1
fi

cd "${TERRAFORM_DIR}"

echo
echo "== Terraform version =="
terraform version

echo
echo "== Formatting =="
terraform fmt -check -recursive

echo
echo "== Initialization =="
terraform init \
    -backend=false \
    -input=false \
    -lockfile=readonly

echo
echo "== Validation =="
terraform validate

echo
echo "Terraform verification SUCCESS"
