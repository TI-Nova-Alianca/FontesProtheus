//  Programa...: ZB1RTIT
//  Autor......: Cláudia Lionço
//  Data.......: 23/10/2020
//  Cliente....: Alianca
//  Descricao..: Relatório de titulos de cartão
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de titulos de cartão
// #PalavasChave      #cartao #titulos #
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

User Function ZB1RTIT()
	Private oReport
	Private cPerg := "ZB1RTIT"
	
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

    oReport := TReport():New("ZB1RTIT","Títulos de cartões",cPerg,{|oReport| PrintReport(oReport)},"Títulos de cartões")
	
	// DEVOLUÇÕES
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    				,08,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Título"		,       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Prefixo"		,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Parc."			,						,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA5", 	"" ,"Tipo"			,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Cliente"		,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Descrição"		,       				,35,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA8", 	"" ,"Dt.Emissão"	,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Autorização"	,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"Valor"		    , "@E 999,999,999.99"   ,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)	
    Local _aDados   := {}
    Local i         := 0

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += "	SELECT"
    _oSQL:_sQuery += "		E1_FILIAL"
    _oSQL:_sQuery += "	   ,E1_NUM"
    _oSQL:_sQuery += "	   ,E1_PREFIXO"
    _oSQL:_sQuery += "	   ,E1_PARCELA"
    _oSQL:_sQuery += "	   ,E1_TIPO"
    _oSQL:_sQuery += "	   ,E1_CLIENTE"
    _oSQL:_sQuery += "	   ,E1_NOMCLI"
    _oSQL:_sQuery += "	   ,E1_EMISSAO"
    _oSQL:_sQuery += "	   ,E1_NSUTEF"
    _oSQL:_sQuery += "	   ,E1_VALOR"
    _oSQL:_sQuery += "	FROM " + RetSQLName ("SE1") 
    _oSQL:_sQuery += "	WHERE D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "	AND E1_FILIAL BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
    _oSQL:_sQuery += "	AND E1_EMISSAO BETWEEN '" + DTOS(mv_par03) + "' and '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += "	AND E1_TIPO IN ('CC', 'CD')"
    _oSQL:_sQuery += "	ORDER BY E1_FILIAL, E1_EMISSAO"
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

        oSection1:PrintLine()
    Next

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
    aadd (_aRegsPerg, {03, "Data de          ", "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {04, "Data ate         ", "D", 8, 0,  "",   "   ", {},                        		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
