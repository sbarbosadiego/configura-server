#!/bin/bash

## VARIAVEIS
PG_VERSAO="14"
DB_NOME="base"
DB_PORTA="porta"
DB_USUARIO="postgres"
DIR_INSTALACAO="/diretorio"
##

# Verifica distribuicao linux utilizada
validar_Distro() {    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" =~ ^(rocky|almalinux|rhel)$ && "$VERSION_ID" =~ ^8 ]]; then
            echo "Distro compatível: $PRETTY_NAME"
        else
            echo "Distro incompatível com o script"
            exit 1
        fi
    else
        echo "Não foi possível determinar a distro. O arquivo /etc/os-release não foi encontrado."
        exit 1
    fi
}

# Verifica se existe a particao $DIR_INSTALACAO
verificar_particao() {
    if mount | grep -q " on $DIR_INSTALACAO "; then
        echo "Partição $DIR_INSTALACAO encontrada."
    else
        echo "Partição $DIR_INSTALACAO não encontrada."
        exit 1
    fi
}

# Instalacao Postgres
instalar_Postgres() {
    dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
    dnf -qy module disable postgresql
    dnf install postgresql$PG_VERSAO-server -y
    dnf install postgresql$PG_VERSAO-contrib -y
}

# Configura o diretorio que vai ser salvo o banco de dados
configurar_Postgres() {
    local service_file="/usr/lib/systemd/system/postgresql-${PG_VERSAO}.service"
    if [ -f "$service_file" ]; then
        # Modifica apenas a linha abaixo de "# Location of database directory"
        sed -i '/# Location of database directory/{n;s|.*|Environment=PGDATA=$DIR_INSTALACAO/pgsql/14/data/|}' "$service_file"
        echo "Linha de PGDATA no arquivo $service_file foi atualizada com sucesso."
    else
        echo "Arquivo $service_file não encontrado. Verifique se o PostgreSQL $PG_VERSAO está instalado."
        exit 1
    fi
    
    sudo /usr/pgsql-${PG_VERSAO}/bin/postgresql-${PG_VERSAO}-setup initdb
    sudo systemctl enable postgresql-${PG_VERSAO}
    sudo systemctl start postgresql-${PG_VERSAO}
}

# Realiza o tuning do banco de dados
tuning_Postgres() {
    local postgre_conf="$DIR_INSTALACAO/pgsql/$PG_VERSAO/data/postgresql.conf"

    # Verifica se o arquivo existe
    if [ -f "$postgre_conf" ]; then
        # Executa os comandos como usuário postgres
        sudo -u postgres bash -c "
            sed -i \"s|^#\\?datestyle = .*|datestyle = 'iso, mdy'|\" \"$postgre_conf\"
            sed -i \"s|^#\\?standard_conforming_strings = .*|standard_conforming_strings = off|\" \"$postgre_conf\"
            sed -i \"s|^#\\?listen_addresses = .*|listen_addresses = '*'|\" \"$postgre_conf\"
            sed -i \"s|^#\\?port = .*|port = $DB_PORTA|\" \"$postgre_conf\"
            sed -i \"s|^#\\?tcp_keepalives_idle = .*|tcp_keepalives_idle = 10|\" \"$postgre_conf\"
            sed -i \"s|^#\\?tcp_keepalives_interval = .*|tcp_keepalives_interval = 10|\" \"$postgre_conf\"
            sed -i \"s|^#\\?tcp_keepalives_count = .*|tcp_keepalives_count = 10|\" \"$postgre_conf\"
            sed -i \"s|^#\\?log_destination = .*|log_destination = 'stderr'|\" \"$postgre_conf\"
            sed -i \"s|^#\\?logging_collector = .*|logging_collector = off|\" \"$postgre_conf\"
            sed -i \"s|^#\\?log_directory = .*|log_directory = 'log'|\" \"$postgre_conf\"
            sed -i \"s|^#\\?log_rotation_age = .*|log_rotation_age = 1d|\" \"$postgre_conf\"
            sed -i \"s|^#\\?log_filename = .*|log_filename = 'postgresql-%a.log'|\" \"$postgre_conf\"
            sed -i \"s|^#\\?log_rotation_size = .*|log_rotation_size = 20MB|\" \"$postgre_conf\"
            sed -i \"s|^#\\?log_truncate_on_rotation = .*|log_truncate_on_rotation = on|\" \"$postgre_conf\"
            sed -i \"s|^#\\?enable_seqscan = .*|enable_seqscan = on|\" \"$postgre_conf\"
            sed -i \"s|^#\\?enable_partitionwise_join = .*|enable_partitionwise_join = on|\" \"$postgre_conf\"
            sed -i \"s|^#\\?enable_partitionwise_aggregate = .*|enable_partitionwise_aggregate = on|\" \"$postgre_conf\"
            sed -i \"s|^#\\?password_encryption = .*|password_encryption = md5|\" \"$postgre_conf\"
            sed -i \"s|^#\\?default_statistics_target = .*|default_statistics_target = 1000|\" \"$postgre_conf\"
        "
        echo "Configurações de tuning aplicadas com sucesso no arquivo $postgre_conf."
    else
        echo "Arquivo $postgre_conf não encontrado. Verifique se o PostgreSQL foi inicializado corretamente."
        exit 1
    fi
}

# Instala utilitarios para manutencao do servidor
instalar_Utilitarios() {
    dnf install epel-release -y
    dnf install htop -y
    dnf install sendemail -y
    dnf install nmtui -y
    dnf install vim -y
    dnf install wget -y
    dnf install tmux -y
    dnf install smartmontools -y
    dnf update -y
}

configurar_Autenticacao() {
    local config_file="$DIR_INSTALACAO/pgsql/$PG_VERSAO/data/pg_hba.conf"

    # Verifica se o arquivo existe
    if [ ! -f "$config_file" ]; then
        echo "Arquivo $config_file não encontrado. Verifique se o PostgreSQL foi inicializado corretamente."
        exit 1
    fi

    # Define os números das linhas que precisam ser alteradas
    local local_auth_line=85  # Linha onde está a configuração "local"
    local host_auth_line=87   # Linha onde está a configuração "host"

    # Substitui o método de autenticação pela palavra "trust" independentemente do conteúdo anterior
    sudo -u postgres sed -i "${local_auth_line}s/\(.*\)[[:space:]]\+\(md5\|peer\|scram-sha-256\|password\|reject\|ident\|trust\)[[:space:]]*$/\1 trust/" "$config_file"
    sudo -u postgres sed -i "${host_auth_line}s/\(.*\)[[:space:]]\+\(md5\|peer\|scram-sha-256\|password\|reject\|ident\|trust\)[[:space:]]*$/\1 trust/" "$config_file"

    sudo systemctl restart postgresql-${PG_VERSAO}

    echo "Configuração de autenticação alterada para 'trust' no arquivo $config_file."
}

# Configura diretorio com scripts utilizados na crontab
configurar_Scripts(){
    cd /
    mkdir util
    chmod 777 -R util/
    cd util
    wget -c https://raw.githubusercontent.com/sbarbosadiego/config-server/refs/heads/main/scriptPgAmCheck.sh
    wget -c https://raw.githubusercontent.com/sbarbosadiego/config-server/refs/heads/main/scriptDump.sh
    wget -c https://raw.githubusercontent.com/sbarbosadiego/config-server/refs/heads/main/scriptVacuum.sh
    wget -c https://raw.githubusercontent.com/sbarbosadiego/config-server/refs/heads/main/scriptReindex.sh    
    wget -c https://raw.githubusercontent.com/sbarbosadiego/config-server/refs/heads/main/scriptVacuumReindex.sh
    wget -c https://raw.githubusercontent.com/sbarbosadiego/config-server/refs/heads/main/scriptBackup.sh
    chmod +x scriptDump.sh scriptPgAmCheck.sh scriptVacuum.sh scriptReindex.sh scriptVacuumReindex.sh scriptBackup.sh
}

criar_Base() {
    # Verifica se o PostgreSQL está rodando e se o banco já existe
    if ! sudo -u postgres psql -h 127.0.0.1 -p "$DB_PORTA" -lqt | cut -d \| -f 1 | grep -qw "$DB_NOME"; then
        # Cria o banco de dados
        sudo -u postgres psql -h 127.0.0.1 -p "$DB_PORTA" -c "CREATE DATABASE $DB_NOME;"
        echo "Banco de dados '$DB_NOME' criado com sucesso."
    else
        echo "O banco de dados '$DB_NOME' já existe."
    fi

    # Criação das roles e usuários
    sudo -u postgres psql -h 127.0.0.1 -p "$DB_PORTA" <<EOF
        ALTER USER postgres WITH ENCRYPTED PASSWORD 'senha';
        CREATE ROLE pgsql LOGIN SUPERUSER INHERIT CREATEDB CREATEROLE REPLICATION;
        ALTER USER pgsql WITH ENCRYPTED PASSWORD 'senha';
        CREATE ROLE teste_do_teste LOGIN SUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
        CREATE USER teste_user;
        ALTER USER teste_user WITH ENCRYPTED PASSWORD 'senha';
        CREATE USER monitor WITH PASSWORD 'senha' INHERIT;
        GRANT pg_monitor TO monitor;
EOF

    echo "Roles e usuários criados com sucesso no PostgreSQL."

    # Criando a extensão amcheck no banco
    sudo -u postgres psql -h 127.0.0.1 -p "$DB_PORTA" -d "$DB_NOME" -c "CREATE EXTENSION IF NOT EXISTS amcheck;"

    echo "Extensão amcheck criada com sucesso no banco '$DB_NOME'."
}

validar_Distro
verificar_particao
instalar_Utilitarios
instalar_Postgres
configurar_Postgres
tuning_Postgres
configurar_Autenticacao
configurar_Scripts
criar_Base