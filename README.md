# wannabe-user
A shell script tailored for containers intended to change UID/GID of the container user before spawning the container process

## Intention

When running containers with mapped host volumes in Docker, every file in this volume belongs to the UID/GID it belongs on the host. This poses a problem for containers not running as root (like web servers), as those processes don't have write permissions for the volumes. That's where wannabe-user.sh steps in. It's intended as an `ENTRYPOINT` script in a Dockerfile to automatically map the container user to the host user

## Functionality
`./wannabe-user.sh -u SOURCE_UID -g SOURCE_GID [-x- NEW_UID -y NEW_GID] [-f OWNERSHIP_PATH]`


`wannabe-user.sh` has two operation modes: **ENV** mode and **OWNERSHIP** mode. Both modes can either be triggered by set environment variables or via commandline arguments. It's possible to set only UID, only GID or both.

### ENV mode
ENV mode needs both variables for an ID set. Thus, setting the UID needs `SOURCE_UID` as well as `NEW_UID`. Similarly setting the GID needs `SOURCE_GID` and `NEW_GID` to be set. Changing both needs all four of these environment variables set.

### OWNERSHIP mode
OWNERSHIP mode only needs the `SOURCE_` variables set as needed. Additionally it expects `OWNERSHIP_PATH` to point to a file whose UID/GID will be applied to the container user. This is intended to automatically map a container user to the IDs of the files on a volume.

## Usage
`wannabe-user.sh` is intended to be run as an [`ENTRYPOINT`](https://docs.docker.com/engine/reference/builder/#entrypoint) script in a Dockerfile after being [`COPY`d](https://docs.docker.com/engine/reference/builder/#copy) or [`ADD`ed](https://docs.docker.com/engine/reference/builder/#add). Simple example, taken from my Dokuwiki container running the official `php:apache` image:
```dockerfile
FROM php:apache
MAINTAINER m3adow

RUN curl http://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz | tar xzvf - --strip 1 \ 
  && apt-get update && apt-get install --auto-remove -y sudo \
  && apt-get clean \
  && rm -r /var/lib/apt/lists/* \
  && chown -R www-data:www-data /var/www/html/??*
COPY ["./wannabe-user.sh", "/usr/local/bin/"]

VOLUME ["/var/www/html/data/pages/", "/var/www/html/data/meta/", "/var/www/html/data/media/", \
  "/var/www/html/data/media_meta/", "/var/www/html/data/attic/", \
  "/var/www/html/data/media_attic/", "/var/www/html/conf/", "/var/www/html/lib/plugins"]

EXPOSE 80 443 
ENTRYPOINT ["/usr/local/bin/wannabe-user.sh", "-u", "33", "-g", "33", "-f", "/var/www/html/conf"]
CMD ["/usr/local/bin/apache2-foreground"]
```

This way the www-user (UID & GID 33) gets the same UID and GID as the directory `/var/www/html/conf` effectively granting the web server write permissions without any hassle.

## Todo

* Implement checking for UID/GID 0 of executing user
* Implement only accepting 0 in variables if some (not yet implemented) force mechanic was enabled
