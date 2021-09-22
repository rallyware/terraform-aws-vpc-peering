variable "auto_accept" {
  type        = bool
  default     = true
  description = "Automatically accept the peering"
}

variable "accepter_vpc_id" {
  type        = string
  description = "Accepter VPC ID filter"
  default     = ""
}

variable "accepter_vpc_cidr_blocks" {
  type        = list(string)
  description = "A list of Accepter VPC cidr block"
  default     = []
}

variable "accepter_vpc_tags" {
  type        = map(string)
  description = "Accepter VPC Tags filter"
  default     = {}
}

variable "accepter_subnet_tags" {
  type        = map(string)
  description = "Only add peer routes to accepter VPC route tables of subnets matching these tags"
  default     = {}
}

variable "accepter_subnet_ids" {
  type        = list(string)
  description = "A list of Accepter Subnet IDs"
  default     = []
}

variable "accepter_subnets_count" {
  type        = number
  description = "A list of Accepter Subnets count, requires only when subnets aren't created yet"
  default     = null
}

variable "accepter_route_table_ids" {
  type        = list(string)
  description = "A list of Accepter Route Table IDs"
  default     = []
}

variable "accepter_route_tables_count" {
  type        = number
  description = "A list of Accepter Route Tables count, requires only when subnets aren't created yet"
  default     = null
}

variable "accepter_allow_remote_vpc_dns_resolution" {
  type        = bool
  default     = true
  description = "Allow accepter VPC to resolve public DNS hostnames to private IP addresses when queried from instances in the requester VPC"
}

variable "requester_subnet_tags" {
  type        = map(string)
  description = "Only add peer routes to requester VPC route tables of subnets matching these tags"
  default     = {}
}

variable "requester_vpc_id" {
  type        = string
  description = "Requester VPC ID filter"
  default     = ""
}

variable "requester_vpc_cidr_blocks" {
  type        = list(string)
  description = "A list of Requester VPC cidr block"
  default     = []
}

variable "requester_vpc_tags" {
  type        = map(string)
  description = "Requester VPC Tags filter"
  default     = {}
}

variable "requester_subnet_ids" {
  type        = list(string)
  description = "A list of Requester Subnet IDs"
  default     = []
}

variable "requester_subnets_count" {
  type        = number
  description = "A list of Requester Subnets count, requires only when subnets aren't created yet"
  default     = null
}

variable "requester_route_table_ids" {
  type        = list(string)
  description = "A list of Requester Route Table IDs"
  default     = []
}

variable "requester_route_tables_count" {
  type        = number
  description = "A list of Requester Route Tables count, requires only when subnets aren't created yet"
  default     = null
}

variable "requester_allow_remote_vpc_dns_resolution" {
  type        = bool
  default     = true
  description = "Allow requester VPC to resolve public DNS hostnames to private IP addresses when queried from instances in the accepter VPC"
}

variable "skip_metadata_api_check" {
  type        = bool
  default     = false
  description = "Don't use the credentials of EC2 instance profile"
}

variable "add_attribute_tag" {
  type        = bool
  default     = true
  description = "If `true` will add additional attribute tag to the requester and accceptor resources"
}
