variable "sqs_delay_seconds" {
  description = "Length of message delay in sqs queue"
  type = number
  default = 0
}

variable "sqs_max_message_size" {
  description = "max number of bytes in sqs queue"
  type = number
  default = 2048
}

variable "sqs_message_retention_seconds" {
  description = "Max number of seconds to hold message in queue for"
  type = number
  default = 86400
}

variable "sqs_receive_wait_time_seconds" {
  description = "Max number of seconds to hold message in queue for"
  type = number
  default = 10
}

variable "dead_letter_queue_max_receive_count" {
  description = "Max number of messages to hold in dead letter queue"
  type = number
  default = 4
}