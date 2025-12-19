#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Environment variables expected:
# PM_API_TOKEN_ID, PM_API_TOKEN_SECRET, CI_USER, CI_PASSWORD, SSH_KEYS_FILE
# -----------------------------

OUTPUT_FILE="terraform_outputs.json"

cd terraform
echo "[INFO] Initializing Terraform..."
TF_VAR_pm_api_token_id="$PM_API_TOKEN_ID" \
TF_VAR_pm_api_token_secret="$PM_API_TOKEN_SECRET" \
TF_VAR_ciuser="$CI_USER" \
TF_VAR_cipassword="$CI_PASSWORD" \
TF_VAR_ssh_keys_file="$SSH_KEYS_FILE" \
terraform init

echo "[INFO] Applying Terraform configuration..."
TF_VAR_pm_api_token_id="$PM_API_TOKEN_ID" \
TF_VAR_pm_api_token_secret="$PM_API_TOKEN_SECRET" \
TF_VAR_ciuser="$CI_USER" \
TF_VAR_cipassword="$CI_PASSWORD" \
TF_VAR_ssh_keys_file="$SSH_KEYS_FILE" \
terraform apply -auto-approve

echo "[INFO] Saving Terraform outputs to $OUTPUT_FILE..."
terraform output -json > "$OUTPUT_FILE"

echo "[OK] Terraform provisioning complete"


