# usuarios_almalinux

Gestiona usuarios para AlmaLinux con políticas de sudo diferenciadas:

- admin: privilegios totales (NOPASSWD: ALL)
- tech: limitado a systemctl/journalctl
- dev: medio (status/restart y logs)
- security: herramientas de seguridad (fail2ban, firewall-cmd, audit, semanage)
- auditor: sin sudo (solo lectura)

Contraseñas desde `vault_almalinux_passwords` (hasheadas en ejecución).
