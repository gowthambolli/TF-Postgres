variable "hostname" {
  type        = "string"
  description = "192.168.0.139"
}

variable "user" {
  type        = "string"
  description = "terraform"
  default     = "root"
}

variable "password" {
  type        = "string"
  description = "Flex@123"
}

variable "timeout" {
  type        = "string"
  description = "timeout for the ssh connection"
  default     = "10m"
}
