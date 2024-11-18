# Cloud Function
provider "google" {
  credentials = "${G_TFORM_DEPLOYMENT_SA}.json"
  project     = "${G_PROJECT_ID}"
  region      = "${G_REGION}"
}

# Cloud Function
resource "google_cloudfunctions_function" "${TFORM_FUNCTION_NAME}" {
  project                = "${G_PROJECT_ID}"
  name                   = "${G_CLOUD_FUNCTION_NAME}"
  description            = "Cloud Function for ${G_CLOUD_FUNCTION_NAME}"
  runtime                = "${G_RUNTIME}"
  entry_point            = "${G_FUNCTION_NAME}"
  region                 = "${G_REGION}"
  available_memory_mb    = 128
  source_archive_bucket  = "${G_ORG_BUCKET_NAME}"
  source_archive_object  = "${G_ARCHIVE_OBJECT}"
  trigger_http           = true
}

# Grant anonymous access
resource "google_cloudfunctions_function_iam_member" "${TFORM_FUNCTION_IAM_NAME}" {
  project        = "${G_PROJECT_ID}"
  region         = "${G_REGION}"
  cloud_function = google_cloudfunctions_function.${TFORM_FUNCTION_NAME}.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}

# Firebase Hosting Site
resource "google_firebase_hosting_site" "${TFORM_FBASE_SITE_NAME}" {
  project = "${G_PROJECT_ID}"
  site_id = "${G_CLOUD_FBASE_SITE_ID}"
}

# Firebase Hosting Deployment
resource "google_firebase_hosting_version" "${TFORM_FBASE_HOSTING_VERSION_NAME}" {
  project = "${G_PROJECT_ID}"
  site    = google_firebase_hosting_site.${TFORM_FBASE_SITE_NAME}.site_id

  version {
    config {
      rewrites = [
        {
          source   = "/${G_URL_PATH_MATCHER}"
          function = google_cloudfunctions_function.${TFORM_FUNCTION_NAME}.id
        }
      ]
    }
  }
}

# Firebase Custom Domain
resource "google_firebase_hosting_custom_domain" "${TFORM_FBASE_CUSTOM_DOMAIN_NAME}" {
  project = "${G_PROJECT_ID}"
  site    = google_firebase_hosting_site.${TFORM_FBASE_SITE_NAME}.site_id
  domain  = "${G_DOMAIN}"
}

# DNS Record for Firebase Hosting
resource "google_dns_record_set" "${TFORM_DNS_RECORD_NAME}" {
  project      = "${G_PROJECT_ID}"
  managed_zone = "${G_CLOUD_DNS_ZONE}"
  name         = "${G_DOMAIN}."
  type         = "CNAME"
  ttl          = 300
  rrdatas = [
    google_firebase_hosting_custom_domain.${TFORM_FBASE_CUSTOM_DOMAIN_NAME}.domain_name
  ]
}
