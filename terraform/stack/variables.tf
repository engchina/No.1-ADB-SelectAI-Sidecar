variable "availability_domain" {
  default = ""
}

variable "compartment_ocid" {
  default = ""
}

variable "adb_name" {
  default = "AISIDECAR"
}

variable "adb_password" {
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
  default = "1.8.0"
}
