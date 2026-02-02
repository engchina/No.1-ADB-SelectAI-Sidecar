variable "availability_domain" {
  default = ""
}

variable "compartment_ocid" {
  default = ""
}

variable "adb_name" {
  default = "AISIDECAR"
}

variable "adb_display_name" {
  description = "Display name for Autonomous Database (optional, defaults to adb_name if not specified)"
  default = ""
}

variable "db_password" {
  default = ""
}

variable "license_model" {
  default = ""
}

variable "instance_display_name" {
  default = "AIDIFY_INSTANCE"
}

variable "instance_shape" {
  default = "VM.Standard.E5.Flex"
}

variable "instance_flex_shape_ocpus" {
  default = 2
}

variable "instance_flex_shape_memory" {
  default = 16
}

variable "instance_boot_volume_size" {
  default = 100
}

variable "instance_boot_volume_vpus" {
  default = 20
}

variable "instance_image_source_id" {
  default = "ocid1.image.oc1.ap-osaka-1.aaaaaaaakubn2okgusevio3dcanojxysaeod42dkey2tilbr7bfvkiconb6q"
}

variable "subnet_public_id" {
  default = ""
}

variable "subnet_private_id" {
  default = ""
}

variable "ssh_authorized_keys" {
  default = ""
}

variable "bucket_region" {
  default = "ap-osaka-1"
}

variable "bucket_name" {
  default = "dify-bucket"
}

variable "bucket_namespace" {
  default = ""
}

variable "oci_access_key" {
  default = ""
}

variable "oci_secret_key" {
  default = ""
}

variable "dify_branch" {
  default = "1.11.4"
}

variable "mysql_display_name" {
  description = "Display name for MySQL database system"
  default = "mysql4adbaisidecar"
}

variable "db_system_display_name" {
  description = "Display name for PostgreSQL database system"
  default = "postgresql4adbaisidecar"
}

variable "db_system_db_version" {
  description = "Version"
  type = number
  default = 16
}

variable "db_system_shape" {
    description = "shape"
    type = string
    default = "PostgreSQL.VM.Standard.E5.Flex"
}

variable "db_system_storage_details_is_regionally_durable" {
  description = "regional"
  type = bool
  default = false
}

variable "db_system_storage_details_system_type" {
  description = "type"
  type = string
  default = "OCI_OPTIMIZED_STORAGE"
}

variable "db_system_credentials_password_details_password_type" {
    description = "type"
    type = string
    default = "PLAIN_TEXT"
}

variable "db_system_instance_count" {
  description = "instance count"
  type = number
  default = 1
}

variable "db_system_instance_memory_size_in_gbs" {
  description = "RAM"
  type = number
  default = 16
}

variable "db_system_instance_ocpu_count" {
  description = "OCPU count"
  type = number
  default = 2
}

variable "enable_mysql" {
  description = "Enable MySQL database installation"
  type = bool
  default = true
}

variable "enable_postgresql" {
  description = "Enable PostgreSQL database installation"
  type = bool
  default = true
}