# GestaoEquipamentos

Banco de dados MySQL para **controle de patrimônio e equipamentos**: o que existe, onde está, em que estado está, quem movimentou e quando. Cada movimentação fica registrada no histórico, gera auditoria e, quando indica um problema, notifica os responsáveis.

Projeto da disciplina **Banco de Dados**, de Engenharia de Software. O modelo foi criado no 1º bimestre e preparado para produção no 2º bimestre, no Trabalho 2, "Meu banco vai para produção".

## Tecnologias

- MySQL 5.7+ (compatível com 8.0)
- InnoDB, com transações e chaves estrangeiras
- phpMyAdmin ou MySQL Workbench para executar o script

## Arquivos

| Arquivo | Descrição |
|---|---|
| `entrega_LEONARDO_NOMEDUPLA.sql` | Script completo: tabelas, dados, views, procedures, triggers, usuário e evento |
| `DER_LEONARDO_NOMEDUPLA.png` | Diagrama entidade-relacionamento do banco |

## Como executar

1. Abra o phpMyAdmin (aba **SQL**) ou o MySQL Workbench, logado como `root`.
2. Execute o arquivo `entrega_LEONARDO_NOMEDUPLA.sql` inteiro.
3. O script é **idempotente**: pode ser executado várias vezes seguidas, sem erro e sem duplicar dados.

> Se o phpMyAdmin reclamar do `DELIMITER`, apague as linhas `Delimiter` e preencha o campo **Delimitador** (abaixo da caixa SQL) com `$$`.
>
> Se já existir uma versão antiga do banco com outra estrutura, rode uma vez `DROP DATABASE IF EXISTS GestaoEquipamentos;` antes do script.

## Modelo de dados

![DER](DER_LEONARDO_NOMEDUPLA.png)

| Tabela | Função |
|---|---|
| `Usuario` | Pessoas do sistema: Administrador, Responsável ou Colaborador |
| `Localizacao` | Locais onde os equipamentos ficam |
| `Categoria` | Tipos de equipamento (Informática, Audiovisual, Rede…) |
| `Objeto` | Os equipamentos, com estado e localização atual |
| `Acao` | Tipos de movimentação (Retirada, Devolução, Transferência…) |
| `Registro` | Histórico de cada movimentação de um objeto |
| `Evidencia` | Arquivos anexados a um registro (fotos, PDFs, vídeos) |
| `Notificacao` | Avisos enviados aos usuários |
| `Auditoria` | Log automático de cadastro e alteração de objetos |
| `Usuario_localizacao` | Associativa N:N: quem é responsável por cada local |
| `Log_rotina` | Log gravado pela rotina automática `ev_rotina` |

## Recursos

### Views de relatório

| View | Pergunta de negócio | Técnica |
|---|---|---|
| `vw_relatorio_join` | Quem é o responsável por cada local e quais locais estão sem responsável? | `LEFT JOIN` |
| `vw_relatorio_grupo` | Quais categorias têm mais de 150 equipamentos com problema? | `GROUP BY` + `HAVING` |
| `vw_relatorio_self` | Quais responsáveis dividem a mesma localização? | `SELF JOIN` |
| `vw_objetos_completos` | Objetos com nome da categoria e do local | `INNER JOIN` |
| `vw_historico_objetos` | Histórico completo de movimentações | `INNER JOIN` + `LEFT JOIN` |
| `vw_objetos_com_problema` | Objetos danificados, em manutenção, desaparecidos ou indisponíveis | `WHERE ... IN` |

### Stored procedures

| Procedure | O que faz |
|---|---|
| `sp_operacao` | Transfere um objeto de local **em transação** (`UPDATE` + `INSERT`, com `ROLLBACK` em caso de erro) |
| `sp_registrar_acao` | Registra uma ação sobre um objeto, validando objeto, usuário, ação e local |
| `sp_historico_objeto` | Histórico de um objeto |
| `sp_ultima_acao_objeto` | Última movimentação de um objeto |
| `sp_objetos_por_local` | Objetos de uma localização |
| `sp_objetos_com_problema` | Lista de objetos com problema |
| `sp_historico_usuario` | Movimentações feitas por um usuário |
| `sp_buscar_objeto` | Busca por nome ou identificação |
| `sp_notificar_problema` | Notifica administradores e responsáveis sobre um problema |

### Triggers

- `trg_objeto_insert` e `trg_objeto_update`: gravam na `Auditoria` todo cadastro e toda alteração de objeto.
- `trg_registro_insert`: atualiza o estado e o local do objeto conforme o registro lançado.
- `trg_registro_problema`: dispara a notificação quando o novo estado indica problema.

### Índices

Os índices são declarados dentro do `CREATE TABLE` (o MySQL 5.7 não tem `CREATE INDEX IF NOT EXISTS`). O principal é o `idx_objeto_nome`, em `Objeto.Nome`, que é usado na busca de equipamentos. Também há índices em `Usuario.Nome`, `Usuario.Setor`, `Objeto.Estado`, `Registro.Data_registro`, `Notificacao.Lida` e `Auditoria.Data_cadastro`.

### Povoamento

Mais **10.000 objetos** gerados por SQL, com `INSERT IGNORE ... SELECT` e `CROSS JOIN` de tabelas de dígitos. A distribuição de categoria, local e estado usa `CRC32`, então é sempre a mesma. A coluna `Identificacao` é `UNIQUE`, então reexecutar o script não duplica dados.

### Segurança

Há um usuário da aplicação com **permissão mínima**:

```sql
Grant Select, Insert, Update On GestaoEquipamentos.* To 'app_leonardo_nomedupla'@'localhost';
```

Ele não tem `DELETE`, `DROP` nem permissão global. Troque a senha do script antes de usar em um ambiente real.

### Rotina automática

O evento `ev_rotina` roda **a cada 1 minuto** e grava na `Log_rotina` o total de objetos, os objetos com problema e as notificações não lidas. O script já liga o agendador com `SET GLOBAL event_scheduler = ON`.

## Testando

```sql
-- Quantidade de objetos (10.012)
Select Count(*) From Objeto;

-- Relatórios
Select * From vw_relatorio_join;
Select * From vw_relatorio_grupo;
Select * From vw_relatorio_self;

-- Transação com ROLLBACK: o usuário 999 não existe, então nada é gravado
Select Id_localizacao From Objeto Where Id_objeto = 2;
Call sp_operacao(2, 999, 3, 'Teste de rollback');   -- erro de FK
Select Id_localizacao From Objeto Where Id_objeto = 2;  -- continua igual

-- Transação com COMMIT
Call sp_operacao(2, 3, 3, 'Remanejamento para a Sala 101');
Call sp_ultima_acao_objeto(2);

-- Rotina automática
Select * From Log_rotina Order By Id_log Desc;

-- Busca usando o índice
Call sp_buscar_objeto('Projetor');
```

## Autores

- **Leonardo Gomes Ferreira** — [@LeonardoGomesFerreira](https://github.com/LeonardoGomesFerreira)
- **NOMEDUPLA**

Professor: Winsley Bonifácio da Silva
