variable "aws_access_key" {
  type        = string
  description = "aws access key id"
  sensitive   = true
}
variable "aws_secret_key" {
  type        = string
  description = "aws access secret key"
  sensitive   = true
}

variable "region" {
  description = "The primary AWS region where all the resources will be created. See https://docs.aws.amazon.com/general/latest/gr/rande.html"
  default     = "us-east-1"
}

variable "NDENO_DEV_DOMAIN" {
  description = "The primary domain name of the website"
  sensitive = true
}
