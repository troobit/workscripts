# ====================================================================================
# Variables
# ====================================================================================

variable "plinkname" {
  description = "Name to be used a suffix for resources deployed associated with this private link endpoint"
  default = "plink"  
}

variable "requestmessage" {
  description = "Message to send with the request for connection to external private link service"
  default = "Request Message"
}

variable "serviceendpointresourcealias" {
  description = "Private link resource alias for the service you are connecting to"
  default = ""
}

variable "location" {
  description = "Which Azure region should the resource be deployed to. Defaults to australiaeast"
  default = "australiaeast"
}

variable "subnetid" {
  description = "subnetID in which the resource will be deployed. Pass azure_rm.subnet.id to this module"
}

variable "tags" {
  description = "Tags to be applied to the link and vnic"
  type = map
}

variable "rgname" {
  description = "The resource group to which this will be deployed"
}

variable "privateIP" {
  description = "Private IP assigned to the endpoint. If left blank the IP is dynamically allocated."
}