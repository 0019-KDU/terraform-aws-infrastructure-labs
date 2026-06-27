resource "aws_instance" "example" {
  ami           = "ami-0912f71e06545ad88"
  count         = var.instance_count
#   instance_type = "t3.micro"
 instance_type= var.environment=="dev" ? "t2.micro" : "t3.micro"

  tags = var.resource_tags
}

resource "aws_security_group" "example" {
  name  = "sg"
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port = ingress.value.from_port
      to_port = ingress.value.to_port
      cidr_blocks = ingress.value.cidr_blocks
      protocol = ingress.value.protocol
    }
  }

  egress=[] 
}


locals {
  all_instance_ids= aws_instance.example[*].id
}