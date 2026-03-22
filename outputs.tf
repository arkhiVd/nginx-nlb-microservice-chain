output "fe_public_ip" {
  value = aws_eip.fe_eip.public_ip
}

output "domain" {
  value = var.domain_name
}