requires the values of hostname, username and password to be passed as variables 

### TO RUN
~~~
  terraform init
  terraform plan
  terraform destroy -auto-approve
  terraform apply -auto-approve -var-file=terraform.tfvars
~~~
OR 
~~~
  terraform init
  terraform plan
  terraform destroy -auto-approve
  TF_VAR_hostname=your-hostname
  TF_VAR_username=your-username
  TF_VAR_password=your-password
  terraform apply -auto-approve
~~~
