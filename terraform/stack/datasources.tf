data "template_file" "cloud_init_file" {
  template = file("./cloud_init/bootstrap.template.yaml")

  vars = {
    oci_database_autonomous_database_connection_string = base64gzip("admin/${var.db_password}@${lower(var.adb_name)}_high")
    oci_database_autonomous_database_wallet_content    = oci_database_autonomous_database_wallet.generated_autonomous_data_warehouse_wallet.content
    oci_database_autonomous_database_password = var.db_password
    oci_database_autonomous_database_dsn = "${lower(var.adb_name)}_high"
    output_compartment_ocid = var.compartment_ocid
    bucket_region = var.bucket_region
    bucket_name   = var.bucket_name
    bucket_namespace = data.oci_objectstorage_namespace.tenant_namespace.namespace
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

# Get private subnet information to retrieve DNS label
data "oci_core_subnet" "private_subnet" {
  subnet_id = var.subnet_private_id
}

# Get VCN information to retrieve DNS label
data "oci_core_vcn" "vcn" {
  vcn_id = data.oci_core_subnet.private_subnet.vcn_id
}