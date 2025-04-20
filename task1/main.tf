terraform {
  required_version = ">= 1.6"
  required_providers {
    yandex = {
      source  = "registry.terraform.io/yandex-cloud/yandex"
      version = "0.138.0"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yandex_cloud_id
  folder_id = var.yandex_folder_id
  zone      = var.zone
}

# Сервисный аккаунт для Data Proc
resource "yandex_iam_service_account" "dataproc_sa" {
  name        = "dataproc-service-account"
  description = "Сервисный аккаунт для кластера Data Proc"
}

# Роли для сервисного аккаунта
resource "yandex_resourcemanager_folder_iam_member" "dataproc_agent" {
  folder_id = var.yandex_folder_id
  role      = "mdb.dataproc.agent"
  member    = "serviceAccount:${yandex_iam_service_account.dataproc_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "storage_admin" {
  folder_id = var.yandex_folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.dataproc_sa.id}"
}

# Статический ключ доступа для сервисного аккаунта
resource "yandex_iam_service_account_static_access_key" "sa_key" {
  service_account_id = yandex_iam_service_account.dataproc_sa.id
  description        = "Статический ключ доступа для объектного хранилища"
}

# Сеть и подсеть
resource "yandex_vpc_network" "dataproc_net" {
  name = "dataproc-network"
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "dataproc-nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "nat_route_table" {
  name       = "dataproc-nat-route-table"
  network_id = yandex_vpc_network.dataproc_net.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_subnet" "dataproc_subnet" {
  name           = "dataproc-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.dataproc_net.id
  v4_cidr_blocks = ["10.1.0.0/16"]
  route_table_id = yandex_vpc_route_table.nat_route_table.id # Добавляем привязку таблицы маршрутов здесь
}

resource "yandex_vpc_default_security_group" "dataproc_default_sg" {
  description = "описание для группы безопасности по умолчанию"
  network_id  = yandex_vpc_network.dataproc_net.id

  labels = {
    my-label = "my-label-value"
  }

  ingress {
    protocol       = "ANY"
    description    = "правило1 описание"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "правило2 описание"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Бакет для хранения данных
resource "yandex_storage_bucket" "dataproc_bucket" {
  bucket        = "task1-transactions-bucket-b1gbmhga2f59uao8jrf0"
  access_key    = yandex_iam_service_account_static_access_key.sa_key.access_key
  secret_key    = yandex_iam_service_account_static_access_key.sa_key.secret_key
  force_destroy = true
}

resource "yandex_storage_object" "transactions" {
  bucket       = yandex_storage_bucket.dataproc_bucket.bucket
  key          = "transactions/transactions_v2.csv"        # Путь в бакете
  source       = "${path.module}/data/transactions_v2.csv" # Локальный путь
  access_key   = yandex_iam_service_account_static_access_key.sa_key.access_key
  secret_key   = yandex_iam_service_account_static_access_key.sa_key.secret_key
  content_type = "text/csv"
}

resource "yandex_storage_object" "user_logs" {
  bucket       = yandex_storage_bucket.dataproc_bucket.bucket
  key          = "logs/logs_v2.txt"                # Путь в бакете
  source       = "${path.module}/data/logs_v2.txt" # Локальный путь
  access_key   = yandex_iam_service_account_static_access_key.sa_key.access_key
  secret_key   = yandex_iam_service_account_static_access_key.sa_key.secret_key
  content_type = "text/plain"
}

# Кластер Data Proc
resource "yandex_dataproc_cluster" "dataproc_cluster" {
  name               = "task1-dataproc-cluster"
  description        = "Кластер Data Proc"
  service_account_id = yandex_iam_service_account.dataproc_sa.id
  bucket             = yandex_storage_bucket.dataproc_bucket.bucket
  security_group_ids = [yandex_vpc_default_security_group.dataproc_default_sg.id]

  cluster_config {
    version_id = "2.0"

    hadoop {
      services = ["HDFS", "YARN", "SPARK", "HIVE"]
      properties = {
        "yarn:yarn.resourcemanager.am.max-attempts" = "3"
      }
      ssh_public_keys = [file(var.ssh_public_key_path)]
    }

    subcluster_spec {
      name = "master"
      role = "MASTERNODE"
      resources {
        resource_preset_id = "s2.small"
        disk_type_id       = "network-hdd"
        disk_size          = 20
      }
      subnet_id        = yandex_vpc_subnet.dataproc_subnet.id
      hosts_count      = 1
      assign_public_ip = true
    }

    subcluster_spec {
      name = "data"
      role = "DATANODE"
      resources {
        resource_preset_id = "s2.small"
        disk_type_id       = "network-hdd"
        disk_size          = 20
      }
      subnet_id   = yandex_vpc_subnet.dataproc_subnet.id
      hosts_count = 1
    }

    subcluster_spec {
      name = "compute"
      role = "COMPUTENODE"
      resources {
        resource_preset_id = "s2.small"
        disk_type_id       = "network-hdd"
        disk_size          = 20
      }
      subnet_id   = yandex_vpc_subnet.dataproc_subnet.id
      hosts_count = 1
    }
  }
}