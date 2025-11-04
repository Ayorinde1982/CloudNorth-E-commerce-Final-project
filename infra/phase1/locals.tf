locals {
  name_prefix = "${var.project}-${var.environment}"
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  default_static_bucket = "cloudnorth-static-${random_string.suffix.id}"
}
