# Docker Swarm Cluster su VMware VSphere
Questo progetto permette di deployare su VMware VSphere usando Terraform un cluster basato su Docker Swarm.

## Crea un template
In primo luogo occorrerà realizzare un template di partenza basato su Ubuntu 16.10.
Su questo template è bene accertarsi che non sia presente una scheda di rete con un mac address assegnato.
Inoltre occorrerà creare una chiave RSA e aggiungere la chiave pubblica tra quelle autorizzate dalle macchine che
successivamente utilizzeranno quel template.

Per generare una chiave RSA:
```
ssh-keygen -t rsa -b 4096 -C "docker@vsphere" -f resources/ssh_keys/vsphere
```

## Generazione certificati
Occorrerà generare anche dei certificati SSL che permetteranno di collegarsi in modalità remota allo Swarm.

- SSL_SUBJECT: Questo parametro dovrò essere sostituito con il dominio al quale si vuole associare lo swarm.
In particolare occorrerà creare un record DNS A che punterà tutti quanti gli indirizzi ip dei nodi manager attivi.

- SSL_IP: Questo parametro dovrà essere sostituito con l'indirizzo ip del primo manager definito nel file di configurazione.

```
docker run --rm -e SSL_SUBJECT="docker-swarm.menxit.com" -e SSL_IP="192.168.161.168" -v $(pwd)/resources/certs/:/certs paulczar/omgwtfssl
```

## Configurazione
A questo punto occorrerà creare un file denominato variables.tfvars e configurarlo sulla base del file variables.tfvars.example.

## Deploy
Per deployare basta eseguire il comando:
```
make apply
```
## Connettersi da remoto allo Swarm
Si realizza un file denominato docker.env.
Al posto di dominio_cluster si inserisce il valore della variabile domain_cluster.

```
export DOCKER_HOST=tcp://docker-swarm.menxit.com:2376
export DOCKER_CERT_PATH=$(pwd)/resources/certs
export DOCKER_TLS_VERIFY=1
```

A questo punto per connettersi allo swarm basterà:
```
eval $(cat docker.env)
```

## Deployare il registry (opzionale)
Per deployare un registry privato:

1) Connettersi allo swarm:
```
eval $(cat docker.env)
```

2) ./services/registry/deploy.sh

## Deployare un'immagine privata
Una volta deployato il registry privato è possibile pusharci sopra immagini private.
In particolare in services/d-sentence-swarm-zuul è possibile trovare un'applicazione basata su 3 microservizi basati
su Spring.

Aprire il docker-compose.yml e fare un search and replace della stringa "docker-swarm.menxit.com:5000" con il proprio
dominio.

A questo punto occorrerà connettersi allo swarm remoto:
```
eval $(cat docker.env)
```

Per buildare le immagini usate nel progetto basta lanciare il seguente comando:
```
$ docker-compose build
```

Per pushare le immagini buildate nel registry privato:
```
$ docker-compose push
```

Per deployare:
```
$ docker stack deploy --compose-file docker-compose.yml sentence-alt
```

## Deployare nginx (opzionale)
Per deployare un web server nginx sulla porta:

1) Connettersi allo swarm:
```
eval $(cat docker.env)
```

2) Creare il servizio:
```
docker service create -p3000:80 nginx
```

3) Accedi al web server:
```
curl http://docker-swarm.menxit.com:3000
```