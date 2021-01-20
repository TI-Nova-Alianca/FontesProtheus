//  Programa...: VA_CLISTIT
//  Autor......: Cláudia Lionço
//  Data.......: 20/01/2021
//  Descricao..: Relatório de títulos vencidos - Sintético
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de títulos vencidos - Sintético
// #PalavasChave      #titulos_vencidos #clientes_inadimplentes
// #TabelasPrincipais #SE1 
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include "totvs.ch"

User Function VA_CLISTIT()
	Private oReport
	Private cPerg := "VA_CLISTIT"
	
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

    oReport := TReport():New("VA_CLISTIT","Títulos em atraso - Sintético",cPerg,{|oReport| PrintReport(oReport)},"Títulos em atraso - Sintético")
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    				,08,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA2", 	"" ,"Valor"	        , "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Saldo"	        , "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1   := oReport:Section(1)	
    Local _aDados := {}
    Local _aTipos     := {}
    Local _sTipo      := ""
    Local i           := 0
    Local Y           := 0
    Local _nVlrTotal  := 0
    Local _nVlrSaldo  := 0

    _aTipos := STRTOKARR(mv_par05,";")

    For y:=1 to Len(_aTipos)
        _sTipo += "'" + alltrim(_aTipos[y]) + "'"
        If y < Len(_aTipos)
            _sTipo += ","
        EndIf
    Next

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
    _oSQL:_sQuery += "		   ,ISNULL(DATEDIFF(DAY, CAST(SE1.E1_VENCREA AS DATETIME), CAST('" + dtos(mv_par04) + "' AS DATETIME)), 1) AS QDIAS"
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
    _oSQL:_sQuery += "	SELECT"
    _oSQL:_sQuery += "		FILIAL"
    _oSQL:_sQuery += "	   ,SUM(VALOR)"
    _oSQL:_sQuery += "	   ,SUM(SALDO)"
    _oSQL:_sQuery += "	FROM C"
    _oSQL:_sQuery += "	WHERE QDIAS > 0"
    _oSQL:_sQuery += "	GROUP BY FILIAL"
    
    _aDados := _oSQL:Qry2Array ()

    oSection1:Init()

    For i := 1 to Len(_aDados)
        oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[i,1] })
        oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aDados[i,2] })
        oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aDados[i,3] })

        oSection1:PrintLine()

        _nVlrTotal += _aDados[i,2]
        _nVlrSaldo += _aDados[i,3]
    Next

    oReport:ThinLine()

    _nLinha :=  oReport:Row()
    _nLinha:= _PulaFolha(_nLinha)
    oReport:PrintText("VALOR TOTAL DOS TITULOS:" ,_nLinha, 100)
    oReport:PrintText(PADL('R$' + Transform(_nVlrTotal, "@E 999,999,999.99"),20,' '),_nLinha, 900)
    oReport:SkipLine(1) 
    oReport:ThinLine()

    _nLinha :=  oReport:Row()
    _nLinha:= _PulaFolha(_nLinha)
    oReport:PrintText("SALDO TOTAL EM ATRASO:" ,_nLinha, 100)
    oReport:PrintText(PADL('R$' + Transform(_nVlrSaldo, "@E 999,999,999.99"),20,' '),_nLinha, 900)
    oReport:SkipLine(1) 
    oReport:ThinLine()

    oSection1:Finish()

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
    aadd (_aRegsPerg, {01, "Filial de        ", "C",  2, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Filial ate       ", "C",  2, 0,  "",   "   ", {},                        		 ""})
    aadd (_aRegsPerg, {03, "Dt.Venc.real de  ", "D",  8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {04, "Dt.Venc.real até ", "D",  8, 0,  "",   "   ", {},                        		 ""})
    aadd (_aRegsPerg, {05, "Tipo não incluso ", "C", 20, 0,  "",   "   ", {},                        		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
