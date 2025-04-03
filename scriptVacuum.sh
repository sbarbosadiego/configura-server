#!/bin/bash

# Variável para a senha do postgres
export PGPASSWORD=senha

/usr/pgsql-14/bin/psql -U postgres -p porta -d base -c "VACUUM ANALYZE"