//  Programa...: VA_PVENDP
//  Autor......: Sandra Sugari
//  Data.......: 16/05/2022
//  Cliente....: Alianca
//  Descricao..: Produtos Vendidos no Periodo
//
// #TipoDePrograma    #relatorio
// #Descricao         #Produtos Vendidos no Periodo
// #PalavasChave      #produtos#vendidos#
// #TabelasPrincipais #BI_ALIANCA.dbo.VA_FATDADOS,#SB1,#ZX5 
// #Modulos 		  #CONT
//
// Historico de alteracoes:
// 
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User Function VA_PVENDP()
	Private oReport
	Private cPerg := "VA_PVENDP"
    
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()

Return
//
// -------------------------------------------------------------------------
Static Function ReportDef()
    Local oReport   := Nil
	Local oSection1 := Nil

    oReport := TReport():New("VA_PVENDP","Produtos Vendidos no Periodo",cPerg,{|oReport| PrintReport(oReport)},"Produtos Vendidos no Periodo")
	oReport:SetLandscape()
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"FILIAL"		    ,	    				,02,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"TIPOPROD"		    ,       				,04,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"COD_PROD"			,						,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA4", 	"" ,"DESCRICAO"			,       				,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"CODLINHA"		    ,       				,02,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"LINHA"		        ,       				,16,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA7", 	"" ,"QTDE"          	,       				,8,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"UNIDADE"	        ,       				,04,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA9", 	"" ,"LITROS"	        ,       				,8,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"VRL_FATURADO_UN"   , "@E 999,999,999.99"   ,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA11", 	"" ,"VRL_TOTAL"	        , "@E 999,999,999.99"   ,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA12", 	"" ,"CUSTO_TOTAL"	    , "@E 999,999,999.99"   ,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA13", 	"" ,"CUSTO_UN"	        , "@E 999,999,999.99"   ,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA14", 	"" ,"CUSTO_STANDER"	    , "@E 999,999,999.99"   ,17,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA15", 	"" ,"MARGEM_%"	        ,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA16", 	"" ,"CPV_%"	            ,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)	
    Local _aDados   := {}
    Local i         := 0

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += "	 FILIAL "
    _oSQL:_sQuery += "   ,TIPOPROD "
    _oSQL:_sQuery += "   ,PRODUTO AS COD_PROD "
    _oSQL:_sQuery += "   ,SB1.B1_DESC AS DESCRICAO "
    _oSQL:_sQuery += "   ,CODLINHA "
    _oSQL:_sQuery += "   ,RTRIM(ISNULL(ZX5_39.ZX5_39DESC, '')) AS LINHA "
    _oSQL:_sQuery += "   ,SUM(QUANTIDADE) AS QTDE "
    _oSQL:_sQuery += "   ,SB1.B1_UM AS UNIDADE "
    _oSQL:_sQuery += "   ,SUM(QTLITROS) AS LITROS "
    _oSQL:_sQuery += "   ,ROUND(SUM(TOTAL) / SUM(QUANTIDADE), 2) AS VRL_FATURADO_UN "
    _oSQL:_sQuery += "   ,ROUND(SUM(TOTAL), 2) AS VRL_TOTAL "
    _oSQL:_sQuery += "   ,ROUND(SUM(CUSTOMEDIO), 2) AS CUSTO_TOTAL "
    _oSQL:_sQuery += "   ,ROUND(AVG(CUSTOMEDIO / QUANTIDADE), 2) AS CUSTO_UN "
    _oSQL:_sQuery += "   ,SB1.B1_CUSTD AS CUSTO_STANDER"
    _oSQL:_sQuery += "   ,ROUND((SUM(TOTAL) - SUM(CUSTOMEDIO)) / SUM(TOTAL) * 100, 1) AS 'MARGEM_%' "
    _oSQL:_sQuery += "   ,ROUND(SUM(CUSTOMEDIO) / SUM(TOTAL) * 100, 0) AS 'CPV_%' "
    _oSQL:_sQuery += " FROM BI_ALIANCA.dbo.VA_FATDADOS "
    _oSQL:_sQuery += " INNER JOIN SB1010 AS SB1 "
    _oSQL:_sQuery += "	    ON (SB1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "			AND SB1.B1_COD = PRODUTO) "
    _oSQL:_sQuery += " LEFT JOIN ZX5010 AS ZX5_39 "
    _oSQL:_sQuery += "	    ON (ZX5_39.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "			AND ZX5_39.ZX5_TABELA = '39' "
    _oSQL:_sQuery += "			AND ZX5_39.ZX5_39COD = CODLINHA) "
    _oSQL:_sQuery += " WHERE F4_MARGEM = '1' "
    _oSQL:_sQuery += " AND FILIAL BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
    _oSQL:_sQuery += " AND EMISSAO BETWEEN '" + DTOS(mv_par03) + "' and '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += " GROUP BY FILIAL "
    _oSQL:_sQuery += "	    ,TIPOPROD "
    _oSQL:_sQuery += "		,PRODUTO "
    _oSQL:_sQuery += "		,SB1.B1_DESC "
    _oSQL:_sQuery += "		,SB1.B1_UM "
    _oSQL:_sQuery += "		,SB1.B1_LINHA "
    _oSQL:_sQuery += "		,ZX5_39DESC "
    _oSQL:_sQuery += "		,CODLINHA "
    _oSQL:_sQuery += "		,SB1.B1_CUSTD "
    _aDados := _oSQL:Qry2Array ()


    oSection1:Init()

    For i := 1 to Len(_aDados)
        oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[i,1] })
        oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aDados[i,2] })
        oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aDados[i,3] })
        oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aDados[i,4] })
        oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aDados[i,5] })
        oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aDados[i,6] })
        oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aDados[i,7] })
        oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aDados[i,8] })
        oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aDados[i,9] })
        oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aDados[i,10] })
        oSection1:Cell("COLUNA11")	:SetBlock   ({|| _aDados[i,11] })
        oSection1:Cell("COLUNA12")	:SetBlock   ({|| _aDados[i,12] })
        oSection1:Cell("COLUNA13")	:SetBlock   ({|| _aDados[i,13] })
        oSection1:Cell("COLUNA14")	:SetBlock   ({|| _aDados[i,14] })
        oSection1:Cell("COLUNA15")	:SetBlock   ({|| _aDados[i,15] })
        oSection1:Cell("COLUNA16")	:SetBlock   ({|| _aDados[i,16] })

        oSection1:PrintLine()
    Next

    oSection1:Finish()
Return
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                     TIPO TAM DEC VALID   F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Filial de                 ", "C", 2, 0,  "",   "SM0", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Filial ate                ", "C", 2, 0,  "",   "SM0", {},                        		 ""})
    aadd (_aRegsPerg, {03, "Data de                   ", "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {04, "Data ate                  ", "D", 8, 0,  "",   "   ", {},                        		 ""})
    aadd (_aRegsPerg, {05, "Produto de                ", "C", 15, 0, "",   "SB1", {},                         		 ""})
    aadd (_aRegsPerg, {06, "Produto ate               ", "C", 15, 0, "",   "SB1", {},                         		 ""})
    aadd (_aRegsPerg, {07, "Tipo de Produto de        ", "C", 2, 0,  "",   "02 ", {},                         		 ""})
    aadd (_aRegsPerg, {08, "Tipo de Produto ate       ", "C", 2, 0,  "",   "02 ", {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
