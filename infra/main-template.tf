# Cloud Function
provider "google" {
  credentials = "${G_TFORM_DEPLOYMENT_SA}.json"
  project     = "${G_PROJECT_ID}"
  region      = "${G_REGION}"
}

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

# Network Endpoint Group
resource "google_compute_region_network_endpoint_group" "${TFORM_NEG_NAME}" {
  project               = "${G_PROJECT_ID}"
  name                  = "${G_CLOUD_NEG_NAME}"
  region                = "${G_REGION}"
  network_endpoint_type = "SERVERLESS"
  cloud_function {
    function = google_cloudfunctions_function.${TFORM_FUNCTION_NAME}.name
  }
}

# Backend Service
resource "google_compute_backend_service" "${TFORM_BACKEND_SERVICE_NAME}" {
  project                = "${G_PROJECT_ID}"
  name                   = "${G_CLOUD_BACKEND_SERVICE_NAME}"
  load_balancing_scheme  = "EXTERNAL"
  protocol               = "HTTPS"
  backend {
    group = google_compute_region_network_endpoint_group.${TFORM_NEG_NAME}.self_link
  }
}

# Blackhole Backend Service
resource "google_compute_backend_service" "${TFORM_BLACKHOLE_BACKEND_SERVICE_NAME}" {
  project                = "${G_PROJECT_ID}"
  name                   = "${G_CLOUD_BLACKHOLE_BACKEND_SERVICE_NAME}"
  load_balancing_scheme  = "EXTERNAL"
  protocol               = "HTTPS"
}

# URL Map
resource "google_compute_url_map" "${TFORM_URL_MAP_NAME}" {
  project        = "${G_PROJECT_ID}"
  name           = "${G_CLOUD_URL_MAP_NAME}"

  default_service = google_compute_backend_service.${TFORM_BLACKHOLE_BACKEND_SERVICE_NAME}.self_link

  host_rule {
    hosts        = ["${G_DOMAIN}"]
    path_matcher = "default-path-matcher"
  }

  path_matcher {
    name            = "default-path-matcher"
    default_service = google_compute_backend_service.${TFORM_BLACKHOLE_BACKEND_SERVICE_NAME}.self_link

    path_rule {
      paths   = ["/${G_URL_PATH_MATCHER}"]
      service = google_compute_backend_service.${TFORM_BACKEND_SERVICE_NAME}.self_link
    }
  }
}

# HTTPS Proxy
resource "google_compute_target_https_proxy" "${TFORM_HTTPS_PROXY_NAME}" {
  project          = "${G_PROJECT_ID}"
  name             = "${G_CLOUD_HTTPS_PROXY_NAME}"
  url_map          = google_compute_url_map.${TFORM_URL_MAP_NAME}.self_link
  ssl_certificates = [
    google_compute_managed_ssl_certificate.${TFORM_SSL_CERT_NAME}.self_link
  ]
}

# Managed SSL Certificate
resource "google_compute_managed_ssl_certificate" "${TFORM_SSL_CERT_NAME}" {
  project = "${G_PROJECT_ID}"
  name    = "${G_CLOUD_SSL_CERT_NAME}"
  managed {
    domains = ["${G_DOMAIN}"]
  }
}

# Static IP Address
resource "google_compute_global_address" "${TFORM_STATIC_IP_NAME}" {
  project = "${G_PROJECT_ID}"
  name    = "${G_CLOUD_FORWARDING_RULE_NAME}-ip"
}

# Global Forwarding Rule
resource "google_compute_global_forwarding_rule" "${TFORM_FORWARDING_RULE_NAME}" {
  project     = "${G_PROJECT_ID}"
  name        = "${G_CLOUD_FORWARDING_RULE_NAME}"
  target      = google_compute_target_https_proxy.${TFORM_HTTPS_PROXY_NAME}.self_link
  port_range  = "443"
  ip_address  = google_compute_global_address.${TFORM_STATIC_IP_NAME}.address
}

# DNS Record
resource "google_dns_record_set" "${TFORM_DNS_RECORD_NAME}" {
  project     = "${G_PROJECT_ID}"
  managed_zone = "${G_CLOUD_DNS_ZONE}"
  name         = "${G_DOMAIN}."
  type         = "A"
  ttl          = 300
  rrdatas = [
    google_compute_global_address.${TFORM_STATIC_IP_NAME}.address
  ]
}
