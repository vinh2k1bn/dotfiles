if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
	exec ~/.scripts/startup.sh
fi
