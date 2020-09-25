// Programa:   VA_RCarg
// Autor:      Robert Koch
// Data:       16/042014
// Descricao:  Romaneio de carga OMS.
// 
// Historico de alteracoes:
// 20/05/2014 - Tiago DWT - Melhorias diversas
// 09/06/2014 - Robert    - Destacada mensagem de 'declaro que foi minha culpa', etc.
// 08/07/2015 - Robert    - Possibilidade de receber parametros na chamada. 
// 31/08/2015 - Robert    - Criado parametro para buscar obs. e msg. do pedido de venda.
// 18/11/2015 - Catia     - Observacoes de Clientes
// 29/08/2019 - Cláudia   - Alterado o campo de peso bruto de B1_P_BRT para B1_PESBRU  
//							Na montagem de carga o valor do DAK_PESO ficava diferenciado do relatório.
// --------------------------------------------------------------------------
user function VA_RCarg (_lAutomat, _sCarga, _dEmissao, _sTipo, _nSintet)
	local _aRet     := {}
	private _lAuto  := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)  // Uso sem interface com o usuario.
//	private _sArqLog := U_NomeLog ()

	// Variaveis obrigatorias dos programas de relatorio
	Titulo   := "Romaneio de Carga"
	cDesc1   := Titulo
	cDesc2   := ""
	cDesc3   := ""
	cString  := "DAK"
	aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	nLastKey := 0
	cPerg    := "VA_RCARG"
	nomeprog := "VA_RCARG"
	wnrel    := "VA_RCARG"
	tamanho  := "M"
	limite   := 132
	nTipo    := 15
	m_pag    := 1
	li       := 80
	cCabec1  := "Produto         Descricao                                                    Quantidade UM      Peso unit     Peso total Kg"
 	cCabec2  := ""
	aOrd     := {}
	
	_ValidPerg ()
	if valtype (_sCarga) != "U"
		U_GravaSX1 (cPerg, '01', _sCarga)
		U_GravaSX1 (cPerg, '02', _sCarga)
	endif
	if valtype (_dEmissao) != "U"
		U_GravaSX1 (cPerg, '03', _dEmissao)
		U_GravaSX1 (cPerg, '04', _dEmissao)
	endif
	if valtype (_sTipo) != "U"
		U_GravaSX1 (cPerg, '05', _sTipo)
	endif
	if valtype (_nSintet) != "U"
		U_GravaSX1 (cPerg, '06', _nSintet)
	endif

	pergunte (cPerg, .F.)
	
	if ! _lAuto
		// Execucao com interface com o usuario.
		wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
	else
		// Execucao sem interface com o usuario.
		// Deleta o arquivo do relatorio para evitar a pergunta se deseja sobrescrever.
		delete file (__reldir + wnrel + ".##r")
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
return _aRet

// --------------------------------------------------------------------------
static function _Imprime ()
	local _nMaxLin   := 63
	local _oSQL      := NIL
	local _aTCarga   := {}
	local _aTGeral   := {}
	local _sCarga    := ""
	local _sLinImp   := 0
	local _sAliasQ   := ""
	local _nQtCarg   := 0
	local _aNotas    := {}
	local _sNotas    := ""
	local _nNota     := 0
	local _sMensNota := ""
	local _aMensNota := {}
	local _nMensNota := 0
	local _sPedido   := ""
	local _sObsPed   := ""
	local _aObsPed   := {}
	local _nObsPed   := 0
	local _i		 := 0
	local j		     := 0
	local i			 := 0

	// Nao aceita filtro por que precisaria inserir na query.
	If !Empty(aReturn[7])
		u_help ("Este relatorio nao aceita filtro do usuario.")
		return
	EndIf	

	li = _nMaxLin + 1
	procregua (3)
    
	// Leitura inicial dos dados.
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DAK.DAK_COD, DAK.DAK_DATA, "
	_oSQL:_sQuery += "        DAK.DAK_VATRAN, ISNULL (SA4.A4_NOME, '') AS NOMETR,"
	_oSQL:_sQuery += "        ISNULL (PED.C9_PRODUTO, '') AS PRODUTO,"
	_oSQL:_sQuery += "        ISNULL (PED.B1_DESC, '') AS DESCRI,"
	_oSQL:_sQuery += "        ISNULL (PED.B1_UM, '') AS UM,"
	_oSQL:_sQuery += "        SUM (ISNULL (PED.C9_QTDLIB, 0)) AS QUANT,"
	_oSQL:_sQuery += "        SUM (ISNULL (PED.B1_PESBRU * PED.C9_QTDLIB, 0)) AS PESO"
	_oSQL:_sQuery += " FROM " + RetSQLName ("DAK") + " DAK "
	_oSQL:_sQuery += "     LEFT JOIN " + RetSQLName ("SA4") + " SA4 "
	_oSQL:_sQuery += "         ON (SA4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "         AND SA4.A4_FILIAL = '" + xfilial ("SA4") + "'"
	_oSQL:_sQuery += "         AND SA4.A4_COD = DAK.DAK_VATRAN),"
	_oSQL:_sQuery +=       RetSQLName ("DAI") + " DAI "
	_oSQL:_sQuery += "     LEFT JOIN (SELECT SC9.C9_PEDIDO,"
	_oSQL:_sQuery +=                       " SC9.C9_PRODUTO,"
	_oSQL:_sQuery +=                       " SB1.B1_DESC,"
	_oSQL:_sQuery +=                       " SC9.C9_QTDLIB,"
	_oSQL:_sQuery +=                       " SB1.B1_UM,"
	_oSQL:_sQuery +=                       " SB1.B1_PESBRU"
	_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SC9") + " SC9, "
	_oSQL:_sQuery +=                             RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery +=                 " WHERE SC9.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                   " AND SC9.C9_FILIAL  = '" + xfilial ("SC9") + "'"
	_oSQL:_sQuery +=                   " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=                   " AND SC9.C9_BLEST = '' " 
	_oSQL:_sQuery +=                   " AND SC9.C9_BLCRED = '' "	
	_oSQL:_sQuery +=                   " AND SB1.B1_COD     = SC9.C9_PRODUTO) as PED"
	_oSQL:_sQuery +=          " ON (PED.C9_PEDIDO = DAI.DAI_PEDIDO)"
	_oSQL:_sQuery += " WHERE DAK.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND DAK.DAK_FILIAL = '" + xfilial ("DAK") + "'"
	_oSQL:_sQuery +=   " AND DAI.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND DAI.DAI_FILIAL = DAK.DAK_FILIAL"
	_oSQL:_sQuery +=   " AND DAI.DAI_COD  = DAK.DAK_COD"
	_oSQL:_sQuery +=   " AND DAK.DAK_COD  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_oSQL:_sQuery +=   " AND DAK.DAK_DATA BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
	_oSQL:_sQuery += " GROUP BY DAK.DAK_COD,"
	_oSQL:_sQuery +=          " DAK.DAK_DATA,"
	_oSQL:_sQuery +=          " DAK.DAK_VATRAN,"
	_oSQL:_sQuery +=          " SA4.A4_NOME,"
	_oSQL:_sQuery +=          " PED.C9_PRODUTO,"
	_oSQL:_sQuery +=          " PED.B1_DESC,"
	_oSQL:_sQuery +=          " PED.B1_UM,"
	_oSQL:_sQuery +=          " PED.B1_PESBRU"
	_oSQL:_sQuery += " ORDER BY DAK.DAK_COD, PED.C9_PRODUTO"
	//u_log (_oSQL:_sQuery)
	_sAliasQ = _oSQL:Qry2Trb (.T.)

	_aTGeral = {}
	do while ! (_sAliasQ) -> (eof ())
		// Quebra pagina por carga.
		_nQtCarg ++
		_sCarga = (_sAliasQ) -> dak_cod
		_aTCarga = {}
		cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		_sLinImp := ""
		_sLinImp += 'Carga: ' + _sCarga + '  ' + dtoc ((_sAliasQ) -> dak_data) + '     '
		_sLinImp += 'Transp.: ' + (_sAliasQ) -> dak_vatrans + ' - ' + (_sAliasQ) -> nometr
		
		@ li, 0 psay _sLinImp
		li += 2
		do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> dak_cod == _sCarga

			if li > _nMaxLin
				cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
			endif

			_sLinImp := ''
			_sLinImp += (_sAliasQ) -> produto + ' '
			_sLinImp += (_sAliasQ) -> descri + ' '
			_sLinImp += transform ((_sAliasQ) -> quant, "@E 999,999.99") + ' '
			_sLinImp += (_sAliasQ) -> UM + ' '
			_sLinImp += transform ((_sAliasQ) -> peso / (_sAliasQ) -> quant, "@E 999,999,999.99") + ' '
			_sLinImp += transform ((_sAliasQ) -> peso, "@E 999,999,999.99")
			@ li, 0 psay _sLinImp
			li ++
				
			// Acumula quantidades e pesos por unidade de medida.
			_i = ascan (_aTCarga, {|_aVal| _aVal [1] == (_sAliasQ) -> um})
			if _i == 0
				aadd (_aTCarga, {(_sAliasQ) -> um, (_sAliasQ) -> quant, (_sAliasQ) -> peso})
			else
				_aTCarga [_i, 2] += (_sAliasQ) -> quant
				_aTCarga [_i, 3] += (_sAliasQ) -> peso
			endif
			_i = ascan (_aTGeral, {|_aVal| _aVal [1] == (_sAliasQ) -> um})
			if _i == 0
				aadd (_aTGeral, {(_sAliasQ) -> um, (_sAliasQ) -> quant, (_sAliasQ) -> peso})
			else
				_aTGeral [_i, 2] += (_sAliasQ) -> quant
				_aTGeral [_i, 3] += (_sAliasQ) -> peso
			endif
					
			(_sAliasQ) -> (dbskip ())
		enddo
	
		@ li, 0 psay __PrtThinLine ()
		li ++
		@ li, 49 psay 'Totais da carga ' + _sCarga + ': '
		for _i = 1 to len (_aTCarga)
			@ li, 73 psay transform (_aTCarga [_i, 2], "@E 999,999,999.99") + ' ' + ;
			              _aTCarga [_i, 1] + '                ' + ;
			              transform (_aTCarga [_i, 3], "@E 999,999,999.99") + ' '
			li ++
		next
		li ++

		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		if Upper(MV_PAR05) == "S"  // Finalidade=separacao
			//pedidos	
			if MV_PAR06 == 1 //analitico (busca os pedidos)
				_oSQL:_sQuery := " SELECT C9_PEDIDO, C9_CLIENTE, A1_NOME, A1_MUN, C9_PRODUTO, B1_DESC, ISNULL (SB1.B1_PESBRU * SC9.C9_QTDLIB, 0) AS PESO, C9_QTDLIB "
				_oSQL:_sQuery += " FROM " + RetSQLName ("SC9") + " SC9 , " + RetSQLName ("SA1") + " SA1, " + RetSQLName ("SB1") + " SB1"
				_oSQL:_sQuery += " WHERE SC9.D_E_L_E_T_ = '' "
				_oSQL:_sQuery += " AND SA1.D_E_L_E_T_ = '' "
				_oSQL:_sQuery += " AND SB1.D_E_L_E_T_ = '' "
				_oSQL:_sQuery += " AND A1_COD = SC9.C9_CLIENTE "
				_oSQL:_sQuery += " AND A1_LOJA = SC9.C9_LOJA " 
				_oSQL:_sQuery += " AND B1_COD = SC9.C9_PRODUTO "
				_oSQL:_sQuery += " AND SC9.C9_FILIAL  = '" + xfilial ("SC9") + "'"
				_oSQL:_sQuery += "AND SC9.C9_CARGA   = '" + _sCarga + "'"
				_oSQL:_sQuery += "ORDER BY C9_PEDIDO "
			else //sintetico
				_oSQL:_sQuery := " SELECT C9_PEDIDO, C9_CLIENTE, A1_NOME, A1_MUN, SUM(ISNULL (SB1.B1_PESBRU * SC9.C9_QTDLIB, 0)) AS PESO, SUM(C9_QTDLIB) "
				_oSQL:_sQuery += " FROM " + RetSQLName ("SC9") + " SC9 , " + RetSQLName ("SA1") + " SA1, " + RetSQLName ("SB1") + " SB1"
				_oSQL:_sQuery += " WHERE SC9.D_E_L_E_T_ = '' "
				_oSQL:_sQuery += " AND SA1.D_E_L_E_T_ = '' "
				_oSQL:_sQuery += " AND SB1.D_E_L_E_T_ = '' "
				_oSQL:_sQuery += " AND A1_COD = SC9.C9_CLIENTE "
				_oSQL:_sQuery += " AND A1_LOJA = SC9.C9_LOJA " 
				_oSQL:_sQuery += " AND B1_COD = SC9.C9_PRODUTO "
				_oSQL:_sQuery += " AND SC9.C9_FILIAL  = '" + xfilial ("SC9") + "'"
				_oSQL:_sQuery += "AND SC9.C9_CARGA   = '" + _sCarga + "'"
				_oSQL:_sQuery += "GROUP BY C9_PEDIDO, C9_CLIENTE, A1_NOME, A1_MUN "
				_oSQL:_sQuery += "ORDER BY C9_PEDIDO "
			endif
		else  // finalidade = entrega (busca as notas)
			//notas
			if MV_PAR06 == 1 //analitico para notas
				_oSQL:_sQuery := " SELECT C9_NFISCAL, C9_CLIENTE, A1_NOME, A1_MUN, C9_PRODUTO, B1_DESC, ISNULL (SB1.B1_PESBRU * SC9.C9_QTDLIB, 0) AS PESO, C9_QTDLIB " "
				_oSQL:_sQuery += " FROM " + RetSQLName ("SC9") + " SC9 , " + RetSQLName ("SA1") + " SA1, " + RetSQLName ("SB1") + " SB1"
				_oSQL:_sQuery += " WHERE SC9.D_E_L_E_T_ = '' "
				_oSQL:_sQuery += " AND SA1.D_E_L_E_T_ = '' "
				_oSQL:_sQuery += " AND SB1.D_E_L_E_T_ = '' "
				_oSQL:_sQuery += " AND A1_COD = SC9.C9_CLIENTE "
				_oSQL:_sQuery += " AND A1_LOJA = SC9.C9_LOJA " 
				_oSQL:_sQuery += " AND B1_COD = SC9.C9_PRODUTO "
				_oSQL:_sQuery += " AND SC9.C9_FILIAL  = '" + xfilial ("SC9") + "'"
				_oSQL:_sQuery += "AND SC9.C9_CARGA   = '" + _sCarga + "'"
				_oSQL:_sQuery += "ORDER BY C9_NFISCAL "
			else //sintetico para notas
				_oSQL:_sQuery := " SELECT C9_NFISCAL, C9_CLIENTE, A1_NOME, A1_MUN, SUM(ISNULL (SB1.B1_PESBRU * SC9.C9_QTDLIB, 0)) AS PESO, SUM(C9_QTDLIB) "
				_oSQL:_sQuery += " FROM " + RetSQLName ("SC9") + " SC9 , " + RetSQLName ("SA1") + " SA1, " + RetSQLName ("SB1") + " SB1"
				_oSQL:_sQuery += " WHERE SC9.D_E_L_E_T_ = '' "
				_oSQL:_sQuery += " AND SA1.D_E_L_E_T_ = '' "
				_oSQL:_sQuery += " AND SB1.D_E_L_E_T_ = '' "
				_oSQL:_sQuery += " AND A1_COD = SC9.C9_CLIENTE "
				_oSQL:_sQuery += " AND A1_LOJA = SC9.C9_LOJA " 
				_oSQL:_sQuery += " AND B1_COD = SC9.C9_PRODUTO "
				_oSQL:_sQuery += " AND SC9.C9_FILIAL  = '" + xfilial ("SC9") + "'"
				_oSQL:_sQuery += " AND SC9.C9_CARGA   = '" + _sCarga + "' "
				_oSQL:_sQuery += "GROUP  BY C9_NFISCAL, C9_CLIENTE, A1_NOME, A1_MUN "
				_oSQL:_sQuery += "ORDER BY C9_NFISCAL "
			endif
		endif
		//u_log (_oSQL:_sQuery)
		_aNotas = aclone (_oSQL:Qry2Array (.F., .F.))
		if len (_aNotas) == 0

			// Busca as notas de faturamento relacionadas a esta carga.
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT DISTINCT C9_NFISCAL"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SC9") + " SC9 "
			_oSQL:_sQuery +=  " WHERE SC9.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SC9.C9_FILIAL  = '" + xfilial ("SC9") + "'"
			_oSQL:_sQuery +=    " AND SC9.C9_CARGA   = '" + _sCarga + "'"
			_oSQL:_sQuery +=  " ORDER BY C9_NFISCAL"
			//u_log (_oSQL:_sQuery)
			_aNotas = aclone (_oSQL:Qry2Array (.F., .F.))
		endif

		if Upper(MV_PAR05) == "S" 
			@ li, 0 psay "Pedidos:"
		else
			@ li, 0 psay "Notas fiscais:"
		endif
		li++
		sc5 -> (dbsetorder (1))
		_compara := ""
		_SumQt := 0
		_SumPes := 0
		for _nNota = 1 to len (_aNotas)
			if li > _nMaxLin
				cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
			endif
			
			if _compara <> _aNotas [_nNota, 1]
				if MV_PAR06 == 1 // sintetico=NAO
					@ li, 5   psay _aNotas [_nNota, 1]
					@ li, 17  psay SubStr(Alltrim(_aNotas [_nNota, 3]),1,25)
					@ li, 44  psay Substr(Alltrim(_aNotas [_nNota, 4]),1,15)
					@ li, 63  psay Alltrim(_aNotas [_nNota, 5])
					@ li, 70  psay Substr(Alltrim(_aNotas [_nNota, 6]),1,35)
					@ li, 100 psay "QT:"+transform (_aNotas [_nNota, 8], "@E 9,999") 
					@ li, 110 psay "P.Bruto:" + transform (_aNotas [_nNota, 7], "@E 999,999.99")
					
					_SumQt +=_aNotas [_nNota, 8]
					_SumPes +=  _aNotas [_nNota, 7]
				else //o campo 5 eh a soma de pessos de todos os itens para o sintetico
					@ li, 5   psay _aNotas [_nNota, 1]
					@ li, 17  psay SubStr(Alltrim(_aNotas [_nNota, 3]),1,25)
					@ li, 44  psay Substr(Alltrim(_aNotas [_nNota, 4]),1,15)
					@ li, 100 psay "QT:"+transform (_aNotas [_nNota, 6], "@E 9,999") 
					@ li, 110 psay "P.Bruto:" + transform (_aNotas [_nNota, 5], "@E 999,999.99")
		
					_SumQt +=_aNotas [_nNota, 6]
					_SumPes +=  _aNotas [_nNota, 5]
				endif 
			    _compara := _aNotas [_nNota, 1]
			else
				if MV_PAR06 == 1 //sintetico=NAO
					@ li, 5   psay _aNotas [_nNota, 1]
					@ li, 17  psay SubStr(Alltrim(_aNotas [_nNota, 3]),1,25)
					@ li, 44  psay Substr(Alltrim(_aNotas [_nNota, 4]),1,15) 
					@ li, 63  psay Alltrim(_aNotas [_nNota, 5])
					@ li, 70  psay Substr(Alltrim(_aNotas [_nNota, 6]),1,35)
					@ li, 100 psay "QT:"+transform (_aNotas [_nNota, 8], "@E 9,999") 
					@ li, 110 psay "P.Bruto:" + transform (_aNotas [_nNota, 7], "@E 999,999.99")
					
					_SumQt +=_aNotas [_nNota, 8]
					_SumPes +=  _aNotas [_nNota, 7]
				else
					@ li, 5 psay _aNotas [_nNota, 1]
					@ li, 17  psay SubStr(Alltrim(_aNotas [_nNota, 3]),1,25)
					@ li, 44  psay Substr(Alltrim(_aNotas [_nNota, 4]),1,15)
					@ li, 100 psay "QT:"+transform (_aNotas [_nNota, 6], "@E 9,999") 
					@ li, 110 psay "P.Bruto:" + transform (_aNotas [_nNota, 5], "@E 999,999.99")					
					
					_SumQt +=_aNotas [_nNota, 6]
					_SumPes +=  _aNotas [_nNota, 5]
				endif 
			endif
			li ++

			if mv_par07 == 2  // imprimir obs pedido
	
				// Nao gosto da forma como foi feito o controle de quebra neste relatorio, mas agora tenho que acompanhar a musica...
				if _nNota == len (_aNotas) .or. (_nNota < len (_aNotas) .and. _aNotas [_nNota, 1] != _aNotas [_nNota + 1, 1])
					if Upper(MV_PAR05) == "S"  // Finalidade=separacao
						_sPedido = _aNotas [_nNota, 1]
					else
						// Busca o primeiro pedido da NF atual. O certo seria buscar na query principal e incluir no group by, mas no momento nao posso
						// alterar a mesma. Que o proximo programador me perdoe... Robert.
						_oSQL := ClsSQL():New ()
						_oSQL:_sQuery := ""
						_oSQL:_sQuery += " SELECT TOP 1 D2_PEDIDO"
						_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD2") + " SD2 "
						_oSQL:_sQuery +=  " WHERE SD2.D_E_L_E_T_ = ''"
						_oSQL:_sQuery +=    " AND SD2.D2_FILIAL  = '" + xfilial ("SD2") + "'"
						_oSQL:_sQuery +=    " AND SD2.D2_DOC     = '" + _aNotas [_nNota, 1] + "'"
						_oSQL:_sQuery +=    " AND SD2.D2_SERIE   = '10 '"
						//u_log (_oSQL:_sQuery)
						_sPedido = _oSQL:RetQry ()
					endif
					if ! empty (_sPedido) .and. sc5 -> (dbseek (xfilial ("SC5") + _sPedido, .F.))
						_sMensNota = ""
						if ! empty (sc5 -> c5_mennota)
							_sMensNota = alltrim (sc5 -> c5_mennota)
						endif
						if ! empty (_sMensNota)
							_aMensNota = U_QuebraTXT (_sMensNota, 115)
							for _nMensNota = 1 to len (_aMensNota)
								@ li, 5 psay iif (_nMensNota == 1, 'Mens. p/NF: ', '            ') + _aMensNota [_nMensNota]
								li ++
							next
						endif
						_sObsPed   = ""
						if ! empty (sc5 -> c5_obs)
							_sObsPed = alltrim (sc5 -> c5_obs)
						endif
						if ! empty (_sObsPed)
							_aObsPed = U_QuebraTXT (_sObsPed, 115)
							for _nObsPed = 1 to len (_aObsPed)
								@ li, 5 psay iif (_nObsPed == 1, 'Obs.pedido: ', '            ') + _aObsPed [_nObsPed]
								li ++
							next
						endif
						if ! empty (_sMensNota) .or. ! empty (_sObsPed)
							li ++
						endif
					endif
				endif																																																												
			endif
		next
		//
		@ li, 10 psay Space(80) + "TOTAIS -> QT:"+transform (_SumQt, "@E 9,999") + "  P.Bruto:" + transform (_SumPes, "@E 999,999.99") 
		li += 2
		// imprime observacoes dos clientes
		_sSQL := ""
		_sSQL += " SELECT DISTINCT (DAI.DAI_CLIENT)"
     	_sSQL += "      , SA1.A1_NOME"
     	if Upper(MV_PAR05) == "S"
	 		_sSQL += "      , SA1.A1_LCODSEP"
		else	 		
	 		_sSQL += "      , SA1.A1_LCODENT"
		endif	 		
  		_sSQL += "   FROM DAI010 AS DAI"
		_sSQL += " 		INNER JOIN SA1010 AS SA1"
		_sSQL += " 			ON (SA1.D_E_L_E_T_  = ''"
		_sSQL += " 				AND SA1.A1_COD  = DAI.DAI_CLIENT"
		_sSQL += " 				AND SA1.A1_LOJA = DAI.DAI_LOJA"
		if Upper(MV_PAR05) == "S"
			_sSQL += " 				AND SA1.A1_LCODSEP != '')"
		else			 
			_sSQL += "              AND SA1.A1_LCODENT != '')"
		endif						
 		_sSQL += " WHERE DAI.D_E_L_E_T_ = ''"
   		_sSQL += "   AND DAI.DAI_FILIAL = '" + xfilial ("DAI") + "'"
   		_sSQL += "   AND DAI.DAI_COD    = '" + _sCarga + "'"
		_sSQL += " ORDER BY DAI.DAI_CLIENT"
		_sObsLog := U_Qry2Array(_sSQL)
		
		if len(_sObsLog) > 0
			if li > _nMaxLin
				cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
			endif
			@ li, 0 psay replicate ("*", limite)
			li ++
			@ li, 0 psay replicate ("*", limite)
			li ++
			@ li, 10 psay "OBSERVAÇÕES:"
			li ++
			
			for i=1 to len(_sObsLog)
				if li > _nMaxLin
					cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
				endif
				@ li, 10 psay "    CLIENTE: " + _sObsLog[i,2] 
				li ++
				_wobscli = U_QuebraTxt(alltrim(MSMM (_sObsLog[i,3],,,,3)),120)
				
				for j=1 to len(_wobsCli)
					if li > _nMaxLin
						cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
					endif
				 	@ li, 23 psay _wobsCli[j] 
					li ++
				next					
			next
		endif			
		// imprime conferencia e assinaturas  
		if li > _nMaxLin - 10
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		endif
		@ li, 0 psay replicate ("*", limite)
		li ++
		@ li, 0 psay replicate ("*", limite)
		li ++
		@ li, 10 psay "ATESTO QUE CONFERI AS MERCADORIAS ACIMA."
		li ++
		if Upper(MV_PAR05) == "E"
			@ li, 10 psay "DECLARO SUA EXATIDAO E PERFEITA GUARDA ATE O CLIENTE, SEM DIREITO DE RECLAMACAO POSTERIOR."
			li += 4
			@ li, 0 psay "  ---------------           ------------------------------             ----------------------------       -----------------------"
			li ++
			@ li, 0 psay "       Placa                        Nome motorista                              Assinatura                           CPF"
		else
			@ li, 0 psay "                                                                       ----------------------------       -----------------------"
			li ++
			@ li, 0 psay "                                                                             Nome Conferente                     Assinatura"
		endif			
		li += 2
		@ li, 0 psay replicate ("*", limite)
		li ++
		@ li, 0 psay replicate ("*", limite)
		li ++
	enddo
	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("DAK")

	if _nQtCarg > 1
		if li > _nMaxLin
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		endif
		@ li, 0 psay __PrtFatLine ()
		li ++
		_sLinImp := ""
		@ li, 45 psay 'Totais gerais do relatorio:'
		for _i = 1 to len (_aTGeral)
			@ li, 73 psay transform (_aTGeral [_i, 2], "@E 999,999,999.99") + ' ' + ;
			              _aTGeral [_i, 1] + '                ' + ;
			              transform (_aTGeral [_i, 3], "@E 999,999,999.99") + ' '
			li ++
		next
		li += 2
	endif

	// Imprime parametros usados na geracao do relatorio
	U_ImpParam (_nMaxLin)
	
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
static function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Carga inicial                 ", "C", 6,  0,  "",   "DAK", {},    ""})
	aadd (_aRegsPerg, {02, "Carga final                   ", "C", 6,  0,  "",   "DAK", {},    ""})
	aadd (_aRegsPerg, {03, "Data inicial geracao carga    ", "D", 8,  0,  "",   "",    {},    ""})
	aadd (_aRegsPerg, {04, "Data final geracao carga      ", "D", 8,  0,  "",   "",    {},    ""})
	aadd (_aRegsPerg, {05, "(S)Separacao ou (E)Entrega?   ", "C", 1,  0,  "",   "",    {},    ""})
	aadd (_aRegsPerg, {06, "Sintetico?                    ", "N", 1,  0,  "",   "",    {"1-Nao","2-Sim"},    ""})	
	aadd (_aRegsPerg, {07, "Imprime observacoes pedido?   ", "N", 1,  0,  "",   "",    {"1-Nao","2-Sim"},    ""})	
	
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return