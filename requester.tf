locals {
  requester_subnet_ids                    = length(var.requester_subnet_ids) > 0 ? sort(var.requester_subnet_ids) : try(distinct(sort(flatten(data.aws_subnet_ids.requester[*].ids))), [])
  requester_subnet_ids_count              = var.requester_subnets_count != null ? var.requester_subnets_count : length(local.requester_subnet_ids)
  requester_vpc_id                        = one(data.aws_vpc.requester[*].id)
  requester_route_table_ids               = length(var.requester_route_table_ids) > 0 ? sort(var.requester_route_table_ids) : try(distinct(sort(data.aws_route_table.requester.*.route_table_id)), [])
  requester_route_table_ids_count         = var.requester_route_tables_count != null ? var.requester_route_tables_count : length(local.requester_route_table_ids)
  requester_cidr_block_associations       = length(var.requester_vpc_cidr_blocks) > 0 ? sort(var.requester_vpc_cidr_blocks) : flatten(data.aws_vpc.requester[*].cidr_block_associations[*].cidr_block)
  requester_cidr_block_associations_count = length(local.requester_cidr_block_associations)

  # Options can't be set until the connection has been accepted and is active,
  # so create an explicit dependency on the accepter when setting options.
  active_vpc_peering_connection_id = one(aws_vpc_peering_connection_accepter.accepter[*].id)
}

module "requester" {
  source  = "cloudposse/label/null"
  version = "0.24.1"

  attributes = var.add_attribute_tag ? ["requester"] : []
  tags       = var.add_attribute_tag ? { "Side" = "requester" } : {}
  context    = module.this.context
}

data "aws_caller_identity" "requester" {
  count    = local.count
  provider = aws.requester
}

data "aws_region" "requester" {
  count    = local.count
  provider = aws.requester
}

# Lookup requester VPC so that we can reference the CIDR
data "aws_vpc" "requester" {
  count    = local.count
  provider = aws.requester
  id       = var.requester_vpc_id
  tags     = var.requester_vpc_tags
}

# Lookup requester subnets
data "aws_subnet_ids" "requester" {
  count    = local.count
  provider = aws.requester
  vpc_id   = local.requester_vpc_id
  tags     = var.requester_subnet_tags
}

# Lookup requester route tables
data "aws_route_table" "requester" {
  count     = module.this.enabled ? local.requester_subnet_ids_count : 0
  provider  = aws.requester
  subnet_id = element(local.requester_subnet_ids, count.index)
}

resource "aws_vpc_peering_connection" "requester" {
  count         = local.count
  provider      = aws.requester
  vpc_id        = local.requester_vpc_id
  peer_vpc_id   = local.accepter_vpc_id
  peer_owner_id = local.accepter_account_id
  peer_region   = local.accepter_region
  auto_accept   = false

  tags = module.requester.tags
}

resource "aws_vpc_peering_connection_options" "requester" {
  count    = local.count
  provider = aws.requester

  # As options can't be set until the connection has been accepted
  # create an explicit dependency on the accepter.
  vpc_peering_connection_id = local.active_vpc_peering_connection_id

  requester {
    allow_remote_vpc_dns_resolution = var.requester_allow_remote_vpc_dns_resolution
  }
}

# Create routes from requester to accepter
resource "aws_route" "requester" {
  count                     = module.this.enabled ? local.requester_route_table_ids_count * local.accepter_cidr_block_associations_count : 0
  provider                  = aws.requester
  route_table_id            = local.requester_route_table_ids[floor(count.index / local.accepter_cidr_block_associations_count)]
  destination_cidr_block    = local.accepter_cidr_block_associations[count.index % local.accepter_cidr_block_associations_count]
  vpc_peering_connection_id = one(aws_vpc_peering_connection.requester[*].id)

  depends_on = [
    data.aws_route_table.requester,
    aws_vpc_peering_connection.requester,
    aws_vpc_peering_connection_accepter.accepter,
  ]
}
