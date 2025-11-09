sssssssssssssssssssssssssssssss#!/bin/bash
set -e

cd /home/kendell/copia/proyecto-so

echo "🔐 Recreando vault con contraseñas correctas..."

cat > /tmp/vault_fix.yml << 'EOF'ssssssssssssssssss
---
vault_bazzite_passwords:
  gamer: "123"
  tech: "Tech2025"
  admin: "21qwasdzxc"

vault_almalinux_passwords:
  admin: "Admin2025!"
  tech: "Tech2025!"
  dev: "Dev2025!"
  security: "Sec2025!"
  auditor: "Audit2025!"

vault_local_sudo: "qwe123$"
EOF

echo "✅ Archivo vault en texto plano creado"
cat /tmp/vault_fix.yml

# Cifrar con vault-id
echo "🔒 Cifrando con vault-id proyecto-so..."
ansible-vault encrypt --encrypt-vault-id proyecto-so /tmp/vault_fix.yml

# Mover al lugar correcto
echo "📦 Instalando vault cifrado..."
mv -f /tmp/vault_fix.yml inventories/group_vars/all/vault.yml

# Verificar
echo "✅ Verificando vault..."
ansible-vault view --vault-id proyecto-so@.vault_password inventories/group_vars/all/vault.yml

echo ""
echo "🎯 Vault recreado. Ahora ejecuta:"
echo "   ansible-playbook -i inventories/hosts playbooks/almalinux.yml --tags usuarios"
