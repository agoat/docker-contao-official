#!/bin/bash
set -e

# version_greater A B returns whether A > B
function version_greater() {
	[[ "$(printf '%s\n' "$@" | sort -s | head -n 1)" != "$1" ]];
}

# return true if specified directory is empty
function directory_empty() {
    [ -n "$(find "$1"/ -prune -empty)" ]
}

function run_as() {
  if [[ $EUID -eq 0 ]]; then
    su www-data -s /bin/bash -c "$1"
  else
    bash -c "$1"
  fi
}

installed_version="0.0.0"
if [ -f /var/www/html/composer.json ]; then
    installed_version=$(run_as "composer show -d /var/www/html" | grep contao/core-bundle | awk '{ print $2 }')
fi
image_version=$(run_as "composer show -d /usr/src/contao-${CONTAO_VERSION}" | grep contao/core-bundle | awk '{ print $2 }')

if version_greater "$installed_version" "$image_version"; then
    echo "Can't start Contao because the version of the installation ($installed_version) is higher than the docker image version ($image_version) and downgrading is not supported. Are you sure you have pulled the newest image version?"
    exit 1
fi

if version_greater "$image_version" "$installed_version"; then
    echo "Updating contao ($installed_version) to ($image_version)."
    if [[ $EUID -eq 0 ]]; then
      rsync_options="-rlDog --chown www-data:root"
    else
      rsync_options="-rlD"
    fi
    rsync $rsync_options --exclude /composer.json --exclude /composer.lock --exclude /files/ --exclude /templates/ --exclude /var/ /usr/src/contao-${CONTAO_VERSION}/ /var/www/html/
	rm -rf /var/www/html/var/cache
	
    for dir in files templates; do
        if [ ! -d /var/www/html/"$dir" ]; then
            run_as "mkdir /var/www/html/${dir}" 
        fi
    done
	
	run_as "composer dump-autoload -o &> /dev/null"
	run_as "php /var/www/html/vendor/bin/contao-console cache:clear > /dev/null"
	run_as "php /var/www/html/vendor/bin/contao-console contao:install > /dev/null"
	run_as "php /var/www/html/vendor/bin/contao-console contao:symlinks > /dev/null"
fi

exec "$@"
