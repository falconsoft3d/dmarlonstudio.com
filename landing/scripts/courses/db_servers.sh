#!/bin/sh
# Servidores de usar y tirar para los cursos de bases de datos
# (scripts/build-courses.mjs): MySQL 8.4 en el puerto 3407, MongoDB en el
# 27027 y el emulador de Cloud Firestore en el 8095, con sus datos en una
# carpeta temporal. PostgreSQL usa el servidor que ya haya (DMS_COURSE_PG).
#
#   sh scripts/courses/db_servers.sh start | stop
#
# Hace falta: brew install mysql@8.4 mongodb-community@4.4 (tap mongodb/brew)
# y Java 11 o más (el emulador de Firestore se descarga solo).
set -e
DIR="${TMPDIR:-/tmp}/dms-db-servers"
MYSQLD="${DMS_MYSQLD:-/opt/homebrew/opt/mysql@8.4/bin/mysqld}"
MONGOD="${DMS_MONGOD:-/opt/homebrew/opt/mongodb-community@4.4/bin/mongod}"
# El emulador de Firestore (el mismo jar que descarga firebase-tools).
FIRESTORE_JAR="${DMS_FIRESTORE_JAR:-$HOME/.cache/firebase/emulators/cloud-firestore-emulator-v1.19.8.jar}"

wait_port() {
  i=0
  while ! nc -z 127.0.0.1 "$1" 2>/dev/null; do
    i=$((i + 1))
    [ $i -gt 120 ] && { echo "no arranca el puerto $1" >&2; exit 1; }
    sleep 0.5
  done
}

case "$1" in
start)
  mkdir -p "$DIR"
  if ! nc -z 127.0.0.1 3407 2>/dev/null; then
    if [ ! -d "$DIR/mysql" ]; then
      "$MYSQLD" --no-defaults --initialize-insecure --datadir="$DIR/mysql" >"$DIR/mysql-init.log" 2>&1
    fi
    "$MYSQLD" --no-defaults --datadir="$DIR/mysql" --port=3407 --bind-address=127.0.0.1 \
      --socket="$DIR/mysql.sock" --mysqlx=OFF --default-time-zone=+00:00 \
      --pid-file="$DIR/mysql.pid" >"$DIR/mysql.log" 2>&1 &
  fi
  if ! nc -z 127.0.0.1 27027 2>/dev/null; then
    mkdir -p "$DIR/mongo"
    "$MONGOD" --dbpath "$DIR/mongo" --port 27027 --bind_ip 127.0.0.1 \
      --pidfilepath "$DIR/mongo.pid" --logpath "$DIR/mongo.log" --fork >/dev/null
  fi
  if ! nc -z 127.0.0.1 8095 2>/dev/null; then
    [ -f "$FIRESTORE_JAR" ] || curl -sSfo "$FIRESTORE_JAR" --create-dirs \
      "https://storage.googleapis.com/firebase-preview-drop/emulator/$(basename "$FIRESTORE_JAR")"
    nohup java -jar "$FIRESTORE_JAR" --host 127.0.0.1 --port 8095 >"$DIR/firestore.log" 2>&1 &
    echo $! >"$DIR/firestore.pid"
  fi
  wait_port 3407
  wait_port 27027
  wait_port 8095
  echo "MySQL 127.0.0.1:3407 · MongoDB 127.0.0.1:27027 · Firestore 127.0.0.1:8095"
  ;;
stop)
  for f in mysql mongo firestore; do
    [ -f "$DIR/$f.pid" ] && kill "$(cat "$DIR/$f.pid")" 2>/dev/null || true
  done
  echo "parados"
  ;;
*)
  echo "uso: $0 start | stop" >&2
  exit 2
  ;;
esac
