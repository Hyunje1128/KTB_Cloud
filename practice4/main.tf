
### 1. provider

provider "aws" {
    region = "ap-northeast-2"
    default_tags {
        tags = {
            Name = "student0"
            Subject = "cloud-programming"
            Chapter = "practice3"
        }
    }
  
}

### 2. vpc

variable "vpc_main_cidr" {
    description = "The CIDR block for the VPC."
    //type        = string
    default     = "10.0.0.0/23"
  
}

resource "aws_vpc" "my_vpc" {
    cidr_block = var.vpc_main_cidr
    instance_tenancy = "default"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "my_vpc"
    }
  
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.1.0.0/23"
}

### 3. subnet

# 3-1. subnet AZ a의 subnet

resource "aws_subnet" "pub_sub_1" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = cidrsubnet(aws_vpc.my_vpc.cidr_block, 1, 0)
    availability_zone = "ap-northeast-2a"
    map_public_ip_on_launch = true
    tags = {
        Name = "pub_sub_1"
    }   
}

resource "aws_subnet" "prv_sub_1" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = cidrsubnet(aws_vpc.my_vpc.cidr_block, 1, 1)
    availability_zone = "ap-northeast-2a"
    tags = {
        Name = "prv_sub_1"
    }   
  
}

# 3-2. subnet AZ b의 subnet

resource "aws_subnet" "pub_sub_2" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = cidrsubnet(aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block, 1, 0)
    availability_zone = "ap-northeast-2b"
    map_public_ip_on_launch = true
    tags = {
        Name = "pub_sub_2"
    }   
}

resource "aws_subnet" "prv_sub_2" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = cidrsubnet(aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block, 1, 1)
    availability_zone = "ap-northeast-2b"
    tags = {
        Name = "prv_sub_2"
    }   
  
}

# 4. Internet gateway & route table 생성

resource "aws_internet_gateway" "my_igw" {
    vpc_id = aws_vpc.my_vpc.id
    tags = {
        Name = "my_igw"
    }
}

resource "aws_route_table" "pub_rt" {
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_igw.id
    }
    tags = {
        Name = "pub_rt"
    }
}

resource "aws_route_table" "prv_rt1" {
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat_gw1.id
        }
    tags = {
        Name = "prv_rt1"
    }
}

resource "aws_route_table" "prv_rt2" {
    vpc_id = aws_vpc.my_vpc.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat_gw2.id
        }
    tags = {
        Name = "prv_rt2"
    }
}

# 5. route table 과 subnet 연결

resource "aws_route_table_association" "pub_rt_asso" {
    subnet_id = aws_subnet.pub_sub_1.id
    route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "pub_rt_asso2" {
    subnet_id = aws_subnet.pub_sub_2.id
    route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "prv_rt1_asso" {
    subnet_id = aws_subnet.prv_sub_1.id
    route_table_id = aws_route_table.prv_rt1.id
}

resource "aws_route_table_association" "prv_rt2_asso" {
    subnet_id = aws_subnet.prv_sub_2.id
    route_table_id = aws_route_table.prv_rt2.id
}

# 6. NAT gateway 생성 및 route table 연결

resource "aws_eip" "nat_eip1" {
    domain = "vpc"
}

resource "aws_eip" "nat_eip2" {
    domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw1" {
    allocation_id = aws_eip.nat_eip1.id
    subnet_id = aws_subnet.pub_sub_1.id
 
    depends_on = [
        aws_internet_gateway.my_igw
    ]
    tags = {
        Name = "nat_gw1"
    }
}

resource "aws_nat_gateway" "nat_gw2" {
    allocation_id = aws_eip.nat_eip2.id
    subnet_id = aws_subnet.pub_sub_2.id
 
    depends_on = [
        aws_internet_gateway.my_igw
    ]
    tags = {
        Name = "nat_gw2"
    }
}