terraform {
  backend "s3" {
    bucket = "terraform-bucket1223"
    key    = "tf-state"
    region = "us-east-1"
  }
}
