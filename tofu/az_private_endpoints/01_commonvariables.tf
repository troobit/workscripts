# ====================================================================================
# Common Variables
# ====================================================================================

variable "common_tags" {
    type = map
    default = {"Project" = "Private Link service"
                "Terraform" = "true"
                "Environment" = "dev"
                "CostCentre" = "CC-OB1234"}
}

variable "location" {
    type = string
    default = "australiaeast"
}

variable "password" {
  description = "Default password for vm's deployed."
  sensitive = true
}

variable "auto_approval_subscription_ids" {
  description = "What subscription IDs are allowed to automatically connect to the private link service (without explicit approval)?"
  default = ["19acb693-f70d-4476-9cdb-ecd9dfc0600e"]
}

variable "visibility_subscription_ids" {
  description = "What subscription IDs can SEE the private link service?"
  default = ["19acb693-f70d-4476-9cdb-ecd9dfc0600e"]
}

variable "adminusername" {
  description = "What the default username for vm's deployed should be"
  default = "osadmin"
}

/*
For use in an auto.tfvars file
auto_approval_subscription_ids = "[]"
visibility_subscription_ids = "[]"
location = ""
ws_default_subnet_name = ""
ws_vnet_name = ""
password = ""
*/