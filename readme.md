requires the values of hostname, username and password to be passed as variables to be 

TO RUN

$ terraform init
$ terraform plan
$ terraform destroy -auto-approve

$ terraform apply -auto-approve -var-file=terraform.tfvars

OR

$ TF_VAR_hostname=your-hostname
$ TF_VAR_username=your-username
$ TF_VAR_password=your-password
$ terraform apply -auto-approve
