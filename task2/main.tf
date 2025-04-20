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
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = "ru-central1-a"
}

# Создаем сервисный аккаунт для доступа к S3 из ClickHouse
resource "yandex_iam_service_account" "clickhouse-sa" {
  name        = "clickhouse-s3-access"
  description = "Сервисный аккаунт для доступа ClickHouse к S3"
}

# Даем права сервисному аккаунту на бакет
resource "yandex_resourcemanager_folder_iam_binding" "s3-viewer" {
  folder_id = var.yc_folder_id
  role      = "storage.viewer"
  members = [
    "serviceAccount:${yandex_iam_service_account.clickhouse-sa.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "s3-editor" {
  folder_id = var.yc_folder_id
  role      = "storage.editor"
  members = [
    "serviceAccount:${yandex_iam_service_account.clickhouse-sa.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "clickhouse-admin" {
  folder_id = var.yc_folder_id
  role      = "managed-clickhouse.admin"
  members = [
    "serviceAccount:${yandex_iam_service_account.clickhouse-sa.id}"
  ]
}

# Создаем статический ключ доступа сервисного аккаунта
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.clickhouse-sa.id
  description        = "Статический ключ доступа для доступа ClickHouse к S3"
}

# Создаем S3 бакет
resource "yandex_storage_bucket" "orders-bucket" {
  bucket     = "task-2-orders-bucket"
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
}

resource "yandex_storage_object" "orders" {
  bucket       = yandex_storage_bucket.orders-bucket.bucket
  key          = "orders.csv"
  source       = "${path.module}/data/orders.csv"
  access_key   = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key   = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  content_type = "text/csv"
}

resource "yandex_storage_object" "order_items" {
  bucket       = yandex_storage_bucket.orders-bucket.bucket
  key          = "order_items.txt"
  source       = "${path.module}/data/order_items.txt"
  access_key   = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key   = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  content_type = "text/plain"
}

# Создаем ClickHouse кластер
resource "yandex_mdb_clickhouse_cluster" "clickhouse-cluster" {
  name               = "task2-clickhouse-cluster"
  environment        = "PRODUCTION"
  network_id         = yandex_vpc_network.network.id
  security_group_ids = [yandex_vpc_security_group.clickhouse-sg.id]
  service_account_id = yandex_iam_service_account.clickhouse-sa.id # привязываем сервисный аккаунт
  access {
    web_sql = true
    data_lens = true
  }

  clickhouse {
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-hdd"
      disk_size          = 32
    }
    config {
      merge_tree {
        replicated_deduplication_window = 100
      }
    }
  }

  database {
    name = "orders"
  }

  user {
    name     = "admin"
    password = var.clickhouse_admin_password
    permission {
      database_name = "orders"
    }
    settings {
      add_http_cors_header = true # для кросс-доменных запросов
    }
  }

  host {
    type             = "CLICKHOUSE"
    zone             = "ru-central1-a"
    subnet_id        = yandex_vpc_subnet.subnet.id
    assign_public_ip = true # Включаем публичный IP
  }

  maintenance_window {
    type = "WEEKLY"
    day  = "SAT"
    hour = 12
  }
}

# Настройка сети
resource "yandex_vpc_network" "network" {
  name = "clickhouse-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "clickhouse-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.1.0.0/24"]
}

# Группа безопасности с правилами для публичного доступа
resource "yandex_vpc_security_group" "clickhouse-sg" {
  name       = "clickhouse-security-group-public"
  network_id = yandex_vpc_network.network.id

  ingress {
    description    = "Публичный доступ к HTTP интерфейсу ClickHouse"
    port           = 8123
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Публичный доступ к нативному интерфейсу ClickHouse"
    port           = 9000
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Публичный доступ к защищенному нативному интерфейсу ClickHouse"
    port           = 9440
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Разрешить SSH для администрирования"
    port           = 22
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"] # Лучше ограничить вашим IP
  }

  egress {
    description    = "Исходящий трафик к S3"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Исходящий трафик к сервисам Yandex Cloud"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}
