# Changelog

## v1.3.0

- Added Let's Encrypt support
- Changed template files to serve ACME challenge files for Certbot client's webroot plugin support
- Changed proxy server template structure, added location block configuration include file
- Commented some WordPress specific directives in Nginx configuration templates that deny access to some files like /readme.html, /readme.txt, /license.txt etc.

## v1.2.2

- To increase maximum file upload size, client_max_body_size increased in proxy and upstream configuration file templates

## v1.2.1

- Upgraded Naxsi to 1.1a
- Fixed empty continuation lines in Dockerfile

## v1.2.0

- Dockerfile-alpine renamed as Dockerfile
- alpine tag will not be used on Docker Hub, the image is only Alpine based

## v1.1.0

- Added http2_push_preload to Nginx automatic configuration file creation templates
- Fixed a bug with server_tokens directive in automatic configuration file creation templates
- Fixed an ambiguity about .htpasswd file location in automatic configuration file creation templates
- Extracted php configuration from template upstrem/nginx-default.conf and created a new template upstrem/nginx-php.conf which can be included multiple times at separate blocks
- Upgraded parent image to official Nginx 1.18 stable image
- Moved Debian related files to "legacy" folder for documentary purposes
- Added VHOST_ prefixed environment variable support

## v1.0.4

- Fixed a bug with dhparam creation

## v1.0.3

- Updated configuration templates

## v1.0.2

- Upgraded parent image to Nginx 1.12.2 stable
- Fixed a bug with default server certificate creation in entyrypoint
- Fixed image size reduction

## v1.0.1

- Minor fixes

## v1.0.0

- Initial release
