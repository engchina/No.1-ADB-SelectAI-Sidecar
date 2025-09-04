data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

data "oci_identity_tenancy" "current" {
  tenancy_id = var.tenancy_ocid
}

locals {
  # Get the current region name where this Terraform is being executed
  # Extract region from availability domain name (format: region-AD-1)
  current_region_name = substr(data.oci_identity_availability_domains.ads.availability_domains[0].name, 0, length(data.oci_identity_availability_domains.ads.availability_domains[0].name) - 5)
}

data "template_file" "cloud_init_file" {
  template = file("./cloud_init/bootstrap.template.yaml")

  vars = {
    oci_database_autonomous_database_connection_string = base64gzip("admin/${var.adb_password}@${lower(var.adb_name)}_high")
    oci_database_autonomous_database_wallet_content    = oci_database_autonomous_database_wallet.generated_autonomous_data_warehouse_wallet.content
    oci_database_autonomous_database_password = var.adb_password
    oci_database_autonomous_database_dsn = "${lower(var.adb_name)}_high"
    output_compartment_ocid = var.compartment_ocid
    bucket_name = var.bucket_name
    bucket_namespace = data.oci_objectstorage_namespace.tenant_namespace.namespace
    bucket_region = local.current_region_name
    oci_access_key = var.oci_access_key
    oci_secret_key = var.oci_secret_key
    dify_branch = var.dify_branch
  }
}


data "template_cloudinit_config" "cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "bootstrap.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud_init_file.rendered
  }
}