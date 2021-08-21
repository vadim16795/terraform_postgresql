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
resource "google_sql_user" "users" {
  name     = "myapp"
  password = "mypassword"
  instance = google_sql_database_instance.master.name
  type     = "CLOUD_IAM_USER"
  depends_on = [
    google_sql_database_instance.master
  ]
}
provider "postgresql" {
  host            = google_sql_database_instance.master.public_ip_address
  username        = google_sql_user.users.name
  password        = google_sql_user.users.password
}

resource "postgresql_schema" "app" {
  name  = "app"
  owner = "myapp"
}