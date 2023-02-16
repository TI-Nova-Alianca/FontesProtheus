// Programa..: VA_PREVCOM
// Autor.....: Claudia Lionço
// Data......: 09/11/2022
// Descricao.: Relatório de Provisão de Comissão
// 
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de Provisão de Comissão
// #PalavasChave      #comissões #comissoes #calculo 
// #TabelasPrincipais #SE3 #SE1 #SF2 #SD2 
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
//
// -----------------------------------------------------------------------------------------------------------------------------------
User Function VA_PREVCOM ()
	Private oReport
	Private cPerg := "VA_PREVCOM"
	
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

	oReport := TReport():New("VA_PREVCOM","Provisão de Comissão",cPerg,{|oReport| PrintReport(oReport)},"Provisão de Comissão")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Vendedor"		,       					,60,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Filial"    	,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Título"		,       					,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Emissão"  		,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Base Prevista" , "@E 999,999,999.99"       ,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Percentual"	, "@E 999,999,999.99"       ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Comissão"  	, "@E 999,999,999.99"       ,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

	oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA1"),"Total")
   
    TRFunction():New(oSection1:Cell("COLUNA7")  ,,"SUM" ,oBreak1,""          , "@E 99,999,999.99", NIL, .F., .T.)

Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	local oSection1  := oReport:Section(1)
    local _aComissao := {}
    local _x         := 0

    oSection1:Init()
	oSection1:SetHeaderSection(.T.)

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""

	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   SF2.F2_VEND1 + ' - ' + SA3.A3_NOME AS VENDEDOR "
	_oSQL:_sQuery += "    ,SD2.D2_FILIAL AS FILIAL "
	_oSQL:_sQuery += "    ,SD2.D2_DOC + ' ' + SD2.D2_SERIE AS DOCUMENTO "
	_oSQL:_sQuery += "    ,SD2.D2_EMISSAO AS EMISSAO "
	_oSQL:_sQuery += "    ,SUM(SD2.D2_TOTAL) AS BASE_PREVISTA "
	_oSQL:_sQuery += "    ,SD2.D2_COMIS1 AS PERC_COMISSAO "
	_oSQL:_sQuery += "    ,SUM(ROUND(SD2.D2_TOTAL * SD2.D2_COMIS1 / 100, 2)) AS VALOR_COMISSAO "
	_oSQL:_sQuery += " FROM " +  RetSQLName ("SD2") + " AS SD2 "
	_oSQL:_sQuery += " INNER JOIN " +  RetSQLName ("SF2") + " AS SF2 "
	_oSQL:_sQuery += " 	ON SF2.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SF2.F2_FILIAL  = SD2.D2_FILIAL "
	_oSQL:_sQuery += " 		AND SF2.F2_DOC     = SD2.D2_DOC "
	_oSQL:_sQuery += " 		AND SF2.F2_SERIE   = SD2.D2_SERIE "
	_oSQL:_sQuery += " 		AND SF2.F2_CLIENTE = SD2.D2_CLIENTE "
	_oSQL:_sQuery += " 		AND SF2.F2_LOJA    = SD2.D2_LOJA "
	_oSQL:_sQuery += "      AND SF2.F2_VEND1 BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' "
	_oSQL:_sQuery += " INNER JOIN " +  RetSQLName ("SA3") + " AS SA3 "
	_oSQL:_sQuery += " 	ON SA3.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA3.A3_COD = SF2.F2_VEND1 "
	_oSQL:_sQuery += " WHERE SD2.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND SD2.D2_COMIS1 > 0 "
	_oSQL:_sQuery += " AND D2_FILIAL  BETWEEN '"+ mv_par01       +"' AND '"+ mv_par02       +"' "
	_oSQL:_sQuery += " AND D2_EMISSAO BETWEEN '"+ dtos(mv_par03) +"' AND '"+ dtos(mv_par04) +"' "
	_oSQL:_sQuery += " GROUP BY SF2.F2_VEND1 "
	_oSQL:_sQuery += " 		,SA3.A3_NOME "
	_oSQL:_sQuery += " 		,SD2.D2_FILIAL "
	_oSQL:_sQuery += " 		,SD2.D2_DOC "
	_oSQL:_sQuery += " 		,SD2.D2_SERIE "
	_oSQL:_sQuery += " 		,SD2.D2_EMISSAO "
	_oSQL:_sQuery += " 		,SD2.D2_COMIS1 "
    _aComissao := aclone(_oSQL:Qry2Array())

    For _x:=1 to Len(_aComissao)
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aComissao[_x,1] 		}) 	
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aComissao[_x,2] 		}) 		
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aComissao[_x,3] 		}) 		
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| stod(_aComissao[_x,4]) }) 		
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aComissao[_x,5] 		}) 		
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aComissao[_x,6] 		}) 		
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aComissao[_x,7] 		}) 	    
	
		oSection1:PrintLine()
    Next

    oSection1:Finish()
Return
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT             TIPO TAM DEC VALID F3        Opcoes                               Help
    aadd (_aRegsPerg, {01, "Filial de       ", "C", 2, 0,  "",   "   "      , {},                         		 ""})
	aadd (_aRegsPerg, {02, "Filial até      ", "C", 2, 0,  "",   "   "      , {},                         		 ""})
    aadd (_aRegsPerg, {03, "Emissão de      ", "D", 8, 0,  "",   "   "      , {},                         		 ""})
    aadd (_aRegsPerg, {04, "Emissão até     ", "D", 8, 0,  "",   "   "      , {},                         		 ""})
    aadd (_aRegsPerg, {05, "Vendedor de     ", "C", 6, 0,  "",   "SA3"      , {},                         		 ""})
    aadd (_aRegsPerg, {06, "Vendedor até    ", "C", 6, 0,  "",   "SA3"      , {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
