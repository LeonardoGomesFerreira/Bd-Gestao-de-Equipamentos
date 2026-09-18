Drop Database If Exists GestaoEquipamentos;
Create Database GestaoEquipamentos Character Set utf8mb4 Collate utf8mb4_unicode_ci;
Use GestaoEquipamentos;
Set Names utf8mb4;

Create Table Usuario (
    Id_usuario Int Not Null Auto_Increment Primary Key,
    Nome Varchar(150) Not Null,
    Email Varchar(150) Not Null Unique,
    Setor Varchar(100) Not Null,
    Tipo Enum('Administrador', 'Responsavel', 'Colaborador') Not Null Default 'Colaborador',
    Status Enum('Ativo', 'Inativo') Not Null Default 'Ativo',
    Data_cadastro DateTime Not Null Default Current_Timestamp
);

Create Table Localizacao (
    Id_localizacao Int Not Null Auto_Increment Primary Key,
    Nome Varchar(150) Not Null,
    Descricao Varchar(300),
    Status Enum('Ativo', 'Inativo') Not Null Default 'Ativo'
);

Create Table Categoria (
    Id_categoria Int Not Null Auto_Increment Primary Key,
    Nome Varchar(100) Not Null Unique,
    Descricao Varchar(300),
    Status Enum('Ativo', 'Inativo') Not Null Default 'Ativo'
);

Create Table Objeto (
    Id_objeto Int Not Null Auto_Increment Primary Key,
    Id_categoria Int Not Null,
    Id_localizacao Int Not Null,
    Nome Varchar(150) Not Null,
    Identificacao Varchar(100) Unique,
    Estado Enum('Normal', 'Em_uso', 'Alterado', 'Danificado', 'Em_manutencao', 'Desaparecido', 'Indisponivel' ) Not Null Default 'Normal',
    Descricao Text,
    Data_cadastro DateTime Not Null Default Current_Timestamp,
    Constraint Fk_objeto_categoria Foreign Key (Id_categoria) References Categoria(Id_categoria),
    Constraint Fk_objeto_localizacao Foreign Key (Id_localizacao) References Localizacao(Id_localizacao)
);

Create Table Acao (
    Id_acao Int Not Null Auto_Increment Primary Key,
    Nome Varchar(100) Not Null Unique,
    Descricao Varchar(300),
    Status Enum('Ativo', 'Inativo') Not Null Default 'Ativo'
);

Create Table Registro (
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
    Constraint Fk_registro_objeto Foreign Key (Id_objeto) References Objeto(Id_objeto),
    Constraint Fk_registro_usuario Foreign Key (Id_usuario) References Usuario(Id_usuario),
    Constraint Fk_registro_acao Foreign Key (Id_acao) References Acao(Id_acao),
    Constraint Fk_registro_local_anterior Foreign Key (Id_local_anterior) References Localizacao(Id_localizacao),
    Constraint Fk_registro_local_novo Foreign Key (Id_local_novo) References Localizacao(Id_localizacao)
);

Create Table Evidencia (
    Id_evidencia Int Not Null Auto_Increment Primary Key,
    Id_registro Int Not Null,
    Nome_arquivo Varchar(255) Not Null,
    Tipo_arquivo Varchar(100),
    Caminho_arquivo Varchar(500),
    Data_upload DateTime Not Null Default Current_Timestamp,
    Constraint Fk_evidencia_registro Foreign Key (Id_registro) References Registro(Id_registro) On Delete Cascade
);

Create Table Notificacao (
    Id_notificacao Int Not Null Auto_Increment Primary Key,
    Id_usuario Int Not Null,
    Id_registro Int,
    Titulo Varchar(200) Not Null,
    Mensagem Varchar(500) Not Null,
    Tipo Enum('Informacao', 'Alteracao', 'Problema', 'Alerta') Not Null Default 'Informacao',
    Lida Boolean Not Null Default False,
    Data_notificacao DateTime Not Null Default Current_Timestamp,
    Constraint Fk_notificacao_usuario Foreign Key (Id_usuario) References Usuario(Id_usuario),
    Constraint Fk_notificacao_registro Foreign Key (Id_registro) References Registro(Id_registro)
);

Create Table Auditoria (
    Id_auditoria Int Not Null Auto_Increment Primary Key,
    Id_objeto Int,
    Id_usuario Int,
    Operacao Enum('Insert', 'Update', 'Delete') Not Null,
    Descricao Varchar(1000) Not Null,
    Data_cadastro DateTime Not Null Default Current_Timestamp,
    Constraint Fk_auditoria_objeto Foreign Key (Id_objeto) References Objeto(Id_objeto),
    Constraint Fk_auditoria_usuario Foreign Key (Id_usuario) References Usuario(Id_usuario)
);

Create Index idx_usuario_nome On Usuario(Nome);
Create Index idx_usuario_setor On Usuario(Setor);
Create Index idx_objeto_nome On Objeto(Nome);
Create Index idx_objeto_identificacao On Objeto(Identificacao);
Create Index idx_objeto_localizacao On Objeto(Id_localizacao);
Create Index idx_objeto_estado On Objeto(Estado);
Create Index idx_registro_objeto On Registro(Id_objeto);
Create Index idx_registro_usuario On Registro(Id_usuario);
Create Index idx_registro_data On Registro(Data_registro);
Create Index idx_notificacao_usuario On Notificacao(Id_usuario);
Create Index idx_notificacao_lida On Notificacao(Lida);
Create Index idx_auditoria_data On Auditoria(Data_cadastro);

Create View vw_objetos_completos As
Select
    o.Id_objeto,
    o.Nome,
    o.Identificacao,
    c.Nome As Categoria,
    l.Nome As Localizacao,
    o.Estado,
    o.Descricao,
    o.Data_cadastro
From Objeto o
Inner Join Categoria c On c.Id_categoria = o.Id_categoria
Inner Join Localizacao l On l.Id_localizacao = o.Id_localizacao;

Create View vw_historico_objetos As
Select
    r.Id_registro,
    r.Id_objeto,
    o.Nome As Objeto,
    o.Identificacao,
    u.Nome As Usuario,
    u.Setor,
    a.Nome As Acao,
    la.Nome As Local_anterior,
    ln.Nome As Local_novo,
    r.Estado_anterior,
    r.Estado_novo,
    r.Motivo,
    r.Observacao,
    r.Data_registro
From Registro r
Inner Join Objeto o On o.Id_objeto = r.Id_objeto
Inner Join Usuario u On u.Id_usuario = r.Id_usuario
Inner Join Acao a On a.Id_acao = r.Id_acao
Left Join Localizacao la On la.Id_localizacao = r.Id_local_anterior
Left Join Localizacao ln On ln.Id_localizacao = r.Id_local_novo;

Create View vw_objetos_com_problema As
Select
    o.Id_objeto,
    o.Nome,
    o.Identificacao,
    c.Nome As Categoria,
    l.Nome As Localizacao,
    o.Estado
From Objeto o
Inner Join Categoria c On c.Id_categoria = o.Id_categoria
Inner Join Localizacao l On l.Id_localizacao = o.Id_localizacao
Where o.Estado In ('Danificado', 'Em_manutencao', 'Desaparecido', 'Indisponivel');


Delimiter //
Create Procedure sp_registrar_acao (
    In p_id_objeto Int,
    In p_id_usuario Int,
    In p_id_acao Int,
    In p_id_local_novo Int,
    In p_estado_novo Varchar(50),
    In p_motivo Varchar(500),
    In p_observacao Varchar(500)
)
Begin
    Declare v_local_anterior Int;
    Declare v_estado_anterior Varchar(50);
    Declare v_existe Int Default 0;
    Select Count(*)
    Into v_existe
    From Objeto
    Where Id_objeto = p_id_objeto;
    If v_existe > 0 Then
        Select Count(*)
        Into v_existe
        From Usuario
        Where Id_usuario = p_id_usuario;
        If v_existe > 0 Then
            Select Count(*)
            Into v_existe
            From Acao
            Where Id_acao = p_id_acao
              And Status = 'Ativo';
            If v_existe > 0 Then
                If p_id_local_novo Is Not Null Then
                    Select Count(*)
                    Into v_existe
                    From Localizacao
                    Where Id_localizacao = p_id_local_novo;
                Else
                    Set v_existe = 1;
                End If;
                If v_existe > 0 Then
                    Select
                        Id_localizacao,
                        Estado
                    Into
                        v_local_anterior,
                        v_estado_anterior
                    From Objeto
                    Where Id_objeto = p_id_objeto;
                    Insert Into Registro (
                        Id_objeto,
                        Id_usuario,
                        Id_acao,
                        Id_local_anterior,
                        Id_local_novo,
                        Estado_anterior,
                        Estado_novo,
                        Motivo,
                        Observacao
                    )
                    Values (
                        p_id_objeto,
                        p_id_usuario,
                        p_id_acao,
                        v_local_anterior,
                        p_id_local_novo,
                        v_estado_anterior,
                        p_estado_novo,
                        p_motivo,
                        p_observacao
                    );
                End If;
            End If;
        End If;
    End If;
End//

Create Procedure sp_historico_objeto (
    In p_id_objeto Int
)
Begin
    Select
        Id_registro,
        Id_objeto,
        Objeto,
        Identificacao,
        Usuario,
        Setor,
        Acao,
        Local_anterior,
        Local_novo,
        Estado_anterior,
        Estado_novo,
        Motivo,
        Observacao,
        Data_registro
    From vw_historico_objetos Where Id_objeto = p_id_objeto Order By Data_registro Desc, Id_registro Desc;
End//

Create Procedure sp_ultima_acao_objeto (
    In p_id_objeto Int
)
Begin
    Select
        Objeto,
        Identificacao,
        Usuario As Ultimo_usuario,
        Setor,
        Acao As Ultima_acao,
        Motivo,
        Observacao,
        Data_registro
    From vw_historico_objetos Where Id_objeto = p_id_objeto Order By Data_registro Desc, Id_registro Desc Limit 1;
End//

Create Procedure sp_objetos_por_local (
    In p_id_localizacao Int
)
Begin
    Select
        v.Id_objeto,
        v.Nome,
        v.Identificacao,
        v.Categoria,
        v.Localizacao,
        v.Estado
    From vw_objetos_completos v
    Inner Join Objeto o On o.Id_objeto = v.Id_objeto Where o.Id_localizacao = p_id_localizacao
    Order By v.Nome;
End//

Create Procedure sp_objetos_com_problema ()
Begin
    Select
        Id_objeto,
        Nome,
        Identificacao,
        Categoria,
        Localizacao,
        Estado
    From vw_objetos_com_problema Order By Nome;
End//

Create Procedure sp_historico_usuario (
    In p_id_usuario Int
)
Begin
    Select
        r.Id_registro,
        u.Nome As Usuario,
        o.Nome As Objeto,
        a.Nome As Acao,
        r.Motivo,
        r.Observacao,
        r.Data_registro
    From Registro r
    Inner Join Usuario u On u.Id_usuario = r.Id_usuario
    Inner Join Objeto o On o.Id_objeto = r.Id_objeto
    Inner Join Acao a On a.Id_acao = r.Id_acao
    Where r.Id_usuario = p_id_usuario
    Order By r.Data_registro Desc, r.Id_registro Desc;
End//

Create Procedure sp_buscar_objeto (
    In p_nome Varchar(150)
)
Begin
    Select
        Id_objeto,
        Nome,
        Identificacao,
        Categoria,
        Localizacao,
        Estado,
        Descricao
    From vw_objetos_completos
    Where Nome Like Concat('%', p_nome, '%') Or Identificacao Like Concat('%', p_nome, '%')
    Order By Nome;
End//

Create Procedure sp_notificar_problema (
    In p_id_registro Int
)
Begin
    Declare v_id_objeto Int;
    Declare v_nome_objeto Varchar(150);
    Declare v_estado_novo Varchar(50);
    Declare v_existe Int Default 0;
    Select Count(*)
    Into v_existe
    From Registro
    Where Id_registro = p_id_registro;
    If v_existe = 0 Then
        Signal Sqlstate '45000'
            Set Message_Text = 'Registro informado nao existe.';
    End If;
    Select
        Id_objeto,
        Objeto,
        Estado_novo
    Into
        v_id_objeto,
        v_nome_objeto,
        v_estado_novo
    From vw_historico_objetos
    Where Id_registro = p_id_registro;
    If v_estado_novo In ('Danificado', 'Em_manutencao', 'Desaparecido', 'Indisponivel') Then
        Insert Into Notificacao (
            Id_usuario,
            Id_registro,
            Titulo,
            Mensagem,
            Tipo
        )
        Select
            u.Id_usuario,
            p_id_registro,
            'Problema identificado',
            Concat(
                'O objeto "',
                v_nome_objeto,
                '" de ID ',
                v_id_objeto,
                ' foi registrado como ',
                v_estado_novo,
                '.'
            ),
            'Problema'
        From Usuario u
        Where u.Status = 'Ativo'
          And u.Tipo In ('Administrador', 'Responsavel');
    End If;
End//
Delimiter ;

Delimiter //
Create Trigger trg_objeto_insert
After Insert On Objeto
For Each Row
Begin
    Insert Into Auditoria (
        Id_objeto,
        Operacao,
        Descricao
    )
    Values (
        New.Id_objeto,
        'Insert',
        Concat(
            'Objeto cadastrado: ',
            New.Nome,
            ' | Identificacao: ',
            Coalesce(
                New.Identificacao,
                'Nao informada'
            )
        )
    );
End//

Create Trigger trg_objeto_update
After Update On Objeto
For Each Row
Begin
    Insert Into Auditoria (
        Id_objeto,
        Operacao,
        Descricao
    )
    Values (
        New.Id_objeto,
        'Update',
        Concat(
            'Objeto alterado | Estado: ',
            Old.Estado,
            ' -> ',
            New.Estado,
            ' | Localizacao: ',
            Old.Id_localizacao,
            ' -> ',
            New.Id_localizacao
        )
    );
End//

Create Trigger trg_registro_insert
After Insert On Registro
For Each Row
Begin
    Update Objeto
    Set
        Estado = Coalesce(
            New.Estado_novo,
            Estado
        ),
        Id_localizacao = Coalesce(
            New.Id_local_novo,
            Id_localizacao
        )
    Where Id_objeto = New.Id_objeto;
End//

Create Trigger trg_registro_problema
After Insert On Registro
For Each Row
Begin
    Call sp_notificar_problema(
        New.Id_registro
    );
End//
Delimiter ;

Select * From vw_objetos_completos;
Select * From vw_historico_objetos;
Select * From vw_objetos_com_problema;
Call sp_historico_objeto(1);
Call sp_ultima_acao_objeto(1);
Call sp_objetos_por_local(1);
Call sp_objetos_com_problema();
Call sp_historico_usuario(1);
Call sp_buscar_objeto('Computador');

Select n.Id_notificacao, u.Nome As Usuario, n.Titulo, n.Mensagem, n.Tipo, n.Lida, n.Data_notificacao From Notificacao n
Inner Join Usuario u On u.Id_usuario = n.Id_usuario Order By n.Data_notificacao Desc;

Select a.Id_auditoria, a.Id_objeto, a.Id_usuario, a.Operacao, a.Descricao, a.Data_cadastro From Auditoria a Order By a.Data_cadastro Desc;