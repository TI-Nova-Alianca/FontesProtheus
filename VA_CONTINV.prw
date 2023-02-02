// Programa.: VA_CONTINV
// Autor....: Cláudia Lionço
// Data.....: 20/03/2020
// Descricao: Formulário para contagem de inventário. GLPI:7695
//
// Historico de alteracoes:
// 22/04/2020 - Cláudia - Alterado cabeçalho para padrão
// 12/02/2021 - Cláudia - Incluida ordenação pela descrição
// 02/06/2021 - Claudia - Alterada ordenação almox/ites. GLPI: 10146
// 30/01/2023 - Claudia - Incluidos novos filtros. GLPI: 13101
// 02/02/2023 - Claudia - Incluida ordenação por endereco. GLPI: 13136
//
// ---------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_CONTINV()
	Private oReport
	Private cPerg   := "VA_CONTINV"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// -------------------------------------------------------------------------
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
 
	oReport := TReport():New("VA_CONTINV","Formulário para contagem de inventário",cPerg,{|oReport| PrintReport(oReport)},"Formulário para contagem de inventário",,,,,,,-2)

	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	oReport:SetLineHeight(50)
	oReport:cFontBody := "Arial"
	oReport:nFontBody := 10
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"	,	    				,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Almox"		,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Tipo"		,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Endereço"	,						,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Item"		,						,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Descrição"	,						,70,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Contagem"	,						,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	
Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local _aDados   := {}
	Local _i        := 0

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	   SB7.B7_FILIAL AS FILIAL"
	_oSQL:_sQuery += "    ,SB7.B7_LOCAL AS ALMOX"
	_oSQL:_sQuery += "    ,SB7.B7_TIPO AS TIPO"
	_oSQL:_sQuery += "    ,SB7.B7_LOCALIZ AS ENDERECO"
	_oSQL:_sQuery += "    ,SB7.B7_COD AS ITEM"
	_oSQL:_sQuery += "    ,SB1.B1_DESC AS DESCRICAO"
	_oSQL:_sQuery += "    ,'' AS CONTAGEM"
	_oSQL:_sQuery += " FROM SB7010 SB7"
	_oSQL:_sQuery += " INNER JOIN SB1010 SB1"
	_oSQL:_sQuery += " 	ON (SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND SB1.B1_COD = SB7.B7_COD "
	If !empty(mv_par10)
		_oSQL:_sQuery += " 	AND SB1.B1_GRUPO BETWEEN '" + mv_par10 + "' AND '" + mv_par11 + "' "
	EndIf
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += " WHERE SB7.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SB7.B7_CONTAGE = '1'"
	_oSQL:_sQuery += " AND SB7.B7_FILIAL ='" + mv_par04 + "'"
	_oSQL:_sQuery += " AND SB7.B7_DATA BETWEEN '" + DTOS(mv_par01) + "' AND '" + DTOS(mv_par02) + "'"
	_oSQL:_sQuery += " AND SB7.B7_DOC = '" + DTOS(mv_par03) + "' "
	_oSQL:_sQuery += " AND SB7.B7_LOCAL BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_oSQL:_sQuery += " AND SB7.B7_TIPO BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
	If !empty(mv_par12)
		_oSQL:_sQuery += " AND SB7.B7_LOCALIZ BETWEEN '"+ mv_par12 +"' AND '"+ mv_par13 +"' ""
	EndIf
	Do Case
		Case mv_par09 == 1
			_oSQL:_sQuery += " ORDER BY FILIAL, ALMOX, ITEM"
		Case mv_par09 == 2
			_oSQL:_sQuery += " ORDER BY FILIAL, ALMOX, TIPO, ENDERECO"
		Case mv_par09 == 3
			_oSQL:_sQuery += " ORDER BY FILIAL, DESCRICAO"
		Case mv_par09 == 4
			_oSQL:_sQuery += " ORDER BY FILIAL, ALMOX, TIPO, DESCRICAO"
		Case mv_par09 == 5
			_oSQL:_sQuery += " ORDER BY FILIAL, ENDERECO, TIPO"
			
	EndCase
	_oSQL:Log ()
	
	_aDados := aclone (_oSQL:Qry2Array (.t.,.t.))
	
	_Almox :=""
	For _i:= 2 to len(_aDados)
		
		If AllTrim(_Almox) <> _aDados[_i,2]
			If _i <> 2 
				oSection1:Finish()
				oReport:EndPage()
			EndIf
			oReport:PrintText("",,100)
			oReport:PrintText("Inventário realizado em:____________________________________",,100)
			oReport:PrintText("",,100)
			oReport:PrintText("Ass responsável:_________________________________________",,100)
			oReport:PrintText("",,100)
			
			oSection1:Init()
			oSection1:SetHeaderSection(.T.)
		EndIf
		
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[_i,1]		})
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aDados[_i,2]		})
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aDados[_i,3]		})
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aDados[_i,4]		})
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aDados[_i,5]		})
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aDados[_i,6]		})
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aDados[_i,7]		})
		
		oSection1:PrintLine()
		
		oReport:FatLine()
		
		_Almox := _aDados[_i,2]	
	Next
Return
// -------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT            TIPO TAM DEC VALID F3     Opcoes                      												Help
    aadd (_aRegsPerg, {01, "Dt. geração de  ", "D", 8,  0,  "",  "   ", {},                         												""})
    aadd (_aRegsPerg, {02, "Dt. geração até ", "D", 8,  0,  "",  "   ", {},                         												""})
    aadd (_aRegsPerg, {03, "Data doc.       ", "D", 8,  0,  "",  "   ", {},                         												""})
    aadd (_aRegsPerg, {04, "Filial          ", "C", 2,  0,  "",  "SM0", {},                         												""})
    aadd (_aRegsPerg, {05, "Local de      	", "C", 2,  0,  "",  "NNR", {},                         												""})
    aadd (_aRegsPerg, {06, "Local até       ", "C", 2,  0,  "",  "NNR", {},                         												""})
    aadd (_aRegsPerg, {07, "Tipo de         ", "C", 2,  0,  "",  "02", {},                         													""})
    aadd (_aRegsPerg, {08, "Tipo até        ", "C", 2,  0,  "",  "02", {},                         													""})
    aadd (_aRegsPerg, {09, "Ordenação       ", "N", 1,  0,  "",  "   ", {"Almox+Item","Tipo+Endereço","Descrição","Tipo+Descrição","Endereco+Tipo"},""})
	aadd (_aRegsPerg, {10, "Grupo de        ", "C", 4,  0,  "",  "SBM", {},    																		""})
	aadd (_aRegsPerg, {11, "Grupo até       ", "C", 4,  0,  "",  "SBM", {},    																		""})
	aadd (_aRegsPerg, {12, "Endereço de     ", "C", 15, 0,  "",  "SBE", {},   												 						""})
	aadd (_aRegsPerg, {13, "Endereço até    ", "C", 15, 0,  "",  "SBE", {},    																		""})

    U_ValPerg (cPerg, _aRegsPerg)
Return

