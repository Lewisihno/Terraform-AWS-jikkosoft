# 🚀 Technical Assessment for AWS Cloud Middle Administrator  
**Nombre:** Lewis Jonathan Muñoz Pérez  
**Fecha:** 2025  
**Plataforma:** AWS + Terraform  

---

## 📌 Descripción del Proyecto

Este repositorio contiene la infraestructura como código (IaC) desarrollada con **Terraform** para cumplir con un assessment técnico en AWS. La solución despliega una arquitectura completa en AWS que incluye:

- ✅ VPC con subredes públicas y privadas  
- ✅ Tablas de rutas y NAT/IGW para conectividad segura  
- ✅ Grupos de seguridad para instancias EC2  
- ✅ Instancias EC2 en subredes pública y privada  
- ✅ IAM: usuario con acceso programático y rol para EC2 con acceso a S3  
- ✅ Bucket S3 con gestión de ciclo de vida  
- ✅ Alarma de CloudWatch con notificaciones por email (SNS)  

La arquitectura sigue buenas prácticas de seguridad, escalabilidad y automatización.

---

## 🔧 Recursos Implementados

### 1. **Red (VPC & Networking)**
- VPC: `10.0.0.0/16`
- Subredes públicas: `10.0.1.0/24`, `10.0.2.0/24`
- Subredes privadas: `10.0.3.0/24`, `10.0.4.0/24`
- Internet Gateway (IGW) y NAT Gateway con EIP
- Tablas de rutas para subredes públicas y privadas

### 2. **Seguridad**
- **Security Group Público**: Permite SSH (22) y HTTP (80) desde cualquier lugar
- **Security Group Privado**: Permite SSH solo desde subredes públicas
- Clave SSH generada automáticamente con `tls_private_key` y registrada en AWS

### 3. **Instancias EC2**
- **Instancia pública**: Bastión con acceso a Internet, perfil IAM, y script `user_data` para subir archivo a S3
- **Instancia privada**: Sin IP pública, accesible solo desde la pública
- La clave SSH se copia automáticamente a la instancia pública para facilitar conexiones hacia la privada

### 4. **IAM**
- **Usuario IAM**: `jikkosoft-user` con acceso programático (Access Key + Secret)
- **Rol IAM**: `jikkosoft-ec2-s3-acces-role` con permisos `AmazonS3FullAccess`, asignado a la instancia pública

### 5. **S3**
- Bucket: `jikkosoft-s3-bucket-<suffix>` (nombre único global)
- Política de ciclo de vida: transición a `STANDARD_IA` después de 30 días

### 6. **CloudWatch & SNS**
- Alarma de CPU: se activa si el uso supera el 80% durante 10 minutos
- Notificaciones por email vía SNS (requiere confirmación del suscriptor)

---

## 📦 Requisitos Previos

Antes de aplicar la infraestructura, asegúrate de tener:

- [Terraform](https://www.terraform.io/downloads.html) instalado (v1.0+)
- Cuenta AWS con credenciales válidas
- Región: `us-east-1`
- Email válido para recibir notificaciones de SNS

---

## 🚀 Cómo Desplegar

### 1. Clonar el repositorio
- git clone https://github.com/Lewisihno/Terraform-AWS-jikkosoft.git
- cd Terraform-AWS-jikkosoft

2. Configurar variables
Crea un archivo terraform.tfvars:

- aws_region      = "us-east-1"
- aws_access_key  = "TU_ACCESS_KEY"
- aws_secret_key  = "TU_SECRET_KEY"
- email           = "tu-email@ejemplo.com"

⚠️ No subas este archivo a Git. Añádelo al .gitignore. 

3. Inicializar e implementar

terraform init
terraform plan
terraform apply

🔐 Acceso a las Instancias
1. Conectarse a la instancia pública
ssh -i jikkosoft-key.pem ec2-user@<IP-Pública>

2. Desde la pública, conectarse a la privada
ssh -i ~/.ssh/jikkosoft-key ec2-user@10.0.3.10

✅ La clave ya fue copiada automáticamente por Terraform. 

📁 Estructura del Proyecto

- main.tf               # Infraestructura principal
- terraform.tfvars      # Variables (no subido a Git)
- jikkosoft-key.pem     # Clave privada generada (no subida a Git)
- .gitignore            # Excluye credenciales y claves
- README.md             # Este archivo

🛑 Buenas Prácticas Aplicadas

✅ Claves SSH generadas y gestionadas con tls_private_key
✅ Nombres únicos de recursos (usando random_id)
✅ Uso de depends_on cuando es necesario
✅ Seguridad: claves con chmod 600, SG restringidos
✅ Automatización: copia de clave con null_resource y provisioner
✅ Notificaciones: SNS + email para alertas
📬 Notificaciones

Después de terraform apply, recibirás un email de confirmación de AWS SNS. Haz clic en el enlace para activar las notificaciones de la alarma.

🧹 Limpieza (Destruir Infraestructura)

- terraform destroy
⚠️ Asegúrate de eliminar manualmente el archivo creado en el bucket S3 si no se borra automáticamente. 

📞 Contacto
Nombre: Lewis Jonathan Muñoz Pérez
Email: ljmunozp@gmail.com
LinkedIn: https://www.linkedin.com/in/lewisihno/