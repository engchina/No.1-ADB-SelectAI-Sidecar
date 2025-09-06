locals {
  mysql_internal_fqdn = var.enable_mysql ? "${oci_mysql_mysql_db_system.mysql_db_system[0].hostname_label}.${data.oci_core_subnet.private_subnet.dns_label}.${data.oci_core_vcn.vcn.dns_label}.oraclevcn.com" : ""
  postgresql_primary_endpoint_fqdn = var.enable_postgresql ? "primary.${substr(oci_psql_db_system.psql_db_system[0].id, -30, 30)}.postgresql.${lower(substr(var.availability_domain, 5, length(var.availability_domain) - 10))}.oci.oraclecloud.com" : ""
}

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
    mysql_hostname = local.mysql_internal_fqdn
    mysql_password = var.db_password
    postgresql_hostname = local.postgresql_primary_endpoint_fqdn
    postgresql_password = var.db_password
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