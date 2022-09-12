//  Programa...: ZC0PRO
//  Autor......: Cl�udia Lion�o
//  Data.......: 12/09/2022
//  Descricao..: Relat�rio de Provis�o de Rapel
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relat�rio de Provis�o de Rapel
// #PalavasChave      #rapel 
// #TabelasPrincipais #ZC0 
// #Modulos 		  #FAT 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------------------
#include 'protheus.ch'

User Function ZC0PRO()
	Private oReport
	Private cPerg := "ZC0PRO"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()

Return
//
// ---------------------------------------------------------------------------
// Cabe�alho da rotina
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	//Local oBreak1

	oReport := TReport():New("ZC0PRO","Provis�o de Rapel",cPerg,{|oReport| PrintReport(oReport)},"Provis�o de Rapel")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"			,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Rede"				,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Nome"				,       					,50,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Cliente"			,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Data"  			,       					,12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Documento"  		,		       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Vlr.Rapel"			, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

	oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA2"),"Total")
   
    TRFunction():New(oSection1:Cell("COLUNA7")  ,,"SUM" ,oBreak1,""          , "@E 99,999,999.99", NIL, .F., .T.)

Return(oReport)
//
// -------------------------------------------------------------------------
// Impress�o
Static Function PrintReport(oReport)
	Local oSection1  := oReport:Section(1)
    Local _x         := 0

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)
	
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   ZC0_FILIAL "
    _oSQL:_sQuery += "    ,ZC0_CODRED "
    _oSQL:_sQuery += "    ,SA1.A1_NOME "
    _oSQL:_sQuery += "    ,ZC0_CODCLI "
    _oSQL:_sQuery += "    ,ZC0.ZC0_DATA "
    _oSQL:_sQuery += "    ,ZC0_DOC +'/' + ZC0.ZC0_SERIE "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		WHEN ZC0_TM = '03' THEN SUM(ZC0_RAPEL) * -1 "
    _oSQL:_sQuery += " 		ELSE SUM(ZC0_RAPEL) "
    _oSQL:_sQuery += " 	END RAPEL "
    _oSQL:_sQuery += " FROM " + RetSQLName ("ZC0") + " ZC0 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
    _oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SA1.A1_COD = ZC0.ZC0_CODRED "
    _oSQL:_sQuery += " WHERE ZC0.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND ZC0.ZC0_TM IN ('02', '03') "
    _oSQL:_sQuery += " AND ZC0.ZC0_FILIAL BETWEEN '" + mv_par01      + "' AND '" + mv_par02       + "' "
    _oSQL:_sQuery += " AND ZC0_NFEMIS     BETWEEN '"+ dtos(mv_par03) + "' AND '" + dtos(mv_par04) + "' "
    _oSQL:_sQuery += " AND ZC0.ZC0_DATA   BETWEEN '"+ dtos(mv_par03) + "' AND '" + dtos(mv_par04) + "' "
    _oSQL:_sQuery += " AND ZC0_RAPEL > 0 "
    _oSQL:_sQuery += " GROUP BY ZC0_FILIAL "
    _oSQL:_sQuery += " 		,ZC0_CODRED "
    _oSQL:_sQuery += " 		,ZC0_CODCLI "
    _oSQL:_sQuery += " 		,SA1.A1_NOME "
    _oSQL:_sQuery += " 		,ZC0.ZC0_DATA "
    _oSQL:_sQuery += " 		,ZC0_DOC "
    _oSQL:_sQuery += " 		,ZC0.ZC0_SERIE "
    _oSQL:_sQuery += " 		,ZC0.ZC0_TM "
    _oSQL:_sQuery += " ORDER BY ZC0_FILIAL, ZC0.ZC0_DATA, ZC0.ZC0_DOC "

	_aZC0 := aclone (_oSQL:Qry2Array ())

	For _x:=1 to Len(_aZC0)

		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aZC0[_x, 1] }) 		
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aZC0[_x, 2] }) 		
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aZC0[_x, 3] }) 		
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aZC0[_x, 4] }) 		
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aZC0[_x, 5] }) 		
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aZC0[_x, 6] }) 		
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aZC0[_x, 7] }) 	
		
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
	aadd (_aRegsPerg, {02, "Filial at�       ", "C", 2, 0,  "",   "   "     , {},                         		 ""})
    aadd (_aRegsPerg, {03, "Data de          ", "D", 8, 0,  "",   "   "     , {},                         		 ""})
    aadd (_aRegsPerg, {04, "Data at�         ", "D", 8, 0,  "",   "   "     , {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
