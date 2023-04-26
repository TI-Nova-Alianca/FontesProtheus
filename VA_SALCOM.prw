// Programa..: VA_SALCOM
// Autor.....: Claudia Lionço
// Data......: 09/11/2022
// Descricao.: Relatório de Provisão de Comissão
// 
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de Provisão de Comissão
// #PalavasChave      #comissões #comissoes #calculo 
// #TabelasPrincipais #SE3 #SE1 #SF2 #SD2 
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
// 03/03/2023 - Claudia - Alterado % de comissão para comissão emdia do SE1. GLPI: 8917
// 14/03/2023 - Cláudia - Alterada a ligação com tabela de titulos. 
// 24/04/2023 - Claudia - Ajuste na regra de comissão, conforme data final. GLPI: 8917
// 26/04/2023 - Cláudia - Voltado o calculo para linha da nota. GLPI: 8917
//
// --------------------------------------------------------------------------------------
User Function VA_SALCOM()
	Private oReport
	Private cPerg := "VA_SALCOM"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// ---------------------------------------------------------------------------
// Cabeçalho da rotina
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil

	oReport := TReport():New("VA_SALCOM","Saldo de Comissão",cPerg,{|oReport| PrintReport(oReport)},"Saldo de Comissão")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Vendedor"		,       					,60,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Filial"    	,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Título"		,       					,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Emissão"  		,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Base Prevista" , "@E 999,999,999.99"       ,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"% Comissão"    , "@E 999.99"       		,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Total Comissão", "@E 999,999,999.99"       ,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Qtd Parcelas"  ,  				       		,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Saldo Comissão", "@E 999,999,999.99"       ,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

	oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA1"),"Total")
    TRFunction():New(oSection1:Cell("COLUNA6")  ,,"SUM" ,oBreak1,""          , "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA8")  ,,"SUM" ,oBreak1,""          , "@E 99,999,999.99", NIL, .F., .T.)

Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	local oSection1 := oReport:Section(1)
    local _aNotas   := {}
    local _x        := 0
	local _nQtdPar  := 1

	_nLinha :=  oReport:Row()
	oReport:PrintText(" *** DATA BASE:" + DTOC(mv_par04),_nLinha, 50)
	oReport:SkipLine(1) 

    oSection1:Init()
	oSection1:SetHeaderSection(.T.)

    // _oSQL:= ClsSQL ():New ()
    // _oSQL:_sQuery := ""
	// _oSQL:_sQuery += " WITH C
	// _oSQL:_sQuery += " AS
	// _oSQL:_sQuery += " (SELECT
	// _oSQL:_sQuery += " 		SF2.F2_VEND1  + ' - ' + SA3.A3_NOME AS VENDEDOR "
	// _oSQL:_sQuery += " 	   ,SD2.D2_FILIAL AS FILIAL "
	// _oSQL:_sQuery += " 	   ,SD2.D2_DOC AS DOCUMENTO "
	// _oSQL:_sQuery += " 	   ,SD2.D2_SERIE AS SERIE "
	// _oSQL:_sQuery += " 	   ,SD2.D2_EMISSAO AS EMISSAO "
	// _oSQL:_sQuery += " 	   ,SD2.D2_TOTAL AS BASE_PREVISTA "
	// _oSQL:_sQuery += " 	   ,(SELECT DISTINCT E1_COMIS1 FROM " +  RetSQLName ("SE1") + " SE1 "
	// _oSQL:_sQuery += " 	        WHERE SE1.D_E_L_E_T_     = '' "
	// _oSQL:_sQuery += " 	        AND SE1.E1_FILIAL  = SD2.D2_FILIAL "
	// _oSQL:_sQuery += " 	        AND SE1.E1_NUM     = SD2.D2_DOC "
	// _oSQL:_sQuery += " 	        AND SE1.E1_PREFIXO = SD2.D2_SERIE "
	// _oSQL:_sQuery += " 	        AND SE1.E1_CLIENTE = SD2.D2_CLIENTE "
	// _oSQL:_sQuery += " 	        AND SE1.E1_LOJA    = SD2.D2_LOJA) AS PERC_COMISSAO "
	// _oSQL:_sQuery += " 	FROM " +  RetSQLName ("SD2") + " AS SD2 "
	// _oSQL:_sQuery += " 	INNER JOIN " +  RetSQLName ("SF2") + " AS SF2 "
	// _oSQL:_sQuery += " 		ON SF2.D_E_L_E_T_  = '' "
	// _oSQL:_sQuery += " 		AND SF2.F2_FILIAL  = SD2.D2_FILIAL "
	// _oSQL:_sQuery += " 		AND SF2.F2_DOC     = SD2.D2_DOC "
	// _oSQL:_sQuery += " 		AND SF2.F2_SERIE   = SD2.D2_SERIE "
	// _oSQL:_sQuery += " 		AND SF2.F2_CLIENTE = SD2.D2_CLIENTE "
	// _oSQL:_sQuery += " 		AND SF2.F2_LOJA    = SD2.D2_LOJA "
	// _oSQL:_sQuery += " 	    AND SF2.F2_VEND1 BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' "
	// _oSQL:_sQuery += " 	INNER JOIN " +  RetSQLName ("SA3") + " AS SA3 "
	// _oSQL:_sQuery += " 		ON SA3.D_E_L_E_T_ = '' "
	// _oSQL:_sQuery += " 		AND SA3.A3_COD = SF2.F2_VEND1 "
	// If mv_par07 == 1
	// 	_oSQL:_sQuery += "      AND A3_ATIVO = 'S' "
	// else
	// 	_oSQL:_sQuery += "      AND A3_ATIVO = 'N' "
	// EndIf
	// _oSQL:_sQuery += "      AND A3_COMIS > 0 "
	// _oSQL:_sQuery += " 	WHERE SD2.D_E_L_E_T_ = '' "
	// _oSQL:_sQuery += " 	AND SD2.D2_COMIS1 > 0 "
	// _oSQL:_sQuery += " 	AND D2_FILIAL  BETWEEN '"+ mv_par01       +"' AND '"+ mv_par02       +"' "
	// _oSQL:_sQuery += " 	AND D2_EMISSAO BETWEEN '"+ dtos(mv_par03) +"' AND '"+ dtos(mv_par04) +"' "
	// //_oSQL:_sQuery += "  AND D2_DOC ='000001346' " // TIRAR DEPOIS
	// _oSQL:_sQuery += " 	) "
	// _oSQL:_sQuery += " SELECT "
	// _oSQL:_sQuery += " 	   VENDEDOR "
	// _oSQL:_sQuery += "    ,FILIAL "
	// _oSQL:_sQuery += "    ,DOCUMENTO "
	// _oSQL:_sQuery += "    ,SERIE "
	// _oSQL:_sQuery += "    ,EMISSAO "
	// _oSQL:_sQuery += "    ,SUM(BASE_PREVISTA) AS BASE_PREVISTA"
	// _oSQL:_sQuery += "    ,ROUND(SUM(BASE_PREVISTA) * PERC_COMISSAO / 100, 2) AS COMISSAO "
	// _oSQL:_sQuery += " FROM C "
	// _oSQL:_sQuery += " WHERE PERC_COMISSAO IS NOT NULL "
	// _oSQL:_sQuery += " GROUP BY VENDEDOR "
	// _oSQL:_sQuery += "    		,FILIAL "
	// _oSQL:_sQuery += "    		,DOCUMENTO "
	// _oSQL:_sQuery += "    		,SERIE "
	// _oSQL:_sQuery += "    		,EMISSAO "
    // _oSQL:_sQuery += "    		,PERC_COMISSAO "
	// _oSQL:_sQuery += " ORDER BY VENDEDOR "
	// _oSQL:_sQuery += " 		,FILIAL "
	// _oSQL:_sQuery += " 		,EMISSAO "
	// _oSQL:_sQuery += " 		,DOCUMENTO "
	// _oSQL:Log()
    // _aNotas := aclone(_oSQL:Qry2Array())

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT
	_oSQL:_sQuery += " 		SF2.F2_VEND1  + ' - ' + SA3.A3_NOME AS VENDEDOR "
	_oSQL:_sQuery += " 	   ,SD2.D2_FILIAL AS FILIAL "
	_oSQL:_sQuery += " 	   ,SD2.D2_DOC AS DOCUMENTO "
	_oSQL:_sQuery += " 	   ,SD2.D2_SERIE AS SERIE "
	_oSQL:_sQuery += " 	   ,SD2.D2_EMISSAO AS EMISSAO "
	_oSQL:_sQuery += " 	   ,SD2.D2_TOTAL AS BASE_PREVISTA "
	_oSQL:_sQuery += " 	   ,SD2.D2_COMIS1 AS PERC_COMISSAO "
    _oSQL:_sQuery += "	   ,ROUND(SUM(SD2.D2_TOTAL) * SD2.D2_COMIS1 / 100, 2) AS COMISSAO "
	_oSQL:_sQuery += " 	FROM " +  RetSQLName ("SD2") + " AS SD2 "
	_oSQL:_sQuery += " 	INNER JOIN " +  RetSQLName ("SF2") + " AS SF2 "
	_oSQL:_sQuery += " 		ON SF2.D_E_L_E_T_  = '' "
	_oSQL:_sQuery += " 		AND SF2.F2_FILIAL  = SD2.D2_FILIAL "
	_oSQL:_sQuery += " 		AND SF2.F2_DOC     = SD2.D2_DOC "
	_oSQL:_sQuery += " 		AND SF2.F2_SERIE   = SD2.D2_SERIE "
	_oSQL:_sQuery += " 		AND SF2.F2_CLIENTE = SD2.D2_CLIENTE "
	_oSQL:_sQuery += " 		AND SF2.F2_LOJA    = SD2.D2_LOJA "
	_oSQL:_sQuery += " 	    AND SF2.F2_VEND1 BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' "
	_oSQL:_sQuery += " 	INNER JOIN " +  RetSQLName ("SA3") + " AS SA3 "
	_oSQL:_sQuery += " 		ON SA3.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA3.A3_COD = SF2.F2_VEND1 "
	If mv_par07 == 1
		_oSQL:_sQuery += "      AND A3_ATIVO = 'S' "
	else
		_oSQL:_sQuery += "      AND A3_ATIVO = 'N' "
	EndIf
	_oSQL:_sQuery += "      AND A3_COMIS > 0 "
	_oSQL:_sQuery += " 	WHERE SD2.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 	AND SD2.D2_COMIS1 > 0 "
	_oSQL:_sQuery += " 	AND D2_FILIAL  BETWEEN '"+ mv_par01       +"' AND '"+ mv_par02       +"' "
	_oSQL:_sQuery += " 	AND D2_EMISSAO BETWEEN '"+ dtos(mv_par03) +"' AND '"+ dtos(mv_par04) +"' "
	_oSQL:_sQuery += " 	GROUP BY SF2.F2_VEND1 "
	_oSQL:_sQuery += " 		,SA3.A3_NOME "
	_oSQL:_sQuery += " 		,SD2.D2_FILIAL "
	_oSQL:_sQuery += " 		,SD2.D2_DOC " 
	_oSQL:_sQuery += " 		,SD2.D2_SERIE "
	_oSQL:_sQuery += " 		,SD2.D2_EMISSAO "
	_oSQL:_sQuery += " 		,SD2.D2_TOTAL "
	_oSQL:_sQuery += " 		,SD2.D2_COMIS1  "
	_oSQL:Log()
    _aNotas := aclone(_oSQL:Qry2Array())

	For _x:=1 to Len(_aNotas)
		_sFilial := _aNotas[_x, 2]
		_sNumero := _aNotas[_x, 3]
		_sSerie  := _aNotas[_x, 4]
		_nTotCom := _aNotas[_x, 8]

		_nQtdPar   := BuscaQtdParcela(_sFilial, _sNumero, _sSerie) 				// Quantidade de parcelas
		_nComPar   := _nTotCom/_nQtdPar   										// Comissão de cada parcela
		_nVlrSaldo := BuscaQtdSaldo(_sFilial, _sNumero, _sSerie,_nComPar)      	// Valor de comissão de parcelas sem baixas (E1_BAIXA VAZIO)
		_nVlrBaixa := BuscaVlrBaixado(_sFilial, _sNumero, _sSerie, _nComPar)	// valor baixado após a data final da posição
		_nVlrCP    := BuscaVlrParcial(_sFilial, _sNumero, _sSerie, _nComPar)	// valor de comissão de parcela parcial		

		//_nVlrParBai := BuscaBaixaParcial(_sFilial, _sNumero, _sSerie, _nComPar) // valor baixado após a data final da posição - valor parcial
		_nValor     := _nVlrSaldo + _nVlrBaixa  + _nVlrCP// + _nVlrParBai			// valor comissao sem baixa parcial + valor comissao parcial + valor ja baixado (apos data da posição)	

		//u_help ("saldo " + str(_nVlrSaldo) + " baixado " + str(_nVlrBaixa) + " baixa parcial " + str(_nVlrCP))
		If _nValor <> 0
			oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aNotas[_x,1] 						}) 	
			oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aNotas[_x,2] 						}) 		
			oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aNotas[_x,3] + " " +_aNotas[_x,4] }) 		
			oSection1:Cell("COLUNA4")	:SetBlock   ({|| stod(_aNotas[_x,5]) 				}) 		
			oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aNotas[_x,6] 						}) 	
			oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aNotas[_x,7] 						}) 
			oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aNotas[_x,8] 						}) 
			oSection1:Cell("COLUNA8")	:SetBlock   ({|| _nQtdPar 							}) 
			oSection1:Cell("COLUNA9")	:SetBlock   ({|| _nValor 							}) 		   

			oSection1:PrintLine()	
		EndIf
	Next
	oSection1:Finish()
	
Return
//
// -------------------------------------------------------------------------
// Busca quantidade total de parcelas
Static Function BuscaQtdParcela(_sFilial, _sNumero, _sSerie)
	Local _aParcela := {}
	Local _x        := 0
	Local _nRet     := 1

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 		COUNT(*) "
	_oSQL:_sQuery += " FROM " +  RetSQLName ("SE1") 
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND E1_FILIAL  = '"+ _sFilial +"'"
	_oSQL:_sQuery += " AND E1_NUM     = '"+ _sNumero +"'"
	_oSQL:_sQuery += " AND E1_PREFIXO = '"+ _sSerie  +"'"
	_aParcela := aclone(_oSQL:Qry2Array())

	For _x:=1 to Len(_aParcela)
		_nRet := _aParcela[_x,1]
	Next
Return _nRet
//
// -------------------------------------------------------------------------
// Busca valor de parcela em aberto
Static Function BuscaQtdSaldo(_sFilial, _sNumero, _sSerie, _nComPar)
	Local _aParcela := {}
	Local _nRet     := 0

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 		E1_SALDO, E1_BAIXA, E1_VALOR "
	_oSQL:_sQuery += " FROM " +  RetSQLName ("SE1") 
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND E1_FILIAL  = '"+ _sFilial +"'"
	_oSQL:_sQuery += " AND E1_NUM     = '"+ _sNumero +"'"
	_oSQL:_sQuery += " AND E1_PREFIXO = '"+ _sSerie  +"'"
	_oSQL:_sQuery += " AND E1_SALDO = E1_VALOR "
	_aParcela := aclone(_oSQL:Qry2Array())

	If Len(_aParcela) > 0
		_nRet := _nComPar * Len(_aParcela)
	else
		_nRet := 0
	EndIf
	
Return _nRet
//
// -------------------------------------------------------------------------
// Busca baixas efetuadas após a data final da pesquisa
Static Function BuscaVlrBaixado(_sFilial, _sNumero, _sSerie, _nComPar)
	Local _aParcela := {}
	Local _nRet     := 0

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 		 E1_SALDO, E1_BAIXA, E1_VALOR " 
	_oSQL:_sQuery += " FROM " +  RetSQLName ("SE1") 
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND E1_FILIAL  = '"+ _sFilial +"'"
	_oSQL:_sQuery += " AND E1_NUM     = '"+ _sNumero +"'"
	_oSQL:_sQuery += " AND E1_PREFIXO = '"+ _sSerie  +"'"
	_oSQL:_sQuery += " AND E1_BAIXA <> ''"
	_oSQL:_sQuery += " AND E1_BAIXA > '"+dtos(mv_par04) +"'"
	_aParcela := aclone(_oSQL:Qry2Array())

	If Len(_aParcela) > 0
		_nRet := _nComPar * Len(_aParcela)
	else
		_nRet := 0
	EndIf
Return _nRet
//
// -------------------------------------------------------------------------
// Busca quantidade de parcela com saldo parcial
Static Function BuscaVlrParcial(_sFilial, _sNumero, _sSerie, _nComPar)
	Local _aParcela := {}
	Local _x        := 0
	Local _nRet     := 0
	Local _nVlr     := 0
	Local _nVlr2    := 0

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += "        E1_VALOR 
	_oSQL:_sQuery += " 		 ,E1_VALOR - E1_SALDO AS VLR_BAIXA "
	_oSQL:_sQuery += " FROM " +  RetSQLName ("SE1") 
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND E1_FILIAL  = '"+ _sFilial +"'"
	_oSQL:_sQuery += " AND E1_NUM     = '"+ _sNumero +"'"
	_oSQL:_sQuery += " AND E1_PREFIXO = '"+ _sSerie  +"'"
	_oSQL:_sQuery += " AND E1_SALDO <> E1_VALOR "
	_oSQL:_sQuery += " AND E1_SALDO <> 0 "
	_oSQL:_sQuery += " AND E1_BAIXA <= '"+ dtos(mv_par04) +"'"
	_aParcela := aclone(_oSQL:Qry2Array())

	For _x:=1 to Len(_aParcela)
		_nVlr  := _aParcela[_x, 1]
		_nVlr2 := _aParcela[_x, 2]
		_nRet += _nComPar - (_nVlr2 * _nComPar / _nVlr)
	Next
Return _nRet
// //
// // -------------------------------------------------------------------------
// // Busca baixas efetuadas após a data final da pesquisa - parcial
// Static Function BuscaBaixaParcial(_sFilial, _sNumero, _sSerie, _nComPar)
// 	Local _aParcela := {}
// 	Local _x        := 0
// 	Local _nRet     := 0

// 	_oSQL:= ClsSQL ():New ()
// 	_oSQL:_sQuery := ""
// 	_oSQL:_sQuery += " SELECT "
// 	_oSQL:_sQuery += "        E1_VALOR 
// 	_oSQL:_sQuery += " 		 ,E1_VALOR - E1_SALDO AS VLR_BAIXA "
// 	_oSQL:_sQuery += " FROM " +  RetSQLName ("SE1") 
// 	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
// 	_oSQL:_sQuery += " AND E1_FILIAL  = '"+ _sFilial +"'"
// 	_oSQL:_sQuery += " AND E1_NUM     = '"+ _sNumero +"'"
// 	_oSQL:_sQuery += " AND E1_PREFIXO = '"+ _sSerie  +"'"
// 	_oSQL:_sQuery += " AND E1_BAIXA > '"+dtos(mv_par04) +"'"
// 	_oSQL:_sQuery += " AND E1_SALDO <> E1_VALOR "
// 	_oSQL:_sQuery += " AND E1_SALDO <> 0 "
// 	_aParcela := aclone(_oSQL:Qry2Array())

// 	For _x:=1 to Len(_aParcela)
// 		_nVlr      := _aParcela[_x, 1]
// 		_nVlrBaixa := _aParcela[_x, 2]
// 		_nRet += _nVlrBaixa * _nComPar / _nVlr
// 	Next
// Return _nRet
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT             TIPO TAM DEC VALID F3        Opcoes                               Help
    aadd (_aRegsPerg, {01, "Filial de       ", "C", 2, 0,  "",   "   "      , {},                         		 ""})
	aadd (_aRegsPerg, {02, "Filial até      ", "C", 2, 0,  "",   "   "      , {},                         		 ""})
    aadd (_aRegsPerg, {03, "Emissão de      ", "D", 8, 0,  "",   "   "      , {},                         		 ""})
    aadd (_aRegsPerg, {04, "Emissão até     ", "D", 8, 0,  "",   "   "      , {},                         		 ""})
    aadd (_aRegsPerg, {05, "Vendedor de     ", "C", 6, 0,  "",   "SA3"      , {},                         		 ""})
    aadd (_aRegsPerg, {06, "Vendedor até    ", "C", 6, 0,  "",   "SA3"      , {},                         		 ""})
	aadd (_aRegsPerg, {07, "Vendedor ativo? ", "N", 1, 0,  "",   "   "      , {"Sim","Não"},                     ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
