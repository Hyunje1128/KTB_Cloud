provider "aws" {
  region = "ap-northeast-2"  # 서울 리전
}

resource "aws_instance" "practice1" {
  ami           = "ami-062cddb9d94dcf95d"  # Amazon Linux 2 AMI (서울 리전)
  instance_type = "t2.micro"
  key_name      = "student1-key"  # AWS에서 생성한 키페어 이름
    subnet_id =  "subnet-03956e6dde3714bed"

  tags = {
    Name = "Terraform-Instance"
  }
}
