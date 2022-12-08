terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.3.6"
}

variable "buildDir" {
  type = string
  default = ".terraform-build"
}

variable "stackName" {
  type = string
  default = "terraform-test"
}

locals {
  excludes = [
    ".terraform",
    ".terraform.lock.hcl",
    ".terraform.tfstate.lock.info",
    "terraform.tfstate",
    "terraform.tfstate.backup",
    "planfile",
    "destroyplan",
    ".git",
    "${var.buildDir}"
  ]
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.stackName}-iam_for_lambda"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
EOF
}

resource "aws_lambda_function" "test_lambda" {
    filename = "${var.buildDir}/${var.stackName}.zip"
    function_name = "${var.stackName}-test_lambda"
    handler = "src/index.handler"
    runtime = "nodejs16.x"
    role = "${aws_iam_role.iam_for_lambda.arn}"
    source_code_hash = filebase64sha256("${var.buildDir}/${var.stackName}.zip")//for updating lambda
    depends_on = [
      data.archive_file.lambdazip
    ]
}
resource "aws_cloudwatch_log_group" "test_lambda_log_group" {
  name = "/aws/lambda/${split(":", "${aws_lambda_function.test_lambda.arn}")[length(split(":", "${aws_lambda_function.test_lambda.arn}")) - 1]}"
}


resource "aws_lambda_function" "test_lambda2" {
    filename = "${var.buildDir}/${var.stackName}.zip"
    function_name = "${var.stackName}-test_lambda2"
    handler = "src2/index.handler"
    runtime = "nodejs16.x"
    role = "${aws_iam_role.iam_for_lambda.arn}"
    source_code_hash = filebase64sha256("${var.buildDir}/${var.stackName}.zip")//for updating lambda
    depends_on = [
      data.archive_file.lambdazip
    ]
}
resource "aws_cloudwatch_log_group" "test_lambda2_log_group" {
  name = "/aws/lambda/${split(":", "${aws_lambda_function.test_lambda2.arn}")[length(split(":", "${aws_lambda_function.test_lambda2.arn}")) - 1]}"
}

data "archive_file" "lambdazip" {
  type = "zip"
  output_path = "${var.buildDir}/${var.stackName}.zip"
  source_dir = "${path.module}/"
  excludes = local.excludes
}

