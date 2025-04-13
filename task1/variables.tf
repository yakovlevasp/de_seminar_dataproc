variable "yc_token" {
  description = "Yandex.Cloud OAuth token"
  type        = string
}

variable "yandex_cloud_id" {
  description = "Cloud ID"
  type        = string
}

variable "yandex_folder_id" {
  description = "Folder ID"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
}

variable "zone" {
  type        = string
  description = "Yandex Cloud zone"
  default     = "ru-central1-a"
}