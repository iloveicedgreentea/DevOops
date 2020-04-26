output "cf_url" {
  description = "CF Dist url"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}
output "cf_hosted_zone" {
  description = "CF Dist hosted zone"
  value       = aws_cloudfront_distribution.s3_distribution.hosted_zone_id 
}
