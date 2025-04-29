provider "aws" {
  region = var.region
}

resource "aws_sqs_queue" "fifo_queue" {
  name                        = var.queue_name
  fifo_queue                  = true
  content_based_deduplication = var.content_based_deduplication
  visibility_timeout_seconds  = 30
  message_retention_seconds   = 345600
  delay_seconds               = 0
  max_message_size            = 262144
  receive_wait_time_seconds   = 0

  tags = {
    Name        = var.queue_name
  }
}
