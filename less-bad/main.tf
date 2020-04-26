resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "frontend"
}

locals {
  s3_origin_id  = "frontend"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Frontend CF"
  default_root_object = var.default_root_object

  aliases = var.use_alias ? var.cloudfront_aliases : []

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "DELETE", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "static/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = var.price_class

  tags = {
    Environment = var.environment
  }

  viewer_certificate {
    acm_certificate_arn = var.acm_certificate_arn
    ssl_support_method = "sni-only"
  }
}

data "aws_caller_identity" "current" {}

# Policy and user for GH actions to invalidate, upload to s3
data "aws_iam_policy_document" "github" {

  statement {
    actions = [
      "s3:DeleteObject",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}/*",
      
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      
    ]
  }

  statement {
    actions = [
      "cloudfront:ListInvalidations",
      "cloudfront:GetInvalidation",
      "cloudfront:CreateInvalidation"
    ]

    resources = [
      "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.s3_distribution.id}"
    ]
  }
}

resource "aws_iam_policy" "github" {
  name   = "${var.environment}-github_actions"
  path   = "/"
  policy = data.aws_iam_policy_document.github.json
}

resource "aws_iam_user" "github" {
  name = "${var.environment}-github_actions"
  path = "/"
  tags = {
    Terraform = "true"
  }
}

resource "aws_iam_user_policy_attachment" "github" {
  user       = aws_iam_user.github.name
  policy_arn = aws_iam_policy.github.arn
}

# S3
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.oai.iam_arn}"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.frontend.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket" "frontend" {
  # random string since buckets are global
  bucket = var.s3_bucket_name
  acl    = "private"

  versioning {
    enabled = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "frontend"
    Terraform = "true"
  }

  region = var.region

  # TF metadata
  lifecycle {
    prevent_destroy = true
  }
}

# Allow CF OAI to access bucket
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

data "aws_route53_zone" "selected" {
  name         = "${local.fctcom}."
  private_zone = false
}
data "aws_route53_zone" "website" {
  name         = "${local.codersagainstcovidorg}."
  private_zone = false
}

# Hosted zones
resource "aws_route53_zone" "findcovidtestingcom" {
  count = var.environment == "production" ? 1 : 0
  name = local.fctcom
}
resource "aws_route53_zone" "findcovid19testingorg" {
  count = var.environment == "production" ? 1 : 0
  name = local.fc19torg
}
resource "aws_route53_zone" "codersagainstcovidorg" {
  count = var.environment == "production" ? 1 : 0
  name = local.codersagainstcovidorg
}

#######################
# codersagainstcovid.org
#######################

# cname www to apex domain
resource "aws_route53_record" "website-www" {
  zone_id = data.aws_route53_zone.website.zone_id
  count = var.environment == "production" ? 1 : 0
  name    = "www"
  type    = "CNAME"
  ttl     = "500"
  records = ["${local.codersagainstcovidorg}"]
}

# main site to cloudfront
resource "aws_route53_record" "website-cloudfront" {
  zone_id = data.aws_route53_zone.website.zone_id
  name    = var.environment == "production" ? "${local.codersagainstcovidorg}" : "${local.codersagainstcovidorg_staging}"
  type    = "A"

  alias {
    name                   = var.website_cloudfront_domain
    zone_id                = "Z2FDTNDATAQYW2" # this is static
    evaluate_target_health = false
  }
}

#######################
# findcovidtesting.com
#######################

# cname www to apex domain
resource "aws_route53_record" "www" {
  count = var.environment == "production" ? 1 : 0
  zone_id = aws_route53_zone.findcovidtestingcom[0].zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = "500"
  records = ["${local.fctcom}"]
}

# main site to cloudfront
resource "aws_route53_record" "fctcom-cloudfront" {
  count = var.environment == "production" ? 1 : 0
  zone_id = aws_route53_zone.findcovidtestingcom[0].zone_id
  name    = local.fctcom
  type    = "A"

  alias {
    name                   = var.cloudfront_domain
    zone_id                = "Z2FDTNDATAQYW2" # this is static
    evaluate_target_health = false
  }
}

# Had to do it this way because resources were already created and changing module logic would cause downtime
resource "aws_route53_record" "fctcom-cloudfront-staging" {
  count = var.environment == "staging" ? 1 : 0
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = local.fctcom_staging
  type    = "A"

  alias {
    name                   = var.cloudfront_domain
    zone_id                = "Z2FDTNDATAQYW2" # this is static
    evaluate_target_health = false
  }
}
# allows redirect
resource "aws_s3_bucket" "fc19torg" {
  count = var.environment == "production" ? 1 : 0
  bucket = local.fc19torg
  acl    = "public-read"

  website {

    redirect_all_requests_to = "https://${local.fctcom}"
  }
}
