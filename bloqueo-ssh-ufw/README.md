# Bloqueo SSH con UFW

Este script automatiza el bloqueo de IPs que realizan múltiples intentos fallidos de conexión SSH en servidores Linux con `ufw`.

## Características
- Detecta intentos fallidos en `/var/log/auth.log`
- Bloquea automáticamente IPs que superen un umbral de intentos
- Limpia bloqueos antiguos para evitar saturar UFW

## Requisitos
- Ubuntu/Debian
- UFW activo
- Acceso root

## Instalación
```bash
sudo cp bloqueo_ssh.sh /usr/local/bin/bloqueo_ssh.sh
sudo chmod +x /usr/local/bin/bloqueo_ssh.sh
sudo touch /var/log/ufw_bloqueos.log
sudo chmod 644 /var/log/ufw_bloqueos.log
````

## Uso manual

```bash
sudo /usr/local/bin/bloqueo_ssh.sh
```

## Uso automático (cron)

Ejecutar cada hora:

```bash
sudo crontab -e
0 * * * * /usr/local/bin/bloqueo_ssh.sh
```