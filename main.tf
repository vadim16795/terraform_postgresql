terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    postgresql = {
      source = "cyrilgdn/postgresql"
      version = "1.14.0"
    }
   }
  }

provider "google" {
 credentials = var.google_creds
 project     = "varkhipovgcloudpostgresql"
 region      = "europe-west1"
}
resource "google_sql_database_instance" "master" {
  name             = "gcloudpostgresqlinstance"
  database_version = "POSTGRES_9_6"
  region           = "europe-west1"

  settings {
    tier = "db-f1-micro"
    availability_type = "ZONAL"
    disk_autoresize = false
    disk_size       = 10
    disk_type       = "PD_HDD"
      ip_configuration {
        ipv4_enabled = true
        authorized_networks {
          name= "all_networks"
          value = "0.0.0.0/0"
        }
      }
      database_flags {
        name = "cloudsql.iam_authentication"
        value = "on"
      }
  }
}

resource "google_sql_database_instance" "master2" {
  name             = "gcloudpostgresqlinstance2"
  database_version = "POSTGRES_9_6"
  region           = "europe-west1"

  settings {
    tier = "db-f1-micro"
    availability_type = "ZONAL"
    disk_autoresize = false
    disk_size       = 10
    disk_type       = "PD_HDD"
      ip_configuration {
        ipv4_enabled = true
        authorized_networks {
          name= "all_networks"
          value = "0.0.0.0/0"
        }
      }
      database_flags {
        name = "cloudsql.iam_authentication"
        value = "on"
      }
  }
}
provider "postgresql" {
  host            = tostring(google_sql_database_instance.master.public_ip_address)
  port            = 5432
  username        = "postgres"
  password        = var.postgres_password
  sslmode         = "require"
  connect_timeout = 15
}
resource "postgresql_database" "my_db" {
  name              = "my_db"
  owner             = "postgres"
  template          = "template0"
  lc_collate        = "C"
  connection_limit  = -1
  allow_connections = true
}