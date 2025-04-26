# S3

terraform init

terraform plan

terraform plan -out out/terraform_s3_plan

terraform apply "out/terraform_s3_plan"

terraform destroy

# Public Key

ssh-keygen -t rsa -b 2048


# EKS
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)

kubectl cluster-info

kubectl get nodes