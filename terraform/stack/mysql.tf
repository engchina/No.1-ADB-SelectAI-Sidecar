resource "oci_mysql_mysql_db_system" "mysql_db_system" {
	access_mode = "UNRESTRICTED"
	admin_password = var.db_password
	admin_username = "admin"
	availability_domain = var.availability_domain
	backup_policy {
		is_enabled = "false"
	}
	compartment_id = var.compartment_ocid
	crash_recovery = "ENABLED"
	data_storage {
		is_auto_expand_storage_enabled = "false"
	}
	data_storage_size_in_gb = "50"
	database_management = "DISABLED"
	database_mode = "READ_WRITE"
	deletion_policy {
		automatic_backup_retention = "DELETE"
		final_backup = "SKIP_FINAL_BACKUP"
		is_delete_protected = "false"
	}
	display_name = var.mysql_display_name
	freeform_tags = {
		"Template" = "Development or testing"
	}
	hostname_label = var.mysql_display_name
	port = "3306"
	port_x = "33060"
	read_endpoint {
		is_enabled = "false"
	}
	secure_connections {
		certificate_generation_type = "SYSTEM"
	}
	shape_name = "MySQL.2"
	subnet_id = var.subnet_private_id
}
