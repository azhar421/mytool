variable "aws-region" {
  description = "The AWS region in which resources will be created."
  default     = "ap-south-1"  # Update with your desired default region
}

variable "vpc-cidr" {
  description = "CIDR block for the VPC."
  default     = "10.0.0.0/16"  # Update with your desired CIDR block
}

variable "instance-tenancy" {
  description = "The tenancy of the instances."
  default     = "default"  # Update with "default" or "dedicated" as needed
}

variable "public-subnet-cidr" {
  description = "CIDR block for the public subnet."
  default     = "10.0.1.0/24"  # Update with your desired CIDR block
}

variable "private-subnets-cidr" {
  description = "List of CIDR blocks for private subnets."
  default     = ["10.0.2.0/24", "10.0.3.0/24"]  # Update with your desired CIDR blocks
}

variable "subnets-azs" {
  description = "List of availability zones for subnets."
  default     = ["ap-south-1a", "ap-south-1b"]  # Update with your desired availability zones
}

variable "ami-id" {
  description = "The ID of the AMI to use for instances."
  default     = "ami-0f5ee92e2d63afc18"  # Update with your desired AMI ID
}

variable "instance-type" {
  description = "The type of EC2 instances."
  default     = "t2.micro"  # Update with your desired instance type
}

variable "key-name" {
  description = "The name of the key pair for instances."
  default     = "azhar"  # Update with your desired key pair name
}

