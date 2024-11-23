rebuild:
	docker build --no-cache -t socks-proxy-server .

start:
	docker build -t socks-proxy-server .
	docker run -d --env-file .env --network host --cap-add=NET_ADMIN --cap-add=NET_RAW --restart unless-stopped --name socks-proxy-server socks-proxy-server

stop:
	docker stop socks-proxy-server
	docker rm socks-proxy-server

logs:
	docker logs -f socks-proxy-server

bash:
	docker exec -it socks-proxy-server /bin/bash