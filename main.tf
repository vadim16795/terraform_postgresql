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
 project     = "varkhipovdiplomaproject"
 region      = "europe-west1"
}
resource "google_sql_database_instance" "master" {
  name             = "gcloudpostgresqlinstance1"
  database_version = "POSTGRES_9_6"
  region           = "europe-west1"
  deletion_protection = false
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
  }
}

resource "google_sql_user" "users" {
  name     = "postgres"
  instance = google_sql_database_instance.master.name
  password = var.postgres_password
}


provider "postgresql" {
  host            = tostring(google_sql_database_instance.master.public_ip_address)
  port            = 5432
  username        = "postgres"
  password        = var.postgres_password
  sslmode         = "require"
  connect_timeout = 15
}

resource "postgresql_database" "prod" {
  name              = "prod"
  owner             = "postgres"
  connection_limit  = -1
  allow_connections = true
}

resource "postgresql_database" "stage" {
  name              = "stage"
  owner             = "postgres"
  connection_limit  = -1
  allow_connections = true
}

resource "google_container_cluster" "primary" {
  name     = "prod-app-cluster"
  location = "europe-west1-c"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "prod-app-pool"
  location   = "europe-west1-c"
  cluster    = google_container_cluster.primary.name
  node_count = 2

  node_config {
    machine_type = "e2-medium"

  }
}

resource "google_container_cluster" "secondary" {
  name     = "stage-app-cluster"
  location = "europe-west1-c"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "secondary_nodes" {
  name       = "stage-app-pool"
  location   = "europe-west1-c"
  cluster    = google_container_cluster.secondary.name
  node_count = 1

  node_config {
    machine_type = "e2-micro"

  }
}