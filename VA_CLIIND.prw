//  Programa...: VA_CLIIND
//  Autor......: Cláudia Lionço
//  Data.......: 22/01/2021
//  Descricao..: Relatório de indice de inadimplencia 
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de indice de inadimplencia 
// #PalavasChave      #titulos_vencidos #clientes_inadimplentes
// #TabelasPrincipais #SE1 
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include "totvs.ch"

User Function VA_CLIIND()
	Private oReport
	Private cPerg := "VA_CLIIND"
	
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

    oReport := TReport():New("VA_CLIIND","Indice de inadimplencia",cPerg,{|oReport| PrintReport(oReport)},"Indice de inadimplencia")
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
    oSection1:SetPageBreak(.T.)
	
    TRCell():New(oSection1,"COLUNA1", 	"" ,"Valor total "	        , "@E 999,999,999.99"   ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA2", 	"" ,"Valor não recebido"	, "@E 999,999,999.99"   ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA3", 	"" ,"% Inadimplencia"	    , "@E 999.99"           ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)	
    Local _aTipos   := {}
    Local _sTipo    := ""
    Local y         := 0

    _aTipos := STRTOKARR(mv_par05,",")

    For y:=1 to Len(_aTipos)
        _sTipo += "'" + alltrim(_aTipos[y]) + "'"
        If y < Len(_aTipos)
            _sTipo += ","
        EndIf
    Next

    // ----------------------------------------------------------------------------------
    //VALOR TOTAL
    _oSQL:= ClsSQL ():New ()

    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT
    _oSQL:_sQuery += " 	    SUM(SE1.E1_VALOR) AS VALOR"
    _oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " AS SE1"
    _oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " AND SE1.E1_FILIAL BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
    _oSQL:_sQuery += " AND SE1.E1_TIPO NOT IN (" + alltrim(_sTipo) + ")"
    _oSQL:_sQuery += " AND SE1.E1_EMISSAO BETWEEN '20030101' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += " AND SE1.E1_VENCREA BETWEEN '" + DTOS(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _aTotal := _oSQL:Qry2Array ()

    If Len(_aTotal) > 0
        _nTotal := _aTotal[1,1]
    Else    
        _nTotal := 0
    EndIf

    // ----------------------------------------------------------------------------------
    // VALOR EM ATRASO
    _oSQL:= ClsSQL ():New ()

    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " WITH C"
    _oSQL:_sQuery += " AS"
    _oSQL:_sQuery += " (SELECT"
    _oSQL:_sQuery += " 		SE1.E1_SALDO AS SALDO"
    _oSQL:_sQuery += " 	   ,ISNULL(DATEDIFF(DAY, CAST(SE1.E1_VENCREA AS DATETIME), CAST('" + dtos(mv_par04) + "' AS DATETIME)), 1) AS QDIAS"
    _oSQL:_sQuery += " 	FROM " + RetSQLName ("SE1") + " AS SE1"
    _oSQL:_sQuery += " 	WHERE SE1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "  AND SE1.E1_FILIAL BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
    _oSQL:_sQuery += "  AND SE1.E1_TIPO NOT IN (" + alltrim(_sTipo) + ")"
    _oSQL:_sQuery += "  AND SE1.E1_EMISSAO BETWEEN '20030101' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += "  AND SE1.E1_VENCREA BETWEEN '" + DTOS(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += " 	AND SE1.E1_SALDO > 0"
    _oSQL:_sQuery += " )"
    _oSQL:_sQuery += " SELECT"
    _oSQL:_sQuery += " 	SUM(SALDO)"
    _oSQL:_sQuery += " FROM C"
    _aAtr := _oSQL:Qry2Array ()

    If Len(_aAtr) > 0
        _nAtr := _aAtr[1,1]
    Else    
        _nAtr := 0
    EndIf

    oSection1:Init()
    _nPerc := ROUND((_nAtr * 100)/_nTotal,2)

    oSection1:Cell("COLUNA1")	:SetBlock   ({|| _nTotal })
    oSection1:Cell("COLUNA2")	:SetBlock   ({|| _nAtr   })
    oSection1:Cell("COLUNA3")	:SetBlock   ({|| _nPerc  })

    oSection1:PrintLine()
    oSection1:Finish()

    // ----------------------------------------------------------------------------------
    // PARAMETROS
    oReport:ThinLine()
    oReport:SkipLine(1)
    oReport:PrintText("PARAMETROS UTILIZADOS:",, 100)
    oReport:PrintText("     Filial de:" + alltrim(mv_Par01) + " até " + alltrim(mv_Par02),, 100)
    oReport:PrintText("     Dt. vencimento real de:" + DTOC(mv_Par03) + " até " + DTOC(mv_Par04),, 100)
    oReport:PrintText("     Tipos não inclusos:" + alltrim(mv_Par05) ,, 100)
    oReport:PrintText(" **********************************************************************************" ,, 100)
    oReport:PrintText(" Descrição de tipos disponíveis:" ,, 100)
    oReport:PrintText("     CC  CARTAO CREDITO" ,, 100)
    oReport:PrintText("     CD  CARTAO DEBITO " ,, 100)
    oReport:PrintText("     CH  CHEQUE" ,, 100)
    oReport:PrintText("     CO  CONVENIO" ,, 100)
    oReport:PrintText("     DP  DUPLICATA" ,, 100)
    oReport:PrintText("     FTC FATURA DE CLIENTE " ,, 100)
    oReport:PrintText("     NCC NOTA CREDITO CLIENTE" ,, 100)
    oReport:PrintText("     NF  Nota Fiscal " ,, 100)
    oReport:PrintText("     R$  DINHEIRO (REAL) " ,, 100)
    oReport:PrintText("     RA  RECEBIMENTO ANTECIPADO  " ,, 100)
    oReport:SkipLine(1)
    oReport:ThinLine()

Return
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

    U_ValPerg (cPerg, _aRegsPerg)
Return
