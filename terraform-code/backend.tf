# --- root/backend.tf ---

terraform {
  backend "s3" {
    bucket = "jenkins-terraform-test-bucket"
    key    = "remote.tfstate"
    region = "ap-northeast-2"
    profile = "personal"
  }
}
