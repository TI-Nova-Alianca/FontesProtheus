// Programa.: ML_COMVEND
// Autor....: Claudia Lionço
// Data.....: 13/01/2022
// Descricao: Demonstrativo de indenização sobre comissões
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Relatório
// #Descricao         #Demonstrativo de indenização sobre comissões
// #PalavasChave      #comissao #provisionado 
// #TabelasPrincipais #SE3 #SA1
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
// 13/01/2022 - Claudia - Realizado melhorias no relatorio, originalmente desenvolvido por 
//                        Catia Cardoso, conforme GLPI: 11468
// 09/05/2022 - Claudia - Descontado valores de verbas e devoluções dos valores. GLPI: 11925
//
// --------------------------------------------------------------------------------------------------- 
#include 'protheus.ch'
#include 'parmtype.ch'

User Function ML_COMVEND()
	Private oReport
	Private cPerg   := "ML_COMVEND"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// --------------------------------------------------------------------------
// Imprime relatório
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	//Local oFunction

	oReport := TReport():New("ML_COMVEND","Demonstrativo de indenização sobre comissões",cPerg,{|oReport| PrintReport(oReport)},"Demonstrativo de indenização sobre comissões")
	
	//oReport:ShowParamPage() // imprime parametros
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
    TRCell():New(oSection1,"COLUNA0", 	"" ,"Vendedor"		      ,	    					,30,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		      ,	    					,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Dt.Pagamento"        ,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Valor Comissão"      , "@E 999,999,999.99"   	,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Desconto Verbas/Dev.", "@E 999,999,999.99"   	,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA5", 	"" ,"Comissão corrigida"  , "@E 999,999,999.99"   	,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"1/2 Avos"		      , "@E 999,999,999.99"   	,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    
    oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA0"),"Total do vendedor")
    TRFunction():New(oSection1:Cell("COLUNA3")	,,"SUM"	,oBreak1,"Total comissão "          , "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA4")	,,"SUM"	,oBreak1,"Total desconto "          , "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA5")	,,"SUM"	,oBreak1,"Total comissão corrigida ", "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA6")	,,"SUM"	,oBreak1,"Valor 1/2 Avos "          , "@E 99,999,999.99", NIL, .F., .T.)

Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local _x        := 0
    Local _i        := 0

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " WITH C "
    _oSQL:_sQuery += " AS "
    _oSQL:_sQuery += " (SELECT "
    _oSQL:_sQuery += " 		SE3.E3_VEND AS COD_VEND "
    _oSQL:_sQuery += " 	   ,SA3.A3_NOME AS COD_NOME "
    _oSQL:_sQuery += " 	   ,SE3.E3_FILIAL AS FILIAL "
    _oSQL:_sQuery += " 	   ,SE3.E3_DATA AS DATAPGTO "
    _oSQL:_sQuery += " 	   ,CASE "
    _oSQL:_sQuery += " 			WHEN SE3.E3_DATA < '20220101' THEN SA3.A3_INDENIZ "
    _oSQL:_sQuery += " 			ELSE SA3.A3_INDEBKP "
    _oSQL:_sQuery += " 		END AS INDENIZACAO "
    _oSQL:_sQuery += " 	   ,SUM(SE3.E3_COMIS) AS COMISSAO "
    _oSQL:_sQuery += " 	   ,ROUND(SUM(SE3.E3_COMIS) / 12, 2) AS AVOS_1_2 "
    _oSQL:_sQuery += " 	FROM " + RetSqlName("SE3") + " AS SE3"
    _oSQL:_sQuery += " 	INNER JOIN " + RetSqlName("SA3") + " AS SA3"
    _oSQL:_sQuery += " 		ON (SA3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SA3.A3_COD = SE3.E3_VEND) "
    _oSQL:_sQuery += " 	WHERE SE3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 	AND SE3.E3_VEND = '" + mv_par01 + "' "
    _oSQL:_sQuery += " 	AND SE3.E3_DATA <> '' "
    _oSQL:_sQuery += " 	GROUP BY SE3.E3_FILIAL "
    _oSQL:_sQuery += " 			,SE3.E3_VEND "
    _oSQL:_sQuery += " 			,SA3.A3_NOME "
    _oSQL:_sQuery += " 			,SE3.E3_DATA "
    _oSQL:_sQuery += " 			,SA3.A3_INDENIZ "
    _oSQL:_sQuery += " 			,SA3.A3_INDEBKP) "
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   COD_VEND "
    _oSQL:_sQuery += "    ,COD_NOME "
    _oSQL:_sQuery += "    ,FILIAL "
    _oSQL:_sQuery += "    ,DATAPGTO "
    _oSQL:_sQuery += "    ,INDENIZACAO "
    _oSQL:_sQuery += "    ,SUM(COMISSAO) "
    _oSQL:_sQuery += "    ,AVOS_1_2 "
    _oSQL:_sQuery += " FROM C "
    If (mv_par03 == 2)
        _oSQL:_sQuery += " WHERE INDENIZACAO = 'S' "
    else
        _oSQL:_sQuery += " WHERE INDENIZACAO = 'N' "
    EndIf
    _oSQL:_sQuery += " GROUP BY COD_VEND "
    _oSQL:_sQuery += " 		,COD_NOME "
    _oSQL:_sQuery += " 		,FILIAL "
    _oSQL:_sQuery += " 		,DATAPGTO "
    _oSQL:_sQuery += " 		,INDENIZACAO "
    _oSQL:_sQuery += " 		,AVOS_1_2 "
    _oSQL:_sQuery += " ORDER BY FILIAL, COD_VEND, DATAPGTO DESC "
    //u_log(_oSQL:_sQuery)
    _aDados := aclone (_oSQL:Qry2Array ())

	For _x:=1 to Len(_aDados)
        If _x == 1 // primeira linha
            _sVendedor := alltrim(_aDados[_x, 1]) + " - " + _aDados[_x, 2]

            oReport:PrintText("VENDEDOR:" +  _sVendedor,, 100)
            oReport:SkipLine(1)
        EndIf

        _dDtPgto   := stod(_aDados[_x, 4])
        _dDtAnt    := MonthSub(_dDtPgto, 1)
        _dDtAntIni := FirstDate(_dDtAnt)
        _dDtAntFim := LastDate(_dDtAnt)

        // descontos de verbas e devoluções
        _nVlrDesc := _VlrVerbasDev(_aDados[_x, 1], _dDtAntIni, _dDtAntFim)
        _nVlrDesc := _nVlrDesc * -1
        // calculo
        _nComissao  := _aDados[_x, 6]
		_nComisPaga := _aDados[_x, 6] - _nVlrDesc
		_n12Avos    := _nComisPaga/12

        If mv_par02 == 1
            _sDt := substr(_aDados[_x, 4],1, 6) + '01'

            _oSQL:= ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " SELECT "
            _oSQL:_sQuery += " 	    ZAI_INPC "
            _oSQL:_sQuery += " FROM " + RetSqlName("ZAI") 
            _oSQL:_sQuery += " WHERE ZAI_DATA >= '" + _sDt + "'"
            _oSQL:_sQuery += " ORDER BY ZAI_DATA ""
            _aINPC := aclone (_oSQL:Qry2Array ())

            For _i:=1 to Len(_aINPC)
                _nComisPaga += ROUND((_nComisPaga * _aINPC[_i, 1])/100, 4) 
            Next
            _n12Avos := _nComisPaga/12
        EndIf
        
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[_x, 3]       }) // filial
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _dDtPgto             }) // dt.pagto
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _nComissao           }) // vlr.comissao
        oSection1:Cell("COLUNA4")	:SetBlock   ({|| _nVlrDesc            }) // vlr.desconto
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _nComisPaga          }) // vlr.comissao corrigida
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _n12Avos             }) // vlr.1/2 avos
		
		oSection1:PrintLine()
	Next

	oSection1:Finish()
Return
//
// --------------------------------------------------------------------------
// Busca descontos de verbas e devoluções
Static Function _VlrVerbasDev(_sVend, _dDtAntIni, _dDtAntFim)
    Local _y       := 0
    Local _nVlr    := 0
    Local _aRet    := {}
    Local _dDtaAnt := DaySub(_dDtAntFim,180) // diminui 6 meses

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " WITH DESCONTO "
    _oSQL:_sQuery += " AS "
    _oSQL:_sQuery += " ( "
    _oSQL:_sQuery += "     SELECT "
    _oSQL:_sQuery += " 		    E5_VALOR * (SELECT "
    _oSQL:_sQuery += " 				SUM(E1_COMIS1) / COUNT(*) "
    _oSQL:_sQuery += " 			FROM " + RetSqlName("SE1") + " AS SE1 "
    _oSQL:_sQuery += " 			WHERE SE1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND SE1.E1_CLIENTE IN (SELECT "
    _oSQL:_sQuery += " 					SA1.A1_COD "
    _oSQL:_sQuery += " 				FROM " + RetSqlName("SA1") + " AS SA1 "
    _oSQL:_sQuery += " 				WHERE SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 				AND SA1.A1_VACBASE = (SELECT "
    _oSQL:_sQuery += " 						SA11.A1_VACBASE "
    _oSQL:_sQuery += " 					FROM " + RetSqlName("SA1") + " AS SA11 "
    _oSQL:_sQuery += " 					WHERE SA11.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 					AND SA11.A1_COD = SE5.E5_CLIFOR "
    _oSQL:_sQuery += " 					AND SA11.A1_LOJA = SE5.E5_LOJA)) "
    _oSQL:_sQuery += " 			AND SE1.E1_LOJA = SE5.E5_LOJA "
    _oSQL:_sQuery += " 			AND SE1.E1_COMIS1 <> 0 "
    _oSQL:_sQuery += " 			AND SE1.E1_VEND1 = '"+ _sVend +"' "
    _oSQL:_sQuery += " 			AND SE1.E1_EMISSAO BETWEEN '" + dtos(_dDtaAnt) + "' AND '" + dtos(_dDtAntFim) + "') "
    _oSQL:_sQuery += " 		/ 100 * -1 AS DESCONTO "
    _oSQL:_sQuery += " 	FROM " + RetSqlName("SE5") + " AS SE5 "
    _oSQL:_sQuery += " 	INNER JOIN " + RetSqlName("SA1") + " AS SA1 "
    _oSQL:_sQuery += " 		ON (SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SA1.A1_COD = SE5.E5_CLIFOR "
    _oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE5.E5_LOJA "
    _oSQL:_sQuery += " 		AND SA1.A1_VEND = '"+ _sVend +"') "
    _oSQL:_sQuery += " 	WHERE SE5.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 	AND E5_FILIAL = '" + xFilial("SE5") + "' "
    _oSQL:_sQuery += " 	AND E5_DATA BETWEEN '" + dtos(_dDtAntIni) + "' AND '" + dtos(_dDtAntFim) + "'"
    _oSQL:_sQuery += " 	AND E5_TIPO = 'NCC' "
    _oSQL:_sQuery += " 	AND E5_MOTBX = 'DEB' "
    _oSQL:_sQuery += " 	AND E5_NATUREZ <> 'VERBAS' "
    _oSQL:_sQuery += " 	UNION ALL "
    _oSQL:_sQuery += " 	SELECT "
    _oSQL:_sQuery += " 		SUM(ZB0_VLCOMS) AS DESCONTO "
    _oSQL:_sQuery += " 	FROM " + RetSqlName("ZB0") + " AS ZB0 "
    _oSQL:_sQuery += " 	WHERE ZB0.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "  AND ZB0_FILIAL = '" + xFilial("ZB0") + "' "
    _oSQL:_sQuery += " 	AND ZB0_DATA BETWEEN '" + dtos(_dDtAntIni) + "' AND '" + dtos(_dDtAntFim) + "'"
    _oSQL:_sQuery += " 	AND ZB0_VENDCH = '"+ _sVend +"')"
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	    SUM(DESCONTO) "
    _oSQL:_sQuery += " FROM DESCONTO "
    //u_log(_oSQL:_sQuery)
    _aRet := aclone (_oSQL:Qry2Array ())

	For _y:=1 to Len(_aRet)
        _nVlr += _aRet[_y,1]
    Next
Return _nVlr
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    aadd (_aRegsPerg, {01, "Representante          ", "C", 3,  0,  "", "SA3", {}                        ,  ""})
	aadd (_aRegsPerg, {02, "Lista valor corrigido ?", "N", 1,  0,  "",    "", {"Sim", "Não"}			,  ""})
    aadd (_aRegsPerg, {03, "Tipo comissão          ", "N", 1,  0,  "",    "", {"Provisionado", "Pago"}	, ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
