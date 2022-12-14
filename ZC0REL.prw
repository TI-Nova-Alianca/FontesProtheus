//  Programa...: ZC0REL
//  Autor......: Cláudia Lionço
//  Data.......: 30/05/2022
//  Descricao..: Relatório de Rapel
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de Rapel
// #PalavasChave      #rapel 
// #TabelasPrincipais #ZC0 
// #Modulos 		  #FAT 
//
// Historico de alteracoes:
// 14/06/2022 - Sandra - Incluso total, incluso parametro 12, quebra por rede. GLPI 12146.
// 07/12/2022 - Claudia - Retirado quebras/somatorios por filial.  GLPI 12885
//
// --------------------------------------------------------------------------------------
#include 'protheus.ch'

User Function ZC0REL()
	Private oReport
	Private cPerg := "ZC0REL"
	
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
	//Local oBreak1

	oReport := TReport():New("ZC0REL","Relatório de Rapel",cPerg,{|oReport| PrintReport(oReport)},"Relatório de Rapel")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Rede"				,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Nome"				,       					,50,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Cliente"			,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Tp.Movimento"  	,       					,50,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Cred/Deb"			,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Data"  			,       					,12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Histórico"  		,       					,50,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Documento"  		,		       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Cod.Prod."  		,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA10", 	"" ,"Vlr.Rapel"			, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA11", 	"" ,"Status"  			,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)

	oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA1"),"Total")
   
    TRFunction():New(oSection1:Cell("COLUNA10")  ,,"SUM" ,oBreak1,""          , "@E 99,999,999.99", NIL, .F., .T.)

Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1  := oReport:Section(1)
    Local _x         := 0

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)
	
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   ZC0_CODRED + '/' + ZC0_LOJRED AS REDE "
	_oSQL:_sQuery += "    ,A1_NOME AS NOME "
	_oSQL:_sQuery += "    ,ZC0_CODCLI + '/' + ZC0_LOJCLI AS CLIENTE "
	_oSQL:_sQuery += "    ,ZC0_TM + ' - ' + ZX5.ZX5_55DESC AS TIPO_MOVIMENTO "
	_oSQL:_sQuery += "    ,CASE "
	_oSQL:_sQuery += " 			WHEN ZX5_55DC = 'C' THEN 'Credito' "
	_oSQL:_sQuery += " 			ELSE 'Debito' "
	_oSQL:_sQuery += " 	   END AS CRED_DEB "
	_oSQL:_sQuery += "    ,ZC0_DATA AS EMISSAO "
	_oSQL:_sQuery += "    ,ZC0_HISTOR AS HISTORICO "
	_oSQL:_sQuery += "    ,ZC0_DOC + '/' + ZC0_SERIE + ' ' + ZC0_PARCEL AS DOCUMENTO "
	_oSQL:_sQuery += "    ,ZC0_PROD AS PRODUTO "
	_oSQL:_sQuery += "    ,ZC0_RAPEL AS VLRRAPEL "
	_oSQL:_sQuery += "    ,CASE "
	_oSQL:_sQuery += " 			WHEN ZC0_STATUS = 'A' THEN 'Aberto' "
	_oSQL:_sQuery += " 			ELSE 'Fechado' "
	_oSQL:_sQuery += " 	   END AS STATUS "
	_oSQL:_sQuery += " 	  ,ZX5_55DC AS DC "
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZC0") + " ZC0 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = ZC0_CODRED "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = ZC0_LOJRED "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("ZX5") + " ZX5 "
	_oSQL:_sQuery += " 	ON ZX5.D_E_L_E_T_ = '' " 
	_oSQL:_sQuery += " 	    AND ZX5.ZX5_TABELA = '55' "
	_oSQL:_sQuery += " 		AND ZX5.ZX5_CHAVE = ZC0_TM "
	_oSQL:_sQuery += " WHERE ZC0.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND ZC0.ZC0_CODRED BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"' "
	_oSQL:_sQuery += " AND ZC0.ZC0_CODCLI BETWEEN '"+ mv_par05 +"' AND '"+ mv_par06 +"' "
	If !empty(mv_par01)
		_oSQL:_sQuery += " AND ZC0.ZC0_DATA   BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"' "
	EndIf
	If !empty(mv_par07)
		_oSQL:_sQuery += " AND ZC0.ZC0_TM    = '"+ mv_par07 +"' "
	EndIf
	If !empty(mv_par08)
		_oSQL:_sQuery += " AND ZC0.ZC0_DOC   = '"+ mv_par08 +"' "
		_oSQL:_sQuery += " AND ZC0.ZC0_SERIE = '"+ mv_par09 +"' "
	EndIf
	
	if mv_par10 == 1
		_oSQL:_sQuery += " ORDER BY REDE, CLIENTE, EMISSAO "
	else
		_oSQL:_sQuery += " ORDER BY NOME, EMISSAO "
	endif
	
	    _aZC0 := aclone (_oSQL:Qry2Array ())

	For _x:=1 to Len(_aZC0)
		If _aZC0[_x, 12] == 'C'
			_nVlrRapel := _aZC0[_x,10]  
		else
			_nVlrRapel := _aZC0[_x,10] * -1
		EndIf

		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aZC0[_x, 1] }) 		// rede
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aZC0[_x, 2] }) 		// nome
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aZC0[_x, 3] }) 		// cliente
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aZC0[_x, 4] }) 		// tp movimento
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aZC0[_x, 5] }) 		// debito/credito
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| stod(_aZC0[_x, 6]) }) 	// data
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aZC0[_x, 7] }) 		// historico
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aZC0[_x, 8] }) 		// documento
		oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aZC0[_x, 9] }) 		// cod.prod
		oSection1:Cell("COLUNA10")	:SetBlock   ({|| _nVlrRapel   }) 		// rapel
		oSection1:Cell("COLUNA11")	:SetBlock   ({|| _aZC0[_x,11] }) 		// status
		
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
    aadd (_aRegsPerg, {01, "Data de          ", "D", 8, 0,  "",   "   "     , {},                         		 ""})
    aadd (_aRegsPerg, {02, "Data até         ", "D", 8, 0,  "",   "   "     , {},                         		 ""})
    aadd (_aRegsPerg, {03, "Rede de          ", "C", 6, 0,  "",   "SA1RED"  , {},                         		 ""})
    aadd (_aRegsPerg, {04, "Rede até         ", "C", 6, 0,  "",   "SA1RED"  , {},                         		 ""})
    aadd (_aRegsPerg, {05, "Cliente de       ", "C", 6, 0,  "",   "SA1"     , {},                         		 ""})
    aadd (_aRegsPerg, {06, "Cliente até      ", "C", 6, 0,  "",   "SA1"     , {},                         		 ""})
    aadd (_aRegsPerg, {07, "Tp.Movimento     ", "C", 2, 0,  "",   "   "     , {},                         		 ""})
	aadd (_aRegsPerg, {08, "Documento        ", "C", 9, 0,  "",   "   "     , {},                         		 ""})
	aadd (_aRegsPerg, {09, "Serie            ", "C", 2, 0,  "",   "   "     , {},                         		 ""})
	aadd (_aRegsPerg, {10, "Ordenação        ", "N", 1, 0,  "",   "   "     , {"Rede","Nome"},                   ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
