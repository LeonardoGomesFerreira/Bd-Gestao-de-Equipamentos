Create Database If Not Exists GestaoEquipamentos Character Set utf8mb4 Collate utf8mb4_unicode_ci;
Use GestaoEquipamentos;
Set Names utf8mb4;

Create Table If Not Exists Usuario (
    Id_usuario Int Not Null Auto_Increment Primary Key,
    Nome Varchar(150) Not Null,
    Email Varchar(150) Not Null Unique,
    Setor Varchar(100) Not Null,
    Tipo Enum('Administrador', 'Responsavel', 'Colaborador') Not Null Default 'Colaborador',
    Status Enum('Ativo', 'Inativo') Not Null Default 'Ativo',
    Data_cadastro DateTime Not Null Default Current_Timestamp,
    Index idx_usuario_nome (Nome),
    Index idx_usuario_setor (Setor)
) Engine = InnoDB;

Create Table If Not Exists Localizacao (
    Id_localizacao Int Not Null Auto_Increment Primary Key,
    Nome Varchar(150) Not Null,
    Descricao Varchar(300),
    Status Enum('Ativo', 'Inativo') Not Null Default 'Ativo'
) Engine = InnoDB;

Create Table If Not Exists Categoria (
    Id_categoria Int Not Null Auto_Increment Primary Key,
    Nome Varchar(100) Not Null Unique,
    Descricao Varchar(300),
    Status Enum('Ativo', 'Inativo') Not Null Default 'Ativo'
) Engine = InnoDB;

Create Table If Not Exists Objeto (
    Id_objeto Int Not Null Auto_Increment Primary Key,
    Id_categoria Int Not Null,
    Id_localizacao Int Not Null,
    Nome Varchar(150) Not Null,
    Identificacao Varchar(100) Unique,
    Estado Enum('Normal', 'Em_uso', 'Alterado', 'Danificado', 'Em_manutencao', 'Desaparecido', 'Indisponivel') Not Null Default 'Normal',
    Descricao Text,
    Data_cadastro DateTime Not Null Default Current_Timestamp,
    Index idx_objeto_nome (Nome),
    Index idx_objeto_estado (Estado),
    Constraint Fk_objeto_categoria Foreign Key (Id_categoria) References Categoria(Id_categoria),
    Constraint Fk_objeto_localizacao Foreign Key (Id_localizacao) References Localizacao(Id_localizacao)
) Engine = InnoDB;

Create Table If Not Exists Acao (
    Id_acao Int Not Null Auto_Increment Primary Key,
    Nome Varchar(100) Not Null Unique,
    Descricao Varchar(300),
    Status Enum('Ativo', 'Inativo') Not Null Default 'Ativo'
) Engine = InnoDB;

Create Table If Not Exists Registro (
    Id_registro Int Not Null Auto_Increment Primary Key,
    Id_objeto Int Not Null,
    Id_usuario Int Not Null,
    Id_acao Int Not Null,
    Id_local_anterior Int,
    Id_local_novo Int,
    Estado_anterior Varchar(50),
    Estado_novo Varchar(50),
    Motivo Varchar(500),
    Observacao Varchar(500),
    Data_registro DateTime Not Null Default Current_Timestamp,
    Index idx_registro_data (Data_registro),
    Constraint Fk_registro_objeto Foreign Key (Id_objeto) References Objeto(Id_objeto),
    Constraint Fk_registro_usuario Foreign Key (Id_usuario) References Usuario(Id_usuario),
    Constraint Fk_registro_acao Foreign Key (Id_acao) References Acao(Id_acao),
    Constraint Fk_registro_local_anterior Foreign Key (Id_local_anterior) References Localizacao(Id_localizacao),
    Constraint Fk_registro_local_novo Foreign Key (Id_local_novo) References Localizacao(Id_localizacao)
) Engine = InnoDB;

Create Table If Not Exists Evidencia (
    Id_evidencia Int Not Null Auto_Increment Primary Key,
    Id_registro Int Not Null,
    Nome_arquivo Varchar(255) Not Null,
    Tipo_arquivo Varchar(100),
    Caminho_arquivo Varchar(500),
    Data_upload DateTime Not Null Default Current_Timestamp,
    Constraint Fk_evidencia_registro Foreign Key (Id_registro) References Registro(Id_registro) On Delete Cascade
) Engine = InnoDB;

Create Table If Not Exists Notificacao (
    Id_notificacao Int Not Null Auto_Increment Primary Key,
    Id_usuario Int Not Null,
    Id_registro Int,
    Titulo Varchar(200) Not Null,
    Mensagem Varchar(500) Not Null,
    Tipo Enum('Informacao', 'Alteracao', 'Problema', 'Alerta') Not Null Default 'Informacao',
    Lida Boolean Not Null Default False,
    Data_notificacao DateTime Not Null Default Current_Timestamp,
    Index idx_notificacao_lida (Lida),
    Constraint Fk_notificacao_usuario Foreign Key (Id_usuario) References Usuario(Id_usuario),
    Constraint Fk_notificacao_registro Foreign Key (Id_registro) References Registro(Id_registro)
) Engine = InnoDB;

Create Table If Not Exists Auditoria (
    Id_auditoria Int Not Null Auto_Increment Primary Key,
    Id_objeto Int,
    Id_usuario Int,
    Operacao Enum('Insert', 'Update', 'Delete') Not Null,
    Descricao Varchar(1000) Not Null,
    Data_cadastro DateTime Not Null Default Current_Timestamp,
    Index idx_auditoria_data (Data_cadastro),
    Constraint Fk_auditoria_objeto Foreign Key (Id_objeto) References Objeto(Id_objeto),
    Constraint Fk_auditoria_usuario Foreign Key (Id_usuario) References Usuario(Id_usuario)
) Engine = InnoDB;

Create Table If Not Exists Usuario_localizacao (
    Id_usuario Int Not Null,
    Id_localizacao Int Not Null,
    Data_inicio Date Not Null,
    Primary Key (Id_usuario, Id_localizacao),
    Constraint Fk_usuloc_usuario Foreign Key (Id_usuario) References Usuario(Id_usuario),
    Constraint Fk_usuloc_localizacao Foreign Key (Id_localizacao) References Localizacao(Id_localizacao)
) Engine = InnoDB;

Create Table If Not Exists Log_rotina (
    Id_log Int Not Null Auto_Increment Primary Key,
    Descricao Varchar(200) Not Null,
    Total_objetos Int Not Null,
    Objetos_com_problema Int Not Null,
    Notificacoes_nao_lidas Int Not Null,
    Executado_em DateTime Not Null Default Current_Timestamp,
    Index idx_log_executado (Executado_em)
) Engine = InnoDB;

Drop Procedure If Exists sp_registrar_acao;
Drop Procedure If Exists sp_historico_objeto;
Drop Procedure If Exists sp_ultima_acao_objeto;
Drop Procedure If Exists sp_objetos_por_local;
Drop Procedure If Exists sp_objetos_com_problema;
Drop Procedure If Exists sp_historico_usuario;
Drop Procedure If Exists sp_buscar_objeto;
Drop Procedure If Exists sp_notificar_problema;
Drop Procedure If Exists sp_operacao;

Delimiter $$
Create Procedure sp_registrar_acao (In p_id_objeto Int, In p_id_usuario Int, In p_id_acao Int, In p_id_local_novo Int, In p_estado_novo Varchar(50), In p_motivo Varchar(500), In p_observacao Varchar(500))
Begin
    Declare v_local_anterior Int;
    Declare v_estado_anterior Varchar(50);
    Declare v_existe Int Default 0;
    Select Count(*) Into v_existe From Objeto Where Id_objeto = p_id_objeto;
    If v_existe > 0 Then
        Select Count(*) Into v_existe From Usuario Where Id_usuario = p_id_usuario;
        If v_existe > 0 Then
            Select Count(*) Into v_existe From Acao Where Id_acao = p_id_acao And Status = 'Ativo';
            If v_existe > 0 Then
                If p_id_local_novo Is Not Null Then
                    Select Count(*) Into v_existe From Localizacao Where Id_localizacao = p_id_local_novo;
                Else
                    Set v_existe = 1;
                End If;
                If v_existe > 0 Then
                    Select Id_localizacao, Estado Into v_local_anterior, v_estado_anterior From Objeto Where Id_objeto = p_id_objeto;
                    Insert Into Registro (Id_objeto, Id_usuario, Id_acao, Id_local_anterior, Id_local_novo, Estado_anterior, Estado_novo, Motivo, Observacao)
                    Values (p_id_objeto, p_id_usuario, p_id_acao, v_local_anterior, p_id_local_novo, v_estado_anterior, p_estado_novo, p_motivo, p_observacao);
                End If;
            End If;
        End If;
    End If;
End$$

Create Procedure sp_historico_objeto (In p_id_objeto Int)
Begin
    Select Id_registro, Id_objeto, Objeto, Identificacao, Usuario, Setor, Acao, Local_anterior, Local_novo, Estado_anterior, Estado_novo, Motivo, Observacao, Data_registro
    From vw_historico_objetos Where Id_objeto = p_id_objeto Order By Data_registro Desc, Id_registro Desc;
End$$

Create Procedure sp_ultima_acao_objeto (In p_id_objeto Int)
Begin
    Select Objeto, Identificacao, Usuario As Ultimo_usuario, Setor, Acao As Ultima_acao, Motivo, Observacao, Data_registro
    From vw_historico_objetos Where Id_objeto = p_id_objeto Order By Data_registro Desc, Id_registro Desc Limit 1;
End$$

Create Procedure sp_objetos_por_local (In p_id_localizacao Int)
Begin
    Select v.Id_objeto, v.Nome, v.Identificacao, v.Categoria, v.Localizacao, v.Estado
    From vw_objetos_completos v Inner Join Objeto o On o.Id_objeto = v.Id_objeto
    Where o.Id_localizacao = p_id_localizacao Order By v.Nome;
End$$

Create Procedure sp_objetos_com_problema ()
Begin
    Select Id_objeto, Nome, Identificacao, Categoria, Localizacao, Estado From vw_objetos_com_problema Order By Nome;
End$$

Create Procedure sp_historico_usuario (In p_id_usuario Int)
Begin
    Select r.Id_registro, u.Nome As Usuario, o.Nome As Objeto, a.Nome As Acao, r.Motivo, r.Observacao, r.Data_registro
    From Registro r
    Inner Join Usuario u On u.Id_usuario = r.Id_usuario
    Inner Join Objeto o On o.Id_objeto = r.Id_objeto
    Inner Join Acao a On a.Id_acao = r.Id_acao
    Where r.Id_usuario = p_id_usuario Order By r.Data_registro Desc, r.Id_registro Desc;
End$$

Create Procedure sp_buscar_objeto (In p_nome Varchar(150))
Begin
    Select Id_objeto, Nome, Identificacao, Categoria, Localizacao, Estado, Descricao
    From vw_objetos_completos
    Where Nome Like Concat('%', p_nome, '%') Or Identificacao Like Concat('%', p_nome, '%') Order By Nome;
End$$

Create Procedure sp_notificar_problema (In p_id_registro Int)
Begin
    Declare v_id_objeto Int;
    Declare v_nome_objeto Varchar(150);
    Declare v_estado_novo Varchar(50);
    Declare v_existe Int Default 0;
    Select Count(*) Into v_existe From Registro Where Id_registro = p_id_registro;
    If v_existe = 0 Then
        Signal Sqlstate '45000' Set Message_Text = 'Registro informado nao existe.';
    End If;
    Select r.Id_objeto, o.Nome, r.Estado_novo Into v_id_objeto, v_nome_objeto, v_estado_novo
    From Registro r Inner Join Objeto o On o.Id_objeto = r.Id_objeto Where r.Id_registro = p_id_registro;
    If v_estado_novo In ('Danificado', 'Em_manutencao', 'Desaparecido', 'Indisponivel') Then
        Insert Into Notificacao (Id_usuario, Id_registro, Titulo, Mensagem, Tipo)
        Select u.Id_usuario, p_id_registro, 'Problema identificado', Concat('O objeto "', v_nome_objeto, '" de ID ', v_id_objeto, ' foi registrado como ', v_estado_novo, '.'), 'Problema'
        From Usuario u Where u.Status = 'Ativo' And u.Tipo In ('Administrador', 'Responsavel');
    End If;
End$$

Create Procedure sp_operacao (In p_id_objeto Int, In p_id_usuario Int, In p_id_local_novo Int, In p_motivo Varchar(500))
Begin
    Declare v_local_anterior Int Default Null;
    Declare v_estado_atual Varchar(50) Default Null;
    Declare v_id_acao Int Default Null;
    Declare Exit Handler For Sqlexception
    Begin
        Rollback;
        Resignal;
    End;
    Start Transaction;
        Select Id_localizacao, Estado Into v_local_anterior, v_estado_atual From Objeto Where Id_objeto = p_id_objeto For Update;
        If v_local_anterior Is Null Then
            Signal Sqlstate '45000' Set Message_Text = 'Objeto informado nao existe.';
        End If;
        If v_local_anterior = p_id_local_novo Then
            Signal Sqlstate '45000' Set Message_Text = 'O objeto ja esta nesta localizacao.';
        End If;
        Select Id_acao Into v_id_acao From Acao Where Nome = 'Transferencia' And Status = 'Ativo';
        Update Objeto Set Id_localizacao = p_id_local_novo Where Id_objeto = p_id_objeto;
        Insert Into Registro (Id_objeto, Id_usuario, Id_acao, Id_local_anterior, Id_local_novo, Estado_anterior, Estado_novo, Motivo, Observacao)
        Values (p_id_objeto, p_id_usuario, v_id_acao, v_local_anterior, p_id_local_novo, v_estado_atual, Null, p_motivo, 'Transferencia feita pela sp_operacao');
    Commit;
End$$
Delimiter ;

Drop Trigger If Exists trg_objeto_insert;
Drop Trigger If Exists trg_objeto_update;
Drop Trigger If Exists trg_registro_insert;
Drop Trigger If Exists trg_registro_problema;

Delimiter $$
Create Trigger trg_objeto_insert After Insert On Objeto For Each Row
Begin
    Insert Into Auditoria (Id_objeto, Operacao, Descricao)
    Values (New.Id_objeto, 'Insert', Concat('Objeto cadastrado: ', New.Nome, ' | Identificacao: ', Coalesce(New.Identificacao, 'Nao informada')));
End$$

Create Trigger trg_objeto_update After Update On Objeto For Each Row
Begin
    Insert Into Auditoria (Id_objeto, Operacao, Descricao)
    Values (New.Id_objeto, 'Update', Concat('Objeto alterado | Estado: ', Old.Estado, ' -> ', New.Estado, ' | Localizacao: ', Old.Id_localizacao, ' -> ', New.Id_localizacao));
End$$

Create Trigger trg_registro_insert After Insert On Registro For Each Row
Begin
    Update Objeto Set Estado = Coalesce(New.Estado_novo, Estado), Id_localizacao = Coalesce(New.Id_local_novo, Id_localizacao)
    Where Id_objeto = New.Id_objeto And (Estado <> Coalesce(New.Estado_novo, Estado) Or Id_localizacao <> Coalesce(New.Id_local_novo, Id_localizacao));
End$$

Create Trigger trg_registro_problema After Insert On Registro For Each Row
Begin
    Call sp_notificar_problema(New.Id_registro);
End$$
Delimiter ;

Insert Ignore Into Usuario (Id_usuario, Nome, Email, Setor, Tipo, Status) Values
    (1, 'Carlos Mendes', 'carlos.mendes@empresa.com', 'TI', 'Administrador', 'Ativo'),
    (2, 'Fernanda Rocha', 'fernanda.rocha@empresa.com', 'Patrimonio', 'Responsavel', 'Ativo'),
    (3, 'Joao Pereira', 'joao.pereira@empresa.com', 'Laboratorios', 'Responsavel', 'Ativo'),
    (4, 'Mariana Alves', 'mariana.alves@empresa.com', 'Audiovisual', 'Responsavel', 'Ativo'),
    (5, 'Rafael Souza', 'rafael.souza@empresa.com', 'Docentes', 'Colaborador', 'Ativo'),
    (6, 'Beatriz Lima', 'beatriz.lima@empresa.com', 'Secretaria', 'Colaborador', 'Ativo'),
    (7, 'Pedro Santos', 'pedro.santos@empresa.com', 'Manutencao', 'Colaborador', 'Ativo'),
    (8, 'Juliana Costa', 'juliana.costa@empresa.com', 'Docentes', 'Colaborador', 'Inativo');

Insert Ignore Into Localizacao (Id_localizacao, Nome, Descricao, Status) Values
    (1, 'Laboratorio de Informatica 1', 'Bloco A - 1 andar', 'Ativo'),
    (2, 'Laboratorio de Informatica 2', 'Bloco A - 2 andar', 'Ativo'),
    (3, 'Sala 101', 'Bloco B - sala de aula', 'Ativo'),
    (4, 'Sala 102', 'Bloco B - sala de aula', 'Ativo'),
    (5, 'Auditorio', 'Bloco C - eventos', 'Ativo'),
    (6, 'Biblioteca', 'Bloco C - terreo', 'Ativo'),
    (7, 'Almoxarifado', 'Estoque de equipamentos', 'Ativo'),
    (8, 'Oficina de Manutencao', 'Conserto de equipamentos', 'Ativo'),
    (9, 'Sala dos Professores', 'Bloco B - terreo', 'Ativo');

Insert Ignore Into Categoria (Id_categoria, Nome, Descricao) Values
    (1, 'Informatica', 'Computadores e notebooks'),
    (2, 'Perifericos', 'Monitores, teclados e mouses'),
    (3, 'Audiovisual', 'Projetores, caixas de som e microfones'),
    (4, 'Mobiliario', 'Mesas, cadeiras e armarios'),
    (5, 'Impressao', 'Impressoras e scanners'),
    (6, 'Rede', 'Roteadores, switches e access points');

Insert Ignore Into Acao (Id_acao, Nome, Descricao) Values
    (1, 'Retirada', 'Colaborador retirou o objeto para uso'),
    (2, 'Devolucao', 'Objeto devolvido apos o uso'),
    (3, 'Transferencia', 'Objeto mudou de localizacao'),
    (4, 'Envio para manutencao', 'Objeto enviado para conserto'),
    (5, 'Retorno de manutencao', 'Objeto voltou do conserto'),
    (6, 'Registro de problema', 'Problema identificado no objeto'),
    (7, 'Conferencia', 'Conferencia periodica do patrimonio');

Insert Ignore Into Usuario_localizacao (Id_usuario, Id_localizacao, Data_inicio) Values
    (1, 1, '2026-02-01'), (3, 1, '2026-02-01'), (3, 2, '2026-02-01'),
    (1, 5, '2026-03-10'), (4, 5, '2026-02-01'), (4, 3, '2026-02-15'),
    (2, 7, '2026-02-01'), (2, 8, '2026-02-01'), (7, 8, '2026-04-05');

Insert Ignore Into Objeto (Id_objeto, Id_categoria, Id_localizacao, Nome, Identificacao, Estado, Descricao) Values
    (1, 1, 1, 'Computador Dell Optiplex 3080', 'PAT-0001', 'Normal', 'Computador do professor - Lab 1'),
    (2, 1, 1, 'Computador Dell Optiplex 3080', 'PAT-0002', 'Normal', 'Computador aluno 01 - Lab 1'),
    (3, 3, 5, 'Projetor Epson PowerLite', 'PAT-0003', 'Normal', 'Projetor principal do auditorio'),
    (4, 2, 2, 'Monitor LG 24 polegadas', 'PAT-0004', 'Normal', 'Monitor aluno 05 - Lab 2'),
    (5, 5, 7, 'Impressora HP LaserJet Pro', 'PAT-0005', 'Normal', 'Impressora reserva'),
    (6, 1, 3, 'Notebook Lenovo ThinkPad E14', 'PAT-0006', 'Normal', 'Notebook de apoio da sala 101'),
    (7, 6, 2, 'Roteador TP-Link Archer C6', 'PAT-0007', 'Normal', 'Wi-Fi do Lab 2'),
    (8, 4, 9, 'Cadeira giratoria executiva', 'PAT-0008', 'Normal', 'Sala dos professores'),
    (9, 3, 5, 'Caixa de som JBL PartyBox', 'PAT-0009', 'Normal', 'Som do auditorio'),
    (10, 3, 3, 'Projetor BenQ MS560', 'PAT-0010', 'Normal', 'Projetor da sala 101'),
    (11, 1, 6, 'Computador Positivo Master', 'PAT-0011', 'Normal', 'Terminal de consulta da biblioteca'),
    (12, 2, 1, 'Teclado e mouse Logitech', 'PAT-0012', 'Normal', 'Kit do computador do professor');

Insert Ignore Into Registro (Id_registro, Id_objeto, Id_usuario, Id_acao, Id_local_anterior, Id_local_novo, Estado_anterior, Estado_novo, Motivo, Observacao, Data_registro) Values
    (1, 1, 5, 1, Null, Null, 'Normal', 'Em_uso', 'Aula de banco de dados', Null, '2026-09-01 08:00:00'),
    (2, 1, 5, 2, Null, Null, 'Em_uso', 'Normal', 'Fim da aula', 'Devolvido sem problemas', '2026-09-01 11:40:00'),
    (3, 3, 4, 6, Null, Null, 'Normal', 'Danificado', 'Lampada queimada', 'Nao liga apos evento', '2026-09-10 19:30:00'),
    (4, 3, 2, 4, 5, 8, 'Danificado', 'Em_manutencao', 'Troca da lampada', 'Enviado para a oficina', '2026-09-11 09:00:00'),
    (5, 6, 4, 3, 3, 4, 'Normal', Null, 'Sala 102 sem notebook', Null, '2026-09-15 14:00:00'),
    (6, 9, 1, 6, Null, Null, 'Normal', 'Desaparecido', 'Nao encontrado na conferencia', 'Ultimo uso no evento de 12/09', '2026-09-20 10:00:00'),
    (7, 10, 5, 1, Null, Null, 'Normal', 'Em_uso', 'Apresentacao de TCC', Null, '2026-10-02 19:00:00'),
    (8, 5, 6, 6, Null, Null, 'Normal', 'Danificado', 'Atolando papel', 'Precisa de manutencao', '2026-10-05 13:20:00');

Insert Ignore Into Evidencia (Id_evidencia, Id_registro, Nome_arquivo, Tipo_arquivo, Caminho_arquivo) Values
    (1, 3, 'projetor_epson_lampada.jpg', 'image/jpeg', '/evidencias/2026/09/projetor_epson_lampada.jpg'),
    (2, 6, 'conferencia_auditorio.pdf', 'application/pdf', '/evidencias/2026/09/conferencia_auditorio.pdf'),
    (3, 8, 'impressora_hp_atolando.mp4', 'video/mp4', '/evidencias/2026/10/impressora_hp_atolando.mp4');

Insert Ignore Into Objeto (Id_categoria, Id_localizacao, Nome, Identificacao, Estado, Descricao)
Select g.cat, g.loc,
    Concat(Case g.cat When 1 Then 'Notebook' When 2 Then 'Monitor' When 3 Then 'Projetor' When 4 Then 'Cadeira' When 5 Then 'Impressora' Else 'Roteador' End, ' ', Lpad(g.n, 5, '0')),
    Concat('GER-', Lpad(g.n, 5, '0')),
    Case
        When g.r_estado < Case g.cat When 1 Then 6 When 2 Then 4 When 3 Then 18 When 4 Then 3 When 5 Then 15 Else 5 End
            Then Case g.r_tipo When 0 Then 'Danificado' When 1 Then 'Em_manutencao' When 2 Then 'Desaparecido' Else 'Indisponivel' End
        When g.r_estado < 30 Then 'Em_uso'
        When g.r_estado < 33 Then 'Alterado'
        Else 'Normal'
    End,
    'Gerado automaticamente (povoamento M3)'
From (
    Select nums.n, 1 + (Crc32(Concat('cat', nums.n)) % 6) As cat, 1 + (Crc32(Concat('loc', nums.n)) % 9) As loc,
        Crc32(Concat('est', nums.n)) % 100 As r_estado, Crc32(Concat('tip', nums.n)) % 4 As r_tipo
    From (
        Select d1.d + d2.d * 10 + d3.d * 100 + d4.d * 1000 As n
        From (Select 0 As d Union All Select 1 Union All Select 2 Union All Select 3 Union All Select 4 Union All Select 5 Union All Select 6 Union All Select 7 Union All Select 8 Union All Select 9) d1
        Cross Join (Select 0 As d Union All Select 1 Union All Select 2 Union All Select 3 Union All Select 4 Union All Select 5 Union All Select 6 Union All Select 7 Union All Select 8 Union All Select 9) d2
        Cross Join (Select 0 As d Union All Select 1 Union All Select 2 Union All Select 3 Union All Select 4 Union All Select 5 Union All Select 6 Union All Select 7 Union All Select 8 Union All Select 9) d3
        Cross Join (Select 0 As d Union All Select 1 Union All Select 2 Union All Select 3 Union All Select 4 Union All Select 5 Union All Select 6 Union All Select 7 Union All Select 8 Union All Select 9) d4
    ) nums
) g;

Create Or Replace View vw_objetos_completos As
Select o.Id_objeto, o.Nome, o.Identificacao, c.Nome As Categoria, l.Nome As Localizacao, o.Estado, o.Descricao, o.Data_cadastro
From Objeto o
Inner Join Categoria c On c.Id_categoria = o.Id_categoria
Inner Join Localizacao l On l.Id_localizacao = o.Id_localizacao;

Create Or Replace View vw_historico_objetos As
Select r.Id_registro, r.Id_objeto, o.Nome As Objeto, o.Identificacao, u.Nome As Usuario, u.Setor, a.Nome As Acao, la.Nome As Local_anterior, ln.Nome As Local_novo,
    r.Estado_anterior, r.Estado_novo, r.Motivo, r.Observacao, r.Data_registro
From Registro r
Inner Join Objeto o On o.Id_objeto = r.Id_objeto
Inner Join Usuario u On u.Id_usuario = r.Id_usuario
Inner Join Acao a On a.Id_acao = r.Id_acao
Left Join Localizacao la On la.Id_localizacao = r.Id_local_anterior
Left Join Localizacao ln On ln.Id_localizacao = r.Id_local_novo;

Create Or Replace View vw_objetos_com_problema As
Select o.Id_objeto, o.Nome, o.Identificacao, c.Nome As Categoria, l.Nome As Localizacao, o.Estado
From Objeto o
Inner Join Categoria c On c.Id_categoria = o.Id_categoria
Inner Join Localizacao l On l.Id_localizacao = o.Id_localizacao
Where o.Estado In ('Danificado', 'Em_manutencao', 'Desaparecido', 'Indisponivel');

Create Or Replace View vw_relatorio_join As
Select l.Id_localizacao, l.Nome As Localizacao, Coalesce(u.Nome, 'SEM RESPONSAVEL') As Responsavel, u.Setor, ul.Data_inicio As Responsavel_desde
From Localizacao l
Left Join Usuario_localizacao ul On ul.Id_localizacao = l.Id_localizacao
Left Join Usuario u On u.Id_usuario = ul.Id_usuario;

Create Or Replace View vw_relatorio_grupo As
Select c.Id_categoria, c.Nome As Categoria, Count(*) As Total_objetos,
    Sum(o.Estado In ('Danificado', 'Em_manutencao', 'Desaparecido', 'Indisponivel')) As Objetos_com_problema,
    Round(100 * Sum(o.Estado In ('Danificado', 'Em_manutencao', 'Desaparecido', 'Indisponivel')) / Count(*), 1) As Percentual_problema
From Categoria c
Inner Join Objeto o On o.Id_categoria = c.Id_categoria
Group By c.Id_categoria, c.Nome
Having Sum(o.Estado In ('Danificado', 'Em_manutencao', 'Desaparecido', 'Indisponivel')) > 150;

Create Or Replace View vw_relatorio_self As
Select l.Nome As Localizacao, u1.Nome As Responsavel_1, u2.Nome As Responsavel_2
From Usuario_localizacao ul1
Inner Join Usuario_localizacao ul2 On ul2.Id_localizacao = ul1.Id_localizacao And ul1.Id_usuario < ul2.Id_usuario
Inner Join Usuario u1 On u1.Id_usuario = ul1.Id_usuario
Inner Join Usuario u2 On u2.Id_usuario = ul2.Id_usuario
Inner Join Localizacao l On l.Id_localizacao = ul1.Id_localizacao;

Create User If Not Exists 'app_leonardo_nomedupla'@'localhost' Identified By 'Gestao#Equip2026';
Grant Select, Insert, Update On GestaoEquipamentos.* To 'app_leonardo_nomedupla'@'localhost';

Set Global event_scheduler = On;
Drop Event If Exists ev_rotina;
Create Event ev_rotina On Schedule Every 1 Minute Starts Current_Timestamp On Completion Preserve Enable
Do
    Insert Into Log_rotina (Descricao, Total_objetos, Objetos_com_problema, Notificacoes_nao_lidas)
    Select 'Fechamento automatico: contagem do patrimonio', (Select Count(*) From Objeto),
        (Select Count(*) From Objeto Where Estado In ('Danificado', 'Em_manutencao', 'Desaparecido', 'Indisponivel')),
        (Select Count(*) From Notificacao Where Lida = False);

Select 'Objeto' As Tabela, Count(*) As Linhas From Objeto
Union All Select 'Usuario', Count(*) From Usuario
Union All Select 'Localizacao', Count(*) From Localizacao
Union All Select 'Categoria', Count(*) From Categoria
Union All Select 'Usuario_localizacao', Count(*) From Usuario_localizacao
Union All Select 'Registro', Count(*) From Registro
Union All Select 'Notificacao', Count(*) From Notificacao
Union All Select 'Auditoria', Count(*) From Auditoria
Union All Select 'Log_rotina', Count(*) From Log_rotina;
Select * From vw_relatorio_join;
Select * From vw_relatorio_grupo;
Select * From vw_relatorio_self;
Select @@event_scheduler As Event_scheduler;
Select Event_name, Status, Last_executed From information_schema.Events Where Event_schema = 'GestaoEquipamentos';
Select * From Log_rotina Order By Id_log Desc Limit 10;
Call sp_historico_objeto(3);
Call sp_ultima_acao_objeto(1);
Call sp_objetos_com_problema();
Call sp_buscar_objeto('Projetor Epson');
