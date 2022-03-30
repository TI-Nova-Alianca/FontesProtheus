// Programa:   VA_CCR
// Autor:      Robert Koch
// Data:       19/01/2009
// Descricao:  Relatorio de calculo de custo de reposicao e comparativo com os
//             custos standard e preco de ultima compra.
//
// Historico de alteracoes:
// 27/01/2009 - Robert - Passa a verificar o campo B1_vaForaL em vez da tabela SG5.
// 20/05/2010 - Robert - Criada possibilidade de exportacao para planilha.
// 30/01/2011 - Robert - Criada possibiliadde de detalhar ultima compra.
//                     - Feitas alteracoes, tambem, na funcao VA_ULTCOM do SQL.
// 28/08/2012 - Robert - Passa a listar PIS e COFINS (novas colunas da funcao VA_ULTCOMP do SQL.
// 29/04/2013 - Robert - Reduzidas chamadas da funcao VA_ULTCOMP do SQL para ganho de preformance.
//                     - Funcao VA_UltCOMP do SQL passa a receber parametros de finial inicial e final.
//                     - Passa a considerar ultimas compras de qualquer filial e nao mais apenas da filial corrente.
// 28/03/2022 - Robert - Eliminada funcionalidade de conversao para TXT (em alguns casos 'perdia' o relatorio).
// 

// --------------------------------------------------------------------------
user function VA_CCR (_lAutomat)
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	private _sArqLog := U_NomeLog ()
	u_logID ()
	
	// Variaveis obrigatorias dos programas de relatorio
	Titulo   := "Custo de reposicao X standard X ultima compra."
	cDesc1   := Titulo
	cDesc2   := ""
	cDesc3   := ""
	cString  := "SG1"
	aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	nLastKey := 0
	cPerg    := "VA_CCR"
	nomeprog := "VA_CCR"
	wnrel    := "VA_CCR"
	tamanho  := "G"
	limite   := 220
	nTipo    := 15
	m_pag    := 1
	li       := 80
	aOrd     := {}
	
	_ValidPerg ()
	pergunte (cPerg, .F.)

	if ! _lAuto

		// Execucao com interface com o usuario.
		wnrel:=SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,cDesc2,cDesc3,.F., aOrd, .F., NIL, tamanho, NIL, .F., NIL, NIL, .F., .T., NIL)
	else
		// Execucao sem interface com o usuario.
		//
		// Deleta o arquivo do relatorio para evitar a pergunta se deseja sobrescrever.
		delete file (__reldir + wnrel + ".##r")
		//
		// Chama funcao setprint sem interface... essa deu trabalho!
		__AIMPRESS[1]:=1  // Obriga a impressao a ser "em disco" na funcao SetPrint
		wnrel := SetPrint (cString, ;  // Alias
		wnrel, ;  // Sugestao de nome de arquivo para gerar em disco
		cPerg, ;  // Parametros
		@titulo, ;  // Titulo do relatorio
		cDesc1, ;  // Descricao 1
		cDesc2, ;  // Descricao 2
		cDesc3, ;  // Descricao 3
		.F., ;  // .T. = usa dicionario
		aOrd, ;  // Array de ordenacoes para o usuario selecionar
		.T., ;  // .T. = comprimido
		tamanho, ;  // P/M/G
		NIL, ;  // Nao pude descobrir para que serve.
		.F., ;  // .T. = usa filtro
		NIL, ;  // lCrystal
		NIL, ;  // Nome driver. Ex.: "EPSON.DRV"
		.T., ;  // .T. = NAO mostra interface para usuario
		.T., ;  // lServer
		NIL)    // cPortToPrint
	endif
	If nLastKey == 27
		Return
	Endif
	delete file (__reldir + wnrel + ".##r")
	SetDefault (aReturn, cString)
	If nLastKey == 27
		Return
	Endif
	
	processa ({|| _Imprime ()})

	if mv_par08 == 1  // Nao eh destino planilha
		MS_FLUSH ()
		DbCommitAll ()

		if ! _lAuto
			If aReturn [5] == 1
				ourspool(wnrel)
			Endif
		endif
	endif
return




// --------------------------------------------------------------------------
static function _Imprime ()
	local _nMaxLin   := 63
	local _sQuery    := ""
	//local _aAliasQ   := ""
	//local _aAliasUC  := ""
	local _nCustD    := 0
	local _nUPrc     := 0
	local _nCusRep   := 0
	local _nMCusRep  := 0
	local _aCampos   := {}
	local _aArqtrb   := {}
	local _aUltCom   := {}
	local _nUltCom   := 0
	local _sCampo    := ""
	local _nCampo    := 0
	local _nVlrFinal := 0
	local _oSQL      := NIL

	if mv_par08 == 2 .and. mv_par09 == 1
		u_help ("Detalhamento do calculo disponivel somente quando destino 'relatorio'.")
		return
	endif

	cCabec1  := "                                                                            ____Custo standard____   _____Ultima compra_____   ____Custo reposicao____  Variacao    _____Media " + cvaltochar (mv_par05) + " ultimas compras______"
	cCabec2  := "Produto         Descricao                                          UM Tipo        atual   data ref     Preco unit     data        calculado   data ref  calc/std      Preco unit    +antiga   +recente"
	li = _nMaxLin + 1
	procregua (3)

	// Busca os produtos a serem listados
	_sQuery := ""
	_sQuery += "SELECT B1_COD AS PRODUTO, B1_DESC AS DESCRICAO, B1_UM AS UN_MEDIDA, B1_TIPO AS TIPO_PROD, SB1.B1_VAFORAL AS FORA_LINHA,"
	_sQuery +=       " B1_CUSTD AS CUSTO_STD, SB1.B1_DATREF AS DT_CUS_STD, SB1.B1_UPRC AS ULT_COMPRA, SB1.B1_UCOM AS DT_ULT_COM"
	_sQuery +=  " FROM " + RetSQLName ("SB1") + " SB1 "
	_sQuery += " WHERE SB1.D_E_L_E_T_ = ''"
	_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_sQuery +=   " AND SB1.B1_TIPO    between '" + mv_par01 + "' and '" + mv_par02 + "'"
	_sQuery +=   " AND SB1.B1_COD     between '" + mv_par03 + "' and '" + mv_par04 + "'"
	if mv_par07 == 2
		_sQuery +=   " AND SB1.B1_MSBLQL != '1'"
	endif
	_sQuery += " ORDER BY B1_COD"
	// u_log (_squery)
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
	U_TCSetFld (_sAliasQ)
	TCSetField (_sAliasQ, "DT_CUS_STD", "D")
	TCSetField (_sAliasQ, "DT_ULT_COM", "D")


	// Cria arquivo de trabalho para preparar os dados.
	_aCampos = {}
	aadd (_aCampos, {"PRODUTO",    "C", 15, 0})
	aadd (_aCampos, {"DESCRICAO",  "C", 60, 0})
	aadd (_aCampos, {"UN_MEDIDA",  "C", 2,  0})
	aadd (_aCampos, {"TIPO_PROD",  "C", 2,  0})
	aadd (_aCampos, {"FORA_LINHA", "C", 1,  0})
	aadd (_aCampos, {"CUSTO_STD",  "N", 15, 8})
	aadd (_aCampos, {"DT_CUS_STD", "D", 8,  0})
	aadd (_aCampos, {"ULT_COMPRA", "N", 15, 8})
	aadd (_aCampos, {"DT_ULT_COM", "D", 8,  0})
	aadd (_aCampos, {"CT_REP_CAL", "N", 15, 8})
	aadd (_aCampos, {"DT_CUS_CAL", "D", 8,  0})
	aadd (_aCampos, {"MED_ULT_CO", "N", 15, 8})
	aadd (_aCampos, {"M_ANTIGA",   "D", 8,  0})
	aadd (_aCampos, {"M_RECENTE",  "D", 8,  0})
	for _nUltCom = 1 to mv_par05
		aadd (_aCampos, {"C_UCom_" + strzero (_nUltCom, 3), "N", 18, 4})
		aadd (_aCampos, {"D_UCom_" + strzero (_nUltCom, 3), "D", 8,  0})
	next
	U_ArqTrb ("Cria", "_plan", _aCampos, {}, @_aArqTrb)

	count to _nRecCount
	procregua (_nRecCount)
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		incproc ()

		// Desconsiderar produtos fora de linha:
		if mv_par06 == 1  // Desconsiderar produtos com pais fora de linha: neste caso, o

			// Se o item nao eh usado em estruturas, verifica apenas pelo seu cadastro
			sg1 -> (dbsetorder (2))  // G1_FILIAL+G1_COMP+G1_COD
			if ! sg1 -> (dbseek (xfilial ("SG1") + (_sAliasQ) -> produto, .T.))
				if (_sAliasQ) -> Fora_Linha == "S"
					// u_log ("Desconsiderando produto fora de linha cfe. seu cadastro:", (_sAliasQ) -> produto)
					(_sAliasQ) -> (dbskip ())
					loop
				endif

			else

				// Se o item eh usado em alguma estrutura, todas as estruturas que o utilizam devem estar fora de linha.
				_sQuery := ""
				_sQuery += " SELECT COUNT (G1_FILIAL)"
				_sQuery +=   " FROM " + RetSQLName ("SG1") + " SG1, "
				_sQuery +=              RetSQLName ("SB1") + " SB1  "
				_sQuery +=  " WHERE SG1.D_E_L_E_T_  = ''"
				_sQuery +=    " AND SB1.D_E_L_E_T_  = ''"
				_sQuery +=    " AND SG1.G1_FILIAL   = '" + xfilial ("SG1") + "'"
				_sQuery +=    " AND SB1.B1_FILIAL   = '" + xfilial ("SB1") + "'"
				_sQuery +=    " AND SG1.G1_COMP     = '" + (_sAliasQ) -> produto + "'"
				_sQuery +=    " AND SG1.G1_INI     <= '" + DTOS (dDataBase) + "'"
				_sQuery +=    " AND SG1.G1_FIM     >= '" + DTOS (dDataBase) + "'"
				_sQuery +=    " AND SB1.B1_COD      = SG1.G1_COD"
				_sQuery +=    " AND SB1.B1_VAFORAL != 'S'"
				if u_RetSQL (_sQuery) == 0
					// u_log ("Desconsiderando produto fora de linha por que nao eh usado por nenhuma estrutura que esteja em linha:", (_sAliasQ) -> produto)
					(_sAliasQ) -> (dbskip ())
					loop
				endif
			endif
		endif

		// Passa dados do registro atual da query para o arquivo de trabalho
		reclock ("_plan", .T.)
		for _nCampo = 1 to (_sAliasQ) -> (fcount ())
			_sCampo = (_sAliasQ) -> (FieldName (_nCampo))
			_plan -> &(_sCampo) := (_sAliasQ) -> &(_sCampo)
		next

/*
		// Busca dados da ultima compra.
		_sQuery := "SELECT CUSREPUNI,"
		_sQuery +=       " D1_DTDIGIT"
		_sQuery +=  " FROM VA_ULTCOMP ('" + cFilAnt + "', '" + (_sAliasQ) -> produto + "', 1)"
		//u_log (_sQuery)
		_aUltCom = aclone (U_Qry2Array (_sQuery, .f., .f.))
		//u_log (_aUltCom)
		if len (_aUltCom) > 0
			_plan -> Ct_Rep_Cal = _aUltCom [1, 1]
			_plan -> Dt_Cus_Cal = stod (_aUltCom [1, 2])
		endif


		// Busca medias das ultimas compras.
		_sQuery := "SELECT AVG(CUSREPUNI),"
		_sQuery +=       " MIN(D1_DTDIGIT),"
		_sQuery +=       " MAX(D1_DTDIGIT)"
		_sQuery +=  " FROM VA_ULTCOMP ('" + cFilAnt + "', '" + (_sAliasQ) -> produto + "', " + cvaltochar (mv_par05) + ")"
		// u_log (_sQuery)
		_aUltCom = aclone (U_Qry2Array (_sQuery))
		if len (_aUltCom) > 0
			_plan -> Med_Ult_Co = _aUltCom [1, 1]
			_plan -> M_Antiga   = stod (_aUltCom [1, 2])
			_plan -> M_Recente  = stod (_aUltCom [1, 3])
		endif

		// Busca dados abertos das ultimas compras (somente na opcao 'planilha').
		if mv_par08 == 2
			_sQuery := "SELECT CUSREPUNI,"
			_sQuery +=       " D1_DTDIGIT"
			_sQuery +=       " FROM VA_ULTCOMP ('" + cFilAnt + "', '" + (_sAliasQ) -> produto + "', " + cvaltochar (mv_par05) + ")"
			// u_log (_sQuery)
			_aUltCom = aclone (U_Qry2Array (_sQuery))
	
			// Inicia o preenchimento pela ultima compra e vai 'voltando' para que a ultima coluna sempre esteja
			// preenchida (pode nao haver tantas ultimas compras quanto solicitado pelo usuario).
			for _nUltCom = len (_aUltCom) to 1 step -1
				_plan -> &("C_UCom_" + strzero (_nUltCom, 3)) = _aUltCom [_nUltCom, 1]
				_plan -> &("D_UCom_" + strzero (_nUltCom, 3)) = _aUltCom [_nUltCom, 2]
			next
		endif
		msunlock ()
*/
		// Busca dados das ultimas compras em array para ganho de performance. Do contrario seriam
		// necessarias varias chamadas `a funcao VA_ULTCOMP.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := "SELECT CUSREPUNI,"
		_oSQL:_sQuery +=       " D1_DTDIGIT"
//		_oSQL:_sQuery +=  " FROM VA_ULTCOMP ('" + cFilAnt + "', '" + (_sAliasQ) -> produto + "', " + cvaltochar (mv_par05) + ")"
		_oSQL:_sQuery +=  " FROM VA_ULTCOMP ('', 'zz', '" + (_sAliasQ) -> produto + "', " + cvaltochar (mv_par05) + ")"
//		u_log (_oSQL:_sQuery)
		_oUltCom := ClsAUtil():New (_oSQL:Qry2Array (.F., .F.))
//		u_log ('oUltCom:', _oUltCom:_aArray)
		if len (_oUltCom:_aArray) > 0
			_plan -> Ct_Rep_Cal = _oUltCom:_aArray [1, 1]
			_plan -> Dt_Cus_Cal = stod (_oUltCom:_aArray [1, 2])
			_plan -> Med_Ult_Co = _oUltCom:MediaCol (1)
			_plan -> M_Antiga   = stod (_oUltCom:_aArray [len (_oUltCom:_aArray), 2])
			_plan -> M_Recente  = stod (_oUltCom:_aArray [1, 2])

			// Busca dados abertos das ultimas compras (somente na opcao 'planilha').
			if mv_par08 == 2
	
				// Inicia o preenchimento pela ultima compra e vai 'voltando' para que a ultima coluna sempre esteja
				// preenchida (pode nao haver tantas ultimas compras quanto solicitado pelo usuario).
				for _nUltCom = len (_oUltCom:_aArray) to 1 step -1
					_plan -> &("C_UCom_" + strzero (_nUltCom, 3)) = _oUltCom:_aArray [_nUltCom, 1]
					_plan -> &("D_UCom_" + strzero (_nUltCom, 3)) = stod (_oUltCom:_aArray [_nUltCom, 2])
				next
			endif
		endif
		msunlock ()

		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())
    dbselectarea ("SB1")

	// u_logtrb ("_plan", .t.)

	if mv_par08 == 1  // Relatorio
		_plan -> (dbgotop ())
		do while ! _plan -> (eof ())

			// Prepara variaveis jah com decimais fixos, para evitar erros de arredondamento nas formulas.
			_nCustD   = round (_plan -> Custo_Std, 4)
			_nUPrc    = round (_plan -> Ult_Compra, 4)
			_nCusRep  = round (_plan -> ct_rep_cal, 4)
			_nMCusRep = round (_plan -> MED_ULT_CO, 4)
			
			// Calcula variacao
			_nVariac = (_nCusRep * 100 / _nCustD) - 100

			if li > _nMaxLin
				cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
			endif

			@ li, 0 psay _plan -> produto + " " + ;
			             U_TamFixo (_plan -> descricao, 50) + " " + ;
			             _plan -> un_medida + " " + ;
			             _plan -> tipo_prod + " " + ;
			             transform (_nCustD, "@E 9,999,999.9999") + "   " + ;
			             dtoc (_plan -> dt_cus_std) + " " + ;
			             transform (_nUprc, "@E 9,999,999.9999") + "   " + ;
			             dtoc (_plan -> dt_ult_com) + " " + ;
			             transform (_nCusRep, "@E 9,999,999.9999") + "   " + ;
			             dtoc (_plan -> dt_cus_cal) + " " + ;
			             transform (_nVariac, "@ER 9,999.99%") + "  " + ;
			             transform (_nMCusRep, "@E 9,999,999.9999") + "   " + ;
			             dtoc (_plan -> m_antiga) + "   " + ;
			             dtoc (_plan -> m_recente)
			li ++

			if mv_par09 == 1  // Detalhar ultima compra.

				// Busca dados da ultima compra.
//				_sQuery := "SELECT 'NF/serie: ' + D1_DOC + '/' + D1_SERIE + '  Fornecedor/loja: ' + D1_FORNECE + '/' + D1_LOJA + '  Item NF: ' + D1_ITEM,"
				_sQuery := "SELECT 'Filial: ' + D1_FILIAL + ' NF/serie: ' + D1_DOC + '/' + D1_SERIE + '  Fornecedor/loja: ' + D1_FORNECE + '/' + D1_LOJA + '  Item NF: ' + D1_ITEM,"
				_sQuery +=       " D1_TOTAL,"
				_sQuery +=       " D1_SEGURO,"
				_sQuery +=       " D1_DESPESA,"
				_sQuery +=       " F4_CREDICM,"
				_sQuery +=       " D1_VALICM,"
				_sQuery +=       " F4_CODIGO,"
				_sQuery +=       " CONHFRETE,"
				_sQuery +=       " D1_QUANT,"
				_sQuery +=       " D1_VALIMP6,"
				_sQuery +=       " D1_VALIMP5"
//				_sQuery +=  " FROM VA_ULTCOMP ('" + cFilAnt + "', '" + _plan -> produto + "', 1)"
				_sQuery +=  " FROM VA_ULTCOMP ('', 'zz', '" + _plan -> produto + "', 1)"
				// u_log (_sQuery)
				_aUltCom = aclone (U_Qry2Array (_sQuery))
				li ++
				if len (_aUltCom) == 0
					@ li, 16 psay "Nao ha dados de ultima compra para calculo do custo"
				else
					@ li, 16 psay "Detalhes do calculo do custo:"
					_nVlrFinal = 0
					@ li, 46 psay "Ultima compra.......: " + _aUltCom [1, 1]
					li ++
					@ li, 46 psay "(+) Valor da nota...: " + transform (_aUltCom [1, 2],  "@E 999,999,999.99")
					li ++
					_nVlrFinal += _aUltCom [1, 2]
					@ li, 46 psay "(+) Valor seguro....: " + transform (_aUltCom [1, 3], "@E 999,999,999.99")
					li ++
					_nVlrFinal += _aUltCom [1, 3]
					@ li, 46 psay "(+) Valor despesa...: " + transform (_aUltCom [1, 4], "@E 999,999,999.99")
					li ++
					_nVlrFinal += _aUltCom [1, 4]
					if _aUltCom [1, 5] == "S"
						@ li, 46 psay "(-) Valor ICMS......: " + transform (_aUltCom [1, 6],   "@E 999,999,999.99") + "   (TES " + _aUltCom [1, 7] + " credita ICMS)"
						_nVlrFinal -= _aUltCom [1, 6]
					else
						@ li, 46 psay "(-) Valor ICMS......: " + transform (0,   "@E 999,999,999.99") + "   (TES " + _aUltCom [1, 7] + " nao credita ICMS)"
					endif
					li ++
					@ li, 46 psay "(+) Frete...........: " + transform (_aUltCom [1, 8], "@E 999,999,999.99")
					_nVlrFinal += _aUltCom [1, 8]
					li ++
					@ li, 46 psay "(-) Valor PIS.......: " + transform (_aUltCom [1, 10], "@E 999,999,999.99")
					_nVlrFinal -= _aUltCom [1, 10]
					li ++
					@ li, 46 psay "(-) Valor COFINS....: " + transform (_aUltCom [1, 11], "@E 999,999,999.99")
					_nVlrFinal -= _aUltCom [1, 11]
					li ++
					_nVlrFinal += _aUltCom [1, 8]
					@ li, 46 psay "Valor final.........: " + transform (_nVlrFinal,  "@E 999,999,999.99") + "  -->  " + alltrim (transform (_nVlrFinal,  "@E 999,999,999.99")) + "/" + alltrim (transform (_aUltCom [1, 9],  "@E 999,999,999.99")) + "(quant) = " + alltrim (transform (_nVlrFinal/_aUltCom [1, 9],  "@E 999,999.9999"))
				endif
				li += 2
			endif
			_plan -> (dbskip ())
		enddo
		li += 2
		U_ImpParam (_nMaxLin)

	else

		// Exporta para planilha
		incproc ("Gerando planilha...")
		U_Trb2XLS ("_plan", .F.)
	endif

	U_ArqTrb ("FechaTodos",,,, @_aArqTrb)
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                           Help
	aadd (_aRegsPerg, {01, "Tipo produto de               ", "C", 2,  0,  "",   "02 ", {},                              "Tipo de produto inicial a ser listado"})
	aadd (_aRegsPerg, {02, "Tipo produto ate              ", "C", 2,  0,  "",   "02 ", {},                              "Tipo de produto final a ser listado"})
	aadd (_aRegsPerg, {03, "Produto de                    ", "C", 15, 0,  "",   "SB1", {},                              "Produto inicial a ser listado"})
	aadd (_aRegsPerg, {04, "Produto ate                   ", "C", 15, 0,  "",   "SB1", {},                              "Produto final a ser listado"})
	aadd (_aRegsPerg, {05, "Qt.compras media ult. compras ", "N", 1,  0,  "",   "   ", {},                              "Quantidade de notas a serem consideradas na media das ultimas compras"})
	aadd (_aRegsPerg, {06, "Produtos / pais fora de linha ", "N", 1,  0,  "",   "   ", {"Desconsiderar", "Considerar"}, "Indique se deseja listar produtos fora de linha ou, quando componentes, cujos pais estao fora de linha."})
	aadd (_aRegsPerg, {07, "Listar produtos bloqueados    ", "N", 1,  0,  "",   "   ", {"Sim", "Nao"},                  "Indique se deseja listar produtos bloqueados"})
	aadd (_aRegsPerg, {08, "Destino                       ", "N", 1,  0,  "",   "   ", {"Relatorio", "Planilha"},       ""})
	aadd (_aRegsPerg, {09, "Detalhar calculo do custo     ", "N", 1,  0,  "",   "   ", {"Sim", "Nao"},                  ""})
	U_ValPerg (cPerg, _aRegsPerg)
Return
