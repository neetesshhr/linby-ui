variable "ami_id" {
  description = "The ID of the AMI to use"
  type        = string
  default     = "ami-04f15c9c38471ac72"  
}

variable "deployregion" {
  description = "The region for the deployment"
  type = string
  default = "ap-south-1"
}

variable "instancetype" {
  description = "The instance type for your region"
  type = string
  default = "t2.micro"
}

variable "ServerName" {
  description = "Name for your Deployment Server"
  type = string
  default = "DeploymentServer"
}

variable "public_key_path" {
  description = "Path to the public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"  # A default value
}