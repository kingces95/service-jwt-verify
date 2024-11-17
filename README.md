
# Project: JWT Signature Verification Service

## Introduction

This project implements a lightweight and cost-effective solution to verify JWT signatures in Google Cloud for platforms like Google App Script that do not support cyprtographic operations needed for JWT verification. This service is deployed using Terraform and integrates seamlessly with Google Cloud Function and supporting Google Cloud infrastructure.

## Motivations

The necessity for this project arose from the following:
- A Trello app was developed to handle OAuth tokens but lacked an integrated OAuth library.
- Google Apps Script was used to create an OAuth library with constants stored in a connected Google Sheet.
- The OAuth library lacked cryptographic capabilities to verify JWT signatures, requiring an external service.
- This service provides an efficient way to verify JWT signatures without incurring significant costs.

## Prerequisites

- **Tools Required:**
  - Terraform (for infrastructure as code).
  - Node.js (for managing dependencies and deployment).
  - Google Cloud CLI (`gcloud`) for managing the cloud project.

- **Google Cloud Setup:**
  - A Google Cloud project with a properly configured organization and billing account.
  - Verified domain ownership for the DNS setup.

## Setup Instructions

### Environment Setup

1. Clone this repository to your development environment (e.g., GitHub Codespaces).
2. Study then source the the `init.sh` script.

### `init.sh` Script

This script automates the environment setup by:
  - Defining environment variables.
  - Installing `gcloud`.
  - Initializing and authenticating Google Cloud.
  - Setting up service accounts for Terraform state storage and deployments.
  - Configuring Terraform backend and state management.
  - Uses `envsubst` to transform `package-template.json`, `backend-template.tf`, and `main-template.tf` to their respective non-template versions.
  - Restores packages in `package.json`

## Terraform Deployment

### Structure

- **Main Configuration (`main.tf`)**:
  Defines all resources, including:
  - Cloud Function.
  - Network Endpoint Group (NEG).
  - Backend services, URL map, HTTPS proxy, SSL certificates, etc.

- **Backend Configuration (`backend.tf`)**:
  - Stores the Terraform state in a Google Cloud Storage bucket.

### State Management

- Terraform state is stored in a remote Google Cloud Storage bucket for collaboration.
- State backups are automatically maintained locally.

## Function Deployment

- Package the Google Cloud Function into a `.zip` file using npm scripts.
- Deploy the function via Terraform, ensuring it has the correct permissions.
- Grant anonymous access for external invocation.

## DNS and SSL Configuration

- Manage DNS records to map the service domain to Google Cloud resources.
- Automatically provision a managed SSL certificate through Google Cloud.

## Testing and Verification

- Test the deployed function using:
  - Internal endpoints for direct verification.
  - External endpoints routed through the HTTPS proxy.

- Ensure the SSL certificate is active and the DNS records are correctly configured.

## Development Workflow

1. Update Terraform or function code as needed.
2. Package the function and apply the Terraform configuration.
3. Verify the deployment in staging or production.

## Contribution Guidelines

- Contributions to improve deployment scripts or the function are welcome.
- Adhere to the established coding and documentation standards.

## License

This project is licensed under [appropriate license, e.g., MIT License]. Refer to the `LICENSE` file for more details.

