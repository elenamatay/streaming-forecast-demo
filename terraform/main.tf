module "main_project" {
  source          = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/project"
  parent          = google_folder.scenario1.name
  name            = "testing-elena" # param

  services        = [
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
  name       = "streaming_data_inbound"
  subscriptions = {
    streaming_data_inbound_subscription = {
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
  source  = "terraform-google-modules/bigquery/google"

  dataset_id                  = "raw_area"
  dataset_name                = "Rawe Area"
  description                 = "Raw Area"
  project_id                  = module.main_project.project_id
  tables = [
  {
    table_id           = "sales",
    schema             =  file("./data/bq_sales_schema.json")
    time_partitioning = null
    range_partitioning = null
    expiration_time = null
    clustering = []
    labels          = {
      env      = "dev"
    },
  }
  ]
}

resource "google_bigquery_table" "shipment_streaming" {
  project = module.main_project.project_id
  dataset_id = module.bigquery.bigquery_dataset.dataset_id
  table_id   = "shipment_streaming"

  labels = {
    env = "default"
  }

  schema = <<EOF
[
  {
    "name": "Shipment_ID",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "ShipmentValue",
    "type": "FLOAT",
    "mode": "NULLABLE"
  },
  {
    "name": "Created",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "Published",
    "type": "STRING",
    "mode": "NULLABLE"
  }
]
EOF

}
