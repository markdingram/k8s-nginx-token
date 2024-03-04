
IMAGE := registry.k8s.io/ingress-nginx/controller:v1.9.6

REDIS_IMAGE := redis:7.2.4-bookworm

.PHONY: all
all: cluster ingress redis app

.PHONY: ingress-docker
ingress-docker: 
	cd ingress/docker && docker build . --build-arg IMAGE=$(IMAGE) --tag $(IMAGE)-lua

.PHONY: cluster
cluster: ingress-docker
	kind create cluster --config cluster.yaml
	kind load docker-image $(IMAGE)-lua
	docker pull $(REDIS_IMAGE) && kind load docker-image $(REDIS_IMAGE)

.PHONY: ingress
ingress: ingress-docker
	helm repo add ingress-nginx  https://kubernetes.github.io/ingress-nginx
	cd ingress; helm upgrade --create-namespace --namespace ingress --install ingress-nginx /Users/markingram/Library/Caches/helm/repository/ingress-nginx-4.9.1.tgz --values ingress-nginx-values.yaml

.PHONY: redis
redis:
	kubectl apply -n ingress -f redis.yaml

.PHONY: app
app:
	cd app; ./wait_for_ingress.sh && kubectl apply -f kuard.yaml


# redeploy any changes to the plugins to an existing cluster
.PHONY: ingress-redeploy
ingress-redeploy: ingress-docker
	kind load docker-image $(IMAGE)-lua
	kubectl delete pod -n ingress -l app.kubernetes.io/component=controller
