// Programa...: VA_XLS15
// Autor......: Robert Koch
// Data.......: 09/07/2018
// Cliente....: Nova Alianca
// Descricao..: Exportacao de saldos em estoque para Excel, com dados de Sisdeclara.
//
// Historico de alteracoes:
// 02/02/2012 - Robert - Filial 04 (antes nao prevista) passa a usar mesmo codigo da 01.
// 19/05/2012 - Robert - Cadastros de codigos do Sisdeclara movidos do SX5 para ZX5.
//                     - Passa a ordenar pelo campo B1_PROD.
// 12/06/2012 - Robert - Para cada filial, somava todas as demais filiais na coluna de saldos.
// 13/02/2013 - Robert - Campo B1_TPPROD passa a ser padrao no Protheus 11. Criado B1_VACOR em seu lugar.
// 08/04/2016 - Robert - Programa desabilitado (ver adiante).
// 19/09/2018 - Andre  - Melhorado relatório 
// 16/10/2018 - Andre  - Adicionado opção "Detalhado" mostrando saldos nas tabelas SBK e SBF. 

// --------------------------------------------------------------------------
User Function VA_XLS15 (_lAutomat)
	Local cCadastro := "Exportacao de saldos em estoque para Excel com dados de Sisdeclara"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS15"
	u_logIni ()
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo gerar uma")
		AADD(aSays,"exportacao de saldos em estoque, com dados de Sisdeclara,")
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
	local _sAliasQ   := NIL
	private aHeader  := {}  // Para simular a exportacao de um GetDados.
	private aCols    := {}  // Para simular a exportacao de um GetDados.

	if empty (mv_par05)
		u_help ("Data de referencia deve ser informada")
		return
	endif
	if mv_par06 = 02 .and. mv_par05 <> DATE ()
	   if lastday(mv_par05) <> mv_par05
		u_help ("Para datas retroativas deve-se informar último dia do mes")
		return
	endif
	endif	  

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "WITH CTE AS ("
	_oSQL:_sQuery += " SELECT DISTINCT B1_COD AS COD_ERP, RTRIM (SB1.B1_DESC) AS DESCR_ERP, RTRIM (SB1.B1_TIPO) AS TIPO,"
	do case
	case cFilAnt == '01'
		_oSQL:_sQuery +=    " SB2.B2_LOCAL AS ALMOX,  "
		_oSQL:_sQuery +=    " RTRIM (SB5.B5_VACSD01) AS COD_SISDECLARA,  "
		_oSQL:_sQuery +=    " RTRIM (ISNULL (ZX5_01.ZX5_12DESC, '')) AS DESCRI_SISDECLARA, "
	case cFilAnt == '03'
		_oSQL:_sQuery +=    " SB2.B2_LOCAL AS ALMOX,  "
		_oSQL:_sQuery +=    " RTRIM (SB5.B5_VACSD03) AS COD_SISDECLARA,  "
		_oSQL:_sQuery +=    " RTRIM (ISNULL (ZX5_03.ZX5_24DESC, '')) AS DESCRI_SISDECLARA, "
	case cFilAnt == '05'
		_oSQL:_sQuery +=    " SB2.B2_LOCAL AS ALMOX,  "
		_oSQL:_sQuery +=    " RTRIM (SB5.B5_VACSD05) AS COD_SISDECLARA,  "
		_oSQL:_sQuery +=    " RTRIM (ISNULL (ZX5_05.ZX5_25DESC, '')) AS DESCRI_SISDECLARA, "	
	case cFilAnt == '06'
		_oSQL:_sQuery +=    " SB2.B2_LOCAL AS ALMOX,  "
		_oSQL:_sQuery +=    " RTRIM (SB5.B5_VACSD06) AS COD_SISDECLARA,  "
		_oSQL:_sQuery +=    " RTRIM (ISNULL (ZX5_06.ZX5_26DESC, '')) AS DESCRI_SISDECLARA, "
	case cFilAnt == '07'
		_oSQL:_sQuery +=    " SB2.B2_LOCAL AS ALMOX,  "
		_oSQL:_sQuery +=    " RTRIM (SB5.B5_VACSD07) AS COD_SISDECLARA,  "
		_oSQL:_sQuery +=    " RTRIM (ISNULL (ZX5_07.ZX5_27DESC, '')) AS DESCRI_SISDECLARA, "
	case cFilAnt == '08'
		_oSQL:_sQuery +=    " SB2.B2_LOCAL AS ALMOX,  "
		_oSQL:_sQuery +=    " RTRIM (SB5.B5_VACSD08) AS COD_SISDECLARA,  "
		_oSQL:_sQuery +=    " RTRIM (ISNULL (ZX5_08.ZX5_37DESC, '')) AS DESCRI_SISDECLARA, "	
	case cFilAnt == '09'
		_oSQL:_sQuery +=    " SB2.B2_LOCAL AS ALMOX,  "
		_oSQL:_sQuery +=    " RTRIM (SB5.B5_VACSD09) AS COD_SISDECLARA,  "
		_oSQL:_sQuery +=    " RTRIM (ISNULL (ZX5_09.ZX5_28DESC, '')) AS DESCRI_SISDECLARA, "	
	case cFilAnt == '10'
		_oSQL:_sQuery +=    " SB2.B2_LOCAL AS ALMOX,  "
		_oSQL:_sQuery +=    " RTRIM (SB5.B5_VACSD10) AS COD_SISDECLARA,  "
		_oSQL:_sQuery +=    " RTRIM (ISNULL (ZX5_10.ZX5_29DESC, '')) AS DESCRI_SISDECLARA, "
	case cFilAnt == '11'
		_oSQL:_sQuery +=    " SB2.B2_LOCAL AS ALMOX,  "
		_oSQL:_sQuery +=    " RTRIM (SB5.B5_VACSD11) AS COD_SISDECLARA,  "
		_oSQL:_sQuery +=    " RTRIM (ISNULL (ZX5_11.ZX5_30DESC, '')) AS DESCRI_SISDECLARA, "	
	case cFilAnt == '12'
		_oSQL:_sQuery +=    " SB2.B2_LOCAL AS ALMOX,  "
		_oSQL:_sQuery +=    " RTRIM (SB5.B5_VACSD12) AS COD_SISDECLARA,  "
		_oSQL:_sQuery +=    " RTRIM (ISNULL (ZX5_12.ZX5_31DESC, '')) AS DESCRI_SISDECLARA, "	
	case cFilAnt == '13'
		_oSQL:_sQuery +=    " SB2.B2_LOCAL AS ALMOX,  "
		_oSQL:_sQuery +=    " RTRIM (SB5.B5_VACSD13) AS COD_SISDECLARA,  "
		_oSQL:_sQuery +=    " RTRIM (ISNULL (ZX5_13.ZX5_23DESC, '')) AS DESCRI_SISDECLARA, "	
	otherwise
		u_help ('Local de Sisdeclara sem tratamento na CTE')
	endcase
		if mv_par06 = 1
			_oSQL:_sQuery +=    " ROUND( SUM (dbo.VA_SALDOESTQ (B2_FILIAL, B1_COD, B2_LOCAL, '" + dtos (mv_par05) + "') * (B1_LITROS)),2) AS LITROS"
		else
			if mv_par05 = DATE()
			_oSQL:_sQuery +=    " SBF.BF_LOCALIZ AS LOCALIZACAOSBF,"
			_oSQL:_sQuery +=    " ROUND( SUM (BF_QUANT * B1_LITROS),2) AS LITROS"
     		else
     		_oSQL:_sQuery +=    " SBK.BK_LOCALIZ AS LOCALIZACAOSBK,"
			_oSQL:_sQuery +=    " ROUND( SUM (BK_QINI * B1_LITROS),2) AS LITROS"
     		endif
		endif	
		if mv_par06 = 1
			_oSQL:_sQuery +=  " FROM " + RetSQLName ("SB2") + " SB2, "
			_oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1, "
			_oSQL:_sQuery +=             RetSQLName ("SB5") + " SB5 "
		else
			_oSQL:_sQuery +=  " FROM " + RetSQLName ("SB2") + " SB2 "
			_oSQL:_sQuery +=   " left join " + RetSQLName ("SBF") + " SBF "
			_oSQL:_sQuery +=       " ON (SBF.D_E_L_E_T_ = ' ' "
			_oSQL:_sQuery +=	   " AND B2_FILIAL = BF_FILIAL "
			_oSQL:_sQuery +=       " AND B2_LOCAL = BF_LOCAL "
			_oSQL:_sQuery +=       " AND B2_COD = BF_PRODUTO "
			_oSQL:_sQuery +=	   " )"
			_oSQL:_sQuery +=   " left join " + RetSQLName ("SBK") + " SBK "
			_oSQL:_sQuery +=       " ON (SBK.D_E_L_E_T_ = ' ' "
			_oSQL:_sQuery +=       " AND B2_FILIAL = BK_FILIAL "
			_oSQL:_sQuery +=       " AND B2_LOCAL = BK_LOCAL "
			_oSQL:_sQuery +=       " AND B2_COD = BK_COD "
			_oSQL:_sQuery +=       " AND BK_DATA = '" + dtos (mv_par05) + "' "
			_oSQL:_sQuery +=	   " ),"
			_oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1, "
			_oSQL:_sQuery +=             RetSQLName ("SB5") + " SB5 "
		endif
	do case
	case cFilAnt == '01'
		_oSQL:_sQuery +=     " left join ZX5010 ZX5_01"
		_oSQL:_sQuery +=       " ON (ZX5_01.ZX5_TABELA = '12'"
		_oSQL:_sQuery +=       " AND ZX5_01.ZX5_12COD = B5_VACSD01"
		_oSQL:_sQuery +=       " AND ZX5_01.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=       " AND ZX5_01.ZX5_FILIAL = '"+xFilial('ZX5')+"')"
	case cFilAnt == '03'
		_oSQL:_sQuery +=     " left join ZX5010 ZX5_03"
		_oSQL:_sQuery +=       " ON (ZX5_03.ZX5_TABELA = '24'"
		_oSQL:_sQuery +=       " AND ZX5_03.ZX5_24COD = B5_VACSD03"
		_oSQL:_sQuery +=       " AND ZX5_03.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=       " AND ZX5_03.ZX5_FILIAL = '"+xFilial('ZX5')+"')"
	case cFilAnt == '05'
		_oSQL:_sQuery +=     " left join ZX5010 ZX5_05"
		_oSQL:_sQuery +=       " ON (ZX5_05.ZX5_TABELA = '25'"
		_oSQL:_sQuery +=       " AND ZX5_05.ZX5_25COD = B5_VACSD05"
		_oSQL:_sQuery +=       " AND ZX5_05.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=       " AND ZX5_05.ZX5_FILIAL = '"+xFilial('ZX5')+"')"
	case cFilAnt == '06'
		_oSQL:_sQuery +=     " left join ZX5010 ZX5_06"
		_oSQL:_sQuery +=       " ON (ZX5_06.ZX5_TABELA = '26'"
		_oSQL:_sQuery +=       " AND ZX5_06.ZX5_26COD = B5_VACSD06"
		_oSQL:_sQuery +=       " AND ZX5_06.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=       " AND ZX5_06.ZX5_FILIAL = '"+xFilial('ZX5')+"')"
	case cFilAnt == '07'
		_oSQL:_sQuery +=     " left join ZX5010 ZX5_07"
		_oSQL:_sQuery +=       " ON (ZX5_07.ZX5_TABELA = '27'"
		_oSQL:_sQuery +=       " AND ZX5_07.ZX5_27COD = B5_VACSD07"
		_oSQL:_sQuery +=       " AND ZX5_07.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=       " AND ZX5_07.ZX5_FILIAL = '"+xFilial('ZX5')+"')"
	case cFilAnt == '08'
		_oSQL:_sQuery +=     " left join ZX5010 ZX5_08"
		_oSQL:_sQuery +=       " ON (ZX5_08.ZX5_TABELA = '37'"
		_oSQL:_sQuery +=       " AND ZX5_08.ZX5_37COD = B5_VACSD08"
		_oSQL:_sQuery +=       " AND ZX5_08.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=       " AND ZX5_08.ZX5_FILIAL = '"+xFilial('ZX5')+"')"
	case cFilAnt == '09'
		_oSQL:_sQuery +=     " left join ZX5010 ZX5_09"
		_oSQL:_sQuery +=       " ON (ZX5_09.ZX5_TABELA = '28'"
		_oSQL:_sQuery +=       " AND ZX5_09.ZX5_28COD = B5_VACSD09"
		_oSQL:_sQuery +=       " AND ZX5_09.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=       " AND ZX5_09.ZX5_FILIAL = '"+xFilial('ZX5')+"')"
	case cFilAnt == '10'
		_oSQL:_sQuery +=     " left join ZX5010 ZX5_10"
		_oSQL:_sQuery +=       " ON (ZX5_10.ZX5_TABELA = '29'"
		_oSQL:_sQuery +=       " AND ZX5_10.ZX5_29COD = B5_VACSD10"
		_oSQL:_sQuery +=       " AND ZX5_10.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=       " AND ZX5_10.ZX5_FILIAL = '"+xFilial('ZX5')+"')"
	case cFilAnt == '11'
		_oSQL:_sQuery +=     " left join ZX5010 ZX5_11"
		_oSQL:_sQuery +=       " ON (ZX5_11.ZX5_TABELA = '30'"
		_oSQL:_sQuery +=       " AND ZX5_11.ZX5_30COD = B5_VACSD11"
		_oSQL:_sQuery +=       " AND ZX5_11.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=       " AND ZX5_11.ZX5_FILIAL = '"+xFilial('ZX5')+"')"
	case cFilAnt == '12'
		_oSQL:_sQuery +=     " left join ZX5010 ZX5_12"
		_oSQL:_sQuery +=       " ON (ZX5_12.ZX5_TABELA = '31'"
		_oSQL:_sQuery +=       " AND ZX5_12.ZX5_31COD = B5_VACSD12"
		_oSQL:_sQuery +=       " AND ZX5_12.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=       " AND ZX5_12.ZX5_FILIAL = '"+xFilial('ZX5')+"')"
	case cFilAnt == '13'
		_oSQL:_sQuery +=     " left join ZX5010 ZX5_13"
		_oSQL:_sQuery +=       " ON (ZX5_13.ZX5_TABELA = '23'"
		_oSQL:_sQuery +=       " AND ZX5_13.ZX5_23COD = B5_VACSD13"
		_oSQL:_sQuery +=       " AND ZX5_13.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=       " AND ZX5_13.ZX5_FILIAL = '"+xFilial('ZX5')+"')"
	endcase
		_oSQL:_sQuery += " WHERE SB2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SB2.B2_COD     BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
		_oSQL:_sQuery +=   " AND SB2.B2_FILIAL  = '"+xFilial('SB2')+"'"
		_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '"+xFilial('SB1')+"'"
		_oSQL:_sQuery +=   " AND SB1.B1_COD     = SB2.B2_COD"
		_oSQL:_sQuery +=   " AND SB1.B1_LITROS != '0'"
		_oSQL:_sQuery +=   " AND SB5.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SB5.B5_VACSD"+cFilAnt+"     BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
		_oSQL:_sQuery +=   " AND SB5.B5_FILIAL  = '"+xFilial('SB5')+"'"
		_oSQL:_sQuery +=   " AND SB5.B5_COD     = SB2.B2_COD"
		_oSQL:_sQuery +=   " AND SB5.B5_VASISDE = 'S'"
	do case
	case cFilAnt == '01'
		if mv_par06 = 01
		_oSQL:_sQuery +=  " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD01, ZX5_01.ZX5_12DESC"
		else
			if lastday(mv_par05) <> mv_par05
			_oSQL:_sQuery +=  " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD01, SBF.BF_LOCALIZ, ZX5_01.ZX5_12DESC"
			else
			_oSQL:_sQuery +=  " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD01, SBK.BK_LOCALIZ, ZX5_01.ZX5_12DESC"
			endif
		endif    
	case cFilAnt == '03'
		if mv_par06 = 01
		_oSQL:_sQuery +=   " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD03, ZX5_03.ZX5_24DESC"
		else
			if lastday(mv_par05) <> mv_par05
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD03, SBF.BF_LOCALIZ, ZX5_03.ZX5_24DESC"
			else
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD03, SBK.BK_LOCALIZ, ZX5_03.ZX5_24DESC"
			endif
		endif
	case cFilAnt == '05'
		if mv_par06 = 01
		_oSQL:_sQuery +=   " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD05, ZX5_05.ZX5_25DESC"
		else
			if lastday(mv_par05) <> mv_par05
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD05, SBF.BF_LOCALIZ, ZX5_05.ZX5_25DESC"
			else
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD05, SBK.BK_LOCALIZ, ZX5_05.ZX5_25DESC"
			endif
		endif
	case cFilAnt == '06'
		if mv_par06 = 01
		_oSQL:_sQuery +=   " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD06, ZX5_06.ZX5_26DESC"
		else
			if lastday(mv_par05) <> mv_par05
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD06, SBF.BF_LOCALIZ, ZX5_06.ZX5_26DESC"
			else
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD06, SBK.BK_LOCALIZ, ZX5_06.ZX5_26DESC"
			endif
		endif
	case cFilAnt == '07'
		if mv_par06 = 01
		_oSQL:_sQuery +=   " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD07, ZX5_07.ZX5_27DESC"
		else
			if lastday(mv_par05) <> mv_par05
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD07, SBF.BF_LOCALIZ, ZX5_07.ZX5_27DESC"
			else
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD07, SBK.BK_LOCALIZ, ZX5_07.ZX5_27DESC"
			endif
		endif 
	case cFilAnt == '08'
		if mv_par06 = 01
		_oSQL:_sQuery +=   " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD08, ZX5_08.ZX5_37DESC"
		else
			if lastday(mv_par05) <> mv_par05
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD08, SBF.BF_LOCALIZ, ZX5_08.ZX5_37DESC"
			else
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD08, SBK.BK_LOCALIZ, ZX5_08.ZX5_37DESC"
			endif
		endif
	case cFilAnt == '09'
		if mv_par06 = 01
		_oSQL:_sQuery +=   " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD09, ZX5_09.ZX5_28DESC"
		else
			if lastday(mv_par05) <> mv_par05
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD09, SBF.BF_LOCALIZ, ZX5_09.ZX5_28DESC"
			else
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD09, SBK.BK_LOCALIZ, ZX5_09.ZX5_28DESC"
			endif
		endif
	case cFilAnt == '10'
		if mv_par06 = 01
		_oSQL:_sQuery +=   " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD10, ZX5_10.ZX5_29DESC"
		else
			if lastday(mv_par05) <> mv_par05
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD10, SBF.BF_LOCALIZ, ZX5_10.ZX5_29DESC"
			else
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD10, SBK.BK_LOCALIZ, ZX5_10.ZX5_29DESC"
			endif
		endif     	
	case cFilAnt == '11'
		if mv_par06 = 01
		_oSQL:_sQuery +=   " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD11, ZX5_11.ZX5_30DESC"
		else
			if lastday(mv_par05) <> mv_par05
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD11, SBF.BF_LOCALIZ, ZX5_11.ZX5_30DESC"
			else
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD11, SBK.BK_LOCALIZ, ZX5_11.ZX5_30DESC"
			endif
		endif
	case cFilAnt == '12'
		if mv_par06 = 01
		_oSQL:_sQuery +=   " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD12, ZX5_12.ZX5_31DESC"
		else
			if lastday(mv_par05) <> mv_par05
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD12, SBF.BF_LOCALIZ, ZX5_12.ZX5_31DESC"
			else
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD12, SBK.BK_LOCALIZ, ZX5_12.ZX5_31DESC"
			endif
		endif
	case cFilAnt == '13'
		if mv_par06 = 01
		_oSQL:_sQuery +=   " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD13, ZX5_13.ZX5_23DESC"
		else
			if lastday(mv_par05) <> mv_par05
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD13, SBF.BF_LOCALIZ, ZX5_13.ZX5_23DESC"
			else
			_oSQL:_sQuery += " GROUP BY SB1.B1_COD, SB1.B1_TIPO, SB1.B1_DESC, SB2.B2_LOCAL, SB5.B5_VACSD13, SBK.BK_LOCALIZ, ZX5_13.ZX5_23DESC"
			endif
		endif
		endcase
	_oSQL:_sQuery += ")"
	if mv_par06 = 1
	_oSQL:_sQuery += "SELECT COD_SISDECLARA, DESCRI_SISDECLARA, TIPO, ALMOX, COD_ERP, DESCR_ERP, LITROS"
	else
		if lastday(mv_par05) <> mv_par05
		_oSQL:_sQuery += "SELECT COD_SISDECLARA, DESCRI_SISDECLARA, TIPO, ALMOX, LOCALIZACAOSBF, COD_ERP, DESCR_ERP, LITROS"
		else
		_oSQL:_sQuery += "SELECT COD_SISDECLARA, DESCRI_SISDECLARA, TIPO, ALMOX, LOCALIZACAOSBK, COD_ERP, DESCR_ERP, LITROS"
		endif
	endif
	_oSQL:_sQuery += " FROM CTE"
	_oSQL:_sQuery += " WHERE LITROS != 0"
	_oSQL:_sQuery += " ORDER BY COD_SISDECLARA"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb (.f.)
	incproc ("Gerando arquivo de exportacao")
	processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("SB2")
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                          Help
	aadd (_aRegsPerg, {01, "Codigo (ERP) inicial          ", "C", 15, 0,  "",   "SB1   ", {},                             ""})
	aadd (_aRegsPerg, {02, "Codigo (ERP) final            ", "C", 15, 0,  "",   "SB1   ", {},                             ""})
	aadd (_aRegsPerg, {03, "Codigo (SisD) inicia          ", "C", 15, 0,  "",   "SB5   ", {},                             ""})
	aadd (_aRegsPerg, {04, "Codigo (SisD) final           ", "C", 15, 0,  "",   "SB5   ", {},                             ""})
	aadd (_aRegsPerg, {05, "Posicao do estoque em         ", "D", 8,  0,  "",   "      ", {},                             ""})
	aadd (_aRegsPerg, {06, "Resumido / Almox Ender        ", "N", 1,  0,  "",   "      ", {"Resumido", "Almox Ender"},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return