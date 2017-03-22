# Docker Swarm Cluster su VMware VSphere

Questo progetto permette di deployare su VMware VSphere usando Terraform un cluster basato su Docker Swarm.

## Crea un template
In primo luogo occorrerà realizzare un template di partenza basato su Ubuntu 16.10. Su questo template è bene accertarsi che non sia presente una scheda di rete con un mac address assegnato. Inoltre occorrerà creare una chiave RSA e aggiungere la chiave pubblica tra quelle autorizzate dalle macchine che successivamente utilizzeranno quel template.

```
ssh-keygen -t rsa -b 4096 -C "docker@vsphere" -f ./resources/ssh_keys/vsphere
```

## Configurazione
A questo punto occorrerà creare un file denominato variables.tfvars e configurarlo sulla base del file variables.tfvars.example.

## Deploy
Per deployare basta eseguire il comando:
```
./deploy.sh
```