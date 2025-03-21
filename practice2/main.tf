# 공급자 설정
provider "aws" {                                                   
  region = "ap-northeast-2"
  default_tags {
    tags = {
      Name = "student0-practice2"
    }
  }
}

# port 변수 설정 & 보안그룹 설정
# variable "server_port" {                                          
#   description = "The port the server will use for HTTP requests"
#   type        = number
#   default     = 8080
# }

# resource "aws_security_group" "webserver_sg" {                       
#   name = "webserver_sg-studentN"
#   vpc_id = "vpc-009e18c7ea1ae07c1"
#   ingress {
#     from_port   = var.server_port
#     to_port     = var.server_port
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# 보안그룹 설정
resource "aws_security_group" "webserver_sg" {                       
  name = "webserver-sg-studentN"
  # HTTP 포트 (8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # SSH 포트 (22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 모든 IP에서 SSH 접근 허용
  }
  tags = {
    Name = "webserver-sg-studentN"
  }
}

# 인스턴스가 들어갈 퍼블릿 서브넷 생성

resource "aws_subnet" "example_subnet" {
  vpc_id                  = "vpc-00ac17d992a484d88"       # 생성할 VPC의 ID
  cidr_block              = "172.31.0.0/24"           # 서브넷의 CIDR 블록
  availability_zone       = "ap-northeast-2a"       # 서브넷을 배치할 가용 영역
  map_public_ip_on_launch = true                    # 퍼블릭 IP 자동 할당 여부

  tags = {
    Name = "example-subnet"
  }
}

# 인스턴스 설정
resource "aws_instance" "webserver" {                             
  ami                    = "ami-04cebc8d6c4f297a3"
  instance_type          = "t2.micro"
  subnet_id = aws_subnet.example_subnet.id
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]

  # user_data = <<-EOF
  #     #!/bin/bash
  #     sudo yum update -y
  #     sudo yum install -y nginx
  #     echo "Hello, World" | sudo tee /usr/share/nginx/html/index.html
  #     sudo systemctl start nginx
  #     sudo systemctl enable nginx
  #     EOF

  user_data = <<-EOF
  #!/bin/bash
  yum update && yum install -y busybox
  echo "Hello, World!!!" > index.html
  nohup busybox httpd -f -p 8080 &
  EOF

  tags = {
    Name = "webserver-studentN"
  }
}

# output "public_ip" {
#   description = "Public ip address of web server"
#   value       = aws_instance.example.public_ip
# }

# Elastic IP 생성
resource "aws_eip" "webserver" {
  instance = aws_instance.webserver.id

}

# EC2 인스턴스의 퍼블릭 IP 출력
output "webserver_public_ip" {
  description = "Public ip address of web server"
  value       = aws_eip.webserver.public_ip
}