output "web_ip"     { value = aws_instance.web.public_ip }
output "monitor_ip" { value = aws_instance.monitor.public_ip }
