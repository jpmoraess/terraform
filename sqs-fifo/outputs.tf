output "fifo_queue_url" {
    description = "The URL of the FIFO SQS queue."
    value       = aws_sqs_queue.fifo_queue.id
}

output "fifo_queue_arn" {
    description = "The ARN of the FIFO SQS queue."
    value       = aws_sqs_queue.fifo_queue.arn
}