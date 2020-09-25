// Programa:  BatUsers
// Autor:     Robert Koch
// Data:      25/06/2015
// Descricao: Leitura de configuracoes / acessos de usuarios e geracao de tabelas no banco de dados.
//
// Historico de alteracoes:
// 01/06/2016 - Robert - Grava avisos para TI no final do processo.
// 20/06/2016 - Robert - Novos avisos para TI.
// 23/07/2016 - Robert - Novos avisos para TI (usuarios sem o acesso 150).
// 27/09/2019 - Robert - Renomeado de Users para BatUsers e acrescentados alguns tratamentos para rodar em batch.
// 23/10/2019 - Robert - Testes com funcao U_ArqTrb().
// 30/10/2019 - Robert - Passa a gravar avisos e erros usando a classe ClsAviso().
// 13/12/2019 - Robert - Acrescentada coluna com o cargo do usuario (para posterior consulta de matriculas).
// 10/02/2020 - Robert - Indices das tabelas VA_USR* passam a ser criados como 'clustered' para permitir reorganizacao pelo SQL.
// 15/06/2020 - Robert - Grava campo 'usado' na tabela de modulos.
//                     - Atualiza campos de nome e e-mail na tabela ZZU.
// 20/07/2020 - Robert - Leitura de novos campos (ZZU_ROTIN e ZZU_MODUL).
//                     - Inseridas tags para catalogacao de fontes
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Leitura de dados de acessos, rotinas e menus alimentando tabelas no SQL para posterior consulta.
// #PalavasChave      #usuarios #acessos
// #TabelasPrincipais #ZZU
// #Modulos           #CFG



// FwUsrPrivDB - Retorna os privil�gios atrelados a um usu�rio em ambientes com dicion�rio no banco de dados.
// FwGrpPrivDB - Retorna os privil�gios de um grupo com ambiente no banco de dados
//	u_log (FwUsrPrivDB ())
//	u_log (FwGrpPrivDB ('000009'))


// --------------------------------------------------------------------------
user function BatUsers (_sUsrID)

	processa ({|| _AndaLogo ()})
/*	
	// Faz algumas validacoes nos dados lidos.
	_aValid := {}

	for _nValid = 1 to len (_aValid)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := _aValid [_nValid]
		_oSQL:Log ()
		_aAvisos = _oSQL:Qry2Array (.F., .F.)
		for _nAviso = 1 to len (_aAvisos)
			if ! empty (_aAvisos [_nAviso, 1])
			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'A'
			_oAviso:Destinatar = 'grpTI'
			_oAviso:Texto      = _aAvisos [_nAviso, 1]
			_oAviso:Origem     = procname ()
			_oAviso:DiasDeVida = 5
			_oAviso:CodAviso   = '003'
			_oAviso:Grava ()
				endif
		next
	next
*/
	// Atualiza campos como ZZU_NOME e ZZU_EMAIL (foram criados como 'reais' para permitir indexar e melhorar performance da tela de manutencao).
	processa ({|| _AtuZZU ()})

	u_log2 ('info', 'Finalizando processo')
return



// --------------------------------------------------------------------------
static function _AndaLogo ()
	local _oSQL      := NIL
	local _aCampos   := {}
	local _aPswRet   := {}
	local _aIns      := {}
	local _sID       := ""
	local _nFilial   := 0
	local _nGrupo    := 0
	local _aModulos  := {}
	local _nModulo   := 0
	local _aAreaSM0  := {}
	local _aAcesList := {}
	local _aAcessos  := {}
	local _nAcesso   := 0
	local _sAcessos  := ""
	local _aUsers    := {}
	local _nUser     := 0
	local _sRegraGrp := ""
	local _aUltLogin := {}
	local _aGrupos   := {}
	local _lTodasEmp := .F.
	local _aEmpFil   := {}
	local _nEmpFil   := 0
	local _aGrpEmp   := {}
	local _nGrpEmp   := 0
	local _aMenus    := {}
	local _nMenu     := 0
	local _aGrpMenu  := {}
	local _nGrpMenu  := 0
	local _oAUtil    := ClsAUtil ():New ()
	local _aRetQry   := {}
	local _nRetQry   := 0
	local _aImpGrp   := {}
	local _aParmGrp  := {}
	procregua (10)
	incproc ("Criando tabelas no SQL")

	// parece retornar apenas se o usuario tem acesso `a rotina --> u_log (chkuserrules ('104'))

	// Cria tabelas no SQL, caso nao existam
	u_log2 ('info', 'Criando tabelas no banco de dados.')
	_aCampos = {}
	aadd (_aCampos, " ID_USR                    VARCHAR (6)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " NOME                      VARCHAR (30) DEFAULT '' NOT NULL ")
	aadd (_aCampos, " BLOQUEADO                 VARCHAR (1)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " AC_SIMULT                 INT          DEFAULT 0  NOT NULL ")
	aadd (_aCampos, " REGRA_GRUPO               VARCHAR (12) DEFAULT '' NOT NULL ")
	aadd (_aCampos, " ULT_LOGIN_DATA            VARCHAR (8)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " ULT_LOGIN_HORA            VARCHAR (5)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " ULT_LOGIN_ESTACAO         VARCHAR (15) DEFAULT '' NOT NULL ")
	aadd (_aCampos, " CONFIGURA_DATA_BASE       VARCHAR (1)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " DIAS_RETROCEDER_DATA_BASE INT          DEFAULT 0  NOT NULL ")
	aadd (_aCampos, " DIAS_AVANCAR_DATA_BASE    INT          DEFAULT 0  NOT NULL ")
	aadd (_aCampos, " CARGO                     VARCHAR (40) DEFAULT '' NOT NULL ")
	_CriaTab ("VA_USR_USUARIOS", _aCampos, {"ID_USR"}, .T.)

	_aCampos = {}
	aadd (_aCampos, " ID_GRUPO                  VARCHAR (6)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " TIPO_GRUPO                VARCHAR (3)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " BLOQUEADO                 VARCHAR (1)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " GRUPO                     VARCHAR (28) DEFAULT '' NOT NULL ")
	aadd (_aCampos, " DESCRICAO                 VARCHAR (50) DEFAULT '' NOT NULL ")
	aadd (_aCampos, " DIRETORIO_IMPRESSAO       VARCHAR (25) DEFAULT '' NOT NULL ")
	aadd (_aCampos, " TIPO_IMPRESSAO            VARCHAR (16) DEFAULT '' NOT NULL ")
	aadd (_aCampos, " AMBIENTE_IMPRESSAO        VARCHAR (8)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " CONFIGURA_DATA_BASE       VARCHAR (1)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " DIAS_RETROCEDER_DATA_BASE INT          DEFAULT 0  NOT NULL")
	aadd (_aCampos, " DIAS_AVANCAR_DATA_BASE    INT          DEFAULT 0  NOT NULL")
	_CriaTab ("VA_USR_GRUPOS", _aCampos, {"ID_GRUPO, TIPO_GRUPO"}, .T.)

	_aCampos = {}
	aadd (_aCampos, " ID_MODULO     VARCHAR (2)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " SIGLA         VARCHAR (5)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " USADO         VARCHAR (1)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " DESCRICAO     VARCHAR (50) DEFAULT '' NOT NULL ")
	aadd (_aCampos, " VERTICAL      VARCHAR (1)  DEFAULT '' NOT NULL ")
	_CriaTab ("VA_USR_MODULOS", _aCampos, {"ID_MODULO"}, .T.)

	_aCampos = {}
	aadd (_aCampos, " ROTINA        VARCHAR (40) DEFAULT '' NOT NULL ")
	aadd (_aCampos, " DESCRICAO     VARCHAR (60) DEFAULT '' NOT NULL ")
	_CriaTab ("VA_USR_ROTINAS", _aCampos, {"ROTINA"}, .T.)

	_aCampos = {}
	aadd (_aCampos, " TIPO             VARCHAR (3)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " ACESSO           VARCHAR (3)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " DESCRICAO        VARCHAR (90) DEFAULT '' NOT NULL ")
	aadd (_aCampos, " MODULOS_AFETADOS VARCHAR (50) DEFAULT '' NOT NULL ")
	aadd (_aCampos, " ROTINAS_AFETADAS VARCHAR (200) DEFAULT '' NOT NULL ")
	_CriaTab ("VA_USR_ACESSOS", _aCampos, {"TIPO, ACESSO"}, .T.)

	_aCampos = {}
	aadd (_aCampos, " ID_USR        VARCHAR (6)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " TIPO_ACESSO   VARCHAR (3)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " ACESSO        VARCHAR (3)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " ORIGEM_ACESSO VARCHAR (60) DEFAULT '' NOT NULL ")
	_CriaTab ("VA_USR_ACESSOS_POR_USUARIO", _aCampos, {"ID_USR, TIPO_ACESSO, ACESSO"}, .T.)

	_aCampos = {}
	aadd (_aCampos, " ID_GRUPO    VARCHAR (6)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " TIPO_ACESSO VARCHAR (3)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " ACESSO      VARCHAR (3)  DEFAULT '' NOT NULL ")
	_CriaTab ("VA_USR_ACESSOS_POR_GRUPO", _aCampos, {"ID_GRUPO, TIPO_ACESSO, ACESSO"}, .T.)

	_aCampos = {}
	aadd (_aCampos, " ID_GRUPO    VARCHAR (6)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " ID_MODULO   VARCHAR (2)  DEFAULT '' NOT NULL ")
	_CriaTab ("VA_USR_MODULOS_POR_GRUPO", _aCampos, {"ID_GRUPO, ID_MODULO"}, .T.)

	_aCampos = {}
	aadd (_aCampos, " ID_USR     VARCHAR (6)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " TIPO_GRUPO VARCHAR (6)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " ID_GRUPO   VARCHAR (6)  DEFAULT '' NOT NULL ")
	_CriaTab ("VA_USR_GRUPOS_POR_USUARIO", _aCampos, {"ID_USR, TIPO_GRUPO, ID_GRUPO"}, .T.)

	_aCampos = {}
	aadd (_aCampos, " ID_USR    VARCHAR (6)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " EMPRESA   VARCHAR (2)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " FILIAL    VARCHAR (2)  DEFAULT '' NOT NULL ")
	_CriaTab ("VA_USR_FILIAIS_USUARIO", _aCampos, {"ID_USR"}, .T.)

	_aCampos = {}
	aadd (_aCampos, " ID_USR        VARCHAR (6)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " ID_MODULO     VARCHAR (2)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " NIVEL         INT          DEFAULT 0  NOT NULL ")
	aadd (_aCampos, " ARQ_MENU      VARCHAR (40) DEFAULT '' NOT NULL ")
	aadd (_aCampos, " ORIGEM_ACESSO VARCHAR (60) DEFAULT '' NOT NULL ")
	_CriaTab ("VA_USR_MODULOS_USUARIO", _aCampos, {"ID_USR"}, .T.)

	_aCampos = {}
	aadd (_aCampos, " ARQ_MENU      VARCHAR (40) DEFAULT '' NOT NULL ")
	aadd (_aCampos, " ROTINA        VARCHAR (40) DEFAULT '' NOT NULL ")
	aadd (_aCampos, " HABILITADA    VARCHAR (1)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " TIPO          VARCHAR (2)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " ID_MODULO     VARCHAR (2)  DEFAULT '' NOT NULL ")
	aadd (_aCampos, " ACESSOS       VARCHAR (10) DEFAULT '' NOT NULL ")
	_CriaTab ("VA_USR_ROTINAS_POR_MENU", _aCampos, {"ARQ_MENU", "ROTINA"}, .T.)


	// Cria array com todos os acessos do configurador, remove acentuacao e popula tabela no banco de dados.
	u_log2 ('info', 'Lendo acessos do configurador')
	_aAcesList = aclone (GetAccessList ())
	for _nAcesso = 1 to len (_aAcesList)
		_aAcesList [_nAcesso, 2] = EncodeUTF8 (_aAcesList [_nAcesso, 2])
	next
	for _nAcesso = 1 to len (_aAcesList)
		_aIns = {}
		aadd (_aIns, {"TIPO",          'CFG'})
		aadd (_aIns, {"ACESSO",        strzero (_aAcesList [_nAcesso, 1], 3)})
		aadd (_aIns, {"DESCRICAO",     U_NoAcento (alltrim (upper (_aAcesList [_nAcesso, 2])))})
		_oSQL := ClsSQL ():New ()
		_oSQL:InsValues ("VA_USR_ACESSOS", _aIns)
	next
	
	// Insere os acessos da tabela ZZU (customizada)
	u_log2 ('info', 'Lendo acessos do ZZU')
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT DISTINCT ZZU_GRUPO, ZZU_DESCRI, ZZU_MODUL, ZZU_ROTIN"
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZZU")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_aRetQry := aclone (_oSQL:Qry2Array ())
	for _nRetQry = 1 to len (_aRetQry)
		_aIns = {}
		aadd (_aIns, {"TIPO",             'ZZU'})
		aadd (_aIns, {"ACESSO",           _aRetQry [_nRetQry, 1]})
		aadd (_aIns, {"DESCRICAO",        U_NoAcento (alltrim (upper (_aRetQry [_nRetQry, 2])))})
		aadd (_aIns, {"MODULOS_AFETADOS", alltrim (upper (_aRetQry [_nRetQry, 3]))})
		aadd (_aIns, {"ROTINAS_AFETADAS", alltrim (upper (_aRetQry [_nRetQry, 4]))})
		_oSQL := ClsSQL ():New ()
		_oSQL:InsValues ("VA_USR_ACESSOS", _aIns)
	next

	// Para cada 'acesso', informa quais os modulos afetados.
	_AtuAces ()

	// Popula tabela com todos os grupos de usuarios do configurador.
	u_log2 ('info', 'Lendo grupos do configurador')
	_aGrupos = aclone (ALLGROUPS ())  // Retorna apenas ID, 'grupo' e descricao.
	for _nGrupo = 1 to len (_aGrupos)
		
		// Busca parametrizacao de impressao para o grupo
		_aImpGrp = FWGrpImp (_aGrupos [_nGrupo, 1, 1])

		// Busca outras parametrizacoes para o grupo
		_aParmGrp = FWGrpParam (_aGrupos [_nGrupo, 1, 1])

		// Busca provilegios associados ao grupo. consta que funciona apenas com banco de dados ---> https://tdn.totvs.com/display/public/PROT/FwGrpPrivDB
		//_aPrivGRP = FwGrpPrivDB (_aGrupos [_nGrupo, 1, 1])
		
		_aIns = {}
		aadd (_aIns, {"TIPO_GRUPO",                'CFG'})
		aadd (_aIns, {"ID_GRUPO",                  alltrim (_aGrupos [_nGrupo, 1, 1])})
		aadd (_aIns, {"GRUPO",                     alltrim (_aGrupos [_nGrupo, 1, 2])})
		aadd (_aIns, {"DESCRICAO",                 U_NoAcento (alltrim (upper (_aGrupos [_nGrupo, 1, 3])))})
		aadd (_aIns, {"DIRETORIO_IMPRESSAO",       alltrim (upper (_aImpGrp [1]))})
		aadd (_aIns, {"TIPO_IMPRESSAO",            {"EM DISCO", "VIA WINDOWS", "DIRETO NA PORTA"} [max (1, val(_aImpGrp [3]))]})
		aadd (_aIns, {"AMBIENTE_IMPRESSAO",        {"SERVIDOR", "CLIENTE"} [max (1, val(_aImpGrp [5]))]})
		aadd (_aIns, {"CONFIGURA_DATA_BASE",       iif (_aParmGrp [2, 1] == '1', 'S', 'N')})
		aadd (_aIns, {"DIAS_RETROCEDER_DATA_BASE", _aParmGrp [2, 2]})
		aadd (_aIns, {"DIAS_AVANCAR_DATA_BASE",    _aParmGrp [2, 3]})
		aadd (_aIns, {"BLOQUEADO",                 iif (_aParmGrp [1, 3] == '1', 'S', 'N')})
		_oSQL := ClsSQL ():New ()
		_oSQL:InsValues ("VA_USR_GRUPOS", _aIns)

		// Popula tabela com os acessos de cada grupo do configurador.
		u_log2 ('info', 'Lendo acessos do grupo ' + _aGrupos [_nGrupo, 1, 1])
		_sAcessos = FWGrpAcess (_aGrupos [_nGrupo, 1, 1])
		for _nAcesso = 1 to len (_aAcesList)
			if substr (_sAcessos, _nAcesso, 1) == 'S'
				_aIns = {}
				aadd (_aIns, {"ID_GRUPO",    alltrim (_aGrupos [_nGrupo, 1, 1])})
				aadd (_aIns, {"TIPO_ACESSO", 'CFG'})
				aadd (_aIns, {"ACESSO",      strzero (_aAcesList [_nAcesso, 1], 3)})
				_oSQL := ClsSQL ():New ()
				_oSQL:InsValues ("VA_USR_ACESSOS_POR_GRUPO", _aIns)
			endif
		next
	next

	// Insere os grupos da tabela ZZU (customizada)
	u_log2 ('info', 'Lendo grupos do ZZU')
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT DISTINCT ZZU_GRUPO, ZZU_DESCRI"
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZZU")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_aRetQry := aclone (_oSQL:Qry2Array ())
	for _nRetQry = 1 to len (_aRetQry)
		_aIns = {}
		aadd (_aIns, {"TIPO_GRUPO", 'ZZU'})
		aadd (_aIns, {"ID_GRUPO",   _aRetQry [_nRetQry, 1]})
		aadd (_aIns, {"DESCRICAO",  alltrim (upper (_aRetQry [_nRetQry, 2]))})
		_oSQL := ClsSQL ():New ()
		_oSQL:InsValues ("VA_USR_GRUPOS", _aIns)
	next

	// Popula tabela com todos os modulos do sistema (nao encontrei funcao que retorne os nomes dos modulos).
	// sugestao ler isso da tabela CW0. 
	u_log2 ('info', 'Criando tabela de modulos')
	_aModulos = {}
	aadd (_aModulos, {'01', 'ATF',   'S', 'N', 'ATIVO FIXO'})
	aadd (_aModulos, {'02', 'COM',   'S', 'N', 'COMPRAS'})
	aadd (_aModulos, {'03', 'CON',   'N', 'N', 'CONTABILIDADE'})
	aadd (_aModulos, {'04', 'EST',   'S', 'N', 'ESTOQUE E CUSTOS'})
	aadd (_aModulos, {'05', 'FAT',   'S', 'N', 'FATURAMENTO'})
	aadd (_aModulos, {'06', 'FIN',   'S', 'N', 'FINANCEIRO'})
	aadd (_aModulos, {'07', 'GPE',   'N', 'N', 'GESTAO DE PESSOAL'})
	aadd (_aModulos, {'08', 'FAS',   'N', ' ', 'FATURAMENTO DE SERVICO'})
	aadd (_aModulos, {'09', 'FIS',   'S', 'N', 'LIVROS FISCAIS'})
	aadd (_aModulos, {'10', 'PCP',   'S', 'N', 'PLANEJ.CONTR.PRODUCAO'})
	aadd (_aModulos, {'11', 'VEI',   'N', ' ', 'VEICULOS'})
	aadd (_aModulos, {'12', 'LOJA',  'S', 'N', 'CONTROLE DE LOJAS'})
	aadd (_aModulos, {'13', 'TMK',   'N', 'N', 'CALL CENTER'})
	aadd (_aModulos, {'14', 'OFI',   'N', ' ', 'OFICINA'})
	aadd (_aModulos, {'15', 'RPM',   'S', 'N', 'PROTHEUS REPORT UTILITY'})
	aadd (_aModulos, {'16', 'PON',   'N', 'N', 'PONTO ELETRONICO'})
	aadd (_aModulos, {'17', 'EIC',   'N', ' ', 'EASY IMPORT CONTROL'})
	aadd (_aModulos, {'18', 'TCF',   'N', ' ', 'TERMINAL DE CONSULTA DO FUNCIONARIO'})
	aadd (_aModulos, {'19', 'MNT',   'S', 'S', 'MANUTENCAO DE ATIVOS'})
	aadd (_aModulos, {'20', 'RSP',   'N', ' ', 'RECRUTAMENTO E SELECAO DE PESSOAL'})
	aadd (_aModulos, {'21', 'QIE',   'N', 'N', 'INSPECAO DE ENTRADAS'})
	aadd (_aModulos, {'22', 'QMT',   'N', 'N', 'METROLOGIA'})
	aadd (_aModulos, {'23', 'FRT',   'N', ' ', 'FRONT LOJA'})
	aadd (_aModulos, {'24', 'QDO',   'N', ' ', 'CONTROLE DE DOCUMENTOS'})
	aadd (_aModulos, {'25', 'QIP',   'N', 'N', 'INSPECAO DE PROCESSOS'})
	aadd (_aModulos, {'26', 'TRM',   'N', ' ', 'TREINAMENTO'})
	aadd (_aModulos, {'27', 'EIF',   'N', ' ', 'IMPORTACAO - FINANCEIRO'})
	aadd (_aModulos, {'28', 'TEC',   'N', ' ', 'GESTAO DE SERVICOS'})
	aadd (_aModulos, {'29', 'EEC',   'N', ' ', 'EASY EXPORT CONTROL'})
	aadd (_aModulos, {'30', 'EFF',   'N', ' ', 'EASY FINANCING'})
	aadd (_aModulos, {'31', 'ECO',   'N', ' ', 'EASY ACCOUNTING'})
	aadd (_aModulos, {'32', 'AFV',   'N', ' ', 'ADMINISTRACAO DE FORCA DE VENDAS'})
	aadd (_aModulos, {'33', 'PLS',   'N', ' ', 'PLANO DE SAUDE'})
	aadd (_aModulos, {'34', 'CTB',   'S', 'N', 'CONTABILIDADE GERENCIAL'})
	aadd (_aModulos, {'35', 'MDT',   'N', 'S', 'MEDICINA E SEGURANCA DO TRABALHO'})
	aadd (_aModulos, {'36', 'QNC',   'N', ' ', 'CONTROLE DE NAO-CONFORMIDADES'})
	aadd (_aModulos, {'37', 'QAD',   'N', ' ', 'CONTROLE DE AUDITORIA'})
	aadd (_aModulos, {'38', 'QCP',   'N', ' ', 'CONTROLE ESTATISTICO DE PROCESSO'})
	aadd (_aModulos, {'39', 'OMS',   'S', 'N', 'OMS - GESTAO DE DISTRIBUICAO'})
	aadd (_aModulos, {'40', 'CSA',   'N', ' ', 'CARGOS E SALARIOS'})
	aadd (_aModulos, {'41', 'PEC',   'N', ' ', 'AUTOPECAS'})
	aadd (_aModulos, {'42', 'WMS',   'N', 'N', 'WMS - GESTAO DE ARMAZENAGEM'})
	aadd (_aModulos, {'43', 'TMS',   'N', ' ', 'TMS - GESTAO DE TRANSPORTES'})
	aadd (_aModulos, {'44', 'PMS',   'N', ' ', 'GESTAO DE PROJETOS'})
	aadd (_aModulos, {'45', 'CDA',   'N', ' ', 'CONTROLE DE DIREITOS AUTORAIS'})
	aadd (_aModulos, {'46', 'ACD',   'N', 'N', 'AUTOMACAO E COLETA DE DADOS'})
	aadd (_aModulos, {'47', 'PPAP',  'N', ' ', 'PPAP'})
	aadd (_aModulos, {'48', 'REP',   'N', 'N', 'REPLICA'})
	aadd (_aModulos, {'49', 'AGE',   'N', ' ', 'GESTAO EDUCACIONAL'})
	aadd (_aModulos, {'50', 'EDC',   'N', ' ', 'EASY DRAWBACK CONTROL'})
	aadd (_aModulos, {'51', 'HSP',   'N', ' ', 'GESTAO HOSPITALAR'})
	aadd (_aModulos, {'52', 'VDOC',  'N', ' ', 'VIEWER'})
	aadd (_aModulos, {'53', 'APD',   'N', ' ', 'AVALIACAO E PESQUISA DE DESEMPENHO'})
	aadd (_aModulos, {'54', 'GSP',   'N', ' ', 'GESTAO DE PREFEITURAS'})
	aadd (_aModulos, {'55', 'CRD',   'N', ' ', 'SISTEMA DE FIDELIZACAO E ANALISE DE CREDITO'})
	aadd (_aModulos, {'56', 'SGA',   'N', 'S', 'GESTAO AMBIENTAL'})
	aadd (_aModulos, {'57', 'PCO',   'N', 'N', 'PLANEJAMENTO E CONTROLE ORCAMENTARIO'})
	aadd (_aModulos, {'58', 'GPR',   'N', ' ', 'GERENCIAMENTO DE PESQUISA E RESULTADO'})
	aadd (_aModulos, {'59', 'GAC',   'N', ' ', 'GESTAO DE ACERVOS'})
	aadd (_aModulos, {'60', 'PRA',   'N', ' ', 'PORTOS E RECINTOS ALFANDEGARIOS'})
	aadd (_aModulos, {'61', 'HGP',   'N', ' ', 'HRP GESTAO HOSPITALAR'})
	aadd (_aModulos, {'62', 'HHG',   'N', ' ', 'HRP FERRAMENTAS DE INFORMACAO'})
	aadd (_aModulos, {'63', 'HPL',   'N', ' ', 'HRP PLANEJAMENTO E DESENVOLVIMENTO'})
	aadd (_aModulos, {'64', 'APT',   'N', ' ', 'PROCESSOS TRABALHISTAS'})
	aadd (_aModulos, {'65', 'GAV',   'N', ' ', 'GESTAO ADVOCATICIA'})
	aadd (_aModulos, {'66', 'ICE',   'N', ' ', 'GESTAO DE RISCOS'})
	aadd (_aModulos, {'67', 'AGR',   'N', ' ', 'GESTAO AGRICOLA'})
	aadd (_aModulos, {'68', 'ARM',   'N', ' ', 'GESTAO DE ARMAZENS GERAIS'})
	aadd (_aModulos, {'69', 'GCT',   'N', ' ', 'GESTAO DE CONTRATOS'})
	aadd (_aModulos, {'70', 'ORG',   'N', ' ', 'ARQUITETURA ORGANIZACIONAL'})
	aadd (_aModulos, {'71', 'LVE',   'N', ' ', 'LOCACAO DE VEICULOS'})
	aadd (_aModulos, {'72', 'PHOTO', 'N', ' ', 'PHOTO'})
	aadd (_aModulos, {'73', 'CRM',   'N', ' ', 'CRM'})
	aadd (_aModulos, {'74', 'BPM',   'N', ' ', 'BUSINESS PROCESS MANAGEMENT'})
	aadd (_aModulos, {'75', 'APON',  'N', ' ', 'APONTAMENTO / PONTO ELETRONICO'})
	aadd (_aModulos, {'76', 'JURI',  'N', ' ', 'GESTAO JURIDICA'})
	aadd (_aModulos, {'77', 'PFS',   'N', ' ', 'PRE FATURAMENTO DE SERVICO'})
	aadd (_aModulos, {'78', 'GFE',   'N', ' ', 'GESTAO DE FRETE EMBARCADOR'})
	aadd (_aModulos, {'79', 'SFC',   'N', ' ', 'CHAO DE FABRICA'})
	aadd (_aModulos, {'80', 'ACV',   'N', ' ', 'ACESSIBILIDADE VISUAL'})
	aadd (_aModulos, {'81', 'LOG',   'N', ' ', 'MONITORAMENTO DE DESEMPENHO LOGISTICO'})
	aadd (_aModulos, {'82', 'DPR',   'N', ' ', 'DESENVOLVEDOR DE PRODUTOS'})
	aadd (_aModulos, {'83', 'VPON',  'N', ' ', 'MONITORAMENTO DE APONTAMENTOS'})
	aadd (_aModulos, {'84', 'TAF',   'S', 'N', 'TOTVS AUTOMACAO FISCAL'})
	aadd (_aModulos, {'85', 'ESS',   'N', ' ', 'EASY SISCOSERV'})
	aadd (_aModulos, {'86', 'VDF',   'N', ' ', 'VIDA FUNCIONAL'})
	aadd (_aModulos, {'87', 'GCP',   'N', ' ', 'GESTAO DE LICITACOES'})
	aadd (_aModulos, {'88', 'GTP',   'N', ' ', 'GESTAO DE TRANSPORTE DE PASSAGEIROS'})
	aadd (_aModulos, {'89', 'PDS',   'N', ' ', 'PROMOCAO DA SAUDE'})
	aadd (_aModulos, {'90', 'GCV',   'N', ' ', 'GESTAO COMERCIAL DO VAREJO'})
	aadd (_aModulos, {'96', 'ESP2',  'N', ' ', 'ESPECIFICOS 2'})
	aadd (_aModulos, {'97', 'ESP',   'S', 'N', 'COOPERATIVA-ESPECIFICO'})
	aadd (_aModulos, {'98', 'ESP1',  'N', ' ', 'ESPECIFICOS 1'})
	aadd (_aModulos, {'99', 'CFG',   'S', 'N', 'CONFIGURADOR'})
	for _nModulo = 1 to len (_aModulos)
		_aIns = {}
		aadd (_aIns, {"ID_MODULO", _aModulos [_nModulo, 1]})
		aadd (_aIns, {"SIGLA",     _aModulos [_nModulo, 2]})
		aadd (_aIns, {"USADO",     _aModulos [_nModulo, 3]})
		aadd (_aIns, {"VERTICAL",  _aModulos [_nModulo, 4]})
		aadd (_aIns, {"DESCRICAO", _aModulos [_nModulo, 5]})
		_oSQL := ClsSQL ():New ()
		_oSQL:InsValues ("VA_USR_MODULOS", _aIns)
	next


	// Percorre lista dos usuarios
	_aUsers := aclone (FwSfAllUsers ())
	procregua (len (_aUsers))
	PswOrder(1)
	for _nUser = 2 to len (_aUsers)  // Usuario 1 = 000000 (Administrador)
		incproc (_aUsers [_nUser, 2]) 
		
//		// Filtra apenas um usuario, para testes.
//		if ! _aUsers [_nUser, 2] $ '000245/000210'
//			loop
//		endif
		
		_sID := _aUsers [_nUser, 2]
		
		u_log2 ('info', 'Lendo usuario ' + _sID)
		if PswSeek (_sID, .T.)
			_aPswRet := PswRet ()
		//	u_log2 ('debug', _aPswRet)
		//	u_log2 ('debug', _aPswRet [1, 14])

			// PARECE QUE NAO GERA NADA: u_log ('fwgetmnuaccess:', fwgetmnuaccess ('000210'))

			// Popula tabela de usuarios.
			_sRegraGrp = FWUsrGrpRule (_sID)
			_sRegraGrp = iif (_sRegraGrp == '1', 'P', iif (_sRegraGrp == '2', 'D', iif (_sRegraGrp == '3', 'S', '')))  // Prioriza / Desconsidera / Soma
			_aUltLogin = aclone (FWUsrUltLog (_sID))
			//U_LOG2 ('DEBUG'	, _aUltLogin)
			_aIns = {}
			aadd (_aIns, {"ID_USR",                    _sID})
			aadd (_aIns, {"NOME",                      alltrim (upper (_aPswRet [1, 2]))})  // setor=12; email=14;dias para troca de senha=7;troca senha prox.logon=9;digitos para o ano(2/4)=18;superiores=11 (em formato 000000|000001|...)
			aadd (_aIns, {"AC_SIMULT",                 _aPswRet [1, 15]})
			aadd (_aIns, {"BLOQUEADO",                 iif (_aPswRet [1, 17], 'S', 'N')})
			aadd (_aIns, {"REGRA_GRUPO",               _sRegraGrp})
			if len (_aUltLogin) > 0  // Com os SX no banco de dados, precisa da lib 20200727
				aadd (_aIns, {"ULT_LOGIN_DATA",            dtos (_aUltLogin [1])})
				aadd (_aIns, {"ULT_LOGIN_HORA",            left (_aUltLogin [2], 5)})
				aadd (_aIns, {"ULT_LOGIN_ESTACAO",         left (_aUltLogin [4], 15)})
			endif
			aadd (_aIns, {"CONFIGURA_DATA_BASE",       iif (_aPswRet [1, 23, 1], 'S', 'N')})
			aadd (_aIns, {"DIAS_RETROCEDER_DATA_BASE", _aPswRet [1, 23, 2]})
			aadd (_aIns, {"DIAS_AVANCAR_DATA_BASE",    _aPswRet [1, 23, 3]})
			aadd (_aIns, {"CARGO",                     _aPswRet [1, 13]})
			_oSQL := ClsSQL ():New ()
			_oSQL:InsValues ("VA_USR_USUARIOS", _aIns)

			// Popula tabela de grupos (do configurador) aos quais o usuario pertence.
			_aGrupos = aclone (UsrRetGrp (_sID))
			for _nGrupo = 1 to len (_aGrupos)
				_aIns = {}
				aadd (_aIns, {"ID_USR",     _sID})
				aadd (_aIns, {"TIPO_GRUPO", 'CFG'})
				aadd (_aIns, {"ID_GRUPO",   _aGrupos [_nGrupo]})
				_oSQL := ClsSQL ():New ()
				_oSQL:InsValues ("VA_USR_GRUPOS_POR_USUARIO", _aIns)
			next

			// Popula tabela de grupos (customizados) aos quais o usuario pertence.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT DISTINCT ZZU_GRUPO"
			_oSQL:_sQuery += " FROM " + RetSQLName ("ZZU")
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND ZZU_USER   = '" + _sID + "'"
			_aRetQry := aclone (_oSQL:Qry2Array ())
			for _nRetQry = 1 to len (_aRetQry)
				_aIns = {}
				aadd (_aIns, {"ID_USR",     _sID})
				aadd (_aIns, {"TIPO_GRUPO", 'ZZU'})
				aadd (_aIns, {"ID_GRUPO",   _aRetQry [_nRetQry, 1]})
				_oSQL := ClsSQL ():New ()
				_oSQL:InsValues ("VA_USR_GRUPOS_POR_USUARIO", _aIns)
			next


			// Popula tabela de filiais acessadas pelo usuario. Verifica se deve ler do usuario, do(s) grupo(s) ou de ambos.
			_lTodasEmp = .F.
			_aEmpFil = {}
			//
			// Pelos meus testes: D/S -> busca soh do usuario; P -> soma os grupos. Vai saber...
			if _sRegraGrp $ 'D/S'
				if len (_aPswRet [2, 6]) == 1 .and. _aPswRet [2, 6, 1] == '@@@@'  // Todas as empresas e filiais
					_lTodasEmp = .T.
				else
					for _nFilial = 1 to len (_aPswRet [2, 6])
						aadd (_aEmpFil, {substr (_aPswRet [2, 6, _nFilial], 1, 2), substr (_aPswRet [2, 6, _nFilial], 3, 2)})
					next
				endif
			elseif _sRegraGrp $ 'P'
				for _nGrupo = 1 to len (_aGrupos)
					_aGrpEmp = aclone (FwGrpEmp (_aGrupos [_nGrupo]))
					if len (_aGrpEmp) == 1 .and. _aGrpEmp [1] == '@@@@'  // Todas as empresas e filiais
						_lTodasEmp = .T.
						exit
					endif
					for _nGrpEmp = 1 to len (_aGrpEmp)
						aadd (_aEmpFil, {substr (_aGrpEmp [_nGrpEmp], 1, 2), substr (_aGrpEmp [_nGrpEmp], 3, 2)})
					next
				next
			endif
			if _lTodasEmp
				_aAreaSM0 = sm0 -> (getarea ())
				sm0 -> (dbgotop ())
				do while ! sm0 -> (eof ())
					aadd (_aEmpFil, {sm0 -> m0_codigo, sm0 -> m0_codfil})
					sm0 -> (dbskip ())
				enddo
				restarea (_aAreaSM0)
			endif
			//
			// Como foi feita leitura de mais de um local, pode haver duplicidade.
		//	_aEmpFil = aclone (_oAUtil:Distinct (_aEmpFil))
			_aEmpFil = aclone (_oAUtil:Distinto (_aEmpFil))
			for _nEmpFil = 1 to len (_aEmpFil)
				_aIns = {}
				aadd (_aIns, {"ID_USR",    _sID})
				aadd (_aIns, {"EMPRESA",   _aEmpFil [_nEmpFil, 1]})
				aadd (_aIns, {"FILIAL",    _aEmpFil [_nEmpFil, 2]})
				_oSQL := ClsSQL ():New ()
				_oSQL:InsValues ("VA_USR_FILIAIS_USUARIO", _aIns)
			next


			// Popula tabela de modulos / menus acessados pelo usuario.
			// Criterio para verificar qual o menu usado, segundo TDN (http://tdn.totvs.com/pages/releaseview.action;jsessionid=A9602D97725DC2F4D3B614EA04C3048A?pageId=73080995)
			//    Priorizar: Se 1 um grupo estiver marcado para priorizar somente seu menu ser� utilizado, caso contr�rio utilizar� o menu do �ltimo grupo cadastrado que tiver acesso ao m�dulo.
			//    Somar: Utilizar� o menu do �ltimo grupo cadastrado que tiver acesso ao m�dulo.
			//    Se n�o tiver acesso pelo grupo verifica menu do usu�rio.
			_aMenus = {}
			// Busca os modulos por grupo
			if _sRegraGrp $ 'P/S'  // Prioriza/soma
				for _nGrupo = 1 to len (_aGrupos)
					if _sRegraGrp == 'P' .and. _nGrupo > 1  // 1=Prioriza. Como nao consegui descobrir qual o grupo prioritario, vou convencionar que seja sempre o primeiro.
						loop
					endif
					_aGrpMenu = aclone (FwGrpMenu (_aGrupos [_nGrupo]))  // https://tdn.totvs.com/display/public/PROT/TVYARN_DT_FWGrpMenu
				//	u_log2 ('aviso', 'olhar aqui se tem X na 3a posicao!!!')
					//u_log ('fwgrpmenu de '+ _aGrupos [_nGrupo], _aGrpMenu)
					for _nGrpMenu = 1 to len (_aGrpMenu)
						if substr (_aGrpMenu [_nGrpMenu], 3, 1) != 'X'
							_nMenu = ascan (_aMenus, {|_aVal| _aVal [1] == substr (_aGrpMenu [_nGrpMenu], 1, 2)})
							if _nMenu == 0
								// u_log ('Considerando menu do modulo', substr (_aGrpMenu [_nGrpMenu], 1, 2), 'cfe. grupo', _aGrupos [_nGrupo])
								aadd (_aMenus, {'', '', '', ''})
								_nMenu = len (_aMenus)
							endif
							_aMenus [_nMenu, 1] = substr (_aGrpMenu [_nGrpMenu], 1, 2)
							_aMenus [_nMenu, 2] = substr (_aGrpMenu [_nGrpMenu], 3, 1)
							_aMenus [_nMenu, 3] = substr (_aGrpMenu [_nGrpMenu], 4)
							_aMenus [_nMenu, 4] = 'Acessos do grupo ' + _aGrupos [_nGrupo] + ' - ' + alltrim (GrpRetName (_aGrupos [_nGrupo]))
						endif
					next
					// u_log ('Menus cfe grupo ' + _aGrupos [_nGrupo], _aMenus)
				next
			endif
			if _sRegraGrp $ 'D/S'  // Soma: neste caso preciso ler, tambem, os acessos do usuario
				for _nModulo = 1 to len (_aPswRet [3])
					if substr (_aPswRet [3, _nModulo], 3, 1) != 'X'
						if ascan (_aMenus, {|_aVal| _aVal [1] == substr (_aPswRet [3, _nModulo], 1, 2)}) == 0
							// u_log ('Considerando menu do modulo', substr (_aPswRet [3, _nModulo], 1, 2), 'cfe. acessos do usuario.')
							aadd (_aMenus, {substr (_aPswRet [3, _nModulo], 1, 2), substr (_aPswRet [3, _nModulo], 3, 1), substr (_aPswRet [3, _nModulo], 4), 'Acessos do usuario'})
						endif
					endif
				next
			endif
			// u_log ('menus no final:', _amenus)
			for _nMenu = 1 to len (_aMenus)
				_aIns = {}
				aadd (_aIns, {"ID_USR",        _sID})
				aadd (_aIns, {"ID_MODULO",     _aMenus [_nMenu, 1]})
				aadd (_aIns, {"NIVEL",         _aMenus [_nMenu, 2]})
				aadd (_aIns, {"ARQ_MENU",      upper (alltrim (_aMenus [_nMenu, 3]))})
				aadd (_aIns, {"ORIGEM_ACESSO", _aMenus [_nMenu, 4]})
				_oSQL := ClsSQL ():New ()
				_oSQL:InsValues ("VA_USR_MODULOS_USUARIO", _aIns)
			next


			// Popula tabela de acessos do usuario.
			_aAcessos = {}
			if _sRegraGrp $ 'P/S'
				for _nGrupo = 1 to len (_aGrupos)
					//u_log ('Lendo acessos do grupo', _aGrupos [_nGrupo])
					if _sRegraGrp == 'P' .and. _nGrupo > 1  // 1=Prioriza. Como nao consegui descobrir qual o grupo prioritario, vou convencionar que seja sempre o primeiro.
						//u_log ('loop')
						loop
					endif
					_sAcessos = FWGrpAcess (_aGrupos [_nGrupo])
					//u_log ('fwgrpaccess do grupo ', _aGrupos [_nGrupo], _sAcessos)
					for _nAcesso = 1 to len (_aAcesList)
						if substr (_sAcessos, _nAcesso, 1) == 'S' .and. ascan (_aAcessos, {|_aVal| _aVal [1] == _nAcesso}) == 0
							aadd (_aAcessos, {_nAcesso, _aAcesList [_nAcesso, 2], 'Acessos do grupo ' + _aGrupos [_nGrupo] + ' - ' + alltrim (GrpRetName (_aGrupos [_nGrupo]))})
							//u_log (_aAcessos)
						endif
					next
				next
			endif
			if _sRegraGrp $ 'D/S'
				_sAcessos = _aPswRet [2, 5]
				//u_log ('fwgrpaccess do usuario ', _sAcessos)
				for _nAcesso = 1 to len (_aAcesList)
					if substr (_sAcessos, _nAcesso, 1) == 'S' .and. ascan (_aAcessos, {|_aVal| _aVal [1] == _nAcesso}) == 0
						aadd (_aAcessos, {_nAcesso, _aAcesList [_nAcesso, 2], 'Acessos do usuario'})
					endif
				next
			endif
			_aAcessos = asort (_aAcessos,,, {|_x, _y| _x [1] < _y [1]})
			//u_log (_aAcessos)
			for _nAcesso = 1 to len (_aAcessos)
				_aIns = {}
				aadd (_aIns, {"ID_USR",        _sID})
				aadd (_aIns, {"TIPO_ACESSO",   'CFG'})
				aadd (_aIns, {"ACESSO",        strzero (_aAcessos [_nAcesso, 1], 3)})
				aadd (_aIns, {"ORIGEM_ACESSO", _aAcessos [_nAcesso, 3]})
				_oSQL := ClsSQL ():New ()
				_oSQL:InsValues ("VA_USR_ACESSOS_POR_USUARIO", _aIns)
			next
				
			//u_log (_aPswRet)
			
		endif
	next
	
	// Leitura dos menus dos usuarios e populacao da tabela de rotinas por menu
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " SELECT DISTINCT ARQ_MENU "
	_oSQL:_sQuery += " FROM VA_USR_MODULOS_USUARIO"
	_aMenus = aclone (_oSQL:Qry2Array ())
	for _nMenu = 1 to len (_aMenus)
		_LeMenu (_aMenus [_nMenu, 1])
	next

	// Insere na tabela de rotinas alguns casos que foram substituidos por 'user functions' nos menus.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "insert into VA_USR_ROTINAS (ROTINA, DESCRICAO) VALUES ('MATA330', 'RECALCULO CUSTO MEDIO')"
	_oSQL:Exec ()
return



// --------------------------------------------------------------------------
// Cria tabela no banco de dados.
static function _CriaTab (_sTabela, _aCampos, _aIndices, _lRecria)
	local _nCampo   := 0
	local _nIndice  := 0
	local _oSQL     := NIL

	_oSQL := ClsSQL ():New ()
	if _lRecria
		_oSQL:_sQuery = "select count (*) from sysobjects where name = '" + _sTabela + "' and type = 'U'"
		if _oSQL:RetQry() > 0
			_oSQL:_sQuery = "DROP TABLE " + _sTabela
			_oSQL:Exec ()
		endif
	endif

	_oSQL:_sQuery = "select count (*) from sysobjects where name = '" + _sTabela + "' and type = 'U'"
	if _oSQL:RetQry() == 0
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "CREATE TABLE " + _sTabela + " ("
		for _nCampo = 1 to len (_aCampos)
			_oSQL:_sQuery += _aCampos [_nCampo] + iif (_nCampo < len (_aCampos), ',', ');')
		next
		if _oSQL:Exec ()
			for _nIndice = 1 to len (_aIndices)
				_oSQL:_sQuery := "CREATE " + iif (_nIndice > 1, "NON", "") + "CLUSTERED INDEX IDX" + cvaltochar (_nIndice) + " ON " + _sTabela + "(" + _aIndices [_nIndice] + ");"
				_oSQL:Exec ()
			next
		endif
	endif
return



// --------------------------------------------------------------------------
static function _LeMenu (_sArqMenu)
	local _aArqTrb  := {}
	local _aRotMenu := {}
	local _nRotMenu := {}
	local _aIns     := {}
	local _aRotinas := {}
	local _nRotina  := 0

	u_log ('Lendo menu ', _sArqMenu)
	if ! file (_sArqMenu)
		u_LOG2 ('aviso', "Arquivo '" + _sArqMenu + "' nao encontrado.")
	else
		U_ArqTrb ('Cria', '_trb', {{"linha", "C", 250, 0}}, {}, @_aArqTrb)
		append from (_sArqMenu) SDF
		_trb -> (dbgotop ())
		if alltrim (_trb -> linha) != '<ApMenu>'
			u_log ('Arquivo de menu invalido: ' + _sArqMenu)
		else
			do while ! _trb -> (eof ())
				_trb -> linha = upper (strtran (_trb -> linha, chr (9), '    '))  // remove TAB
				_trb -> (dbskip ())
			enddo
			_trb -> (dbgotop ())
			do while ! _trb -> (eof ())
				if 'MENU STATUS' $ _trb -> linha
					_LeNivel (@_aRotMenu, (! 'DISABLE' $ _trb -> linha), 1)
				endif
				_trb -> (dbskip ())
			enddo
		endif
		U_ArqTrb ('FechaTodos',,,, @_aArqTrb)
	endif
	//u_log (_aRotMenu)
	for _nRotMenu = 1 to len (_aRotMenu)
		_aIns = {}
		aadd (_aIns, {"ARQ_MENU",   upper (alltrim (_sArqMenu))})
		aadd (_aIns, {"ROTINA",     _aRotMenu [_nRotMenu, 1]})
		aadd (_aIns, {"HABILITADA", _aRotMenu [_nRotMenu, 3]})
		aadd (_aIns, {"TIPO",       _aRotMenu [_nRotMenu, 4]})
		aadd (_aIns, {"ID_MODULO",  _aRotMenu [_nRotMenu, 5]})
		aadd (_aIns, {"ACESSOS",    _aRotMenu [_nRotMenu, 6]})
		_oSQL := ClsSQL ():New ()
		_oSQL:InsValues ("VA_USR_ROTINAS_POR_MENU", _aIns)
		
		if ascan (_aRotinas, {|_aVal| _aVal [1] == alltrim (_aRotMenu [_nRotMenu, 1])}) == 0
			aadd (_aRotinas, {alltrim (_aRotMenu [_nRotMenu, 1]), alltrim (strtran (_aRotMenu [_nRotMenu, 2], "'", ""))})
		endif
	next
	
	// Insere na tabela de rotinas o que encontrou neste menu.
	// Dica para evitar duplicidade: http://stackoverflow.com/questions/3407857/only-inserting-a-row-if-its-not-already-there/3408196#3408196
	_oSQL := ClsSQL ():New ()
	for _nRotina = 1 to len (_aRotinas)
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " INSERT INTO VA_USR_ROTINAS "
		_oSQL:_sQuery += " SELECT '" + _aRotinas [_nRotina, 1] + "', "
		_oSQL:_sQuery +=         "'" + _aRotinas [_nRotina, 2] + "'"
		_oSQL:_sQuery +=  " WHERE NOT EXISTS (SELECT 0
		_oSQL:_sQuery +=                      " FROM VA_USR_ROTINAS WITH (UPDLOCK, HOLDLOCK) "
		_oSQL:_sQuery +=                     " WHERE ROTINA = '" + _aRotinas [_nRotina, 1] + "')"
		_oSQL:Exec ()
	next
return _aRotMenu



// --------------------------------------------------------------------------
static function _LeNivel (_aRotMenu, _lEnabled, _nNivel)
	local _sTitle    := ''
	local _sFunction := ''
	local _sType     := ''
	local _sModule   := ''
	local _sAccess   := ''

	_trb -> (dbskip ())  // Avanca para o registro inicial da secao.
	//u_log ('lendo nivel', _nNivel, alltrim (_trb -> linha), _lEnabled)
	do while ! _trb -> (eof ()) .and. alltrim (_trb -> linha) != '</MENU>' .and. alltrim (_trb -> linha) != '</MENUITEM>'
		if 'MENU STATUS' $ _trb -> linha .or. 'MENUITEM STATUS' $ _trb -> linha
			_LeNivel (@_aRotMenu, _lEnabled .and. (! 'DISABLE' $ _trb -> linha), _nNivel + 1)
		endif
		if '<TITLE LANG="PT">' $ _trb -> linha
			_sTitle = alltrim (strtran (strtran (_trb -> linha, '<TITLE LANG="PT">', ''), '</TITLE>', ''))
		endif
		if '<FUNCTION>' $ _trb -> linha
			_sFunction = alltrim (strtran (strtran (_trb -> linha, '<FUNCTION>', ''), '</FUNCTION>', ''))
		endif
		if '<TYPE>' $ _trb -> linha
			_sType = alltrim (strtran (strtran (_trb -> linha, '<TYPE>', ''), '</TYPE>', ''))
		endif
		if '<MODULE>' $ _trb -> linha
			_sModule = alltrim (strtran (strtran (_trb -> linha, '<MODULE>', ''), '</MODULE>', ''))
		endif
		if '<ACCESS>' $ _trb -> linha
			_sAccess = alltrim (strtran (strtran (_trb -> linha, '<ACCESS>', ''), '</ACCESS>', ''))
		endif
		_trb -> (dbskip ())
	enddo
	if ! empty (_sFunction)
		aadd (_aRotMenu, {_sFunction, _sTitle, iif (_lEnabled, 'S', 'N'), _sType, _sModule, _sAccess})
	endif
return



// --------------------------------------------------------------------------
static function _AtuZZU ()
	local _aUsers := aclone (FwSfAllUsers ())
	local _nUser  := 0

	procregua (zzu -> (reccount ()))
	incproc ()
	zzu -> (dbgotop ())
	do while ! zzu -> (eof ())
		if ! '*' $ zzu -> zzu_user
			_nUser = ascan (_aUsers, {| _aVal | _aVal [2] == zzu -> zzu_user})
			if _nUser == 0
				u_log2 ('erro', 'Usuario ' + zzu -> zzu_user + ' (encontrado no campo ZZU_USER) nao encontrado na funcao FwSfAllUsers.')
			else
				reclock ("ZZU", .F.)
				zzu -> zzu_nome  = upper (_aUsers [_nUser, 3])
				zzu -> zzu_email = _aUsers [_nUser, 5]
				msunlock ()
			endif
		endif
		zzu -> (dbskip ())
	enddo
return



// --------------------------------------------------------------------------
// Atualiza, na tabela de acessos, quais sao os modulos afetados por cada acesso.
static function _AtuAces ()
	local _oSQL := NIL
	local _aAcesMod := {}
	local _nAcesMod := 0

	// Apenas para os acessos do configurador. Os do ZZU jah vai estar cadastrado no ZZU.
	aadd (_aAcesMod, {  1, 'EST'})  // EXCLUIR PRODUTOS
	aadd (_aAcesMod, {  2, 'EST'})  // ALTERAR PRODUTOS
	aadd (_aAcesMod, {  3, 'EST,COM'})  // EXCLUIR CADASTROS
	aadd (_aAcesMod, {  4, 'COM'})  // ALTERAR SOLICIT COMPRAS
	aadd (_aAcesMod, {  5, 'COM'})  // EXCLUIR SOLICIT COMPRAS
	aadd (_aAcesMod, {  6, 'COM'})  // ALTERAR PEDIDOS COMPRAS
	aadd (_aAcesMod, {  7, 'COM'})  // EXCLUIR PEDIDOS COMPRAS
	aadd (_aAcesMod, {  8, 'COM'})  // ANALISAR COTAçOES
	aadd (_aAcesMod, {  9, ''})  // RELAT FICHA CADASTRAL
	aadd (_aAcesMod, { 10, 'FIN'})  // RELAT BANCOS
	aadd (_aAcesMod, { 11, 'COM'})  // RELACAO SOLICIT COMPRAS
	aadd (_aAcesMod, { 12, 'COM'})  // RELACAO DE PEDIDOS COMPRA
	aadd (_aAcesMod, { 13, 'EST,PCP'})  // ALTERAR ESTRUTURAS
	aadd (_aAcesMod, { 14, 'EST,PCP'})  // EXCLUIR ESTRUTURAS
	aadd (_aAcesMod, { 15, 'EST,FIN,FAT,COM,FIS'})  // ALTERAR TES
	aadd (_aAcesMod, { 16, 'EST,FIN,FAT,COM,FIS'})  // EXCLUIR TES
	aadd (_aAcesMod, { 17, 'EST,CTB'})  // INVENTARIO
	aadd (_aAcesMod, { 18, 'CTB'})  // FECHAMENTO MENSAL
	aadd (_aAcesMod, { 19, 'EST,CTB'})  // PROC DIFERENCA INVENTARIO
	aadd (_aAcesMod, { 20, 'FAT'})  // ALTERAR PEDIDOS DE VENDA
	aadd (_aAcesMod, { 21, 'FAT'})  // EXCLUIR PEDIDOS DE VENDA
	aadd (_aAcesMod, { 22, 'CFG'})  // ALTERAR HELP`S
	aadd (_aAcesMod, { 23, 'FIN'})  // SUBSTITUIçäO DE TìTULOS
	aadd (_aAcesMod, { 24, 'CFG'})  // INCLUSäO DO DADOS VIA F3
	aadd (_aAcesMod, { 25, 'LOJA'})  // ROTINA DE ATENDIMENTO
	aadd (_aAcesMod, { 26, 'LOJA'})  // PROC. TROCO
	aadd (_aAcesMod, { 27, 'LOJA'})  // PROC. SANGRIA
	aadd (_aAcesMod, { 28, 'FIN'})  // BORDERô CHEQUES PRé-DAT.
	aadd (_aAcesMod, { 29, 'FIN'})  // ROTINA DE PAGAMENTO
	aadd (_aAcesMod, { 30, 'FIN'})  // ROTINA DE RECEBIMENTO
	aadd (_aAcesMod, { 31, 'LOJA'})  // TROCA DE MERCADORIAS
	aadd (_aAcesMod, { 32, ''})  // ACESSO TABELA DE PRECOS
	aadd (_aAcesMod, { 33, ''})  // NãO UTILIZADO
	aadd (_aAcesMod, { 34, ''})  // NãO UTILIZADO
	aadd (_aAcesMod, { 35, ''})  // ACESSO CONDICAO NEGOCIADA
	aadd (_aAcesMod, { 36, 'EST,FIN,FAT,COM,FIS'})  // ALTERAR DATABASE DO SIST.
	aadd (_aAcesMod, { 37, 'EST,PCP'})  // ALTERAR EMPENHOS DE OPS.
	aadd (_aAcesMod, { 38, ''})  // NãO UTILIZADO
	aadd (_aAcesMod, { 39, 'FAT'})  // FORM.PREçOS TODOS NíVEIS
	aadd (_aAcesMod, { 40, 'LOJA'})  // CONFIGURA VENDA RAPIDA
	aadd (_aAcesMod, { 41, 'LOJA'})  // ABRIR/FECHAR CAIXA
	aadd (_aAcesMod, { 42, 'LOJA'})  // EXCLUIR NOTA/ORç. LOJA
	aadd (_aAcesMod, { 43, 'ATF.CTB'})  // ALTERAR BEM ATIVO FIXO
	aadd (_aAcesMod, { 44, 'ATF.CTB'})  // EXCLUIR BEM ATIVO FIXO
	aadd (_aAcesMod, { 45, 'ATF.CTB'})  // INCLUIR BEM VIA COPIA
	aadd (_aAcesMod, { 46, ''})  // TX JUROS CONDIC NEGOCIADA
	aadd (_aAcesMod, { 47, 'LOJA'})  // LIBERACAO VENDA FORCAD TEF
	aadd (_aAcesMod, { 48, 'LOJA'})  // CANCELAMENTO VENDA TEF
	aadd (_aAcesMod, { 49, 'FIN,FAT,COM'})  // CADASTRA MOEDA NA ABERTURA
	aadd (_aAcesMod, { 50, 'FIS'})  // ALTERAR NUM. DA NF
	aadd (_aAcesMod, { 51, 'CTB,EST,FIS,FAT'})  // EMITIR NF RETROATIVA
	aadd (_aAcesMod, { 52, 'FIN'})  // EXCLUIR BAIXA - RECEBER
	aadd (_aAcesMod, { 53, 'FIN'})  // EXCLUIR BAIXA - PAGAR
	aadd (_aAcesMod, { 54, ''})  // INCLUIR TABELAS
	aadd (_aAcesMod, { 55, ''})  // ALTERAR TABELAS
	aadd (_aAcesMod, { 56, ''})  // EXCLUIR TABELAS
	aadd (_aAcesMod, { 57, ''})  // INCLUIR CONTRATOS
	aadd (_aAcesMod, { 58, ''})  // ALTERAR CONTRATOS
	aadd (_aAcesMod, { 59, ''})  // EXCLUIR CONTRATOS
	aadd (_aAcesMod, { 60, 'COM,EST'})  // USO INTEGRAçäO SIGAEIC
	aadd (_aAcesMod, { 61, 'FIN'})  // INCLUIR EMPRESTIMO
	aadd (_aAcesMod, { 62, 'FIN'})  // ALTERAR EMPRESTIMO
	aadd (_aAcesMod, { 63, 'FIN'})  // EXCLUIR EMPRESTIMO
	aadd (_aAcesMod, { 64, 'FIN'})  // INCLUIR LEASING
	aadd (_aAcesMod, { 65, 'FIN'})  // ALTERAR LEASING
	aadd (_aAcesMod, { 66, 'FIN'})  // EXCLUIR LEASING
	aadd (_aAcesMod, { 67, 'FIN'})  // INCLUIR IMP.NAO FINANC.
	aadd (_aAcesMod, { 68, 'FIN'})  // ALTERAR IMP.NAO FINANC.
	aadd (_aAcesMod, { 69, 'FIN'})  // EXCLUIR IMP.NAO FINANC.
	aadd (_aAcesMod, { 70, 'FIN'})  // INCLUIR IMP.FINANCIADA
	aadd (_aAcesMod, { 71, 'FIN'})  // ALTERAR IMP.FINANCIADA
	aadd (_aAcesMod, { 72, 'FIN'})  // EXCLUIR IMP.FINANCIADA
	aadd (_aAcesMod, { 73, 'FIN'})  // INCLUIR IMP.FIN.EXPORT.
	aadd (_aAcesMod, { 74, 'FIN'})  // ALTERAR IMP.FIN.EXPORT.
	aadd (_aAcesMod, { 75, 'FIN'})  // EXCLUIR IMP.FIN.EXPORT.
	aadd (_aAcesMod, { 76, ''})  // INCLUIR CONTRATO
	aadd (_aAcesMod, { 77, ''})  // ALTERAR CONTRATO
	aadd (_aAcesMod, { 78, ''})  // EXCLUIR CONTRATO
	aadd (_aAcesMod, { 79, ''})  // LANCAR TAXA LIBOR
	aadd (_aAcesMod, { 80, 'CTB'})  // CONSOLIDAR EMPRESAS
	aadd (_aAcesMod, { 81, ''})  // INCLUIR CADASTROS
	aadd (_aAcesMod, { 82, ''})  // ALTERAR CADASTROS
	aadd (_aAcesMod, { 83, 'FIN,COM,CTB'})  // INCLUIR COTACAO MOEDAS
	aadd (_aAcesMod, { 84, 'FIN,COM,CTB'})  // ALTERAR COTACAO MOEDAS
	aadd (_aAcesMod, { 85, 'FIN,COM,CTB'})  // EXCLUIR COTACAO MOEDAS
	aadd (_aAcesMod, { 86, ''})  // INCLUIR CORRETORAS
	aadd (_aAcesMod, { 87, ''})  // ALTERAR CORRETORAS
	aadd (_aAcesMod, { 88, ''})  // EXCLUIR CORRETORAS
	aadd (_aAcesMod, { 89, ''})  // INCLUIR IMP./EXP./CONS
	aadd (_aAcesMod, { 90, ''})  // ALTERAR IMP./EXP./CONS
	aadd (_aAcesMod, { 91, ''})  // EXCLUIR IMP./EXP./CONS
	aadd (_aAcesMod, { 92, ''})  // BAIXA SOLICITACOES
	aadd (_aAcesMod, { 93, ''})  // VISUALIZA ARQUIVO LIMITE
	aadd (_aAcesMod, { 94, ''})  // IMPRIME  DOCTOS.CANCELADOS
	aadd (_aAcesMod, { 95, ''})  // REATIVA  DOCTOS.CANCELADOS
	aadd (_aAcesMod, { 96, ''})  // CONSULTA DOCTOS.OBSOLETOS
	aadd (_aAcesMod, { 97, ''})  // IMPRIME  DOCTOS.OBSOLETOS
	aadd (_aAcesMod, { 98, ''})  // CONSULTA DOCTOS.VENCIDOS
	aadd (_aAcesMod, { 99, ''})  // IMPRIME  DOCTOS.VENCIDOS
	aadd (_aAcesMod, {100, ''})  // DEF. LAUDO FINAL ENTREGA
	aadd (_aAcesMod, {101, ''})  // IMPRIME PARAM RELATORIOS
	aadd (_aAcesMod, {102, ''})  // TRANSFERE PENDENCIAS
	aadd (_aAcesMod, {103, ''})  // USA RELATORIO POR E-MAIL
	aadd (_aAcesMod, {104, 'FAT,FIN'})  // CONSULTA POSICAO CLIENTE
	aadd (_aAcesMod, {105, ''})  // MANUTEN. AUS TEMP. TODOS
	aadd (_aAcesMod, {106, ''})  // MANUTEN. AUS. TEMP USUARIO
	aadd (_aAcesMod, {107, 'FAT'})  // FORMAçãO DE PREçO
	aadd (_aAcesMod, {108, ''})  // GRAVAR RESPOSTA PARAMETROS
	aadd (_aAcesMod, {109, ''})  // CONFIGURAR CONSULTA F3
	aadd (_aAcesMod, {110, ''})  // PERMITE ALTERAR CONFIGURAçãO DE IMPRESSORA
	aadd (_aAcesMod, {111, ''})  // GERAR REL. EM DISCO LOCAL
	aadd (_aAcesMod, {112, ''})  // GERAR REL. NO SERVIDOR
	aadd (_aAcesMod, {113, 'COM'})  // INCLUIR SOLIC. COMPRAS
	aadd (_aAcesMod, {114, ''})  // MBROWSE - VISUALIZA OUTRAS FILIAIS
	aadd (_aAcesMod, {115, ''})  // MBROWSE - EDITA REGISTROS DE OUTRAS FILIAIS
	aadd (_aAcesMod, {116, ''})  // MBROWSE - PERMITE O USO DE FILTRO
	aadd (_aAcesMod, {117, ''})  // F3 - PERMITE O USO DE FILTRO
	aadd (_aAcesMod, {118, ''})  // MBROWSE - PERMITE O USO DAS OPçõES DE CONFIGURAçãO
	aadd (_aAcesMod, {119, ''})  // ALTERA ORçAMENTO APROVADO
	aadd (_aAcesMod, {120, ''})  // REVISA ORçAMENTO APROVADO
	aadd (_aAcesMod, {121, ''})  // USA IMPRESSORA NO SERVER
	aadd (_aAcesMod, {122, ''})  // USA IMPRESSORA NO CLIENT
	aadd (_aAcesMod, {123, ''})  // AGENDAR PROCESSOS/RELATóRIOS
	aadd (_aAcesMod, {124, ''})  // PROCESSOS IDENTICOS NA MDI
	aadd (_aAcesMod, {125, ''})  // DATAS DIFERENTES NA MDI
	aadd (_aAcesMod, {126, ''})  // CAD.CLI. NO CATALOGO E-MAIL
	aadd (_aAcesMod, {127, ''})  // CAD.FOR. NO CATALOGO E-MAIL
	aadd (_aAcesMod, {128, ''})  // CAD.VEN. NO CATALOGO E-MAIL
	aadd (_aAcesMod, {129, ''})  // IMPR. INFORMACöES PERSONALIZADAS
	aadd (_aAcesMod, {130, ''})  // RESPEITA PARAMETRO MV_WFMESSE
	aadd (_aAcesMod, {131, 'EST,PCP'})  // APROVAR/REJEITAR PRE ESTRUTURA
	aadd (_aAcesMod, {132, 'EST,PCP'})  // CRIAR ESTRUTURA COM BASE EM PRé ESTRUTURA
	aadd (_aAcesMod, {133, ''})  // GERIR ETAPAS
	aadd (_aAcesMod, {134, ''})  // GERIR DESPESAS
	aadd (_aAcesMod, {135, ''})  // LIBERAR DESPESA PARA FATURAMENTO
	aadd (_aAcesMod, {136, 'FAT,FIN'})  // LIB. PED. VENDA (CREDITO)
	aadd (_aAcesMod, {137, 'FAT,EXT'})  // LIB. PED. VENDA (ESTOQUE)
	aadd (_aAcesMod, {138, ''})  // HABILITAR OPçãO EXECUTAR(CTRL+R)
	aadd (_aAcesMod, {139, 'PCP,EST'})  // PERMITE INCLUIR ORDEM DE PRODUçãO
	aadd (_aAcesMod, {140, ''})  // ACESSO VIA ACTIVEX
	aadd (_aAcesMod, {141, 'ATF,CTB'})  // EXCLUIR BENS
	aadd (_aAcesMod, {142, 'CTB'})  // RATEIO DO ITEM POR CENTO DE CUSTO
	aadd (_aAcesMod, {143, 'FAT'})  // ALTERAR O CADASTRO DE CLIENTES
	aadd (_aAcesMod, {144, 'FAT'})  // EXCLUIR CADASTRO DE CLIENTES
	aadd (_aAcesMod, {145, ''})  // HABILITAR FILTROS NOS RELATóRIOS
	aadd (_aAcesMod, {146, ''})  // CONTATOS NO CATALOGO E-MAIL
	aadd (_aAcesMod, {147, ''})  // CRIAR FORMULAS NOS RELATORIOS
	aadd (_aAcesMod, {148, ''})  // PERSONALIZAR RELATóRIOS
	aadd (_aAcesMod, {149, ''})  // ACESSO AO CADASTRO DE LOTES
	aadd (_aAcesMod, {150, ''})  // GRAVAR RESPOSTA PARAMETROS POR EMPRESA
	aadd (_aAcesMod, {151, ''})  // MANUTENçãO NO REPOSITóRIO DE IMAGENS
	aadd (_aAcesMod, {152, ''})  // CRIAR RELATóRIOS PERSONALIZáVEIS
	aadd (_aAcesMod, {153, ''})  // PERMISSãO PARA UTILIZAR O TOII
	aadd (_aAcesMod, {154, ''})  // ACESSO AO SIGARPM
	aadd (_aAcesMod, {155, ''})  // MAIúSCULO/MINúSCULO NA CONSULTA PADRãO
	aadd (_aAcesMod, {156, ''})  // VALIDA ACESSO DO GRUPO POR EMP/FILIAL
	aadd (_aAcesMod, {157, ''})  // ACESSA BASE INSTALADA NO CAD. TéCNICOS
	aadd (_aAcesMod, {158, ''})  // DESABILITA OPçãO USUáRIOS DO MENU
	aadd (_aAcesMod, {159, ''})  // IMPRESSãO LOCAL P/ COMPONENTE GRáFICO
	aadd (_aAcesMod, {160, ''})  // IMPRESSãO EM PLANILHA
	aadd (_aAcesMod, {161, ''})  // ACESSO A SCRIPTS CONFIDENCIAIS
	aadd (_aAcesMod, {162, ''})  // QUALIFICAçãO DE SUSPECTS
	aadd (_aAcesMod, {163, ''})  // EXECUçãO DE SCRIPTS DINâMICOS
	aadd (_aAcesMod, {164, ''})  // MDI - PERMITE ENCERRAR AMBIENTE PELO X
	aadd (_aAcesMod, {165, ''})  // PERMITE UTILIZAR O WALKTHRU
	aadd (_aAcesMod, {166, ''})  // GERAçãO DE FORECAST
	aadd (_aAcesMod, {167, 'FAT,COM,FIN,FIS'})  // EXECUçãO DE MASHUPS
	aadd (_aAcesMod, {168, ''})  // PERMITE EXPORTAR PLANILHA PMS PARA EXCEL
	aadd (_aAcesMod, {169, ''})  // GRAVAR FILTRO DO BROWSE COM EMPRESA/FILIAL
	aadd (_aAcesMod, {170, ''})  // EXPORTAR TELAS PARA EXCEL (MOD1 E 3)
	aadd (_aAcesMod, {171, ''})  // SE ADMINISTRADOR, PODE UTILIZAR O SIGACFG.
	aadd (_aAcesMod, {172, ''})  // SE ADMINISTRADOR, PODE UTILIZAR O APSDU.
	aadd (_aAcesMod, {173, ''})  // SE ACESSA APSDU, é READ-WRITE
	aadd (_aAcesMod, {174, ''})  // ACESSO A INSCRIçãO NOS EVENTOS DO EVENTVIEWER
	aadd (_aAcesMod, {175, ''})  // MBROWSE - PERMITE UTILIZACãO DO LOCALIZADOR
	aadd (_aAcesMod, {176, ''})  // VISUALIZAçãO VIA F3
	aadd (_aAcesMod, {177, 'COM'})  // EXCLUIR PURCHASE ORDER
	aadd (_aAcesMod, {178, 'COM'})  // ALTERAR PURCHASE ORDER
	aadd (_aAcesMod, {179, 'COM'})  // EXCLUIR SOLICITAçãO DE IMPORTAçãO
	aadd (_aAcesMod, {180, 'COM'})  // ALTERAR SOLICITAçãO DE IMPORTAçãO
	aadd (_aAcesMod, {181, 'COM,EST'})  // EXCLUIR DESEMBARAçO
	aadd (_aAcesMod, {182, 'COM,EST'})  // ALTERAR DESEMBARAçO
	aadd (_aAcesMod, {183, 'MDT'})  // INCLUIR AGENDA MéDICA
	aadd (_aAcesMod, {184, 'MDT'})  // ALTERAR AGENDA MéDICA
	aadd (_aAcesMod, {185, 'MDT'})  // EXCLUIR AGENDA MéDICA
	aadd (_aAcesMod, {186, 'FAT,FIN,EST,COM,FIS'})  // ACESSO A FóRMULAS
	aadd (_aAcesMod, {187, ''})  // UTILIZAR CONFIG. DE IMPRESSãO NA TMSPRINTER
	aadd (_aAcesMod, {188, ''})  // MBROWSE - HABILITA IMPRESSãO
	aadd (_aAcesMod, {189, ''})  // ACESSO VIA SMARTCLIENT HTML
	aadd (_aAcesMod, {190, ''})  // GRAVA CONFIGURAçãO DO BROWSE POR EMPRESA/FILIAL
	aadd (_aAcesMod, {191, 'CTB'})  // PERMITE EFETUAR LANçAMENTOS MANUAIS ATRAVéS DA ROTINA DE LANçAMENTOS CONTáBEIS
	aadd (_aAcesMod, {192, ''})  // DADOS PESSOAIS
	aadd (_aAcesMod, {193, ''})  // DADOS SENSíVEIS

	_oSQL := ClsSQL ():New ()
	for _nAcesMod = 1 to len (_aAcesMod)
		_oSQL:_sQuery := "UPDATE VA_USR_ACESSOS"
		_oSQL:_sQuery +=   " SET MODULOS_AFETADOS = '" + _aAcesMod [_nAcesMod, 2] + "'"
		_oSQL:_sQuery += " WHERE TIPO = 'CFG' AND ACESSO = '" + strzero (_aAcesMod [_nAcesMod, 1], 3) + "'"
		_Osql:lOG ()
		_oSQL:Exec ()
	next
return
