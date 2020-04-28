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