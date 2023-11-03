variable "tennantid" {
  description = "Tenntat Id"
  type = string
}
variable "subscriptionid" {
  description = "ID of subscription"
  type = string
}
variable "projectPrefix" {
  description = "Prefix for the project"
  type = string
}
variable "rgName" {
  description = "The default resource group Name"
  type = string
}
variable "location" {
  description = "Default Azure location"
  default = "westeurope"
}
variable "linuser" {
  description = "Linux user name"
  default = "azuser"
}
