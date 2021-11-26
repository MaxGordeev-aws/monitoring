# Get the current cluster name
cluster = max-eks
#cluster = $(shell basename $(kubectl config current-context))

# configutation
version = 1.21
namespace = monitoring
include cluster/$(cluster)/config
region = us-east-2

# do not change
kubectl := kubectl -n $(namespace)

#env-vars for replacements
replacements="\
s/NAMESPACE/$(namespace)/g;\
s/STORAGESIZE/$(storagesize)/g;\
s/CLUSTER/$(cluster)/g;\
s/RETENTIONPERIOD/$(retentionPeriod)/g\
"

namespace:
	@cat namespace.yaml | sed $(replacements) | kubectl apply -f -

run-prometheus: namespace
	@cat server/cluster-role.yaml | sed $(replacements) | kubectl apply -f -
	@cat server/pvc.yaml | sed $(replacements) | kubectl apply -f -
	@cat server/config-map.yaml | sed $(replacements) | kubectl apply -f -
	@cat server/deployment.yaml | sed $(replacements) | kubectl apply -f -
	@cat server/service.yaml | sed $(replacements) | kubectl apply -f -
	@###
	@cat kube-state-metrics/cluster-role.yaml | sed $(replacements) | kubectl apply -f -
	@cat kube-state-metrics/deployment.yaml | sed $(replacements) | kubectl apply -f -
	@cat kube-state-metrics/service.yaml | sed $(replacements) | kubectl apply -f -
	@###
	@cat node-exporter/daemonset.yaml | sed $(replacements) | kubectl apply -f -
	@cat node-exporter/service.yaml | sed $(replacements) | kubectl apply -f -
	@###
	@cat pushgateway/cluster-role.yaml | sed $(replacements) | kubectl apply -f -
	@cat pushgateway/deployment.yaml | sed $(replacements) | kubectl apply -f -
	@cat pushgateway/service.yaml | sed $(replacements) | kubectl apply -f -

delete-prometheus: namespace
	@cat server/cluster-role.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat server/pvc.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat server/config-map.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat server/deployment.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat server/service.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@###
	@cat kube-state-metrics/cluster-role.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat kube-state-metrics/deployment.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat kube-state-metrics/service.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@###
	@cat node-exporter/daemonset.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat node-exporter/service.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@###
	@cat pushgateway/cluster-role.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat pushgateway/deployment.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found
	@cat pushgateway/service.yaml | sed $(replacements) | kubectl delete -f - --ignore-not-found



# After resize you will have to wait at least 6 hours before another modification per EBS volume
# Resizing might take anywhere between couple minutes to 10-15 minutes

resize-volume:
	@cat server/pvc.yml | sed $(replacements) | kubectl apply -f -
	$(kubectl) wait pvc/prometheus-server --for=condition=FileSystemResizePending --timeout=30m
	@$(eval podname := $(shell $(kubectl) get pods -lapp=prometheus-server -o name))
	@$(kubectl) delete $(podname)


disk-usage:
	@$(kubectl) exec -it $$($(kubectl) get pod \
		-l app=prometheus-server -o=jsonpath='{.items[0].metadata.name}') \
		-c prometheus-server -- df -h
