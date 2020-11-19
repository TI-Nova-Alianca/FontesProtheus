// Programa:  VA_MDFeNF
// Autor:     Cláudia Lionço
// Data:      27/01/2020
// Descricao: Listagem de Notas Fiscais e MDF'e correspondentes
//
// Historico de alteracoes:
// 

#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User Function VA_MDFeNF()
	Private oReport
	Private cPerg   := "VA_MDFeNF"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
// --------------------------------------------------------------------------------------------------------------
//
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	Local oSection2:= Nil
	//Local oFunction
	//Local oBreak1
	//Local oBreak2

	oReport := TReport():New("VA_MDFeNF","NFs X MDFe",cPerg,{|oReport| PrintReport(oReport)},"Listagem de Notas Fiscais e MDF'e correspondentes")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	//SESSÃO 1 NOTAS
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	oSection1:SetTotalInLine(.F.)	
	TRCell():New(oSection1,"COLUNA1", 	" ","Data Emissão"	,	    			,12,/*lPixel*/,{||	},"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA2", 	" ","Filial"		,       			,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA3", 	" ","Série"			,    				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA4", 	" ","Número MDF-e"	,					,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA5", 	" ","Chave MDF-e"	,                   ,48,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA6", 	" ","Status"		,					,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA7", 	" ","Vlr.Total"		,"@E 99,999,999.99" ,20,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"COLUNA8", 	" ","Tipo"			,					,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)

	//SESSÃO2 - MDFE's
	oSection2 := TRSection():New(oReport," ",{""}, , , , , ,.T.,.F.,.F.) 
	
	oSection2:SetTotalInLine(.F.)
	TRCell():New(oSection2,"COLUNA1", 	" ","Filial"			,,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA2", 	" ","Série"				,,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA3", 	" ","Documento"			,,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA4", 	" ","Cliente/Fornec."	,,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA5", 	" ","Loja"				,,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA6", 	" ","Dt.Emissão"		,,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA7", 	" ","Chave NF"			,,50,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	
Return(oReport)
// --------------------------------------------------------------------------------------------------------------
//
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local oSection2 := oReport:Section(2)
	Local _oSQL     := NIL
	Local _oSQL1    := NIL
	Local _oSQL2    := NIL
	Local _sAliasQ  := ""
	Local _aDados   := {}
	Local _i        := 1

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " SELECT "
	_oSQL:_sQuery += "	CC0_DTEMIS "
	_oSQL:_sQuery += " ,CC0_FILIAL "
	_oSQL:_sQuery += " ,CC0_SERMDF "
	_oSQL:_sQuery += " ,CC0_NUMMDF "
	_oSQL:_sQuery += " ,CC0_CHVMDF "
    _oSQL:_sQuery += " ,CASE "
	_oSQL:_sQuery += " 		WHEN CC0_STATUS = 1 THEN '1 - Transmitidos' "
	_oSQL:_sQuery += " 		WHEN CC0_STATUS = 2 THEN '2 - Não Transmitidos' "
	_oSQL:_sQuery += " 		WHEN CC0_STATUS = 3 THEN '3 - Autorizados' "
	_oSQL:_sQuery += " 		WHEN CC0_STATUS = 4 THEN '4 - Não Autorizados' "
	_oSQL:_sQuery += " 		WHEN CC0_STATUS = 5 THEN '5 - Cancelados' "
	_oSQL:_sQuery += " 		WHEN CC0_STATUS = 6 THEN '6 - Encerrados' "
	_oSQL:_sQuery += " 		ELSE '' "
	_oSQL:_sQuery += " 	END AS CC0_STATUS "
	_oSQL:_sQuery += " ,CC0_VTOTAL "
	_oSQL:_sQuery += " ,CC0_TPNF "
	_oSQL:_sQuery += " ,CASE "
	_oSQL:_sQuery += " 		WHEN CC0_TPNF = 1 THEN 'NF Saída' "
	_oSQL:_sQuery += " 		WHEN CC0_TPNF = 2 THEN 'NF Entrada' "
	_oSQL:_sQuery += " 		ELSE '' "
	_oSQL:_sQuery += " 	END AS CC0_DESCTP "
	_oSQL:_sQuery += " FROM " + RetSqlName("CC0") + " CC0 " 
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND CC0_FILIAL BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_oSQL:_sQuery += " AND CC0_DTEMIS BETWEEN '" + dtos (mv_par03) + "' and '" + dtos (mv_par04) + "'"
	If !empty(mv_par09)
		_oSQL:_sQuery += " AND CC0_CHVMDF = '" + alltrim(mv_par09)+ "' "
	Else
		_oSQL:_sQuery += " AND CC0_NUMMDF BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
		_oSQL:_sQuery += " AND CC0_SERMDF BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"	
	EndIf
	_oSQL:_sQuery += " ORDER BY CC0_FILIAL, CC0_SERMDF, CC0_NUMMDF "
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	
	While (_sAliasQ)  -> (!Eof())	
		oSection1:Init()	
		
		oSection1:Cell("COLUNA1"):SetValue(STOD((_sAliasQ) -> CC0_DTEMIS))
		oSection1:Cell("COLUNA2"):SetValue((_sAliasQ) -> CC0_FILIAL)		
		oSection1:Cell("COLUNA3"):SetValue((_sAliasQ) -> CC0_SERMDF)	
		oSection1:Cell("COLUNA4"):SetValue((_sAliasQ) -> CC0_NUMMDF)
		oSection1:Cell("COLUNA5"):SetValue((_sAliasQ) -> CC0_CHVMDF)	
		oSection1:Cell("COLUNA6"):SetValue((_sAliasQ) -> CC0_STATUS)	
		oSection1:Cell("COLUNA7"):SetValue((_sAliasQ) -> CC0_VTOTAL)	
		oSection1:Cell("COLUNA8"):SetValue((_sAliasQ) -> CC0_DESCTP)			
		oSection1:Printline()
		
		If (_sAliasQ) -> CC0_TPNF == '1'  // SAIDAS
			_oSQL1 := ClsSQL ():New ()
			_oSQL1:_sQuery := " SELECT "
			_oSQL1:_sQuery += "		F2_FILIAL "
			_oSQL1:_sQuery += "	   ,F2_SERIE "
			_oSQL1:_sQuery += "	   ,F2_DOC "
			_oSQL1:_sQuery += "	   ,F2_CLIENTE "
			_oSQL1:_sQuery += "	   ,F2_LOJA "
			_oSQL1:_sQuery += "	   ,F2_EMISSAO "
			_oSQL1:_sQuery += "	   ,F2_CHVNFE "
			_oSQL1:_sQuery += "	FROM " + RetSqlName("SF2") + " SF2 "  
			_oSQL1:_sQuery += "	WHERE D_E_L_E_T_ = '' "
			_oSQL1:_sQuery += "	AND F2_FILIAL = '" + (_sAliasQ) -> CC0_FILIAL + "' "
			_oSQL1:_sQuery += "	AND F2_NUMMDF = '" + (_sAliasQ) -> CC0_NUMMDF + "' "
			_oSQL1:_sQuery += "	AND F2_SERMDF = '" + (_sAliasQ) -> CC0_SERMDF + "' "
			_aDados := aclone (_oSQL1:Qry2Array ())
		Else 							// ENTRADAS
			_oSQL2 := ClsSQL ():New ()
			_oSQL2:_sQuery := " SELECT "
			_oSQL2:_sQuery += "		F1_FILIAL "
			_oSQL2:_sQuery += "	   ,F1_SERIE "
			_oSQL2:_sQuery += "	   ,F1_DOC "
			_oSQL2:_sQuery += "	   ,F1_FORNECE "
			_oSQL2:_sQuery += "	   ,F1_LOJA "
			_oSQL2:_sQuery += "	   ,F1_EMISSAO "
			_oSQL2:_sQuery += "	   ,F1_CHVNFE "
			_oSQL2:_sQuery += "	FROM " + RetSqlName("SF1") + " SF1 "  
			_oSQL2:_sQuery += "	WHERE D_E_L_E_T_ = '' "
			_oSQL2:_sQuery += "	AND F1_FILIAL = '" + (_sAliasQ) -> CC0_FILIAL + "' "
			_oSQL2:_sQuery += "	AND F1_NUMMDF = '" + (_sAliasQ) -> CC0_NUMMDF + "' "
			_oSQL2:_sQuery += "	AND F1_SERMDF = '" + (_sAliasQ) -> CC0_SERMDF + "' "
			_aDados := aclone (_oSQL2:Qry2Array ())
		EndIf
		
		oSection2:Init()
		For _i:=1 to Len(_aDados)
		
			oSection2:Cell("COLUNA1"):SetValue(_aDados[_i,1])
			oSection2:Cell("COLUNA2"):SetValue(_aDados[_i,2])		
			oSection2:Cell("COLUNA3"):SetValue(_aDados[_i,3])
			oSection2:Cell("COLUNA4"):SetValue(_aDados[_i,4])
			oSection2:Cell("COLUNA5"):SetValue(_aDados[_i,5])	
			oSection2:Cell("COLUNA6"):SetValue(_aDados[_i,6])
			oSection2:Cell("COLUNA7"):SetValue(_aDados[_i,7])			
			oSection2:Printline()
		Next
		oReport:PrintText(" " ,,50)
		oSection2:Finish() 

	(_sAliasQ) -> (dbskip ())
	EndDo
	oSection1:Finish()
Return
// -------------------------------------------------------------------------------------------------------------------------
// Perguntas relatório
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                   TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Filial de               ", "C", 2, 0,  "",  "SM0", {},                         ""})
    aadd (_aRegsPerg, {02, "Filial até              ", "C", 2, 0,  "",  "SM0", {},                         ""})
    aadd (_aRegsPerg, {03, "Data de emissão de      ", "D", 8, 0,  "",  "   ", {},                         ""})
    aadd (_aRegsPerg, {04, "Data de emissão até     ", "D", 8, 0,  "",  "   ", {},                         ""})
    aadd (_aRegsPerg, {05, "Número MDF-e de         ", "C", 9, 0,  "",  "CC0", {},                         ""})
	aadd (_aRegsPerg, {06, "Número MDF-e até        ", "C", 9, 0,  "",  "CC0", {},                         ""})
	aadd (_aRegsPerg, {07, "Série MDF-e de   		", "C", 3, 0,  "",  "CC0", {},                         ""})
    aadd (_aRegsPerg, {08, "Série MDF-e até  		", "C", 3, 0,  "",  "CC0", {},                         ""})
    aadd (_aRegsPerg, {09, "Chave MDF-e   		    ", "C",44, 0,  "",  "   ", {},                         ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
