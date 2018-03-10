#/bin/bash

#NOT TESTED YET


NAME="scaledown-cassandra-service"

PIDFILE="/var/run/$NAME.pid"
LOGFILE="/var/log/$NAME.log"

SCRIPT="/usr/share/clearwater/bin/scale-down.sh"
RUNAS=root

start() {
    if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE"); 
    then
        echo "The service is already running."
        return 1
    fi
    echo "Starting service..." >&2
    local COMMAND="$SCRIPT &> \"$LOGFILE\" & echo \$!"
    su -c $COMMAND $RUNAS > "$PIDFILE"
    echo "The service is started." >&2
}

stop() {
    if [ ! -f "$PIDFILE" ] || ! kill -0 $(cat "$PIDFILE");
    then
    echo "The service is not running." >&2
    fi
    echo "Stopping service...">&2
    su -c kill -15 $(cat "$PIDFILE") && rm -f "$PIDFILE"
    echo "The service is stopped">&2
}

uninstall() {
    read -p "Do you want to permanently remove this service? [y/n]" -n 1
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        stop
        rm -f "$PIDFILE"
        update-rc.d -f $NAME remove
        rm -fv "$0"      
    fi

}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    uninstall)
        uninstall
        ;;
    restart)
        stop
        start
        ;;
    *)
    echo "Usage: $0 {start|stop|restart|uninstall}"
esac