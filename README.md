# Real-Time Streaming data
For the purpose of the streaming data demo, some additional resources have been created and then a simple script to simulate the streaming data being published to pub/sub has been used.

## Architecture Diagram
The demo follows a very simplistics architecture:
<img src="../docs/streaming_data_diagram.svg" widht="1200">

## Steps to reproduce the demo
Please follow the below steps to reproduce the demo:

### 1) Create additional resources (pub/sub, dataset) using Terraform
Those resources can be created either manually or by using terraform. 

Below some snippets:

```yaml
module "pubsub" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/pubsub"
  project_id = module.main_project.project_id
  name       = var.pubsub_topic_name

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
```

### 2) Install dependencies and use virtual env
```bash
pyenv virtualenv 3.8.13 acciona-streaming
pyenv activate acciona-streaming
pip install google-cloud-pubsub 
```

### 3) Publish data using the script
```
./simulate_streaming_data.py --project $PROJECT --speedFactor=60
```

### 4) See the result using the Dashboard
Example dashboard: 
https://datastudio.google.com/c/u/0/reporting/24898ed5-37e9-4983-8abb-4e13a4e6c607/page/tEnnC

<img src="../docs/streaming_dash_screenshot.png" width="1200">
