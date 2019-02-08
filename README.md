gitlist-docker
==============

GitList (an elegant and modern git repository viewer) in a small footprint Docker image
(based on nginx, php-fpm 7.2, and Alpine Linux 3.9) with configurable runtime options (such as timezone, gid, theme)
and an extra custom 100% wide bootstrap theme that is the new default theme.

You can use it to quickly and safely expose a web interface to the git repositories directory on your host machine.

The Dockerfile uses a custom build of GitList that's a more recent build than the 1.01 release
available from http://gitlist.org/ or https://github.com/klaussilveira/gitlist

Installation
------------

### Option 1: Download image from hub.docker.com ###
You can simply pull this image from docker hub like this:

	docker pull cmanley/gitlist

If you want to, then you can create a shorter tag (alias) for the image using this command:

	docker tag cmanley/gitlist gitlist

With the shorter tag, you can replace the last argument `cmanley/gitlist` (the image name) with `gitlist`
in all the `docker run` commands listed under the header *Usage examples*.

### Option 2: Build the image yourself ###

	git clone <Link from "Clone or download" button>
	cd gitlist-docker
	docker build --rm -t cmanley/gitlist .

The docker build command must be run as root or as member of the docker group,
or else you'll get the error "permission denied while trying to connect to the Docker daemon socket".

Usage examples
--------------

Assuming that your git repository root directory on the host machine is `/var/lib/git`
and has the privileges 750 (user may read+write, group can only read, and others are denied),
and that you want gitlist be accessible on `127.0.0.1:8888`, then execute one of the commands below.
You may want to place your preferred command in an shell alias or script to not have to type it out each time.

Minimal:

	docker run --name gitlist -v /var/lib/git:/repos:ro -p 127.0.0.1:8888:80/tcp --rm -d cmanley/gitlist

Recommended use (use the same time zone as the host):

	docker run --name gitlist \
	-v /var/lib/git:/repos:ro \
	-p 127.0.0.1:8888:80 \
	-e TZ=$(</etc/timezone) \
	--rm -d cmanley/gitlist

Specify a different theme:

	docker run --name gitlist \
	-v /var/lib/git:/repos:ro \
	-p 127.0.0.1:8888:80/tcp \
	-e GITLIST_THEME=default \
	--rm -d cmanley/gitlist

Specify a different theme, which group id to use for reading the repository, and the timezone:

	docker run --name gitlist \
	-v /var/lib/git:/repos:ro \
	-p 127.0.0.1:8888:80/tcp \
	-e GITLIST_GID=$(stat -c%g /var/lib/git) \
	-e GITLIST_THEME=bootstrap3 \
	-e TZ=$(</etc/timezone) \
	--rm -d cmanley/gitlist

Start container and a shell session within it (this does not start nginx):

	docker run --name gitlist \
	-v /var/lib/git:/repos:ro \
	-p 127.0.0.1:8888:80/tcp \
	--rm -it cmanley/gitlist /bin/sh

In case of problems, start the container without the --rm option, check your docker logs, and check that the container is running:

	docker logs gitlist
	docker ps

Stop the container using:

	docker stop gitlist

Remove the container (in case you didn't run it with the --rm option) using:

	docker rm gitlist

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

The theme called `default` is the default theme in the original source distribution of GitList.
In this Docker build however, the default theme has been changed to `bootstrap3-wide` which is a 100% wide variant of the `bootstrap3` theme.

Security information
--------------------

* nginx runs as nobody:nobody and forwards requests to php-fpm which executes the GitList code.
* php-fpm runs with uid nobody and with the gid of the GITLIST_GID environment variable if given, else with gid of the host volume.
* It's important to always protect your host's volume by adding the ":ro" attribute to the docker run -v option as in the examples above.
* This image also exposes the URI `/phpinfo.php` , so you may want to deny access to it in your proxy if you think it exposes too much info.
