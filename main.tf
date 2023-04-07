//тест розгортування глпі в гуглі

provider "google" {
  project = "GLPI"
  region  = "us-central1"
  zone    = "us-central1-c"
}

# Створення бази даних MySQL на Cloud SQL
resource "google_sql_database_instance" "glpi-db" {
  name             = "glpi-db"
  database_version = "MYSQL_5_7"
  region           = "us-central1"
  settings {
    tier = "db-n1-standard-1"
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
    sudo apt-get install -y nginx php-fpm
    sudo wget https://github.com/glpi-project/glpi/releases/download/10.0.7/glpi-10.0.7.tgz
    sudo tar -xvzf glpi-10.0.7.tgz -C /var/www/html/
    sudo rm /etc/nginx/sites-enabled/default
    sudo tee /etc/nginx/sites-available/glpi <<EOF1
      server {
        listen 80;
        root /var/www/html/glpi;
        index index.php;
        location / {
          try_files \$uri \$uri/ /index.php?\$args;
        }
        location ~ \.php$ {
          include snippets/fastcgi-php.conf;
          fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
        }
      }
    EOF1
    sudo ln -s /etc/nginx/sites-available/glpi /etc/nginx/sites-enabled/glpi
    sudo service nginx restart
  EOF
}

# Відкриваємо доступ до порту 80 з інтернету
resource "google_compute_firewall" "glpi-allow-http" {
  name    = "glpi-allow-http"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [google_compute_instance.glpi.tags["items"][0]]
}