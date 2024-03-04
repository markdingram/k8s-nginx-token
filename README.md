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


