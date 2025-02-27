resource "aws_sqs_queue" "priority-1-queue" {
  name                      = "priority-1-queue"
  delay_seconds             = var.sqs_delay_seconds
  max_message_size          = var.sqs_max_message_size
  message_retention_seconds = var.sqs_message_retention_seconds
  receive_wait_time_seconds = var.sqs_receive_wait_time_seconds
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
    maxReceiveCount     = var.dead_letter_queue_max_receive_count
  })
}

resource "aws_sqs_queue" "priority-2-queue" {
  name                      = "priority-2-queue"
  delay_seconds             = var.sqs_delay_seconds
  max_message_size          = var.sqs_max_message_size
  message_retention_seconds = var.sqs_message_retention_seconds
  receive_wait_time_seconds = var.sqs_receive_wait_time_seconds
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
    maxReceiveCount     = var.dead_letter_queue_max_receive_count
  })
}

resource "aws_sqs_queue" "priority-3-queue" {
  name                      = "priority-3-queue"
  delay_seconds             = var.sqs_delay_seconds
  max_message_size          = var.sqs_max_message_size
  message_retention_seconds = var.sqs_message_retention_seconds
  receive_wait_time_seconds = var.sqs_receive_wait_time_seconds
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
    maxReceiveCount     = var.dead_letter_queue_max_receive_count
  })
}


resource "aws_sqs_queue" "terraform_queue_deadletter" {
  name = "priority-deadletter-queue"
}

resource "aws_sqs_queue_redrive_allow_policy" "terraform_queue_redrive_allow_policy" {
  queue_url = aws_sqs_queue.terraform_queue_deadletter.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.priority-1-queue.arn]
  })
}