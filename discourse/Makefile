COMPOSE_DATA=-f ../devbox/compose.bn-pg15.yml -f ../devbox/compose.bn-redis.yml -f ../devbox/compose.mariadb.yml

prepare:
	@echo "Preparing Discourse"
	rm -rf discourse
	rm -rf discourse_docker
	git clone https://github.com/discourse/discourse.git --depth 1
	git clone https://github.com/discourse/discourse_docker.git --depth 1
	
setup:
	@echo "No setup required"

build-clear:
	docker rmi -f discourse/base discourse/app

build-base:
	docker build -f image/base/slim.Dockerfile image/base -t discourse/base

build-app:
	docker build . -f image/discourse_app/Dockerfile -t discourse/app

server-up:
	docker compose \
	-f compose.yml \
	-f ../buildbox/compose/compose.base-network.yml \
	-f ../buildbox/compose/compose.redis.yml \
	-f ../buildbox/compose/compose.postgres.yml \
	up -d

server-down:
	docker compose \
	-f compose.yml \
	-f ../buildbox/compose/compose.base-network.yml \
	-f ../buildbox/compose/compose.redis.yml \
	-f ../buildbox/compose/compose.postgres.yml \
	down -v

server-enter:
	docker compose \
	-f compose.yml \
	-f ../buildbox/compose/compose.base-network.yml \
	-f ../buildbox/compose/compose.redis.yml \
	-f ../buildbox/compose/compose.postgres.yml \
	run wp-install bash
