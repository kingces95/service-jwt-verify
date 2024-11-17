#!/bin/bash

# Environment Variables
export G_PROJECT_ID="your-project-id" # Replace with your Google Cloud project ID
export G_BUCKET_NAME="your-bucket-name" # Replace with your Terraform state bucket
export G_TFORM_STORAGE_SA="terraform-storage-sa"  # Service account for storage
export G_TFORM_DEPLOYMENT_SA="terraform-deploy-sa" # Service account for deployments

# Create Service Account for Terraform Storage
echo "Creating service account for Terraform storage..."
gcloud iam service-accounts create $G_TFORM_STORAGE_SA \
  --description="Service account for managing Terraform state storage" \
  --display-name="Terraform Storage Service Account" \
  --project=$G_PROJECT_ID

# Grant Storage Admin Permissions
echo "Granting storage admin permissions to the service account..."
gcloud storage buckets add-iam-policy-binding $G_BUCKET_NAME \
  --member="serviceAccount:$G_TFORM_STORAGE_SA@$G_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.admin" \
  --project=$G_PROJECT_ID

# Generate Key for Terraform Storage Service Account
echo "Generating key for Terraform storage service account..."
gcloud iam service-accounts keys create terraform-storage-sa-key.json \
  --iam-account="$G_TFORM_STORAGE_SA@$G_PROJECT_ID.iam.gserviceaccount.com" \
  --project=$G_PROJECT_ID

# Create Service Account for Terraform Deployment
echo "Creating service account for Terraform deployment..."
gcloud iam service-accounts create $G_TFORM_DEPLOYMENT_SA \
  --description="Service account for managing Terraform deployments" \
  --display-name="Terraform Deployment Service Account" \
  --project=$G_PROJECT_ID

# Grant Editor Role for Terraform Deployment
echo "Granting editor role to the deployment service account..."
gcloud projects add-iam-policy-binding $G_PROJECT_ID \
  --member="serviceAccount:$G_TFORM_DEPLOYMENT_SA@$G_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor" \
  --project=$G_PROJECT_ID

# Generate Key for Terraform Deployment Service Account
echo "Generating key for Terraform deployment service account..."
gcloud iam service-accounts keys create terraform-deploy-sa-key.json \
  --iam-account="$G_TFORM_DEPLOYMENT_SA@$G_PROJECT_ID.iam.gserviceaccount.com" \
  --project=$G_PROJECT_ID

# Verify Permissions for Service Accounts
echo "Verifying permissions for service accounts..."
gcloud iam service-accounts get-iam-policy \
  "$G_TFORM_STORAGE_SA@$G_PROJECT_ID.iam.gserviceaccount.com" \
  --project=$G_PROJECT_ID

gcloud iam service-accounts get-iam-policy \
  "$G_TFORM_DEPLOYMENT_SA@$G_PROJECT_ID.iam.gserviceaccount.com" \
  --project=$G_PROJECT_ID

echo "Service account creation and configuration complete. Keys generated:"
echo " - terraform-storage-sa-key.json (for storage)"
echo " - terraform-deploy-sa-key.json (for deployments)"
echo "Store these keys securely and configure your Terraform environment accordingly."
