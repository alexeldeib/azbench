default: push deploy

deploy:
	./scripts/deploy.sh

push: postgresql-push pgbench-push

postgresql-push: postgresql-image
	docker push alexeldeib/postgresql:latest

postgresql-image:
	docker build -f images/postgresql/Dockerfile images/postgresql -t alexeldeib/postgresql:latest

pgbench-push: pgbench-image
	docker push alexeldeib/pgbench:latest

pgbench-image:
	docker build -f images/pgbench/Dockerfile images/pgbench -t alexeldeib/pgbench:latest