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
