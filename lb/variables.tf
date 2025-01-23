variable "region" {
  type = string
  default = "us-east-1"
}

variable "vpc_id" {
  type = string
  default = "vpc-0898a93565218e090"
}

variable "subnets" {
  type = list
  default = ["subnet-0e68041adde17c4cd", "subnet-03bbaddaf838bbaa5"]
}

variable "instance_id" {
  type = string
  default = "i-006b0496565380035"
}