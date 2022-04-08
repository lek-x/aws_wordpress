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
  description = "name ssh key"
  type        = string
}
