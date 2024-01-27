terraform {
  backend "s3" {
    bucket = "bazikyan-terraform-state"
    key    = "homework-20-01-24"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}
