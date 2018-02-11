#!/bin/bash

###
# vkucukcakar/nginx
# NGINX Docker image with automatic configuration file creation and export
# Copyright (c) 2017 Volkan Kucukcakar
#
# This file is part of vkucukcakar/nginx.
#
# vkucukcakar/nginx is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# vkucukcakar/nginx is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This copyright notice and license must be retained in all files and derivative works.
###

# Create configuration files using environment variables if auto configuration is enabled and configuration files are not found
# Symbolic links are then created from known configuration files at /configurations directory to their original locations
if [ "$AUTO_CONFIGURE" == "enable" ]; then
	# Limit environment variables to substitute
	SHELL_FORMAT='$CONTAINER_NAME,$DOMAIN_NAME,$PHP_CONTAINER_NAME,$_UPSTREAM_CONTAINER_NAME,$_UPSTREAM_DOMAIN_NAME'

	# Check if the required environment variables are set and create configuration files
	if [ "$SERVER_ROLE" == "upstream" ]; then
		echo "AUTO_CONFIGURE enabled, starting auto configuration with upstream as SERVER_ROLE."
		# Check if the required environment variables are set and create configuration files
		if [ "$CONTAINER_NAME" ] && [ "$DOMAIN_NAME" ] && [ "$PHP_CONTAINER_NAME" ]; then
			# Check if /configurations/nginx.conf configuration file already exists/mounted
			if [ ! -f /configurations/nginx.conf ]; then
				echo "Creating configuration file '/configurations/nginx.conf' from template."
				# Substitute the values of environment variables to create the real configuration file from template
				envsubst "$SHELL_FORMAT" < /templates/upstream/nginx.conf > /configurations/nginx.conf
			else
				echo "Configuration file '/configurations/nginx.conf' already exists, skipping file creation. You can edit the file according to your needs."
			fi

			# Check if /configurations/nginx-default.conf configuration file already exists/mounted
			if [ ! -f /configurations/nginx-default.conf ]; then
				echo "Creating configuration file '/configurations/nginx-default.conf' from template."
				# Substitute the values of environment variables to create the real configuration file from template
				envsubst "$SHELL_FORMAT" < /templates/upstream/nginx-default.conf > /configurations/nginx-default.conf
			else
				echo "Configuration file '/configurations/nginx-default.conf' already exists, skipping file creation. You can edit the file according to your needs."
			fi
		else
			echo "Error: One or more environment variable required for AUTO_CONFIGURE with upstream as SERVER_ROLE is not set, please check: CONTAINER_NAME, DOMAIN_NAME, PHP_CONTAINER_NAME"
			exit 1
		fi
	elif [ "$SERVER_ROLE" == "proxy" ]; then
		echo "AUTO_CONFIGURE enabled, starting auto configuration with proxy as SERVER_ROLE."
		# Check if the required environment variables are set and create configuration files
		if [ "$CONTAINER_NAME" ] && [ "$VHOSTS" ] && [[ $VHOSTS =~ ^([[:alnum:]\._-]+[[:blank:]]*)+$ ]]; then
			# Check if /configurations/nginx.conf configuration file already exists/mounted
			if [ ! -f /configurations/nginx.conf ]; then
				echo "Creating configuration file '/configurations/nginx.conf' from template."
				# Substitute the values of environment variables to create the real configuration file from template
				envsubst "$SHELL_FORMAT" < /templates/proxy/nginx.conf > /configurations/nginx.conf
			else
				echo "Configuration file '/configurations/nginx.conf' already exists, skipping file creation. You can edit the file according to your needs."
			fi

			# Parse VHOSTS. VHOSTS contains domain names separated by space. (e.g.: "example.com test.tld anything.tld")
			for _UPSTREAM_DOMAIN_NAME in $VHOSTS; do
				# export new variables to use with envsubst later (required here!)
				export _UPSTREAM_DOMAIN_NAME
				# Get environment variable CONTAINER_NAME_example.com
				export _UPSTREAM_CONTAINER_NAME=$(awk "BEGIN {print ENVIRON[\"CONTAINER_NAME_${_UPSTREAM_DOMAIN_NAME}\"]}")
				echo "Creating configuration files for upstream domain name ${_UPSTREAM_DOMAIN_NAME} and upstream container name ${_UPSTREAM_CONTAINER_NAME}"
				# Check if /configurations/nginx-${_UPSTREAM_DOMAIN_NAME}.conf configuration file already exists/mounted
				if [ ! -f /configurations/nginx-${_UPSTREAM_DOMAIN_NAME}.conf ]; then
					echo "Creating configuration file '/configurations/nginx-${_UPSTREAM_DOMAIN_NAME}.conf' from template."
					# Substitute the values of environment variables to create the real configuration file from template
					envsubst "$SHELL_FORMAT" < /templates/proxy/nginx-example.com.conf > /configurations/nginx-${_UPSTREAM_DOMAIN_NAME}.conf
				else
					echo "Configuration file '/configurations/nginx-${_UPSTREAM_DOMAIN_NAME}.conf' already exists, skipping file creation. You can edit the file according to your needs."
				fi

				# Create symbolic links for upstream configuration file(s)
				# Create symbolic link for configuration file '/configurations/nginx-${_UPSTREAM_DOMAIN_NAME}.conf' to real location
				if [ ! -f /etc/nginx/conf.d/nginx-${_UPSTREAM_DOMAIN_NAME}.conf ]; then
					echo "Creating symbolic link for configuration file '/configurations/nginx-${_UPSTREAM_DOMAIN_NAME}.conf' to '/etc/nginx/conf.d/nginx-${_UPSTREAM_DOMAIN_NAME}.conf'"
					ln -s /configurations/nginx-${_UPSTREAM_DOMAIN_NAME}.conf /etc/nginx/conf.d/nginx-${_UPSTREAM_DOMAIN_NAME}.conf
				elif [ ! -L /etc/nginx/conf.d/nginx-${_UPSTREAM_DOMAIN_NAME}.conf ]; then
					echo "Warning: The file '/etc/nginx/conf.d/nginx-${_UPSTREAM_DOMAIN_NAME}.conf' is not a symbolic link created by AUTO_CONFIGURE. You can delete the file if you want to create symbolic link on next startup."
				fi

				# Create self signed server ssl certificates for domains
				# Get environment variable "CERT_CREATE_example.com"
				CERT_CREATE=$(awk "BEGIN {print ENVIRON[\"CERT_CREATE_${_UPSTREAM_DOMAIN_NAME}\"]}")
				if [ "$CERT_CREATE" == "enable" ]; then
					# Self signed ssl certificate creation parameters. (Get environment variable "CERT_*_example.com")
					CERT_COUNTRY=$(awk "BEGIN {print ENVIRON[\"CERT_COUNTRY_${_UPSTREAM_DOMAIN_NAME}\"]}")
					[[ $CERT_COUNTRY ]] || CERT_COUNTRY="US"
					CERT_STATE=$(awk "BEGIN {print ENVIRON[\"CERT_STATE_${_UPSTREAM_DOMAIN_NAME}\"]}")
					[[ $CERT_STATE ]] || CERT_STATE="ExampleState"
					CERT_LOCALITY=$(awk "BEGIN {print ENVIRON[\"CERT_LOCALITY_${_UPSTREAM_DOMAIN_NAME}\"]}")
					[[ $CERT_LOCALITY ]] || CERT_LOCALITY="ExampleLocality"
					# Create self signed server ssl certificates
					if [ ! -f /configurations/${_UPSTREAM_DOMAIN_NAME}.crt ] || [ ! -f /etc/nginx/ssl/${_UPSTREAM_DOMAIN_NAME}.key ]; then
						echo "Creating self signed certificates for ${_UPSTREAM_DOMAIN_NAME}"
						openssl req -new -x509 -days 7300 -nodes \
							-out /configurations/${_UPSTREAM_DOMAIN_NAME}.crt \
							-keyout /configurations/${_UPSTREAM_DOMAIN_NAME}.key \
							-subj "/C=${CERT_COUNTRY}/ST=${CERT_STATE}/L=${CERT_LOCALITY}/O=${_UPSTREAM_DOMAIN_NAME}/CN=${_UPSTREAM_DOMAIN_NAME}"
					fi
				else
					echo "Self signed ssl certificate creation disabled."
				fi

				# Create symbolic links for created or mounted server ssl certificates
				# Create symbolic link for server ssl certificates '/configurations/${_UPSTREAM_DOMAIN_NAME}.crt' and '/configurations/${_UPSTREAM_DOMAIN_NAME}.key' to real location
				if [ -f /configurations/${_UPSTREAM_DOMAIN_NAME}.key ]; then
					if [ ! -f /etc/nginx/ssl/${_UPSTREAM_DOMAIN_NAME}.key ]; then
						echo "Creating symbolic link for server ssl certificate file '/configurations/${_UPSTREAM_DOMAIN_NAME}.crt' to '/etc/nginx/ssl/${_UPSTREAM_DOMAIN_NAME}.crt'"
						ln -s /configurations/${_UPSTREAM_DOMAIN_NAME}.crt /etc/nginx/ssl/${_UPSTREAM_DOMAIN_NAME}.crt
						echo "Creating symbolic link for server ssl certificate file '/configurations/${_UPSTREAM_DOMAIN_NAME}.key' to '/etc/nginx/ssl/${_UPSTREAM_DOMAIN_NAME}.key'"
						ln -s /configurations/${_UPSTREAM_DOMAIN_NAME}.key /etc/nginx/ssl/${_UPSTREAM_DOMAIN_NAME}.key
					elif [ ! -L /etc/nginx/ssl/${_UPSTREAM_DOMAIN_NAME}.key ]; then
						echo "Warning: The file '/etc/nginx/ssl/${_UPSTREAM_DOMAIN_NAME}.key' is not a symbolic link created by AUTO_CONFIGURE. You can delete the file if you want to create symbolic link on next startup."
					fi
				fi

				# Create dhparam (Still may not be enabled)
				if [ "$DHPARAM_CREATE" == "enable" ]; then
					echo "Creating dhparam with keysize of ${DHPARAM_KEYSIZE}."
					[[ $DHPARAM_KEYSIZE ]] || DHPARAM_KEYSIZE="2048"
					# Create DHE key
					openssl dhparam -out /configurations/dhparam.pem ${DHPARAM_KEYSIZE}
				else
					echo "dhparam creation disabled."
				fi

				# Create symbolic link for created or mounted dhparam
				if [ -f /configurations/dhparam.pem ]; then
					if [ ! -f /etc/nginx/ssl/dhparam.pem ]; then
						echo "Creating symbolic link for dhparam file '/configurations/dhparam.pem' to '/etc/nginx/ssl/dhparam.pem'"
						ln -s /configurations/dhparam.pem /etc/nginx/ssl/dhparam.pem
					elif [ ! -L /etc/nginx/ssl/dhparam.pem ]; then
						echo "Warning: The file '/etc/nginx/ssl/dhparam.pem' is not a symbolic link created by AUTO_CONFIGURE. You can delete the file if you want to create symbolic link on next startup."
					fi
				fi
			done

			# Create self signed ssl certificate for default server
			if [ "$CERT_CREATE_default_server" == "enable" ]; then
				if [ ! -f /configurations/default_server.crt ] || [ ! -f /etc/nginx/ssl/default_server.key ]; then
					[[ $CERT_COUNTRY_default_server ]] || CERT_COUNTRY_default_server="US"
					[[ $CERT_STATE_default_server ]] || CERT_STATE_default_server="ExampleState"
					[[ $CERT_LOCALITY_default_server ]] || CERT_LOCALITY_default_server="ExampleLocality"
					echo "Creating self signed certificates for default_server"
					openssl req -new -x509 -days 7300 -nodes \
						-out /configurations/default_server.crt \
						-keyout /configurations/default_server.key \
						-subj "/C=${CERT_COUNTRY_default_server}/ST=${CERT_STATE_default_server}/L=${CERT_LOCALITY_default_server}/O=default_server/CN=default_server"
				fi
			fi

			# Create symbolic links for created or mounted default_server ssl certificates
			if [ -f /configurations/default_server.key ]; then
				if [ ! -f /etc/nginx/ssl/default_server.key ]; then
					echo "Creating symbolic link for server ssl certificate file '/configurations/default_server.crt' to '/etc/nginx/ssl/default_server.crt'"
					ln -s /configurations/default_server.crt /etc/nginx/ssl/default_server.crt
					echo "Creating symbolic link for server ssl certificate file '/configurations/default_server.key' to '/etc/nginx/ssl/default_server.key'"
					ln -s /configurations/default_server.key /etc/nginx/ssl/default_server.key
				elif [ ! -L /etc/nginx/ssl/default_server.key ]; then
					echo "Warning: The file '/etc/nginx/ssl/default_server.key' is not a symbolic link created by AUTO_CONFIGURE. You can delete the file if you want to create symbolic link on next startup."
				fi
			fi

		else
			echo "Error: One or more environment variable required for AUTO_CONFIGURE with proxy as SERVER_ROLE is not set, please check: CONTAINER_NAME, VHOSTS. VHOSTS contains domain names separated by space. (e.g.: 'example.com test.tld anything.tld')"
			exit 1
		fi
	else
		echo "Error: Incorrect SERVER_ROLE environment variable. Supported  values are 'upstream' and 'proxy'."
		exit 1
	fi

	# Create symbolic links for common configuration files
	# Create symbolic link for configuration file '/configurations/nginx.conf' to real location
	if [ ! -f /etc/nginx/nginx.conf ]; then
		echo "Creating symbolic link for configuration file '/configurations/nginx.conf' to '/etc/nginx/nginx.conf'"
		ln -s /configurations/nginx.conf /etc/nginx/nginx.conf
	elif [ ! -L /etc/nginx/nginx.conf ]; then
		echo "Warning: The file '/etc/nginx/nginx.conf' is not a symbolic link created by AUTO_CONFIGURE. You can delete the file if you want to create symbolic link on next startup."
	fi

	# Create symbolic link for configuration file '/configurations/nginx-default.conf' to real location
	if [ -f /configurations/nginx-default.conf ]; then
		if [ ! -f /etc/nginx/conf.d/nginx-default.conf ]; then
			echo "Creating symbolic link for configuration file '/configurations/nginx-default.conf' to '/etc/nginx/conf.d/nginx-default.conf'"
			ln -s /configurations/nginx-default.conf /etc/nginx/conf.d/nginx-default.conf
		elif [ ! -L /etc/nginx/conf.d/nginx-default.conf ]; then
			echo "Warning: The file '/etc/nginx/conf.d/nginx-default.conf' is not a symbolic link created by AUTO_CONFIGURE. You can delete the file if you want to create symbolic link on next startup."
		fi
	fi
	echo "AUTO_CONFIGURE completed."
else
	echo "AUTO_CONFIGURE disabled."
fi

# Continue with default cmd
echo "Executing nginx default cmd: $@"
exec "$@"

