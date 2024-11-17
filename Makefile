run:
	docker build -t strongswan-vpn .
	docker run -d --env-file .env --network host --cap-add=NET_ADMIN --cap-add=NET_RAW --restart unless-stopped --name strongswan-vpn strongswan-vpn

stop:
	docker stop strongswan-vpn
	docker rm strongswan-vpn