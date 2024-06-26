terraform "aws_vpc" "three-tier-vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "three-tier-vpc"
    }
}


###Public Subnets

resource "aws_subnet" "three-tier-pub-sub-1" {
    vpc_id = aws_vpc.three-tier-vpc.id
    cidr_block = 10.0.0.0/28
    availability_zone = "ap-southeast-1a"
    map_public_ip_on_launch = "true"
    tags = {
        Name = "three-tier-pub-sub-1"
    }  
}

resource "aws_subnet" "three-tier-pub-sub-2" {
    vpc_id = aws_vpc.three-tier-vpc.id
    cidr_block = 10.0.0.16/28
    availability_zone = "ap-southeast-1b"
    map_public_ip_on_launch = "true"
    tags = {
        Name = "three-tier-pub-sub-2"
    }  
}


### Private Subnets

resource "aws_subnet" "there-tier-pvt-sub-1" {
  vpc_id = aws_vpc.three-tier-vpc.id
  cidr_block = "10.0.0.32/28"
  availability_zone = "ap-southeast-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "three-tier-pvt-sub-1"
  }
}

resource "aws_subnet" "three-tier-pvt-sub-2" {
    vpc_id = aws_vpc.three-tier-vpc.id
    cidr_block = "10.0.0.48/28"
    availability_zone = "ap-southeast-1b"
    map_public_ip_on_launch = false
    tags = {
      Name = "three-tier-pvt-sub-2"
    }  
}

resource "aws_subnet" "there-tier-pvt-sub-3" {
  vpc_id = aws_vpc.three-tier-vpc.id
  cidr_block = "10.0.0.64/28"
  availability_zone = "ap-southeast-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "three-tier-pvt-sub-3"
  }
}

resource "aws_subnet" "three-tier-pvt-sub-4" {
    vpc_id = aws_vpc.three-tier-vpc.id
    cidr_block = "10.0.0.80/28"
    availability_zone = "ap-southeast-1b"
    map_public_ip_on_launch = false
    tags = {
      Name = "three-tier-pvt-sub-4"
    }  
}


####Create Internet Gateway
resource "aws_internet_gateway" "three-tier-igw" {
    tags = {
        Name = "three-tier-igw"
    }
    vpc_id =  aws_vpc.three-tier-vpc.id
}

###Create a route Table
resource "aws_route_table" "three-tier-web-rt" {
    vpc_id = aws_vpc.three-tier-vpc.id
    tags = {
        Name = "three-tier-web-rt"
    }
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.three-tier-igw.id
    }  
}
resource "aws_route_table" "three-tier-app-rt" {
    vpc_id = aws_vpc.three-tier-vpc.id
    tags = {
        Name = "three-tier-app-rt"
    }
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.three-tier-natgw-01.id
    }
}

### Route Table Association

resource "aws_route_table_association" "three-tier-rt-as-1" {
    subnet_id = aws_subnet.there-tier-pvt-sub-1.id
    route_table_id =  aws_route_table.three-tier-web-rt.id  
}

resource "aws_route_table_association" "three-tier-rt-as-2" {
    subnet_id = aws_subnet.three-tier-pub-sub-2.id
    route_table_id = aws_route_table.three-tier-web-rt.id  
}
resource "aws_route_table_association" "three-tier-rt-as-3" {
    subnet_id = aws_subnet.three-tier-pvt-sub-1.id
    route_table_id = aws_route_table.three-tier-app-rt.id  
}

resource "aws_route_table_association" "three-tier-rt-as-4" {
    subnet_id = aws_subnet.three-tier-pvt-sub-2.id
    route_table_id = aws_route_table.three-tier-app-rt.id  
}

resource "aws_route_table_association" "three-tier-rt-as-5" {
  subnet_id      = aws_subnet.three-tier-pvt-sub-3.id
  route_table_id = aws_route_table.three-tier-app-rt.id
}
resource "aws_route_table_association" "three-tier-rt-as-6" {
  subnet_id      = aws_subnet.three-tier-pvt-sub-4.id
  route_table_id = aws_route_table.three-tier-app-rt.id
}

###Create an Elastic IP address for the NAT Gateway

resource "aws_eip" "three-tier-nat-eip" {
    vpc = true  
}

###NAT Gateway
resource "aws_nat_gateway" "three-tier-natgw-01" {
    allocation_id = aws_eip.three-tier-nat-eip.id
    subnet_id = aws_subnet.three-tier-pub-sub-1.id
    tags = {
      Name = "three-tier-natgw-01"
    }
    depends_on = [ aws_internet_gateway.three-tier-igw ]  
}

######### Create an EC2 Auto scanling Group - web #####
resource "aws_autoscaling_group" "three-tier-web-asg" {
    name = "three-tier-web-asg"
    launch_configuration = aws_launch_configuration.three-tier-web-lconfig.id
    vpc_zone_identifier = [aws_subnet.three-tier-pub-sub-1.id, aws_subnet.three-tier-pub-sub-2.id]
    min_size             = 2
    max_size             = 3
    desired_capacity     = 2 
}

###### Create a launch configuration for the EC2 instances #####
resource "aws_launch_configuration" "three-tier-web-lconfig" {
  name_prefix                 = "three-tier-web-lconfig"
  image_id                    = "ami-0b3a4110c36b9a5f0"
  instance_type               = "t2.micro"
  key_name                    = "three-tier-web-asg-kp"
  security_groups             = [aws_security_group.three-tier-ec2-asg-sg.id]
  user_data                   = <<-EOF
                                #!/bin/bash

                                # Update the system
                                sudo yum -y update

                                # Install Apache web server
                                sudo yum -y install httpd

                                # Start Apache web server
                                sudo systemctl start httpd.service

                                # Enable Apache to start at boot
                                sudo systemctl enable httpd.service

                                # Create index.html file with your custom HTML
                                sudo echo '
                                <!DOCTYPE html>
                                <html lang="en">
                                    <head>
                                        <meta charset="utf-8" />
                                        <meta name="viewport" content="width=device-width, initial-scale=1" />

                                        <title>A Basic HTML5 Template</title>

                                        <link rel="preconnect" href="https://fonts.googleapis.com" />
                                        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
                                        <link
                                            href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700;800&display=swap"
                                            rel="stylesheet"
                                        />

                                        <link rel="stylesheet" href="css/styles.css?v=1.0" />
                                    </head>

                                    <body>
                                        <div class="wrapper">
                                            <div class="container">
                                                <h1>Welcome! An Apache web server has been started successfully.</h1>
                                                <h2>Achintha Bandaranaike</h2>
                                            </div>
                                        </div>
                                    </body>
                                </html>

                                <style>
                                    body {
                                        background-color: #34333d;
                                        display: flex;
                                        align-items: center;
                                        justify-content: center;
                                        font-family: Inter;
                                        padding-top: 128px;
                                    }

                                    .container {
                                        box-sizing: border-box;
                                        width: 741px;
                                        height: 449px;
                                        display: flex;
                                        flex-direction: column;
                                        justify-content: center;
                                        align-items: flex-start;
                                        padding: 48px 48px 48px 48px;
                                        box-shadow: 0px 1px 32px 11px rgba(38, 37, 44, 0.49);
                                        background-color: #5d5b6b;
                                        overflow: hidden;
                                        align-content: flex-start;
                                        flex-wrap: nowrap;
                                        gap: 24;
                                        border-radius: 24px;
                                    }

                                    .container h1 {
                                        flex-shrink: 0;
                                        width: 100%;
                                        height: auto; /* 144px */
                                        position: relative;
                                        color: #ffffff;
                                        line-height: 1.2;
                                        font-size: 40px;
                                    }
                                    .container p {
                                        position: relative;
                                        color: #ffffff;
                                        line-height: 1.2;
                                        font-size: 18px;
                                    }
                                </style>
                                ' > /var/www/html/index.html

                EOF

  associate_public_ip_address = true
  lifecycle {
    prevent_destroy = true
    ignore_changes = all
  }
}