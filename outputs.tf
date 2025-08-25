output "vpc_id" {
  value = aws_vpc.vpc_jikkosoft.id
  description = "ID de la VPC creada"
}

output "public_subnets" {
  value = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]
  description = "IDs de las subredes públicas"
}

output "private_subnets" {
  value = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]
  description = "IDs de las subredes privadas"
}

output "IGW" {
  value = aws_internet_gateway.igw.id
  description = "IGW creada"
}

output "NAT" {
  value = aws_nat_gateway.nat_gw.id
  description = "NAT Creada"
}

output "EIP" {
  value = aws_eip.nat_eip.public_ip
  description = "EIP Creada"
}

output "Security_Group" {
  value = {
    public  = [
      "${aws_security_group.sg_public_ec2.id} SG_Public_name: ${aws_security_group.sg_public_ec2.name}"
    ]
    private = [
      "${aws_security_group.sg_private_ec2.id} SG_Private_name: ${aws_security_group.sg_private_ec2.name}"
    ]
  }
}

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