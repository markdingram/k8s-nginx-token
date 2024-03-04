#!/bin/bash

### Wait for ingress nginx pod creation
echo -n "Wait for pod app.kubernetes.io/component=controller to be created."
while : ; do
[ -n "$(kubectl -n ingress get pod --selector=app.kubernetes.io/component=controller 2> /dev/null)" ] && echo && break
sleep 2
echo -n "."
done
### Wait for pod to be ready
timeout="180s"
echo -n "Wait for pod app.kubernetes.io/component=controller to be ready (timeout=$timeout)..."
kubectl wait --namespace ingress \
            --for=condition=ready pod \
            --selector=app.kubernetes.io/component=controller \
            --timeout=$timeout
echo

### Even after waiting for the pod to be ready it there is still a chance that a Ingress creation request could fail with
### Error: Internal error occurred: failed calling webhook "validate.nginx.ingress.kubernetes.io": Post "https://ingress-nginx-controller-admission.ingress-nginx.svc:443/networking/v1/ingresses?timeout=10s": dial tcp 10.96.133.10:443: connect: connection refused
### This final sleep is an attempt to avoid this - the Webhook has no condition to check exactly when it becomes ready, just hope it is shortly after the pod above is ready
echo -n "Extra wait to hope for webhook readiness"
sleep 2
