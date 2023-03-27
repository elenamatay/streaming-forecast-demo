module "main_project" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/project"
  parent = var.folder_id
  name   = var.project_name

  services = [
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "datafusion.googleapis.com",
    "dataflow.googleapis.com",
    "dataproc.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "workflows.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com"
  ]
}

module "pubsub" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/pubsub"
  project_id = module.main_project.project_id
  name       = var.pubsub_topic_name

  subscriptions = {
    streaming_data_inbound_schema_sub = {
      labels = { env = "dev" }
      options = {
        ack_deadline_seconds       = null
        message_retention_duration = null
        retain_acked_messages      = true
        expiration_policy_ttl      = null
        filter                     = null
      }
    }
  }
}

module "bigquery" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/bigquery-dataset"

  dataset_id   = var.bigquery_dataset_id
  dataset_name = var.bigquery_dataset_name
  description  = var.bigquery_dataset_description
  project_id   = module.main_project.project_id

  tables = [
    {
      table_id           = var.bigquery_table_id
      schema             = file(var.bigquery_table_schema_file)
      time_partitioning  = null
      range_partitioning = null
      expiration_time    = null
      clustering         = []
      labels = {
        env = "dev"
      },
    }
  ]
}

# resource "google_bigquery_table" "shipment_streaming" {
#   project    = module.main_project.project_id
#   dataset_id = module.bigquery.bigquery_dataset.dataset_id
#   table_id   = "shipment_streaming"

#   labels = {
#     env = "default"
#   }

#   schema = <<EOF
# [
#   {
#     "name": "Shipment_ID",
#     "type": "INTEGER",
#     "mode": "NULLABLE"
#   },
#   {
#     "name": "ShipmentValue",
#     "type": "FLOAT",
#     "mode": "NULLABLE"
#   },
#   {
#     "name": "Created",
#     "type": "STRING",
#     "mode": "NULLABLE"
#   },
#   {
#     "name": "Published",
#     "type": "STRING",
#     "mode": "NULLABLE"
#   }
# ]
# EOF

# }
