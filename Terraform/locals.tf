locals {
  cluster_name = var.ecs_cluster_name != null ? var.ecs_cluster_name : "${var.app_name}-${var.environment}"
  azs          = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)
}