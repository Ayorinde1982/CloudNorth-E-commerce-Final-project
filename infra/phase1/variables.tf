variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "cloudnorth"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# Two AZs for cost-optimized dev
variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

# Disable NAT to avoid charges; we’ll enable before EKS
variable "enable_nat_gateway" {
  type    = bool
  default = false
}

variable "key_name" {
  type    = string
  default = "cloudnorth-jenkins-key"
}

variable "allowed_ssh_cidr" {
  description = "Your public IP in CIDR (e.g., 203.0.113.10/32). Leave empty to disable SSH."
  type        = string
  default     = ""
}

# Free-tier friendly
variable "frontend_instance_type" {
  type    = string
  default = "t2.micro"
}
variable "backend_instance_type" {
  type    = string
  default = "t2.micro"
}

# RDS settings
variable "db_identifier" {
  type    = string
  default = "cloudnorth-dev-db"
}
variable "db_username" {
  type    = string
  default = "cloudnorthapp"
}
variable "db_name" {
  type    = string
  default = "cloudnorth"
}
# Pin Postgres major 15; update minor if needed
variable "db_engine_version" {
  type    = string
  default = "15.5"
}
variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro"
}

# Optional override for static bucket; leave empty to auto-generate
variable "static_bucket_name" {
  type    = string
  default = ""
}
