[
  {
    "image": "${image}",
    "name": "${name}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${region}",
        "awslogs-group": "${log_group}",
        "awslogs-stream-prefix": "${stream_prefix}"
      }
    },
    "portMappings": [{
      "hostPort": 80,
      "protocol": "tcp",
      "containerPort": 80
    }]
  }
]
