
variable "region" {
  description = "aws region"
  default     = "us-east-1"
}

variable "cloudfront_domain" {
  description = "Domain to cloudfront dist"
}
variable "website_cloudfront_domain" {
  description = "Domain to website cloudfront dist"
}

variable "environment" {
  description = "Environment to deploy into"
}


