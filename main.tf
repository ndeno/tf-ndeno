variable "aws_region" {
  type        = string
  description = "The region in which the resources will be created"
  default     = "eu-central-1"
}

data "aws_acm_certificate" "ndeno-dev" {
  domain   = var.NDENO_DEV_DOMAIN
  statuses = ["ISSUED"]
}

resource "aws_s3_bucket" "ndeno-app" {
  bucket = "app-${var.NDENO_DEV_DOMAIN}-1"

  tags = {
    Name = "app-bucket"
  }
}

resource "aws_s3_bucket" "ndeno-web" {
  bucket = "web-${var.NDENO_DEV_DOMAIN}-1"

  tags = {
    Name = "web-bucket"
  }
}

resource "aws_cloudfront_origin_access_control" "ndeno-web" {
  name                              = "ndeno-default"
  description                       = "Default Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "ndeno-web" {
  origin {
    domain_name              = aws_s3_bucket.ndeno-web.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.ndeno-web.id
    origin_id                = aws_s3_bucket.ndeno-web.id
  }

  enabled         = true
  is_ipv6_enabled = true
  # default_root_object = "index.html"

  aliases = [var.NDENO_DEV_DOMAIN]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.ndeno-web.id

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
    acm_certificate_arn            = data.aws_acm_certificate.ndeno-dev.arn
    ssl_support_method             = "sni-only"
  }
}


data "aws_iam_policy_document" "ndeno-web" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_distribution.ndeno-web.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.ndeno-web.arn,
      "${aws_s3_bucket.ndeno-web.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "ndeno-web" {
  bucket = aws_s3_bucket.ndeno-web.id
  policy = data.aws_iam_policy_document.ndeno-web.json
}

resource "aws_s3_bucket_website_configuration" "ndeno-web" {
  bucket = aws_s3_bucket.ndeno-web.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
