gitlist-docker
==============

GitList (an elegant and modern git repository viewer) in a small footprint Docker image (based on nginx, php-fpm 7.2, and Alpine Linux 3.8) with configurable runtime options (such as timezone, gid, theme) and an extra custom 100% wide bootstrap theme.

You can use it to quickly and safely expose a web interface to the git repositories directory on your host machine.

The Dockerfile uses a custom build of GitList from https://github.com/klaussilveira/gitlist

Usage
-----

You can simply pull this image from docker hub like this:

	docker pull cmanley/gitlist-docker

Or you can build the image like this:

    git clone <Link from "Clone or download" button>
    cd gitlist-docker
    docker build --rm -t gitlist .

The docker build command must be run as root or as member of the docker group,
or else you'll get the error "permission denied while trying to connect to the Docker daemon socket".

Then assuming that your git repository root directory on the host machine is /var/lib/git
and has the privileges 750 (user may read+write, group can only read, and others are denied),
and you want gitlist be accessible on 127.0.0.1:8888, execute one of these commands:

	# Simple
	docker run --name gitlist -v /var/lib/git:/repos:ro -p 127.0.0.1:8888:80/tcp --rm -d gitlist

	# Use the same time zone as the host
	docker run --name gitlist -v /var/lib/git:/repos:ro -p 127.0.0.1:8888:80 -e TZ=$(</etc/timezone) -d --rm gitlist

	# Specify a different theme
	docker run --name gitlist -v /var/lib/git:/repos:ro -p 127.0.0.1:8888:80/tcp -e GITLIST_THEME=default --rm -d gitlist

	# Specify a different theme, which GID to use for reading the repository, and the timezone
	docker run --name gitlist -v /var/lib/git:/repos:ro -p 127.0.0.1:8888:80/tcp -e GITLIST_GID=$(stat -c%g /var/lib/git) -e GITLIST_THEME=bootstrap3 -e TZ=$(</etc/timezone) --rm -d gitlist

	# Start container and a shell session within it (this does not start nginx)
	docker run --name gitlist -v /var/lib/git:/repos:ro -p 127.0.0.1:8888:80/tcp --rm -it gitlist /bin/sh

In case of problems, start the container without the --rm option, check your docker logs, and check that the container is running:

	docker logs gitlist
	docker ps

Stop the container using:

	docker stop gitlist

Runtime configuration
---------------------

You can configure how the container runs by passing some of the environment variables below using the --env or -e option to docker run.
Unless your host's repository is world-readable (which it shouldn't be), then you'll need to at least need to specify GITLIST_GID.

| name              | description                                                                                                      |
|-------------------|------------------------------------------------------------------------------------------------------------------|
| **GITLIST_DEBUG** | Allowed values: true or false (default).                                                                         |
| **GITLIST_GID**   | The gid (group id) of the host repository directory. If not given, then the gid of the host volume will be used. |
| **GITLIST_THEME** | This can be the name of any existing gitlist theme (default, bootstrap3, bootstrap3-wide)                        |
| **TZ**            | Specify the time zone to use. Default is UTC. In most cases, use the value in the host's /etc/timezone file.     |

The theme called "default" is the default theme in the original source distribution of GitList.
In this Docker build however, the default theme has been changed to "bootstrap3-wide" which is a 100% wide variant of the "bootstrap3" theme.

Security information
--------------------

* nginx runs as nobody:nobody and forwards requests to php-fpm which executes the GitList code.
* php-fpm runs with uid nobody and with the gid of the GITLIST_GID environment variable if given, else with gid of the host volume.
* It's important to always protect your host's volume by adding the ":ro" attribute to the docker run -v option as in the examples above.
* The URI /phpinfo.php exists, so you may want to deny access to it in your proxy.
