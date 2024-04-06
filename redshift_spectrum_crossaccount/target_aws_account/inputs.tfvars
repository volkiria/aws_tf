environment       = "test"
org_code          = "someorgcode"
region            = "us-east-1"
tables_categories = ["financial-metrics", "performance-metrics"]
table_publishers = {
  sales_costs_service = {
    sales_costs = {
      category = "financial-metrics"
    }
  },

  costs_efficiency_service = {
    direct_costs_efficiency = {
      category = "financial-metrics"
    },
    indirect_costs_efficiency = {
      category = "financial-metrics"
    }
  }

}
#### Principals that will be granted access to the KMS ley used to encrypt external tables objects in S3 bucket
# these lists may contain shortnames and full ARN
# if full ARN is defined it will be used as is in the policy (expected to be principles from another accounts)
# if short name is defined it should have respective prefix of "user/" or "role/" (as it appears in ARN for particular type of IAM resource)
# short names are considered as entities in the account where resources are been deployed and respective ARNs will be generated
external_tables_key_administrator_access  = ["user/cloud_user", "role/admin"]
external_tables_key_encryptonly_access    = ["arn:aws:iam::111111111111:role/costs_efficiency_service", "arn:aws:iam::111111111111:role/sales_costs_service"] # Principals granted access to use key only for encryption, any data encrypted by these principals will not be readable for them afterwords
external_tables_key_encryptdecrypt_access = ["user/cloud_user", "role/admin"]                                                                                 # Principals granted access to use key for encryption and decryption