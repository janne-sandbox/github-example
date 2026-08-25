
```bash
#!/usr/bin/env bash

set -euo pipefail

TERRAFORM_DIR="${1:-./terraform}"
FORMULA="hashicorp/tap/terraform"

echo "========================================"
echo " Terraform macOS setup"
echo "========================================"
echo

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "ERROR: This script is intended for macOS."
    exit 1
fi

# ------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------

if ! command -v brew >/dev/null 2>&1; then
    echo "ERROR: Homebrew is required."
    echo
    echo "Install Homebrew first:"
    echo
    echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
fi

echo "== Homebrew =="

brew tap hashicorp/tap >/dev/null

# ------------------------------------------------------------
# Terraform installation
# ------------------------------------------------------------

if ! command -v terraform >/dev/null 2>&1; then
    echo
    echo "Terraform is not installed."
    echo "Installing ${FORMULA}..."
    echo

    brew install "${FORMULA}"
else
    echo
    echo "Terraform is already installed:"
    terraform version | head -1
fi

# ------------------------------------------------------------
# Terraform upgrade
# ------------------------------------------------------------

echo
echo "== Checking for Terraform upgrade =="

brew update >/dev/null

if brew outdated "${FORMULA}" >/dev/null 2>&1; then

    OUTDATED="$(brew outdated "${FORMULA}" || true)"

    if [[ -n "${OUTDATED}" ]]; then
        echo
        echo "A newer Terraform version is available:"
        echo
        echo "${OUTDATED}"
        echo

        read -r -p "Upgrade Terraform now? [y/N] " ANSWER

        case "${ANSWER}" in
            y|Y|yes|YES)
                echo
                echo "Upgrading Terraform..."
                brew upgrade "${FORMULA}"
                ;;
            *)
                echo "Terraform upgrade skipped."
                ;;
        esac
    else
        echo "Terraform is up to date."
    fi
else
    echo "Terraform is up to date."
fi

# ------------------------------------------------------------
# Locate Terraform
# ------------------------------------------------------------

TERRAFORM_BIN="$(command -v terraform)"

echo
echo "== Terraform binary =="
echo "${TERRAFORM_BIN}"

# Resolve Homebrew symlink if possible.
REAL_TERRAFORM_BIN="$(realpath "${TERRAFORM_BIN}" 2>/dev/null || echo "${TERRAFORM_BIN}")"

echo "Resolved binary:"
echo "${REAL_TERRAFORM_BIN}"

# ------------------------------------------------------------
# Remove macOS quarantine
# ------------------------------------------------------------

echo
echo "== macOS quarantine =="

if xattr "${REAL_TERRAFORM_BIN}" 2>/dev/null | grep -q '^com.apple.quarantine$'; then
    echo "Terraform is quarantined by macOS."
    echo "Removing quarantine attribute..."

    if ! xattr -d com.apple.quarantine "${REAL_TERRAFORM_BIN}" 2>/dev/null; then
        echo "Normal removal failed; trying with sudo..."
        sudo xattr -d com.apple.quarantine "${REAL_TERRAFORM_BIN}"
    fi

    echo "Terraform quarantine removed."
else
    echo "Terraform is not quarantined."
fi

# Homebrew may have Terraform inside a directory carrying quarantine.
TERRAFORM_CELLAR_DIR="$(dirname "${REAL_TERRAFORM_BIN}")"

if xattr "${TERRAFORM_CELLAR_DIR}" 2>/dev/null | grep -q '^com.apple.quarantine$'; then
    echo "Removing quarantine from Terraform installation directory..."

    if ! xattr -dr com.apple.quarantine "${TERRAFORM_CELLAR_DIR}" 2>/dev/null; then
        sudo xattr -dr com.apple.quarantine "${TERRAFORM_CELLAR_DIR}"
    fi
fi

# ------------------------------------------------------------
# Verify Terraform executable
# ------------------------------------------------------------

echo
echo "== Terraform version =="

terraform version

# ------------------------------------------------------------
# Terraform project
# ------------------------------------------------------------

echo
echo "== Terraform project =="

if [[ ! -d "${TERRAFORM_DIR}" ]]; then
    echo "ERROR: Terraform directory does not exist:"
    echo "  ${TERRAFORM_DIR}"
    exit 1
fi

cd "${TERRAFORM_DIR}"

if ! find . -maxdepth 1 -name '*.tf' -print -quit | grep -q .; then
    echo "ERROR: No .tf files found in:"
    pwd
    exit 1
fi

echo "Terraform directory:"
pwd

# ------------------------------------------------------------
# Detect Mac architecture
# ------------------------------------------------------------

ARCH="$(uname -m)"

case "${ARCH}" in
    arm64)
        MAC_PLATFORM="darwin_arm64"
        ;;
    x86_64)
        MAC_PLATFORM="darwin_amd64"
        ;;
    *)
        echo "ERROR: Unsupported macOS architecture: ${ARCH}"
        exit 1
        ;;
esac

echo
echo "Detected platform: ${MAC_PLATFORM}"

# ------------------------------------------------------------
# Clean provider installation
# ------------------------------------------------------------

echo
echo "== Cleaning Terraform provider cache =="

if [[ -d ".terraform" ]]; then
    echo "Removing existing .terraform directory..."
    rm -rf .terraform
fi

# ------------------------------------------------------------
# Repair dependency lock file
# ------------------------------------------------------------

echo
echo "== Updating Terraform provider lock file =="

#
# Include:
#
#   - current macOS architecture
#   - Intel macOS, useful if repository is shared
#   - Apple Silicon
#   - Linux AMD64, commonly used by CI/CD
#
# terraform providers lock downloads official provider checksum
# information from the provider registry.
#

terraform providers lock \
    -platform=darwin_arm64 \
    -platform=darwin_amd64 \
    -platform=linux_amd64

# ------------------------------------------------------------
# Initialize Terraform
# ------------------------------------------------------------

echo
echo "== Initializing Terraform =="

terraform init \
    -backend=false \
    -input=false \
    -lockfile=readonly \
    -upgrade=false

# ------------------------------------------------------------
# Formatting
# ------------------------------------------------------------

echo
echo "== Checking formatting =="

if ! terraform fmt -check -recursive; then
    echo
    echo "Terraform formatting is incorrect."
    echo
    echo "Fixing formatting automatically..."
    terraform fmt -recursive
fi

# ------------------------------------------------------------
# Validation
# ------------------------------------------------------------

echo
echo "== Validation =="

terraform validate

# ------------------------------------------------------------
# Final result
# ------------------------------------------------------------

echo
echo "========================================"
echo " Terraform installation SUCCESS"
echo "========================================"
echo
echo "Terraform:"
terraform version | head -1

echo
echo "Platform:"
echo "  ${MAC_PLATFORM}"

echo
echo "Terraform directory:"
pwd

echo
echo "Provider dependency lock:"
echo "  .terraform.lock.hcl"

echo
echo "Provider cache:"
echo "  .terraform/providers"

echo
echo "Validation:"
echo "  SUCCESS"
```

