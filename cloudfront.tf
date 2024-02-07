provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "random_string" "random" { 
    length = 6
    special = false 
    upper = false 
}

resource "aws_s3_bucket" "my_bucket" { 
    bucket = "rossislike-cloudfront-v${random_string.random.result}"
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.my_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_blocked" { 
    bucket = aws_s3_bucket.my_bucket.id
 
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    bucket_key_enabled = true
  }
}

locals { 
    s3_origin_id = "${random_string.random.result}-origin"
    hosted_zone_id = "Z08726341PYJE1TO4OC0C"
    my_domain = "rossagginie.com"
    acm_arn = "arn:aws:acm:us-east-1:442359104502:certificate/1d0d2a9a-2c82-4d9f-89a6-887da1f70051"
}

resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "index.html"
  source = "index.html"
  etag = filemd5("index.html")
  content_type = "text/html"
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = aws_s3_bucket.my_bucket.bucket_regional_domain_name
  description                       = "${random_string.random.result}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" { 
    origin {
        domain_name              = aws_s3_bucket.my_bucket.bucket_regional_domain_name
        origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
        origin_id                = local.s3_origin_id
    }

    enabled = true
    is_ipv6_enabled = false
    comment = "S3 bucket distribution"
    default_root_object = "index.html"

    aliases = ["rossagginie.com", "*.rossagginie.com"]

    default_cache_behavior {
        compress = true
        viewer_protocol_policy = "allow-all"
        allowed_methods = ["GET", "HEAD"]
        cached_methods = ["GET", "HEAD"]
        
        target_origin_id = local.s3_origin_id
        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }

        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }

    restrictions {
        geo_restriction {
            restriction_type = "whitelist"
            locations        = ["US", "CA", "GB", "DE"]
        }
    }

    price_class = "PriceClass_100"

    tags = {
        Environment = "development"
    }

    viewer_certificate {
        cloudfront_default_certificate = true
        acm_certificate_arn = local.acm_arn
        ssl_support_method = "sni-only"
        minimum_protocol_version = "TLSv1.2_2021"
    }
}

data "aws_iam_policy_document" "s3_policy_data" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.my_bucket.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
        test     = "StringEquals"
        variable = "aws:SourceArn"
        values   = ["${aws_cloudfront_distribution.s3_distribution.arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.my_bucket.id
  policy = data.aws_iam_policy_document.s3_policy_data.json
}

resource "aws_route53_record" "www" {
  zone_id = local.hosted_zone_id
  name    = local.my_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

output "cloudfront_endpoint" {
    value = "https://${aws_route53_record.www.name}"
}