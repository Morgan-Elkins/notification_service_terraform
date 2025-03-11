output "priority_queue_1_url" {
  value = aws_sqs_queue.priority-1-queue.arn
}

output "priority_queue_2_url" {
  value = aws_sqs_queue.priority-2-queue.arn
}

output "priority_queue_3_url" {
  value = aws_sqs_queue.priority-3-queue.arn
}

output "dead_letter_queue_url" {
  value = aws_sqs_queue.terraform_queue_deadletter.arn
}