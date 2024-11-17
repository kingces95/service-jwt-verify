gsutil mb -l ${G_REGION} gs://${G_ORG_NAME}
gsutil cp ./bin/package.zip gs://${G_ORG_NAME}
gsutil ls gs://${G_ORG_NAME}
gsutil rm gs://${G_ORG_NAME}/package.zip

gcloud functions deploy ${G_FUNCTION_NAME} \
  --region=${G_REGION} \
  --stage-bucket=${G_ORG_BUCKET_URL} \
  --entry-point=${G_FUNCTION_NAME} \
  --source=./src \
  --runtime=${G_RUNTIME} \
  --trigger-http \
  --gen2
gcloud functions list
gcloud functions describe ${G_FUNCTION_NAME}
gcloud functions delete ${G_FUNCTION_NAME} --quiet

# Define asset types as an array
ASSET_TYPES_LIST=(
  "compute.googleapis.com/Instance"
  "compute.googleapis.com/Address"
  #"compute.googleapis.com/Firewall"
  "compute.googleapis.com/ForwardingRule"
  #"compute.googleapis.com/Network"
  #"compute.googleapis.com/Subnetwork"
  "compute.googleapis.com/Router"
  "compute.googleapis.com/BackendService"
  "compute.googleapis.com/TargetHttpProxy"
  "compute.googleapis.com/TargetHttpsProxy"
  "compute.googleapis.com/UrlMap"
  "compute.googleapis.com/SslCertificate"
  "compute.googleapis.com/NetworkEndpointGroup"
  "cloudfunctions.googleapis.com/CloudFunction"
)

# Join the array into a comma-separated string
ASSET_TYPES=$(IFS=, ; echo "${ASSET_TYPES_LIST[*]}")

gcloud asset search-all-resources \
    --scope=projects/${G_PROJECT_ID} \
    --asset-types="$ASSET_TYPES" \
    --format="table(assetType, name, project)"

curl -fsSL https://releases.hashicorp.com/terraform/$(curl -fsSL https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/^v//')/terraform_$(curl -fsSL https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/^v//')_linux_amd64.zip -o terraform.zip
unzip terraform.zip
sudo mv terraform /usr/local/bin/
terraform --version
terraform init

gcloud auth login
gcloud auth application-default login
