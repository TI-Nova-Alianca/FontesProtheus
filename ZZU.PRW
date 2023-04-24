// Programa...: ZZU
// Autor......: Robert Koch
// Data.......: 10/10/2013
// Descricao..: Tela de manutencao de rotinas x usuarios.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #PalavasChave      #usuarios #grupos_de_usuarios #ZZU #acessos
// #TabelasPrincipais #ZZU
// #Modulos    

// Historico de alteracoes:
// 23/10/2013 - Robert  - Criado tratamento para campos ZZU_EMP e ZZU_FIL.
// 30/10/2013 - Robert  - Funcao ZZUNU passa a aceitar array de rotinas.
// 28/11/2013 - Robert  - Criada função ZZULD.
// 25/06/2014 - Robert  - Envia grupo/rotina para a funcao Sendmail.
// 10/03/2015 - Catia   - incluido usuario CATIA.CARDOSO para poder usar este programa
// 02/07/2015 - Robert  - Funcao ZZUVL passa a aceitar parametro com tipos de acessos.
// 30/09/2015 - Robert  - Selecionada ordem 1 (PswOrder) na funcao ZZULD.
// 05/11/2015 - Robert  - Notifica usuarios somente se estiverem com tipo 2 ou 3 
//                        (antes notificava mesmo estando com tipo 1=libera).
// 04/10/2017 - Robert  - Funcao ZZUNU retorna numero de e-mails enviados.
// 19/10/2017 - Robert  - Funcao ZZULD passa a retornar tambem uma array com os IDs dos usuarios.
// 11/12/2017 - Robert  - Passa a validar usuario atual pelos grupos do configurador.
// 30/07/2019 - Robert  - Grava evento de incl/alt/excl; de cadastro.
// 04/11/2019 - Robert  - Passa a validar campo ZZU_VALID.
// 15/06/2020 - Robert  - Campos ZZU_NOME e ZZU_EMAIL passam a ser 'reais'.
// 19/07/2020 - Robert  - Inseridas tags para catalogacao de fontes
//                      - Campo ZZU_ROTINA migrado para ZZU_GRUPO
//                      - Tratamento para novos campos ZZU_ROTIN e ZZU_MODUL
//                      - Removido tratamento por empresa (campo ZZU_EMP).
// 05/10/2020 - Cláudia - Incluida variavel na função zzuvl para emitir/não emitir a mensagem de aviso.
// 17/01/2021 - Robert  - Eliminadas algumas linhas comentariadas.
// 31/03/2022 - Robert  - Melhoria logs.
// 25/08/2022 - Robert  - Criado tratamento para o campo ZZU_SITUAC.
// 09/09/2022 - Robert  - Funcao ZZULD() passa a retornar tambem uma lista de
//                        usernames para uso nas notificacoes do NaWeb.
// 20/04/2023 - Robert  - Implementada alteracao de validade por usuario (em todos os grupos)
//                      - Melhorada gravacao de eventos (gravar ALIAS e CHAVE, para posterior consulta)
//                      - Criada consulta de eventos relacionados ao grupo.
//

// --------------------------------------------------------------------------
User Function ZZU ()
	local _sFiltrTop  := ""
	local _aRotUser   := {}
	private aRotina   := {}  // Opcoes do menu
	private cCadastro := "Grupos x usuarios"

	if ascan (UsrRetGrp (__cUserId), '000000') == 0
		u_help ("Acesso somente ao grupo 'Administradores'.",, .t.)
		return
	endif

	// Submenu de rotinas 'por usuario'
	aadd (_aRotUser, {"Alterar validade", "processa ({||U_ZZUAU ('AV')})", 0, 4})

	aAdd(aRotina, {"Pesquisar",  "AxPesqui" , 0, 1})
	aAdd(aRotina, {"Visualizar", "U_ZZUA", 0, 2})
	aAdd(aRotina, {"Incluir"  ,  "U_ZZUA", 0, 3})
	aAdd(aRotina, {"Alterar"  ,  "U_ZZUA", 0, 4})
	aAdd(aRotina, {"Excluir"  ,  "U_ZZUE", 0, 5})
	aAdd(aRotina, {"Eventos"  ,  "U_VA_SZNC ('ALIAS_CHAVE', 'ZZU', zzu -> zzu_grupo)", 0, 5})
	aadd(aRotina, {"Operacoes por usuario", _aRotUser, 0,4})
	dbSelectArea ("ZZU")
	dbSetOrder (1)
	mBrowse(,,,,"ZZU",,,,,,,,,,,,,,_sFiltrTop)
return



// --------------------------------------------------------------------------
// Tela de manutencao
user function ZZUA ()
	local   _oEvento   := NIL
	local   _nLinACols := 0
	private _sGrupoZZU := ""
	private _sDescrZZU := ""
	private _sRotinZZU := ''
	private _sModulZZU := ''
	private aHeader    := {}
	private aCols      := {}
	private N          := 1
	private aGets      := {}
	private aTela      := {}

	nOpc := 2
	if inclui .or. altera
		nOpc = 4
	endif

	if inclui
		_sGrupoZZU = CriaVar ("ZZU_GRUPO")
		_sDescrZZU = CriaVar ("ZZU_DESCRI")
		_sRotinZZU = CriaVar ("ZZU_ROTIN")
		_sModulZZU = CriaVar ("ZZU_MODUL")
	else
		_sGrupoZZU = zzu -> ZZU_GRUPO
		_sDescrZZU = zzu -> ZZU_DESCRI
		_sRotinZZU = zzu -> ZZU_ROTIN
		_sModulZZU = zzu -> ZZU_MODUL
	endif

	// Gera aHeader e aCols.
	aHeader := U_GeraHead ("ZZU", .F., {"ZZU_GRUPO", "ZZU_DESCRI", "ZZU_MODUL", "ZZU_ROTIN"})
	if ! inclui
		aCols := U_GeraCols ("ZZU", ;  // Alias
		1, ;  // Indice
		xfilial ("ZZU") + zzu -> ZZU_GRUPO, ;  // Seek inicial
		'xfilial ("ZZU") + zzu -> ZZU_GRUPO == "' + xfilial ("ZZU") + zzu -> ZZU_GRUPO + '"', ;  // While
		aHeader, ;  // Passa aHeader por que posso estar usando MsNewGetDados
		.F.)  // Executa ou nao os gatilhos.
	else
		aCols := {}
		aadd (aCols, aclone (U_LinVazia (aHeader)))
	endif

	// Inicializa campos virtuais
	for _nLinACols = 1 to len (aCols)
		if alltrim (GDFieldGet ("ZZU_USER", _nLinACols)) == "*"
			GDFieldPut ("ZZU_NOME", "TODOS", _nLinACols)
		endif
		GDFieldPut ("ZZU_SITUAC", iif (GDFieldGet ("ZZU_VALID", _nLinACols) >= date (), 'Ativo', 'Vencido'), _nLinACols)
	next
	N := 1

	// Variaveis do cabecalho da tela:
	aC:={}
	aadd (aC, {"_sGrupoZZU", {15, 5},   "Grupo",    "@!", "vazio () .or. existchav ('ZZU')", "", inclui})
	aadd (aC, {"_sDescrZZU", {15, 100}, "Descricao", "@!", "", "", .T.})
	aadd (aC, {"_sModulZZU", {30, 5},   "Modulos afetados", "@S30", "", "", .T.})
	aadd (aC, {"_sRotinZZU", {30, 300}, "Rotinas afetadas", "@S30", "", "", .T.})

	aR := {}
	_aJanela := {60, 30, oMainWnd:nClientHeight - 30, oMainWnd:nClientWidth - 30}  // Janela (dialog) do modelo2
	aCGD := {55,20,118,315}
	if Modelo2 (cCadastro, ;  // Titulo
		aC, ;  // Cabecalho
		aR, ;  // Rodape
		aCGD, ;  // Coordenadas da getdados
		nOpc, ;  // nOPC
		'U_ZZULK ()', ;  // Linha OK
		'U_ZZUTK ()', ;  // Tudo OK
		, ;  // Gets editaveis
		, ;  // bloco codigo para tecla F4
		, ;  // Campos inicializados
		999, ;  // Numero maximo de linhas
		_aJanela, ;  // Coordenadas da janela
		.T.)  // Linhas podem ser deletadas.

		// Gravacao
		// Monta lista de campos que nao estao no browse, com seu devido conteudo, para posterior gravacao.
		_aCposFora := {}
		aadd (_aCposFora, {"ZZU_FILIAL", xfilial ("ZZU")})
		aadd (_aCposFora, {"ZZU_GRUPO",  _sGrupoZZU})
		aadd (_aCposFora, {"ZZU_DESCRI", _sDescrZZU})
		aadd (_aCposFora, {"ZZU_ROTIN",  _sRotinZZU})
		aadd (_aCposFora, {"ZZU_MODUL",  _sModulZZU})

		// Grava dados do aCols.
		ZZU -> (dbsetorder (1))  // ZZU_FILIAL, ZZU_GRUPO, ZZU_FIL, ZZU_USER, R_E_C_N_O_, D_E_L_E_T_
		for _nLinACols = 1 to len (aCols)

			// Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
			u_log2 ('debug', 'pesquisando com chave >>' + xfilial ("ZZU") + _sGrupoZZU + GDFieldGet ("ZZU_FIL", _nLinACols) + GDFieldGet ("ZZU_USER", _nLinACols) + '<<')
			if ZZU -> (dbseek (xfilial ("ZZU") + _sGrupoZZU + GDFieldGet ("ZZU_FIL", _nLinACols) + GDFieldGet ("ZZU_USER", _nLinACols) , .F.))
				u_log2 ('debug', 'encontrei ZZU')

				// Se estah deletado em aCols, preciso excluir do arquivo tambem.
				if GDDeleted (_nLinACols)
					u_log2 ('debug', 'deletado no aCols')
					_oEvento := ClsEvent ():New ()
					_oEvento:CodEven = 'ZZU003'
					_oEvento:Texto = "Removendo usuario '" + zzu -> zzu_user + "' (" + alltrim (GDFieldGet ("ZZU_NOME", _nLinACols)) + ") do grupo '" + zzu -> zzu_grupo + "' (" + alltrim (_sDescrZZU) + ")"
					_oEvento:Alias  = 'ZZU'
					_oEvento:Recno  = zzu -> (recno ())
					_oEvento:Chave  = zzu -> zzu_grupo
					_oEvento:Grava ()

					reclock ("ZZU", .F.)
					ZZU -> (dbdelete ())
					msunlock ("ZZU")
				else  // Alteracao
					if zzu -> zzu_fil != GDFieldGet ("ZZU_FIL", _nLinACols) ;
						.or. zzu -> zzu_user  != GDFieldGet ("ZZU_USER", _nLinACols) ;
						.or. zzu -> zzu_tipo  != GDFieldGet ("ZZU_TIPO", _nLinACols) ;
						.or. zzu -> zzu_valid != GDFieldGet ("ZZU_VALID", _nLinACols) ;
						.or. zzu -> zzu_hist  != GDFieldGet ("ZZU_HIST", _nLinACols)

						_oEvento := ClsEvent ():New ()
						_oEvento:CodEven = 'ZZU002'
						_oEvento:Texto = "Alterando amarracao usuario '" + zzu -> zzu_user + "' (" + alltrim (GDFieldGet ("ZZU_NOME", _nLinACols)) + ") X grupo '" + zzu -> zzu_grupo + "' (" + alltrim (_sDescrZZU) + ")" + chr (13) + chr (10)
						_oEvento:Texto += "Situacao anterior: filial: " + zzu -> ZZU_FIL + "; Tipo de acesso: " + alltrim (x3combo ('ZZU_TIPO', zzu -> ZZU_TIPO)) + "; Historico: " + alltrim (zzu -> ZZU_HIST) + chr (13) + chr (10)
						_oEvento:Texto += "Nova situacao: filial: " + GDFieldGet ("ZZU_FIL", _nLinACols) + "; Tipo de acesso: " + alltrim (x3combo ('ZZU_TIPO', GDFieldGet ("ZZU_TIPO", _nLinACols))) + "; Historico: " + alltrim (GDFieldGet ("ZZU_HIST", _nLinACols)) + chr (13) + chr (10)
						_oEvento:Alias  = 'ZZU'
						_oEvento:Recno  = zzu -> (recno ())
						_oEvento:Chave  = zzu -> zzu_grupo
						_oEvento:Grava ()
					endif

					reclock ("ZZU", .F.)
					U_GrvACols ("ZZU", _nLinACols, _aCposFora)
					msunlock ("ZZU")
				endif

			else  // A linha ainda nao existe no arquivo
				if GDDeleted (_nLinACols)
					loop
				else
					begin transaction
					reclock ("ZZU", .T.)
					U_GrvACols ("ZZU", _nLinACols, _aCposFora)
					msunlock ("ZZU")

					_oEvento := ClsEvent ():New ()
					_oEvento:CodEven = 'ZZU001'
					_oEvento:Texto = "Incluindo usuario '" + GDFieldGet ("ZZU_USER", _nLinACols) + "' (" + alltrim (GDFieldGet ("ZZU_NOME", _nLinACols)) + ") no grupo '" + _sGrupoZZU + "' (" + alltrim (_sDescrZZU) + ")" + chr (13) + chr (10)
					_oEvento:Texto += "Filial: " + GDFieldGet ("ZZU_FIL", _nLinACols) + " Tipo de acesso: " + alltrim (x3combo ('ZZU_TIPO', GDFieldGet ("ZZU_TIPO", _nLinACols))) + chr (13) + chr (10)
					_oEvento:Texto += "Historico: " + alltrim (GDFieldGet ("ZZU_HIST", _nLinACols))
					_oEvento:Alias  = 'ZZU'
					_oEvento:Recno  = zzu -> (recno ())
					_oEvento:Chave  = zzu -> zzu_grupo
					_oEvento:Grava ()
					end transaction
				endif
			endif
		next

	endif
return



// --------------------------------------------------------------------------
// Executar operacoes 'por usuario'
user function ZZUAU (_sQueFazer)
	local _sUser   := space (6)
	local _aReg    := {}
	local _nReg    := 0
	local _oSQL    := NIL
	local _dValid  := ctod ('')
	local _oEvento := NIL

	_sUser = U_Get ("Codigo do usuario", 'C', 6, '', 'USR', _sUser, .f., '.t.')
	if empty (_sUser)
		u_help ("Usuario nao informado. Processo cancelado.",, .t.)
	else
		// Leitura dos grupos onde o usuario aparece e montagem de markbrowse para selecao do usuario
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT '' AS OK, R_E_C_N_O_, ZZU_USER, ZZU_NOME, ZZU_GRUPO, ZZU_DESCRI, dbo.VA_DTOC (ZZU_VALID), ZZU_HIST"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZZU") + " ZZU"
		_oSQL:_sQuery += " WHERE ZZU.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZZU.ZZU_FILIAL = '" + xfilial ("ZZU") + "'"
		_oSQL:_sQuery +=   " AND ZZU.ZZU_USER   = '" + _sUser + "'"
		_oSQL:_sQuery += " ORDER BY ZZU.ZZU_GRUPO"
		_aReg := aclone (_osql:Qry2Array (.f., .f.))

		// Inicializa coluna de selecao com .F. ('nao selecionada').
		for _nReg = 1 to len (_aReg)
			_aReg [_nReg, 1] = .F.
		next

		_aCols = {}
		aadd (_aCols, {3, 'Usuario',          30, ''})
		aadd (_aCols, {4, 'Nome',             60, ''})
		aadd (_aCols, {5, 'Grupo',            30, ''})
		aadd (_aCols, {6, 'Descr.grupo',      60, ''})
		aadd (_aCols, {7, 'Validade',         40, ''})
		aadd (_aCols, {8, 'Historico',       250, ''})
		U_MBArray (@_aReg, 'Selecione registros a alterar', _aCols, 1)

		do case
		case _sQueFazer == 'AV'  // Alterar validade dos registros
			_dValid = U_Get ("Nova data de validade", 'D', 8, '@D', '', date (), .f., '.t.')
			if empty (_dValid)
				u_help ("Nova data de validade deve ser informada. Processo cancelado.",, .t.)
			else
				procregua (len (_aReg))
				for _nReg = 1 to len (_aReg)
					incproc ()
					if _aReg [_nReg, 1]
						zzu -> (dbgoto (_aReg [_nReg, 2]))
						
						begin transaction
						_oEvento := ClsEvent ():New ()
						_oEvento:CodEven = 'ZZU002'
						_oEvento:Texto := "Alterando validade de " + dtoc (zzu -> zzu_valid) + " para " + dtoc (_dValid)
						_oEvento:Texto += " na amarracao usuario " + zzu -> zzu_user + " (" + alltrim (_aReg [_nReg, 4]) + ")"
						_oEvento:Texto += " X grupo " + zzu -> zzu_grupo + " (" + alltrim (_aReg [_nReg, 6]) + ")"
						_oEvento:Alias  = 'ZZU'
						_oEvento:Recno  = zzu -> (recno ())
						_oEvento:Chave  = zzu -> zzu_grupo
						_oEvento:Grava ()

						reclock ('ZZU', .F.)
						zzu -> zzu_valid = _dValid
						msunlock ()
						end transaction
					endif
				next
			endif
		otherwise
			u_help ("Opcao '" + _sQueFazer + "' sem tratamento!",, .t.)
		endcase
	endif
return


// --------------------------------------------------------------------------
// Exclusao total.
user function ZZUE ()
	local _sGrupoZZU := zzu -> ZZU_GRUPO
	local _lContinua := .T.
	local _oEvento   := NIL

	if _lContinua .and. u_msgyesno ("Confirma a exclusao do grupo e seus relacionamentos com usuarios?")

		begin transaction
		_oEvento := ClsEvent ():New ()
		_oEvento:CodEven = 'ZZU004'
		_oEvento:Texto = "Excluindo grupo '" + zzu -> zzu_grupo + "' (" + alltrim (ZZU -> ZZU_DESCRI) + ")" + chr (13) + chr (10)

		zzu -> (dbsetorder (1))  // zzu_FILIAL + ZZU_GRUPO + zzu_USER
		zzu -> (dbseek (xfilial ("zzu") + _sGrupoZZU, .T.))
		do while ! zzu -> (eof ()) .and. zzu -> zzu_filial == xfilial ("zzu") .and. zzu -> ZZU_GRUPO == _sGrupoZZU
			_oEvento:Texto += "Removendo usuario " + zzu -> zzu_user + " - " + alltrim (zzu -> zzu_nome) + chr (13) + chr (10)
			_oEvento:Alias  = 'ZZU'
			_oEvento:Chave  = zzu -> zzu_grupo
			reclock ("zzu", .F.)
			zzu -> (dbdelete ())
			msunlock ()
			zzu -> (dbskip ())
		enddo
		_oEvento:Grava ()
		end transaction
		u_help ("Dados excluidos.")
	endif
return



// --------------------------------------------------------------------------
// Validacao de 'Linha OK'
user function ZZULK ()
	local _lRet    := .T.

	// Verifica campos obrigatorios
	if _lRet .and. ! GDDeleted ()
		_lRet = MaCheckCols (aHeader, aCols, N, {})
	endif

	if _lRet .and. ! GDDeleted ()
		_lRet = GDCheckKey ({"ZZU_FIL", "ZZU_USER"}, 4)
	endif

	if _lRet .and. ! GDDeleted ()
		if alltrim (GDFieldGet ("ZZU_USER")) == "*" .and. GDFieldGet ("ZZU_TIPO") != '1'
			u_help ("Usuario '*' (todos) aplica-se apenas para tipo 'liberacao'")
			_lRet = .F.
		endif
	endif
return _lRet



// --------------------------------------------------------------------------
// Validacao de 'Tudo OK'
user function ZZUTK ()
	local _lRet    := .T.
	if _lRet .and. (empty (_sGrupoZZU) .or. empty (_sDescrZZU))
		u_help ("Campos GRUPO e DESCRICAO devem ser informados.")
		_lRet = .F.
	endif
return _lRet



// --------------------------------------------------------------------------
// Verifica se o usuario pertence ao grupo solicitado.
user function ZZUVL (_sGrupoZZU, _sUser, _lComTela)  //, _sEmp, _sFil, _sTipos)
	local _lRet     := .F.
	local _aAreaAnt := U_ML_SRArea ()
	local _sMsg     := ""

	_sUser    := iif (_sUser    == NIL, __cUserID, _sUser)
	_lComTela := iif (_lComTela == NIL, .T.,       _lComTela)
	_sTipos   := iif (_sTipos   == NIL, '13',      _sTipos)

	zzu -> (dbsetorder (1))  // ZZU_FILIAL+ZZU_GRUPO+ZZU_FIL+ZZU_USER
	if ! zzu -> (dbseek (xfilial ("ZZU") + _sGrupoZZU, .T.))
		_sMsg += "Grupo '" + _sGrupoZZU + "' nao cadastrado na tabela ZZU. Entre em contato com o setor de informatica."
		_lRet = .F.
	else
		_lRet = .F.
		do while ! zzu -> (eof ()) .and. zzu -> zzu_filial == xfilial ("ZZU") .and. zzu -> zzu_grupo == _sGrupoZZU
	//		u_log2 ('debug', 'dentro do while')
			if alltrim (zzu -> zzu_fil) == "*" .or. zzu -> zzu_fil == cFilAnt  // _sFil
		//		u_log2 ('debug', 'filial ok')
				if alltrim (zzu -> zzu_user) == "*" .or. zzu -> zzu_user == _sUser
			//		u_log2 ('debug', 'usuario ok')
					if zzu -> zzu_tipo $ _sTipos //'13'  // 1=Libera;2=Notifica;3=Libera e notifica
				//		u_log2 ('debug', 'tipo de acesso ok')
						if zzu -> zzu_valid >= date ()
					//		u_log2 ('debug', 'validade ok')
							_lRet = .T.
							exit
						endif
					endif
				endif
			endif
			zzu -> (dbskip ())
		enddo
		if ! _lRet 
			// _sMsg += "Usuario '" + _sUser + "' sem liberacao (ou nao cadastrado) no grupo '" + _sGrupoZZU + "'."
			_sMsg += "Usuario '" + _sUser + "' sem liberacao (ou nao cadastrado) no grupo '" + _sGrupoZZU + "' na filial '" + cFilAnt + "'."
		endif
	endif
	
	if ! empty (_sMsg)
		if _lComTela
			u_help (_sMsg,, .t.)
		else
			if type ("_oBatch") == 'O'
				_oBatch:Mensagens += _sMsg
			endif
		endif
	endif

	if ! _lRet
		U_Log2 ('aviso', '[' + procname () + ']Retornando ' + cvaltochar (_lRet) + ' para grupoZZU=' + _sGrupoZZU + ' e usr=' + _sUser)
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet


// --------------------------------------------------------------------------
// Notifica usuarios associados ao grupo.
user function ZZUNU (_aGrpZZU, _sTitMsg, _sCorpoMsg, _lComTela)
	local _aAreaAnt  := U_ML_SRArea ()
	local _sResultTo := ""
	local _sMsgErro  := ""
	local _sGrupoZZU := ""
	local _nGrpZZU   := 0
	local _nEnvios   := 0

	_lComTela := iif (_lComTela == NIL, .T.,       _lComTela)
	_aGrpZZU  := iif (valtype (_aGrpZZU) == 'C', {_aGrpZZU}, _aGrpZZU)

	if empty (_sTitMsg) .and. empty (_sCorpoMsg)
		_sMsgErro += ("Parametros invalidos no programa " + procname () + ": falta titulo e corpo da mensagem.")
		U_AvisaTI (_sMsgErro)
		if _lComTela
			u_help (_sMsgErro)
		else
			u_log (_sMsgErro)
		endif
	else
		for _nGrpZZU = 1 to len (_aGrpZZU)
			_sGrupoZZU = _aGrpZZU [_nGrpZZU]
			_sResultTo = ''

			// Busca lista de destinatarios do grupo atual.
			_sResultTo = U_ZZULD (_sGrupoZZU, cFilAnt, '23')[1]

			// Envia notificacao por e-mail
			if ! empty (_sResultTo)
				U_SendMail (_sResultTo, _sTitMsg, _sCorpoMsg, {}, NIL, _sGrupoZZU)
				_nEnvios ++
			endif
		next
	endif

	U_ML_SRArea (_aAreaAnt)
return _nEnvios



// --------------------------------------------------------------------------
// Retorna lista dos usuarios associados ao grupo.
user function ZZULD (_sGrupoZZU, _sFil, _sTipos)
	local _aAreaAnt  := U_ML_SRArea ()
	local _sResultTo := ""
	local _aResultTo := {}
	local _aIDs      := {}
	local _sUsrNames := ''

	_sTipos = iif (_sTipos == NIL, '123', _sTipos)

	zzu -> (dbsetorder (1))
	zzu -> (dbseek (xfilial ("ZZU") + _sGrupoZZU, .T.))
	do while ! zzu -> (eof ()) .and. zzu -> zzu_filial == xfilial ("ZZU") .and. zzu -> zzu_grupo == _sGrupoZZU
		if alltrim (zzu -> zzu_fil) == "*" .or. zzu -> zzu_fil == _sFil
			if zzu -> zzu_tipo $ _sTipos //'23'  // 1=Libera;2=Notifica;3=Libera e notifica
				if zzu -> zzu_valid >= date ()
					aadd (_aIDs, zzu -> zzu_user)
					PswOrder (1)  // 1 - ID do usuário/grupo; 2 - Nome do usuário/grupo; 3 - Senha do usuário; 4 - E-mail do usuário
					if PswSeek (zzu -> zzu_user, .T.)
						_aUser := PswRet ()
						
						// Lista de usernames para uso nas notificacoes do NaWeb
						_sUsrNames += iif (empty (_sUsrNames), '', ';') + alltrim (_aUser [1, 2])
						
						if empty (_aUser [1, 14])
							U_log2 ('aviso', "Usuario '" + zzu -> zzu_user + "' nao tem e-mail no cadastro de usuarios do sistema.")
						else
							_sResultTo += alltrim (_aUser [1, 14]) + ";"
							aadd (_aResultTo, alltrim (_aUser [1, 14]))
						endif
					else
						u_log2 ('aviso', "Codigo de usuario '" + zzu -> zzu_user + "' nao encontrado no cadastro de usuarios!")
					endif
				endif
			endif
		endif
		zzu -> (dbskip ())
	enddo

	U_ML_SRArea (_aAreaAnt)
return {_sResultTo, _aResultTo, _aIDs, _sUsrNames}
