# vkucukcakar/nginx

NGINX Docker image with automatic configuration file creation and export

* Based on official NGINX Docker image
* Automatic configuration creates well-commented configuration files using environment variables or use configuration files at volume "/configurations"
* Configuration files for "proxy" or "usptream" server roles

## Supported tags

* latest (Alpine based)
* Some version based tags may be available, please see tags section on Docker Hub

## Environment variables supported

* AUTO_CONFIGURE=[enable|disable]
	Enable automatic configuration file creation
	
* SERVER_ROLE=[upstream]*
	Server Role
* CONTAINER_NAME=[example-com-web]
	Current container name
* DOMAIN_NAME=[example.com]
	Current domain name
* PHP_CONTAINER_NAME=[php-container-name]
	PHP-FPM container name

* SERVER_ROLE=[proxy]*
	Server role
* CONTAINER_NAME=[server-proxy]
	Current container name
* CONTAINER_NAME_example.com=[example-com-web]
	Your example-com container name
* VHOSTS=["example.com test.tld mydomain.tld"]
	Virtual hosts separated by space
* VHOST_example.com=["example.com"]
	Variables starting with VHOST_ prefix will be added to VHOSTS (Added for flexibility in Compose)
* CERT_CREATE_example.com=[enable|disable]
	Enable self signed certificate creation for example.com
* CERT_COUNTRY_example.com=[XX]
	Certificate country for example.com
* CERT_STATE_example.com=[ExampleState]
	Certificate state for example.com
* CERT_LOCALITY_example.com=[ExampleLocality]
	Certificate locality for example.com

* DHPARAM_CREATE=[enable|disable]
	Enable dhparam creation (Must be enabled also in /configurations/nginx-example.com.conf) (Should be disabled for development servers since certification creation takes some time)
* DHPARAM_KEYSIZE=[1024|2048]
	Dhparam key size (Even it is a one time process. 2048 is safer but creation takes much longer time.)
	
## Caveats

* Automatic configuration, creates configuration files using the supported environment variables 
  unless they already exist at /configurations directory. These are well-commented configuration files
  that you can edit according to your needs and make them persistent by mounting /configurations directory 
  to a location on host. If you need to re-create them using the environment variables, then you must 
  delete the old ones. This is all by design.
  
* There is a working Docker Compose example project which you can see vkucukcakar/nginx image in action: [lemp-stack-compose](https://github.com/vkucukcakar/lemp-stack-compose )

## Notice

Support for Debian based image has reached it's end-of-life.
Debian related file(s) were moved to "legacy" folder for documentary purposes.
Sorry, but it's not easy for me to maintain both Alpine and Debian based images.

If you really need the Debian based image, please use previous versions up to v1.0.4.
