#Copyright 2021 Google LLC. This software is provided as is, without warranty or representation for any use or purpose. Your use of it is subject to your agreement with Google.

variable "project_id" {
  type = string
}

variable "notification_channels" {
  type    = list(string)
  default = []
}

variable "workspace_project_id" {
  type = string
}