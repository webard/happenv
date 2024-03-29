#!/bin/bash
### Set Language
TEXTDOMAIN=virtualhost

### Set default parameters
action=$1
domain=$2
phpVersion=$3
userAs=$4
rootDir=$5
owner=$(who am i | awk '{print $1}')
sitesEnable='/etc/nginx/sites-enabled/'
sitesAvailable='/etc/nginx/sites-available/'
userDir='/var/www/'
phpFpmPoolsEnabled="/etc/php/$phpVersion/fpm/pool.d/"
phpFpmPoolsAvailable="/etc/php/$phpVersion/fpm/pools-available/"

MY_DIR=$(dirname $(readlink -f $0))


createHostname() {
    ### Add domain in /etc/hosts
		if ! echo "127.0.0.1	$domain" >> /etc/hosts
			then
				echo $"ERROR: Not able write $domain in /etc/hosts"
				exit;
		else
				echo -e $"Host $domain added to /etc/hosts file \n"
		fi

        ### Add domain in /mnt/c/Windows/System32/drivers/etc/hosts (Windows Subsytem for Linux)
		if [ -e /mnt/c/Windows/System32/drivers/etc/hosts ]
		then
			if ! echo -e "\r127.0.0.1       $domain" >> /mnt/c/Windows/System32/drivers/etc/hosts
			then
				echo $"ERROR: Not able to write in /mnt/c/Windows/System32/drivers/etc/hosts (Hint: Try running Bash as administrator)"
			else
				echo -e $"Host added to /mnt/c/Windows/System32/drivers/etc/hosts file \n"
			fi
		fi
}

deleteHostname() {
    ### Delete domain in /etc/hosts
			newhost=${domain//./\\.}
			sed -i "/$newhost/d" /etc/hosts

			### Delete domain in /mnt/c/Windows/System32/drivers/etc/hosts (Windows Subsytem for Linux)
			if [ -e /mnt/c/Windows/System32/drivers/etc/hosts ]
			then
				newhost=${domain//./\\.}
				sed -i "/$newhost/d" /mnt/c/Windows/System32/drivers/etc/hosts
			fi
}

if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user. Use sudo"
		exit 1;
fi

if [ "$action" != 'create' ] && [ "$action" != 'remove' ] && [ "$action" != 'enable' ] && [ "$action" != 'disable' ]
	then
		echo $"You need to prompt for action (create or delete) -- Lower-case only"
		exit 1;
fi

while [ "$domain" == "" ]
do
	echo -e $"Please provide domain name (fqdn)."
	read domain
done

if [ "$rootDir" == "" ]; then
	rootDir=${domain}
fi

### if root dir starts with '/', don't use /var/www as default starting point
if [[ "$rootDir" =~ ^/ ]]; then
	userDir=''
fi

rootDir=$userDir$rootDir

if [ "$action" == 'create' ]
	then

	while [ "$userAs" == "" ]
		do
			echo -e $"Please provide username for website. User will be created in system."
			read userAs
	done

	while [ "$phpVersion" == "" ]
		do
			echo -e $"Please provide PHP version, eg. 7.2"
			read phpVersion
	done
		### check if domain already exists
		if [ -e $sitesAvailable$domain ]; then
			echo -e $"This domain already exists.\nPlease Try Another one"
			exit;
		fi

		### create user
		adduser --disabled-password --gecos "" $userAs

		### check if directory exists or not
		if ! [ -d $userDir$rootDir ]; then
			### create the directory
			mkdir $userDir$rootDir
			mkdir $userDir$rootDir/tmp
			### give permission to root dir
			chmod -R 700 $userDir$rootDir
			### write test file in the new domain dir
			if ! echo "<?php echo phpinfo(); ?>" > $userDir$rootDir/phpinfo.php
				then
					echo $"[ERROR] Not able to write in $userDir/$rootDir/. Please check permissions."
					exit;
			else
					### remove file
                    rm $userDir$rootDir/phpinfo.php
					echo $"[OK] $userDir$rootDir is writable"
			fi
			###TODO: should test if PHP is available
		fi

		### create virtual host rules file
		if ! echo "server {
			listen   80;
			root $userDir$rootDir/current/public;
			index index.php;
			server_name $domain;
			

			# serve static files directly
			location ~* \.(jpg|jpeg|gif|css|png|js|ico|html)$ {
				access_log off;
				expires max;
			}

			# removes trailing slashes (prevents SEO duplicate content issues)
			if (!-d \$request_filename) {
				rewrite ^/(.+)/\$ /\$1 permanent;
			}

			# unless the request is for a valid file (image, js, css, etc.), send to bootstrap
			if (!-e \$request_filename) {
				rewrite ^/(.*)\$ /index.php?/\$1 last;
				break;
			}

			# removes trailing 'index' from all controllers
			if (\$request_uri ~* index/?\$) {
				rewrite ^/(.*)/index/?\$ /\$1 permanent;
			}

			location / {
                try_files \$uri \$uri/ /index.php;
        	}

			# catch all
			error_page 404 /index.php;

			location ~ \.php$ {
				fastcgi_split_path_info ^(.+\.php)(/.+)\$;
				fastcgi_pass unix:/run/php/php$phpVersion-fpm.$domain.sock;
				fastcgi_index index.php;
				include fastcgi_params;
				fastcgi_param SCRIPT_FILENAME \$document_root/\$fastcgi_script_name;
			}

			location ~ /\.ht {
				deny all;
			}

		}" > $sitesAvailable$domain
		then
			echo -e $"[ERROR] Cannot create $sitesAvailable$domain file."
			exit;
		else
			echo -e $"\nNew Virtual Host Created\n"
		fi

         ### create PHP-FPM pool file
		if ! echo "[$userAs]
user = $userAs
group = www-data
listen = /run/php/php7.2-fpm.$domain.sock
listen.owner = nginx
listen.group = nginx
pm = dynamic
pm.max_children = 10
pm.start_servers = 4
pm.min_spare_servers = 2
pm.max_spare_servers = 4
pm.max_requests = 500
request_terminate_timeout = 600

env[HOSTNAME] = \$hostName
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /var/www/$domain/tmp
env[TMPDIR] = /var/www/$domain/tmp
env[TEMP] = /var/www/$domain/tmp
security.limit_extensions = .php
php_admin_value [cgi.fix_pathinfo] = 1
php_admin_value[post_max_size] = 1G
php_admin_value[upload_max_filesize] = 1G
php_admin_value[memory_limit] = 384M
php_admin_value[open_basedir] = /var/www/$domain:/tmp
php_admin_value[display_errors] = Off

        " > $phpFpmPoolsAvailable$domain.conf
		then
			echo -e $"There is an ERROR create PHP-FPM Pool $domain.conf. Probably PHP-FPM is not installed."
			exit;
		else
			echo -e $"\nNew PHP-FPM Pool Created\n"
		fi


		createHostname $domain

		#if [ "$owner" == "" ]; then
		#	chown -R $(whoami):www-data $userDir$rootDir
		#else
			#chown -R $owner:www-data $userDir$rootDir
		#fi

		chown -R $userAs:$userAs $userDir$rootDir

		### enable website
		ln -s $sitesAvailable$domain $sitesEnable$domain

		### enable PHP FPM pool
		ln -s $phpFpmPoolsAvailable$domain.conf $phpFpmPoolsEnabled$domain.conf

		### restart Nginx
		service nginx restart
		service php$phpVersion-fpm restart

		### show the finished message
		echo -e $"Complete! \nYou now have a new Virtual Host \nYour new host is: http://$domain \nAnd its located at $userDir$rootDir"
		exit;
elif [ "$action" == 'enable' ]; then
		### check whether domain already exists
		if ! [ -e $sitesAvailable$domain ]; then
			echo -e $"This domain dont exists.\nPlease Try Another one"
			exit;
		else
			createHostname $domain
			
			### enable website
			ln -s $sitesAvailable$domain $sitesEnable$domain

			### enable PHP FPM pool
			ln -s $phpFpmPoolsAvailable$domain.conf $phpFpmPoolsEnabled$domain.conf

			### restart Nginx
			service nginx reload
            service php7.2-fpm reload
		fi

		### show the finished message
		echo -e $"Complete!\nYou just enabled Virtual Host $domain"
		exit 0;
elif [ "$action" == 'disable' ] ; then
		### check whether domain already exists
		if ! [ -e $sitesAvailable$domain ]; then
			echo -e $"This domain dont exists.\nPlease Try Another one"
			exit;
		else
			deleteHostname $domain

			### disable website
			rm $sitesEnable$domain

			### disable PHP FPM pool
			rm $phpFpmPoolsEnabled$domain.conf

			### restart Nginx
			service nginx reload
            service php7.2-fpm reload
		fi

		### show the finished message
		echo -e $"Complete!\nYou just disabled Virtual Host $domain"
		exit 0;
elif [ "$action" == 'remove' ]; then
		### check whether domain already exists
		if ! [ -e $sitesAvailable$domain ]; then
			echo -e $"This domain dont exists.\nPlease Try Another one"
			exit;
		else
			deleteHostname $domain

			### disable website
			rm $sitesEnable$domain
            rm $phpFpmPoolsEnabled$domain.conf
            deluser $userAs

			### restart Nginx
			service nginx reload
            service php7.2-fpm reload

			### Delete virtual host rules files
			rm $sitesAvailable$domain
			rm $phpFpmPoolsAvailable$domain.conf
		fi

		### check if directory exists or not
		if [ -d $userDir$rootDir ]; then
			

				rm -rf $userDir$rootDir
				echo -e $"Directory deleted"
			
		else
			echo -e $"Host directory not found. Ignored"
		fi

		### show the finished message
		echo -e $"Complete!\nYou just removed Virtual Host $domain"
		exit 0;
fi