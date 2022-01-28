locals {
  accepter_subnet_ids                    = length(var.accepter_subnet_ids) > 0 ? sort(var.accepter_subnet_ids) : try(distinct(sort(flatten(data.aws_subnet_ids.accepter[*].ids))))
  accepter_subnet_ids_count              = var.accepter_subnets_count != null ? var.accepter_subnets_count : length(local.accepter_subnet_ids)
  accepter_vpc_id                        = one(data.aws_vpc.accepter[*].id)
  accepter_account_id                    = one(data.aws_caller_identity.accepter[*].account_id)
  accepter_region                        = one(data.aws_region.accepter[*].name)
  accepter_route_table_ids               = length(var.accepter_route_table_ids) > 0 ? sort(var.accepter_route_table_ids) : try(distinct(sort(data.aws_route_table.accepter[*].route_table_id)), [])
  accepter_route_table_ids_count         = var.accepter_route_tables_count != null ? var.accepter_route_tables_count : length(local.accepter_route_table_ids)
  accepter_cidr_block_associations       = length(var.accepter_vpc_cidr_blocks) > 0 ? sort(var.accepter_vpc_cidr_blocks) : flatten(data.aws_vpc.accepter[*].cidr_block_associations[*].cidr_block)
  accepter_cidr_block_associations_count = length(local.accepter_cidr_block_associations)
}

module "accepter" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = var.add_attribute_tag ? ["accepter"] : []
  tags       = var.add_attribute_tag ? { "Side" = "accepter" } : {}
  context    = module.this.context
}

data "aws_caller_identity" "accepter" {
  count    = local.count
  provider = aws.accepter
}

data "aws_region" "accepter" {
  count    = local.count
  provider = aws.accepter
}

# Lookup accepter's VPC so that we can reference the CIDR
data "aws_vpc" "accepter" {
  count    = local.count
  provider = aws.accepter
  id       = var.accepter_vpc_id
  tags     = var.accepter_vpc_tags
}

# Lookup accepter subnets
data "aws_subnet_ids" "accepter" {
  count    = local.count
  provider = aws.accepter

  vpc_id = local.accepter_vpc_id
  tags   = var.accepter_subnet_tags
}

# Lookup accepter route tables
data "aws_route_table" "accepter" {
  count     = module.this.enabled ? local.accepter_subnet_ids_count : 0
  provider  = aws.accepter
  subnet_id = element(local.accepter_subnet_ids, count.index)
}

# Create routes from accepter to requester
resource "aws_route" "accepter" {
  count                     = module.this.enabled ? local.accepter_route_table_ids_count * local.requester_cidr_block_associations_count : 0
  provider                  = aws.accepter
  route_table_id            = local.accepter_route_table_ids[floor(count.index / local.requester_cidr_block_associations_count)]
  destination_cidr_block    = local.requester_cidr_block_associations[count.index % local.requester_cidr_block_associations_count]
  vpc_peering_connection_id = join("", aws_vpc_peering_connection.requester[*].id)

  depends_on = [
    data.aws_route_table.accepter,
    aws_vpc_peering_connection_accepter.accepter,
    aws_vpc_peering_connection.requester,
  ]
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "accepter" {
  count                     = local.count
  provider                  = aws.accepter
  vpc_peering_connection_id = join("", aws_vpc_peering_connection.requester[*].id)
  auto_accept               = var.auto_accept
  tags                      = module.accepter.tags
}

resource "aws_vpc_peering_connection_options" "accepter" {
  count                     = local.count
  provider                  = aws.accepter
  vpc_peering_connection_id = local.active_vpc_peering_connection_id

  accepter {
    allow_remote_vpc_dns_resolution = var.accepter_allow_remote_vpc_dns_resolution
  }
}
