provider "aws" {
  region = "us-east-1"
   access_key = "use your own key from security credentials"
  secret_key = "use your own key from security credentials"
}
# create a vpc ------------------------------------1.

resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
   Name = "production"
  }
}

# create Internet Gateway -------------------------------2.

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "Production-IG"
  }
}

# create custom route table --------------------------------3. 

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod"
  }
}

# create subnet -----------------------------------------------------4.

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "prod subnet"
  }
}

# Associate subnet with route table ---------------------------------------5.

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# create security group to allow port 22,443,80 ----------------------------6.

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# create a network interface with an ip in the subnet that was created in step 4 -------------------7.

  resource "aws_network_interface" "web-server" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# Assign an elastic IP to the network Interface 

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}

# create ubuntu server and install/enable apache 2

  resource "aws_instance" "web-server"{
    ami = "ami-04505e74c0741db8d"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "mayank22"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.web-server.id
    }

    user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c "echo your very web server is ready > /var/www/html/index.html"
              EOF

    tags ={
      Name = "ubuntu-server"
    } 
  }


# resource "aws_instance" "web" {
#     ami = "ami-04505e74c0741db8d"
#     instance_type = "t2.micro"

#     tags = {
#     Name = "HelloWorld"
#   }


#   resource "aws_vpc" "firstvpc" {
#   cidr_block = "10.0.0.0/16"
#   tags = {
#     Name = "production"
#   }
# }

# resource "aws_vpc" "secondvpc" {
#   cidr_block = "10.1.0.0/16"
#   tags = {
#     Name = "dev"
#   }
# }

# resource "aws_subnet" "subnet1" {
#   vpc_id     = aws_vpc.firstvpc.id
#   cidr_block = "10.0.1.0/24"

#   tags = {
#     Name = "prod subnet"
#   }
# }

# resource "aws_subnet" "subnet2" {
#   vpc_id     = aws_vpc.secondvpc.id
#   cidr_block = "10.1.1.0/24"

#   tags = {
#     Name = "dev subnet"
#   }
# }
  
