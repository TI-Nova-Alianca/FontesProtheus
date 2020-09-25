// Programa:   VA_PJE
// Autor:      Robert Koch
// Data:       01/10/2008
// Cliente:    Alianca
// Descricao:  Relatorio de projecao de estoques.
// 
// Historico de alteracoes:
// 20/08/2009 - Robert - Remodelado para leitura de previsoes do SC4
// 16/09/2009 - Robert - Novos parametros
// 26/04/2010 - Robert - Considerava OPs encerradas
//                     - Perdia saldo do produto quando o mesmo nao tinha pedido de venda
// 16/04/2015 - Robert - Tratamento da filial 03 (Livramento) passado para 13 (Caxias).
// 20/10/2015 - Robert - Desconsidera OPs previstas.
//                     - Se uma filial nao tivesse pedido/prev.venda/OP, nao olhava seu estoque.
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
user function VA_PJE (_lAutomat)
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	private _sArqLog := U_Nomelog ()

	u_logIni ()
	
	// Variaveis obrigatorias dos programas de relatorio
	cDesc1   := "Relatorio de projecao semanal de estoques"
	cDesc2   := ""
	cDesc3   := ""
	cString  := "SB1"
	aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	nLastKey := 0
	Titulo   := "Relatorio de projecao semanal de estoques"
	cPerg    := "VA_PJE"
	nomeprog := "VA_PJE"
	wnrel    := "VA_PJE"
	tamanho  := "G"
	limite   := 220
	nTipo    := 15
	m_pag    := 1
	li       := 80
	cCabec1  := ""
	cCabec2  := ""
	aOrd     := {}
	
	_ValidPerg ()
	pergunte (cPerg, .F.)

	if ! _lAuto

		// Execucao com interface com o usuario.
		//wnrel:=SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,cDesc2,cDesc3,.F., aOrd, .T., NIL, tamanho, NIL, .F., NIL, NIL, .F., .T., NIL)
	    wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
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
		//aReturn [8] = 1
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
	MS_FLUSH ()
	DbCommitAll ()

	// Se era execucao via rotina automatica, converte o relatorio para TXT.
	if _lAuto
		_sErroConv = U_ML_R2T (__reldir + wnrel + ".##r", __reldir + wnrel + ".txt")
		if ! empty (_sErroConv)
			u_help (_sErroConv)
		endif
	else
		If aReturn [5] == 1
			ourspool(wnrel)
		Endif
	endif
	u_logFim ()
return




// --------------------------------------------------------------------------
static function _Imprime ()
	local _nMaxLin   := 63
	local _sQuery    := ""
	local _aAliasQ   := ""
	local _oDUtil    := ClsDUtil():New ()
	local _oAUtil    := NIL
	local _aSemanas  := {}
	local _nSemana   := 0
	local _aArqtrb   := {}  // Para arquivos de trabalho
	local _aAlmox    := {}
	local _nAlmox    := 0
	local _aCols     := {}
	local _aFil01    := {}
	local _nFilial   := 0
	local _sFilial   := ""
	local _nTotSald  := 0
	local _aDescob   := {}
	local _aProd     := {}
	local _nProd     := 0
	li = _nMaxLin + 1

	u_logIni ()
	// Nao aceita filtro por que precisaria inserir na query.
	If !Empty(aReturn[7])
		u_help ("Este relatorio nao aceita filtro do usuario.")
		return
	EndIf	


	// Monta array com as filiais a considerar.
	_aFil01 = {}
	if mv_par10 == 1 .or. mv_par12 == 1
		if mv_par10 == 1
			aadd (_aFil01, "01")
		endif
		if mv_par12 == 1
			aadd (_aFil01, "13")
		endif
	endif


	// Monta markbrowses para o usuario selecionar os armazens de cada filial.
	// Nao pergunta almoxarifados da vinicola por que a mesma nao tem estoques.
	if ! _lAuto
		_aCols = {}
		aadd (_aCols, {2, "Armazem",   30, ""})
		aadd (_aCols, {3, "Descricao", 80, ""})
		if mv_par10 == 1  // Matriz
			_sQuery := ""
			_sQuery += "SELECT '', X5_CHAVE, X5_DESCRI"
			_sQuery +=  " FROM SX5010 SX5"
			_sQuery += " WHERE SX5.D_E_L_E_T_ = ''"
			_sQuery +=   " AND SX5.X5_FILIAL  = '  '"
			_sQuery +=   " AND SX5.X5_TABELA  = 'AL'"
			_sQuery += " ORDER BY X5_CHAVE"
			_aAlmox := aclone (U_Qry2Array (_sQuery))
			for _nAlmox = 1 to len (_aAlmox)
				_aAlmox [_nAlmox, 1] = (at (alltrim (_aAlmox [_nAlmox, 2]), mv_par11) > 0)
			next
			mv_par11 = ""
			if len (_aAlmox) > 0
				U_MbArray (@_aAlmox, "Selecione armazens da matriz", _aCols, 1, 500, 300, ".t.")
				for _nAlmox = 1 to len (_aAlmox)
					if _aAlmox [_nAlmox, 1]
						mv_par11 += alltrim (_aAlmox [_nAlmox, 2]) + iif (_nAlmox < len (_aAlmox), "/", "")
					endif
				next
			endif
		endif
		if mv_par12 == 1  // Caxias
			_sQuery := ""
			_sQuery += "SELECT '', X5_CHAVE, X5_DESCRI"
			_sQuery +=  " FROM SX5010 SX5"
			_sQuery += " WHERE SX5.D_E_L_E_T_ = ''"
			_sQuery +=   " AND SX5.X5_FILIAL  = '  '"
			_sQuery +=   " AND SX5.X5_TABELA  = 'AL'"
			_sQuery += " ORDER BY X5_CHAVE"
			_aAlmox := aclone (U_Qry2Array (_sQuery))
			for _nAlmox = 1 to len (_aAlmox)
				_aAlmox [_nAlmox, 1] = (at (alltrim (_aAlmox [_nAlmox, 2]), mv_par13) > 0)
			next
			mv_par13 = ""
			if len (_aAlmox) > 0
				U_MbArray (@_aAlmox, "Selecione armazens de Caxias", _aCols, 1, 500, 300, ".t.")
				for _nAlmox = 1 to len (_aAlmox)
					if _aAlmox [_nAlmox, 1]
						mv_par13 += alltrim (_aAlmox [_nAlmox, 2]) + iif (_nAlmox < len (_aAlmox), "/", "")
					endif
				next
			endif
			U_GravaSX1 (cPerg, "11", mv_par11)
			U_GravaSX1 (cPerg, "13", mv_par13)
		endif
	endif

	procregua (4)
	incproc ("Gerando periodos...")

	// Monta array com as semanas a listar
	_aSemanas := aclone (_oDUtil:Semanas (ddatabase, ddatabase +100))  // Certamente serao semanas suficientes.
	_oAUtil   := ClsAUtil():New (_aSemanas)
	_oAUtil:Del (14, len (_oAUtil:_aArray))  // Deleta as posicoes excedentes
	_aSemanas := aclone (_oAUtil:_aArray)


	// Monta cabecalhos das colunas com as datas dos periodos
	if mv_par09 == 1  // Resumido
		cCabec1  = "Produto                                                Local     Estq     Estq.tot       "
		cCabec2  = "                                                               minimo        atual       "
	else
		cCabec1  = "Produto                                                Local     Estq   Alm   Estq       "
		cCabec2  = "                                                               minimo        atual       "
	endif
	for _nSemana = 1 to len (_aSemanas)
		cCabec1 += "  de " + left (dtoc (_aSemanas [_nSemana, 1]), 5)
		cCabec2 += "   a " + left (dtoc (_aSemanas [_nSemana, 2]), 5)
	next


	// Monta arquivo de trabalho para facilitar a preparacao dos dados.
	incproc ("Montando arquivo temporario...")
	_aCampos = {}
	aadd (_aCampos, {"Filial",     "C", 2,  0})
	aadd (_aCampos, {"Produto",    "C", 15, 0})
	aadd (_aCampos, {"Descri",     "C", 60, 0})
	aadd (_aCampos, {"TipoReg",    "C", 1,  0})
	aadd (_aCampos, {"Almox",      "C", 2,  0})
	aadd (_aCampos, {"Estoque",    "N", 18, 2})
	aadd (_aCampos, {"EstMin",     "N", 18, 2})
	for _nSemana = 1 to len (_aSemanas)
		aadd (_aCampos, {"Per" + strzero (_nSemana, 2), "N", 18, 2})
	next
	U_ArqTrb ("Cria", "_trb", _aCampos, {"Filial + Produto + TipoReg", "Produto + Filial + TipoReg"}, @_aArqTrb)
	_trb -> (dbsetorder (1))

	incproc ("Buscando pedidos de venda")
	for _nFilial = 1 to len (_aFil01)
		_sFilial = _aFil01 [_nFilial]
		_sQuery := ""
		_sQuery += "SELECT C6_PRODUTO, C6_ENTREG, SUM (C6_QTDVEN - C6_QTDENT) QUANT"
		_sQuery +=  " FROM " + RetSQLName ("SC6") + " SC6, "
		_sQuery +=        "SB1010 SB1 "
		_sQuery += " WHERE SC6.D_E_L_E_T_ = ''"
		_sQuery +=   " AND SC6.C6_FILIAL  = '" + _sFilial + "'"
		_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
		_sQuery +=   " AND SB1.B1_FILIAL  = '  '"
		_sQuery +=   " AND SB1.B1_COD     = SC6.C6_PRODUTO"
		_sQuery +=   " AND SB1.B1_TIPO    BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
		_sQuery +=   " AND SB1.B1_CODLIN  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
		_sQuery +=   " AND SC6.C6_PRODUTO BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
		_sQuery +=   " AND SC6.C6_BLQ != 'R'"
		_sQuery +=   " AND SC6.C6_BLQ != 'S'"
		_sQuery +=   " AND SC6.C6_BLOQUEI = ''"
		_sQuery +=   " AND SC6.C6_LOCAL   IN " + FormatIn (alltrim (iif (_sFilial == "01", mv_par11, mv_par13)), "/")
		_sQuery +=   " AND C6_QTDVEN > C6_QTDENT"
		_sQuery +=   " AND C6_ENTREG <= '" + dtos (_aSemanas [len (_aSemanas), 2]) + "'"
		_sQuery +=   " AND C6_ENTREG >= '" + dtos (dDataBase - 90) + "'"  // Pedidos mais antigos que isso eh por que foram esquecidos.
		_sQuery += " GROUP BY C6_PRODUTO, C6_ENTREG"
		//u_log (_squery)
		_sAliasQ = GetNextAlias ()
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
		TCSetField (alias (), "C6_ENTREG", "D")
		Do While ! (_sAliasQ) -> (Eof())
	
			// Verifica em qual periodo deve ser acumulado
			_nSemana = ascan (_aSemanas, {|_aVal| _aVal [1] <= (_sAliasQ) -> c6_entreg .and. _aVal [2] >= (_sAliasQ) -> c6_entreg})
			if _nSemana == 0  // Provavelmente eh pedido atrasado
				_nSemana = 1
			endif
	
			reclock ("_trb", ! _trb -> (dbseek (_sFilial + (_sAliasQ) -> c6_produto + "1", .F.)))
			_trb -> filial  = _sFilial
			_trb -> produto = (_sAliasQ) -> c6_produto
			_trb -> TipoReg = "1"
			_trb -> &("per" + strzero (_nSemana, 2)) += (_sAliasQ) -> quant
			msunlock ()
			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())
	next


	incproc ("Buscando previsoes de venda")
	for _nFilial = 1 to len (_aFil01)
		_sFilial = _aFil01 [_nFilial]
		_sQuery := ""
		_sQuery += "SELECT C4_FILIAL, C4_PRODUTO, C4_DATA, SUM (C4_QUANT) QUANT"
		_sQuery +=  " FROM " + RetSQLName ("SC4") + " SC4, "
		_sQuery +=        "SB1010 SB1 "
		_sQuery += " WHERE SC4.D_E_L_E_T_ = ''"
		_sQuery +=   " AND SC4.C4_FILIAL  = '" + _sFilial + "'"
		_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
		_sQuery +=   " AND SB1.B1_FILIAL  = '  '"
		_sQuery +=   " AND SB1.B1_COD     = SC4.C4_PRODUTO"
		_sQuery +=   " AND SB1.B1_TIPO    BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
		_sQuery +=   " AND SB1.B1_CODLIN  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
		_sQuery +=   " AND SC4.C4_PRODUTO BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
		_sQuery +=   " AND SC4.C4_LOCAL   IN " + FormatIn (alltrim (iif (_sFilial == "01", mv_par11, mv_par13)), "/")
		_sQuery +=   " AND C4_DATA >= '" + dtos (_aSemanas [1, 1]) + "'"
		_sQuery +=   " AND C4_DATA <= '" + dtos (_aSemanas [len (_aSemanas), 2]) + "'"
		_sQuery += " GROUP BY C4_FILIAL, C4_PRODUTO, C4_DATA"
//			u_log (_squery)
		_sAliasQ = GetNextAlias ()
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
		TCSetField (alias (), "C4_DATA", "D")
		Do While ! (_sAliasQ) -> (Eof())
	
			// Verifica em qual periodo deve ser acumulado
			_nSemana = ascan (_aSemanas, {|_aVal| _aVal [1] <= (_sAliasQ) -> c4_data .and. _aVal [2] >= (_sAliasQ) -> c4_data})
	
			reclock ("_trb", ! _trb -> (dbseek (_sFilial + (_sAliasQ) -> c4_produto + "2", .F.)))
			_trb -> filial  = _sFilial
			_trb -> produto = (_sAliasQ) -> c4_produto
			_trb -> TipoReg = "2"
			_trb -> &("per" + strzero (_nSemana, 2)) += (_sAliasQ) -> quant
			msunlock ()
			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())
	next


	incproc ("Buscando ordens de producao")
	for _nFilial = 1 to len (_aFil01)
		_sFilial = _aFil01 [_nFilial]
		_sQuery := ""
		_sQuery += "SELECT C2_FILIAL, C2_PRODUTO, C2_DATPRF, SUM (C2_QUANT) QUANT"
		_sQuery +=  " FROM " + RetSQLName ("SC2") + " SC2, "
		_sQuery +=        "SB1010 SB1 "
		_sQuery += " WHERE SC2.D_E_L_E_T_ = ''"
		_sQuery +=   " AND SC2.C2_FILIAL  = '" + _sFilial + "'"
		_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
		_sQuery +=   " AND SB1.B1_FILIAL  = '  '"
		_sQuery +=   " AND SB1.B1_COD     = SC2.C2_PRODUTO"
		_sQuery +=   " AND SB1.B1_TIPO    BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
		_sQuery +=   " AND SB1.B1_CODLIN  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
		_sQuery +=   " AND SC2.C2_PRODUTO BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
		_sQuery +=   " AND SC2.C2_LOCAL   IN " + FormatIn (alltrim (iif (_sFilial == "01", mv_par11, mv_par13)), "/")
		_sQuery +=   " AND C2_DATPRF >= '" + dtos (_aSemanas [1, 1]) + "'"
		_sQuery +=   " AND C2_DATPRF <= '" + dtos (_aSemanas [len (_aSemanas), 2]) + "'"
		_sQuery +=   " AND C2_DATRF   = ''"
		_sQuery +=   " AND C2_TPOP    = 'F'"
		_sQuery += " GROUP BY C2_FILIAL, C2_PRODUTO, C2_DATPRF"
//		u_log (_squery)
		_sAliasQ = GetNextAlias ()
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
		TCSetField (alias (), "C2_DATPRF", "D")
		Do While ! (_sAliasQ) -> (Eof())
	
			// Verifica em qual periodo deve ser acumulado
			_nSemana = ascan (_aSemanas, {|_aVal| _aVal [1] <= (_sAliasQ) -> c2_datprf .and. _aVal [2] >= (_sAliasQ) -> c2_datprf})
	
			reclock ("_trb", ! _trb -> (dbseek (_sFilial + (_sAliasQ) -> c2_produto + "3", .F.)))
			_trb -> filial  = _sFilial
			_trb -> produto = (_sAliasQ) -> c2_produto
			_trb -> TipoReg = "3"
			_trb -> &("per" + strzero (_nSemana, 2)) += (_sAliasQ) -> quant
			msunlock ()
			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())
	next


	// Cria registro para o saldo disponivel de cada produto.
	_trb -> (DbGoTop ())
	Do While ! _trb -> (Eof())
		_sFilial  = _trb -> filial
		_sProduto = _trb -> produto
		_aPed    := afill (array (len (_aSemanas)), 0)
		_aPrev   := afill (array (len (_aSemanas)), 0)
		_aOP     := afill (array (len (_aSemanas)), 0)
		_aSaldos := afill (array (len (_aSemanas)), 0)

		// Acumula cada tipo de registro do produto atual
		Do While ! _trb -> (Eof()) .and. _trb -> filial == _sFilial .and. _trb -> produto == _sProduto
			for _nSemana = 1 to len (_aSemanas)
				if _trb -> TipoReg == "1"
					_aPed  [_nSemana] += _trb -> &("Per" + strzero (_nSemana, 2))
				elseif _trb -> TipoReg == "2"
					_aPrev [_nSemana] += _trb -> &("Per" + strzero (_nSemana, 2))
				elseif _trb -> TipoReg == "3"
					_aOP   [_nSemana] += _trb -> &("Per" + strzero (_nSemana, 2))
				endif
			next
			_trb -> (dbskip ())
		enddo
		
		// Considera o maior entre pedidos de venda e previsoes de venda
		for _nSemana = 1 to len (_aSemanas)
			_aSaldos [_nSemana] -= max (_aPed [_nSemana], _aPrev [_nSemana])
			_aSaldos [_nSemana] += _aOP [_nSemana]
		next
		reclock ("_trb", .T.)
		_trb -> filial  = _sFilial
		_trb -> produto = _sProduto
		_trb -> TipoReg = "4"
		for _nSemana = 1 to len (_aSemanas)
			_trb -> &("Per" + strzero (_nSemana, 2)) = _aSaldos [_nSemana]
		next
		msunlock ()
		_trb -> (dbskip ())
	enddo


	// Monta array com todos os produtos do arquivo de trabalho para que os mesmos
	// possam ser reprocessados (serao criados novos registros no arquivo de trabalho,
	// o que dificulta o seu processamento completo, pois mexe com os indices. Tendo
	// todos os produtos em uma lista separada, tem-se certeza de que todos serao reprocessados.
	_aProd = {}
	_trb -> (DbGoTop ())
	Do While ! _trb -> (Eof())
		if ascan (_aProd, _trb -> produto) == 0
			aadd (_aProd, _trb -> produto)
		endif
		_trb -> (dbskip ())
	enddo
	//u_log ("_aprod", _aprod)

	// Preenche descricao, busca saldo em estoque e atualiza registro de saldos.
	sb1 -> (dbsetorder (1))
	sb2 -> (dbsetorder (1))
	for _nProd = 1 to len (_aProd)
		_sProduto = _aProd [_nProd]
		sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))

		for _nFilial = 1 to len (_aFil01)
			_sFilial = _aFil01 [_nFilial]

			_nTotSald = 0
	
			_sQuery := ""
			_sQuery += "SELECT B2_LOCAL, B2_QATU - B2_RESERVA AS SALDO"
			_sQuery +=  " FROM " + RetSQLName ("SB2") + " SB2 "
			_sQuery += " WHERE SB2.D_E_L_E_T_ = ''"
			_sQuery +=   " AND SB2.B2_FILIAL  = '" + _sFilial + "'"
			_sQuery +=   " AND SB2.B2_COD     = '" + _sProduto + "'"
			_sQuery +=   " AND SB2.B2_LOCAL   IN " + FormatIn (alltrim (iif (_sFilial == "01", mv_par11, mv_par13)), "/")
			_sQuery +=   " AND B2_QATU - B2_RESERVA != 0"
			_sQuery += " ORDER BY B2_LOCAL"
			//u_log (_sQuery)
			_sAliasQ = GetNextAlias ()
			DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
			Do While ! (_sAliasQ) -> (Eof())
				reclock ("_trb", .t.)
				_trb -> filial  = _sFilial
				_trb -> produto = _sProduto
				_trb -> descri  = sb1 -> b1_desc
				_trb -> TipoReg = "0"
				_trb -> Almox   = (_sAliasQ) -> b2_local
				_trb -> Estoque = (_sAliasQ) -> saldo
				_trb -> EstMin  = sb1 -> b1_emin
				msunlock ()
				_nTotSald += (_sAliasQ) -> saldo
				(_sAliasQ) -> (dbskip ())
			enddo
			(_sAliasQ) -> (dbclosearea ())
			dbselectarea ("_trb")

			// Com os registros de saldos em estoque criados, percorre novamente o produto
			// atualizando descricao, estoque minimo e recalculando a linha de saldos.
			_trb -> (dbseek (_sFilial + _sProduto, .T.))
			Do While ! _trb -> (Eof()) .and. _trb -> filial == _sFilial .and. _trb -> produto == _sProduto
				if _trb -> TipoReg > "0"
					reclock ("_trb", .F.)
					_trb -> descri = sb1 -> b1_desc
					_trb -> EstMin  = sb1 -> b1_emin
					_trb -> estoque = _nTotSald
					
					// Acumula o saldo disponivel dos periodos.
					if _trb -> TipoReg == "4"
						_trb -> per01 += _trb -> estoque
						for _nSemana = 2 to len (_aSemanas)
							_trb -> &("Per" + strzero (_nSemana, 2)) += _trb -> &("Per" + strzero (_nSemana - 1, 2))
						next
					endif
					msunlock ()
				endif
				_trb -> (dbskip ())
			enddo
		next
		//u_log ("Atualizei tipo 4")
	next


	// Criado o arquivo de trabalho com os saldos dos periodos, verifica se deve eliminar
	// os produtos com cobertura de estoque
	if mv_par07 == 1

		// Monta lista dos produtos descobertos
		_aDescob = {}
		_trb -> (DbGoTop ())
		Do While ! _trb -> (Eof())
			if _trb -> TipoReg == "4"
				for _nSemana = 2 to min (len (_aSemanas), mv_par08)
					if _trb -> &("Per" + strzero (_nSemana, 2)) < 0
						aadd (_aDescob, {_trb -> filial, _trb -> produto})
						exit
					endif
				next
			endif
			_trb -> (dbskip ())
		enddo
		
		// Deixa no arquivo somente os produtos descobertos.
		_trb -> (DbGoTop ())
		Do While ! _trb -> (Eof())
			if ascan (_aDescob, {|_aVal| _aVal [1] == _trb -> filial .and. _aVal [2] == _trb -> produto}) == 0
				reclock ("_trb", .F.)
				_trb -> (dbdelete ())
				msunlock ()
			endif
			_trb -> (dbskip ())
		enddo
	endif

	// Impressao
	_sProduto = ""
	_trb -> (dbsetorder (2))
	_trb -> (DbGoTop ())
	Do While ! _trb -> (Eof())
		IncProc ()
		if li > _nMaxLin
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		endif

		// Controla quebra por produto para imprimir a descricao somente uma vez.
		_sProduto = _trb -> produto
		_sLinImp = u_tamfixo (alltrim (_trb -> produto) + " - " + _trb -> descri, 53)
		@ li, 0 psay _sLinImp
		Do While ! _trb -> (Eof()) .and. _trb -> produto == _sProduto
			_sFilial  = _trb -> filial
			_sLinImp  = ""
			if _trb -> filial == "01"
				_sLinImp += "Matriz "
			elseif _trb -> filial == "13"
				_sLinImp += "Caxias "
			endif
			_sLinImp += transform (_trb -> estMin, "@E 999,999") + "  "
			@ li, 55 psay _sLinImp

			Do While ! _trb -> (Eof()) .and. _trb -> produto == _sProduto .and. _trb -> filial == _sFilial
				_sLinImp = ""
				if mv_par09 == 2  // Detalhado
					if _trb -> TipoReg == "0"
						_sLinImp += " " + _trb -> almox + " "
						_sLinImp += transform (_trb -> estoque, "@E 999,999")
					else
						_sLinImp += space (12)
						if _trb -> TipoReg == "1" .and. mv_par09 == 2
							_sLinImp += "Ped.vd:"
						elseif _trb -> TipoReg == "2" .and. mv_par09 == 2
							_sLinImp += "Prv.vd:"
						elseif _trb -> TipoReg == "3" .and. mv_par09 == 2
							_sLinImp += "O.P.:  "
						elseif _trb -> TipoReg == "4" .and. mv_par09 == 2
							_sLinImp += "Saldos:"
						else
							_sLinImp += "??????"
						endif
						for _nSemana = 1 to len (_aSemanas)
							_sLinImp += transform (_trb -> &("Per" + strzero (_nSemana, 2)), "@E 9,999,999") + " "
						next
					endif
				else
					// No rel. resumido lista somente o tipo 4
					if _trb -> TipoReg == "4"
						_sLinImp += " " + transform (_trb -> estoque, "@E 99,999,999") + "  "
						_sLinImp += "Saldo:"
						for _nSemana = 1 to len (_aSemanas)
							_sLinImp += transform (_trb -> &("Per" + strzero (_nSemana, 2)), "@E 9,999,999") + " "
						next
					endif
				endif
				if ! empty (_sLinImp)
					@ li, 71 psay _sLinImp
					li ++
				endif
				_trb -> (dbskip ())
			enddo
		enddo
		if mv_par09 == 2
			li ++
		endif
	enddo
	U_ArqTrb ("FechaTodos",,,, @_aArqTrb)
	
	// Imprime parametros usados na geracao do relatorio
	li ++
	U_ImpParam (_nMaxLin)
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Tipo de produto de            ", "C", 02, 0,  "",   "02 ", {},                         ""})
	aadd (_aRegsPerg, {02, "Tipo de produto ate?          ", "C", 02, 0,  "",   "02 ", {},                         ""})
	aadd (_aRegsPerg, {03, "Linha de produtos de?         ", "C", 02, 0,  "",   "88 ", {},                         ""})
	aadd (_aRegsPerg, {04, "Linha de produtos ate?        ", "C", 02, 0,  "",   "88 ", {},                         ""})
	aadd (_aRegsPerg, {05, "Produto de?                   ", "C", 15, 0,  "",   "SB1", {},                         "Produto inicial a ser considerado"})
	aadd (_aRegsPerg, {06, "Produto ate?                  ", "C", 15, 0,  "",   "SB1", {},                         "Produto final a ser considerado"})
	aadd (_aRegsPerg, {07, "Somente descobertos ou todos? ", "N", 1,  0,  "",   "   ", {"Descoberto", "Todos"},    "Descobertos: itens que tem previsao de ficarem negativos dentro do periodo informado no parametro seguinte"})
	aadd (_aRegsPerg, {08, "Estq. descoberto a partir de? ", "N", 2,  0,  "",   "   ", {},                         "Numero de semanas a partir do qual os produtos tem previsao de ficarem negativos"})
	aadd (_aRegsPerg, {09, "Resumido ou detalhado?        ", "N", 1,  0,  "",   "   ", {"Resumido", "Detalhado"},  "Formato do relatorio"})
	aadd (_aRegsPerg, {10, "Considera matriz?             ", "N", 1,  0,  "",   "   ", {"Sim", "Nao"},             ""})
	aadd (_aRegsPerg, {11, "Almoxarifados matriz          ", "C", 60, 0,  "",   "AL ", {},                         "Almoxarifados a considerar, separados por barras (/)"})
	aadd (_aRegsPerg, {12, "Considera filial Caxias?      ", "N", 1,  0,  "",   "   ", {"Sim", "Nao"},             ""})
	aadd (_aRegsPerg, {13, "Almoxarifados filial Caxias   ", "C", 60, 0,  "",   "AL ", {},                         "Almoxarifados a considerar, separados por barras (/)"})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
