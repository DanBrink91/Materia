#!/bin/bash
set -e

echo "remember you can limit your test groups with './run_tests.sh --group=Lti'"

# If you have an issue with a broken widget package breaking this script, run the following to clear the widgets
# docker-compose -f docker-compose.yml -f docker-compose.admin.yml run --rm phpfpm bash -c -e 'rm /var/www/html/fuel/packages/materia/vendor/widget/test/*'

# use env/args to determine which docker-compose files to load
source run_dc.sh

DCTEST="$DC -f docker-compose.test.yml"

$DC -f docker-compose.test.yml run --rm phpfpm /wait-for-it.sh mysql:3306 -t 20 -- env COMPOSER_ALLOW_SUPERUSER=1 composer run testci -- "$@"
