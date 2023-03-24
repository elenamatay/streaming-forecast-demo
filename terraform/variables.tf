variable "folder_id" {
  description = "Folder to be used in folders/nnnn format."
  type        = string
}

variable "project_name" {
  description = "Project name in used"
  type        = string
}

variable "pubsub_topic_name" {
  description = "PubSub topic name"
  type        = string
}

variable "bigquery_dataset_id" {
  description = "BigQuery Dataset id"
  type        = string
}

variable "bigquery_dataset_name" {
  description = "BigQuery Dataset name"
  type        = string
}

variable "bigquery_dataset_description" {
  description = "BigQuery Dataset description"
  type        = string
}

variable "bigquery_table_id" {
  description = "BigQuery table id"
  type        = string
}

variable "bigquery_table_schema_file" {
  description = "Path to file containingf the BigQuery table schema"
  type        = string
}