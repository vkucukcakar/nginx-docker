# Changelog

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
