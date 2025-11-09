#!/bin/bash

# Script de instalación del Proyecto SO
# Configura el entorno y dependencias necesarias

echo "🔧 INSTALADOR DEL PROYECTO SO"
echo "=============================="

# Verificar que estamos en AlmaLinux
if ! grep -q "AlmaLinux" /etc/os-release 2>/dev/null; then
    echo "⚠️  Este proyecto está optimizado para AlmaLinux"
    echo "   Continuando de todas formas..."
fi

# Actualizar el sistema
echo "📦 Actualizando el sistema..."
sudo dnf update -y

# Instalar Ansible y dependencias
echo "🤖 Instalando Ansible..."
sudo dnf install -y ansible python3-pip git openssl jq curl wget

# Instalar colecciones de Ansible necesarias
echo "📚 Instalando colecciones de Ansible..."
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general

# Verificar instalación
echo "✅ Verificando instalación..."
ansible --version
python3 --version

# Configurar SSH si es necesario
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "🔑 Generando claves SSH..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    echo "💡 Clave SSH generada en ~/.ssh/id_rsa.pub"
    echo "   Copia esta clave a los sistemas Bazzite remotos"
fi

# Hacer scripts ejecutables
chmod +x scripts/*.sh

echo ""
echo "🎉 ¡INSTALACIÓN COMPLETADA!"
echo "=========================="
echo "📋 Próximos pasos:"
echo "1. Edita inventories/hosts para agregar tus sistemas Bazzite"
echo "2. Copia tu clave SSH a los sistemas remotos:"
echo "   ssh-copy-id usuario@ip-bazzite"
echo "3. Ejecuta la configuración:"
echo "   ./scripts/run-all.sh        # Para todo"
echo "   ./scripts/run-almalinux.sh  # Solo AlmaLinux"
echo "   ./scripts/run-bazzite.sh    # Solo Bazzite"
echo ""
echo "📖 Lee README.md para más información"