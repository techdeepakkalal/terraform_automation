terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# -------------------------
# SECURITY GROUP
# -------------------------
resource "aws_security_group" "flask_sg" {
  name = "flask-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------
# EC2 INSTANCE
# -------------------------
resource "aws_instance" "flask_ec2" {
  ami                    = "ami-0532be01f26a3de55" # Amazon Linux (us-east-1)
  instance_type          = "t3.micro"
  key_name               = "test123"
  vpc_security_group_ids = [aws_security_group.flask_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 git

              # App directory
              mkdir -p /opt/flask-app
              cd /opt/flask-app

              # Flask app
              cat << 'EOPY' > app.py
              from flask import Flask
              import os

              app = Flask(__name__)

              @app.route("/")
              def hello():
                  return "Flask app running via Terraform user-data 🚀"

              if __name__ == "__main__":
                  app.run(host="0.0.0.0", port=5000)
              EOPY

              # Install Flask
              pip3 install flask

              # Run app in background
              nohup python3 app.py > app.log 2>&1 &
              EOF

  tags = {
    Name = "terraform-flask-ec2"
  }
}
