# ====================================================================================
# Common Variables
# ====================================================================================

variable "subscription_id" {
    type = string
    #default = "d79193eb-3ccd-4b78-ae11-0c0507247e5b"
}

variable "common_tags" {
    type = map
    default = {"Project" = "ProjectNames"}
}

variable "location" {
    type = string
    #default = "australiaeast"
}