#!/bin/bash

# Script para ejecutar configuración de Bazzite
# Ejecuta desde AlmaLinux hacia sistemas Bazzite remotos

echo "🎮 Iniciando configuración de Bazzite..."
echo "================================================"

# Cambiar al directorio del proyecto
cd "$(dirname "$0")/.." || exit 1

# Verificar que hay hosts Bazzite configurados
if ! ansible-inventory -i inventories/hosts --list | grep -q "bazzite"; then
    echo "⚠️  No hay hosts Bazzite configurados en el inventario"
    echo "💡 Edita inventories/hosts y agrega los sistemas Bazzite"
    exit 1
fi

# Verificar conectividad con hosts Bazzite
echo "🔍 Verificando conectividad con hosts Bazzite..."
if ! ansible bazzite -i inventories/hosts -m ping; then
    echo "❌ No se puede conectar a los hosts Bazzite"
    echo "💡 Verifica:"
    echo "   - Las IPs en inventories/hosts"
    echo "   - Las claves SSH"
    echo "   - La conectividad de red"
    exit 1
fi

# Ejecutar playbook específico para Bazzite
echo "📋 Ejecutando playbook de Bazzite..."
ansible-playbook playbooks/bazzite.yml -i inventories/hosts -l bazzite -K -v

EXIT_CODE=$?

echo "================================================"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Configuración de Bazzite completada exitosamente"
    echo "🖥️  Configuraciones aplicadas:"
    echo "   - Usuarios creados y configurados"
    echo "   - Software instalado (Flatpak + RPM)"
    echo "   - SDDM configurado"
    echo "   - Sistema optimizado"
    echo "   - Mantenimiento automático habilitado"
else
    echo "❌ Error en la configuración. Código de salida: $EXIT_CODE"
    echo "💡 Revisa los logs arriba para más detalles"
fi

exit $EXIT_CODE