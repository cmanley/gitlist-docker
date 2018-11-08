FROM alpine:3.8

LABEL Maintainer="Craig Manley https://github.com/cmanley" \
      Description="GitList (an elegant git repository viewer) using nginx, php-fpm 7.2, and Alpine Linux 3.8"

RUN apk update && apk --no-cache add \
	git \
	nginx \
	php7 \
	php7-ctype \
	php7-fpm \
	php7-json \
	php7-mbstring \
	php7-simplexml \
	supervisor


### repository mount point and dummy repository ###
ARG REPOSITORY_ROOT=/repos
ARG REPOSITORY_DUMMY=$REPOSITORY_ROOT/If_you_see_this_then_the_host_volume_was_not_mounted
RUN mkdir -p $REPOSITORY_DUMMY \
	&& cd $REPOSITORY_DUMMY \
	&& git --bare init \
	&& cd -;


### gitlist ####
ARG GITLIST_DOWNLOAD_BASENAME=gitlist-master.tar.gz
ARG GITLIST_DOWNLOAD_URL=https://github.com/cmanley/gitlist-docker/raw/custom-gitlist-build-php72/$GITLIST_DOWNLOAD_BASENAME
ARG GITLIST_DOWNLOAD_SHA256=14c055f506705d808d17f5b66a423ccc16dbf33e26357fed1c8fa61be8c472b0
WORKDIR /var/www
RUN NEED='curl'; \
	DEL='' \
	&& for x in $NEED; do \
		if [ $(apk list "$x" | grep -F [installed] | wc -l) -eq 0 ]; then \
			DEL="$DEL $x" \
			&& echo "Add temporary package $x" \
			&& apk --no-cache add $x; \
		fi; \
	done \
	&& curl -fsSL "$GITLIST_DOWNLOAD_URL" -o "$GITLIST_DOWNLOAD_BASENAME" \
	&& sha256sum $GITLIST_DOWNLOAD_BASENAME \
	&& echo "$GITLIST_DOWNLOAD_SHA256  $GITLIST_DOWNLOAD_BASENAME" | sha256sum -c - \
	&& tar -xf "$GITLIST_DOWNLOAD_BASENAME" \
	&& rm "$GITLIST_DOWNLOAD_BASENAME" \
	&& if [ -n "$DEL" ]; then echo "Delete temporary package(s) $DEL" && apk del $DEL; fi \
	&& mkdir -p gitlist/cache \
	&& chmod a+trwx gitlist/cache;

# Create an alternate bootstrap3 theme called bootstrap3-wide having 100% width instead of a limited set of 'adaptive' widths.
WORKDIR /var/www/gitlist/themes
RUN cp -al bootstrap3 bootstrap3-wide && \
	rm bootstrap3-wide/css/style.css && \
	cp bootstrap3/css/style.css bootstrap3-wide/css/style.css && \
	sed -E -i -e 's/(@media ?\(min-width:[0-9]+px\)\{\.container\{width:[0-9]+px\}\})+/.container{width:100%}/' bootstrap3-wide/css/style.css
WORKDIR /


COPY copy /
EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["gitlist"]