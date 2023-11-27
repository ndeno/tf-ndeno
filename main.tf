variable "aws_region" {
  type        = string
  description = "The region in which the resources will be created"
  default     = "eu-central-1"
}

resource "aws_cognito_user_pool" "example_pool" {
  name             = "example-pool"
  alias_attributes = ["email"]

  schema {
    name                = "email"
    required            = true
    attribute_data_type = "String"
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
}

resource "aws_cognito_user_pool_client" "example_client" {
  name                                 = "example-client"
  user_pool_id                         = aws_cognito_user_pool.example_pool.id
  generate_secret                      = true
  allowed_oauth_flows                  = ["implicit"]
  allowed_oauth_scopes                 = ["openid"]
  callback_urls                        = ["https://example.com/callback"]
  allowed_oauth_flows_user_pool_client = true
}

resource "aws_cognito_user_pool_domain" "example_domain" {
  domain       = "example-domain"
  user_pool_id = aws_cognito_user_pool.example_pool.id
}

resource "aws_cognito_user_group" "example_group" {
  name         = "example-group"
  description  = "Example group"
  precedence   = 1
  user_pool_id = aws_cognito_user_pool.example_pool.id
}

resource "aws_cognito_user" "example_user" {
  username     = "example-user"
  user_pool_id = aws_cognito_user_pool.example_pool.id

  attributes = {
    email = "example@example.com"
  }

  // TODO
  # temporary_password = ""

}
