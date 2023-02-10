//  Programa...: ZC0VALID
//  Autor......: Cláudia Lionço
//  Data.......: 09/02/2023
//  Descricao..: Validação de Rapel
//
// #TipoDePrograma    #relatorio
// #Descricao         #Validação de Rapel
// #PalavasChave      #rapel 
// #TabelasPrincipais #ZC0 
// #Modulos 		  #FAT 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------------------
#include 'protheus.ch'

User Function ZC0VALID()
	Private oReport
	Private cPerg := "ZC0VALID"
	
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
	Local oSection2:= Nil

	oReport := TReport():New("ZC0VALID","Validação de Rapel",cPerg,{|oReport| PrintReport(oReport)},"Validação de Rapel")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Documento"	,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Serie"		,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Rede"		,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Cliente"  	,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Nome"		,       					,80,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Data"  	,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Tipo"  	,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Vlr.Rapel"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

	oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA7"),"Total")
    TRFunction():New(oSection1:Cell("COLUNA8")  ,,"SUM" ,oBreak1,""          , "@E 99,999,999.99", NIL, .F., .T.)


	oSection2 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection2,"COLUNA1", 	"" ,"Documento"	,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA2", 	"" ,"Serie"		,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA3", 	"" ,"Rede"		,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA4", 	"" ,"Cliente"  	,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA5", 	"" ,"Nome"		,       					,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA6", 	"" ,"Data"  	,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA7", 	"" ,"Tipo"  	,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA8", 	"" ,"Vlr.Rapel"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

	oBreak2 := TRBreak():New(oSection2,oSection2:Cell("COLUNA7"),"Total")
   
    TRFunction():New(oSection2:Cell("COLUNA8")  ,,"SUM" ,oBreak2,""          , "@E 99,999,999.99", NIL, .F., .T.)

Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1  := oReport:Section(1)
	Local oSection2  := oReport:Section(1)
    Local _x         := 0

	// ----------------- DEVOLUÇÃO
	oSection1:Init()
	oSection1:SetHeaderSection(.T.)
	
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH DEVOLUCAO "
	_oSQL:_sQuery += " AS "
	_oSQL:_sQuery += " (SELECT "
	_oSQL:_sQuery += " 		ZC0_DOC AS NF "
	_oSQL:_sQuery += " 	   ,ZC0.ZC0_SERIE AS SERIE "
	_oSQL:_sQuery += " 	   ,ZC0.ZC0_CODRED AS REDE "
	_oSQL:_sQuery += " 	   ,ZC0.ZC0_CODCLI AS CLIENTE "
	_oSQL:_sQuery += " 	   ,SA1.A1_NOME AS NOME "
	_oSQL:_sQuery += " 	   ,ZC0.ZC0_DATA AS DATA "
	_oSQL:_sQuery += " 	   ,ZC0_RAPEL * -1 VLR_RAPEL "
	_oSQL:_sQuery += " 	   ,'DEVOLUCAO' TIPO "
	_oSQL:_sQuery += " 	FROM " + RetSQLName ("ZC0") + " ZC0 "
	_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 		ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = ZC0.ZC0_CODCLI "
	_oSQL:_sQuery += " 	WHERE ZC0.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 	AND ZC0.ZC0_TM IN ('03', '07') "
	_oSQL:_sQuery += " 	AND ZC0.ZC0_CODRED BETWEEN '" + mv_par03       + "' AND '" + mv_par04       + "' "
	_oSQL:_sQuery += " 	AND ZC0.ZC0_CODCLI BETWEEN '" + mv_par05       + "' AND '" + mv_par06       + "' "
	_oSQL:_sQuery += " 	AND ZC0.ZC0_DATA   BETWEEN '" + dtos(mv_par01) + "' AND '" + dtos(mv_par02) + "' "
	_oSQL:_sQuery += " 	AND ZC0_RAPEL <> 0) "
	_oSQL:_sQuery += "  SELECT "
	_oSQL:_sQuery += " 	   NF "
	_oSQL:_sQuery += "    ,SERIE "
	_oSQL:_sQuery += "    ,REDE "
	_oSQL:_sQuery += "    ,CLIENTE "
	_oSQL:_sQuery += "    ,NOME "
	_oSQL:_sQuery += "    ,DATA "
	_oSQL:_sQuery += "    ,TIPO "
	_oSQL:_sQuery += "    ,SUM(VLR_RAPEL) AS RAPEL "
	_oSQL:_sQuery += " FROM DEVOLUCAO "
	_oSQL:_sQuery += " WHERE VLR_RAPEL <> 0 "
	_oSQL:_sQuery += " GROUP BY  NF "
	_oSQL:_sQuery += " 			,SERIE "
	_oSQL:_sQuery += " 			,REDE "
	_oSQL:_sQuery += " 			,CLIENTE "
	_oSQL:_sQuery += " 			,NOME "
	_oSQL:_sQuery += " 			,DATA "
	_oSQL:_sQuery += " 			,TIPO "
	_oSQL:_sQuery += " ORDER BY DATA, TIPO, NF "
	
	_aDev := aclone (_oSQL:Qry2Array ())

	For _x:=1 to Len(_aDev)
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDev[_x, 1] }) 		
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aDev[_x, 2] }) 		
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aDev[_x, 3] }) 		
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aDev[_x, 4] }) 		
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aDev[_x, 5] }) 		
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| stod(_aDev[_x, 6]) }) 	
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aDev[_x, 7] }) 		
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aDev[_x, 8] }) 		
		
		oSection1:PrintLine()
	Next
	oSection1:Finish()

	// ----------------- VENDAS
	oSection2:Init()
	oSection2:SetHeaderSection(.F.)
	
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH VENDA "
	_oSQL:_sQuery += " AS "
	_oSQL:_sQuery += " (SELECT "
	_oSQL:_sQuery += " 		ZC0_DOC AS NF "
	_oSQL:_sQuery += " 	   ,ZC0.ZC0_SERIE AS SERIE "
	_oSQL:_sQuery += " 	   ,ZC0.ZC0_CODRED AS REDE "
	_oSQL:_sQuery += " 	   ,ZC0.ZC0_CODCLI AS CLIENTE "
	_oSQL:_sQuery += " 	   ,SA1.A1_NOME AS NOME "
	_oSQL:_sQuery += " 	   ,ZC0.ZC0_DATA AS DATA "
	_oSQL:_sQuery += " 	   ,ZC0_RAPEL VLR_RAPEL "
	_oSQL:_sQuery += " 	   ,'VENDA' TIPO "
	_oSQL:_sQuery += " 	FROM " + RetSQLName ("ZC0") + " ZC0 "
	_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 		ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = ZC0.ZC0_CODCLI "
	_oSQL:_sQuery += " 	WHERE ZC0.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 	AND ZC0.ZC0_TM IN ('02', '08') "
	_oSQL:_sQuery += " 	AND ZC0.ZC0_CODRED BETWEEN '" + mv_par03       + "' AND '" + mv_par04       + "' "
	_oSQL:_sQuery += " 	AND ZC0.ZC0_CODCLI BETWEEN '" + mv_par05       + "' AND '" + mv_par06       + "' "
	_oSQL:_sQuery += " 	AND ZC0.ZC0_DATA   BETWEEN '" + dtos(mv_par01) + "' AND '" + dtos(mv_par02) + "' "
	_oSQL:_sQuery += " 	AND ZC0_RAPEL <> 0) "
	_oSQL:_sQuery += "  SELECT "
	_oSQL:_sQuery += " 	   NF "
	_oSQL:_sQuery += "    ,SERIE "
	_oSQL:_sQuery += "    ,REDE "
	_oSQL:_sQuery += "    ,CLIENTE "
	_oSQL:_sQuery += "    ,NOME "
	_oSQL:_sQuery += "    ,DATA "
	_oSQL:_sQuery += "    ,TIPO "
	_oSQL:_sQuery += "    ,SUM(VLR_RAPEL) AS RAPEL "
	_oSQL:_sQuery += " FROM VENDA "
	_oSQL:_sQuery += " WHERE VLR_RAPEL <> 0 "
	_oSQL:_sQuery += " GROUP BY  NF "
	_oSQL:_sQuery += " 			,SERIE "
	_oSQL:_sQuery += " 			,REDE "
	_oSQL:_sQuery += " 			,CLIENTE "
	_oSQL:_sQuery += " 			,NOME "
	_oSQL:_sQuery += " 			,DATA "
	_oSQL:_sQuery += " 			,TIPO "
	_oSQL:_sQuery += " ORDER BY DATA, TIPO, NF "
	
	_aDev := aclone (_oSQL:Qry2Array ())

	For _x:=1 to Len(_aDev)
		oSection2:Cell("COLUNA1")	:SetBlock   ({|| _aDev[_x, 1] }) 		
		oSection2:Cell("COLUNA2")	:SetBlock   ({|| _aDev[_x, 2] }) 		
		oSection2:Cell("COLUNA3")	:SetBlock   ({|| _aDev[_x, 3] }) 		
		oSection2:Cell("COLUNA4")	:SetBlock   ({|| _aDev[_x, 4] }) 		
		oSection2:Cell("COLUNA5")	:SetBlock   ({|| _aDev[_x, 5] }) 		
		oSection2:Cell("COLUNA6")	:SetBlock   ({|| stod(_aDev[_x, 6]) }) 	
		oSection2:Cell("COLUNA7")	:SetBlock   ({|| _aDev[_x, 7] }) 		
		oSection2:Cell("COLUNA8")	:SetBlock   ({|| _aDev[_x, 8] }) 		
		
		oSection2:PrintLine()
	Next
	oSection2:Finish()
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
   
    U_ValPerg (cPerg, _aRegsPerg)
Return
