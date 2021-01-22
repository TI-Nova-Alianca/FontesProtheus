//  Programa...: VA_CLIATIT
//  Autor......: Cláudia Lionço
//  Data.......: 20/01/2021
//  Descricao..: Relatório de títulos vencidos 
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de títulos vencidos 
// #PalavasChave      #titulos_vencidos #clientes_inadimplentes
// #TabelasPrincipais #SE1 
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include "totvs.ch"

User Function VA_CLIATIT()
	Private oReport
	Private cPerg := "VA_CLIATIT"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()

Return
//
// ---------------------------------------------------------------------------------------------------
Static Function ReportDef()
    Local oReport   := Nil
	Local oSection1 := Nil
    Local oSection2 := Nil
    Local oSection3 := Nil
    Local oBreak1
    Local oBreak2

    oReport := TReport():New("VA_CLIATIT","Títulos em atraso",cPerg,{|oReport| PrintReport(oReport)},"Títulos em atraso")
	
	// 100% ATRASO
	oSection1 := TRSection():New(oReport,"TÍTULOS EM ATRASO - SEM BAIXAS PARCIAIS",{}, , , , , ,.F.,.F.,.F.) 
	oSection1:SetPageBreak(.T.)

	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    				,08,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Título"		,       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Tipo"		    ,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Cliente"		,						,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA5", 	"" ,"Nome"			,       				,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Dt.Emissão"    ,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Dt.Venc.Real"	,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA8", 	"" ,"Valor"	        , "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Saldo"	        , "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"Dias Vencidos" ,                       ,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    
    oBreak1 := TRBreak():New(oSection1,{|| oSection1:Cell("COLUNA1"):uPrint },"Total da filial:")
    TRFunction():New(oSection1:Cell("COLUNA8")	,,"SUM"	,oBreak1, "Valor total ", "@E 999,999,999,999.99", NIL, .F., .F.)
	TRFunction():New(oSection1:Cell("COLUNA9")	,,"SUM"	,oBreak1, "Saldo total ", "@E 999,999,999,999.99", NIL, .F., .F.)

    // ATRASO PARCIAL
	oSection2 := TRSection():New(oReport,"TÍTULOS EM ATRASO - BAIXAS PARCIAIS",{}, , , , , ,.F.,.F.,.F.) 
	oSection2:SetPageBreak(.T.)

	TRCell():New(oSection2,"COLUNA1", 	"" ,"Filial"		,	    				,08,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA2", 	"" ,"Título"		,       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA3", 	"" ,"Tipo"		    ,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA4", 	"" ,"Cliente"		,						,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection2,"COLUNA5", 	"" ,"Nome"			,       				,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA6", 	"" ,"Dt.Emissão"    ,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA7", 	"" ,"Dt.Venc.Real"	,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection2,"COLUNA8", 	"" ,"Valor"	        , "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA9", 	"" ,"Saldo"	        , "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection2,"COLUNA10", 	"" ,"Dias Vencidos" ,                       ,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)

    oBreak2 := TRBreak():New(oSection2,{|| oSection2:Cell("COLUNA1"):uPrint },"Total da filial:")
    TRFunction():New(oSection2:Cell("COLUNA8")	,,"SUM"	,oBreak2, "Valor total ", "@E 999,999,999,999.99", NIL, .F., .F.)
	TRFunction():New(oSection2:Cell("COLUNA9")	,,"SUM"	,oBreak2, "Saldo total ", "@E 999,999,999,999.99", NIL, .F., .F.)

     // TOTALIZADORES
	oSection3 := TRSection():New(oReport,"TÍTULOS EM ATRASO - TOTALIZADORES",{}, , , , , ,.F.,.F.,.F.) 
	oSection3:SetPageBreak(.T.)

	TRCell():New(oSection3,"COLUNA1", 	"" ,"Filial"		,	    				,08,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection3,"COLUNA2", 	"" ,"Valor"	        , "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection3,"COLUNA3", 	"" ,"Saldo"	        , "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1   := oReport:Section(1)	
    Local oSection2   := oReport:Section(2)	
    Local oSection3   := oReport:Section(3)	
    Local _a100Atraso := {}
    Local _aParcial   := {}
    Local _aTipos     := {}
    Local _aTotal     := {}
    Local _sTipo      := ""
    Local i           := 0
    Local x           := 0
    Local y           := 0
    Local _nVlr100    := 0
    Local _nParcial   := 0
    Local _nQnt100    := 0
    Local _nQntParc   := 0
    Local _nTotalVlr  := 0
    Local _nTotalSal  := 0

    _aTipos := STRTOKARR(mv_par05,";")

    For y:=1 to Len(_aTipos)
        _sTipo += "'" + alltrim(_aTipos[y]) + "'"
        If y < Len(_aTipos)
            _sTipo += ","
        EndIf
    Next
    //
    // ----------------------------------------------------------------------------------
    // TITULOS 100% EM ATRASO
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += "	WITH C"
    _oSQL:_sQuery += "	AS"
    _oSQL:_sQuery += "	(SELECT"
    _oSQL:_sQuery += "			SE1.E1_FILIAL AS FILIAL"
    _oSQL:_sQuery += "		   ,SE1.E1_NUM + '/' + SE1.E1_PREFIXO + '/' + SE1.E1_PARCELA AS TITULO"
    _oSQL:_sQuery += "		   ,SE1.E1_TIPO AS TIPO"
    _oSQL:_sQuery += "		   ,SE1.E1_CLIENTE + '/' + SE1.E1_LOJA AS CLIENTE"
    _oSQL:_sQuery += "		   ,SA1.A1_NOME AS NOME"
    _oSQL:_sQuery += "		   ,SE1.E1_EMISSAO AS EMISSAO"
    _oSQL:_sQuery += "		   ,SE1.E1_VENCREA AS VENCREA"
    _oSQL:_sQuery += "		   ,SE1.E1_VALOR AS VALOR"
    _oSQL:_sQuery += "		   ,SE1.E1_SALDO AS SALDO"
    _oSQL:_sQuery += "		   ,ISNULL(DATEDIFF(DAY, CAST(SE1.E1_VENCREA AS DATETIME), CAST('" + dtos(mv_par06) + "' AS DATETIME)), 1) AS QDIAS"
    _oSQL:_sQuery += "		FROM " + RetSQLName ("SE1") + " AS SE1"
    _oSQL:_sQuery += "		INNER JOIN " + RetSQLName ("SA1") + " AS SA1"
    _oSQL:_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "			AND SA1.A1_COD = SE1.E1_CLIENTE"
    _oSQL:_sQuery += "			AND SA1.A1_LOJA = SE1.E1_LOJA)"
    _oSQL:_sQuery += "		WHERE SE1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "		AND SE1.E1_FILIAL BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
    _oSQL:_sQuery += "		AND SE1.E1_TIPO NOT IN (" + alltrim(_sTipo) + ")"
    _oSQL:_sQuery += "		AND SE1.E1_SALDO > 0"
    _oSQL:_sQuery += "		AND SE1.E1_SALDO = SE1.E1_VALOR"
    _oSQL:_sQuery += "		AND SE1.E1_EMISSAO BETWEEN '20030101' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += "		AND SE1.E1_VENCREA BETWEEN '" + DTOS(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += "	)"
    _oSQL:_sQuery += "	SELECT"
    _oSQL:_sQuery += "		*"
    _oSQL:_sQuery += "	FROM C"
    _oSQL:_sQuery += "	WHERE QDIAS > 0"
    _oSQL:_sQuery += "	ORDER BY FILIAL, QDIAS"
    _a100Atraso := _oSQL:Qry2Array ()

    oSection1:Init()

    oReport:PrintText(" TÍTULOS EM ATRASO - SEM BAIXAS PARCIAIS",,100)
    oReport:SkipLine(1) 

    For i := 1 to Len(_a100Atraso)
        oSection1:Cell("COLUNA1")	:SetBlock   ({|| _a100Atraso[i,1] })
        oSection1:Cell("COLUNA2")	:SetBlock   ({|| _a100Atraso[i,2] })
        oSection1:Cell("COLUNA3")	:SetBlock   ({|| _a100Atraso[i,3] })
        oSection1:Cell("COLUNA4")	:SetBlock   ({|| _a100Atraso[i,4] })
        oSection1:Cell("COLUNA5")	:SetBlock   ({|| _a100Atraso[i,5] })
        oSection1:Cell("COLUNA6")	:SetBlock   ({|| STOD(_a100Atraso[i,6]) })
        oSection1:Cell("COLUNA7")	:SetBlock   ({|| STOD(_a100Atraso[i,7]) })
        oSection1:Cell("COLUNA8")	:SetBlock   ({|| _a100Atraso[i,8] })
        oSection1:Cell("COLUNA9")	:SetBlock   ({|| _a100Atraso[i,9] })
        oSection1:Cell("COLUNA10")	:SetBlock   ({|| _a100Atraso[i,10]})

        oSection1:PrintLine()

        _nVlr100 += _a100Atraso[i,9]
        _nQnt100 += 1
    Next

    oSection1:Finish()

    oReport:ThinLine()
    _nLinha :=  oReport:Row()
    _nLinha:= _PulaFolha(_nLinha)
    oReport:PrintText("SALDO 100% EM ATRASO:" ,_nLinha, 100)
    oReport:PrintText(PADL('R$' + Transform(_nVlr100, "@E 999,999,999.99"),20,' '),_nLinha, 900)
    oReport:SkipLine(1) 

    _nLinha :=  oReport:Row()
    _nLinha:= _PulaFolha(_nLinha)
    oReport:PrintText("QNT.TITULOS 100% EM ATRASO:" ,_nLinha, 100)
    oReport:PrintText(PADL('  ' + Transform(_nQnt100, "@E 99999,999,999"),20,' '),_nLinha, 900)
    oReport:SkipLine(1) 

    oReport:ThinLine()

    // ----------------------------------------------------------------------------------------------------------------------------------
    // TITULOS PARCIAIS EM ATRASO
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += "	WITH C"
    _oSQL:_sQuery += "	AS"
    _oSQL:_sQuery += "	(SELECT"
    _oSQL:_sQuery += "			SE1.E1_FILIAL AS FILIAL"
    _oSQL:_sQuery += "		   ,SE1.E1_NUM + '/' + SE1.E1_PREFIXO + '/' + SE1.E1_PARCELA AS TITULO"
    _oSQL:_sQuery += "		   ,SE1.E1_TIPO AS TIPO"
    _oSQL:_sQuery += "		   ,SE1.E1_CLIENTE + '/' + SE1.E1_LOJA AS CLIENTE"
    _oSQL:_sQuery += "		   ,SA1.A1_NOME AS NOME"
    _oSQL:_sQuery += "		   ,SE1.E1_EMISSAO AS EMISSAO"
    _oSQL:_sQuery += "		   ,SE1.E1_VENCREA AS VENCREA"
    _oSQL:_sQuery += "		   ,SE1.E1_VALOR AS VALOR"
    _oSQL:_sQuery += "		   ,SE1.E1_SALDO AS SALDO"
    _oSQL:_sQuery += "		   ,ISNULL(DATEDIFF(DAY, CAST(SE1.E1_VENCREA AS DATETIME), CAST('" + dtos(mv_par06) + "' AS DATETIME)), 1) AS QDIAS"
    _oSQL:_sQuery += "		FROM " + RetSQLName ("SE1") + " AS SE1"
    _oSQL:_sQuery += "		INNER JOIN " + RetSQLName ("SA1") + " AS SA1"
    _oSQL:_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "			AND SA1.A1_COD = SE1.E1_CLIENTE"
    _oSQL:_sQuery += "			AND SA1.A1_LOJA = SE1.E1_LOJA)"
    _oSQL:_sQuery += "		WHERE SE1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "		AND SE1.E1_FILIAL BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
    _oSQL:_sQuery += "		AND SE1.E1_TIPO NOT IN (" + alltrim(_sTipo) + ")"
    _oSQL:_sQuery += "		AND SE1.E1_SALDO > 0"
    _oSQL:_sQuery += "		AND SE1.E1_SALDO != SE1.E1_VALOR"
    _oSQL:_sQuery += "		AND SE1.E1_EMISSAO BETWEEN '20030101' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += "		AND SE1.E1_VENCREA BETWEEN '" + DTOS(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += "	)"
    _oSQL:_sQuery += "	SELECT"
    _oSQL:_sQuery += "		*"
    _oSQL:_sQuery += "	FROM C"
    _oSQL:_sQuery += "	WHERE QDIAS > 0"
    _oSQL:_sQuery += "	ORDER BY FILIAL, QDIAS"
    _aParcial := _oSQL:Qry2Array ()

    oReport:SkipLine(2) 
    oReport:ThinLine()
    oSection2:Init()
    oReport:SkipLine(1) 
    oReport:PrintText(" TÍTULOS EM ATRASO - BAIXAS PARCIAIS",,100)

    For x := 1 to Len(_aParcial)
        oSection2:Cell("COLUNA1")	:SetBlock   ({|| _aParcial[x,1] })
        oSection2:Cell("COLUNA2")	:SetBlock   ({|| _aParcial[x,2] })
        oSection2:Cell("COLUNA3")	:SetBlock   ({|| _aParcial[x,3] })
        oSection2:Cell("COLUNA4")	:SetBlock   ({|| _aParcial[x,4] })
        oSection2:Cell("COLUNA5")	:SetBlock   ({|| _aParcial[x,5] })
        oSection2:Cell("COLUNA6")	:SetBlock   ({|| STOD(_aParcial[x,6]) })
        oSection2:Cell("COLUNA7")	:SetBlock   ({|| STOD(_aParcial[x,7]) })
        oSection2:Cell("COLUNA8")	:SetBlock   ({|| _aParcial[x,8] })
        oSection2:Cell("COLUNA9")	:SetBlock   ({|| _aParcial[x,9] })
        oSection2:Cell("COLUNA10")	:SetBlock   ({|| _aParcial[x,10]})

        oSection2:PrintLine()

        _nParcial += _aParcial[x,9]
        _nQntParc += 1
    Next

    oSection2:Finish()

    oReport:ThinLine()
    _nLinha :=  oReport:Row()
    _nLinha:= _PulaFolha(_nLinha)
    oReport:PrintText("SALDO PARCIAL EM ATRASO:" ,_nLinha, 100)
    oReport:PrintText(PADL('R$' + Transform(_nParcial, "@E 999,999,999.99"),20,' '),_nLinha, 900)
    oReport:SkipLine(1) 

    _nLinha :=  oReport:Row()
    _nLinha:= _PulaFolha(_nLinha)
    oReport:PrintText("QNT.TITULOS PARCIAIS EM ATRASO:" ,_nLinha, 100)
    oReport:PrintText(PADL('  ' + Transform(_nQntParc, "@E 99999,999,999"),20,' '),_nLinha, 900)
    oReport:SkipLine(1) 

    oReport:ThinLine()

    // ----------------------------------------------------------------------------------
    // TOTAL GERAL
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += "	WITH C"
    _oSQL:_sQuery += "	AS"
    _oSQL:_sQuery += "	(SELECT"
    _oSQL:_sQuery += "			SE1.E1_FILIAL AS FILIAL"
    _oSQL:_sQuery += "		   ,SE1.E1_NUM + '/' + SE1.E1_PREFIXO + '/' + SE1.E1_PARCELA AS TITULO"
    _oSQL:_sQuery += "		   ,SE1.E1_TIPO AS TIPO"
    _oSQL:_sQuery += "		   ,SE1.E1_CLIENTE + '/' + SE1.E1_LOJA AS CLIENTE"
    _oSQL:_sQuery += "		   ,SA1.A1_NOME AS NOME"
    _oSQL:_sQuery += "		   ,SE1.E1_EMISSAO AS EMISSAO"
    _oSQL:_sQuery += "		   ,SE1.E1_VENCREA AS VENCREA"
    _oSQL:_sQuery += "		   ,SE1.E1_VALOR AS VALOR"
    _oSQL:_sQuery += "		   ,SE1.E1_SALDO AS SALDO"
    _oSQL:_sQuery += "		   ,ISNULL(DATEDIFF(DAY, CAST(SE1.E1_VENCREA AS DATETIME), CAST('" + dtos(mv_par06) + "' AS DATETIME)), 1) AS QDIAS"
    _oSQL:_sQuery += "		FROM " + RetSQLName ("SE1") + " AS SE1"
    _oSQL:_sQuery += "		INNER JOIN " + RetSQLName ("SA1") + " AS SA1"
    _oSQL:_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "			AND SA1.A1_COD = SE1.E1_CLIENTE"
    _oSQL:_sQuery += "			AND SA1.A1_LOJA = SE1.E1_LOJA)"
    _oSQL:_sQuery += "		WHERE SE1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "		AND SE1.E1_FILIAL BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
    _oSQL:_sQuery += "		AND SE1.E1_TIPO NOT IN (" + alltrim(_sTipo) + ")"
    _oSQL:_sQuery += "		AND SE1.E1_SALDO > 0"
    _oSQL:_sQuery += "		AND SE1.E1_EMISSAO BETWEEN '20030101' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += "		AND SE1.E1_VENCREA BETWEEN '" + DTOS(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += "	)"
    _oSQL:_sQuery += "	SELECT "
    _oSQL:_sQuery += "	    FILIAL"
    _oSQL:_sQuery += "	    ,SUM(VALOR)"
    _oSQL:_sQuery += "	    ,SUM(SALDO)"
    _oSQL:_sQuery += "	FROM C"
    _oSQL:_sQuery += "	WHERE QDIAS > 0"	
    _oSQL:_sQuery += "	GROUP BY FILIAL"
    _oSQL:_sQuery += "	ORDER BY FILIAL"
    _aTotal := _oSQL:Qry2Array ()

    oReport:SkipLine(2) 
    oReport:ThinLine()
    oSection3:Init()
    oReport:SkipLine(1) 
    oReport:PrintText(" TÍTULOS EM ATRASO - TOTALIZADORES",,100)

    For x := 1 to Len(_aTotal)
        oSection3:Cell("COLUNA1")	:SetBlock   ({|| _aTotal[x,1] })
        oSection3:Cell("COLUNA2")	:SetBlock   ({|| _aTotal[x,2] })
        oSection3:Cell("COLUNA3")	:SetBlock   ({|| _aTotal[x,3] })

        oSection3:PrintLine()

        _nTotalVlr += _aTotal[x,2]
        _nTotalSal += _aTotal[x,3]
    Next

    oSection3:Finish()

    oReport:ThinLine()
    _nLinha :=  oReport:Row()
    _nLinha:= _PulaFolha(_nLinha)
    oReport:PrintText("VALOR TOTAL DE TÍTULOS:" ,_nLinha, 10)
    oReport:PrintText(PADL('R$' + Transform(_nTotalVlr, "@E 999,999,999.99"),20,' '),_nLinha, 450)
    oReport:SkipLine(1) 

    _nLinha :=  oReport:Row()
    _nLinha:= _PulaFolha(_nLinha)
    oReport:PrintText("SALDO TOTAL EM ATRASO:" ,_nLinha, 10)
    oReport:PrintText(PADL('R$' + Transform(_nTotalSal, "@E 999,999,999.99"),20,' '),_nLinha, 450)
    oReport:SkipLine(1) 

    oReport:ThinLine()
    oReport:SkipLine(5) 
    oReport:ThinLine()

    // ----------------------------------------------------------------------------------
    // PARAMETROS
    oReport:SkipLine(1)

    oReport:PrintText("PARAMETROS:",, 100)
    oReport:PrintText("Filial de:" + alltrim(mv_Par01) + " até " + alltrim(mv_Par02),, 100)
    oReport:PrintText("Dt. vencimento real de:" + DTOC(mv_Par03) + " até " + DTOC(mv_Par04),, 100)
    oReport:PrintText("Tipos não inclusos:" + alltrim(mv_Par05) ,, 100)
    oReport:PrintText("Dt.Base para calculo de dias:" + DTOC(mv_Par06) ,, 100)

    oReport:SkipLine(1)
    oReport:ThinLine()

Return
//
// --------------------------------------------------------------------------
// Pular folha na impressão
Static Function _PulaFolha(_nLinha)
	local _nRet := 0

	If  _nLinha > 2300
		oReport:EndPage()
		oReport:StartPage()
		_nRet := oReport:Row()
	Else
		_nRet := _nLinha
	EndIf
Return _nRet
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT             TIPO  TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Filial de        ", "C",  2, 0,  "",   "   ", {},              "Filial de"})
    aadd (_aRegsPerg, {02, "Filial ate       ", "C",  2, 0,  "",   "   ", {},              "Filial até"})
    aadd (_aRegsPerg, {03, "Dt.Venc.real de  ", "D",  8, 0,  "",   "   ", {},              "Data de vencimento de"})
    aadd (_aRegsPerg, {04, "Dt.Venc.real até ", "D",  8, 0,  "",   "   ", {},              "Data de vencimento até"})
    aadd (_aRegsPerg, {05, "Tipo não incluso ", "C", 20, 0,  "",   "   ", {},              "Incluir os tipos que não serão impressos, através de ;"})
    aadd (_aRegsPerg, {06, "Dt.Base p/Dias   ", "D",  8, 0,  "",   "   ", {},              "Data base para"})

    U_ValPerg (cPerg, _aRegsPerg)
Return
