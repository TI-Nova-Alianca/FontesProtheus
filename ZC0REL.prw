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
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"			,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Rede"				,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Nome"				,       					,50,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Cliente"			,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Tp.Movimento"  	,       					,50,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Cred/Deb"			,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Data"  			,       					,12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Histórico"  		,       					,50,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Documento"  		,		       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA10", 	"" ,"Cod.Prod."  		,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA11", 	"" ,"Vlr.Rapel"			, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA12", 	"" ,"Status"  			,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)

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
	_oSQL:_sQuery += " 	   ZC0_FILIAL AS FILIAL "
	_oSQL:_sQuery += "    ,ZC0_CODRED + '/' + ZC0_LOJRED AS REDE "
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
	_oSQL:_sQuery += " AND ZC0.ZC0_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	_oSQL:_sQuery += " AND ZC0.ZC0_DATA   BETWEEN '"+ dtos(mv_par03) +"' AND '"+ dtos(mv_par04) +"' "
	_oSQL:_sQuery += " AND ZC0.ZC0_CODRED BETWEEN '"+ mv_par05 +"' AND '"+ mv_par06 +"' "
	_oSQL:_sQuery += " AND ZC0.ZC0_CODCLI BETWEEN '"+ mv_par07 +"' AND '"+ mv_par08 +"' "
	If !empty(mv_par09)
		_oSQL:_sQuery += " AND ZC0.ZC0_TM    = '"+ mv_par09 +"' "
	EndIf
	If !empty(mv_par10)
		_oSQL:_sQuery += " AND ZC0.ZC0_DOC   = '"+ mv_par10 +"' "
		_oSQL:_sQuery += " AND ZC0.ZC0_SERIE = '"+ mv_par11 +"' "
	EndIf
	_oSQL:_sQuery += " ORDER BY FILIAL, EMISSAO, REDE, CLIENTE "
    _aZC0 := aclone (_oSQL:Qry2Array ())

	For _x:=1 to Len(_aZC0)
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aZC0[_x, 1] }) 		// filial
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aZC0[_x, 2] }) 		// rede
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aZC0[_x, 3] }) 		// nome
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aZC0[_x, 4] }) 		// cliente
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aZC0[_x, 5] }) 		// tp movimento
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aZC0[_x, 6] }) 		// debito/credito
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| stod(_aZC0[_x, 7]) }) 	// data
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aZC0[_x, 8] }) 		// historico
		oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aZC0[_x, 9] }) 		// documento
		oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aZC0[_x,10] }) 		// cod.prod
		oSection1:Cell("COLUNA11")	:SetBlock   ({|| _aZC0[_x,11] }) 		// rapel
		oSection1:Cell("COLUNA12")	:SetBlock   ({|| _aZC0[_x,12] }) 		// status
		
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
    aadd (_aRegsPerg, {01, "Filial de        ", "C", 2, 0,  "",   "   "     , {},                         		 ""})
	aadd (_aRegsPerg, {02, "Filial até       ", "C", 2, 0,  "",   "   "     , {},                         		 ""})
    aadd (_aRegsPerg, {03, "Data de          ", "D", 8, 0,  "",   "   "     , {},                         		 ""})
    aadd (_aRegsPerg, {04, "Data até         ", "D", 8, 0,  "",   "   "     , {},                         		 ""})
    aadd (_aRegsPerg, {05, "Rede de          ", "C", 6, 0,  "",   "SA1RED"  , {},                         		 ""})
    aadd (_aRegsPerg, {06, "Rede até         ", "C", 6, 0,  "",   "SA1RED"  , {},                         		 ""})
    aadd (_aRegsPerg, {07, "Cliente de       ", "C", 6, 0,  "",   "SA1"     , {},                         		 ""})
    aadd (_aRegsPerg, {08, "Cliente até      ", "C", 6, 0,  "",   "SA1"     , {},                         		 ""})
    aadd (_aRegsPerg, {09, "Tp.Movimento     ", "C", 2, 0,  "",   "   "     , {},                         		 ""})
	aadd (_aRegsPerg, {10, "Documento        ", "C", 9, 0,  "",   "   "     , {},                         		 ""})
	aadd (_aRegsPerg, {11, "Serie            ", "C", 2, 0,  "",   "   "     , {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
