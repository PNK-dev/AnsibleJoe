#!/bin/bash

# Script para configurar Ansible Vault en el Proyecto SO
# Maneja la creación, encriptación y gestión de credenciales

VAULT_FILE="inventories/group_vars/all/vault.yml"
VAULT_PASSWORD_FILE=".vault_password"
VAULT_ID="proyecto-so"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 CONFIGURACIÓN DE ANSIBLE VAULT - PROYECTO SO${NC}"
echo -e "${BLUE}================================================${NC}"

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  setup       - Configuración inicial del vault"
    echo "  encrypt     - Encriptar archivo vault.yml"
    echo "  decrypt     - Desencriptar archivo vault.yml"
    echo "  edit        - Editar archivo vault.yml encriptado"
    echo "  view        - Ver contenido del vault sin desencriptar"
    echo "  rekey       - Cambiar contraseña del vault"
    echo "  create-pass - Crear archivo de contraseña"
    echo "  test        - Probar configuración del vault"
    echo "  help        - Mostrar esta ayuda"
}

# Función para generar contraseña segura
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Función para crear hash de contraseña
create_password_hash() {
    local password=$1
    python3 -c "import crypt; print(crypt.crypt('$password', crypt.mksalt(crypt.METHOD_SHA512)))"
}

# Función para configuración inicial
setup_vault() {
    echo -e "${GREEN}🔧 Configuración inicial del vault...${NC}"
    
    # Verificar que estamos en el directorio correcto
    if [ ! -f "ansible.cfg" ]; then
        echo -e "${RED}❌ Error: Ejecuta este script desde el directorio raíz del proyecto${NC}"
        exit 1
    fi
    
    # Crear contraseña del vault si no existe
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        echo -e "${YELLOW}📝 Creando contraseña del vault...${NC}"
        read -s -p "Ingresa una contraseña para el vault (o presiona Enter para generar una): " vault_pass
        echo
        
        if [ -z "$vault_pass" ]; then
            vault_pass=$(generate_password)
            echo -e "${GREEN}✅ Contraseña generada automáticamente${NC}"
        fi
        
        echo "$vault_pass" > "$VAULT_PASSWORD_FILE"
        chmod 600 "$VAULT_PASSWORD_FILE"
        echo -e "${GREEN}✅ Archivo de contraseña creado: $VAULT_PASSWORD_FILE${NC}"
        echo -e "${YELLOW}⚠️  IMPORTANTE: Guarda esta contraseña en un lugar seguro${NC}"
    fi
    
    # Configurar ansible.cfg para usar el vault
    if ! grep -q "vault_password_file" ansible.cfg; then
        echo "" >> ansible.cfg
        echo "# Configuración de Ansible Vault" >> ansible.cfg
        echo "vault_password_file = $VAULT_PASSWORD_FILE" >> ansible.cfg
        echo -e "${GREEN}✅ ansible.cfg configurado para usar vault${NC}"
    fi
    
    # Encriptar vault.yml si no está encriptado
    if [ -f "$VAULT_FILE" ] && ! ansible-vault view "$VAULT_FILE" &>/dev/null; then
        echo -e "${YELLOW}🔒 Encriptando archivo vault.yml...${NC}"
        ansible-vault encrypt "$VAULT_FILE"
        echo -e "${GREEN}✅ Archivo vault.yml encriptado${NC}"
    fi
    
    echo -e "${GREEN}🎉 Configuración del vault completada${NC}"
}

# Función para encriptar vault
encrypt_vault() {
    echo -e "${GREEN}🔒 Encriptando vault...${NC}"
    
    if [ ! -f "$VAULT_FILE" ]; then
        echo -e "${RED}❌ Error: No se encontró $VAULT_FILE${NC}"
        exit 1
    fi
    
    ansible-vault encrypt "$VAULT_FILE"
    echo -e "${GREEN}✅ Vault encriptado correctamente${NC}"
}

# Función para desencriptar vault
decrypt_vault() {
    echo -e "${YELLOW}🔓 Desencriptando vault...${NC}"
    
    ansible-vault decrypt "$VAULT_FILE"
    echo -e "${GREEN}✅ Vault desencriptado${NC}"
    echo -e "${YELLOW}⚠️  Recuerda encriptar nuevamente después de editar${NC}"
}

# Función para editar vault
edit_vault() {
    echo -e "${GREEN}✏️  Editando vault encriptado...${NC}"
    
    ansible-vault edit "$VAULT_FILE"
    echo -e "${GREEN}✅ Edición completada${NC}"
}

# Función para ver vault
view_vault() {
    echo -e "${GREEN}👁️  Visualizando contenido del vault...${NC}"
    
    ansible-vault view "$VAULT_FILE"
}

# Función para cambiar contraseña
rekey_vault() {
    echo -e "${GREEN}🔑 Cambiando contraseña del vault...${NC}"
    
    ansible-vault rekey "$VAULT_FILE"
    
    # Actualizar archivo de contraseña
    read -s -p "Ingresa la nueva contraseña para actualizar el archivo: " new_pass
    echo
    echo "$new_pass" > "$VAULT_PASSWORD_FILE"
    chmod 600 "$VAULT_PASSWORD_FILE"
    
    echo -e "${GREEN}✅ Contraseña del vault actualizada${NC}"
}

# Función para crear archivo de contraseña
create_password_file() {
    echo -e "${GREEN}📝 Creando archivo de contraseña...${NC}"
    
    read -s -p "Ingresa la contraseña del vault: " vault_pass
    echo
    echo "$vault_pass" > "$VAULT_PASSWORD_FILE"
    chmod 600 "$VAULT_PASSWORD_FILE"
    
    echo -e "${GREEN}✅ Archivo de contraseña creado${NC}"
}

# Función para probar configuración
test_vault() {
    echo -e "${GREEN}🧪 Probando configuración del vault...${NC}"
    
    # Verificar archivo de contraseña
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        echo -e "${RED}❌ No se encontró archivo de contraseña${NC}"
        return 1
    fi
    
    # Verificar que el vault se puede leer
    if ansible-vault view "$VAULT_FILE" &>/dev/null; then
        echo -e "${GREEN}✅ Vault se puede leer correctamente${NC}"
    else
        echo -e "${RED}❌ Error al leer el vault${NC}"
        return 1
    fi
    
    # Probar variables del vault
    echo -e "${GREEN}🔍 Probando acceso a variables...${NC}"
    ansible localhost -m debug -a "var=vault_usuarios_passwords" -e "@$VAULT_FILE" &>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Variables del vault accesibles${NC}"
    else
        echo -e "${RED}❌ Error al acceder a variables del vault${NC}"
        return 1
    fi
    
    echo -e "${GREEN}🎉 Configuración del vault funcionando correctamente${NC}"
}

# Función para generar contraseñas de usuarios
generate_user_passwords() {
    echo -e "${GREEN}👥 Generando contraseñas para usuarios...${NC}"
    
    users=("profesor" "estudiante1" "estudiante2" "admin-so")
    
    echo "# Contraseñas generadas para usuarios del proyecto SO"
    echo "# Copia estos hashes al archivo vault.yml"
    echo ""
    
    for user in "${users[@]}"; do
        password=$(generate_password)
        hash=$(create_password_hash "$password")
        echo "# Usuario: $user"
        echo "# Contraseña: $password"
        echo "$user: \"$hash\""
        echo ""
    done
}

# Función principal
main() {
    case "${1:-help}" in
        "setup")
            setup_vault
            ;;
        "encrypt")
            encrypt_vault
            ;;
        "decrypt")
            decrypt_vault
            ;;
        "edit")
            edit_vault
            ;;
        "view")
            view_vault
            ;;
        "rekey")
            rekey_vault
            ;;
        "create-pass")
            create_password_file
            ;;
        "test")
            test_vault
            ;;
        "gen-passwords")
            generate_user_passwords
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Ejecutar función principal
main "$@"