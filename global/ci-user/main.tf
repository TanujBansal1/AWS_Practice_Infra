terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# Fallback from OIDC only. Static access keys should be rotated and removed
# in production once the OIDC path is working end-to-end.
resource "aws_iam_user" "github_actions_ci" {
  name = "github-actions-ci"
  path = "/"

  tags = var.tags
}

resource "aws_iam_access_key" "github_actions_ci" {
  user = aws_iam_user.github_actions_ci.name
}

data "aws_iam_policy_document" "github_actions_ci" {
  statement {
    sid    = "TerraformStateBucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketVersions",
    ]
    resources = ["arn:aws:s3:::tanay-tf-state-phase-one"]
  }

  statement {
    sid    = "TerraformStateObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObjectVersion",
      "s3:DeleteObjectVersion",
    ]
    resources = ["arn:aws:s3:::tanay-tf-state-phase-one/*"]
  }

  statement {
    sid    = "DynamoDBLockTableAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = ["arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/terraform-locks"]
  }

  statement {
    sid    = "EcrFullAccess"
    effect = "Allow"
    actions = [
      "ecr:*",
    ]
    resources = ["*"]
  }

  # Full lifecycle actions terraform apply/destroy needs for cluster, service,
  # and task definition resources - the original narrow list (Update/Describe
  # Services + Register/DescribeTaskDefinition) was missing Create/Delete for
  # clusters and services, and tagging, which caused AccessDeniedException.
  statement {
    sid    = "EcsDeployAccess"
    effect = "Allow"
    actions = [
      "ecs:CreateCluster",
      "ecs:DeleteCluster",
      "ecs:DescribeClusters",
      "ecs:CreateService",
      "ecs:UpdateService",
      "ecs:DeleteService",
      "ecs:DescribeServices",
      "ecs:ListServices",
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
      "ecs:ListTaskDefinitions",
      "ecs:TagResource",
      "ecs:UntagResource",
      "ecs:ListTagsForResource",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IamPassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "BroadTerraformApplyAccess"
    effect = "Allow"
    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
      "rds:*",
      "logs:*",
      "iam:*",
      "secretsmanager:*",
      "application-autoscaling:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "github_actions_ci" {
  name   = "github-actions-ci-inline"
  user   = aws_iam_user.github_actions_ci.name
  policy = data.aws_iam_policy_document.github_actions_ci.json
}