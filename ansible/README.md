# Ansible scripts

Prepare environment:

```shell script
export GCP_AUTH_KIND=serviceaccount
export GCP_SERVICE_ACCOUNT_FILE=<path to service account file>
export GCP_SCOPES=https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/cloud-platform
```

Ansible extra vars:
```shell script
env=dev|prod
project_id=<project id>
state=create|clean
sql_db_version=1 // optional
```

Create development environment:
```shell script
ansible-playbook main.yaml --extra-vars "state=create env=dev project_id=webserver1-283520"
```
Clean development environment:
```shell script
ansible-playbook main.yaml --extra-vars "state=clean env=dev project_id=webserver1-283520"
```
Create production environment:
```shell script
ansible-playbook main.yaml --extra-vars "state=create env=prod project_id=einvoice-prod"
```
Clean production environment:
```shell script
ansible-playbook main.yaml --extra-vars "state=clean env=prod project_id=einvoice-prod"
```
