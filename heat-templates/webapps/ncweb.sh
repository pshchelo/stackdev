#! /bin/sh -v
body=$(hostname)
ncport=${NC_PORT:-8080}
start-stop-daemon -S -bmp /var/run/simpleweb.pid -x nc -- -lk -p $ncport -e sh -c "echo -e \"HTTP/1.1 200 OK\r\nContent-Length: ${#body}\r\n\r\n${body}\""
