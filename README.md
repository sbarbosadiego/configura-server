# Script Configuração de Servidor – VR Software

## 📄 Descrição

Este script foi desenvolvido com o objetivo de padronizar a configuração de servidores de banco de dados PostgreSQL em nuvem, especialmente em ambientes onde foram identificadas falhas recorrentes e ausência de boas práticas. Dentre os principais problemas observados, destacam-se:

- Ausência de tuning adequado no PostgreSQL;
- Falta de padronização nas ferramentas de manutenção utilizadas;
- Instalação de versões antigas do PostgreSQL, sem qualquer verificação da versão;
- Implantação do PostgreSQL em distribuições Linux com suporte próximo do fim ou já encerrado;
- Não verificação da distribuição utilizada, o que resultava em incompatibilidades;
- Instalação do banco de dados em partições padrão (como /var/lib/pgsql) ou com pouco espaço disponível, dificultando a manutenção e aumentando o risco de falhas;
- Ausência de scripts automatizados para backup diário e verificação de integridade dos bancos de dados;
- Criação manual e inconsistente das roles e usuários necessários para o funcionamento do ERP.
- O projeto também inclui um **manual de implantação**, elaborado para **facilitar a aplicação do script** e auxiliar outras unidades da **VR Software** durante o processo de migração de servidores para a **nuvem (Cloud)**.

Além da automação e padronização, este projeto resultou também na criação de um processo implantação de servidores cloud na VR Software, que antes era inexistente, gerando falhas constantes, configurações incompletas e retrabalho frequente.

## ⚙️ Funcionalidades

- **Verificação da distribuição Linux** (compatível com RHEL 8, Rocky Linux e AlmaLinux);
- **Validação da partição de instalação** do PostgreSQL;
- **Instalação automática** do PostgreSQL na versão definida;
- **Configuração do diretório PGDATA** em local personalizado;
- **Tuning automático** do PostgreSQL com parâmetros de desempenho e log;
- **Alteração do método de autenticação** (`pg_hba.conf`) para facilitar o acesso inicial;
- **Instalação de utilitários essenciais** para administração do servidor;
- **Criação de diretório `/util` com scripts auxiliares** para:
  - Backup diário;
  - Reindexação e Vacuum;
  - Verificação de integridade com `pg_amcheck` + notificação por e-mail;
- **Criação automática de roles e usuários padrão** utilizados pelo ERP;
- **Criação da extensão `amcheck`** no banco de dados principal.

## 📁 Estrutura Esperada

- Diretório de instalação do banco: `/diretorio`
- Banco principal: `base`
- Porta personalizada (deve ser definida no script): `"porta"`
- Scripts utilitários salvos em `/util`

## 🧾 Requisitos

- Distribuição baseada em RHEL 8 (ex: Rocky Linux 8, AlmaLinux 8)
- Permissões de root (sudo)
- Conectividade com a internet para baixar pacotes e scripts

## 📚 Manual de Implantação

Este script conta com um manual técnico desenvolvido por mim, que serve de guia para a implantação completa do ambiente. No entanto, o manual não pode ser disponibilizado publicamente, pois passou a fazer parte do material interno da empresa, além de conter informações sensíveis sobre a configuração do restante do ERP.

## ⚠️ Aviso

Este script foi adaptado para **fins de estudo e treinamento**. Algumas medidas de segurança (como uso de `trust` no `pg_hba.conf` e senhas genéricas) **devem ser ajustadas antes de uso em ambientes de produção real**.

