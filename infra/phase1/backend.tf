terraform {
  backend "s3" {
    bucket         = "bucket-cloudnorth"
    key            = "cloudnorth/dev/phase1/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cloudnorth-tf-locks"
    encrypt        = true
  }
}
