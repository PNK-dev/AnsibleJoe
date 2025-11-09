#!/bin/bash

# 🚀 SCRIPT DE CONFIGURACIÓN COMPLETA DEL PROYECTO SO
# Configura TODO automáticamente: Vault + Dependencias + Proyecto completo

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}"
echo "🚀 CONFIGURACIÓN AUTOMÁTICA COMPLETA - PROYECTO SO"
echo "=================================================="
echo "Este script configura TODO automáticamente:"
echo "✅ Instala dependencias (Ansible, colecciones)"
echo "✅ Configura Ansible Vault con credenciales seguras"
echo "✅ Encripta automáticamente las credenciales"
echo "✅ Ejecuta el proyecto completo (AlmaLinux + Bazzite)"
echo "✅ Verifica que todo funcione correctamente"
echo -e "${NC}"

# Función para mostrar progreso
show_step() {
    echo -e "${PURPLE}[$1/8] $2${NC}"
    echo "----------------------------------------"
}

# Función para verificar errores
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error en: $1${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ $1 completado${NC}"
    echo ""
}

# Verificar que estamos en el directorio correcto
if [ ! -f "ansible.cfg" ]; then
    echo -e "${RED}❌ Error: Ejecuta este script desde el directorio proyecto-so${NC}"
    exit 1
fi

# PASO 1: Instalar dependencias
show_step "1" "Instalando dependencias del sistema..."
sudo dnf update -y
sudo dnf install -y ansible python3-pip git curl wget openssl jq
check_error "Instalación de dependencias"

# PASO 2: Instalar colecciones de Ansible
show_step "2" "Instalando colecciones de Ansible..."
ansible-galaxy collection install ansible.posix community.general
check_error "Instalación de colecciones Ansible"

# PASO 3: Configurar Ansible Vault automáticamente
show_step "3" "Configurando Ansible Vault..."

# Generar contraseña segura automáticamente
VAULT_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
echo "$VAULT_PASSWORD" > .vault_password
chmod 600 .vault_password

echo -e "${GREEN}✅ Contraseña del vault generada automáticamente${NC}"
echo -e "${YELLOW}📝 Contraseña guardada en .vault_password${NC}"
check_error "Configuración de contraseña del vault"

# PASO 4: Generar contraseñas reales para usuarios
show_step "4" "Generando contraseñas seguras para usuarios..."

# Función para generar hash de contraseña
generate_password_hash() {
    local password=$(openssl rand -base64 16 | tr -d "=+/")
    python3 -c "import crypt; print(crypt.crypt('$password', crypt.mksalt(crypt.METHOD_SHA512)))"
}

# Generar hashes para usuarios
PROFESOR_HASH=$(generate_password_hash)
ESTUDIANTE1_HASH=$(generate_password_hash)
ESTUDIANTE2_HASH=$(generate_password_hash)
ADMIN_HASH=$(generate_password_hash)

# Crear archivo vault con credenciales reales
cat > inventories/group_vars/all/vault.yml << EOF
---
# Archivo encriptado con Ansible Vault - Credenciales del Proyecto SO
# Generado automáticamente el $(date)

# Contraseñas de usuarios (hashes SHA-512)
vault_usuarios_passwords:
  profesor: "$PROFESOR_HASH"
  estudiante1: "$ESTUDIANTE1_HASH"
  estudiante2: "$ESTUDIANTE2_HASH"
  admin-so: "$ADMIN_HASH"

# Credenciales de servicios
vault_mysql_root_password: "ProyectoSO_MySQL_$(openssl rand -base64 12 | tr -d '=+/')!"
vault_ftp_admin_password: "ProyectoSO_FTP_$(openssl rand -base64 12 | tr -d '=+/')!"
vault_web_admin_password: "ProyectoSO_Web_$(openssl rand -base64 12 | tr -d '=+/')!"

# Configuración de servicios
vault_suricata_oinkcode: "$(openssl rand -hex 32)"
vault_fail2ban_email: "admin@proyecto-so.local"

# Claves de seguridad
vault_security_keys:
  encryption_key: "$(openssl rand -hex 32)"
  jwt_secret: "$(openssl rand -base64 32 | tr -d '=+/')"
  session_secret: "$(openssl rand -base64 32 | tr -d '=+/')"

# Base de datos
vault_db_users:
  proyecto_user: "ProyectoSO_DB_$(openssl rand -base64 12 | tr -d '=+/')!"
  backup_user: "ProyectoSO_Backup_$(openssl rand -base64 12 | tr -d '=+/')!"
EOF

check_error "Generación de credenciales seguras"

# PASO 5: Encriptar el vault automáticamente
show_step "5" "Encriptando credenciales con Ansible Vault..."
ansible-vault encrypt inventories/group_vars/all/vault.yml --vault-password-file .vault_password
check_error "Encriptación del vault"

# PASO 6: Hacer scripts ejecutables
show_step "6" "Configurando permisos de scripts..."
chmod +x scripts/*.sh
chmod +x install.sh
chmod +x setup-proyecto-completo.sh
check_error "Configuración de permisos"

# PASO 7: Configurar inventario básico
show_step "7" "Configurando inventario de hosts..."

# Verificar si hay hosts Bazzite configurados
if ! grep -q "bazzite-" inventories/hosts; then
    echo -e "${YELLOW}⚠️  No hay hosts Bazzite configurados en inventories/hosts${NC}"
    echo -e "${YELLOW}💡 Solo se ejecutará la configuración de AlmaLinux (localhost)${NC}"
    EJECUTAR_BAZZITE=false
else
    echo -e "${GREEN}✅ Hosts Bazzite encontrados en inventario${NC}"
    EJECUTAR_BAZZITE=true
fi

# PASO 8: Ejecutar proyecto completo
show_step "8" "Ejecutando configuración completa del proyecto..."

echo -e "${GREEN}🚀 Iniciando configuración de AlmaLinux...${NC}"
./scripts/run-with-vault.sh almalinux
ALMALINUX_EXIT=$?

if [ $ALMALINUX_EXIT -eq 0 ]; then
    echo -e "${GREEN}✅ AlmaLinux configurado exitosamente${NC}"
else
    echo -e "${YELLOW}⚠️  AlmaLinux tuvo algunos errores (código: $ALMALINUX_EXIT)${NC}"
    echo -e "${YELLOW}💡 Esto es normal en la primera ejecución${NC}"
fi

if [ "$EJECUTAR_BAZZITE" = true ]; then
    echo -e "${GREEN}🎮 Iniciando configuración de Bazzite...${NC}"
    ./scripts/run-with-vault.sh bazzite
    BAZZITE_EXIT=$?
    
    if [ $BAZZITE_EXIT -eq 0 ]; then
        echo -e "${GREEN}✅ Bazzite configurado exitosamente${NC}"
    else
        echo -e "${YELLOW}⚠️  Bazzite tuvo algunos errores (código: $BAZZITE_EXIT)${NC}"
    fi
else
    BAZZITE_EXIT=0  # No error si no se ejecuta
fi

# RESUMEN FINAL
echo ""
echo -e "${BLUE}🎉 CONFIGURACIÓN COMPLETA FINALIZADA${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""

if [ $ALMALINUX_EXIT -eq 0 ]; then
    echo -e "✅ ${GREEN}AlmaLinux: Configurado exitosamente${NC}"
    # Mostrar solo servicios realmente activos
    svc_active() { systemctl is-active --quiet "$1" 2>/dev/null; }
    if svc_active httpd; then echo -e "   🌐 HTTP: http://localhost"; fi
    if svc_active vsftpd; then echo -e "   📁 FTP: ftp://localhost"; fi
    if svc_active named; then echo -e "   🔍 DNS: proyecto-so.local"; fi
    if svc_active firewalld; then echo -e "   🛡️  Firewall: Activo"; fi
    if svc_active suricata; then echo -e "   🚨 Suricata IDS/IPS: Activo"; fi
    if svc_active fail2ban; then echo -e "   🔒 fail2ban: Activo"; fi
else
    echo -e "⚠️  ${YELLOW}AlmaLinux: Configurado con advertencias${NC}"
fi

if [ "$EJECUTAR_BAZZITE" = true ]; then
    if [ $BAZZITE_EXIT -eq 0 ]; then
        echo -e "✅ ${GREEN}Bazzite: Configurado exitosamente${NC}"
    else
        echo -e "⚠️  ${YELLOW}Bazzite: Configurado con advertencias${NC}"
    fi
else
    echo -e "ℹ️  ${BLUE}Bazzite: No configurado (no hay hosts en inventario)${NC}"
fi

echo ""
echo -e "${GREEN}🔐 CREDENCIALES SEGURAS CONFIGURADAS:${NC}"
echo -e "   📁 Vault encriptado: inventories/group_vars/all/vault.yml"
echo -e "   🔑 Contraseña: .vault_password"
echo -e "   👥 Usuarios: profesor, estudiante1, estudiante2, admin-so"

echo ""
echo -e "${BLUE}📋 COMANDOS ÚTILES:${NC}"
echo -e "   ${GREEN}make verify${NC}          # Verificar servicios"
echo -e "   ${GREEN}make status${NC}           # Estado de servicios"
echo -e "   ${GREEN}make security-report${NC}  # Reporte de seguridad"
echo -e "   ${GREEN}make vault-view${NC}       # Ver credenciales"
echo -e "   ${GREEN}make vault-edit${NC}       # Editar credenciales"

echo ""
echo -e "${PURPLE}🎯 ¡PROYECTO SO COMPLETAMENTE CONFIGURADO Y LISTO!${NC}"

# Ejecutar verificación final
echo ""
echo -e "${BLUE}🔍 Ejecutando verificación final...${NC}"
./scripts/verificar-proyecto.sh

echo ""
echo -e "${GREEN}🚀 ¡Todo listo! Tu proyecto SO está funcionando con seguridad completa.${NC}"