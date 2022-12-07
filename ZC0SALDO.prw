//  Programa...: ZC0SALDO
//  Autor......: Cláudia Lionço
//  Data.......: 12/09/2022
//  Descricao..: Relatório de Saldo de Rapel
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de Saldo de Rapel
// #PalavasChave      #rapel 
// #TabelasPrincipais #ZC0 
// #Modulos 		  #FAT 
//
// Historico de alteracoes:
// 07/12/2022 - Claudia - Retirado quebras/somatorios por filial. GLPI 12885 
//
// --------------------------------------------------------------------------------------
#include 'protheus.ch'

User Function ZC0SALDO()
	Private oReport
	Private cPerg := "ZC0SALDO"
	
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

	oReport := TReport():New("ZC0SALDO","Saldo de Rapel",cPerg,{|oReport| PrintReport(oReport)},"Saldo de Rapel")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"			,	    					, 10,/*lPixel*/,{||     },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Rede"				,       					, 15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Nome"				,       					, 60,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Vlr.Rapel"			, "@E 999,999,999.99"   	, 20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

	oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA1"),"Total")
   
    TRFunction():New(oSection1:Cell("COLUNA4")  ,,"SUM" ,oBreak1,""          , "@E 99,999,999.99", NIL, .F., .T.)

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
    _oSQL:_sQuery += "     '' "
    _oSQL:_sQuery += "    ,ZC0.ZC0_CODRED "
    _oSQL:_sQuery += "    ,SA1.A1_NOME "
    _oSQL:_sQuery += "    ,ROUND(SUM(CASE "
    _oSQL:_sQuery += " 		WHEN ZX5_55DC = 'D' THEN ZC0_RAPEL * -1 "
    _oSQL:_sQuery += " 		ELSE ZC0_RAPEL "
    _oSQL:_sQuery += " 	END), 2) AS VLRRAPEL "
    _oSQL:_sQuery += " FROM " + RetSQLName ("ZC0") + " ZC0 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
    _oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SA1.A1_COD  = ZC0_CODRED "
    _oSQL:_sQuery += " 		AND SA1.A1_LOJA = ZC0_LOJRED "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("ZX5") + " ZX5 "
    _oSQL:_sQuery += " 	ON ZX5.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND ZX5.ZX5_TABELA = '55' "
    _oSQL:_sQuery += " 		AND ZX5.ZX5_CHAVE  = ZC0_TM "
    _oSQL:_sQuery += " WHERE ZC0.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND ZC0_RAPEL > 0 "
    _oSQL:_sQuery += " GROUP BY ZC0.ZC0_CODRED "
    _oSQL:_sQuery += " 		   ,SA1.A1_NOME "
    _oSQL:_sQuery += " ORDER BY ZC0.ZC0_CODRED, SA1.A1_NOME "
	_aZC0 := aclone (_oSQL:Qry2Array ())

	For _x:=1 to Len(_aZC0)

		//oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aZC0[_x, 1] }) 		
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aZC0[_x, 2] }) 		
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aZC0[_x, 3] }) 		
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aZC0[_x, 4] }) 		
		
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
    aadd (_aRegsPerg, {01, "Ordenação        ", "N", 1, 0,  "",   "   "     , {"Rede","Nome"},                   ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
