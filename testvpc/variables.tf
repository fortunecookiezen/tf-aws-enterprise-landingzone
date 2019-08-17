variable "owner" {}

variable "environment" {
  default = "nonprod"
}

variable "net_cidr" {}

variable "delete" {
  default = "never"
}
