# S3

terraform init

terraform plan

terraform plan -out out/terraform_s3_plan

terraform apply "out/terraform_s3_plan"

terraform destroy

# Public Key

ssh-keygen -t rsa -b 2048