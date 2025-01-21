terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "jpmoraess" {
    bucket = "jpmoraess"
}

resource "aws_s3_bucket_versioning" "jpmoraess_versioning" {
  bucket = aws_s3_bucket.jpmoraess.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_cors_configuration" "jpmoraess_cors" {
  bucket = aws_s3_bucket.jpmoraess.id
  cors_rule {
    allowed_methods = [ "GET" ]
    allowed_origins = [ "*" ]
    expose_headers = [ "ETag" ]
    max_age_seconds = 3000
  }
}
