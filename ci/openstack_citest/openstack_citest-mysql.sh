#!/bin/sh
# It's best practice to remove anonymous users from the database.  If
# an anonymous user exists, then it matches first for connections and
# other connections from that host will not work.
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h localhost -e "
    DELETE FROM mysql.user WHERE User='';
    FLUSH PRIVILEGES;
    CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PW';
    GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'%' WITH GRANT OPTION;"
# Now create our database.
mysql -u"$DB_USER" -p"$DB_PW" -h localhost -e "
    SET default_storage_engine=MYISAM;
    DROP DATABASE IF EXISTS $TEST_DB;
    CREATE DATABASE $TEST_DB CHARACTER SET utf8;"
