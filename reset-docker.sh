echo "Resetting docker-compose environment..."

docker-compose down
echo y | docker volume prune
echo y | rm -r Public/*
docker-compose up db & pid=$!
sleep 5
kill ${pid}
docker-compose run migrate
docker-compose up db app queues redis caddy
