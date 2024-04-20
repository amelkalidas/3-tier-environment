# variables.tf
variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}
variable "availability_zone_A" {
  description = "The name of the public AZ"
  default     = "ap-southeast-1a"
}

variable "availability_zone_C" {
  description = "The name of the private AZ"
  default     = "ap-southeast-1c"
}
variable "public_subnet_cidrs_AZ1" {
  type    = string
  default = "10.10.0.0/24"
}
variable "public_subnet_cidrs_AZ3" {
  type    = string
  default =  "10.10.1.0/24"
}
variable "private_app_sub_cidrs_AZ1" {
  type    = string
  default = "10.10.10.0/24"
}
variable "private_app_sub_cidrs_AZ3" {
  type    = string
  default = "10.10.11.0/24"
}
variable "private_DB_sub_cidrs_AZ1" {
  type    = string
  default = "10.10.20.0/24"
}
variable "private_DB_sub_cidrs_AZ3" {
  type    = string
  default = "10.10.21.0/24"
}
#############################


variable "ec2_instance_type" {
  default = "t2.micro"
}
variable "ec2_ami" {
  default = "ami-08db74f389216e7e0"
}

variable "s3_bucket" {
  default = "mys3for3tierapp15"  
}

variable "image_id" {  
  default = "ami-08db74f389216e7e0"
}