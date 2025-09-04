# Provider for home region
provider "oci" {
  alias  = "bucket_region"
  region = var.bucket_region
}

# Get namespace in home region
data "oci_objectstorage_namespace" "tenant_namespace" {
  provider       = oci.bucket_region
  compartment_id = var.compartment_ocid
}

# Create bucket in home region
resource "oci_objectstorage_bucket" "dify_bucket" {
  provider       = oci.bucket_region
  compartment_id = var.compartment_ocid
  name           = var.bucket_name
  namespace      = data.oci_objectstorage_namespace.tenant_namespace.namespace
  # Optional: Disable versioning to make cleanup easier
  versioning     = "Disabled"
}

resource "null_resource" "bucket_cleanup" {
  triggers = {
    bucket_name = oci_objectstorage_bucket.dify_bucket.name
    namespace   = oci_objectstorage_bucket.dify_bucket.namespace
    region      = var.bucket_region
  }

  provisioner "local-exec" {
    when    = destroy
    command = "oci os object bulk-delete --bucket-name ${self.triggers.bucket_name} --namespace ${self.triggers.namespace} --region ${self.triggers.region} --force || true"
  }

  depends_on = [oci_objectstorage_bucket.dify_bucket]
}