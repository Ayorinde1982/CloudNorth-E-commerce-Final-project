output "vpc_id" {
  value = module.vpc.vpc_id
}

output "frontend_public_ip" {
  value = module.frontend.public_ip
}

output "frontend_public_dns" {
  value = module.frontend.public_dns
}

output "backend_public_ip" {
  value = module.backend.public_ip
}

output "backend_public_dns" {
  value = module.backend.public_dns
}

output "static_bucket_name" {
  value = module.static_bucket.s3_bucket_id
}

output "db_endpoint" {
  value = module.db.db_instance_endpoint
}

output "db_identifier" {
  value = var.db_identifier
}
