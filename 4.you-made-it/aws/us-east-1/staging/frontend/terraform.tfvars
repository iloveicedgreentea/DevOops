environment = "staging"
region = "us-east-1"
# Cloudfront bucket name
s3_bucket_name = "cac-frontend-staging-39j23ij1"
default_root_object = "index.html"
acm_certificate_arn = "arn:aws:acm:us-east-1:656509764755:certificate/843619b4-16f8-4eb0-bf93-98f3471ce44d"

# Set to true and update list below to set an alias
use_alias = true
cloudfront_aliases = ["staging.findcovidtesting.com"]

# US and Europe edge locations
price_class = "PriceClass_100"
