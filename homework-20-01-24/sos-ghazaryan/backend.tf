terraform {
  backend "s3" {
    bucket = "test-bucket-from-devops"
    key    = "terraform_state"
    region = "us-east-1"
  }
}