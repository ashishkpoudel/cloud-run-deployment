provider "google" {
  credentials = "../credentials/test-service-account.json"
  project = var.project
  region = var.region
  zone = var.zone
}

provider "google-beta" {
  credentials = "../credentials/test-service-account.json"
  project = var.project
  region = var.region
  zone = var.zone
}

terraform {
  backend "gcs" {
    bucket = "cloud-run-deployment-next"
    prefix = "api"
    credentials = "../credentials/test-service-account.json"
  }
}

resource "google_cloud_run_service" "api" {
  name = "cloudrun-deployment-api"
  location = var.region
  provider = google-beta
  autogenerate_revision_name = true

  template {
    spec {
      containers {
        image = var.app_image

        resources {
          limits = {
            cpu = "1"
            memory = "1000Mi"
          }

          requests = {
            cpu = "1"
            memory = "400Mi"
          }
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = "1",
        "autoscaling.knative.dev/maxScale" = "10",
        "run.googleapis.com/client-name" = "terraform"
      }
    }
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.api.location
  project = google_cloud_run_service.api.project
  provider = google-beta
  service = google_cloud_run_service.api.name
  policy_data = data.google_iam_policy.noauth.policy_data
}
