


## Description:
 This code deploys in one command Wordpress onto two AWS EC2 instances, with shared EFS for Wordpress content files, creates Amazon RDS (MYSQL DB), creates Application load balancer.

### Attention:
At this moment **there isn't Route53 DNS** in this code
 
![image](https://miro.medium.com/max/1200/1*NB8QjhhDnkjauxTgx7QjKQ.png)


##  Requirements:
  - Ansible >= 2.0
  - Terraform >= 1.0
  - AWS account
  - Created SSH key in AWS  

## Parameters:
1. In this project uses t2.micro EC2 intsances
2. Amazon RDS (t2.micro)
3. After deploying you can find password for Amazon RDS database in roles/wordpress_inst/vars/passdb.yaml


## Quick start:
1. Clone repo
2. Initialize terraform modules
```
terraform init
```
3.  Validate code
```
terraform init
```
4. See what terraform will build
```
terraform plan
```
5. Build 
```
terraform apply
```
5.1. Terraform asks you to enter name of  existing ssh key (see name in AWS Console/EC2/Key pairs). **e.g. wordpress**
5.2. Terraform asks you to enter full path to your pirvate part of  AWS ssh key. **e.g. ~/.ssh/wordpress.pem** 







## License
GNU GPL v3