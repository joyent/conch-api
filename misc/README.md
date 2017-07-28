# Conch Nginx config

This is an Nginx config that proxy's port 80 to port 5000 for the
Conch dancer2 service.  In addition it adds the proper CORS headers
for preflight checks.  See [this page](https://distinctplace.com/2017/04/17/nginx-access-control-allow-origin-cors/)
for some documentation about CORS.  We should only need this if the UI
is running on a different server than the Conch dancer2 server.

Here is the most easy way to check that it is working:

``` shell
curl -H "Origin: foo.com" \
  -H "Access-Control-Request-Method: POST" \
  -X OPTIONS --verbose \
http://<service-ip>:80/login
```
This will emulate what a browser sends before sending the actual POST request
when logging in.

The response should look like:

``` shell
*   Trying <ip> ...
* TCP_NODELAY set
* Connected to <ip> (<ip>) port 80 (#0)
> OPTIONS /login HTTP/1.1
> Host: <ip>
> User-Agent: curl/7.54.0
> Accept: */*
> Origin: foo.com
> Access-Control-Request-Method: POST
>
< HTTP/1.1 200 OK
< Server: nginx/1.10.3 (Ubuntu)
< Date: Fri, 28 Jul 2017 21:13:14 GMT
< Content-Type: application/octet-stream
< Content-Length: 0
< Connection: keep-alive
< Access-Control-Allow-Origin: *
< Access-Control-Allow-Methods: GET, POST, OPTIONS, HEAD
< Access-Control-Allow-Headers: Authorization, Origin, X-Requested-With, Content-Type, Accept
<
* Connection #0 to host <ip> left intact
```

The most important part is the `200 OK` and `< Access-Control-Allow-Origin: *`

If you don't see either of those, cross-origin requests **will not work**

If that does work, you can then do the normal request that you intended in the
first place:

``` shell
curl -v -X POST -d '{"user":"myuname","password":"mypasswd"}' http://<service ip>:80/login
```

Again, that should return `200 OK` and `< Access-Control-Allow-Origin: *`
