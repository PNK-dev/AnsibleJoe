#!/bin/bash

# Script maestro para ejecutar configuración completa del proyecto SO
# Configura tanto AlmaLinux como Bazzite

echo "🌟 PROYECTO DE SISTEMAS OPERATIVOS - CONFIGURACIÓN COMPLETA"
echo "============================================================"
echo "Este script configurará:"
echo "📊 AlmaLinux: Servicios de red (HTTP, FTP, DNS, DHCPv6, IPv6)"
echo "🎮 Bazzite: Sistema desktop (usuarios, software, SDDM, optimización)"
echo "============================================================"

# Cambiar al directorio del proyecto
cd "$(dirname "$0")/.." || exit 1

# Función para mostrar el progreso
show_progress() {
    echo ""
    echo "⏳ $1..."
    echo "------------------------------------------------------------"
}

# Verificar prerrequisitos
show_progress "Verificando prerrequisitos"

if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Ansible no está instalado. Instalando..."
    sudo dnf install -y ansible
fi

# Ejecutar configuración de AlmaLinux (localhost)
show_progress "Configurando AlmaLinux (localhost)"
./scripts/run-almalinux.sh
ALMALINUX_EXIT=$?

if [ $ALMALINUX_EXIT -ne 0 ]; then
    echo "❌ Error en la configuración de AlmaLinux"
    echo "🛑 Deteniendo ejecución"
    exit $ALMALINUX_EXIT
fi

# Pausa entre configuraciones
echo ""
echo "⏸️  Pausa de 5 segundos antes de configurar Bazzite..."
sleep 5

# Ejecutar configuración de Bazzite (remoto)
show_progress "Configurando sistemas Bazzite"
./scripts/run-bazzite.sh
BAZZITE_EXIT=$?

# Resumen final
echo ""
echo "============================================================"
echo "📊 RESUMEN DE CONFIGURACIÓN"
echo "============================================================"

if [ $ALMALINUX_EXIT -eq 0 ]; then
    echo "✅ AlmaLinux: Configuración exitosa"
else
    echo "❌ AlmaLinux: Error (código $ALMALINUX_EXIT)"
fi

if [ $BAZZITE_EXIT -eq 0 ]; then
    echo "✅ Bazzite: Configuración exitosa"
else
    echo "❌ Bazzite: Error (código $BAZZITE_EXIT)"
fi

echo "============================================================"

# Determinar código de salida final
if [ $ALMALINUX_EXIT -eq 0 ] && [ $BAZZITE_EXIT -eq 0 ]; then
    echo "🎉 ¡PROYECTO COMPLETADO EXITOSAMENTE!"
    echo "🌐 Todos los servicios y sistemas están configurados"
    exit 0
else
    echo "⚠️  Proyecto completado con errores"
    echo "💡 Revisa los logs para más detalles"
    exit 1
fi