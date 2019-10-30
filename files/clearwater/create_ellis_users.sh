#!/bin/bash

for i in {2010000000..2010029999}; do 
    mysql -D ellis -e "insert into users values(\"id_$i\", \"7kkzTyGW\", \"$i@example.com\", \"$i@example.com\", NULL, NULL, NULL)"
done
