/* Perform CIDR math to compute subnets.
 *
 *           +---------------+---------------+
 *           |    us-west-2a |    us-west-2b |
 * +---------+---------------+---------------+
 * | public  |   10.x.0.0/20 |  10.0.16.0/20 |
 * +---------+---------------+---------------+
 * | private |  10.x.32.0/19 |  10.x.64.0/19 |            |               |
 * +---------+---------------+---------------+
 */
locals {
  /* Split the network over two availability zones.
   *
   * Most applications should use more than one (for redundancy). Some applications will require
   * more than two zones (for extra capacity), but this is fairly rare.
   */
  availability_zone_count = 2
  availability_zones = [
    for index in range(local.availability_zone_count) :
    data.aws_availability_zones.available.names[index]
  ]

  /* Split the full CIDR range into smaller subnets.
   */
  public_subnet_bits  = 3
  private_subnet_bits = 4

  /* Allocate one /20 subnet for public traffic in each availability zone.
   */
  public_subnets = [
    for index in range(local.availability_zone_count) :
    cidrsubnet(var.cidr_block, local.public_subnet_bits, index)
  ]

  /* Allocate one /19 subnet for public traffic in each availability zone.
   *
   * We skip the first /19 subnet to account for public subnets.
   */
  private_subnets = [
    for index in range(local.availability_zone_count) :
    cidrsubnet(var.cidr_block, local.private_subnet_bits, 1 + index)
  ]
}

/* Create an AWS VPC network.
 */
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  azs                    = local.availability_zones
  cidr                   = var.cidr_block
  create_vpc             = true
  enable_dns_hostnames   = true
  enable_nat_gateway     = true
  name                   = var.name
  one_nat_gateway_per_az = true
  private_subnets        = local.private_subnets
  public_subnets         = local.public_subnets
  single_nat_gateway     = false
}
