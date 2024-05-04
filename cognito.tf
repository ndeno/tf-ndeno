data "aws_cognito_user_pool_client" "ndeno_dev_client" {
  client_id    = var.NDENO_DEV_PUBLIC_CLIENT_1_ID
  user_pool_id = var.NDENO_DEV_USER_POOL_ID
}

data "aws_cognito_user_pools" "ndeno_dev_user_pool" {
  name = var.NDENO_DEV_USER_POOL_NAME
}
