// Programa:  LePerg
// Autor:     Robert Koch
// Data:      23/11/2016
// Descricao: Leitura (no profile do usuario) das respostas das perguntas do sistema (SX1).

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Leitura das perguntas 
// #PalavasChave      #perguntas #parametros
// #TabelasPrincipais 
// #Modulos           #

// Historico de alteracoes:
// 03/01/2016 - Robert - Ajustes gerais.
// 19/08/2020 - Robert - Leitura da tabela de acessos do usuario passa a testar, antes, se a tabela existe.
//                     - Adicionadas tags para catalogo de fontes.
//

// --------------------------------------------------------------------------
// Parametros: _sUserID = ID do usuario no configurador. Pode-se usar __cUserID.
//             _sGrupo  = Grupo de perguntas no SX1. Geralmente eh a variavel cPerg.
user function LePerg (_sUserID, _sGrupo)
	local _aRet      := {}
	local _oSQL      := NIL
	local _sChave    := ""
	local _sUserName := ""
	local _sMemoProf := ""
	local _aAreaAnt  := U_ML_SRArea ()
	local _aResp     := {}
	//local _nResp     := 0
	local _sResp     := ""
	local _lComTela  := (empty (_sUserID) .and. type ("oMainWnd") == "O")  // Se tem interface com o usuario
	local _nPerg     := 0
	local _lContinua := .T.

	u_logIni ()
	
	if empty (_sUserID) .and. _lComTela
		_sUserID = U_Get ("Codigo do usuario", 'C', 6, '', 'US1', space(6), .F., '.T.')
	endif
	if empty (_sGrupo) .and. _lComTela
		_sGrupo = U_Get ("Grupo de perguntas", 'C', 10, '', '', space(10), .F., '.T.')
	endif

	_sGrupo = padr (_sGrupo, len (sx1 -> x1_grupo), " ")
	sx1 -> (dbsetorder (1))
	if ! sx1 -> (dbseek (_sGrupo, .F.))
		u_help ("Grupo de perguntas '" + _sGrupo + "' nao encontrado na tabela SX1.")
		_lContinua = .F.
	endif
	
	if _lContinua
		PswOrder(1)
		if PswSeek (_sUserID, .T.)
			_sUserName = PswRet(1) [1, 2]
		else
			u_help ("ID '" + _sUserID + "' nao encontrado na tabela de usuarios.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		//u_log (PswRet())
		//u_log (PswRet(1))
		_oSQL := ClsSQL ():New ()
//		_oSQL:_sQuery := "SELECT COUNT (*) FROM VA_USR_ACESSOS_USUARIO WHERE ID_USR = '" + _sUserID + "' and ACESSO = '150'"  // Grava respostas por empresa.

		_oSQL:_sQuery := "select case when OBJECT_ID('VA_USR_ACESSOS_POR_USUARIO', 'U') IS NOT NULL"  // Verifica se a tabela existe.
		_oSQL:_sQuery += " then (SELECT COUNT (*) FROM VA_USR_ACESSOS_POR_USUARIO WHERE ID_USR = '" + _sUserID + "' and ACESSO = '150')"  // Grava respostas por empresa.
		_oSQL:_sQuery += " else 0 end"
		if _oSQL:RetQry () == 0
			_sChave = _sUserName
		else
			_sChave = cEmpAnt + _sUserName
		endif
		_sChave = U_TamFixo (_sChave, 15)

		// Carrega memo com o profile do usuario (o profile fica gravado em um campo memo)
		_sMemoProf := RetProfDef (_sChave, _sGrupo, "PERGUNTE", "MV_PAR")
		//u_log ('_sMemoProf=', _sMemoProf)
		if empty (_sMemoProf)
			u_log ("Profile do usuario vazio para este grupo de perguntas. Chave usada: " + _sChave + _sGrupo)
			_lContinua = .F.
		endif
	endif
	
	if _lContinua
		// Monta array com a resposta de cada pergunta
		_aResp = {}
		for _nPerg = 1 to MLCount (_sMemoProf)
			//u_log ('lendo linha >>' + MemoLine (_sMemoProf,, _nPerg) + '<<: ' + alltrim (substr (MemoLine (_sMemoProf,, _nPerg), 5)))
			aadd (_aResp, alltrim (substr (MemoLine (_sMemoProf,, _nPerg), 5)))
		next
		//u_log ('_aResp:', _aResp)

		// Monta array com cada pergunta e sua resposta em uma linha.
		do while ! sx1 -> (eof ()) .and. sx1 -> x1_grupo == _sGrupo
			if sx1 -> x1_gsc == "C"
				_sResp = cvaltochar (_aResp [val (sx1 -> x1_ordem)]) + ' [' + sx1 -> &('x1_def0' + _aResp [val (sx1 -> x1_ordem)]) + ']'
			elseif sx1 -> x1_tipo $ 'N/C'
				_sResp = _aResp [val (sx1 -> x1_ordem)]
			elseif sx1 -> x1_tipo == 'D'
				_sResp = stod (_aResp [val (sx1 -> x1_ordem)])
			else
				u_help ("Tipo de pergunta '" + sx1 -> x1_tipo + "' sem tratamento.")
				_sResp = ''
			endif
			aadd (_aRet, {_sChave, sx1 -> x1_grupo, sx1 -> x1_ordem, alltrim (sx1 -> x1_pergunt), _sResp, sx1 -> x1_def01, sx1 -> x1_def02, sx1 -> x1_def03, sx1 -> x1_def04, sx1 -> x1_def05})
			sx1 -> (dbskip ())
		enddo
	endif

	// Se chamou sem parametros (direto do menu) mostra resultado em tela.
	if _lComTela
		u_showarray (_aRet)
	endif

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return _aRet
