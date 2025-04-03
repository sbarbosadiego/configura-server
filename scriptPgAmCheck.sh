#!/bin/bash

DB_HOST="ip"
DB_PORT="porta"
DB_USER="user"
DB_NAME="base"
CLIENTE_NOME="loja"
ERROR_LOG="/tmp/pg_amcheck_error.log"
EMAIL="exemplo.gmail.com"
DESTEMAILS=("exemplo.gmail.com" "exemplo.gmail.com")
EMAILPASS="senha"
BIN_POSTGRES="/usr/pgsql-14/bin/"

$BIN_POSTGRES/pg_amcheck -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" &> "$ERROR_LOG"
EXIT_CODE=$?

DESTEMAIL=$(IFS=','; echo "${DESTEMAILS[*]}")

if [ $EXIT_CODE -ne 0 ]; then
    if [ -s "$ERROR_LOG" ]; then
        ERROR_MESSAGE=$(<"$ERROR_LOG")
    else
        ERROR_MESSAGE="Erro desconhecido. O arquivo de log está vazio."
    fi
    
    sendEmail -f "$EMAIL" \
        -t "$DESTEMAIL" \
        -s smtp.gmail.com:587 \
        -u "Alerta: Verificação via pg_amcheck Falhou $CLIENTE_NOME" \
        -m "Prezado,\n\nValidação via pg_amcheck para o banco de dados '$DB_NAME' falhou. Detalhes do erro:\n\n$ERROR_MESSAGE\n\nPor favor, entre em contato com a VR Software para suporte.\n\nAtenciosamente,\nEquipe de Suporte VR Software" \
        -xu "$EMAIL" \
        -xp "$EMAILPASS" \
        -o tls=yes
    
    exit $EXIT_CODE
fi

sendEmail -f "$EMAIL" \
    -t "$DESTEMAIL" \
    -s smtp.gmail.com:587 \
    -u "Relatório: Verificação via pg_amcheck Concluído com Sucesso $CLIENTE_NOME" \
    -m "Prezado Cliente,\n\nValidação via pg_amcheck para o banco de dados '$DB_NAME' foi concluída com sucesso.\n\nAtenciosamente,\nEquipe de Suporte VR Software" \
    -xu "$EMAIL" \
    -xp "$EMAILPASS" \
    -o tls=yes

echo "Comando pg_amcheck executado com sucesso no banco de dados $DB_NAME."
exit 0
