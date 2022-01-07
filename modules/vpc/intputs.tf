variable "env" {
  type = string
  default = "dev"
}

variable "public_subnet_numbers" {
  type = map(number)

  description = "Map of AZ to a number that should be used for public subnets"

  # Currently creating only 1 subnet in 1 a-zone, uncomment if you want to create more subnets in different a-zones
  default = {
    "eu-west-3a" = 1
#    "eu-west-3b" = 2
#    "eu-west-3c" = 3
  }
}

variable "vpc_cidr" {
  type        = string
  description = "The IP range to use for the VPC"
  default     = "10.0.0.0/16"
}