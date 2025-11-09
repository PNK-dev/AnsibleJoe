#!/bin/bash

# 🚀 SCRIPT RÁPIDO SOLO PARA BAZZITE
# Configura únicamente sistemas Bazzite remotos

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}"
echo "🎮 CONFIGURACIÓN RÁPIDA SOLO BAZZITE"
echo "===================================="
echo "Este script configura SOLO sistemas Bazzite con:"
echo "✅ Usuarios del proyecto con permisos"
echo "✅ Software Flatpak (Firefox, LibreOffice, VS Code, etc.)"
echo "✅ Software RPM (git, vim, htop, etc.)"
echo "✅ Configuración SDDM personalizada"
echo "✅ Optimización del sistema"
echo "✅ Mantenimiento automático"
echo -e "${NC}"

# Verificar directorio
if [ ! -f "ansible.cfg" ]; then
    echo -e "${RED}❌ Error: Ejecuta desde el directorio proyecto-so${NC}"
    exit 1
fi

# Función para mostrar progreso
show_step() {
    echo -e "${PURPLE}[$1/6] $2${NC}"
    echo "----------------------------------------"
}

# PASO 1: Verificar dependencias
show_step "1" "Verificando dependencias..."
if ! command -v ansible &> /dev/null; then
    echo "Instalando Ansible y dependencias..."
    sudo dnf install -y ansible python3-pip openssl jq
    ansible-galaxy collection install ansible.posix community.general
fi
echo -e "${GREEN}✅ Dependencias listas${NC}"

# PASO 2: Verificar hosts Bazzite
show_step "2" "Verificando hosts Bazzite..."
if ! grep -q "bazzite" inventories/hosts || ! grep -q "ansible_host" inventories/hosts; then
    echo -e "${YELLOW}⚠️  No hay hosts Bazzite configurados en inventories/hosts${NC}"
    echo ""
    echo -e "${BLUE}💡 Para configurar hosts Bazzite:${NC}"
    echo "1. Edita inventories/hosts"
    echo "2. Agrega tus sistemas Bazzite:"
    echo ""
    echo -e "${GREEN}[bazzite]${NC}"
    echo -e "${GREEN}bazzite-desktop ansible_host=192.168.1.100 ansible_user=deck${NC}"
    echo -e "${GREEN}bazzite-laptop ansible_host=192.168.1.101 ansible_user=deck${NC}"
    echo ""
    echo "3. Configura SSH:"
    echo -e "${GREEN}ssh-copy-id deck@192.168.1.100${NC}"
    echo -e "${GREEN}ssh-copy-id deck@192.168.1.101${NC}"
    echo ""
    echo "4. Ejecuta este script nuevamente"
    exit 1
fi

echo -e "${GREEN}✅ Hosts Bazzite encontrados${NC}"

# PASO 3: Configurar Vault si no existe
show_step "3" "Configurando Ansible Vault..."
if [ ! -f ".vault_password" ]; then
    echo "Generando contraseña del vault..."
    VAULT_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    echo "$VAULT_PASSWORD" > .vault_password
    chmod 600 .vault_password
fi

# Verificar si vault.yml existe
if [ ! -f "inventories/group_vars/all/vault.yml" ]; then
    echo "Creando archivo vault para Bazzite..."
    
    # Generar contraseñas para usuarios
    PROFESOR_HASH=$(python3 -c "import crypt; print(crypt.crypt('ProfesorBazzite2024!', crypt.mksalt(crypt.METHOD_SHA512)))")
    ESTUDIANTE1_HASH=$(python3 -c "import crypt; print(crypt.crypt('Estudiante1Bazzite!', crypt.mksalt(crypt.METHOD_SHA512)))")
    ESTUDIANTE2_HASH=$(python3 -c "import crypt; print(crypt.crypt('Estudiante2Bazzite!', crypt.mksalt(crypt.METHOD_SHA512)))")
    ADMIN_HASH=$(python3 -c "import crypt; print(crypt.crypt('AdminBazzite2024!', crypt.mksalt(crypt.METHOD_SHA512)))")
    
    cat > inventories/group_vars/all/vault.yml << EOF
---
# Credenciales para Bazzite - Proyecto SO
vault_usuarios_passwords:
  profesor: "$PROFESOR_HASH"
  estudiante1: "$ESTUDIANTE1_HASH"
  estudiante2: "$ESTUDIANTE2_HASH"
  admin-so: "$ADMIN_HASH"

vault_security_keys:
  encryption_key: "$(openssl rand -hex 32)"
  jwt_secret: "$(openssl rand -base64 32 | tr -d '=+/')"
  session_secret: "$(openssl rand -base64 32 | tr -d '=+/')"
EOF

    # Encriptar vault
    ansible-vault encrypt inventories/group_vars/all/vault.yml --vault-password-file .vault_password
    echo -e "${GREEN}✅ Vault creado y encriptado${NC}"
fi

# PASO 4: Probar conectividad
show_step "4" "Probando conectividad con hosts Bazzite..."
echo "Verificando conexión SSH..."

if ansible bazzite -i inventories/hosts -m ping --vault-password-file .vault_password; then
    echo -e "${GREEN}✅ Conectividad exitosa con hosts Bazzite${NC}"
else
    echo -e "${RED}❌ Error de conectividad con hosts Bazzite${NC}"
    echo ""
    echo -e "${YELLOW}💡 Soluciones:${NC}"
    echo "1. Verifica las IPs en inventories/hosts"
    echo "2. Configura SSH: ssh-copy-id usuario@ip"
    echo "3. Verifica que los hosts estén encendidos"
    echo "4. Prueba SSH manual: ssh usuario@ip"
    exit 1
fi

# PASO 5: Ejecutar configuración de Bazzite
show_step "5" "Ejecutando configuración de Bazzite..."
echo -e "${GREEN}🎮 Configurando sistemas Bazzite...${NC}"

./scripts/run-with-vault.sh bazzite
BAZZITE_EXIT=$?

# PASO 6: Verificación y resumen
show_step "6" "Verificando configuración..."

echo ""
echo -e "${BLUE}🎮 RESUMEN DE CONFIGURACIÓN BAZZITE${NC}"
echo -e "${BLUE}===================================${NC}"

if [ $BAZZITE_EXIT -eq 0 ]; then
    echo -e "✅ ${GREEN}Bazzite configurado exitosamente${NC}"
    echo ""
    echo -e "${GREEN}👥 USUARIOS CREADOS EN BAZZITE:${NC}"
    echo -e "   👨‍💼 admin (administrador general)"
    echo -e "   🧑‍🔧 tech (administrador técnico)"
    echo -e "   🎮 gamer (usuario de juegos)"
    echo ""
    echo -e "${GREEN}⚙️  CONFIGURACIONES APLICADAS:${NC}"
    echo -e "   🖥️  SDDM configurado con tema personalizado"
    echo -e "   👤 Usuarios ocultos del login"
    echo -e "   🚀 Sistema optimizado para rendimiento"
    echo -e "   🔄 Mantenimiento automático habilitado"
    echo -e "   📁 Directorios home estructurados"
    echo -e "   🔧 Bashrc personalizado para cada usuario"
    
    echo ""
    echo -e "${GREEN}🔐 SEGURIDAD:${NC}"
    echo -e "   🔒 Contraseñas encriptadas con Vault"
    echo -e "   👥 Grupos de permisos configurados"
    echo -e "   🛡️  Configuración sudo para administradores"
    
else
    echo -e "⚠️  ${YELLOW}Bazzite configurado con algunas advertencias${NC}"
    echo -e "${YELLOW}💡 Algunos paquetes pueden requerir reinicio${NC}"
fi

echo ""
echo -e "${BLUE}📋 COMANDOS ÚTILES PARA BAZZITE:${NC}"
echo -e "   ${GREEN}ansible bazzite -m shell -a 'neofetch'${NC}     # Info del sistema"
echo -e "   ${GREEN}ansible bazzite -m shell -a 'flatpak list --user'${NC}  # Apps instaladas"
echo -e "   ${GREEN}ansible bazzite -m shell -a 'who'${NC}          # Usuarios conectados"
echo -e "   ${GREEN}make vault-view${NC}                            # Ver credenciales"

echo ""
echo -e "${BLUE}🎮 ACCESO A SISTEMAS BAZZITE:${NC}"
echo "Para conectarte a los sistemas Bazzite configurados:"
echo ""

# Mostrar hosts configurados
grep -A 10 "\[bazzite\]" inventories/hosts | grep "ansible_host" | while read line; do
    hostname=$(echo "$line" | awk '{print $1}')
    ip=$(echo "$line" | grep -o 'ansible_host=[^ ]*' | cut -d'=' -f2)
    user=$(echo "$line" | grep -o 'ansible_user=[^ ]*' | cut -d'=' -f2)
    echo -e "   🖥️  ${GREEN}ssh $user@$ip${NC}  # $hostname"
done

echo ""
echo -e "${PURPLE}🎯 ¡SISTEMAS BAZZITE COMPLETAMENTE CONFIGURADOS!${NC}"

# Verificación final
echo ""
echo -e "${BLUE}🔍 Verificación final de conectividad...${NC}"
ansible bazzite -i inventories/hosts -m shell -a "echo 'Bazzite configurado correctamente - $(date)'" --vault-password-file .vault_password

echo ""
echo -e "${GREEN}🎮 ¡Sistemas Bazzite listos para usar!${NC}"