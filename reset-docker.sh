echo "Resetting docker compose environment..."

DEV=false
FILE=""
if [ $1 = "dev" -o $1 = "-d" ] ; then
    DEV=true
    FILE="-f docker-compose.development.yml"
    echo "Running in development mode."
fi

docker compose $FILE down -v
echo y | rm -r Public/*
docker compose $FILE up db & pid=$!
sleep 5
kill ${pid}
if [ $DEV = false ] ; then
    docker compose $FILE up elasticsearch -d
    sleep 5
    docker compose $FILE run migrate
    docker compose $FILE up db app queues redis caddy
else
    docker compose $FILE up elasticsearch db redis kibana
fi
