#!/bin/bash

# Script de verificación del Proyecto SO
# Verifica que todos los servicios estén funcionando correctamente

echo "🔍 VERIFICACIÓN DEL PROYECTO SO"
echo "==============================="

# Cambiar al directorio del proyecto
cd "$(dirname "$0")/.." || exit 1

# Función para verificar servicios
verificar_servicio() {
    local servicio=$1
    local puerto=$2
    local host=${3:-localhost}
    
    echo -n "🔹 $servicio ($puerto): "
    
    if systemctl is-active --quiet "$servicio" 2>/dev/null; then
        echo "✅ Activo"
        
        # Verificar puerto si se especifica
        if [ -n "$puerto" ]; then
            if netstat -tuln 2>/dev/null | grep -q ":$puerto "; then
                echo "   Puerto $puerto: ✅ Abierto"
            else
                echo "   Puerto $puerto: ❌ Cerrado"
            fi
        fi
    else
        echo "❌ Inactivo"
    fi
}

# Función para verificar conectividad
verificar_conectividad() {
    local host=$1
    local descripcion=$2
    
    echo -n "🌐 $descripcion ($host): "
    
    if ping -c 1 -W 2 "$host" &>/dev/null; then
        echo "✅ Conectado"
    else
        echo "❌ Sin conexión"
    fi
}

echo ""
echo "📊 VERIFICACIÓN DE ALMALINUX (localhost)"
echo "========================================"

# Verificar servicios de AlmaLinux
verificar_servicio "httpd" "80"
verificar_servicio "vsftpd" "21"
verificar_servicio "named" "53"
verificar_servicio "radvd" ""
verificar_servicio "firewalld" ""
verificar_servicio "fail2ban" ""
verificar_servicio "suricata" ""

echo ""
echo "🌐 VERIFICACIÓN DE CONECTIVIDAD WEB"
echo "==================================="

# Verificar servicios web
echo -n "🔹 HTTP (puerto 80): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
    echo "✅ Respondiendo"
else
    echo "❌ No responde"
fi

echo -n "🔹 FTP (puerto 21): "
if nc -z localhost 21 2>/dev/null; then
    echo "✅ Abierto"
else
    echo "❌ Cerrado"
fi

echo -n "🔹 DNS (puerto 53): "
if nslookup proyecto-so.local localhost &>/dev/null; then
    echo "✅ Resolviendo"
else
    echo "❌ No resuelve"
fi

echo ""
echo "👥 VERIFICACIÓN DE USUARIOS"
echo "==========================="

# Verificar usuarios del proyecto
for usuario in profesor estudiante1 estudiante2 admin-so; do
    echo -n "🔹 Usuario $usuario: "
    if id "$usuario" &>/dev/null; then
        echo "✅ Existe"
        # Verificar directorio home
        if [ -d "/home/$usuario" ]; then
            echo "   Home: ✅ Existe"
        else
            echo "   Home: ❌ No existe"
        fi
    else
        echo "❌ No existe"
    fi
done

echo ""
echo "🎮 VERIFICACIÓN DE BAZZITE (remoto)"
echo "=================================="

# Verificar hosts Bazzite si están configurados
if ansible-inventory -i inventories/hosts --list 2>/dev/null | grep -q "bazzite"; then
    echo "🔹 Hosts Bazzite configurados: ✅"
    
    # Intentar ping a hosts Bazzite
    ansible bazzite -i inventories/hosts -m ping --one-line 2>/dev/null | while read line; do
        if echo "$line" | grep -q "SUCCESS"; then
            host=$(echo "$line" | cut -d'|' -f1 | tr -d ' ')
            echo "🔹 $host: ✅ Conectado"
        elif echo "$line" | grep -q "UNREACHABLE"; then
            host=$(echo "$line" | cut -d'|' -f1 | tr -d ' ')
            echo "🔹 $host: ❌ Sin conexión"
        fi
    done
else
    echo "🔹 Hosts Bazzite: ⚠️  No configurados"
    echo "   Edita inventories/hosts para agregar sistemas Bazzite"
fi

echo ""
echo "📋 RESUMEN DE LOGS RECIENTES"
echo "============================"
echo "🔹 Últimas 5 líneas del log del sistema:"
journalctl --since "1 hour ago" --no-pager | tail -5

echo ""
echo "🛡️  VERIFICACIÓN DE SEGURIDAD"
echo "============================="

# Verificar firewall
echo -n "🔹 Estado del firewall: "
if firewall-cmd --state &>/dev/null; then
    echo "✅ Activo"
    echo "   Zona activa: $(firewall-cmd --get-active-zones | head -1)"
    echo "   Servicios: $(firewall-cmd --list-services | tr '\n' ' ')"
else
    echo "❌ Inactivo"
fi

# Verificar fail2ban
echo -n "🔹 Fail2ban: "
if systemctl is-active --quiet fail2ban; then
    echo "✅ Activo"
    banned_count=$(fail2ban-client status 2>/dev/null | grep -o "Jail list:.*" | wc -w)
    echo "   Jails activas: $((banned_count - 2))"
else
    echo "❌ Inactivo"
fi

# Verificar script de monitoreo
if [ -f "/usr/local/bin/firewall-monitor.sh" ]; then
    echo "🔹 Monitor de firewall: ✅ Disponible"
    echo "   Usa: /usr/local/bin/firewall-monitor.sh"
else
    echo "🔹 Monitor de firewall: ❌ No disponible"
fi

# Verificar Suricata IDS/IPS
echo -n "🔹 Suricata IDS/IPS: "
if systemctl is-active --quiet suricata; then
    echo "✅ Activo"
    if [ -f "/usr/local/bin/suricata-monitor.sh" ]; then
        echo "   Monitor: ✅ Disponible"
        echo "   Usa: /usr/local/bin/suricata-monitor.sh"
        
        # Mostrar estadísticas rápidas
        if [ -f "/var/log/suricata/eve.json" ]; then
            alertas_hoy=$(grep "$(date '+%Y-%m-%d')" /var/log/suricata/eve.json | grep "event_type.*alert" | wc -l)
            echo "   Alertas hoy: $alertas_hoy"
        fi
    else
        echo "   Monitor: ❌ No disponible"
    fi
else
    echo "❌ Inactivo"
fi

echo ""
echo "🎯 VERIFICACIÓN COMPLETADA"
echo "=========================="
echo "💡 Si hay servicios inactivos, ejecuta:"
echo "   ./scripts/run-almalinux.sh  # Para reconfigurar AlmaLinux"
echo "   ./scripts/run-bazzite.sh    # Para reconfigurar Bazzite"
echo ""
echo "🛡️  Para monitoreo de seguridad:"
echo "   /usr/local/bin/firewall-monitor.sh  # Estado del firewall"
echo "   /usr/local/bin/suricata-monitor.sh  # Estado de Suricata IDS/IPS"
echo "   make status                         # Estado de servicios"
echo "   make security-report                # Reporte de seguridad completo"