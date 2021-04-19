//  Programa...: ZB1DIF
//  Autor......: Cláudia Lionço
//  Data.......: 19/04/2021
//  Cliente....: Alianca
//  Descricao..: Relatório de diferença de baixas
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de diferença de baixas
// #PalavasChave      #cartao #titulos #baixas #diferencas
// #TabelasPrincipais #SE1 
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User Function ZB1DIF()
	Private oReport
	Private cPerg := "ZB1DIF"
	
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

    oReport := TReport():New("ZB1DIF","Diferenças de baixas",cPerg,{|oReport| PrintReport(oReport)},"Diferenças de baixas")
	
	// DEVOLUÇÕES
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    				,08,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Título"		,       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Prefixo"		,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Parc."			,						,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA5", 	"" ,"Tipo"			,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA6", 	"" ,"Dt.Emissão"	,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA7", 	"" ,"NSU"			,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Autorização"	,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA9", 	"" ,"Valor SE1"		, "@E 999,999,999.99"   ,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"Valor SE5"		, "@E 999,999,999.99"   ,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA11", 	"" ,"Valor Difer."	, "@E 999,999,999.99"   ,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)	
    Local _aDados   := {}
    Local i         := 0

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += "	WITH C"
    _oSQL:_sQuery += "	AS"
    _oSQL:_sQuery += "	(SELECT"
    _oSQL:_sQuery += "			SE1.E1_FILIAL AS FILIAL"
    _oSQL:_sQuery += "		   ,SE1.E1_NUM AS NUMERO"
    _oSQL:_sQuery += "		   ,SE1.E1_PREFIXO AS PREFIXO"
    _oSQL:_sQuery += "		   ,SE1.E1_PARCELA AS PARCELA"
    _oSQL:_sQuery += "		   ,SE1.E1_TIPO AS TIPO"
    _oSQL:_sQuery += "		   ,SE1.E1_EMISSAO AS EMISSAO"
    _oSQL:_sQuery += "		   ,SE1.E1_NSUTEF AS NSU"
    _oSQL:_sQuery += "		   ,SE1.E1_CARTAUT AS CODAUT"
    _oSQL:_sQuery += "		   ,ROUND(CAST(SE1.E1_VALOR AS FLOAT), 2) AS VALOR_SE1"
    _oSQL:_sQuery += "		   ,ROUND(SUM(ISNULL(SE5.E5_VALOR, 0) - ISNULL(SE5A.E5_VALOR, 0)), 2) AS VALOR_SE5"
    _oSQL:_sQuery += "		FROM " + RetSQLName ("SE1") + " SE1"
    _oSQL:_sQuery += "		INNER JOIN " + RetSQLName ("SE5") + " SE5"
    _oSQL:_sQuery += "			ON SE5.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "			AND SE5.E5_FILIAL = SE1.E1_FILIAL"
    _oSQL:_sQuery += "			AND SE5.E5_NUMERO = SE1.E1_NUM"
    _oSQL:_sQuery += "			AND SE5.E5_PREFIXO = SE1.E1_PREFIXO"
    _oSQL:_sQuery += "			AND SE5.E5_PARCELA = SE1.E1_PARCELA"
    _oSQL:_sQuery += "			AND SE5.E5_CLIFOR = SE1.E1_CLIENTE"
    _oSQL:_sQuery += "			AND SE5.E5_LOJA = SE1.E1_LOJA"
    _oSQL:_sQuery += "			AND SE5.E5_RECPAG = 'R'"
    _oSQL:_sQuery += "			AND SE5.E5_TIPODOC IN ('VL', 'DC')"
    _oSQL:_sQuery += "		LEFT JOIN " + RetSQLName ("SE5") + " SE5A"
    _oSQL:_sQuery += "			ON SE5A.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "			AND SE5A.E5_FILIAL = SE1.E1_FILIAL"
    _oSQL:_sQuery += "			AND SE5A.E5_NUMERO = SE1.E1_NUM"
    _oSQL:_sQuery += "			AND SE5A.E5_PREFIXO = SE1.E1_PREFIXO"
    _oSQL:_sQuery += "			AND SE5A.E5_PARCELA = SE1.E1_PARCELA"
    _oSQL:_sQuery += "			AND SE5A.E5_CLIFOR = SE1.E1_CLIENTE"
    _oSQL:_sQuery += "			AND SE5A.E5_LOJA = SE1.E1_LOJA"
    _oSQL:_sQuery += "			AND SE5A.E5_RECPAG = 'R'"
    _oSQL:_sQuery += "			AND SE5A.E5_TIPODOC = 'JR'"
    _oSQL:_sQuery += "		WHERE SE1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "		AND SE1.E1_FILIAL BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'"
    _oSQL:_sQuery += "		AND SE1.E1_EMISSAO >= '" + DTOS(MV_PAR03)+ "'"
    _oSQL:_sQuery += "		AND E1_TIPO IN ('CC', 'CD')"
    _oSQL:_sQuery += "		GROUP BY SE1.E1_FILIAL"
    _oSQL:_sQuery += "				,SE1.E1_NUM"
    _oSQL:_sQuery += "				,SE1.E1_PREFIXO"
    _oSQL:_sQuery += "				,SE1.E1_PARCELA"
    _oSQL:_sQuery += "				,SE1.E1_TIPO "
    _oSQL:_sQuery += "				,SE1.E1_EMISSAO"
    _oSQL:_sQuery += "				,SE1.E1_NSUTEF "
    _oSQL:_sQuery += "				,SE1.E1_CARTAUT "
    _oSQL:_sQuery += "				,SE1.E1_VALOR)"
    _oSQL:_sQuery += "	SELECT"
    _oSQL:_sQuery += "		FILIAL"
    _oSQL:_sQuery += "	   ,NUMERO"
    _oSQL:_sQuery += "	   ,PREFIXO"
    _oSQL:_sQuery += "	   ,PARCELA"
    _oSQL:_sQuery += "	   ,TIPO"
    _oSQL:_sQuery += "	   ,EMISSAO"
    _oSQL:_sQuery += "	   ,NSU"
    _oSQL:_sQuery += "	   ,CODAUT"
    _oSQL:_sQuery += "	   ,VALOR_SE1"
    _oSQL:_sQuery += "	   ,VALOR_SE5"
    _oSQL:_sQuery += "	   ,VALOR_SE1 - VALOR_SE5 AS DIFERENCA"
    _oSQL:_sQuery += "	FROM C"
    _oSQL:_sQuery += "	WHERE VALOR_SE1 - VALOR_SE5 <> 0 "
    _oSQL:_sQuery += "  ORDER BY FILIAL, NUMERO, PREFIXO, PARCELA "
    _aDados := _oSQL:Qry2Array ()

    oSection1:Init()

    If Len(_aDados) > 0

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

            oSection1:PrintLine()
        Next
    Else
        oReport:PrintText(" Não existe registros com diferenças de baixas!",,100)
    EndIf

    oReport:ThinLine()
    oReport:PrintText(" ",,100)
    oReport:PrintText(" DIFERENÇAS LISTADAS DESDE DATA: " + str(mv_par03),,100)
    oSection1:Finish()
Return
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT             TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Filial de        ", "C", 2, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Filial ate       ", "C", 2, 0,  "",   "   ", {},                        		 ""})
    aadd (_aRegsPerg, {03, "Data inicial     ", "D", 8, 0,  "",   "   ", {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
