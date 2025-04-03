#!/bin/bash

HOST="ip"
PORT="porta"
DB_NAME="exemplo"
USER="user"
PASSWORD="senha"

CLIENT_NAME="exemplo"
SAMBA_PATH="ip/diretorio"
SAMBA_USER="user"
SAMBA_PASSWORD="senha"

BACKUP_DIR="/exemplo/exemplo"
LOG_DIR="/exemplo/backup/logs"

BACKUP_PATH="$BACKUP_DIR/$CLIENT_NAME"
LOG_PATH="$LOG_DIR/$CLIENT_NAME"
mkdir -p "$BACKUP_PATH"
mkdir -p "$LOG_PATH"

LOG_FILE="$LOG_PATH/${DB_NAME}_$(date +%Y%m%d_%H%M%S).log"
BACKUP_FILE="$BACKUP_PATH/${DB_NAME}_$(date +%Y%m%d_%H%M%S).backup"

export PGPASSWORD=$PASSWORD

echo "Realizando o backup do banco de dados..."
pg_dump -h $HOST -p $PORT -U $USER -d $DB_NAME -Fc > "$BACKUP_FILE" 2> "$LOG_FILE"

if [[ $? -ne 0 ]]; then
    echo "Erro ao realizar o backup do banco de dados! Verifique o log em: $LOG_FILE"
    exit 1
fi

echo "Sincronizando com o servidor..."
export RSYNC_PASSWORD=$SAMBA_PASSWORD
rsync -av --progress "$BACKUP_PATH/" "$SAMBA_USER@$SAMBA_PATH/$CLIENT_NAME/"
if [[ $? -ne 0 ]]; then
    echo "Erro ao sincronizar com o servidor!"
    exit 1
fi
echo "Sincronização concluída com sucesso!"

unset PGPASSWORD
unset RSYNC_PASSWORD

echo "Processo concluído."
