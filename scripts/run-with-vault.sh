#!/bin/bash

VAULT_PASSWORD_FILE=".vault_password"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔐 EJECUTOR CON ANSIBLE VAULT - PROYECTO SO${NC}"
echo -e "${BLUE}===========================================${NC}"

# Verificar que existe el archivo de contraseña del vault
if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
    echo -e "${RED}❌ Error: No se encontró el archivo de contraseña del vault${NC}"
    echo -e "${YELLOW}💡 Ejecuta: ./scripts/vault-setup.sh setup${NC}"
    exit 1
fi

# Verificar que el vault se puede leer
if ! ansible-vault view inventories/group_vars/all/vault.yml &>/dev/null; then
    echo -e "${RED}❌ Error: No se puede leer el archivo vault${NC}"
    echo -e "${YELLOW}💡 Verifica la contraseña del vault${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Vault configurado correctamente${NC}"

# Función para ejecutar AlmaLinux con vault
run_almalinux() {
    echo -e "${GREEN}📊 Ejecutando configuración de AlmaLinux con credenciales encriptadas...${NC}"
    
    ansible-playbook playbooks/almalinux.yml \
        -i inventories/hosts \
        -l almalinux \
        --vault-password-file "$VAULT_PASSWORD_FILE" \
        -v
    
    return $?
}

# Función para ejecutar Bazzite con vault
run_bazzite() {
    echo -e "${GREEN}🎮 Ejecutando configuración de Bazzite con credenciales encriptadas...${NC}"
    
    # Verificar conectividad primero
    if ! ansible bazzite -i inventories/hosts -m ping --vault-password-file "$VAULT_PASSWORD_FILE"; then
        echo -e "${RED}❌ No se puede conectar a los hosts Bazzite${NC}"
        return 1
    fi
    
    ansible-playbook playbooks/bazzite.yml \
        -i inventories/hosts \
        -l bazzite \
        --vault-password-file "$VAULT_PASSWORD_FILE" \
        -v
    
    return $?
}

# Función para ejecutar todo
run_all() {
    echo -e "${GREEN}🌟 Ejecutando proyecto completo con credenciales encriptadas...${NC}"
    
    # Ejecutar AlmaLinux
    run_almalinux
    ALMALINUX_EXIT=$?
    
    if [ $ALMALINUX_EXIT -ne 0 ]; then
        echo -e "${RED}❌ Error en la configuración de AlmaLinux${NC}"
        return $ALMALINUX_EXIT
    fi
    
    # Pausa entre configuraciones
    echo -e "${YELLOW}⏸️  Pausa de 5 segundos...${NC}"
    sleep 5
    
    # Ejecutar Bazzite
    run_bazzite
    BAZZITE_EXIT=$?
    
    # Resumen final
    echo ""
    echo -e "${BLUE}📊 RESUMEN DE EJECUCIÓN${NC}"
    echo -e "${BLUE}======================${NC}"
    
    if [ $ALMALINUX_EXIT -eq 0 ]; then
        echo -e "✅ AlmaLinux: Configuración exitosa"
    else
        echo -e "❌ AlmaLinux: Error (código $ALMALINUX_EXIT)"
    fi
    
    if [ $BAZZITE_EXIT -eq 0 ]; then
        echo -e "✅ Bazzite: Configuración exitosa"
    else
        echo -e "❌ Bazzite: Error (código $BAZZITE_EXIT)"
    fi
    
    if [ $ALMALINUX_EXIT -eq 0 ] && [ $BAZZITE_EXIT -eq 0 ]; then
        echo -e "${GREEN}🎉 ¡Proyecto completado exitosamente con credenciales seguras!${NC}"
        return 0
    else
        return 1
    fi
}

# Función para ejecutar playbook personalizado
run_custom() {
    local playbook=$1
    local limit=${2:-all}
    
    if [ -z "$playbook" ]; then
        echo -e "${RED}❌ Error: Especifica el playbook a ejecutar${NC}"
        echo "Uso: $0 custom <playbook> [limit]"
        return 1
    fi
    
    echo -e "${GREEN}🔧 Ejecutando playbook personalizado: $playbook${NC}"
    
    ansible-playbook "$playbook" \
        -i inventories/hosts \
        -l "$limit" \
        --vault-password-file "$VAULT_PASSWORD_FILE" \
        -v
    
    return $?
}

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [comando] [opciones]"
    echo ""
    echo "Comandos:"
    echo "  almalinux   - Configurar solo AlmaLinux"
    echo "  bazzite     - Configurar solo Bazzite"
    echo "  all         - Configurar todo el proyecto"
    echo "  custom      - Ejecutar playbook personalizado"
    echo "  test        - Probar conectividad con vault"
    echo "  help        - Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 almalinux"
    echo "  $0 bazzite"
    echo "  $0 all"
    echo "  $0 custom playbooks/custom.yml almalinux"
}

test_connectivity() {
    echo -e "${GREEN}🧪 Probando conectividad con credenciales del vault...${NC}"
    
    echo "Probando AlmaLinux (localhost):"
    ansible almalinux -i inventories/hosts -m ping --vault-password-file "$VAULT_PASSWORD_FILE"
    
    echo ""
    echo "Probando Bazzite (remoto):"
    ansible bazzite -i inventories/hosts -m ping --vault-password-file "$VAULT_PASSWORD_FILE" || echo "No hay hosts Bazzite configurados"
    
    echo ""
    echo -e "${GREEN}✅ Prueba de conectividad completada${NC}"
}

# Función principal
main() {
    case "${1:-help}" in
        "almalinux")
            run_almalinux
            ;;
        "bazzite")
            run_bazzite
            ;;
        "all")
            run_all
            ;;
        "custom")
            run_custom "$2" "$3"
            ;;
        "test")
            test_connectivity
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Ejecutar función principal
main "$@"