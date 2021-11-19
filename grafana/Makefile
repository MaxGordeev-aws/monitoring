# Get the current Main Cluster name
cluster = Ubuntu-team-EKS
#cluster = $(shell basename $(kubectl config current-context))
namespace = monitoring

# in order to change service, all grafana resource names and labels should be changed to SERVICE_NAME
service = grafana
include cluster/$(cluster)/config


# do not change these
kubectl := kubectl -n $(namespace)
aws := aws --region $(region)


# Configure and deploy the service
replacements="\
s/SERVICE_NAME/$(service)/g;\
s/NAMESPACE/$(namespace)/g;\
s/STORAGESIZE/$(storagesize)/g;\
s/HOSTNAME/$(hostname)/g;\
"

namespace:
	@cat namespace.yaml | sed $(replacements) | kubectl apply -f -

run-grafana: namespace
    
	@cat cluster-role.yaml | sed $(replacements) | kubectl apply -f -
	@cat pvc.yaml | sed $(replacements) | kubectl apply -f -
	@cat config-map.yaml | sed $(replacements) | kubectl apply -f -
	@cat deployment.yaml | sed $(replacements) | kubectl apply -f -
	@$(kubectl) create configmap grafana-general-dashboards --from-file ./dashboards/dashboard.json \
		--dry-run=client -o yaml | sed $(replacements) | $(kubectl) create -f -

delete-grafana: namespace
    
	@cat cluster-role.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat deployment.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat config-map.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	

destroy-pvc:
	
	@cat pvc.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found



# Inject secrets from AWS to kube

inject-secrets:
	
	@bin/k8s-secrets-inject-secrets.sh $(service) $(namespace) ./aws/secrets

# Inject secrets from file to aws

create-secrets:
	
	@bin/aws-secretsmanager-create-secrets.sh $(service) ./aws/secrets

# Inject secrets from file to aws

update-secrets:
	
	@bin/aws-secretsmanager-update-secrets.sh $(service) ./aws/secrets
