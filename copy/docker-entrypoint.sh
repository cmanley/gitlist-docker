#!/bin/sh
# Same settings as in Dockerfile:
REPOSITORY_ROOT='/repos'
REPOSITORY_DUMMY="$REPOSITORY_ROOT/If_you_see_this_then_the_host_volume_was_not_mounted"


# Abort if the host's volume was not mounted read-only.
if [ ! -d "$REPOSITORY_DUMMY" ]; then
	#RO=$(findmnt -no 'OPTIONS' "$REPOSITORY_ROOT" 2>&1 | tr , "\n" | grep -F ro);	# part of util-linux package
	RO=$(sed -En 's|^\S+\s+'"$REPOSITORY_ROOT"'\s+\S+\s+(\S+).*|\1|p' < /proc/mounts | tr , "\n" | grep -F ro)
	if [ -z "$RO" ]; then
		echo "$0: Aborted to protect you from your own bad habits because you didn't mount the volume $REPOSITORY_ROOT read-only using the :ro attribute" >&2
		exit 1
	fi
fi


# Default entrypoint (as defined by Dockerfile CMD):
if [ "$(echo $1 | cut -c1-7)" = 'gitlist' ] || [ "$1" = 'shell' ]; then
	GITLIST_ROOT='/var/www/gitlist'
	GITLIST_CACHE_DIR="$GITLIST_ROOT/cache"
	GITLIST_THEMES_DIR="$GITLIST_ROOT/themes"
	GITLIST_CONFIG_FILE="$GITLIST_ROOT/config.ini"
	PHP_FPM_GID_FILE='/etc/php7/php-fpm.d/zz_gid.conf'

	# Set gid of php-fpm so that it can read the host's volume
	if [ ! -d "$REPOSITORY_DUMMY" ]; then
		if [ -z "$GITLIST_GID" ]; then
			# GITLIST_GID not given and volume was mounted, so read gid from mounted volume.
			GITLIST_GID=$(stat -c%g "$REPOSITORY_ROOT")
			echo "$0: Host's volume has gid $GITLIST_GID" >&2
		elif ! echo "$GITLIST_GID" | grep -qE '^[0-9]{1,9}$'; then
			echo "$0: Bad gid syntax in GITLIST_GID environment variable ($GITLIST_GID)" >&2
			exit 1
		fi
		CURRENT_GROUP=
		CURRENT_GID=
		if [ -f "$PHP_FPM_GID_FILE" ]; then
			CURRENT_GROUP=$(sed -En 's/^group\s*=\s*(\S+)\s*$/\1/p' < "$PHP_FPM_GID_FILE")
			if [ -n "$CURRENT_GROUP" ]; then
				CURRENT_GID=$(getent group "$CURRENT_GROUP" | cut -d: -f3)
			fi
		fi
		if [ "$GITLIST_GID" = "$CURRENT_GID" ]; then
			echo "$0: php-fpm is already configured to use the gid $GITLIST_GID($CURRENT_GROUP)"
		else
			GROUP=$(getent group "$GITLIST_GID" | cut -d: -f1)
			if [ -z "$GROUP" ]; then	# no existing group has the requested gid; so create the gitlist group for this
				if [ "$(id -u)" = '0' ]; then
					GROUP=gitlist
					addgroup -g "$GITLIST_GID" "$GROUP"
				else
					echo "$0: You need to run this script as root in order to add a new group" >&2
					exit 1
				fi
			else
				:	# the requested gid belongs to an existing group name, so just use that
			fi
			printf "\n[www]\ngroup=%s\n" "$GROUP" > "$PHP_FPM_GID_FILE"
			chgrp -R "$GROUP" "$GITLIST_CACHE_DIR"
			echo "$0: php-fpm gid set to $GITLIST_GID($GROUP)"
		fi
	fi

	# Optionally set the gitlist debug flag to true or false
	if [ -n "$GITLIST_DEBUG" ]; then
		CURRENT_DEBUG=$(sed -En 's/^debug\s*=\s*(\S+)\s*$/\1/p' < "$GITLIST_CONFIG_FILE")
		if [ "$GITLIST_DEBUG" = "$CURRENT_DEBUG" ]; then
			echo "$0: gitlist debug value is already \"$GITLIST_DEBUG\""
		else
			if [ "$GITLIST_DEBUG" = 'true' ] || [ "$GITLIST_DEBUG" = 'false' ]; then
				sed -E -i -e 's/^(debug\s*=\s*).+/\1'"$GITLIST_DEBUG"'/' "$GITLIST_CONFIG_FILE"
				echo "$0: gitlist debug value changed to \"$GITLIST_DEBUG\""
			else
				echo "$0: Bad syntax in GITLIST_DEBUG environment variable ($GITLIST_DEBUG)"
			fi
		fi
	fi

	# Optionally set gitlist theme
	if [ -n "$GITLIST_THEME" ]; then
		CURRENT_THEME=$(sed -En 's/^theme\s*=\s*['"'"'"](.+?)['"'"'"]\s*$/\1/p' < "$GITLIST_CONFIG_FILE")
		if [ "$GITLIST_THEME" = "$CURRENT_THEME" ]; then
			echo "$0: gitlist theme is already \"$GITLIST_THEME\""
		else
			if [ -d "$GITLIST_THEMES_DIR/$GITLIST_THEME" ]; then
				sed -E -i -e 's/^(theme\s*=\s*).+/\1"'"$GITLIST_THEME"'"/' "$GITLIST_CONFIG_FILE"
				echo "$0: gitlist theme changed to \"$GITLIST_THEME\""
			else
				echo "$0: gitlist theme \"$GITLIST_THEME\" does not exist"
			fi
		fi
	fi

	if [ "$1" = 'shell' ]; then
		# Enter the shell
		echo 'Start supervisord with: /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf'
		exec /bin/sh
	else
		# Start nginx and php-fpm
		exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
	fi
else
	# All other entry points. Typically /bin/sh
	exec "$@"
fi
