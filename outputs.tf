output "instances_info" {
  value = <<-EOT
    Instancias EC2
    Pública:
       ID: ${aws_instance.public_instance.id}
       IP Pública: ${aws_instance.public_instance.public_ip}
       IP Privada: ${aws_instance.public_instance.private_ip}
    
    Privada:
       ID: ${aws_instance.private_instance.id}
       IP Privada: ${aws_instance.private_instance.private_ip}
  EOT
}

#Mostrar credenciales IAM
output "iam_user_access_key" {
  value       = aws_iam_access_key.jikkosoft_user.id
  description = "Access Key ID del usuario IAM"
}

output "iam_user_secret_key" {
  value       = aws_iam_access_key.jikkosoft_user.secret
  description = "Secret Access Key del usuario IAM"
  sensitive = true
}