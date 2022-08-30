//  Programa...: ZD0RIMP
//  Autor......: Cláudia Lionço
//  Data.......: 24/08/2022
//  Descricao..: Relatório Importações pagar-me
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório Importações pagar-me
// #PalavasChave      #cartao #titulos #pagar.me
// #TabelasPrincipais #SE1 
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User Function ZD0RIMP( dDataIni, dDataFin)
	Private oReport
	Private cPerg := "ZD0RIMP"
	
	//_ValidPerg()
	//Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()

Return
//
// ---------------------------------------------------------------------------
// Cabeçalho da rotina
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	Local oBreak1

	oReport := TReport():New("ZD0RIMP","Importação de pagamentos Pagar.me",cPerg,{|oReport| PrintReport(oReport)},"Importação de pagamentos Pagar.me")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"ID Recebivel"  ,       					,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"ID Transacao"  ,       					,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Parcela"	    ,                        	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Vlr.Parcela"	, "@E 999,999,999.99"   	,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Vlr.Taxa"		, "@E 999,999,999.99"   	,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Vlr.Liquido"	, "@E 999,999,999.99"   	,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Dt.Pgto"		,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA9", 	"" ,"Método Pgto"	,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)

    oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA1"),"Total por filial")
    TRFunction():New(oSection1:Cell("COLUNA5")	,,"SUM"	,oBreak1,"Total parcela "   , "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA6")	,,"SUM"	,oBreak1,"Total taxa "      , "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA7")	,,"SUM"	,oBreak1,"Total liquido "   , "@E 99,999,999.99", NIL, .F., .T.)
		
	
Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local _x        := 0

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   ZD0_FILIAL "
    _oSQL:_sQuery += "    ,ZD0_RID "
    _oSQL:_sQuery += "    ,ZD0_TID "
    _oSQL:_sQuery += "    ,ZD0_PARCEL "
    _oSQL:_sQuery += "    ,ZD0_VLRPAR "
    _oSQL:_sQuery += "    ,ZD0_TAXTOT "
    _oSQL:_sQuery += "    ,ZD0_VLRLIQ "
    _oSQL:_sQuery += "    ,ZD0_DTAPGT "
    _oSQL:_sQuery += "    ,ZD0_PGTMET "
    _oSQL:_sQuery += " FROM " + RetSQLName ("ZD0")  
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''
    _oSQL:_sQuery += " AND ZD0_FILIAL = '"+ xFilial('ZD0')+"'"
    _oSQL:_sQuery += " AND ZD0_DTAPGT BETWEEN '"+ dtos(dDataIni) +"' AND '"+ dtos(dDataFin) +"'"
    _aZD0 := aclone (_oSQL:Qry2Array ())

	For _x := 1 to Len(_aZD0)

		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aZD0[_x, 1] }) 
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aZD0[_x, 2] }) 
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aZD0[_x, 3] }) 
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aZD0[_x, 4] }) 
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aZD0[_x, 5] }) 
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aZD0[_x, 6] }) 
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aZD0[_x, 7] }) 
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aZD0[_x, 8] }) 
        oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aZD0[_x, 9] }) 
		
		oSection1:PrintLine()
	Next

	oSection1:Finish()
Return
