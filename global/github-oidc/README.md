# global/github-oidc

One-time bootstrap Terraform config for CI/CD authentication.

Provisions the GitHub Actions OIDC identity provider and IAM role that
workflows assume, avoiding long-lived AWS access keys.

The `github_repository` variable must be set to the exact `owner/repo`
slug that is allowed to assume the role.
