### Using providers
provider "aws" {
  region     = var.region
  access_key = var.accesskey
  secret_key = var.secretkey
}


###Upload netw ssh pub key
resource "aws_key_pair" "root" {
  key_name   = "terraform"
  public_key = file("${path.module}/id_rsa.pub")
}

######NETWORK BLOCK ###########

#Create new VPC
resource "aws_vpc" "vpc1" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"

  tags = {
    Name = "vpc1"
  }
}


#Create public subnet in VPC
resource "aws_subnet" "pubsub1" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.0.0/20"
  map_public_ip_on_launch = "true"
  availability_zone       = "eu-central-1a"

  tags = {
    "network" = "pubsub1"
  }
}

#Create public subnet in VPC
resource "aws_subnet" "pubsub2" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.16.0/20"
  map_public_ip_on_launch = "true"
  availability_zone       = "eu-central-1b"

  tags = {
    "network" = "pubsub2"
  }
}

##Create Private subnet in VPC
#resource "aws_subnet" "privsub1" {
#  vpc_id                  = aws_vpc.vpc1.id
#  cidr_block              = "10.0.128.0/20"
#  availability_zone       = "eu-central-1a"
#
#  tags = {
#    "network" = "privsub1"
#	
#  }
#}
#
###Create Private subnet in VPC
#resource "aws_subnet" "privsub2" {
#  vpc_id                  = aws_vpc.vpc1.id
#  cidr_block              = "10.0.144.0/20"
#  availability_zone       = "eu-central-1b"
#
#  tags = {
#    "network" = "privsub2"
#	
#  }
#}





### Create Internet Gateway for VPC
resource "aws_internet_gateway" "gateway1" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "maingw"
  }
}


#Create route pub1
resource "aws_route_table" "public1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway1.id
  }

  tags = {
    Name = "pub1"
  }
}

resource "aws_route_table_association" "route1" {
  subnet_id      = aws_subnet.pubsub1.id
  route_table_id = aws_route_table.public1.id
}

resource "aws_route_table_association" "route2" {
  subnet_id      = aws_subnet.pubsub2.id
  route_table_id = aws_route_table.public1.id
}


###Security group
resource "aws_security_group" "main" {
  name        = "main"
  description = "Main group"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    description = "allow incoming ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {

    description = "allow  incoming http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {

    description = "allow all traffic inside vpc"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc1.cidr_block]
  }
  ingress {
    description = "allow icmp"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}



resource "aws_eip" "eip_res1" {
  instance = aws_instance.vm1.id
  vpc      = true
  tags = {
    Name = "eip_res1"
  }
}


resource "aws_eip" "eip_res2" {
  instance = aws_instance.vm2.id
  vpc      = true
  tags = {
    Name = "eip_res1"
  }
}


#resource "aws_eip_association" "eip_assoc" {
#  instance_id   = "${element(aws_instance.kub[*].id, count.index)}"
#  allocation_id = "${element(aws_eip.eip_res[*].id,count.index)}"
#
#}


### Create new VMs
resource "aws_instance" "vm1" {
  ami                         = "ami-0d527b8c289b4af7f"
  instance_type               = "t2.small"
  subnet_id                   = aws_subnet.pubsub1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.main.id]
  key_name                    = aws_key_pair.root.id
  tags = {
    Name = "node1"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/id_rsa_private")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo '127.0.0.1 ${self.tags.Name}' | sudo tee -a /etc/hosts",
      "sudo hostnamectl set-hostname ${self.tags.Name}",
      "sudo sed -i 's/#PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config",
      "sudo rm -rf /root/.ssh/authorized-keys",
      "sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/",
      "sudo chown root:root /root/.ssh/authorized_keys && sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo service sshd restart"
    ]
  }

  root_block_device {
    delete_on_termination = true
    volume_size           = 10
    volume_type           = "gp3"
  }

}


### Create new VMs2
resource "aws_instance" "vm2" {
  ami                         = "ami-0d527b8c289b4af7f"
  instance_type               = "t2.small"
  subnet_id                   = aws_subnet.pubsub2.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.main.id]
  key_name                    = aws_key_pair.root.id
  tags = {
    Name = "node2"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/id_rsa_private")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo '127.0.0.1 ${self.tags.Name}' | sudo tee -a /etc/hosts",
      "sudo hostnamectl set-hostname ${self.tags.Name}",
      "sudo sed -i 's/#PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config",
      "sudo rm -rf /root/.ssh/authorized-keys",
      "sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/",
      "sudo chown root:root /root/.ssh/authorized_keys && sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo service sshd restart"
    ]
  }

  root_block_device {
    delete_on_termination = true
    volume_size           = 10
    volume_type           = "gp3"
  }

}


resource "aws_efs_file_system" "efs1" {
  creation_token = "wordpress"
  encrypted      = true

  tags = {
    Name = "wordpress"
  }
}

resource "aws_efs_mount_target" "alpha" {
  file_system_id  = aws_efs_file_system.efs1.id
  subnet_id       = aws_subnet.pubsub1.id
  security_groups = [aws_security_group.main.id]
}

resource "aws_efs_mount_target" "beta" {
  file_system_id  = aws_efs_file_system.efs1.id
  subnet_id       = aws_subnet.pubsub2.id
  security_groups = [aws_security_group.main.id]
}


resource "aws_lb_target_group" "wordpress" {
  name        = "wordpress-gr"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc1.id
}

resource "aws_lb_target_group_attachment" "vm1" {
  target_group_arn = aws_lb_target_group.wordpress.arn
  target_id        = aws_instance.vm1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "vm2" {
  target_group_arn = aws_lb_target_group.wordpress.arn
  target_id        = aws_instance.vm2.id
  port             = 80
}

resource "aws_lb" "test" {
  name               = "Wordpress-Lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.main.id]
  subnets            = [aws_subnet.pubsub1.id, aws_subnet.pubsub2.id]

  enable_deletion_protection = false

  tags = {
    Environment = "test"
  }
}


resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
}


resource "aws_db_subnet_group" "wordpress" {
  name       = "wordpressgr"
  subnet_ids = [aws_subnet.pubsub1.id, aws_subnet.pubsub2.id]

  tags = {
    Name = "Education"
  }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "mysql" {
  allocated_storage               = 20
  engine                          = "mysql"
  engine_version                  = "8.0"
  instance_class                  = "db.t2.micro"
  db_name                         = "wordpress"
  username                        = "wordpress"
  password                        = random_password.password.result
  skip_final_snapshot             = true
  enabled_cloudwatch_logs_exports = ["error"]
  vpc_security_group_ids          = [aws_security_group.main.id]
  db_subnet_group_name            = aws_db_subnet_group.wordpress.id
}




###Show EC_ID
output "instance_id1" {
  description = "ID of the EC2 instance"
  value       = aws_instance.vm1.id
}
###Show EC_ID
output "instance_id2" {
  description = "ID of the EC2 instance"
  value       = aws_instance.vm2.id
}

###Show EC2_priv_ip
output "instance_private_ip1" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.vm1.private_ip
}

###Show EC2_priv_ip
output "instance_private_ip2" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.vm2.private_ip
}

###Show EC2_pub_ip
output "instance_public_ip1" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.vm1.public_ip
}
###Show EC2_pub_ip
output "instance_public_ip2" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.vm2.public_ip
}


###Show EC2_hostname
output "instance_hostname1" {
  description = "DNS address of the EC2 instance"
  value       = aws_instance.vm1.private_dns
}

output "instance_hostname2" {
  description = "DNS address of the EC2 instance"
  value       = aws_instance.vm2.private_dns
}


output "lb" {
  description = "DNS address of Load balancer"
  value       = aws_lb.test.dns_name
}

output "db" {
  description = "DB address"
  value       = aws_db_instance.mysql.address
}

output "db_pass" {
  description = "DB address"
  value       = random_password.password.result
  sensitive   = true
}

output "efs_id" {
  description = "efs id"
  value       = aws_efs_file_system.efs1.id
  sensitive   = true
}




#### Rendering inventory (pub IP)
resource "local_file" "inventory" {
  content = templatefile("${path.module}/inventory.tmpl",
    {
      ip1 = aws_eip.eip_res1.public_ip,
      ip2 = aws_eip.eip_res2.public_ip,

    }
  )
  filename = "${path.module}/inventory.ini"
}

#### Rendering inventory (pub IP)
resource "local_file" "passdb" {
  content = templatefile("${path.module}/passdb.tmpl",
    {
      ps  = random_password.password.result,
      dbh = aws_db_instance.mysql.address,
      efs = aws_efs_file_system.efs1.id
    }
  )
  filename = "${path.module}/roles/wordpress_inst/vars/passdb.yaml"
}


resource "null_resource" "playbook" {
  provisioner "local-exec" {
    command = "ansible-playbook -u root -i inventory.ini --private-key ~/.ssh/${var.pvt_key}  --ssh-common-args='-o StrictHostKeyChecking=no' wordpress.yml"

  }
  depends_on = [local_file.inventory]
}