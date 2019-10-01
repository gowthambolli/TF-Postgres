requires the values of hostname, username and password to be passed as variables 

<<<<<<< HEAD
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
=======
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
>>>>>>> 44304c5bdc6ff34ecdff667b93633c02efb8e3d0
