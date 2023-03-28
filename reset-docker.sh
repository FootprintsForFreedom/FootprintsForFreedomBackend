echo "Resetting docker-compose environment..."

docker compose down -v
# echo y | docker volume prune
echo y | rm -r Public/*
docker compose up db & pid=$!
sleep 5
kill ${pid}
docker compose up elasticsearch -d
sleep 5
docker compose run migrate
docker compose up db app queues redis caddy
