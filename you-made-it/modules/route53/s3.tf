# allows redirect
resource "aws_s3_bucket" "fc19torg" {
  count = var.environment == "production" ? 1 : 0
  bucket = local.fc19torg
  acl    = "public-read"

  website {

    redirect_all_requests_to = "https://${local.fctcom}"
  }
}
