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
	//oReport:SetLandScape(.T.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
    TRCell():New(oSection1,"COLUNA0", 	"" ,"Vendedor"		    ,	    					,30,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		    ,	    					,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Dt.Pagamento"      ,       					,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Valor Comissão"    , "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Comissão corrigida", "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"1/2 Avos"		    , "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    
    oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA0"),"Total do vendedor")
    TRFunction():New(oSection1:Cell("COLUNA3")	,,"SUM"	,oBreak1,"Total comissão "          , "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA4")	,,"SUM"	,oBreak1,"Total comissão corrigida ", "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA5")	,,"SUM"	,oBreak1,"Valor 1/2 Avos "          , "@E 99,999,999.99", NIL, .F., .T.)

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
    _oSQL:_sQuery += " WITH C
    _oSQL:_sQuery += " AS "
    _oSQL:_sQuery += " (SELECT "
    _oSQL:_sQuery += " 		SE3.E3_VEND AS COD_VEND "
    _oSQL:_sQuery += " 	   ,SA3.A3_NOME AS COD_NOME "
    _oSQL:_sQuery += " 	   ,SE3.E3_FILIAL AS FILIAL "
    _oSQL:_sQuery += " 	   ,SE3.E3_EMISSAO AS EMISSAO "
    _oSQL:_sQuery += " 	   ,CASE "
    _oSQL:_sQuery += " 			WHEN SE3.E3_EMISSAO < '20220101' THEN SA3.A3_INDENIZ "
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
    _oSQL:_sQuery += " 			,SE3.E3_EMISSAO "
    _oSQL:_sQuery += " 			,SA3.A3_INDENIZ "
    _oSQL:_sQuery += " 			,SA3.A3_INDEBKP) "
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	* "
    _oSQL:_sQuery += " FROM C "
    If (mv_par03 == 1)
        _oSQL:_sQuery += " WHERE INDENIZACAO = 'S' "
    else
        _oSQL:_sQuery += " WHERE INDENIZACAO = 'N' "
    EndIf
    _oSQL:_sQuery += " ORDER BY FILIAL, COD_VEND, EMISSAO DESC"
    _aDados := aclone (_oSQL:Qry2Array ())

	For _x:=1 to Len(_aDados)
        If _x == 1 // primeira linha
            _sVendedor := alltrim(_aDados[_x, 1]) + " - " + _aDados[_x, 2]

            oReport:PrintText("VENDEDOR:" +  _sVendedor,, 100)
            oReport:SkipLine(1)
        EndIf

		_nComissao  := _aDados[_x, 6]
		_nComisPaga := _aDados[_x, 6]
		_n12Avos    := _nComisPaga/12

        If mv_par02 == 1
            _oSQL:= ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " SELECT "
            _oSQL:_sQuery += " 	    ZAI_INPC "
            _oSQL:_sQuery += " FROM " + RetSqlName("ZAI") 
            _oSQL:_sQuery += " WHERE ZAI_DATA > '"+ _aDados[_x, 4] +"'"
            _oSQL:_sQuery += " ORDER BY ZAI_DATA ""
            _aINPC := aclone (_oSQL:Qry2Array ())

            For _i:=1 to Len(_aINPC)
                _nComisPaga += ROUND((_nComisPaga * _aINPC[_i, 1])/100, 4) 
            Next
            _n12Avos := _nComisPaga/12
        EndIf
        
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[_x, 3]       }) // filial
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| stod(_aDados[_x, 4]) }) // dt.pagto
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _nComissao           }) // vlr.comissao
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _nComisPaga          }) // vlr.comissao corrigida
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _n12Avos             }) // vlr.1/2 avos
		
		oSection1:PrintLine()
	Next

	oSection1:Finish()
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    aadd (_aRegsPerg, {01, "Representante          ", "C", 6,  0,  "", "SA3", {}                        ,  ""})
	aadd (_aRegsPerg, {02, "Lista valor corrigido ?", "N", 1,  0,  "",    "", {"Sim", "Não"}			,  ""})
    aadd (_aRegsPerg, {03, "Tipo comissão          ", "N", 1,  0,  "",    "", {"Provisionado", "Pago"}	, ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
