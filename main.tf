# Задаємо провайдера Google Cloud
provider "google" {
    credentials = file("C:/users/a.kulikov/desktop/ethereal-pride-383012-fd44ce2709a1.json")
  project = "ethereal-pride-383012"
  region  = "europe-west3"
  zone    = "europe-west3-c"
}

resource "google_compute_network" "glpi-network" {
  name                    = "glpi-network"
  auto_create_subnetworks = false
}

# Створення бази даних MySQL на Cloud SQL
resource "google_sql_database_instance" "glpi-db" {
  name             = "glpi-db"
  database_version = "MYSQL_5_7"
  region           = "europe-west3"
  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_database" "glpi-db" {
  name     = "glpi"
  instance = google_sql_database_instance.glpi-db.name
}

# Створення інстансу Compute Engine
resource "google_compute_instance" "glpi" {
  name         = "glpi"
  machine_type = "f1-micro"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }
  network_interface {
    network = "default"
  }
  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y apache2 php
    sudo wget https://github.com/glpi-project/glpi/releases/download/9.5.5/glpi-9.5.5.tgz
    sudo tar -xvzf glpi-9.5.5.tgz -C /var/www/html/
  EOF
}

# Відкриваємо доступ до порту 80 з інтернету
resource "google_compute_firewall" "glpi-allow-http" {
  name        = "glpi-allow-http"
  network     = google_compute_network.glpi-network.name
  direction   = "INGRESS"
  priority    = 1000

  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}