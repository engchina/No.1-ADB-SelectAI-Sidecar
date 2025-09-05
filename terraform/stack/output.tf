output "bucket_region" {
  description = "Bucket region where Resource Manager is running"
  value       = var.bucket_region
}

output "bucket_name" {
  description = "The name of the created object storage bucket"
  value       = oci_objectstorage_bucket.dify_bucket.name
}

output "bucket_namespace" {
  description = "The namespace of the object storage bucket"
  value       = data.oci_objectstorage_namespace.tenant_namespace.namespace
}

output "admin_username" {
    value = "admin"
}

output "db_password" {
    value = var.db_password
}

output "adb_dsn" {
  description = "ADB DSN for connection"
  value       = "${lower(var.adb_name)}_high"
}

output "wallet_file_location" {
  description = "Location of the wallet file"
  value       = "${path.module}/wallet.zip"
}

output "adb_connection_string" {
  value = lookup(
    oci_database_autonomous_database.generated_database_autonomous_database.connection_strings[0].all_connection_strings,
    "HIGH",
    "unavailable",
  )
}

output "adb_connection_string_full" {
  description = "Full Oracle connection descriptor for ADB HIGH service"
  value = try(
    [for profile in oci_database_autonomous_database.generated_database_autonomous_database.connection_strings[0].profiles :
      profile.value if profile.consumer_group == "HIGH" && profile.tls_authentication == "MUTUAL"
    ][0],
    "unavailable"
  )
}

output "adb_connection_string_for_dify" {
  description = "Full Oracle connection descriptor for dify"
  value = try(
    "oracle+oracledb://admin:${var.db_password}@${[for profile in oci_database_autonomous_database.generated_database_autonomous_database.connection_strings[0].profiles :
      profile.value if profile.consumer_group == "HIGH" && profile.tls_authentication == "MUTUAL"
    ][0]}",
    "unavailable"
  )
}

output "mysql_internal_fqdn" {
  description = "MySQL Internal FQDN"
  value       = "${oci_mysql_mysql_db_system.mysql_db_system.hostname_label}.${data.oci_core_subnet.private_subnet.dns_label}.${data.oci_core_vcn.vcn.dns_label}.oraclevcn.com"
}

output "mysql_internal_connection_string_for_dify" {
  description = "MySQL Internal connection string for dify"
  value       = "mysql+pymysql://admin:${var.db_password}@${oci_mysql_mysql_db_system.mysql_db_system.hostname_label}.${data.oci_core_subnet.private_subnet.dns_label}.${data.oci_core_vcn.vcn.dns_label}.oraclevcn.com:3306"
}

output "postgresql_primary_endpoint_fqdn" {
  description = "PostgreSQL Primary endpoint FQDN"
  value       = "primary.${substr(oci_psql_db_system.psql_db_system.id, -30, 30)}.postgresql.${lower(substr(var.availability_domain, 5, length(var.availability_domain) - 10))}.oci.oraclecloud.com"
}

output "postgresql_internal_connection_string_for_dify" {
  description = "PostgreSQL Internal connection string for dify"
  value       = "postgresql+psycopg2://admin:${var.db_password}@${oci_psql_db_system.psql_db_system.network_details[0].primary_db_endpoint_private_ip}:5432/postgres"
}

output "ssh_to_instance" {
  description = "convenient command to ssh to the instance"
  value       = "ssh -o ServerAliveInterval=10 ubuntu@${oci_core_instance.generated_oci_core_instance.public_ip}"
}

output "application_url" {
  description = "convenient url to access the application"
  value       = "http://${oci_core_instance.generated_oci_core_instance.public_ip}:8080"
}

output "langfuse_url" {
  description = "Langfuse URL for LLM observability"
  value       = "http://${oci_core_instance.generated_oci_core_instance.public_ip}:3100"
}
