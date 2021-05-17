// Programa...: GDUtil
// Autor......: Robert Koch
// Data.......: 13/08/2004
// Descricao..: Utilitarios para trabalhar com GetDados
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #generico
// #Descricao         #Utilitarios para trabalhar com GetDados
// #PalavasChave      #GetDados
// #TabelasPrincipais #SX3 
// #Modulos           #todos
//
// Historico de alteracoes:
// 02/02/2005 - Robert  - Trata aCols e aHeader genericos (uso em MsNewGetDados)
// 06/07/2005 - Robert  - Possibilidade de executar gatilhos ao gerar aCols
// 20/07/2005 - Robert  - Nao salvava areas de trabalho no inicio e fim das funcoes.
// 01/08/2005 - Robert  - Implementada funcao LinVazia.
// 12/08/2005 - Robert  - Tratamento campos virtuais na geracao do aCols
// 19/08/2005 - Robert  - Funcao ObrCols salvava area em duplicidade por nada.
// 26/10/2005 - Robert  - Possibilidade de informar campos que nao devem paricipar do aHeader.
// 05/12/2005 - Robert  - Possibilidade de nao gerar linha vazia inicial no aCols.
// 14/01/2006 - Robert  - Possibilidade de informar os unicos campos que devem paricipar do aHeader.
//                      - Possibilidade de executar SoftLock nos registros do aCols.
//                      - Testava pelo SX3 se um campo eh virtual, mas, as vezes, o SX3 estah vazio.
// 16/01/2006 - Robert  - Nao verificava corretamente a existencia de campos.
// 15/03/2006 - Robert  - Confundia campos com inicio igual, no parametro 'campos sim'.
// 28/07/2006 - Robert  - Nao respeitava parametro CamposSim na geracao do aHeader.
// 08/09/2006 - Robert  - Criada funcao GrvACols
// 29/09/2006 - Robert  - Testa se o campo existe antes de gravar na funcao GrvACols.
// 25/03/2007 - Robert  - Seleciona alias na funcao GeraCols para nao precisar passar no filtro da chamada.
// 16/04/2007 - Robert  - Criado parametro no GeraHead para informar se quer apenas os campos do parametro _aCposSim.
// 27/11/2007 - Robert  - Criada funcao GDTemDad.
// 26/06/2008 - Robert  - Funcao GeraHead passa a gerar aHeader com campos de diferentes arquivos.
// 26/04/2013 - Robert  - Funcao GeraCols parra a receber filtro adicional como parametro.
// 05/05/2013 - Robert  - Criado tratamento para campo ZZZ_RECNO.
// 13/05/2021 - Claudia - Ajuste da tabela SX3 devido a R27. GLPI: 8825
//
// ------------------------------------------------------------------------------------------------------------------
//
// Gera aHeader do arquivo especificado.
user function GeraHead (_sAlias, _lNew, _aCposNao, _aCposSim, _lSohEstes)
	local _aAreaAnt := U_ML_SRArea ()  // Salva todas as areas de trabalho
	local aHeader 	:= {}
	local _nCampo 	:= 0
	local _nLinha	:= 0
	local _x        := 0
	
	// Prepara defaults
	_lNew     := iif(_lNew     == NIL, .F., _lNew)
	_aCposNao := iif(_aCposNao == NIL,  {}, _aCposNao)
	_aCposSim := iif(_aCposSim == NIL,  {}, _aCposSim)
	
	// Preenche nomes de campos com espacos para ficar igual ao x3_campo e evitar
	// confusao entre H6_OP e H6_OPERADO, por exemplo.
	for _nLinha = 1 to len (_aCposNao)
		_aCposNao [_nLinha] = upper (padr (_aCposNao [_nLinha], 10, " "))
	next

	for _nLinha = 1 to len (_aCposSim)
		_aCposSim [_nLinha] = upper (padr (_aCposSim [_nLinha], 10, " "))
	next
	
	// Se, em lugar do alias, foi passada uma string vazia, entao eh por que
	// o programa chamador quer campos de diferentes tabelas.
	if _sAlias == ""

		for _nCampo = 1 to len (_aCposSim)

			_oSQL  := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT"
			_oSQL:_sQuery += " 	   X3_ARQUIVO"	// 01
			_oSQL:_sQuery += "    ,X3_ORDEM"	// 02
			_oSQL:_sQuery += "    ,X3_CAMPO"	// 03
			_oSQL:_sQuery += "    ,X3_TIPO"		// 04
			_oSQL:_sQuery += "    ,X3_TAMANHO"	// 05
			_oSQL:_sQuery += "    ,X3_DECIMAL"	// 06
			_oSQL:_sQuery += "    ,X3_TITULO"	// 07
			_oSQL:_sQuery += "    ,X3_PICTURE"	// 08
			_oSQL:_sQuery += "    ,X3_VALID"	// 09
			_oSQL:_sQuery += "    ,X3_USADO"	// 10
			_oSQL:_sQuery += "    ,X3_RELACAO"	// 11
			_oSQL:_sQuery += "    ,X3_F3"		// 12
			_oSQL:_sQuery += "    ,X3_NIVEL"	// 13
			_oSQL:_sQuery += "    ,X3_CONTEXT"	// 14
			_oSQL:_sQuery += "    ,X3_CBOX"		// 15
			_oSQL:_sQuery += " FROM SX3010"
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery += " AND X3_CAMPO     = '" + _aCposSim [_nCampo] + "'"
			_aSX3  = aclone (_oSQL:Qry2Array ())	

			for _x:= 1 to Len(_aSX3)
				if X3USO(_aSX3[_x, 10]) .And. cNivel >= _aSX3[_x,13]
					if _lNew  	// Usado quando MsNewGetDados
						AADD (aHeader, {TRIM(_aSX3[_x,7]), _aSX3[_x,3], _aSX3[_x,8], _aSX3[_x,5], _aSX3[_x,6], _aSX3[_x,9], _aSX3[_x,10], _aSX3[_x,4], _aSX3[_x,12], _aSX3[_x,14], _aSX3[_x,15], _aSX3[_x,11], ".T."})
					
					else  		// GetDados tradicional
						AADD (aHeader, {TRIM(_aSX3[_x,7]), _aSX3[_x,3], _aSX3[_x,8], _aSX3[_x,5], _aSX3[_x,6], ""         , _aSX3[_x,10], _aSX3[_x,4], _aSX3[_x, 1], _aSX3[_x,14]})
					endif
				endif
			next
		next

		// sx3 -> (DbSetOrder (2))
		// for _nCampo = 1 to len (_aCposSim)
		// 	if sx3 -> (dbseek (_aCposSim [_nCampo], .F.))

		// 		// Decidir se o campo deve ir para o aHeader ou nao eh uma tarefa complicada...
		// 		If X3USO (sx3 -> X3_USADO) .And. cNivel >= sx3 -> X3_NIVEL
		// 			if _lNew  // Usado quando MsNewGetDados
		// 				AADD (aHeader, {TRIM(sx3->X3_TITULO), sx3->X3_CAMPO, sx3->X3_PICTURE, sx3->X3_TAMANHO, sx3->X3_DECIMAL, sx3 -> x3_valid, sx3->X3_USADO, sx3->X3_TIPO, sx3 -> x3_f3,      sx3->X3_CONTEXT, sx3->x3_cbox, sx3->x3_relacao, ".t."})
		// 			else  // GetDados tradicional
		// 				AADD (aHeader, {TRIM(sx3->X3_TITULO), sx3->X3_CAMPO, sx3->X3_PICTURE, sx3->X3_TAMANHO, sx3->X3_DECIMAL, "",              sx3->X3_USADO, sx3->X3_TIPO, sx3 -> X3_ARQUIVO, sx3->X3_CONTEXT})
		// 			endif
		// 		endif
		// 	Endif
		// next

	else
		_oSQL  := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT"
		_oSQL:_sQuery += " 	   X3_ARQUIVO"	// 01
		_oSQL:_sQuery += "    ,X3_ORDEM"	// 02
		_oSQL:_sQuery += "    ,X3_CAMPO"	// 03
		_oSQL:_sQuery += "    ,X3_TIPO"		// 04
		_oSQL:_sQuery += "    ,X3_TAMANHO"	// 05
		_oSQL:_sQuery += "    ,X3_DECIMAL"	// 06
		_oSQL:_sQuery += "    ,X3_TITULO"	// 07
		_oSQL:_sQuery += "    ,X3_PICTURE"	// 08
		_oSQL:_sQuery += "    ,X3_VALID"	// 09
		_oSQL:_sQuery += "    ,X3_USADO"	// 10
		_oSQL:_sQuery += "    ,X3_RELACAO"	// 11
		_oSQL:_sQuery += "    ,X3_F3"		// 12
		_oSQL:_sQuery += "    ,X3_NIVEL"	// 13
		_oSQL:_sQuery += "    ,X3_CONTEXT"	// 14
		_oSQL:_sQuery += "    ,X3_CBOX"		// 15
		_oSQL:_sQuery += " FROM SX3010"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND X3_ARQUIVO   = '" + _sAlias + "'"
		_aSX3  = aclone (_oSQL:Qry2Array ())	

		for _x:= 1 to Len(_aSX3)
			if ascan(_aCposNao, _aSX3[_x,3]) == 0
				if ascan(_aCposSim, _aSX3[_x,3]) > 0 .or. (X3USO(_aSX3[_x,10]) .And. cNivel >= _aSX3[_x,13] .and. ! _lSohEstes)
					if _lNew  	// Usado quando MsNewGetDados
						AADD (aHeader, {TRIM(_aSX3[_x,7]), _aSX3[_x,3], _aSX3[_x,8], _aSX3[_x,5], _aSX3[_x,6], _aSX3[_x,9], _aSX3[_x,10], _aSX3[_x,4], _aSX3[_x,12], _aSX3[_x,14], _aSX3[_x,15], _aSX3[_x,11], ".T."})
					
					else  		// GetDados tradicional
						AADD (aHeader, {TRIM(_aSX3[_x,7]), _aSX3[_x,3], _aSX3[_x,8], _aSX3[_x,5], _aSX3[_x,6], ""         , _aSX3[_x,10], _aSX3[_x,4], _aSX3[_x, 1], _aSX3[_x,14]})
					endif
				endif
			endif
		next
		// sx3 -> (DbSetOrder (1))
		// sx3 -> (DbSeek (_sAlias))
		// Do While ! sx3 -> (Eof ()) .And. (sx3 -> X3_ARQUIVO == _sALias)

		// 	// Decidir se o campo deve ir para o aHeader ou nao eh uma tarefa complicada...
		// 	if ascan (_aCposNao, sx3->x3_campo) == 0
		// 		If ascan (_aCposSim, sx3->x3_campo) > 0 .or. (X3USO (sx3 -> X3_USADO) .And. cNivel >= sx3 -> X3_NIVEL .and. ! _lSohEstes)
		// 			if _lNew  // Usado quando MsNewGetDados
		// 				AADD (aHeader, {TRIM(sx3->X3_TITULO), sx3->X3_CAMPO, sx3->X3_PICTURE, sx3->X3_TAMANHO, sx3->X3_DECIMAL, sx3 -> x3_valid, sx3->X3_USADO, sx3->X3_TIPO, sx3 -> x3_f3,      sx3->X3_CONTEXT, sx3->x3_cbox, sx3->x3_relacao, ".t."})
		// 			else  // GetDados tradicional
		// 				AADD (aHeader, {TRIM(sx3->X3_TITULO), sx3->X3_CAMPO, sx3->X3_PICTURE, sx3->X3_TAMANHO, sx3->X3_DECIMAL, "",              sx3->X3_USADO, sx3->X3_TIPO, sx3 -> X3_ARQUIVO, sx3->X3_CONTEXT})
		// 			endif
		// 		endif
		// 	Endif
		// 	sx3 -> (DbSkip())
		// Enddo

	endif
	
	U_ML_SRArea (_aAreaAnt)
return aHeader
//
// --------------------------------------------------------------------------
// Gera aCols do arquivo especificado.
user function GeraCols (_sAlias, _nOrdem, _sSeekIni, _sWhile, aHeader, _lGatilh, _lVazia, _lLock, _sFiltro)
	local _nCampo   := 0
	local aCols     := {}
	local _nCol	    := 0
	local _nLinha   := 0
	local _aAreaAnt := U_ML_SRArea ()  // Salva todas as areas de trabalho
	
	_lGatilh := iif(_lGatilh == NIL,   .F., _lGatilh)
	_lVazia  := iif(_lVazia  == NIL,   .T., _lVazia)
	_lLock   := iif(_lLock   == NIL,   .F., _lLock)
	_sFiltro := iif(_sFiltro == NIL, '.T.', _sFiltro)
	
	// Tenta ler os registros do arquivo.
	dbselectarea (_sAlias)
	(_sAlias) -> (dbsetorder (_nOrdem))
	(_sAlias) -> (dbgotop ())
	(_sAlias) -> (dbSeek (_sSeekIni, .t.))

	do while ! (_sAlias) -> (eof ()) .and. &_sWhile
		if _lLock .and. ! SoftLock (_sAlias)
			exit
		endif

		if ! &(_sFiltro)
			(_sAlias) -> (dbskip ())
			loop
		endif

		AADD (aCols, Array (len (aHeader) + 1))

		for _nCampo = 1 to len (aHeader)
			if (_sAlias) -> (FieldPos (aHeader [_nCampo, 2])) > 0  // Campo real. Nao testar pelo SX3 por que as vezes estah em branco!
				aCols [Len (aCols), _nCampo] := (_sAlias) -> (FieldGet (FieldPos (aHeader [_nCampo, 2])))
			else  // Campo virtual ou especifico.
				if alltrim (aHeader [_nCampo, 2]) == "ZZZ_RECNO"
					aCols [Len (aCols), _nCampo] := (_sAlias) -> (recno ())
				else
					aCols [Len (aCols), _nCampo] := CriaVar (aHeader [_nCampo, 2])
				endif
			endif
		next
		aCols [len (aCols), len (aCols [1])] = .F.  // Linha nao deletada
		(_sAlias) -> (dbSkip ())
	End
	
	// Se aCols estiver vazio, tenho que inicializar com uma linha em branco
	if len (aCols) == 0 .and. _lVazia
		aCols := {array (len (aHeader) + 1)}
		For _nCampo = 1 to len (aHeader)
			aCols [1, _nCampo] := CriaVar (aHeader [_nCampo, 2])
		Next
		aCols [1, len (aCols [1])] := .F.  // Linha nao deletada
	endif
	
	// Percorre todas as linhas de aCols executando gatilhos
	if _lGatilh
		for _nLinha = 1 to len (aCols)
			private N := _nLinha  // Algum gatilho pode estar usando N.
			
			// Percorre todos os campos da linha atual
			for _nCol = 1 to len (aHeader)
				
				// Se tem gatilho no campo atual, executa-o.
				RunTrigger (2, _nLinha, , , aHeader [_nCol, 2])
			next
		next
	endif
	
	U_ML_SRArea (_aAreaAnt)
return aCols
//
// --------------------------------------------------------------------------
// Verifica se ha campos obrigatorios nao preenchidos no aCols
user function ObrCols (_nLinha, _sMsg)
	local _nCampo   := 0
	local _aAreaAnt := {}
	//local _aAreaSX3 := {}
	local _lRet     := .T.
	local _x        := 0
	
	_nLinha := iif (_nLinha == NIL, N, _nLinha)

	if ! GDDeleted (_nLinha)

		for _nCampo = 1 to len (aHeader)
			if empty (aCols [_nLinha, _nCampo])

				_oSQL  := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT"
				_oSQL:_sQuery += " 	   X3_ARQUIVO"	// 01
				_oSQL:_sQuery += "    ,X3_ORDEM"	// 02
				_oSQL:_sQuery += "    ,X3_CAMPO"	// 03
				_oSQL:_sQuery += "    ,X3_TIPO"		// 04
				_oSQL:_sQuery += "    ,X3_TAMANHO"	// 05
				_oSQL:_sQuery += "    ,X3_DECIMAL"	// 06
				_oSQL:_sQuery += "    ,X3_TITULO"	// 07
				_oSQL:_sQuery += "    ,X3_PICTURE"	// 08
				_oSQL:_sQuery += "    ,X3_VALID"	// 09
				_oSQL:_sQuery += "    ,X3_USADO"	// 10
				_oSQL:_sQuery += "    ,X3_RELACAO"	// 11
				_oSQL:_sQuery += "    ,X3_F3"		// 12
				_oSQL:_sQuery += "    ,X3_NIVEL"	// 13
				_oSQL:_sQuery += "    ,X3_CONTEXT"	// 14
				_oSQL:_sQuery += "    ,X3_CBOX"		// 15
				_oSQL:_sQuery += "    ,X3_OBRIGAT"  // 16
				_oSQL:_sQuery += "    ,X3_RESERV"   // 17
				_oSQL:_sQuery += " FROM SX3010"
				_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
				_oSQL:_sQuery += " AND X3_CAMPO     = '" + aHeader[_nCampo, 2] + "'"
				_aSX3  = aclone (_oSQL:Qry2Array ())	

				for _x := 1 to Len(_aSX3)
					if (x3uso(_aSX3[_x,10]) .and. ((SubStr(BIN2STR(_aSX3[_x,16]),1,1) == "x") .or. VerByte(_aSX3[_x,17],7)))
						u_help(iif(_sMsg == NIL, "", _sMsg + chr (13) + chr (10)) + "Campo " + alltrim (aHeader [_nCampo, 1]) + " deve ser informado", aHeader [_nCampo, 2])
						_lRet = .F.
						exit
					endif
				next
			endif
		next
		restarea (_aAreaAnt)
	endif
	//
	// if ! GDDeleted (_nLinha)
	// 	_aAreaAnt := getarea ()
	// 	_aAreaSX3 := sx3 -> (getarea ())
	// 	sx3 -> (dbsetorder (2))  // Por nome de campo
	// 	for _nCampo = 1 to len (aHeader)
	// 		if empty (aCols [_nLinha, _nCampo])
	// 			if sx3 -> (dbseek (aHeader [_nCampo, 2], .F.))
	// 				if (x3uso(SX3->X3_USADO) .and. ((SubStr(BIN2STR(SX3->X3_OBRIGAT),1,1) == "x") .or. VerByte(SX3->x3_reserv,7)))
	// 					msgalert (iif (_sMsg == NIL, "", _sMsg + chr (13) + chr (10)) + "Campo " + alltrim (aHeader [_nCampo, 1]) + " deve ser informado", aHeader [_nCampo, 2])
	// 					_lRet = .F.
	// 					exit
	// 				endif
	// 			endif
	// 		endif
	// 	next
	// 	sx3 -> (restarea (_aAreaSX3))
	// 	restarea (_aAreaAnt)
	// endif
return _lRet
//
// --------------------------------------------------------------------------
// Gera linha vazia para aCols.
user function LinVazia (aHeader)
	local _nCampo   := 0
	local _aLinha   := {}
	local _xCampo   := NIL
	local _sTipo    := ""
	local _aAreaAnt := U_ML_SRArea ()  // Salva todas as areas de trabalho


	for _nCampo = 1 to len (aHeader)
		_oSQL  := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT"
		_oSQL:_sQuery += " 	   X3_ARQUIVO"	// 01
		_oSQL:_sQuery += "    ,X3_ORDEM"	// 02
		_oSQL:_sQuery += "    ,X3_CAMPO"	// 03
		_oSQL:_sQuery += "    ,X3_TIPO"		// 04
		_oSQL:_sQuery += "    ,X3_TAMANHO"	// 05
		_oSQL:_sQuery += "    ,X3_DECIMAL"	// 06
		_oSQL:_sQuery += "    ,X3_TITULO"	// 07
		_oSQL:_sQuery += "    ,X3_PICTURE"	// 08
		_oSQL:_sQuery += "    ,X3_VALID"	// 09
		_oSQL:_sQuery += "    ,X3_USADO"	// 10
		_oSQL:_sQuery += "    ,X3_RELACAO"	// 11
		_oSQL:_sQuery += "    ,X3_F3"		// 12
		_oSQL:_sQuery += "    ,X3_NIVEL"	// 13
		_oSQL:_sQuery += "    ,X3_CONTEXT"	// 14
		_oSQL:_sQuery += "    ,X3_CBOX"		// 15
		_oSQL:_sQuery += "    ,X3_OBRIGAT"  // 16
		_oSQL:_sQuery += "    ,X3_RESERV"   // 17
		_oSQL:_sQuery += " FROM SX3010"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND X3_CAMPO     = '" + aHeader[_nCampo, 2] + "'"
		_aSX3  = aclone (_oSQL:Qry2Array ())	

		if Len(_aSX3) > 0
			_xCampo := CriaVar(aHeader[_nCampo, 2])
		else  // Campo generico
			_sTipo := aHeader[_nCampo, 8]
			do case
				case _sTipo $ "C/M"
					_xCampo := space(aHeader[_nCampo, 4])
				case _sTipo == "N"
					_xCampo := 0
				case _sTipo == "D"
					_xCampo := ctod ("")
				case _sTipo == "L"
					_xCampo := .F.
			endcase
		endif
		aadd (_aLinha, _xCampo)
	next
	aadd (_aLinha, .F.)  // Linha nao deletada

	// sx3 -> (dbsetorder (2))
	// for _nCampo = 1 to len (aHeader)
	// 	if sx3 -> (dbseek (aHeader [_nCampo, 2], .F.))  // Campo do dic. de dados
	// 		_xCampo = CriaVar (aHeader [_nCampo, 2])
	// 	else  // Campo generico
	// 		_sTipo = aHeader [_nCampo, 8]
	// 		do case
	// 			case _sTipo $ "C/M"
	// 				_xCampo = space (aHeader [_nCampo, 4])
	// 			case _sTipo == "N"
	// 				_xCampo = 0
	// 			case _sTipo == "D"
	// 				_xCampo = ctod ("")
	// 			case _sTipo == "L"
	// 				_xCampo = .F.
	// 		endcase
	// 	endif
	// 	aadd (_aLinha, _xCampo)
	// next
	// aadd (_aLinha, .F.)  // Linha nao deletada
	
	U_ML_SRArea (_aAreaAnt)
return _aLinha
//
// --------------------------------------------------------------------------
// Grava em arquivo os campos do aCols. O registro jah deve estar travado com RecLock.
// Parametros: - Alias do arquivo onde gravar
//             - Numero da linha do aCols a ser gravada
//             - Array com campos adicionais a gravar (que nao estao no aCols), no formato {<nome_do_campo>, <conteudo>}
user function GrvACols (_sAlias, _nLinha, _aCpos)
	local _nCampo  := 0
	local _sCampo  := ""
	local _nposCpo := 0
	
	for _nCampo = 1 to len (aHeader)
		_sCampo = aHeader [_nCampo, 2]
		_nPosCpo = (_sAlias) -> (fieldpos (_sCampo))

		if _nPosCpo > 0
			(_sAlias) -> (fieldput (_nPosCpo, aCols [_nLinha, _nCampo]))
		endif
	next
	
	// Grava campos que nao estao no aCols
	for _nCampo = 1 to len (_aCpos)
		(_sAlias) -> &(_aCpos [_nCampo, 1]) = _aCpos [_nCampo, 2]
	next
return
//
// --------------------------------------------------------------------------
// Verifica se a linha tem dados (se precisa ser gravada, por exemplo)
user function GDTemDad (_nLinha)
	local _lRet   := .F.
	local _nCampo := 0

	for _nCampo = 1 to len (aHeader)
		if ! empty (aCols [_nLinha, _nCampo])
			_lRet = .T.
			exit
		endif
	next
return _lRet
