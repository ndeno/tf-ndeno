variable "aws_region" {
  type        = string
  description = "The region in which the resources will be created"
  default     = "eu-central-1"
}

resource "aws_s3_bucket" "ndeno_bucket" {
  bucket = "ndeno-${var.ndeno_domain}-1"

  tags = {
    Name = "bucket-1"
  }
}
