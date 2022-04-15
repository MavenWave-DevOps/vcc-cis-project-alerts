#Copyright 2021 Google LLC. This software is provided as is, without warranty or representation for any use or purpose. Your use of it is subject to your agreement with Google.

resource "google_logging_metric" "project_ownership" {
  name   = "project-ownership"
  filter = "(protoPayload.serviceName=\"cloudresourcemanager.googleapis.com\") AND (ProjectOwnership OR projectOwnerInvitee) OR (protoPayload.serviceData.policyDelta.bindingDeltas.action=\"REMOVE\"  AND protoPayload.serviceData.policyDelta.bindingDeltas.role=\"roles/owner\") OR (protoPayload.serviceData.policyDelta.bindingDeltas.action=\"ADD\"  AND protoPayload.serviceData.policyDelta.bindingDeltas.role=\"roles/owner\")"
  metric_descriptor {
    unit         = 1
    value_type   = "INT64"
    metric_kind  = "DELTA"
    display_name = title("project ownership assignments/changes")
  }
  project = var.project_id
}

resource "google_logging_metric" "audit_config_changes" {
  name   = "audit-config-changes"
  filter = "protoPayload.methodName=\"SetIamPolicy\" AND protoPayload.serviceData.policyDelta.auditConfigDeltas:*"
  metric_descriptor {
    unit         = 1
    value_type   = "INT64"
    metric_kind  = "DELTA"
    display_name = title("audit configuration changes")
  }
  project = var.project_id
}

resource "google_logging_metric" "custom_role_changes" {
  name   = "custom-role-changes"
  filter = "resource.type=\"iam_role\" AND protoPayload.methodName = \"google.iam.admin.v1.CreateRole\" OR protoPayload.methodName=\"google.iam.admin.v1.DeleteRole\" OR protoPayload.methodName=\"google.iam.admin.v1.UpdateRole\""
  metric_descriptor {
    unit         = 1
    value_type   = "INT64"
    metric_kind  = "DELTA"
    display_name = title("custom role changes")
  }
  project = var.project_id
}

resource "google_logging_metric" "vpc_firewall_changes" {
  name   = "vpc-firewall-changes"
  filter = "resource.type=\"gce_firewall_rule\" AND jsonPayload.event_subtype=\"compute.firewalls.patch\" OR jsonPayload.event_subtype=\"compute.firewalls.insert\""
  metric_descriptor {
    unit         = 1
    value_type   = "INT64"
    metric_kind  = "DELTA"
    display_name = title("vpc firewall changes")
  }
  project = var.project_id
}

resource "google_logging_metric" "vpc_route_changes" {
  name   = "vpc-route-changes"
  filter = "resource.type=\"gce_route\" AND jsonPayload.event_subtype=\"compute.routes.delete\" OR jsonPayload.event_subtype=\"compute.routes.insert\""
  metric_descriptor {
    unit         = 1
    value_type   = "INT64"
    metric_kind  = "DELTA"
    display_name = title("vpc route changes")
  }
  project = var.project_id
}

resource "google_logging_metric" "vpc_network_changes" {
  name   = "vpc-network-changes"
  filter = "resource.type=gce_network AND jsonPayload.event_subtype=\"compute.networks.insert\" OR jsonPayload.event_subtype=\"compute.networks.patch\" OR jsonPayload.event_subtype=\"compute.networks.delete\" OR jsonPayload.event_subtype=\"compute.networks.removePeering\" OR jsonPayload.event_subtype=\"compute.networks.addPeering\""
  metric_descriptor {
    unit         = 1
    value_type   = "INT64"
    metric_kind  = "DELTA"
    display_name = title("vpc network changes")
  }
  project = var.project_id
}

resource "google_logging_metric" "cloud_storage_changes" {
  name   = "cloud-storage-iam-changes"
  filter = "resource.type=gcs_bucket AND protoPayload.methodName=\"storage.setIamPermissions\""
  metric_descriptor {
    unit         = 1
    value_type   = "INT64"
    metric_kind  = "DELTA"
    display_name = title("cloud storage iam changes")
  }
  project = var.project_id
}

resource "google_logging_metric" "sql_config_changes" {
  name   = "cloud-sql-config-changes"
  filter = "resource.type=gcs_bucket AND protoPayload.methodName=\"storage.setIamPermissions\""
  metric_descriptor {
    unit         = 1
    value_type   = "INT64"
    metric_kind  = "DELTA"
    display_name = title("cloud SQL config changes")
  }
  project = var.project_id
}

resource "google_monitoring_alert_policy" "cis_project_alerts" {
  depends_on   = [google_logging_metric.project_ownership, google_logging_metric.audit_config_changes, google_logging_metric.custom_role_changes]
  display_name = "CIS Project Alerts"
  combiner     = "OR"
  conditions {
    display_name = "Project Ownership Changes"
    condition_threshold {
      duration   = "0s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        per_series_aligner   = "ALIGN_DELTA"
        alignment_period     = "600s"
        cross_series_reducer = "REDUCE_COUNT"
      }
      filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.project_ownership.id}\" AND resource.type=\"global\""
    }
  }
  conditions {
    display_name = "Audit Configuration Changes"
    condition_threshold {
      duration   = "0s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        per_series_aligner   = "ALIGN_DELTA"
        alignment_period     = "600s"
        cross_series_reducer = "REDUCE_COUNT"
      }
      filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.audit_config_changes.id}\" AND resource.type=\"global\""
    }
  }
  conditions {
    display_name = "Custom Role Changes"
    condition_threshold {
      duration   = "0s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        per_series_aligner   = "ALIGN_DELTA"
        alignment_period     = "600s"
        cross_series_reducer = "REDUCE_COUNT"
      }
      filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.custom_role_changes.id}\" AND resource.type=\"global\""
    }
  }
  project               = var.workspace_project_id
  notification_channels = var.notification_channels
}

resource "google_monitoring_alert_policy" "cis_network_alerts" {
  depends_on   = [google_logging_metric.vpc_firewall_changes, google_logging_metric.vpc_route_changes, google_logging_metric.vpc_network_changes]
  display_name = "CIS Network Alerts"
  combiner     = "OR"
  conditions {
    display_name = "VPC Firewall Changes"
    condition_threshold {
      duration   = "0s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        per_series_aligner   = "ALIGN_DELTA"
        alignment_period     = "600s"
        cross_series_reducer = "REDUCE_COUNT"
      }
      filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.vpc_firewall_changes.id}\" AND resource.type=\"global\""
    }
  }
  conditions {
    display_name = "VPC Route Changes"
    condition_threshold {
      duration   = "0s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        per_series_aligner   = "ALIGN_DELTA"
        alignment_period     = "600s"
        cross_series_reducer = "REDUCE_COUNT"
      }
      filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.vpc_route_changes.id}\" AND resource.type=\"global\""
    }
  }
  conditions {
    display_name = "VPC Network Changes"
    condition_threshold {
      duration   = "0s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        per_series_aligner   = "ALIGN_DELTA"
        alignment_period     = "600s"
        cross_series_reducer = "REDUCE_COUNT"
      }
      filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.vpc_network_changes.id}\" AND resource.type=\"global\""
    }
  }
  project               = var.workspace_project_id
  notification_channels = var.notification_channels
}

resource "google_monitoring_alert_policy" "cis_cloud_storage_alerts" {
  depends_on   = [google_logging_metric.cloud_storage_changes]
  display_name = "CIS Cloud Storage Alerts"
  combiner     = "OR"
  conditions {
    display_name = "Cloud Storage IAM Changes"
    condition_threshold {
      duration   = "0s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        per_series_aligner   = "ALIGN_DELTA"
        alignment_period     = "600s"
        cross_series_reducer = "REDUCE_COUNT"
      }
      filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.cloud_storage_changes.id}\" AND resource.type=\"global\""
    }
  }
  project               = var.workspace_project_id
  notification_channels = var.notification_channels
}

resource "google_monitoring_alert_policy" "cis_cloud_sql_alerts" {
  depends_on   = [google_logging_metric.sql_config_changes]
  display_name = "CIS Cloud SQL Alerts"
  combiner     = "OR"
  conditions {
    display_name = "Cloud SQL Config Changes"
    condition_threshold {
      duration   = "0s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        per_series_aligner   = "ALIGN_DELTA"
        alignment_period     = "600s"
        cross_series_reducer = "REDUCE_COUNT"
      }
      filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.sql_config_changes.id}\" AND resource.type=\"global\""
    }
  }
  project               = var.workspace_project_id
  notification_channels = var.notification_channels
}