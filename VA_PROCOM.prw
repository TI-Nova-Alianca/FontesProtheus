// Programa..: VA_PROCOM
// Autor.....: Claudia Lionço
// Data......: 03/03/2023
// Descricao.: Relatório de Provisão de Comissão
// 
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de Provisão de Comissão
// #PalavasChave      #comissões #comissoes #calculo 
// #TabelasPrincipais #SE3 #SE1 #SF2 #SD2 
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
// 03/03/2023 - Claudia - Alterado % de comissão para comissão emdia do SE1. GLPI: 13229
//
// -----------------------------------------------------------------------------------------------------------------------------------
User Function VA_PROCOM()
	Private oReport
	Private cPerg := "VA_PROCOM"
	
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

	oReport := TReport():New("VA_PROCOM","Provisão de Comissão",cPerg,{|oReport| PrintReport(oReport)},"Provisão de Comissão")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Vendedor"		,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Nome"    	    ,	    					,40,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA3", 	"" ,"Emissão"  		,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Nota/Serie"	,       					,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Base Comissão" , "@E 999,999,999.99"       ,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA6", 	"" ,"% Comissão"    , "@E 999.99"               ,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Valor Comissão", "@E 999,999,999.99"       ,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

	oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA1"),"Total")
    TRFunction():New(oSection1:Cell("COLUNA7")  ,,"SUM" ,oBreak1,""          , "@E 99,999,999.99", NIL, .F., .T.)

Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	local oSection1 := oReport:Section(1)
    local _aDados   := {}
    local _x        := 0

    oSection1:Init()
	oSection1:SetHeaderSection(.T.)

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH COMISSAO  "
    _oSQL:_sQuery += " AS  "
    _oSQL:_sQuery += " (SELECT  "
    _oSQL:_sQuery += " 		F2_VEND1 AS VENDEDOR  "
    _oSQL:_sQuery += " 	   ,A3_NOME AS NOME_VENDEDOR  "
    _oSQL:_sQuery += " 	   ,SD2.D2_EMISSAO AS DT_EMISSAO  "
    _oSQL:_sQuery += " 	   ,SD2.D2_DOC AS NOTA  "
    _oSQL:_sQuery += " 	   ,SD2.D2_SERIE AS SERIE  "
    _oSQL:_sQuery += " 	   ,SUM(SD2.D2_TOTAL) AS BASE_COM  "
    _oSQL:_sQuery += " 	   ,SE1.E1_COMIS1 AS PERC_COMIS  "
    _oSQL:_sQuery += " 	FROM " +  RetSQLName ("SD2") + " AS SD2 "
    _oSQL:_sQuery += " 	INNER JOIN " +  RetSQLName ("SF4") + " AS SF4 "
    _oSQL:_sQuery += " 		ON (SF4.D_E_L_E_T_ = ''  "
    _oSQL:_sQuery += " 		AND SF4.F4_CODIGO  = SD2.D2_TES  "
    _oSQL:_sQuery += " 		AND SF4.F4_MARGEM  = '1')  "
    _oSQL:_sQuery += " 	INNER JOIN " +  RetSQLName ("SF2") + " AS SF2 "
    _oSQL:_sQuery += " 		ON (SF2.D_E_L_E_T_ = ''  "
    _oSQL:_sQuery += " 		AND SF2.F2_FILIAL  = SD2.D2_FILIAL  "
    _oSQL:_sQuery += " 		AND SF2.F2_DOC     = SD2.D2_DOC  "
    _oSQL:_sQuery += " 		AND SF2.F2_SERIE   = SD2.D2_SERIE  "
    _oSQL:_sQuery += " 		AND SF2.F2_CLIENTE = SD2.D2_CLIENTE  "
    _oSQL:_sQuery += " 		AND SF2.F2_LOJA    = SD2.D2_LOJA  "
    _oSQL:_sQuery += " 		AND SF2.F2_EMISSAO = SD2.D2_EMISSAO  "
    _oSQL:_sQuery += " 		AND SF2.F2_VEND1 != ''  "
    _oSQL:_sQuery += " 		AND SF2.F2_VEND1 NOT IN  " + FormatIn(alltrim(GetMv('MV_VENDDIR')), '/')   
    _oSQL:_sQuery += " 		AND SF2.F2_VEND1 BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "')"
    _oSQL:_sQuery += " 	INNER JOIN " +  RetSQLName ("SA3") + " AS SA3 "
    _oSQL:_sQuery += " 		ON (SA3.D_E_L_E_T_ = ''  "
    _oSQL:_sQuery += " 		AND SA3.A3_COD = SF2.F2_VEND1)  "
    _oSQL:_sQuery += " 	LEFT JOIN " +  RetSQLName ("SE1") + " AS SE1 "
    _oSQL:_sQuery += " 		ON (SE1.D_E_L_E_T_ = ''  "
    _oSQL:_sQuery += " 		AND SE1.E1_FILIAL  = SD2.D2_FILIAL  "
    _oSQL:_sQuery += " 		AND SE1.E1_NUM     = SD2.D2_DOC  "
    _oSQL:_sQuery += " 		AND SE1.E1_PREFIXO = SD2.D2_SERIE  "
    _oSQL:_sQuery += " 		AND SE1.E1_CLIENTE = SD2.D2_CLIENTE  "
    _oSQL:_sQuery += " 		AND SE1.E1_LOJA    = SD2.D2_LOJA)  "
    _oSQL:_sQuery += " 	WHERE SD2.D_E_L_E_T_ = ''  " 
    _oSQL:_sQuery += " 	AND SD2.D2_SERIE = '10'  "
    _oSQL:_sQuery += " 	AND SD2.D2_COMIS1 > 0  "
    _oSQL:_sQuery += " 	AND SD2.D2_FILIAL  BETWEEN '" + mv_par01       + "' AND '" + mv_par02       + "'"
    _oSQL:_sQuery += " 	AND SD2.D2_EMISSAO BETWEEN '" + dtos(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += " 	GROUP BY F2_VEND1  "
    _oSQL:_sQuery += " 			,A3_NOME
    _oSQL:_sQuery += " 			,SD2.D2_EMISSAO  "
    _oSQL:_sQuery += " 			,SD2.D2_DOC  "
    _oSQL:_sQuery += " 			,SD2.D2_SERIE  "
    _oSQL:_sQuery += " 			,SE1.E1_COMIS1)  "
    _oSQL:_sQuery += " SELECT  "
    _oSQL:_sQuery += "    ,VENDEDOR  "
    _oSQL:_sQuery += "    ,NOME_VENDEDOR  "
    _oSQL:_sQuery += "    ,DT_EMISSAO  "
    _oSQL:_sQuery += "    ,NOTA  "
    _oSQL:_sQuery += "    ,SERIE  "
    _oSQL:_sQuery += "    ,BASE_COM  "
    _oSQL:_sQuery += "    ,PERC_COMIS  "
    _oSQL:_sQuery += "    ,ROUND(BASE_COM * PERC_COMIS / 100, 2) AS VLR_COM  "
    _oSQL:_sQuery += " FROM COMISSAO  "
    _oSQL:_sQuery += " ORDER BY VENDEDOR, DT_EMISSAO, NOTA  "
	_oSQL:Log()
    _aDados := aclone(_oSQL:Qry2Array())

	For _x:=1 to Len(_aDados)

        oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[_x, 1]                         }) 	
        oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aDados[_x, 2]			                }) 		
        oSection1:Cell("COLUNA3")	:SetBlock   ({|| stod(_aDados[_x, 3])                   }) 		
        oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aDados[_x, 4]	+ "/" +_aDados[_x, 5]   }) 		
        oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aDados[_x, 6]			                }) 	
        oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aDados[_x, 7]			                }) 
        oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aDados[_x, 8]			                })   

        oSection1:PrintLine()	
	Next

	oSection1:Finish()
Return
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT             TIPO TAM DEC VALID F3        Opcoes                                              Help
    aadd (_aRegsPerg, {01, "Filial de                    ", "C", 2, 0,  "",   "SM0", {},                                        ""})
    aadd (_aRegsPerg, {02, "Filial até                   ", "C", 2, 0,  "",   "SM0", {},                                        ""})
    aadd (_aRegsPerg, {03, "Data de Emissao de           ", "D", 8, 0,  "",   "   ", {},                                        ""})
    aadd (_aRegsPerg, {04, "Data de Emissao até          ", "D", 8, 0,  "",   "   ", {},                                        ""})
    aadd (_aRegsPerg, {05, "Representante de             ", "C", 3, 0,  "",   "SA3", {},                                        ""})
    aadd (_aRegsPerg, {06, "Representante ate            ", "C", 3, 0,  "",   "SA3", {},                                        ""})
    //aadd (_aRegsPerg, {07, "Ordenação                    ", "N", 1, 0,  "",   "      ", {"Vend.+ Data", "Data + Vend."},        ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
