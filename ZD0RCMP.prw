//  Programa...: ZD0RCMP
//  Autor......: Cláudia Lionço
//  Data.......: 24/08/2022
//  Descricao..: Relatório de baixas pagar-me
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

User Function ZD0RCMP(dDataIni, dDataFin)
	Private oReport
	Private cPerg := "ZD0RCMP"
	
    Private dDtIni := dDataIni
    Private dDtFin := dDataFin

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

	oReport := TReport():New("ZD0RCMP","Baixas de pagamentos Pagar.me",cPerg,{|oReport| PrintReport(oReport)},"Baixas de pagamentos Pagar.me")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"ID Recebivel"  ,       					,16,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"ID Transacao"  ,       					,16,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Parcela"	    ,                        	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA5", 	"" ,"Vlr.Liquido"	, "@E 999,999,999.99"   	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA6", 	"" ,"Título  "	    ,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA7", 	"" ,"Tipo  "	    ,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA8", 	"" ,"Saldo"	        , "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA9", 	"" ,"Título RA  "	,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"Tipo  "	    ,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA11", 	"" ,"Saldo RA"	    , "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA12", 	"" ,"Status baixa"	,       					,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)

    oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA1"),"Total por filial")
    TRFunction():New(oSection1:Cell("COLUNA5")	,,"SUM"	,oBreak1,"Total vlr.Liquido", "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA8")	,,"SUM"	,oBreak1,"Total saldo tit." , "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA11")	,,"SUM"	,oBreak1,"Total saldo RA"   , "@E 99,999,999.99", NIL, .F., .T.)
		
Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local _x        := 0
    Local _y        := 0

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   ZD0_FILIAL "
    _oSQL:_sQuery += "    ,ZD0_RID "
    _oSQL:_sQuery += "    ,ZD0_TID "
    _oSQL:_sQuery += "    ,ZD0_PARCEL "
    _oSQL:_sQuery += "    ,ZD0.ZD0_VLRLIQ "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		WHEN SE1TIT.E1_NUM + '/' + SE1TIT.E1_PREFIXO + ' ' + SE1TIT.E1_PARCELA <> '' THEN SE1TIT.E1_NUM + '/' + SE1TIT.E1_PREFIXO + ' ' + SE1TIT.E1_PARCELA "
    _oSQL:_sQuery += " 		ELSE '' "
    _oSQL:_sQuery += " 	END AS TITULO "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		WHEN SE1TIT.E1_TIPO <> '' THEN SE1TIT.E1_TIPO "
    _oSQL:_sQuery += " 		ELSE '' "
    _oSQL:_sQuery += " 	END AS TIT_TIPO "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		WHEN SE1TIT.E1_SALDO <> '' THEN SE1TIT.E1_SALDO "
    _oSQL:_sQuery += " 		ELSE '' "
    _oSQL:_sQuery += " 	END AS TIT_SALDO "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		WHEN SE1RA.E1_NUM + '/' + SE1RA.E1_PREFIXO + ' ' + SE1RA.E1_PARCELA <> '' THEN SE1RA.E1_NUM + '/' + SE1RA.E1_PREFIXO + ' ' + SE1RA.E1_PARCELA "
    _oSQL:_sQuery += " 		ELSE '' "
    _oSQL:_sQuery += " 	END AS RA_TITULO "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		WHEN SE1RA.E1_TIPO <> '' THEN SE1RA.E1_TIPO "
    _oSQL:_sQuery += " 		ELSE '' "
    _oSQL:_sQuery += " 	END AS RA_TIPO "
    _oSQL:_sQuery += "    ,ISNULL(SE1RA.E1_SALDO, 0) AS RA_SALDO "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		WHEN ZD0.ZD0_STABAI = 'B' THEN 'Baixado' "
    _oSQL:_sQuery += " 		WHEN SE1TIT.E1_SALDO = 0 AND "
    _oSQL:_sQuery += " 			SE1RA.E1_SALDO = 0 THEN 'Titulos baixados manualmente' "
    _oSQL:_sQuery += " 		WHEN SE1TIT.E1_SALDO = 0 AND "
    _oSQL:_sQuery += " 			SE1RA.E1_SALDO > 0 THEN 'Titulo baixado/RA aberto' "
    _oSQL:_sQuery += " 		WHEN SE1TIT.E1_SALDO <> 0 AND "
    _oSQL:_sQuery += " 			SE1RA.E1_SALDO = 0 THEN 'RA baixado/Titulo aberto' "
    _oSQL:_sQuery += " 		ELSE 'Aberto' "
    _oSQL:_sQuery += " 	END "
    _oSQL:_sQuery += " FROM " + RetSQLName ("ZD0") + " ZD0 "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SE1") + " SE1TIT "
    _oSQL:_sQuery += " 	ON SE1TIT.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SE1TIT.E1_FILIAL   = ZD0.ZD0_FILIAL "
    _oSQL:_sQuery += " 		AND SE1TIT.E1_PARCELA  = ZD0.ZD0_PARCEL "
    _oSQL:_sQuery += " 		AND SE1TIT.E1_VAIDT    = ZD0_TID "
    _oSQL:_sQuery += " 		AND SE1TIT.E1_PREFIXO <> 'PGM' "
    _oSQL:_sQuery += " 		AND SE1TIT.E1_TIPO    <> 'RA' "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SE1") + " SE1RA "
    _oSQL:_sQuery += " 	ON SE1RA.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SE1RA.E1_FILIAL  = ZD0.ZD0_FILIAL "
    _oSQL:_sQuery += " 		AND SE1RA.E1_PARCELA = ZD0.ZD0_PARCEL "
    _oSQL:_sQuery += " 		AND SE1RA.E1_VAIDT   = ZD0_TID "
    _oSQL:_sQuery += " 		AND SE1RA.E1_PREFIXO = 'PGM' "
    _oSQL:_sQuery += " 		AND SE1RA.E1_TIPO    = 'RA' "
    _oSQL:_sQuery += " WHERE ZD0.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND ZD0_FILIAL = '"+ xFilial('ZD0')+"'"
    _oSQL:_sQuery += " AND ZD0_DTAPGT BETWEEN '"+ dtos(dDtIni) +"' AND '"+ dtos(dDtFin) +"'"
    _oSQL:_sQuery += " ORDER BY ZD0_TID
    _oSQL:Log ()
    _aZD0 := aclone (_oSQL:Qry2Array ())

	For _x := 1 to Len(_aZD0)
        _sTitulo  := _aZD0[_x,6]
        _sTipo    := _aZD0[_x,7]
        _sSaldo   := _aZD0[_x,8]

		If empty(_sTitulo) // se nao encontrou o titulo, verifica se é a parcela A, já que o pagar.me inclui como 1 parcela em compra de cartões
			_oSQL := ClsSQL():New ()  
			_oSQL:_sQuery := "" 		
			_oSQL:_sQuery += " 	SELECT "
			_oSQL:_sQuery += " 		 SE1.E1_NUM "
			_oSQL:_sQuery += " 		,SE1.E1_PREFIXO "
			_oSQL:_sQuery += " 		,SE1.E1_PARCELA "
            _oSQL:_sQuery += " 		,SE1.E1_TIPO "
            _oSQL:_sQuery += " 		,SE1.E1_SALDO "
			_oSQL:_sQuery += " 	FROM " + RetSQLName ("SE1") + " SE1 "
			_oSQL:_sQuery += " 	WHERE SE1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 	AND SE1.E1_FILIAL   = '" + _aZD0[_x, 1] +"' "
			_oSQL:_sQuery += " 	AND SE1.E1_VAIDT    = '" + _aZD0[_x, 3] +"' "
			_oSQL:_sQuery += " 	AND SE1.E1_PARCELA  = '' "
			_oSQL:_sQuery += " 	AND SE1.E1_PREFIXO  <> 'PGM' "
			_aTit := _oSQL:Qry2Array ()

			For _y:=1 to Len(_aTit)
				_sTitulo := _aTit[_y, 1] + "/" + _aTit[_y, 2] + " " + _aTit[_y, 3]
                _sTipo   := _aTit[_y, 4] 
                _sSaldo  := _aTit[_y, 5] 
			Next
		EndIf

		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aZD0[_x,  1] }) 
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aZD0[_x,  2] }) 
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aZD0[_x,  3] }) 
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aZD0[_x,  4] }) 
        oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aZD0[_x,  5] }) 
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _sTitulo      }) 
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| _sTipo        }) 
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| _sSaldo       }) 
		oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aZD0[_x,  9] }) 
        oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aZD0[_x, 10] }) 
        oSection1:Cell("COLUNA11")	:SetBlock   ({|| _aZD0[_x, 11] }) 
        oSection1:Cell("COLUNA12")	:SetBlock   ({|| _aZD0[_x, 12] }) 
		
		oSection1:PrintLine()
	Next

	oSection1:Finish()
Return
