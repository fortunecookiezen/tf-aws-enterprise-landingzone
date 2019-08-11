variable "region" {
  default = "us-east-1"
}
variable "profile" {
  default = ""
}
provider "aws" {
  region  = var.region
  profile = var.profile
}