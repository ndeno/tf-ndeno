data "aws_acm_certificate" "this" {
  domain   = var.ndeno_domain
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "this" {
  name         = var.ndeno_domain
  private_zone = false
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.bucket_prefix}${var.ndeno_domain}"

  tags = {
    Name = var.ndeno_domain
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    principals {
      type = "Service"
      identifiers = [
        "cloudfront.amazonaws.com"
      ]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.bucket_prefix}${var.ndeno_domain}_oac"
  description                       = "Default s3 origin access control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "this" {
  name    = "index_html_redirect"
  runtime = "cloudfront-js-1.0"
  comment = "redirect to index.html file"
  publish = true
  code    = file("./cloudfront_functions/redirect.js")
}

resource "aws_cloudfront_distribution" "this" {
  comment = "${var.bucket_prefix}${var.ndeno_domain}"
  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
    origin_id                = aws_s3_bucket.this.id
  }

  enabled         = true
  is_ipv6_enabled = true

  aliases = ["${var.bucket_prefix}${var.ndeno_domain}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.this.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.this.arn
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["GB"]
    }
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.this.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${var.bucket_prefix}${var.ndeno_domain}"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
