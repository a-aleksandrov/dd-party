#!/usr/bin/env bash

set -e
path=$(dirname "$0")
true=`which true`
source ${path}/common.sh

echo "Installing site...";
sqlfile=${base}/build/ref/${SITE_CODE}.sql
gzipped_sqlfile=${sqlfile}.gz

if [ -e "$gzipped_sqlfile" ]; then
  echo "...from reference database."
  ${drush} sql-drop -y
  gunzip -c "$gzipped_sqlfile" | ${drush} sqlc
elif [ -e "${sqlfile}" ]; then
  echo "...from reference database."
  ${drush} sql-drop -y
  ${drush} sqlc < ${sqlfile}
elif [ -e "$drupal_root/profiles/contrib/config_installer" ]; then
  echo "...from existing config with config installer profile.";
  ${drush} sql-drop --yes
  ${drush} si config_installer --yes \
    --account-name=admin \
    --account-pass=admin \
    --site-name=hcpelv \
    --db-url=mysql://root:rootpasswd@${SITE_CODE}db/drupal \
    --notify
else
  echo "...from scratch, with Drupal minimal profile.";
  #${drush} si ${DRUPAL_PROFILE} --yes \
    #--account-name=${DRUPAL_USER} \
    #--account-pass=${DRUPAL_PASS} \
    #--site-name=${DRUPAL_SITE_NAME} \
    #--db-url=${DRUPAL_DBURL} \
    #--db-su=${MYSQL_USER} \
    #--db-su-pw=${MYSQL_PASSWORD}
  ${drush} sql-drop --yes
  ${drush} si minimal --yes \
    --account-name=admin \
    --account-pass=admin \
    --site-name=hcpelv \
    --db-url=mysql://root:rootpasswd@${SITE_CODE}db/drupal \
    --notify

  if [[ -e "$base/config/drupal/sync/system.site.yml" ]]; then
    # Without this, our import would fail in update.sh. See https://github.com/drush-ops/drush/pull/1635
    site_uuid="$(grep "uuid: " "$base/config/drupal/sync/system.site.yml" | sed "s/uuid: //")"
    ${drush} cset system.site uuid ${site_uuid} -y
  fi
fi
source ${path}/update.sh
