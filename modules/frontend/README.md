# modules/frontend

Reusable Terraform module for the static frontend.

Provisions a private S3 bucket (no public access) fronted by a CloudFront
distribution using Origin Access Control (OAC), so the bucket is only ever
reachable through CloudFront over HTTPS. Deploy the built frontend files by
syncing them to the `bucket_name` output and invalidating
`cloudfront_distribution_id` afterwards.
