/* Lookup the current AWS region.
 */
data "aws_region" "current" {}

/* Lookup the available AZs.
 */
data "aws_availability_zones" "available" {
  state = "available"
}
