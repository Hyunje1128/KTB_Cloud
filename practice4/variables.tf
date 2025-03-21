#variables.tf

variable "server_port" {
    description = "Webserver's HTTP port"
    type        = number
    default     = 80

}

variable "my_ip" {
    description = "My public IP"
    type        = string
    default     = "0.0.0.0/0"
}

variable "alb_security_group_name" {
    description = "ALB Security Group Name"
    type        = string
    default     = "webserver-alb-sg-studentN"
  
}

variable "alb_name" {
    description = "ALB Name"
    type        = string
    default     = "webserver-alb-studentN"
}