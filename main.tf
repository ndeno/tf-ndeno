variable "aws_region" {
  type        = string
  description = "The region in which the resources will be created"
  default     = "eu-central-1"
}

data "aws_acm_certificate" "ndeno-dev-acm-cert" {
  domain   = var.NDENO_DEV_DOMAIN
  statuses = ["ISSUED"]
}

resource "aws_s3_bucket" "ndeno-dev-bucket" {
  bucket = "dev-bucket-${var.NDENO_DEV_DOMAIN}-1"

  tags = {
    Name = "bucket-1"
  }
}

resource "aws_s3_bucket" "ndeno-static-bucket" {
  bucket = "static-bucket-${var.NDENO_DEV_DOMAIN}-1"

  tags = {
    Name = "bucket-1"
  }
}

resource "aws_cloudfront_origin_access_control" "ndeno-default" {
  name                              = "ndeno-default"
  description                       = "Default Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.ndeno-static-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.ndeno-default.id
    origin_id                = aws_s3_bucket.ndeno-static-bucket.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  aliases = [var.NDENO_DEV_DOMAIN]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.ndeno-static-bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# // TODO
# data "aws_iam_policy_document" "ndeno-static-iam-policy-document" {
#   statement {
#     actions   = ["s3:GetObject"]
#     resources = ["${aws_s3_bucket.ndeno-static-bucket.arn}/*"]

#     principals {
#       type        = "AWS"
#       identifiers = [aws_cloudfront_origin_access_identity.example.iam_arn]
#     }
#   }
# }

# resource "aws_s3_bucket_policy" "examndeno-static-bucket-policy" {
#   bucket = aws_s3_bucket.ndeno-static-bucket.id
#   policy = data.aws_iam_policy_document.ndeno-static-iam-policy-document.json
# }

resource "aws_s3_bucket_website_configuration" "ndeno-static-bucket-config" {
  bucket = aws_s3_bucket.ndeno-static-bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
