#!/bin/bash

# Paths
export PROJ_DIR="/workspaces/$(basename "$PWD")"
export SRC_DIR="$PROJ_DIR/src"
export INFRA_DIR="$PROJ_DIR/infra"
export TERRA_DIR="$PROJ_DIR/terraform"
export BIN_DIR="$PROJ_DIR/bin"
export TEST_DIR="$PROJ_DIR/tests"
export KEYS_DIR="$TEST_DIR/keys"
export JWTS_DIR="$TEST_DIR/jwts"
export SCRIPTS_DIR="$TEST_DIR/scripts"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
  echo "Installing Google Cloud SDK quietly..."
  curl -sSL https://sdk.cloud.google.com | bash -s -- --quiet
  exec -l $SHELL
  gcloud init --quiet
  echo "Google Cloud SDK installed and initialized."
fi

# Check if gcloud is authorized
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
  echo "No active gcloud account found. Please log in using 'gcloud auth login'."
  gcloud auth login
fi

# Check if application-default credentials are configured
if ! gcloud auth application-default print-access-token &> /dev/null; then
  echo "Application-default credentials are not configured. Running 'gcloud auth application-default login'..."
  gcloud auth application-default login
fi

# Google Cloud Environment
export G_PROJECT_ID="$(gcloud config get-value project)"
export G_PROJECT_NAME="$(gcloud projects describe ${G_PROJECT_ID} --format="value(name)")"
export G_ORG_ID="$(gcloud projects get-ancestors ${G_PROJECT_ID} --format="value(id)" | awk 'NR==2')"
export G_ORG_NAME="$(gcloud organizations describe ${G_ORG_ID} --format="value(displayName)")"
export G_REGION="$(gcloud config get-value compute/region || echo "us-central1")"
export G_ORG_DOMAIN="${G_ORG_NAME}"
export G_SUBDOMAIN="service"

export G_RUNTIME="nodejs18"
export G_FUNCTION_NAME="verifyJwtSignature"
export G_URL_PATH_MATCHER="${G_FUNCTION_NAME}"
export G_DOMAIN="${G_SUBDOMAIN}.${G_ORG_DOMAIN}"
export G_ORG_BUCKET_NAME="${G_ORG_DOMAIN}"
export G_ORG_BUCKET_URL="gs://${G_ORG_BUCKET_NAME}"
export G_ARCHIVE_NAME="${G_FUNCTION_NAME}-gcf"
export G_ARCHIVE_OBJECT="${G_ARCHIVE_NAME}.zip"
export G_ARCHIVE_URL="${G_ORG_BUCKET_URL}/${G_ARCHIVE_OBJECT}"
export G_TFORM_STORAGE_SA="terraform-storage-sa"
export G_TFORM_DEPLOYMENT_SA="terraform-deploy-sa"

# Set gcloud configuration
gcloud config set project ${G_PROJECT_ID} --quiet &> /dev/null
gcloud config set compute/region ${G_REGION} --quiet &> /dev/null

export G_CLOUD_DNS_ZONE="$(gcloud dns managed-zones list --format="value(name)" --quiet || echo "service-zone")"
export G_CLOUD_FUNCTION_NAME="verify-jwt-signature"
export G_CLOUD_DEPLOYMENT_NAME="${G_CLOUD_FUNCTION_NAME}-deployment"
export G_CLOUD_FUNCTION_NAME="${G_CLOUD_FUNCTION_NAME}-function"
export G_CLOUD_NEG_NAME="${G_CLOUD_FUNCTION_NAME}-neg"
export G_CLOUD_BACKEND_SERVICE_NAME="${G_CLOUD_FUNCTION_NAME}-backend-service"
export G_CLOUD_BLACKHOLE_BACKEND_SERVICE_NAME="blackhole-backend-service"
export G_CLOUD_URL_MAP_NAME="${G_SUBDOMAIN}-url-map"
export G_CLOUD_HTTPS_PROXY_NAME="${G_SUBDOMAIN}-https-proxy"
export G_CLOUD_SSL_CERT_NAME="${G_SUBDOMAIN}-ssl-cert"
export G_CLOUD_FORWARDING_RULE_NAME="${G_SUBDOMAIN}-forwarding-rule"

# TFORM variables, replacing '-' with '_'
export TFORM_FUNCTION_NAME="${G_CLOUD_FUNCTION_NAME//-/_}"
export TFORM_FUNCTION_IAM_NAME="${TFORM_FUNCTION_NAME}_iam"
export TFORM_NEG_NAME="${G_CLOUD_NEG_NAME//-/_}"
export TFORM_BACKEND_SERVICE_NAME="${G_CLOUD_BACKEND_SERVICE_NAME//-/_}"
export TFORM_BLACKHOLE_BACKEND_SERVICE_NAME="${G_CLOUD_BLACKHOLE_BACKEND_SERVICE_NAME//-/_}"
export TFORM_URL_MAP_NAME="${G_CLOUD_URL_MAP_NAME//-/_}"
export TFORM_HTTPS_PROXY_NAME="${G_CLOUD_HTTPS_PROXY_NAME//-/_}"
export TFORM_SSL_CERT_NAME="${G_CLOUD_SSL_CERT_NAME//-/_}"
export TFORM_FORWARDING_RULE_NAME="${G_CLOUD_FORWARDING_RULE_NAME//-/_}"
export TFORM_DNS_RECORD_NAME="service_dns_record"
export TFORM_STATIC_IP_NAME="service_static_ip"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
  echo "Terraform not found. Installing..."
  
  # Create a temporary directory
  TMP_DIR=$(mktemp -d)
  
  # Fetch the latest version of Terraform
  LATEST_VERSION=$(curl -fsSL https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/^v//')
  ZIP_URL="https://releases.hashicorp.com/terraform/${LATEST_VERSION}/terraform_${LATEST_VERSION}_linux_amd64.zip"
  
  echo "Downloading Terraform ${LATEST_VERSION}..."
  curl -fsSL "${ZIP_URL}" -o "${TMP_DIR}/terraform.zip"
  
  # Unzip and move to /usr/local/bin
  echo "Extracting Terraform..."
  unzip -q "${TMP_DIR}/terraform.zip" -d "${TMP_DIR}"
  
  echo "Installing Terraform to /usr/local/bin..."
  sudo mv "${TMP_DIR}/terraform" /usr/local/bin/
  sudo chmod +x /usr/local/bin/terraform
  
  # Clean up the temporary directory
  echo "Cleaning up..."
  rm -rf "${TMP_DIR}"
  
  echo "Terraform installed successfully."
fi

# Function to check and create a service account
create_service_account() {
  local sa_name=$1
  local sa_display_name=$2
  local roles=$3
  local key_file="$TERRA_DIR/${sa_name}.json"

  if [ -f "$key_file" ]; then
    return
  fi

  echo "Creating service account $sa_name..."
  gcloud iam service-accounts create $sa_name --display-name="$sa_display_name" --quiet
  gcloud projects add-iam-policy-binding $G_PROJECT_ID \
    --member="serviceAccount:${sa_name}@${G_PROJECT_ID}.iam.gserviceaccount.com" \
    --role=$roles --quiet
  gcloud iam service-accounts keys create "$key_file" \
    --iam-account="${sa_name}@${G_PROJECT_ID}.iam.gserviceaccount.com" --quiet
}

# Create Terraform storage service account
create_service_account $G_TFORM_STORAGE_SA "Terraform Storage Account" "roles/storage.admin"

# Create Terraform deployment service account
create_service_account $G_TFORM_DEPLOYMENT_SA "Terraform Deployment Account" "roles/editor"

# Check if the local backup exists
if [ ! -f "${TERRA_DIR}/terraform.tfstate.backup" ]; then
  echo "Local terraform.tfstate.backup is missing. Attempting to restore from GCS..."
  
  # Check if the remote state file exists in the GCS bucket
  if gsutil -q stat "${G_ORG_BUCKET_URL}/terraform/terraform.tfstate"; then
    echo "Found remote state file in GCS. Restoring backup locally..."
    
    # Pull the remote state file and save as backup
    gsutil cp "${G_ORG_BUCKET_URL}/terraform/terraform.tfstate" "${TERRA_DIR}/terraform.tfstate.backup"
    echo "Backup restored to ${TERRA_DIR}/terraform.tfstate.backup"
  else
    echo "No remote state file found in GCS. Cannot restore backup."
    echo "Ensure the state file exists remotely or initialize Terraform fresh."
  fi
fi

# Populate templates
envsubst < ${PROJ_DIR}/package-template.json > ${PROJ_DIR}/package.json
envsubst < ${INFRA_DIR}/main-template.tf > ${TERRA_DIR}/main.tf
envsubst < ${INFRA_DIR}/backend-template.tf > ${TERRA_DIR}/backend.tf

# Install npm dependencies
npm install --no-package-lock --silent

# Package app
npm run pack-ls --silent > .package

