#!/usr/bin/env bash

DEFAULT_DB_FILE=data/sqlite6.db
while
  read -p "Enter database file path [$DEFAULT_DB_FILE]: " DB_FILE
  [ -z "$DB_FILE" ] && DB_FILE="$DEFAULT_DB_FILE"
  [ ! -e "$DB_FILE" -o ! -r "$DB_FILE" ]
do
  <"$DB_FILE" # this prints an error message
done

run_sql() {
  echo "$1" | sqlite3 "$DB_FILE" || exit $?
}

while
  read -p "Enter username: " USERNAME
  [ -z "$USERNAME" -o "$(run_sql "select username from users where username = '$USERNAME';")" != "$USERNAME" ]
do
  if [ -n "$USERNAME" ]; then
    echo "User not found: $USERNAME"
    echo "Existing users:"
    run_sql "select username from users;" | sed 's/^/  /'
  fi
done

while
  while
    read -s -p "Enter new password for $USERNAME: " PASSWORD
    echo
    [ -z "$PASSWORD" ];
  do
    echo "Password cannot be empty"
  done

  while
    read -s -p "Re-enter new password for $USERNAME: " PASSWORD2
    echo
    [ -z "$PASSWORD2" ];
  do
    echo "Password cannot be empty"
  done

  [ "$PASSWORD" != "$PASSWORD2" ]
do
  echo "Passwords do not match, try again"
done

SALT=$(run_sql "select value from salt;")

HASH=$(echo -n "$PASSWORD$SALT" | sha1sum - | cut -c1-40)
[ ${#HASH} -ne 40 ] && exit 1

run_sql "update users set password = '$HASH' where username = '$USERNAME';"
echo "Password for $USERNAME successfully updated"
exit 0
