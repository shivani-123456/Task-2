provider "aws" {
  region = var.aws_region
}


resource "aws_vpc" "terraform-vpc" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}



/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  tags = {
    Name        = var.internet_gw_name
  }
}

/* Public subnet */
resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.terraform-vpc.id}"
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true
  tags = {
    Name        = var.subnet_name
  }
}


/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  tags = {
    Name        = var.route_name
  }
}


resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.ig.id}"
}


/* Route table associations */
resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public.id}"
}


## Security Group for Ec2 instance##
resource "aws_security_group" "terraform_private_sg" {
  description = "Allow limited inbound external traffic"
  vpc_id      = "${aws_vpc.terraform-vpc.id}"
  name        = "terraform_ec2_private_sg"

  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 80
  }

 ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 80
  }


  egress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }

  tags = {
    Name = var.sg_name
  }
}




resource "aws_instance" "public_ec2" {
    ami = "ami-0b614a5d911900a9b"
    instance_type = "t2.micro"
    security_groups =  [ "${aws_security_group.terraform_private_sg.id}" ]
    subnet_id = "${aws_subnet.public_subnet.id}"
    user_data= <<-EOF
	#! /bin/bash -ex
	 sudo yum install httpd -y
         sudo systemctl start httpd
         sudo systemctl enable httpd
         echo "<h1>Sample Webserver Network Nuts" | sudo tee  /home/573855.cloudwaysapps.com/hfjzxghgzg/public_html/html/index.html
 
    EOF
    key_name="s3-ec2"
     root_block_device {
    volume_size           = "100"
}
    associate_public_ip_address = true
    tags = {
      Name              = var.ec2_name
      Environment       = "development"
      Project           = "TERRAFORM"
    }
}

resource "aws_ebs_volume" "data-vol" {
 availability_zone = "us-east-2a"
 size = 200
 tags = {
        Name = "data-volume"
 }

}

resource "aws_volume_attachment" "good-morning-vol" {
 device_name = "/dev/xvdb"
 volume_id = "${aws_ebs_volume.data-vol.id}"
 instance_id = "${aws_instance.public_ec2.id}"
}


