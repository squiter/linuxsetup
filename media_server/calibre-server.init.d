#!/usr/bin/env bash
### BEGIN INIT INFO
# Provides:          calibre-server
# Required-Start:    $network $local_fs $syslog
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Calibre server with books
# Description:
#
### END INIT INFO

DAEMON_PATH="/usr/bin/"
DAEMON=calibre-server
DAEMONOPTS="--with-library '/home/renan/Copy/Biblioteca Técnica/Computing/' -p 4366"

NAME=calibre-server
DESC="Web interface for serving calibre content"
PIDFILE=/tmp/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME

case "$1" in
    start)
	printf "%-50s" "Starting $NAME..."
	cd $DAEMON_PATH
	echo "$DAEMON $DAEMONOPTS"
	PID=`sudo -u renan calibre-server --with-library '/home/renan/Copy/Biblioteca Técnica/Computing/' -p 4366 > /dev/null 2>&1 & echo $!`
	#echo "Saving PID" $PID " to " $PIDFILE
        if [ -z $PID ]; then
            printf "%s\n" "Fail"
        else
            echo $PID > $PIDFILE
            printf "%s\n" "Ok"
        fi
	;;
    status)
        printf "%-50s" "Checking $NAME..."
        if [ -f $PIDFILE ]; then
            PID=`cat $PIDFILE`
            if [ -z "`ps axf | grep ${PID} | grep -v grep`" ]; then
                printf "%s\n" "Process dead but pidfile exists"
            else
                echo "Running"
            fi
        else
            printf "%s\n" "Service not running"
        fi
	;;
    stop)
        printf "%-50s" "Stopping $NAME"
        PID=`cat $PIDFILE`
        cd $DAEMON_PATH
        if [ -f $PIDFILE ]; then
            kill -HUP $PID
            printf "%s\n" "Ok"
            rm -f $PIDFILE
        else
            printf "%s\n" "pidfile not found"
        fi
	;;

    restart)
  	$0 stop
  	$0 start
	;;

    *)
        echo "Usage: $0 {status|start|stop|restart}"
        exit 1
esac
