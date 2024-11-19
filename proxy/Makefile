start:
	docker build -t proxy-server .
	docker run -d --env-file .env --network host --cap-add=NET_ADMIN --cap-add=NET_RAW --restart unless-stopped --name proxy-server proxy-server

stop:
	docker stop proxy-server
	docker rm proxy-server