variable "aws_region" {
  type        = string
  description = "The region in which the resources will be created"
  default     = "eu-central-1"
}

data "aws_acm_certificate" "ndeno-dev" {
  domain   = var.NDENO_DEV_DOMAIN
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "ndeno-dev" {
  name = var.NDENO_DEV_DOMAIN
}

// Web Domain
resource "aws_route53_record" "ndeno-web" {
  zone_id = data.aws_route53_zone.ndeno-dev.zone_id
  name    = var.NDENO_DEV_DOMAIN
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.ndeno-web.domain_name
    zone_id                = aws_cloudfront_distribution.ndeno-web.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "ndeno-web-subdomain" {
  zone_id = data.aws_route53_zone.ndeno-dev.zone_id
  name    = "www.${var.NDENO_DEV_DOMAIN}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.ndeno-web.domain_name
    zone_id                = aws_cloudfront_distribution.ndeno-web.hosted_zone_id
    evaluate_target_health = false
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

  aliases = [var.NDENO_DEV_DOMAIN, "www.${var.NDENO_DEV_DOMAIN}"]

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

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect.arn
    }

    viewer_protocol_policy = "redirect-to-https"
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
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.ndeno-web.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.ndeno-web.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "ndeno-web" {
  bucket = aws_s3_bucket.ndeno-web.id
  policy = data.aws_iam_policy_document.ndeno-web.json
}

resource "aws_cloudfront_function" "redirect" {
  name    = "redirect"
  runtime = "cloudfront-js-1.0"
  publish = true
  code    = file("${path.module}/modules/cloudfront_functions/redirect.js")
}

// Dev Domain

resource "aws_route53_record" "ndeno-dev" {
  zone_id = data.aws_route53_zone.ndeno-dev.zone_id
  name    = "dev.${var.NDENO_DEV_DOMAIN}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.ndeno-dev.domain_name
    zone_id                = aws_cloudfront_distribution.ndeno-dev.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_s3_bucket" "ndeno-dev" {
  bucket = "dev-${var.NDENO_DEV_DOMAIN}-1"

  tags = {
    Name = "dev-bucket"
  }
}

resource "aws_cloudfront_origin_access_control" "ndeno-dev" {
  name                              = "ndeno-dev-aoc"
  description                       = "Default Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "ndeno-dev" {
  origin {
    domain_name              = aws_s3_bucket.ndeno-dev.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.ndeno-dev.id
    origin_id                = aws_s3_bucket.ndeno-dev.id
  }

  enabled         = true
  is_ipv6_enabled = true
  # default_root_object = "index.html"

  aliases = ["dev.${var.NDENO_DEV_DOMAIN}"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.ndeno-dev.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect.arn
    }

    viewer_protocol_policy = "redirect-to-https"
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

data "aws_iam_policy_document" "ndeno-dev" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.ndeno-dev.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.ndeno-dev.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "ndeno-dev" {
  bucket = aws_s3_bucket.ndeno-dev.id
  policy = data.aws_iam_policy_document.ndeno-dev.json
}

// TODO - CF function to verify /route + redirect - else redirect to root
# resource "aws_cloudfront_function" "redirect" {
#   name    = "redirect"
#   runtime = "cloudfront-js-1.0"
#   publish = true
#   code    = file("${path.module}/modules/cloudfront_functions/redirect.js")
# }
