// Programa:   _matr909
// Autor:      Robert Koch
// Data:       06/09/2017
// Descricao:  Relatorio controle selos de IPI 
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function _MATR909 (_lAutomat)
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	// Variaveis obrigatorias dos programas de relatorio
	cDesc1   := "Selos de controle"
	cDesc2   := ""
	cDesc3   := ""
	cString  := "SFN"
	aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	nLastKey := 0
	Titulo   := cDesc1
	cPerg    := "_MATR909"
	nomeprog := "_MATR909"
	wnrel    := "_MATR909"
	tamanho  := "G"
	limite   := 220
	nTipo    := 15
	m_pag    := 2
	li       := 80
	cCabec1  := ""
	cCabec2  := ""
	aOrd     := {} //{"Por data"}
	
	_ValidPerg ()
	pergunte (cPerg, .F.)

	if ! _lAuto

		// Execucao com interface com o usuario.
		wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F., aOrd)
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
	processa ({|| _Gera ()})
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
return



// --------------------------------------------------------------------------
static function _Gera ()
	local   _oSQL    := NIL
	local   _nSaldo  := 0
	private _nMaxLin := 68

	li = 1

	// Nao aceita filtro por que precisaria inserir na query.
	If !Empty(aReturn[7])
		u_help ("Este relatorio nao aceita filtro do usuario.")
		return
	EndIf	

	procregua (10)
	incproc ("Lendo dados...")

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C"
	_oSQL:_sQuery += " AS"
	_oSQL:_sQuery += " (SELECT"
	_oSQL:_sQuery += " 'E' AS MOVIMENTO"
	_oSQL:_sQuery += " ,FN_FILIAL AS FILIAL"
	_oSQL:_sQuery += " ,FN_QTDE * CASE FN_TIPO WHEN 'N' THEN 1 ELSE -1 END AS QT_ENTRADA"
	_oSQL:_sQuery += " ,0 AS QT_SAIDA"
	_oSQL:_sQuery += " ,FN_DATA AS DTMOVTO"
	_oSQL:_sQuery += " ,FN_GUIA AS DOC"
	_oSQL:_sQuery += " ,FN_SERIE AS SERIE"
	_oSQL:_sQuery += " ,SFN.FN_NUMERO AS NUMEROINI"
	_oSQL:_sQuery += " ,SFN.FN_NRFINAL AS NUMEROFIM"
	_oSQL:_sQuery += " ,SFN.FN_CLASSE AS CLASSE"
	_oSQL:_sQuery += " ,SFN.FN_COR AS COR"
	_oSQL:_sQuery += " ,CASE FN_TIPO WHEN 'N' THEN '' ELSE 'DEVOLUCAO' END AS OBS"
	_oSQL:_sQuery += " FROM SFN010 SFN"
	_oSQL:_sQuery += " WHERE SFN.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SFN.FN_FILIAL IN " + FormatIn (mv_par01, '/')
	_oSQL:_sQuery += " AND SFN.FN_CLASSE = '" + mv_par04 + "'"
	_oSQL:_sQuery += " AND SFN.FN_DATA BETWEEN '" + dtos (mv_par02) + "' AND '" + dtos (mv_par03) + "'"
	_oSQL:_sQuery += " UNION ALL"
/*
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " '1' AS TIPO_REG"
	_oSQL:_sQuery += " ,'S' AS MOVIMENTO"
	_oSQL:_sQuery += " ,D3_FILIAL AS FILIAL"
	_oSQL:_sQuery += " ,0 AS QT_ENTRADA"
	_oSQL:_sQuery += " ,ROUND(SUM(SD3.D3_QUANT * SB1.B1_QTDEMB), 0) AS QT_SAIDA"
	_oSQL:_sQuery += " ,SD3.D3_EMISSAO AS DTMOVTO"
	_oSQL:_sQuery += " ,SD3.D3_OP AS DOC"
	_oSQL:_sQuery += " ,'' AS SERIE"
	_oSQL:_sQuery += " ,'' AS NUMEROINI"
	_oSQL:_sQuery += " ,'' AS NUMEROFIM"
	_oSQL:_sQuery += " ,'" + mv_par04 + "' AS CLASSE"
	_oSQL:_sQuery += " ,'' AS COR"
	_oSQL:_sQuery += " ,'' AS OBS"
	_oSQL:_sQuery += " FROM SD3010 SD3"
	_oSQL:_sQuery += " ,SB1010 SB1"
	_oSQL:_sQuery += " WHERE SD3.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SD3.D3_FILIAL IN " + FormatIn (alltrim (mv_par01), '/')
	_oSQL:_sQuery += " AND SD3.D3_ESTORNO != 'S'"
	_oSQL:_sQuery += " AND SD3.D3_EMISSAO BETWEEN '" + dtos (mv_par02) + "' AND '" + dtos (mv_par03) + "'"
	_oSQL:_sQuery += " AND SD3.D3_OP != ''"
	_oSQL:_sQuery += " AND SD3.D3_CF LIKE 'PR%'"
	_oSQL:_sQuery += " AND NOT (D3_FILIAL IN ('01','13') AND D3_COD IN ('0194','0328A', '0137', '2123'))"  // consumo indevido
	_oSQL:_sQuery += " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery += " AND SB1.B1_COD = SD3.D3_COD"
	_oSQL:_sQuery += " AND SB1.B1_CLASSE = '" + mv_par04 + "'"
	_oSQL:_sQuery += " GROUP BY SD3.D3_FILIAL, SD3.D3_EMISSAO, D3_OP"
*/
	_oSQL:_sQuery += " 	SELECT"
	_oSQL:_sQuery += " 	   'S' AS MOVIMENTO"
	_oSQL:_sQuery += "     ,D2_FILIAL AS FILIAL"
	_oSQL:_sQuery += " 	   ,0 AS QT_ENTRADA"
	_oSQL:_sQuery += " 	   ,ROUND(SUM(SD2.D2_QUANT * SB1.B1_QTDEMB), 0) AS QT_SAIDA"
	if mv_par05 == 1
		_oSQL:_sQuery += " ,SD2.D2_EMISSAO AS DTMOVTO"
		_oSQL:_sQuery += " ,SD2.D2_DOC AS DOC"
		_oSQL:_sQuery += " ,SD2.D2_SERIE AS SERIE"
	else
		_oSQL:_sQuery += " ,SUBSTRING (SD2.D2_EMISSAO, 1, 4) + '1231' AS DTMOVTO"
		_oSQL:_sQuery += " ,'' as DOC"
		_oSQL:_sQuery += " ,'' AS SERIE"
	endif
	_oSQL:_sQuery += " 	   ,'' AS NUMEROINI"
	_oSQL:_sQuery += " 	   ,'' AS NUMEROFIM"
	_oSQL:_sQuery += "     ,'" + mv_par04 + "' AS CLASSE"
	_oSQL:_sQuery += "     ,'' AS COR"
	_oSQL:_sQuery += "     ,'NF SAIDA' AS OBS"
	_oSQL:_sQuery += " 	FROM SD2010 SD2"
	_oSQL:_sQuery += " 		,SB1010 SB1"
	_oSQL:_sQuery += " 		,SF4010 SF4"
	_oSQL:_sQuery += " 	WHERE SD2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND SD2.D2_FILIAL IN " + FormatIn (alltrim (mv_par01), '/')
	_oSQL:_sQuery += " 	AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par02) + "' AND '" + dtos (mv_par03) + "'"
	_oSQL:_sQuery += " 	AND SD2.D2_TIPO = 'N'"
	_oSQL:_sQuery += " 	AND SD2.D2_CLIENTE != '011863'"  // DEPOSITO FILIAL 04
	_oSQL:_sQuery += " 	AND NOT (D2_FILIAL IN ('01','13') AND SD2.D2_TES IN ('850','534','855','868','869','870','856','853','861','863','854','635','830'))"  // MOVIMENTACAO DEPOSITO FECHADO
	_oSQL:_sQuery += " 	AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery += " 	AND SB1.B1_COD = SD2.D2_COD"
	_oSQL:_sQuery += " 	AND SB1.B1_SELO = '1'"
	_oSQL:_sQuery += " 	AND SB1.B1_CLASSE = '" + mv_par04 + "'"
	_oSQL:_sQuery += " 	AND SF4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND SF4.F4_FILIAL = '" + xfilial ("SF4") + "'"
	_oSQL:_sQuery += " 	AND SF4.F4_CODIGO = SD2.D2_TES
//	_oSQL:_sQuery += " 	AND SF4.F4_ESTOQUE = 'S'"
	_oSQL:_sQuery += " 	AND SF4.F4_SELO IN ('1','2','3')" // 1=Venda/Compra;2=Remessa/Devolucao;3=Outros;4=Näo Movimenta
	if mv_par05 == 1
		_oSQL:_sQuery += " GROUP BY SD2.D2_FILIAL, SD2.D2_EMISSAO,D2_DOC, D2_SERIE"
	else
		_oSQL:_sQuery += "	GROUP BY SD2.D2_FILIAL, SUBSTRING (SD2.D2_EMISSAO, 1, 4)"
	endif

	_oSQL:_sQuery += " UNION ALL"
	_oSQL:_sQuery += " 	SELECT"
	_oSQL:_sQuery += " 	   'E' AS MOVIMENTO"
	_oSQL:_sQuery += "     ,D1_FILIAL AS FILIAL"
	_oSQL:_sQuery += " 	   ,ROUND(SUM(SD1.D1_QUANT * SB1.B1_QTDEMB), 0) AS QT_ENTRADA"
	_oSQL:_sQuery += " 	   ,0 AS QT_SAIDA"
	if mv_par05 == 1
		_oSQL:_sQuery += " ,SD1.D1_DTDIGIT AS DTMOVTO"
		_oSQL:_sQuery += " ,SD1.D1_DOC AS DOC"
		_oSQL:_sQuery += " ,SD1.D1_SERIE AS SERIE"
	else
		_oSQL:_sQuery += " ,SUBSTRING (SD1.D1_DTDIGIT, 1, 4) + '1231' AS DTMOVTO"
		_oSQL:_sQuery += " ,'' AS DOC"
		_oSQL:_sQuery += " ,'' AS SERIE"
	endif
	_oSQL:_sQuery += " 	   ,'' AS NUMEROINI"
	_oSQL:_sQuery += " 	   ,'' AS NUMEROFIM"
	_oSQL:_sQuery += "     ,'" + mv_par04 + "' AS CLASSE"
	_oSQL:_sQuery += "     ,'' AS COR"
	_oSQL:_sQuery += "     ,'DEVOLUCAO VENDA' AS OBS" //rtrim(D1_COD) + ' qt:' + rtrim (cast (D1_QUANT as varchar (10))) + ' tes:' + D1_TES + ' ' + rtrim (B1_DESC) AS OBS"
	_oSQL:_sQuery += " 	FROM SD1010 SD1"
	_oSQL:_sQuery += " 		,SB1010 SB1"
	_oSQL:_sQuery += " 		,SF4010 SF4"
	_oSQL:_sQuery += " 	WHERE SD1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND SD1.D1_FILIAL IN " + FormatIn (alltrim (mv_par01), '/')
	_oSQL:_sQuery += " 	AND SD1.D1_DTDIGIT BETWEEN '" + dtos (mv_par02) + "' AND '" + dtos (mv_par03) + "'"
	_oSQL:_sQuery += " 	AND SD1.D1_TIPO = 'D'"
	_oSQL:_sQuery += " 	AND SD1.D1_FORNECE != '011863'"  // DEPOSITO FILIAL 04
	_oSQL:_sQuery += " 	AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery += " 	AND SB1.B1_COD = SD1.D1_COD"
	_oSQL:_sQuery += " 	AND SB1.B1_SELO = '1'"
	_oSQL:_sQuery += " 	AND SB1.B1_CLASSE = '" + mv_par04 + "'"
	_oSQL:_sQuery += " 	AND SF4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND SF4.F4_FILIAL = '" + xfilial ("SF4") + "'"
	_oSQL:_sQuery += " 	AND SF4.F4_CODIGO = SD1.D1_TES
	_oSQL:_sQuery += " 	AND SF4.F4_ESTOQUE = 'S'"
	_oSQL:_sQuery += " 	AND SF4.F4_SELO IN ('1','2','3')" // 1=Venda/Compra;2=Remessa/Devolucao;3=Outros;4=Näo Movimenta
	if mv_par05 == 1
		_oSQL:_sQuery += " GROUP BY SD1.D1_FILIAL, SD1.D1_DTDIGIT,D1_DOC, D1_SERIE"
	else
		_oSQL:_sQuery += "	GROUP BY SD1.D1_FILIAL, SUBSTRING (SD1.D1_DTDIGIT, 1, 4)"
	endif

	_oSQL:_sQuery += " )"
	_oSQL:_sQuery += " SELECT TOP 100 PERCENT"
	_oSQL:_sQuery += " ROW_NUMBER() OVER (ORDER BY C.DTMOVTO, C.FILIAL, C.DOC, C.SERIE) AS LINHA"
	_oSQL:_sQuery += " ,C.FILIAL"
	_oSQL:_sQuery += " ,C.DTMOVTO"
	_oSQL:_sQuery += " ,C.DOC"
	_oSQL:_sQuery += " ,C.SERIE"
	_oSQL:_sQuery += " ,C.QT_ENTRADA"
	_oSQL:_sQuery += " ,C.QT_SAIDA"
	_oSQL:_sQuery += " ,SUM(C2.QT_ENTRADA - C2.QT_SAIDA) AS SALDO"
	_oSQL:_sQuery += " ,C.MOVIMENTO"
	_oSQL:_sQuery += " ,C.NUMEROINI"
	_oSQL:_sQuery += " ,C.NUMEROFIM"
	_oSQL:_sQuery += " ,C.CLASSE"
	_oSQL:_sQuery += " ,C.COR"
	_oSQL:_sQuery += " ,C.OBS"
	_oSQL:_sQuery += " FROM C"
	_oSQL:_sQuery += " LEFT JOIN C AS C2"  // FAZ UM JOIN COM A PROPRIA TABELA PARA COMPOR O SALDO
	_oSQL:_sQuery += " ON (C2.DTMOVTO + C2.FILIAL + C2.DOC + C2.SERIE <= C.DTMOVTO + C.FILIAL + C.DOC + C.SERIE)"
	_oSQL:_sQuery += " GROUP BY C.FILIAL"
	_oSQL:_sQuery += " ,C.DTMOVTO"
	_oSQL:_sQuery += " ,C.DOC"
	_oSQL:_sQuery += " ,C.SERIE"
	_oSQL:_sQuery += " ,C.QT_ENTRADA"
	_oSQL:_sQuery += " ,C.QT_SAIDA"
	_oSQL:_sQuery += " ,C.MOVIMENTO"
	_oSQL:_sQuery += " ,C.NUMEROINI"
	_oSQL:_sQuery += " ,C.NUMEROFIM"
	_oSQL:_sQuery += " ,C.CLASSE"
	_oSQL:_sQuery += " ,C.COR"
	_oSQL:_sQuery += " ,C.OBS"
	_oSQL:_sQuery += " ORDER BY C.DTMOVTO,C.FILIAL,C.MOVIMENTO,C.DOC, C.SERIE"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb (.F.)
	procregua ((_sAliasQ) -> (reccount ()))

	_Cabec (.T.)
	
	(_sAliasQ) -> (dbgotop ())
	if (_sAliasQ) -> (eof ())
		u_help ("Nao ha dados gerados para esta consulta.")
	else
		do while ! (_sAliasQ) -> (eof ())

			incproc ()

			if li > _nMaxLin
				_Cabec (.F.)
			endif

			// Monta linha para impressao
			_sLinImp = "|   "
			_sLinImp += (_sAliasQ) -> filial + "   | "
			if (_sAliasQ) -> movimento == 'E'
				_sLinImp += U_TamFixo ((_sAliasQ) -> doc, 10) + ' |  '
				_sLinImp += U_TamFixo ((_sAliasQ) -> serie, 3) + '  | '
				_sLinImp += U_TamFixo (dtoc (stod ((_sAliasQ) -> DTMOVTO)), 10) + ' | '
				_sLinImp += transform ((_sAliasQ) -> qt_entrada, '@E 99,999,999,999') + '  | '
				_sLinImp += U_TamFixo ((_sAliasQ) -> numeroini, 9) + ' a ' + U_TamFixo ((_sAliasQ) -> numerofim, 9) + ' |   '
			else
				_sLinImp += '           |       |            |                 |                       |   '
			endif
			if (_sAliasQ) -> movimento == 'S'
				_sLinImp += U_TamFixo ((_sAliasQ) -> doc, 13) + " " + U_TamFixo ((_sAliasQ) -> serie, 3) + '  | '
				_sLinImp += U_TamFixo (dtoc (stod ((_sAliasQ) -> DTMOVTO)), 10) + ' | '
				_sLinImp += transform ((_sAliasQ) -> qt_saida, '@E 999,999,999,999') + '  |   '
			else
				_sLinImp += '                   |            |                  |   '
			endif
			_sLinImp += transform ((_sAliasQ) -> saldo, '@E 999,999,999,999') + ' | '
			_sLinImp += U_TamFixo ((_sAliasQ) -> obs, 55) + ' |'
			_nSaldo = (_sAliasQ) -> saldo

			_Imprime (_sLinImp)

			(_sAliasQ) -> (dbskip ())
		enddo
		_Imprime ("|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|")
		_Imprime ("|                                                                                                                                           |   " + transform (_nSaldo, '@E 999,999,999,999') + " |                                                         |")
	endif
	(_sAliasQ) -> (dbclosearea ())

	_Imprime ("+-------------------------------------------------------------------------------------------------------------------------------------------+-------------------+---------------------------------------------------------+")
return



// --------------------------------------------------------------------------
static function _Cabec (_lPrim)

	// Termina a pagina atual antes de gerar novo cabecalho.
	if ! _lPrim
		_Imprime ("+-------------------------------------------------------------------------------------------------------------------------------------------+-------------------+---------------------------------------------------------+")
	endif

	li = 1
	@ li, 0 psay aValImp (Limite)  // Gera quebra de folha
	_Imprime ("+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------+")
	_Imprime ("|                                                                                 Registro de Entrada e Saida do Selo de Controle                                                                               |  Folha  |")
	_Imprime ("|                                                                                                                                                                                                               |   " + strzero (m_pag, 3) + "   |")
	_Imprime ("+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------+")
	_Imprime ("| Firma : " + transform (sm0 -> m0_cgc, "@R 99.999.999/9999-99") + " - " + sm0 -> m0_nomecom + "                                                                                                                               |")
	_Imprime ("| Classe : " + (_sAliasQ) -> classe + ' - ' + Tabela ('A9', (_sAliasQ) -> classe) + '                    Cor : ' + (_sAliasQ) -> cor + '                Serie : ' + (_sAliasQ) -> serie + "                                                                                                   |")
	_Imprime ("+------------------------------------------------------------------------------------+------------------------------------------------------+-------------------+---------------------------------------------------------+")
	_Imprime ("|                                E N T R A D A S                                     |                      S A I D A S                     |        S A L D O  |                  O B S E R V A C O E S                  |")
	_Imprime ("+--------+------------+-------+------------+-----------------+-----------------------+----------------------+------------+------------------+-------------------+---------------------------------------------------------+")
	_Imprime ("| Filial |   Guia     | Serie |   Data     |     Quantidade  | Faixa de numeracao    | Documento / serie    |   Data     |       Quantidade |                   |                                                         |")
	_Imprime ("+--------+------------+-------+------------+-----------------+-----------------------+----------------------+------------+------------------+-------------------+---------------------------------------------------------+")
	m_pag ++

return



// --------------------------------------------------------------------------
// Imprime linha.
static function _Imprime (_sLinImp)
	@ li, 0 psay _sLinImp
	li ++
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes          Help
	aadd (_aRegsPerg, {01, "Filiais (separadas por barras)", "C", 30, 0,  "",   "   ", {},             ""})
	aadd (_aRegsPerg, {02, "Data inicial                  ", "D", 8,  0,  "",   "   ", {},             ""})
	aadd (_aRegsPerg, {03, "Data final                    ", "D", 8,  0,  "",   "   ", {},             ""})
	aadd (_aRegsPerg, {04, "Classe selo                   ", "C", 6,  0,  "",   "A9 ", {},             ""})
	aadd (_aRegsPerg, {05, "Detalhar NF                   ", "N", 1,  0,  "",   "   ", {"Sim", "Nao"}, ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return


/*	
	// Define layout de impressao.
	_aLay[01] :="+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------+"
	_aLay[02] :="|                                                                                 Registro de Entrada e Saida do Selo de Controle                                                                               |  Folha  |"
	_aLay[03] :="|                                                                                                                                                                                                               |  #####  |"
	_aLay[04] :="+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------+"
	_aLay[05] :="| Firma : ############################################################################                                                                                                                                    |"
	_aLay[06] :="| Grupo ou SubGrupo : ######-####################                                                                                                                            Cor : ###############    Serie : ##########  |"
	_aLay[07] :="+--------------------------------------------------------------------+----------------------------------------------------+---------------+-------------------------------------------------------------------------------+"
	_aLay[08] :="|                           E N T R A D A                            |                      S A I D A                     |               |                                                                               |"
	_aLay[09] :="+-----------+---------------------------+---------------+------------+------------------------------------+---------------|     SALDO     |                                                                               |"
	_aLay[10] :="|    Ano    |           Guia            |               |            |             NOTA FISCAL            |    Outras     |               |                                 OBSERVACOES                                   |"
	_aLay[11] :="|-----------+---------------------------| 4)Quantidade  | 5)Numeros  |------------------------------------|  Quantidades  | (Quantidade)  |                                                                               |"
	_aLay[12] :="| 1)Mes/Ano | 2)Numero     | 3)Data     |               |            | 6)Serie | 7)Numero | 8)Quantidade  | 9)            | 10)           |11)                                                                            |"
	_aLay[13] :="+-----------+--------------+------------+---------------+------------+---------+----------+---------------+---------------+---------------+-------------------------------------------------------------------------------+"
	_aLay[14] :="| ##/##/##  |              |            |               |            |   ###   | ######   | ############  | ############  | ############  |###############################################################################|"
	_aLay[15] :="+-----------+--------------+------------+---------------+------------+---------+----------+---------------+---------------+---------------+-------------------------------------------------------------------------------+"
	_aLay[16] :="| Total do ## Decendio                  | ############# |                                 | ############# | ############# | ############# |                                                                               |"
	_aLay[17] :="| Total da ## Quinzena                  | ############# |                                 | ############# | ############# | ############# |                                                                               |"
	_aLay[18] :="| Total do Mes #######                  | ############# |                                 | ############# | ############# | ############# |                                                                               |"
	_aLay[19] :="+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+"
	_aLay[20] :="| ##/##/##  | ############ | ##/##/##   |               |            |         |          |               |               | ############  |                                                                               |"
	_aLay[21] :="| ##/##/##  | ############ | ##/##/##   | ############  |   ######   |         |          |               |               | ############  |###############################################################################|"
	_aLay[22] :="| Total Geral                           | ############# |                                 | ############# | ############# | ############# |                                                                               |"
	_aLay[23] :="+---------------------------------------+---------------+---------------------------------+---------------+---------------+---------------+-------------------------------------------------------------------------------+"
	_aLay[24] :="|           |              |            |               |            |         |          |               |               |               |                                                                               |"
	nLin := 0
*/
