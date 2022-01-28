//  Programa...: VA_RELOPC
//  Autor......: Cláudia Lionço
//  Descricao..: Relatório de Opcionais
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de Opcionais
// #PalavasChave      #opcionais 
// #TabelasPrincipais #SGA 
// #Modulos 		  #PCP 
//
// Historico de alteracoes:
//
// ------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_RELOPC()
	Private oReport
	Private cPerg   := "VA_RELOPC"
	
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
	
	oReport := TReport():New("VA_RELOPC","Opcionais",cPerg,{|oReport| PrintReport(oReport)},"Opcionais")
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Opcional"	,   ,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Descricao"	,   ,100,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.T.)

Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local _x		:= 0
	Local _i        := 0

    oSection1:Init()
	oSection1:SetHeaderSection(.F.)

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT DISTINCT "
    _oSQL:_sQuery += " 	   GA_GROPC "
    _oSQL:_sQuery += "    ,GA_DESCGRP "
    _oSQL:_sQuery += " FROM " + RetSqlName("SGA")
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND GA_GROPC   BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' "
    _oSQL:_sQuery += " AND GA_VACODOP BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "' "
    _aGrp := aclone (_oSQL:Qry2Array ())

    For _x:=1 to Len(_aGrp)
        _sGrupo := alltrim(_aGrp[_x, 1]) + " - " + _aGrp[_x, 2]

        oReport:PrintText("GRUPO: " +  _sGrupo,, 100)
        oReport:SkipLine(1)

        _oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += " 	   GA_OPC "
        _oSQL:_sQuery += "    ,GA_DESCOPC "
        _oSQL:_sQuery += " FROM " + RetSqlName("SGA")
        _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND GA_GROPC = '" + _aGrp[_x, 1]+ "' "
        _aDados := aclone (_oSQL:Qry2Array ())

        For _i:= 1 to Len(_aDados)
            oSection1:Cell("COLUNA1"):SetBlock ({|| _aDados[_i, 1] }) 
		    oSection1:Cell("COLUNA2"):SetBlock ({|| _aDados[_i, 2] }) 

            oSection1:PrintLine()
        Next
        oReport:SkipLine(1)
    Next
    oSection1:Finish()
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT            TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Grupo de        ", "C", 3, 0,   "",   "   ", {},                        ""})
    aadd (_aRegsPerg, {02, "Grupo ate       ", "C", 3, 0,   "",   "   ", {},                        ""})
    aadd (_aRegsPerg, {03, "Opcional de     ", "C", 15, 0,  "",   "   ", {},                        ""})
    aadd (_aRegsPerg, {04, "Opcional ate    ", "C", 15, 0,  "",   "   ", {},                        ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
