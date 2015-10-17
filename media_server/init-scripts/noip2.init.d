#! /bin/sh
# /etc/init.d/noip2

# Supplied by no-ip.com
# Modified for Debian GNU/Linux by Eivind L. Rygge <eivind@rygge.org>
# Updated by David Courtney to not use pidfile 130130 for Debian 6.
# Updated again by David Courtney to "LSBize" the script for Debian 7.

### BEGIN INIT INFO
# Provides:     noip2
# Required-Start: networking
# Required-Stop:
# Should-Start:
# Should-Stop:
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Start noip2 at boot time
# Description: Start noip2 at boot time
### END INIT INFO

# . /etc/rc.d/init.d/functions  # uncomment/modify for your killproc

DAEMON=/usr/local/bin/noip2
NAME=noip2

test -x $DAEMON || exit 1

case "$1" in
    start)
        echo -n "Starting dynamic address update: "
        start-stop-daemon --start --exec $DAEMON --name $NAME
        echo "done."
        ;;
    stop)
        echo -n "Shutting down dynamic address update:"
        start-stop-daemon --stop --oknodo --retry 30 --exec $DAEMON --name $NAME
        echo "done."
        ;;

    restart)
        echo -n "Restarting dynamic address update: "
        start-stop-daemon --stop --oknodo --retry 30 --exec $DAEMON --name $NAME
        start-stop-daemon --start --exec $DAEMON --name $NAME
        echo "done."
        ;;

    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac
exit 0
