// Programa...: VA_XLS17
// Autor......: Robert Koch
// Data.......: 02/04/2012
// Descricao..: Exportacao de ST para planilha.
//
// Historico de alteracoes:
// 06/06/2012 - Robert - Incluidas colunas de quantitade, preco unitario e grupo de ST (b1_vastsp).
// 03/11/2014 - Robert - Incluido tratamento para nectar e outras bebidas nao alcoolicas.
//

// --------------------------------------------------------------------------
User Function VA_XLS17 (_lAutomat)
	Local cCadastro := "Exportacao de dados de ST para planilha"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	Private cPerg   := "VAXLS17"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo gerar uma")
		AADD(aSays,"exportacao de dados de ST")
		AADD(aSays,"para planilha eletronica.")
		
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return



// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
	
	
	
// --------------------------------------------------------------------------
Static Function _Gera()
	local _oSQL      := NIL
	local _oAssoc    := NIL
	local _aLinVazia := {}
	local _sAliasQ   := ""
//	local _aHistSafr := {}
	local _sUltSafr  := ""
	private aHeader  := {}  // Para simular a exportacao de um GetDados.
	private aCols    := {}  // Para simular a exportacao de um GetDados.
	private N        := 0

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "WITH C AS ("
	_oSQL:_sQuery += " SELECT FT_FILIAL AS FILIAL, "
	_oSQL:_sQuery +=        " SUBSTRING (FT_EMISSAO, 7, 2) + '/' + SUBSTRING (FT_EMISSAO, 5, 2) + '/' + SUBSTRING (FT_EMISSAO, 1, 4) AS EMISSAO, "
	_oSQL:_sQuery +=        " FT_NFISCAL AS NF, FT_SERIE AS SERIE, FT_TIPO AS TIPO_NF, FT_CLIEFOR AS CLIENTE, FT_LOJA AS LOJA, "
	_oSQL:_sQuery +=        " FT_VALCONT AS VL_CONTAB, D2_TOTAL AS VL_PRODUT, FT_VALIPI AS VL_IPI, FT_BASERET AS BASE_RET, FT_ICMSRET AS ICMS_RET, FT_CFOP AS CFOP, D2_TES AS TES, "
	_oSQL:_sQuery +=        " FT_PRODUTO AS PRODUTO, B1_DESC AS DESCRI, "
	_oSQL:_sQuery +=        " CASE WHEN SUBSTRING (SB1.B1_POSIPI, 1, 4) = '2204' THEN "
	_oSQL:_sQuery +=              " CASE WHEN SUBSTRING (SB1.B1_POSIPI, 1, 8) IN ('22041090', '22041010') THEN "
	_oSQL:_sQuery +=                  " 'ESPUMANTE'"
	_oSQL:_sQuery +=              " ELSE "
	_oSQL:_sQuery +=                  " 'VINHO'"
	_oSQL:_sQuery +=              " END"
	_oSQL:_sQuery +=        " ELSE "
	_oSQL:_sQuery +=            " CASE WHEN SUBSTRING (SB1.B1_POSIPI, 1, 4) IN ('2205', '2206', '2207', '2208') THEN "
	_oSQL:_sQuery +=                 " 'COOLER' "
	_oSQL:_sQuery +=            " ELSE "
	_oSQL:_sQuery +=                " CASE WHEN SUBSTRING (SB1.B1_POSIPI, 1, 4) IN ('2009') THEN "
	_oSQL:_sQuery +=                    " 'SUCO' "
	_oSQL:_sQuery +=                " ELSE "
	_oSQL:_sQuery +=                   " CASE WHEN SUBSTRING (SB1.B1_POSIPI, 1, 8) IN ('22029000') THEN "
	_oSQL:_sQuery +=                       " 'NECTAR' "
	_oSQL:_sQuery +=                   " ELSE "
	_oSQL:_sQuery +=                      " CASE WHEN SUBSTRING (SB1.B1_POSIPI, 1, 8) IN ('22021000') THEN "
	_oSQL:_sQuery +=                          " 'OUTRAS NAO ALC.' "
	_oSQL:_sQuery +=                      " ELSE "
	_oSQL:_sQuery +=                         " '?' "
	_oSQL:_sQuery +=                      " END "
	_oSQL:_sQuery +=                   " END "
	_oSQL:_sQuery +=                " END "
	_oSQL:_sQuery +=            " END "
	_oSQL:_sQuery +=        " END AS TIPO_PROD,"
	_oSQL:_sQuery +=        " B1_POSIPI AS CLAS_FISC,"
	_oSQL:_sQuery +=        " FT_QUANT AS QUANT,"
	_oSQL:_sQuery +=        " FT_PRCUNIT AS PRCUNIT,"
	_oSQL:_sQuery +=        " B1_VASTSP AS GRUPO_PARA_ST,"
	_oSQL:_sQuery +=        " SX5_75.X5_DESCRI AS DESC_GRUPO"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SFT") + " SFT, "
	_oSQL:_sQuery +=              RetSQLName ("SD2") + " SD2, "
	_oSQL:_sQuery +=              RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery +=         "LEFT JOIN " + RetSQLName ("SX5") + " SX5_75 "
	_oSQL:_sQuery +=             " ON (SX5_75.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=             " AND SX5_75.X5_FILIAL = '" + xfilial ("SX5") + "'"
	_oSQL:_sQuery +=             " AND SX5_75.X5_TABELA = '75'"
	_oSQL:_sQuery +=             " AND SX5_75.X5_CHAVE  = SB1.B1_VASTSP)"
	_oSQL:_sQuery +=  " WHERE SB1.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=    " AND SB1.B1_COD      = SFT.FT_PRODUTO"
	_oSQL:_sQuery +=    " AND SB1.B1_FILIAL   = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=    " AND SD2.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=    " AND SD2.D2_CLIENTE  = SFT.FT_CLIEFOR"
	_oSQL:_sQuery +=    " AND SD2.D2_LOJA     = SFT.FT_LOJA"
	_oSQL:_sQuery +=    " AND SD2.D2_DOC      = SFT.FT_NFISCAL"
	_oSQL:_sQuery +=    " AND SD2.D2_SERIE    = SFT.FT_SERIE"
	_oSQL:_sQuery +=    " AND SD2.D2_FILIAL   = SFT.FT_FILIAL"
	_oSQL:_sQuery +=    " AND SD2.D2_ITEM     = SFT.FT_ITEM"
	_oSQL:_sQuery +=    " AND SFT.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=    " AND SFT.FT_ICMSRET != 0"
	_oSQL:_sQuery +=    " AND SFT.FT_ESTADO   = '" + mv_par01 + "'"
	_oSQL:_sQuery +=    " AND SFT.FT_EMISSAO BETWEEN '" + dtos (mv_par02) + "' AND '" + dtos (mv_par03) + "'"
	_oSQL:_sQuery += ") SELECT * FROM C"
	_oSQL:_sQuery +=   " WHERE 1=1"
	if mv_par04 == 2
		_oSQL:_sQuery += " AND TIPO_PROD != 'SUCO'"
	endif
	if mv_par05 == 2
		_oSQL:_sQuery += " AND TIPO_PROD != 'VINHO'"
	endif
	if mv_par06 == 2
		_oSQL:_sQuery += " AND TIPO_PROD != 'ESPUMANTE'"
	endif
	if mv_par07 == 2
		_oSQL:_sQuery += " AND TIPO_PROD != 'COOLER'"
	endif
	if mv_par08 == 2
		_oSQL:_sQuery += " AND TIPO_PROD != 'OUTRAS NAO ALC.'"
	endif
	if mv_par09 == 2
		_oSQL:_sQuery += " AND TIPO_PROD != 'NECTAR'"
	endif
	_oSQL:_sQuery += " ORDER BY FILIAL, EMISSAO, NF"
	u_log (_oSQL:_squery)
	processa ({ || U_Trb2XLS (_oSQL:Qry2Trb ())})
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes       Help
	aadd (_aRegsPerg, {01, "UF destino                    ", "C", 2,  0,  "",   "12 ", {},             ""})
	aadd (_aRegsPerg, {02, "Data emissao inicial          ", "D", 8,  0,  "",   "   ", {},             ""})
	aadd (_aRegsPerg, {03, "Data emissao final            ", "D", 8,  0,  "",   "   ", {},             ""})
	aadd (_aRegsPerg, {04, "Considerar sucos              ", "N", 1,  0,  "",   "   ", {'Sim', 'Nao'}, ""})
	aadd (_aRegsPerg, {05, "Considerar vinhos             ", "N", 1,  0,  "",   "   ", {'Sim', 'Nao'}, ""})
	aadd (_aRegsPerg, {06, "Considerar espumantes         ", "N", 1,  0,  "",   "   ", {'Sim', 'Nao'}, ""})
	aadd (_aRegsPerg, {07, "Considerar coolers            ", "N", 1,  0,  "",   "   ", {'Sim', 'Nao'}, ""})
	aadd (_aRegsPerg, {08, "Considerar out.bebidas nao alc", "N", 1,  0,  "",   "   ", {'Sim', 'Nao'}, ""})
	aadd (_aRegsPerg, {09, "Considerar nectares           ", "N", 1,  0,  "",   "   ", {'Sim', 'Nao'}, ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
