########################
# VPC (2 AZs, NAT disabled to avoid charges)
########################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  # Internet for public subnets (for EC2 testing)
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tag subnets to be EKS-friendly later
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.tags
}

########################
# Security Groups
# - Frontend/Backend: HTTP/HTTPS open; SSH only from your IP (if set)
# - RDS: only from BACKEND SG
########################
module "sg_frontend" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name_prefix}-frontend-sg"
  description = "Frontend web SG"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  ingress_with_cidr_blocks = var.allowed_ssh_cidr != "" ? [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from my IP"
      cidr_blocks = var.allowed_ssh_cidr
    }
  ] : []

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]

  tags = local.tags
}

module "sg_backend" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name_prefix}-backend-sg"
  description = "Backend web SG"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  ingress_with_cidr_blocks = var.allowed_ssh_cidr != "" ? [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from my IP"
      cidr_blocks = var.allowed_ssh_cidr
    }
  ] : []

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]

  tags = local.tags
}

module "sg_rds" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name_prefix}-rds-sg"
  description = "Allow Postgres from backend SG only"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      description              = "Postgres from backend servers"
      source_security_group_id = module.sg_backend.security_group_id
    }
  ]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]

  tags = local.tags
}

########################
# IAM role for SSM on EC2 (so you can SSM into the instances)
########################
resource "aws_iam_role" "ec2_ssm_role" {
  name = "${local.name_prefix}-ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "${local.name_prefix}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

########################
# AMI for Amazon Linux 2023 (x86_64)
########################
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

########################
# EC2 Instances (frontend + backend)
########################
module "frontend" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name                        = "${local.name_prefix}-frontend"
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.frontend_instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [module.sg_frontend.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data = <<-EOF
              #!/bin/bash
              set -e
              dnf -y update
              dnf -y install nginx
              echo "<h1>CloudNorth Frontend</h1><p>It works! 🚀</p>" > /usr/share/nginx/html/index.html
              systemctl enable nginx
              systemctl start nginx
              EOF

  tags = local.tags
}

module "backend" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name                        = "${local.name_prefix}-backend"
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.backend_instance_type
  subnet_id                   = module.vpc.public_subnets[1]
  vpc_security_group_ids      = [module.sg_backend.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data = <<-EOF
              #!/bin/bash
              set -e
              dnf -y update
              dnf -y install nginx
              echo "<h1>CloudNorth Backend</h1><p>Placeholder service running via Nginx.</p>" > /usr/share/nginx/html/index.html
              systemctl enable nginx
              systemctl start nginx
              EOF

  tags = local.tags
}

########################
# S3 bucket for static content (private)
########################
module "static_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket        = var.static_bucket_name != "" ? var.static_bucket_name : local.default_static_bucket
  force_destroy = false

  acl                     = null
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  tags = local.tags
}

########################
# RDS PostgreSQL (private subnets, free-tier friendly)
########################
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = var.db_identifier

  engine                = "postgres"
  engine_version        = var.db_engine_version
  family                = "postgres15" # parameter group family for Postgres 15
  instance_class        = var.rds_instance_class
  allocated_storage     = 20 # free-tier suitable
  max_allocated_storage = 100
  storage_type          = "gp3"

  db_name  = var.db_name
  username = var.db_username

  # Let AWS generate and store the master password in Secrets Manager (safer)
  manage_master_user_password = true

  port                   = 5432
  publicly_accessible    = false
  multi_az               = false
  create_db_subnet_group = true
  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [module.sg_rds.security_group_id]

  performance_insights_enabled = false # avoid extra cost

  maintenance_window      = "Sun:00:00-Sun:02:00"
  backup_window           = "03:00-04:00"
  backup_retention_period = 7

  deletion_protection = false
  skip_final_snapshot = true # dev convenience

  tags = local.tags
}
