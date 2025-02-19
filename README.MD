# n8n Azure VM Deployment

This repository contains templates and scripts to deploy n8n workflow automation platform on Azure Virtual Machine. This deployment uses Docker and Docker Compose for running n8n and PostgreSQL, with Caddy as a reverse proxy for automatic HTTPS.

## Overview

The deployment consists of:
- Azure B1ms VM (1 vCPU, 2GB RAM)
- Ubuntu 22.04 LTS
- Docker & Docker Compose
- n8n Community Edition
- PostgreSQL database
- Caddy web server (for HTTPS)
- Automatic backups
- Basic monitoring

## Prerequisites

1. Azure CLI installed
```bash
curl -sL https://aka.ms/InstallAzureCLI | bash
```

2. Azure subscription
```bash
az login
```

3. A domain name pointed to Azure VM's IP (will be obtained during deployment)

## Repository Structure

```
.
├── n8n-vm-template.json    # Azure ARM template for VM
├── deploy.sh               # Deployment script
├── setup.sh               # VM setup script
├── docker-compose.yml     # Docker composition for n8n
├── backup.sh             # Backup script
└── README.md             # This file
```

## Deployment Steps

### 1. Clone the Repository

```bash
git clone https://github.com/jawand/n8n-azure-deploy
cd n8n-azure-deploy
```

### 2. Configure Deployment

Edit `deploy.sh` and set your preferred values:
```bash
RESOURCE_GROUP="n8n-rg"
LOCATION="eastus"
VM_NAME="n8n-vm"
ADMIN_USERNAME="n8nadmin"
DOMAIN_NAME="your-domain.com"  # Replace with your domain
```

### 3. Deploy the VM

```bash
chmod +x deploy.sh
./deploy.sh
```

The script will:
- Create a resource group
- Generate SSH keys if needed
- Deploy the VM using ARM template
- Output connection information

### 4. Configure DNS

Point your domain to the VM's IP address (shown in deployment output)

### 5. Setup n8n

1. SSH into the VM:
```bash
ssh n8nadmin@<VM_IP>
```

2. Copy setup files:
```bash
# From your local machine
scp setup.sh docker-compose.yml backup.sh n8nadmin@<VM_IP>:~/
```

3. Run setup:
```bash
chmod +x setup.sh
./setup.sh
```

### 6. Access n8n

Once deployment is complete, you can access n8n at:
```
https://your-domain.com
```

Default credentials:
- Username: admin
- Password: (Set during deployment)

## Configuration Files

### docker-compose.yml
Contains service definitions for:
- n8n
- PostgreSQL

Key configurations:
```yaml
services:
  n8n:
    image: docker.io/n8nio/n8n
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      # ... other env vars

  postgres:
    image: postgres:14-alpine
    environment:
      - POSTGRES_USER=n8n
      # ... other env vars
```

### Backup Configuration

The `backup.sh` script performs:
- PostgreSQL database dumps
- n8n data volume backup
- Optional upload to Azure Storage

To enable automatic backups:
```bash
(crontab -l 2>/dev/null; echo "0 0 * * * /home/n8nadmin/backup.sh") | crontab -
```

## Maintenance

### Updates

Update n8n and PostgreSQL:
```bash
docker-compose pull
docker-compose up -d
```

### Monitoring

1. Check container status:
```bash
docker-compose ps
```

2. View logs:
```bash
docker-compose logs -f
```

3. Monitor system resources:
```bash
htop
```

### Backups

Manual backup:
```bash
./backup.sh
```

## Security Considerations

1. Firewall rules are configured to allow only:
   - SSH (22)
   - HTTP (80)
   - HTTPS (443)

2. SSH access:
   - Key-based authentication only
   - Password authentication disabled

3. n8n security:
   - Basic authentication enabled
   - HTTPS enforced
   - Regular security updates

## Troubleshooting

1. Cannot connect to n8n:
   - Check VM status in Azure portal
   - Verify domain DNS settings
   - Check docker containers: `docker-compose ps`

2. Database connection issues:
   - Check PostgreSQL logs: `docker-compose logs postgres`
   - Verify environment variables in docker-compose.yml

3. SSL/HTTPS issues:
   - Check Caddy logs: `sudo journalctl -u caddy`
   - Verify domain points to correct IP

## Cost Estimation

Monthly cost breakdown:
- VM (B1ms): ~$13.14
- Storage (OS Disk): ~$2.40
- Total: ~$15.54/month

## Support

For issues:
1. Check the [n8n documentation](https://docs.n8n.io/)
2. Open an issue in this repository
3. Check [n8n community forums](https://community.n8n.io/)

## License

This deployment template is MIT licensed. n8n is licensed under its own terms.
