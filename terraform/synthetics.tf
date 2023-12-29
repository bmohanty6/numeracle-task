locals {
  canary_name          = format("%s-%s", var.org, var.k8s_app_name)
  artifacts_prefix     = "artifacts"
  lambda_source_prefix = "lambda-source"
  lambda_handler_key   = format("%s/%s", local.lambda_source_prefix, "demoURLMonitor.zip")
}
module "canary_s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "numeracle-task-canaries"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
  attach_deny_insecure_transport_policy = true
}
data "archive_file" "handler" {
  type = "zip"
  source {
    content = templatefile("./files/canary_source_template.tftpl", {
      app_url = format("http://%s", kubernetes_service_v1.numeracle-demo-app.status.0.load_balancer.0.ingress.0.hostname)
    })
    filename = "python/demoURLMonitor.py"
  }
  output_path = "./files/demoURLMonitor.zip"
}
resource "aws_s3_object" "lambda_source" {
  key    = local.lambda_handler_key
  bucket = module.canary_s3_bucket.s3_bucket_id
  source = "./files/demoURLMonitor.zip"
}
resource "aws_synthetics_canary" "demo-app-monitor" {
  name                 = local.canary_name
  artifact_s3_location = format("s3://%s/%s", module.canary_s3_bucket.s3_bucket_id, local.artifacts_prefix)
  execution_role_arn   = aws_iam_role.synthetic_canary_access.arn
  handler              = "demoURLMonitor.handler"
  s3_bucket            = module.canary_s3_bucket.s3_bucket_id
  s3_key               = local.lambda_handler_key
  runtime_version      = "syn-python-selenium-2.0"
  start_canary         = true

  schedule {
    expression = "cron(0/5 * * * ? *)"
  }
}

resource "aws_iam_role" "synthetic_canary_access" {
  name = format("%s-role", local.canary_name)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  inline_policy {
    name = format("%s-access", local.canary_name)
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject"
          ]
          Resource = [
            format("arn:aws:s3:::%s/*", module.canary_s3_bucket.s3_bucket_id)
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "s3:GetBucketLocation"
          ]
          Resource = [
            format("arn:aws:s3:::%s", module.canary_s3_bucket.s3_bucket_id)
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:CreateLogGroup"
          ],
          Resource = [
            format("arn:aws:logs:%s:%s:log-group:/aws/lambda/cwsyn-%s-*", var.aws_region, data.aws_caller_identity.current.account_id, local.canary_name)
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "s3:ListAllMyBuckets",
            "xray:PutTraceSegments"
          ],
          Resource = [
            "*"
          ]
        },
        {
          Effect   = "Allow"
          Resource = "*"
          Action   = "cloudwatch:PutMetricData"
          Condition = {
            StringEquals = {
              "cloudwatch:namespace" = "CloudWatchSynthetics"
            }
          }
      }]
    })
  }
}