// Programa...: ZDOPXT
// Autor......: Claudia Lionço
// Data.......: 01/09/2022
// Descricao..: Consulta Pagar.me X titulos
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #consulta
// #Descricao         #Consulta Pagar.me X titulos
// #PalavasChave      #e-commerce #pagar.me 
// #TabelasPrincipais #SC5 #SE1 #SF2
// #Modulos           #FAT
//
//  Historico de alterações
// 06/09/2022 - Claudia - Retirada a coluna de saldos de titulos. 
// 06/09/2023 - Claudia - Incluida impressão de taxas. GLPI: 14150
// 04/07/2024 - Claudia - Subtraido um dia da data inicial para busca dos recebimentos. GLPI:15685
//
// ----------------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User Function ZD0PXT( dDataIni, dDataFin)
	Private oReport
	Private cPerg := "ZD0PXT"
	
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
	Local oBreak1

	oReport := TReport():New("ZD0PXT","Pagar.me x Titulos",cPerg,{|oReport| PrintReport(oReport)},"Pagar.me x Titulos")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1"	, 	"" ,"Filial"		,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2"	, 	"" ,"Tipo Reg."     ,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3"	, 	"" ,"ID Recebivel"  ,       					,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4"	, 	"" ,"ID Transacao"  ,       					,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5"	, 	"" ,"Parcela"       ,       					,06,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6"	, 	"" ,"Dt.Extrato"    ,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7"	, 	"" ,"Vlr.Parcela"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8"	, 	"" ,"Vlr.Taxa"		, "@E 999,999,999.99"   	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9"	, 	"" ,"Vlr.Liquido"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10"	, 	"" ,"Título"    	,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA11"	, 	"" ,"Cliente"    	,       					,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA12"	, 	"" ,"Titulo RA"    	,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)

    oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA1"),"Total por filial")
    TRFunction():New(oSection1:Cell("COLUNA7")	,,"SUM"	,oBreak1,"Total parcela "   , "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA8")	,,"SUM"	,oBreak1,"Total taxa "      , "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA9")	,,"SUM"	,oBreak1,"Total liquido "   , "@E 99,999,999.99", NIL, .F., .T.)
	
Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local _x        := 0
	Local _y        := 0
	Local _sData1   := DTOS(date()) +' 00:00:00'
	Local _sData2   := DTOS(date()) +' 23:59:59'

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)

	_nLinha :=  oReport:Row()
	oReport:PrintText("Período de " +dtoc(mv_par03)+ " até " + dtoc(mv_par04) ,_nLinha, 100)
	oReport:SkipLine(1) 

	_oSQL := ClsSQL():New ()  
	_oSQL:_sQuery := "" 		
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	ZD0_DTAEXT + ' ' + ZD0_HOREXT "
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZD0")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND ZD0_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	_oSQL:_sQuery += " AND ZD0_DTAEXT BETWEEN '"+ dtos(DaySub(mv_par03, 1)) +"' AND '"+ dtos(mv_par04) +"' "
	_oSQL:_sQuery += " AND ZD0_TIPO = '2' "
	_oSQL:_sQuery += " ORDER BY ZD0_DTAEXT "
	_aDatas := _oSQL:Qry2Array ()

	For _y := 1 to Len(_aDatas)		
		If _y == 1
			_sData1 := _aDatas[_y,1]
		EndIf
		If _y == 2
			_sData2 := _aDatas[_y,1]
		EndIf
	Next

	_oSQL := ClsSQL():New ()  
	_oSQL:_sQuery := "" 		
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += "     ZD0_FILIAL "
	_oSQL:_sQuery += "    ,CASE "
	_oSQL:_sQuery += " 		WHEN ZD0_TIPO = '1' THEN 'Transação' "
	_oSQL:_sQuery += " 		WHEN ZD0_TIPO = '2' THEN 'Transferencia' "
	_oSQL:_sQuery += " 		WHEN ZD0_TIPO = '3' THEN 'Tarifa' "
	_oSQL:_sQuery += " 	END AS TIPO "
	_oSQL:_sQuery += "    ,ZD0_RID "
	_oSQL:_sQuery += "    ,ZD0_TID "
	_oSQL:_sQuery += "    ,ZD0_PARCEL "
	_oSQL:_sQuery += "    ,ZD0_DTAEXT "
	_oSQL:_sQuery += "    ,ZD0_VLRPAR "
	_oSQL:_sQuery += "    ,ZD0_TAXTOT "
	_oSQL:_sQuery += "    ,ZD0_VLRLIQ "
	_oSQL:_sQuery += "    ,SE1.E1_NUM + '/' + SE1.E1_PREFIXO + ' ' + SE1.E1_PARCELA AS TITULO "
	_oSQL:_sQuery += "    ,SE1.E1_CLIENTE + ' - ' + SA1.A1_NOME AS CLIENTE "
	_oSQL:_sQuery += "    ,SE1RA.E1_NUM + '/' + SE1RA.E1_PREFIXO + ' ' + SE1RA.E1_PARCELA AS TITULO_RA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZD0") + " ZD0 "
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " 	ON SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SE1.E1_FILIAL  = ZD0.ZD0_FILIAL "
	_oSQL:_sQuery += " 		AND SE1.E1_VAIDT   = ZD0.ZD0_TID "
	_oSQL:_sQuery += " 		AND SE1.E1_PARCELA = ZD0.ZD0_PARCEL "
	_oSQL:_sQuery += " 		AND SE1.E1_TIPO   <> 'RA' "
	_oSQL:_sQuery += " 		AND SE1.E1_PREFIXO <> 'PGM' "
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SE1") + " SE1RA "
	_oSQL:_sQuery += " 	ON SE1RA.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SE1RA.E1_FILIAL  = ZD0.ZD0_FILIAL "
	_oSQL:_sQuery += " 		AND SE1RA.E1_VAIDT   = ZD0.ZD0_TID "
	_oSQL:_sQuery += " 		AND SE1RA.E1_PARCELA = ZD0.ZD0_PARCEL "
	_oSQL:_sQuery += " 		AND SE1RA.E1_TIPO    = 'RA' "	
	_oSQL:_sQuery += " 		AND SE1RA.E1_PREFIXO = 'PGM' "	
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_  = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND A1_LOJA    = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE ZD0.D_E_L_E_T_ = ''
	_oSQL:_sQuery += " AND ZD0_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	_oSQL:_sQuery += " AND ZD0_DTAEXT + ' ' + ZD0_HOREXT BETWEEN '"+ _sData1 +"' AND '"+ _sData2 +"' "
	_oSQL:_sQuery += " AND ZD0_TIPO <> '2' "
	_oSQL:_sQuery += " ORDER BY ZD0_DTAEXT "
	_oSQL:Log ()
	_aDados := _oSQL:Qry2Array ()

	For _x := 1 to Len(_aDados)
		_sTitulo  := _aDados[_x,10]
		_sCliente := _aDados[_x,11]

		If empty(_sTitulo) // se nao encontrou o titulo, verifica se é a parcela A, já que o pagar.me inclui como 1 parcela em compra de cartões
			_oSQL := ClsSQL():New ()  
			_oSQL:_sQuery := "" 		
			_oSQL:_sQuery += " 	SELECT "
			_oSQL:_sQuery += " 		 SE1.E1_NUM "
			_oSQL:_sQuery += " 		,SE1.E1_PREFIXO "
			_oSQL:_sQuery += " 		,SE1.E1_PARCELA "
			_oSQL:_sQuery += " 		,SE1.E1_CLIENTE "
			_oSQL:_sQuery += " 		,SA1.A1_NOME "
			_oSQL:_sQuery += " 	FROM " + RetSQLName ("SE1") + " SE1 "
			_oSQL:_sQuery += " 	LEFT JOIN " + RetSQLName ("SA1") + " SA1 "
			_oSQL:_sQuery += " 		ON SA1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SA1.A1_COD = SE1.E1_CLIENTE "
			_oSQL:_sQuery += " 			AND SA1.A1_LOJA = SE1.E1_LOJA "
			_oSQL:_sQuery += " 	WHERE SE1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 	AND SE1.E1_FILIAL   = '" + _aDados[_x, 1] +"' "
			_oSQL:_sQuery += " 	AND SE1.E1_VAIDT    = '" + _aDados[_x, 4] +"' "
			_oSQL:_sQuery += " 	AND SE1.E1_PARCELA  = '' "
			_oSQL:_sQuery += " 	AND SE1.E1_PREFIXO  <> 'PGM' "
			_aTit := _oSQL:Qry2Array ()

			For _y:=1 to Len(_aTit)
				_sTitulo  := _aTit[_y, 1] + "/" + _aTit[_y, 2] + " " + _aTit[_y, 3]
				_sCliente := _aTit[_y, 4] + " - " + _aTit[_y, 5]
			Next
		EndIf

		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[_x, 1] }) 
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aDados[_x, 2] }) 
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aDados[_x, 3] }) 
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aDados[_x, 4] }) 
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aDados[_x, 5] }) 
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aDados[_x, 6] }) 
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aDados[_x, 7] }) 
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aDados[_x, 8] }) 
		oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aDados[_x, 9] }) 
        oSection1:Cell("COLUNA10")	:SetBlock   ({|| _sTitulo       }) 
		oSection1:Cell("COLUNA11")	:SetBlock   ({|| _sCliente      }) 
		oSection1:Cell("COLUNA12")	:SetBlock   ({|| _aDados[_x,12] }) 
		
		oSection1:PrintLine()
	Next

	oSection1:Finish()
Return
// 
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT           TIPO TAM DEC VALID F3     Opcoes                    Help
	aadd (_aRegsPerg, {01, "Filial inicial", "C", 02, 0,  "",   "   ", {},                       ""})
	aadd (_aRegsPerg, {02, "Filial final"  , "C", 02, 0,  "",   "   ", {},                       ""})
    aadd (_aRegsPerg, {03, "Data inicial"  , "D", 08, 0,  "",   "   ", {},                       ""})
	aadd (_aRegsPerg, {04, "Data final"    , "D", 08, 0,  "",   "   ", {},                       ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
