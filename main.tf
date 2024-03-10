variable "aws_region" {
  type        = string
  description = "The region in which the resources will be created"
  default     = "eu-central-1"
}

resource "aws_s3_bucket" "ndeno_dev-bucket" {
  bucket = "dev-bucket-${var.NDENO_DEV_DOMAIN}-1"

  tags = {
    Name = "bucket-1"
  }
}

resource "aws_s3_bucket" "ndeno_static-bucket" {
  bucket = "static-bucket-${var.NDENO_DEV_DOMAIN}-1"

  tags = {
    Name = "bucket-1"
  }
}

resource "aws_s3_bucket_website_configuration" "ndeno_static-bucket-config" {
  bucket = aws_s3_bucket.ndeno_static-bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
