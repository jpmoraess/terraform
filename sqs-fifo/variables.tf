variable "region" {
    description = "The AWS region to deploy the resources in."
    type        = string
    default     = "us-east-1"
}

variable "queue_name" {
    description = "The name of the SQS FIFO queue."
    type        = string
    default     = "my-fifo-queue.fifo"
}

variable "content_based_deduplication" {
    description = "Enable content-based deduplication for the FIFO queue."
    type        = bool
    default     = true
}
