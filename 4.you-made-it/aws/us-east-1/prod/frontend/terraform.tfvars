environment = "production"
region = "us-east-1"
# Cloudfront bucket name
s3_bucket_name = "cac-frontend-iejwef833161234"
default_root_object = "index.html"
acm_certificate_arn = "arn:aws:acm:us-east-1:656509764755:certificate/5e07058a-2ce5-4409-ae36-39e3c345ed38"

# Set to true and update list below to set an alias
use_alias = true
cloudfront_aliases = ["findcovidtesting.com", "www.findcovidtesting.com"]

# US and Europe edge locations
price_class = "PriceClass_100"
