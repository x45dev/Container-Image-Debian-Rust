# Makefile
.PHONY: build run clean shell

build:
	docker-compose build

run:
	docker-compose up --build # Rebuild if necessary and start.

run-detached:
	docker-compose up -d --build

stop:
	docker-compose down

clean:
	docker-compose down --rmi all --volumes  # Remove containers, images, and volumes.  Use with caution!

shell:
	docker-compose run app bash # Get a shell inside the container (for debugging).

logs:
	docker-compose logs -f app

test: build
	# Assuming you have integration tests (e.g., in a 'tests' directory)
	# You might use a different service definition in docker-compose.yml for tests
	# docker-compose run app cargo test

build-builder:
	docker-compose build --build-arg BUILDKIT_INLINE_CACHE=1 app --target builder

build-runtime:
	docker-compose build --build-arg BUILDKIT_INLINE_CACHE=1 app --target runtime