variable "accesskey" {}
variable "secretkey" {}
variable "region" {
  description = "enter region desired name"
  type        = string
  default     = "eu-central-1"
}

variable "inst_type" {
  description = "enter desired instance type"
  type        = string
  default     = "t2.medium"
}

variable "pvt_key" {
  description = "Enter full path to your Private key for AWS EC2"
  type        = string
}


variable "keyname" {
  description = "enter name of your existing ssh key on AWS PLATFORM"
  type        = string
}
