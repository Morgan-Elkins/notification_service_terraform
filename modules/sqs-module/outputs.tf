output "priority_queue_1_url" {
  value = aws_sqs_queue.terraform_queue_deadletter.id
}

output "priority_queue_2_url" {
  value = aws_sqs_queue.terraform_queue_deadletter.id
}

output "priority_queue_3_url" {
  value = aws_sqs_queue.terraform_queue_deadletter.id
}

output "dead_letter_queue_url" {
  value = aws_sqs_queue.terraform_queue_deadletter.id
}