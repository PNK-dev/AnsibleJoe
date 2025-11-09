#!/bin/bash

# Script para ejecutar configuración de AlmaLinux
# Ejecuta desde localhost hacia localhost

echo "🚀 Iniciando configuración de AlmaLinux..."
echo "================================================"

# Verificar que estamos en AlmaLinux
if ! grep -q "AlmaLinux" /etc/os-release 2>/dev/null; then
    echo "⚠️  Advertencia: Este script está diseñado para ejecutarse en AlmaLinux"
fi

# Cambiar al directorio del proyecto
cd "$(dirname "$0")/.." || exit 1

# Verificar que Ansible está instalado
if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Ansible no está instalado. Instalando..."
    sudo dnf install -y ansible-core
    ansible-galaxy collection install community.general
    ansible-galaxy collection install ansible.posix

fi

# Ejecutar playbook específico para AlmaLinux
echo "📋 Ejecutando playbook de AlmaLinux..."
ansible-playbook playbooks/almalinux.yml -i inventories/hosts -l almalinux -K -v

EXIT_CODE=$?

echo "================================================"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Configuración de AlmaLinux completada exitosamente"
    echo "🌐 Servicios configurados:"
    echo "   - HTTP/Apache en puerto 80"
    echo "   - FTP/vsftpd en puerto 21"
    echo "   - DNS/BIND"
    echo "   - DHCPv6"
    echo "   - IPv6/radvd"
else
    echo "❌ Error en la configuración. Código de salida: $EXIT_CODE"
    echo "💡 Revisa los logs arriba para más detalles"
fi

exit $EXIT_CODE