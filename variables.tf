variable "hostname" {
  type        = "string"
  description = "Hostname or IP address of the remote server"
}

variable "user" {
  type        = "string"
  description = "username of the remote user"
  default     = "root"
}

variable "password" {
  type        = "string"
  description = "password of the remote user"
}

variable "timeout" {
  type        = "string"
  description = "timeout for the ssh connection"
  default     = "10m"
}
