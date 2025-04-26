variable "ecr_repo_name" {
  description = "ECR repository name"
  type        = string
  default     = "jpmoraess"
}

variable "region" {
  description = "The AWS region to deploy the ECS cluster in."
  type        = string
  default     = "us-east-1"

}
