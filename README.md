# Docker Swarm Cluster su VMware VSphere
Questo progetto permette di deployare un cluster basato su Docker Swarm su VMware VSphere usando Terraform.

## Crea un template
In primo luogo occorrerà realizzare un template di partenza basato su Ubuntu 16.10.
Su questo template è bene accertarsi che non sia presente una scheda di rete con un mac address assegnato.
Inoltre occorrerà creare una chiave RSA e aggiungere la chiave pubblica tra quelle autorizzate dalle macchine che
successivamente utilizzeranno quel template.

Per generare una chiave RSA:
```bash
$ ssh-keygen -t rsa -b 4096 -C "docker@vsphere" -f resources/ssh_keys/vsphere
```

## Generazione certificati
Occorrerà generare anche dei certificati SSL che permetteranno di collegarsi in modalità remota allo Swarm.

- SSL_SUBJECT: Questo parametro dovrà essere sostituito con il dominio al quale si vuole associare lo swarm.
In particolare occorrerà creare un record DNS A che punterà tutti quanti gli indirizzi ip dei nodi manager attivi.

- SSL_IP: Questo parametro dovrà essere sostituito con l'indirizzo ip del primo manager definito nel file di configurazione.
Questo parametro è necessario in quanto in fase di provisioning i manager e i worker dovranno fare il join sul nodo master
e avranno necessità di utilizzare l'indirizzo ip per connettersi ad esso e prelevare il token segreto.

```bash
$ docker run --rm -e SSL_SUBJECT="swarm.inf.uniroma3.it" -e SSL_IP="192.168.161.168" -v $(pwd)/resources/certs/:/certs paulczar/omgwtfssl
```

## Configurazione
A questo punto occorrerà creare un file denominato variables.tfvars e configurarlo sulla base del file variables.tfvars.example.

## Deploy
Per deployare basta eseguire il comando:
```bash
$ make apply
```
## Connettersi da remoto allo Swarm
Si realizza un file denominato docker.env.
Al posto di dominio_cluster si inserisce il valore della variabile domain_cluster.

```bash
export DOCKER_HOST=tcp://swarm.inf.uniroma3.it:2376
export DOCKER_CERT_PATH=$(pwd)/resources/certs
export DOCKER_TLS_VERIFY=1
```

A questo punto per connettersi allo swarm basterà:
```bash
$ eval $(cat docker.env)
```

## Deployare il registry (opzionale)
Per deployare un registry privato:

1) Connettersi allo swarm:
```bash
$ eval $(cat docker.env)
```

2) Entrare nella cartella services/registry
```bash
$ cd services/registry
```

3) Deployare il registry
```bash
$ ./deploy.sh
```

## Deployare un'immagine privata (opzionale)
Una volta deployato il registry privato è possibile pusharci sopra immagini private.
In particolare in services/d-sentence-swarm-zuul è possibile trovare un'applicazione basata su 3 microservizi basati
su Spring.

Aprire il docker-compose.yml e fare un search and replace della stringa "swarm.inf.uniroma3.it:5000" con il proprio
dominio.

A questo punto occorrerà connettersi allo swarm remoto:
```bash
$ eval $(cat docker.env)
```

Entrare nella cartella services/d-sentence-swarm-zuul:
```bash
$ cd services/d-sentence-swarm-zuul
```

Per buildare le immagini usate nel progetto basta lanciare il seguente comando:
```bash
$ docker-compose build
```

Per pushare le immagini buildate nel registry privato:
```bash
$ docker-compose push
```

Per deployare:
```bash
$ ./deploy.sh
```

## Deployare nginx (opzionale)
Per deployare un web server nginx sulla porta:

1) Connettersi allo swarm:
```bash
$ eval $(cat docker.env)
```

2) Creare il servizio:
```bash
$ docker service create -p3000:80 nginx
```

3) Accedi al web server:
```bash
$ curl http://swarm.inf.uniroma3.it:3000
```