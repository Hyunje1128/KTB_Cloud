#cluste.tf

# EC2 인스턴스(webserver) 보안그룹 생성
resource "aws_security_group" "webserver_sg" {
    name = "webserver_sg-studentN"
    vpc_id = aws_vpc.my_vpc.id
    
    # 8080 포트 허용 (인바운드) - ALB로부터 오는 트래픽 허용
    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = [aws_subnet.pub_sub_1.cidr_block, aws_subnet.pub_sub_2.cidr_block]
        security_groups = [aws_security_group.alb_sg.id]  # ALB 보안그룹으로부터

    }
    # SSH 포트 (22) 이 설정이 있어야 ec2 연결 가능(key없이)
    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 모든 IP에서 SSH 접근 허용
    }

    # 아웃바운드 규칙 추가 - 필수!
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Launch Template 생성
resource "aws_launch_template" "Webserver_template" {
    name =  "webserver_launch_template-studentN"
    image_id = "ami-062cddb9d94dcf95d" # Amazon Linux 2023 AMI
    instance_type = "t3.micro" # 인스턴스 유형

   network_interfaces {
        security_groups = [aws_security_group.webserver_sg.id]
        associate_public_ip_address = true
    }
    
    user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx  # nginx 설치
    mkdir -p /usr/share/nginx/html
    echo "Hello, World 333" > /usr/share/nginx/html/index.html
    
    # nginx 서비스 시작
    systemctl start nginx
    systemctl enable nginx
    
    # 서비스가 시작됐는지 확인
    echo "nginx service started on port 80" >> /tmp/startup.log
    EOF
    )

}

# Auto Scaling Group 생성
resource "aws_autoscaling_group" "webserver_asg" {
    vpc_zone_identifier = [ aws_subnet.pub_sub_1.id, aws_subnet.pub_sub_2.id ]
    target_group_arns = [ aws_lb_target_group.target_asg.arn ]
    
    health_check_type = "ELB"
    health_check_grace_period = 300  # 5분의 그레이스 기간

    min_size = 2 # 최소 인스턴스 수
    max_size = 2 # 최대 인스턴스 수
    desired_capacity = 2  # 기본 인스턴스 수 (최초 생성 시 2개로 시작)

    launch_template {
        id      = aws_launch_template.Webserver_template.id
        version = "$Latest" # 항상 최신 버전 시작 템플릿 사용
    }
    
    depends_on = [aws_launch_template.Webserver_template, aws_subnet.pub_sub_1, aws_subnet.pub_sub_2, aws_lb_target_group.target_asg ]
}

# ALB 보안그룹 생성
resource "aws_security_group" "alb_sg" {
    name = var.alb_security_group_name # ALB 보안 그룹 이름
    vpc_id = aws_vpc.my_vpc.id
    
    # 8080 포트 허용 (인바운드)
    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }
    # 전체 IP 트래픽 허용 (아웃바운드)
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [var.my_ip] # 모든 IP 허용
    } 
}

# ALB 생성
resource "aws_lb" "webserver_alb" {
    name = var.alb_name # ALB 이름
    load_balancer_type = "application" # ALB 유형
    subnets = [ aws_subnet.pub_sub_1.id, aws_subnet.pub_sub_2.id ]
    security_groups = [ aws_security_group.alb_sg.id ]
}

resource "aws_lb_target_group" "target_asg" {
    name = var.alb_name
    port = var.server_port
    protocol = "HTTP"
    vpc_id = aws_vpc.my_vpc.id
  
    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 60
        timeout = 15
        healthy_threshold = 3
        unhealthy_threshold = 3
    }
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.webserver_alb.arn
    port = var.server_port
    protocol = "HTTP"
  
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.target_asg.arn
    }
}

resource "aws_lb_listener_rule" "webserver_asg_rule" {
    listener_arn = aws_lb_listener.http.arn
    priority     = 100

    condition {
        path_pattern {
            values = ["/"]  # 예시: `/index.html`로 제한
						    # 경로패턴 ["*"] 경로가 문제인거 같은데?
        }
    }

    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.target_asg.arn
    }
}