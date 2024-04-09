// Programa...: LePerg
// Autor......: Robert Koch
// Data.......: 23/11/2016
// Descricao..: Leitura (no profile do usuario) das respostas das perguntas do sistema (SX1).
//
// Parametros: _sUserID = ID do usuario no configurador. Pode-se usar __cUserID.
//             _sGrupo  = Grupo de perguntas no SX1. Geralmente eh a variavel cPerg.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Leitura das perguntas 
// #PalavasChave      #perguntas #parametros
// #TabelasPrincipais 
// #Modulos           #
//
// Historico de alteracoes:
// 03/01/2016 - Robert  - Ajustes gerais.
// 19/08/2020 - Robert  - Leitura da tabela de acessos do usuario passa a testar, antes, se a tabela existe.
//                      - Adicionadas tags para catalogo de fontes.
// 12/05/2021 - Claudia - Ajustada a chamada SX1 para R27. GLPI: 8825
// 09/04/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//
// --------------------------------------------------------------------------

user function LePerg (_sUserID, _sGrupo)
	local _aRet      := {}
	local _oSQL      := NIL
	local _sChave    := ""
	local _sUserName := ""
	local _sMemoProf := ""
	local _aAreaAnt  := U_ML_SRArea ()
	local _aResp     := {}
	local _sResp     := ""
	local _lComTela  := (empty (_sUserID) .and. type ("oMainWnd") == "O")  // Se tem interface com o usuario
	local _nPerg     := 0
	local _lContinua := .T.
	local _x         := 0
	
	if empty (_sUserID) .and. _lComTela
		_sUserID = U_Get ("Codigo do usuario", 'C', 6, '', 'US1', space(6), .F., '.T.')
	endif

	if empty (_sGrupo) .and. _lComTela
		_sGrupo = U_Get ("Grupo de perguntas", 'C', 10, '', '', space(10), .F., '.T.')
	endif

	_oSQL  := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   X1_GRUPO "
	_oSQL:_sQuery += "    ,X1_ORDEM "
	_oSQL:_sQuery += "    ,X1_TIPO "
	_oSQL:_sQuery += "    ,X1_GSC "
	_oSQL:_sQuery += "    ,X1_PERGUNT "
	_oSQL:_sQuery += "    ,X1_DEF01 "
	_oSQL:_sQuery += "    ,X1_DEF02 "
	_oSQL:_sQuery += "    ,X1_DEF03 "
	_oSQL:_sQuery += "    ,X1_DEF04 "
	_oSQL:_sQuery += "    ,X1_DEF05 "
	_oSQL:_sQuery += " FROM SX1010 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND X1_GRUPO     = '" + _sGrupo + "'"
	_aSX1 := aclone (_oSQL:Qry2Array (.f., .f.))

	if Len(_aSX1) > 0
		PswOrder(1)
		if PswSeek (_sUserID, .T.)
			_sUserName = PswRet(1) [1, 2]
		else
			u_help ("ID '" + _sUserID + "' nao encontrado na tabela de usuarios.")
			_lContinua = .F.
		endif

		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " SELECT "
		_oSQL:_sQuery += " 		ISNULL(CONVERT(VARCHAR(2047), CONVERT(VARBINARY(2047), P_DEFS)), '') AS CONTEUDO "
		_oSQL:_sQuery += " FROM MP_SYSTEM_PROFILE"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND P_TASK = 'PERGUNTE'"
		_oSQL:_sQuery += " AND P_TYPE = 'MV_PAR'"
		_oSQL:_sQuery += " AND P_PROG = '" + _sGrupo + "'"
		_oSQL:_sQuery += " AND P_NAME IN ('" + _sUserName + "', '" + cEmpAnt + _sUserName + "', '" + _sUserID + "')"
		_oSQL:_sQuery += " ORDER BY R_E_C_N_O_"
		_aProfile := aclone (_oSQL:Qry2Array (.f., .f.))

		for _x := 1 to Len(_aProfile)
			_sMemoProf := _aProfile[_x, 1]
		next
	
		if empty (_sMemoProf)
			u_log ("Profile do usuario vazio para este grupo de perguntas. Chave usada: " + _sChave + _sGrupo)
			_lContinua := .F.
		endif

	else
		u_help ("Grupo de perguntas '" + _sGrupo + "' nao encontrado na tabela SX1.")
		_lContinua := .F.
	endif

	if _lContinua
		// Monta array com a resposta de cada pergunta
		_aResp = {}
		for _nPerg = 1 to MLCount (_sMemoProf)
			aadd (_aResp, alltrim (substr (MemoLine (_sMemoProf,, _nPerg), 5)))
		next

		// Monta array com cada pergunta e sua resposta em uma linha.
		for _x:= 1 to Len(_aSX1)
			_sX1_GRUPO  := _aSX1[_x, 1]
			_sX1_ORDEM	:= _aSX1[_x, 2] 		
			_sX1_TIPO	:= _aSX1[_x, 3]
			_sX1_GSC	:= _aSX1[_x, 4]
			_sX1_PERGUNT:= _aSX1[_x, 5]
			_sX1_DEF01	:= _aSX1[_x, 6]
			_sX1_DEF02	:= _aSX1[_x, 7]
			_sX1_DEF03	:= _aSX1[_x, 8]
			_sX1_DEF04	:= _aSX1[_x, 9]
			_sX1_DEF05	:= _aSX1[_x,10]

			do case
				case _sX1_GSC == "C"
					do case
						case _aResp [val(_sX1_ORDEM)] == '1'
							_sX1_DEF := _sX1_DEF01
						case _aResp [val(_sX1_ORDEM)] == '2'
							_sX1_DEF := _sX1_DEF02
						case _aResp [val(_sX1_ORDEM)] == '3'
							_sX1_DEF := _sX1_DEF03
						case _aResp [val(_sX1_ORDEM)] == '4'
							_sX1_DEF := _sX1_DEF04
						case _aResp [val(_sX1_ORDEM)] == '5'
							_sX1_DEF := _sX1_DEF05
					endcase

					_sResp := cvaltochar (_aResp [val(_sX1_ORDEM)]) + ' [' + _sX1_DEF + ']'

				case _sX1_TIPO $ 'N/C'
					_sResp := _aResp [val(_sX1_ORDEM)]

				case _sX1_TIPO == 'D'
					_sResp := stod (_aResp [val(_sX1_ORDEM)])

				otherwise
					u_help ("Tipo de pergunta '" + _sX1_TIPO + "' sem tratamento.")
					_sResp := ''
			endcase
			aadd (_aRet, {_x, _sX1_GRUPO, _sX1_ORDEM, alltrim(_sX1_PERGUNT), _sResp, _sX1_DEF01, _sX1_DEF02, _sX1_DEF03, _sX1_DEF04, _sX1_DEF05})
		next
	endif

	//Se chamou sem parametros (direto do menu) mostra resultado em tela.
	if _lComTela
		u_showarray (_aRet)
	endif

	U_ML_SRArea (_aAreaAnt)

return _aRet

