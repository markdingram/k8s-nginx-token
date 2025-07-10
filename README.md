WARNING: Ingress NGINX removed Lua Plugins in https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.12.0

# Ingress NGINX Controller - LUA example

Running Lua Plugins inside Kubernetes "ingress-nginx"

## Setup

- Install Kind, Helm etc

- Add to /etc/hosts

    ```
    ::1       kind.internal
    127.0.0.1 kind.internal
    ```

- Run `make all`


- http://kind.internal/ should show the `kuard` page


- Test the "auth_simple" plugin: `curl -H "Authorization: rejectme" "http://kind.internal"`

- Connect to redis: `docker run --rm redis:7.2.4-bookworm redis-cli -h host.docker.internal set hello 1`


## Test the "auth_redis" plugin

Confirm that the app is serving:

````
$ curl -I -X GET "http://kind.internal"
HTTP/1.1 200 OK
Date: Mon, 04 Mar 2024 11:41:09 GMT
Content-Type: text/html
Content-Length: 1703
Connection: keep-alive
````

Confirm with a token not in Redis:

````
$ curl -s -I -X GET -H "Authorization: Bearer aaaa.bbbb.my_sig" "http://kind.internal" | head -n 1
HTTP/1.1 200 OK
````

Write token to Redis & confirm request is now rejected:


````
$ docker run --rm redis:7.2.4-bookworm redis-cli -h host.docker.internal set my_sig 1
OK
$ curl -s -I -X GET -H "Authorization: Bearer aaaa.bbbb.my_sig" "http://kind.internal" | head -n 1
HTTP/1.1 403 Forbidden
````


## Confirm Redis connections are being pooled

````
$ while true; do curl -s -I -X GET -H "Authorization: Bearer aaaa.bbbb.my_sig" "http://kind.internal" | head -n 1; done
HTTP/1.1 403 Forbidden
HTTP/1.1 403 Forbidden
HTTP/1.1 403 Forbidden
... ^c

Check the "reused" values printed in ingress logs:

$ kubectl logs -n ingress deploy/ingress-nginx-controller | grep reused
2024/03/04 12:00:36 [notice] 35#35: *3752 [lua] main.lua:29: signature: my_sig, exists: 1, reused: 2, client: 192.168.65.1, server: kind.internal, request: "GET / HTTP/1.1", host: "kind.internal"
2024/03/04 12:00:36 [notice] 40#40: *3753 [lua] main.lua:29: signature: my_sig, exists: 1, reused: 6, client: 192.168.65.1, server: kind.internal, request: "GET / HTTP/1.1", host: "kind.internal"
2024/03/04 12:00:36 [notice] 43#43: *3754 [lua] main.lua:29: signature: my_sig, exists: 1, reused: 4, client: 192.168.65.1, server: kind.internal, request: "GET / HTTP/1.1", host: "kind.internal"
````

