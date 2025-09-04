resource "oci_psql_db_system" "psql_db_system" {
    compartment_id = var.compartment_ocid
    db_version = var.db_system_db_version
    display_name = var.db_system_display_name
    network_details {
        subnet_id = var.subnet_private_id
    }
    shape = var.db_system_shape
    storage_details {
        availability_domain = var.availability_domain
        is_regionally_durable = var.db_system_storage_details_is_regionally_durable
        system_type = var.db_system_storage_details_system_type
        #Optional
        # availability_domain = var.db_system_storage_details_availability_domain
        # iops = var.db_system_storage_details_iops
    }
    credentials {
        #Required
        password_details {
            #Required
            password_type = var.db_system_credentials_password_details_password_type
            #Optional
            password = var.db_password
        }
        username = "admin"
    }
    instance_count = var.db_system_instance_count
    instance_memory_size_in_gbs = var.db_system_instance_memory_size_in_gbs
    instance_ocpu_count = var.db_system_instance_ocpu_count
    # config_id = "ocid1.postgresqldefaultconfiguration.oc1.ap-osaka-1.amaaaaaayn42exyafss22tavrbzveakylonbyfwnxrgewmtrdqabuoyx2awa"
}