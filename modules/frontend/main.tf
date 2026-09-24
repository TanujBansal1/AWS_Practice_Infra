# Static site bucket - never reachable directly, only via CloudFront's
# Origin Access Control (OAC). force_destroy so `terraform destroy` works
# even while the CI-synced site files are still in the bucket.
resource "aws_s3_bucket" "frontend" {
  bucket_prefix = "${var.name_prefix}-frontend-"
  force_destroy = true

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning left off on purpose - the site content is fully reproducible
# from the repo and re-synced on every deploy, so old versions aren't worth
# the extra storage cost for a demo project.
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Disabled"
  }
}

# OAC (the modern replacement for the older OAI) lets CloudFront sign
# requests to the private S3 origin with SigV4 - no bucket ACLs or public
# access needed.
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.name_prefix}-frontend-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# AWS-0012 (no WAF attached): a WAF web ACL bills a recurring monthly fee
# regardless of traffic - not justified for a learning project's static
# demo frontend.
#tfsec:ignore:AWS-0012
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = var.price_class
  comment             = "${var.name_prefix} frontend"

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Single-page app: any path CloudFront can't find in the bucket (deep
  # links, refreshes) should still serve index.html instead of S3's raw
  # 403/404, letting client-side routing (if any is added later) work.
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # No custom domain/ACM cert for this learning project - the default
  # *.cloudfront.net certificate is free and already HTTPS-only.
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

# Grants CloudFront (via its own service principal, scoped to this specific
# distribution's ARN) read access - the bucket itself stays fully private.
data "aws_iam_policy_document" "frontend_bucket" {
  statement {
    sid    = "AllowCloudFrontOAC"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend_bucket.json
}
