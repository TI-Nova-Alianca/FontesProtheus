//  Programa...: VA_CLITITA
//  Autor......: Cláudia Lionço
//  Data.......: 20/01/2021
//  Descricao..: Relatório de titulos pagos em atraso
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de clientes em atraso
// #PalavasChave      #titulos_vencidos #clientes_inadimplentes
// #TabelasPrincipais #SE1 
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
// 05/02/2021 - Claudia - Incluido mais um parametro para tipos nao inclusos
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include "totvs.ch"

User Function VA_CLITITA()
	Private oReport
	Private cPerg := "VA_CLITITA"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()

Return
//
// -------------------------------------------------------------------------
Static Function ReportDef()
    Local oReport   := Nil
	Local oSection1 := Nil
    Local oSection2 := Nil
    Local oBreak1

    oReport := TReport():New("VA_CLITITA","Titulos quitados em atraso",cPerg,{|oReport| PrintReport(oReport)},"Titulos quitados em atraso")
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
    oSection1:SetPageBreak(.T.)
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    			    ,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA2", 	"" ,"Titulo"		,	    			    ,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA3", 	"" ,"Tipo"		    ,	    			    ,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA4", 	"" ,"Cliente"		,	    			    ,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA5", 	"" ,"Nome"		    ,	    			    ,35,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA6", 	"" ,"Dt.Emissão"	,	    			    ,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA7", 	"" ,"Dt.Venc.Real"	,	    			    ,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA8", 	"" ,"Dt.Baixa"		,	    			    ,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA9", 	"" ,"Valor"	        , "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA10", 	"" ,"Dias Vencidos"	,	    			    ,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)

    oBreak1 := TRBreak():New(oSection1,{|| oSection1:Cell("COLUNA1"):uPrint },"Total da filial:")
	TRFunction():New(oSection1:Cell("COLUNA9")	,,"SUM"	,oBreak1, "Valor total ", "@E 999,999,999,999.99", NIL, .F., .F.)

    oSection2 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
    oSection2:SetPageBreak(.T.)
	
    TRCell():New(oSection2,"COLUNA1", 	"" ,"Cliente"		,	    			    ,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection2,"COLUNA2", 	"" ,"Nome"		    ,	    			    ,60,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection2,"COLUNA3", 	"" ,"Valor"	        , "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA4", 	"" ,"Média dias"	,	    			    ,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)


Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1   := oReport:Section(1)	
    Local oSection2   := oReport:Section(2)	
    Local _aDados     := {}
    Local _aDadosCli  := {}
    Local _sTipo      := ""
    Local i           := 0
    Local _nVlrTotal  := 0
    Local _nVlrTCli   := 0

     _sTipo := RetornaTipo()
    // ----------------------------------------------------------------------------------
    // DIAS PAGOS EM ATRASO - POR TÍTULO
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " WITH C"
    _oSQL:_sQuery += " AS"
    _oSQL:_sQuery += " (SELECT"
    _oSQL:_sQuery += "		SE1.E1_FILIAL AS FILIAL"
    _oSQL:_sQuery += "	   ,SE1.E1_NUM + '/' + SE1.E1_PREFIXO + '/' + SE1.E1_PARCELA AS TITULO"
    _oSQL:_sQuery += "	   ,SE1.E1_TIPO AS TIPO"
    _oSQL:_sQuery += "	   ,SE1.E1_CLIENTE + '/' + SE1.E1_LOJA AS CLIENTE"
    _oSQL:_sQuery += "	   ,SA1.A1_NOME AS NOME"
    _oSQL:_sQuery += "	   ,SE1.E1_EMISSAO AS EMISSAO"
    _oSQL:_sQuery += "	   ,SE1.E1_VENCREA AS VENCREA"
    _oSQL:_sQuery += "	   ,SE1.E1_BAIXA AS BAIXA"
    _oSQL:_sQuery += "	   ,SE1.E1_VALOR AS VALOR"
    _oSQL:_sQuery += "	   ,ISNULL(DATEDIFF(DAY, CAST(SE1.E1_VENCREA AS DATETIME), CAST(SE1.E1_BAIXA AS DATETIME)), 1) AS QDIAS"
    _oSQL:_sQuery += " 	FROM " + RetSQLName ("SE1") + " AS SE1"
    _oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SA1") + " AS SA1"
    _oSQL:_sQuery += "		ON (SA1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "		AND SA1.A1_COD = SE1.E1_CLIENTE"
    _oSQL:_sQuery += "		AND SA1.A1_LOJA = SE1.E1_LOJA)"
    _oSQL:_sQuery += "	WHERE SE1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "		AND SE1.E1_FILIAL BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
    _oSQL:_sQuery += "		AND SE1.E1_TIPO NOT IN (" + alltrim(_sTipo) + ")"
    _oSQL:_sQuery += "		AND SE1.E1_SALDO = 0"
    _oSQL:_sQuery += "		AND SE1.E1_EMISSAO BETWEEN '20030101' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += "		AND SE1.E1_VENCREA BETWEEN '" + DTOS(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += " )"
    _oSQL:_sQuery += " SELECT"
    _oSQL:_sQuery += "	*"
    _oSQL:_sQuery += " FROM C"
    _oSQL:_sQuery += " WHERE QDIAS > 1"
    _oSQL:_sQuery += " ORDER BY FILIAL, QDIAS"
    
    _aDados := _oSQL:Qry2Array ()

    oReport:SkipLine(2) 
    oReport:ThinLine()
    oSection1:Init()

    oReport:SkipLine(1) 
    oReport:PrintText(" DIAS PAGOS EM ATRASO - POR TÍTULO",,100)

    For i := 1 to Len(_aDados)
        oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[i,1] })
        oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aDados[i,2] })
        oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aDados[i,3] })
        oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aDados[i,4] })
        oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aDados[i,5] })
        oSection1:Cell("COLUNA6")	:SetBlock   ({|| STOD(_aDados[i,6]) })
        oSection1:Cell("COLUNA7")	:SetBlock   ({|| STOD(_aDados[i,7]) })
        oSection1:Cell("COLUNA8")	:SetBlock   ({|| STOD(_aDados[i,8]) })
        oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aDados[i,9] })
        oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aDados[i,10]})

        oSection1:PrintLine()

        _nVlrTotal += _aDados[i,9]
    Next

    oSection1:Finish()

    oReport:ThinLine()
    oReport:SkipLine(1) 
    oReport:SkipLine(1) 
    _nLinha :=  oReport:Row()
    _nLinha:= _PulaFolha(_nLinha)
    oReport:PrintText("VALOR TOTAL DOS TÍTULOS:" ,_nLinha, 100)
    oReport:PrintText(PADL('R$' + Transform(_nVlrTotal, "@E 999,999,999.99"),20,' '),_nLinha, 900)
    oReport:SkipLine(1) 

    // --------------------------------------------------------------------------------------
    // TITULOS PAGOS EM ATRASO - AGRUPADO POR CLIENTE BASE
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " WITH C"
    _oSQL:_sQuery += " AS"
    _oSQL:_sQuery += " (SELECT"
    _oSQL:_sQuery += "		SE1.E1_FILIAL AS FILIAL"
    _oSQL:_sQuery += "	   ,SE1.E1_NUM + '/' + SE1.E1_PREFIXO + '/' + SE1.E1_PARCELA AS TITULO"
    _oSQL:_sQuery += "	   ,SE1.E1_TIPO AS TIPO"
    _oSQL:_sQuery += "	   ,SA1.A1_VACBASE + '/' + SA1.A1_VALBASE AS CLIENTE"
    _oSQL:_sQuery += "	   ,SA1.A1_NOME AS NOME"
    _oSQL:_sQuery += "	   ,SE1.E1_EMISSAO AS EMISSAO"
    _oSQL:_sQuery += "	   ,SE1.E1_VENCREA AS VENCREA"
    _oSQL:_sQuery += "	   ,SE1.E1_BAIXA AS BAIXA"
    _oSQL:_sQuery += "	   ,SE1.E1_VALOR AS VALOR"
    _oSQL:_sQuery += "	   ,ISNULL(DATEDIFF(DAY, CAST(SE1.E1_VENCREA AS DATETIME), CAST(SE1.E1_BAIXA AS DATETIME)), 1) AS QDIAS"
    _oSQL:_sQuery += " 	FROM " + RetSQLName ("SE1") + " AS SE1"
    _oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SA1") + " AS SA1"
    _oSQL:_sQuery += "		ON (SA1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "		AND SA1.A1_COD = SE1.E1_CLIENTE"
    _oSQL:_sQuery += "		AND SA1.A1_LOJA = SE1.E1_LOJA)"
    _oSQL:_sQuery += "	WHERE SE1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "		AND SE1.E1_FILIAL BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
    _oSQL:_sQuery += "		AND SE1.E1_TIPO NOT IN (" + alltrim(_sTipo) + ")"
    _oSQL:_sQuery += "		AND SE1.E1_SALDO = 0"
    _oSQL:_sQuery += "		AND SE1.E1_EMISSAO BETWEEN '20030101' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += "		AND SE1.E1_VENCREA BETWEEN '" + DTOS(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += " )"
    _oSQL:_sQuery += " SELECT"
    _oSQL:_sQuery += " 	   CLIENTE"
    _oSQL:_sQuery += "    ,NOME"
    _oSQL:_sQuery += "    ,SUM(VALOR)"
    _oSQL:_sQuery += "    ,SUM(QDIAS) / COUNT(TITULO)"
    _oSQL:_sQuery += " FROM C"
    _oSQL:_sQuery += " WHERE QDIAS > 1"
    _oSQL:_sQuery += " GROUP BY CLIENTE"
    _oSQL:_sQuery += " 		,NOME"
    _oSQL:_sQuery += " ORDER BY NOME"

    _aDadosCli := _oSQL:Qry2Array ()

    oReport:SkipLine(2) 
    oReport:ThinLine()
    oSection2:Init()

    oReport:SkipLine(1) 
    oReport:PrintText(" MÉDIA DE DIAS PAGOS EM ATRASO - POR CLIENTE",,100)

    For i := 1 to Len(_aDadosCli)
        oSection2:Cell("COLUNA1")	:SetBlock   ({|| _aDadosCli[i,1] })
        oSection2:Cell("COLUNA2")	:SetBlock   ({|| _aDadosCli[i,2] })
        oSection2:Cell("COLUNA3")	:SetBlock   ({|| _aDadosCli[i,3] })
        oSection2:Cell("COLUNA4")	:SetBlock   ({|| _aDadosCli[i,4] })

        oSection2:PrintLine()

        _nVlrTCli += _aDadosCli[i,3]
    Next

    oReport:ThinLine()
    oReport:SkipLine(2) 
    _nLinha :=  oReport:Row()
    _nLinha:= _PulaFolha(_nLinha)
    oReport:PrintText("VALOR TOTAL:" ,_nLinha, 100)
    oReport:PrintText(PADL('R$' + Transform(_nVlrTCli, "@E 999,999,999.99"),20,' '),_nLinha, 900)
    oReport:SkipLine(1) 

    // ----------------------------------------------------------------------------------
    // PARAMETROS
    oReport:SkipLine(1)

    oReport:PrintText("PARAMETROS:",, 100)
    oReport:PrintText("     Filial de:" + alltrim(mv_Par01) + " até " + alltrim(mv_Par02),, 100)
    oReport:PrintText("     Dt. vencimento real de:" + DTOC(mv_Par03) + " até " + DTOC(mv_Par04),, 100)
    oReport:PrintText("     Tipos não inclusos:" + alltrim(_sTipo),, 100)
    oReport:PrintText(" **********************************************************************************" ,, 100)
    oReport:PrintText(" Descrição de tipos disponíveis:" ,, 100)
    oReport:PrintText("     CC  CARTAO CREDITO" ,, 100)
    oReport:PrintText("     CD  CARTAO DEBITO " ,, 100)
    oReport:PrintText("     CH  CHEQUE" ,, 100)
    oReport:PrintText("     CO  CONVENIO" ,, 100)
    oReport:PrintText("     DP  DUPLICATA" ,, 100)
    oReport:PrintText("     FTC FATURA DE CLIENTE " ,, 100)
    oReport:PrintText("     NCC NOTA CREDITO CLIENTE" ,, 100)
    oReport:PrintText("     NF  NOTA FISCAL " ,, 100)
    oReport:PrintText("     R$  DINHEIRO (REAL) " ,, 100)
    oReport:PrintText("     RA  RECEBIMENTO ANTECIPADO  " ,, 100)
    oReport:SkipLine(1)
    oReport:ThinLine()

    oSection2:Finish()

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
// --------------------------------------------------------------------------
// Retorna os tipos não inclusos
Static Function RetornaTipo()
    Local _sTipo   := ""
    Local _aTipos  := {}
    Local _aTipos2 := {}
    Local y        := 0

    _aTipos := STRTOKARR(mv_par05,",")

    For y:=1 to Len(_aTipos)
        _sTipo += "'" + alltrim(_aTipos[y]) + "'"
        If y < Len(_aTipos)
            _sTipo += ","
        EndIf
    Next

    _aTipos2 := STRTOKARR(mv_par06,",")

    For y:=1 to Len(_aTipos2)
        _sTipo += ",'" + alltrim(_aTipos2[y]) + "'"
    Next
Return _sTipo
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
    aadd (_aRegsPerg, {05, "Tipo não incluso ", "C", 20, 0,  "",   "   ", {},              "Incluir os tipos que não serão impressos, através de virgula ,"})
    aadd (_aRegsPerg, {06, "Tipo não incluso ", "C", 20, 0,  "",   "   ", {},              "Incluir os tipos que não serão impressos, através de virgula ,"})

    U_ValPerg (cPerg, _aRegsPerg)
Return
