terraform {
  backend "gcs" {
    bucket         = "${G_ORG_BUCKET_NAME}"
    prefix         = "terraform/state/${G_PROJECT_ID}"
    credentials    = "${G_TFORM_STORAGE_SA}.json"
  }
}
