# Terraform: Conditional Expressions, Splat Expressions & Dynamic Blocks

> **Lesson Goal:** Master three of Terraform's most powerful HCL features to write flexible, DRY, and production-ready infrastructure code.

---

## Table of Contents

1. [Conditional Expressions](#1-conditional-expressions)
2. [Splat Expressions](#2-splat-expressions)
3. [Dynamic Blocks](#3-dynamic-blocks)
4. [This Lesson's Code Walkthrough](#4-this-lessons-code-walkthrough)
5. [Production Best Practices](#5-production-best-practices)

---

## 1. Conditional Expressions

### What Is It?

A **conditional expression** evaluates a boolean condition and returns one of two values — identical to a ternary operator in most programming languages.

```hcl
condition ? value_if_true : value_if_false
```

### Syntax

```hcl
variable "environment" {
  type    = string
  default = "dev"
}

resource "aws_instance" "web" {
  ami           = "ami-0912f71e06545ad88"
  instance_type = var.environment == "prod" ? "t3.large" : "t2.micro"
}
```

| Environment | Result         |
|-------------|----------------|
| `prod`      | `t3.large`     |
| `dev`/any   | `t2.micro`     |

### How It Works

- The **condition** must resolve to `true` or `false`
- Both branches must return the **same type** (string, number, bool, etc.)
- Conditions support: `==`, `!=`, `>`, `<`, `>=`, `<=`, `&&`, `||`, `!`

### Production Use Case: Environment-Aware Sizing

In real-world production infrastructure you never want to hard-code instance sizes. A single variable controls the entire fleet:

```hcl
# variables.tf
variable "environment" {
  type        = string
  description = "Deployment environment: dev | staging | prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

# main.tf
resource "aws_instance" "api_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.environment == "prod" ? "t3.xlarge" : "t3.micro"

  # Enable deletion protection only in prod
  disable_api_termination = var.environment == "prod" ? true : false

  # Use encrypted storage in prod only
  root_block_device {
    encrypted = var.environment == "prod" ? true : false
  }
}

# Enable enhanced monitoring only when needed
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  count = var.environment == "prod" ? 1 : 0
  # ... alarm config
}
```

**Real scenarios where this is used:**
- Choosing instance size per environment (dev/staging/prod)
- Enabling/disabling monitoring, backups, or multi-AZ only in prod
- Selecting between single-AZ (dev) and Multi-AZ RDS (prod)
- Toggling deletion protection on databases

---

## 2. Splat Expressions

### What Is It?

A **splat expression** (`[*]`) extracts a single attribute from **every element** in a list of resources or objects — replacing verbose `for` loops with a single concise expression.

```hcl
resource_type.resource_name[*].attribute
```

### Syntax

```hcl
# Create 3 EC2 instances
resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-0912f71e06545ad88"
  instance_type = "t2.micro"
}

# Collect ALL instance IDs in one line
output "all_instance_ids" {
  value = aws_instance.web[*].id
}

# Collect ALL private IPs
output "all_private_ips" {
  value = aws_instance.web[*].private_ip
}
```

**Output:**
```
all_instance_ids = ["i-0abc123", "i-0def456", "i-0ghi789"]
all_private_ips  = ["10.0.1.10", "10.0.1.11", "10.0.1.12"]
```

### Splat vs For Expression

| Need                              | Use                                         |
|-----------------------------------|---------------------------------------------|
| Extract one attribute from all    | `resource[*].attr`                          |
| Filter, transform, or multi-attr  | `[for r in resource : r.attr if condition]` |

### Production Use Case: Load Balancer Target Registration

When you scale out EC2 instances and need to register all of them with a load balancer or pass IPs to another module:

```hcl
# Auto-scaling fleet of app servers
resource "aws_instance" "app_server" {
  count         = var.instance_count
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.medium"
  subnet_id     = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
}

# Register ALL instances with an ALB target group using splat
resource "aws_lb_target_group_attachment" "app" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app_server[count.index].id
  port             = 8080
}

# Pass all private IPs to an Ansible inventory or SSM parameter
resource "aws_ssm_parameter" "app_server_ips" {
  name  = "/prod/app/server-ips"
  type  = "StringList"
  value = join(",", aws_instance.app_server[*].private_ip)
}

# Output all IDs for a downstream module
output "app_server_ids" {
  value = aws_instance.app_server[*].id
}
```

**Real scenarios where this is used:**
- Collecting all EC2 IDs to pass into an Auto Scaling Group or Target Group
- Gathering all subnet IDs created by a VPC module
- Extracting all Route53 record values for DNS verification
- Building an Ansible inventory from a fleet of servers

---

## 3. Dynamic Blocks

### What Is It?

A **dynamic block** generates repeated nested configuration blocks from a list or map variable — eliminating copy-paste and making resources data-driven.

```hcl
dynamic "block_name" {
  for_each = var.some_list_or_map
  content {
    # use block_name.value.attribute or block_name.key
  }
}
```

### Without Dynamic Block (Bad — Hard-coded)

```hcl
resource "aws_security_group" "web" {
  name = "web-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  # Adding a new port = editing HCL. Not scalable.
}
```

### With Dynamic Block (Good — Data-Driven)

```hcl
# variables.tf
variable "ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
}

# main.tf
resource "aws_security_group" "web" {
  name = "web-sg"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress = []
}
```

```hcl
# terraform.tfvars
ingress_rules = [
  { from_port = 80,  to_port = 80,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"],   description = "HTTP"  },
  { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"],   description = "HTTPS" },
  { from_port = 22,  to_port = 22,  protocol = "tcp", cidr_blocks = ["10.0.0.0/8"],  description = "SSH internal" },
]
```

Adding a new port now = **one line in tfvars**. Zero HCL changes.

### Dynamic Block Iterator Name

By default the iterator variable matches the block label (`ingress.value`). You can rename it with `iterator`:

```hcl
dynamic "ingress" {
  for_each = var.ingress_rules
  iterator = rule           # custom iterator name
  content {
    from_port   = rule.value.from_port
    to_port     = rule.value.to_port
    protocol    = rule.value.protocol
    cidr_blocks = rule.value.cidr_blocks
  }
}
```

### Production Use Case: Multi-Environment Security Groups via tfvars

```hcl
# environments/prod.tfvars
ingress_rules = [
  { from_port = 443,  to_port = 443,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"],       description = "HTTPS public"       },
  { from_port = 8443, to_port = 8443, protocol = "tcp", cidr_blocks = ["10.0.0.0/8"],      description = "Internal API"       },
  { from_port = 9090, to_port = 9090, protocol = "tcp", cidr_blocks = ["10.10.0.0/16"],    description = "Prometheus scrape"  },
]

# environments/dev.tfvars
ingress_rules = [
  { from_port = 80,   to_port = 80,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"],        description = "HTTP dev"           },
  { from_port = 22,   to_port = 22,  protocol = "tcp", cidr_blocks = ["203.0.113.0/24"],   description = "SSH office IP"      },
]
```

Deploy with: `terraform apply -var-file=environments/prod.tfvars`

**Real scenarios where this is used:**
- Security group rules managed entirely from tfvars (no HCL changes per team request)
- EBS volume attachments for EC2 instances
- IAM policy statements built from a list of actions/resources
- AWS WAF rules, CloudWatch log metric filters
- RDS parameter groups with many parameters

---

## 4. This Lesson's Code Walkthrough

### [main.tf](main.tf)

```hcl
# CONDITIONAL EXPRESSION — picks instance type based on environment variable
resource "aws_instance" "example" {
  ami           = "ami-0912f71e06545ad88"
  count         = var.instance_count
  instance_type = var.environment == "dev" ? "t2.micro" : "t3.micro"
  tags          = var.resource_tags
}

# DYNAMIC BLOCK — builds ingress rules from var.ingress_rules list
resource "aws_security_group" "example" {
  name = "sg"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      cidr_blocks = ingress.value.cidr_blocks
      protocol    = ingress.value.protocol
    }
  }
}

# SPLAT EXPRESSION — collects all instance IDs into a list
locals {
  all_instance_ids = aws_instance.example[*].id
}
```

### [variables.tf](variables.tf)

| Variable         | Type            | Purpose                                     |
|------------------|-----------------|---------------------------------------------|
| `environment`    | `string`        | Drives the conditional instance type        |
| `instance_count` | `number`        | How many EC2s to create (used by splat)     |
| `ingress_rules`  | `list(object)`  | Data source for the dynamic ingress block   |
| `resource_tags`  | `map(string)`   | Tags applied to all resources               |

### [terraform.tfvars](terraform.tfvars)

```hcl
environment    = "dev"      # triggers t2.micro via conditional
instance_count = 2          # creates 2 instances; splat returns 2 IDs
```

---

## 5. Production Best Practices

### Conditional Expressions

| Do                                              | Avoid                                             |
|-------------------------------------------------|---------------------------------------------------|
| Add `validation {}` blocks to variables         | Using conditionals for complex multi-branch logic |
| Keep conditions simple and readable             | Nesting conditionals 3+ levels deep               |
| Use `count = var.enable_x ? 1 : 0` to toggle resources | Duplicating entire resource blocks          |

### Splat Expressions

| Do                                              | Avoid                                             |
|-------------------------------------------------|---------------------------------------------------|
| Use `[*]` for simple attribute extraction       | Using splat on `for_each` resources (use `values()` instead) |
| Combine with `join()` for SSM/output strings    | Assuming splat order is guaranteed                |
| Pass splat results to downstream modules        | Using splat when you need filtering (use `for`)   |

### Dynamic Blocks

| Do                                              | Avoid                                             |
|-------------------------------------------------|---------------------------------------------------|
| Drive rules entirely from tfvars per environment | Mixing hard-coded and dynamic blocks in the same resource |
| Use `iterator` for readability in complex blocks | Deep nesting of dynamic blocks                    |
| Add descriptions to every rule object           | Using dynamic blocks for single-item blocks       |

---

## Quick Reference

```hcl
# Conditional Expression
value = condition ? "if_true" : "if_false"

# Splat Expression (count-based resources)
output = resource_type.name[*].attribute

# Splat for for_each resources
output = values(resource_type.name)[*].attribute

# Dynamic Block
dynamic "block_label" {
  for_each = var.list_or_map
  content {
    attr = block_label.value.field
  }
}
```

---

> **Next Lesson:** [Lifecycle Meta-Arguments](../life_cycle/) — `create_before_destroy`, `prevent_destroy`, `ignore_changes`
