// Programa..: ML_VALEASOC
// Autor.....: Sandra Sugari
// Data......: 17/02/2021
// Nota......: Vales Presentes Associados 
//
// Historico de alteracoes:
// 
// 17/02/2021 - Sandra  - Associação dos vales aos associados GLPI 9329.
// 08/03/2021 - Cláudia - Incluida coluna e parametro de status. GLPI 9571
// 08/03/2021 - Claudia - Ajuste da nomenclatura "cod. associado" para "cod cliente".
// 30/04/2021 - Sandra  - Ajuste para ordenar por codigo do vale.
//
// ------------------------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User function ML_VALEASOC()
	Private oReport
	Private cPerg   := "ML_VALEASOC"
	
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

	oReport := TReport():New("ML_VALEASOC","Vales Presentes Vinculados a Associados ",cPerg,{|oReport| PrintReport(oReport)},"Vales Presentes Vinculados a Associados ")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Cód.Cliente"   ,	    				, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Associado"		,       				,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Loja"			,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Nº Vale"   	,						,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Vlr Vale"		, "@E 999,999,999.99"   ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Ini Vigência"	,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA7", 	"" ,"Fim Vigência"	,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Status"		,       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	
Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local _oSQL      := ClsSQL ():New ()

	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	   MDD_CLIV AS COD_ASSOCIADO"
	_oSQL:_sQuery += "    ,A1_NOME AS NOME"
	_oSQL:_sQuery += "    ,MDD_LJCLIV AS LOJA"
	_oSQL:_sQuery += "    ,MDD_CODIGO AS N_VALE"
	_oSQL:_sQuery += "    ,MDD_VALOR AS VALOR"
	_oSQL:_sQuery += "    ,MDD_DTINI AS INI_VIGENCIA"  
	_oSQL:_sQuery += "    ,MDD_DTFIM AS FIM_VIGENCIA"
	_oSQL:_sQuery += "    ,MDD_STATUS AS STATUS"
	_oSQL:_sQuery += " FROM MDD010, SA1010 " 
	_oSQL:_sQuery += " WHERE MDD_CLIV = A1_COD "
    _oSQL:_sQuery += " AND MDD_LJCLIV = A1_LOJA "
	_oSQL:_sQuery += " AND MDD_DTINI >= '" + dtos (MV_PAR01) + "'"
	_oSQL:_sQuery += " AND MDD_DTFIM <= '" + dtos (MV_PAR02) + "'"
	_oSQL:_sQuery += " AND MDD_CLIV BETWEEN '" + mv_par03 + "' AND '" + mv_par05 + "'"
	_oSQL:_sQuery += " AND MDD_CODIGO BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
	_oSQL:_sQuery += " AND MDD_LJCLIV BETWEEN '" + mv_par04 + "' AND '" + mv_par06 + "'"
    _oSQL:_sQuery += " AND MDD010.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND SA1010.D_E_L_E_T_ = '' "
	//_oSQL:_sQuery += " ORDER BY MDD_CODIGO "
	Do Case 
		Case mv_par09 == 2
			_oSQL:_sQuery += " AND MDD_STATUS = '1' "
		Case mv_par09 == 3
			_oSQL:_sQuery += " AND MDD_STATUS = '2' "
		Case mv_par09 == 4
			_oSQL:_sQuery += " AND MDD_STATUS = '3' "
		Case mv_par09 == 5
			_oSQL:_sQuery += " AND MDD_STATUS = '4' "
	EndCase 
	_oSQL:_sQuery += " ORDER BY MDD_CODIGO "

	// nHandle := FCreate("c:\temp\log.txt")
	// FWrite(nHandle, _oSQL:_sQuery )
	// FClose(nHandle)

	_sAliasQ := _oSQL:Qry2Trb (.f.)
	(_sAliasQ) -> (dbgotop ())
	
	oSection1:Init()
	oSection1:SetHeaderSection(.T.)
			
	While !(_sAliasQ) -> (eof ())
		
		_sCodStatus := (_sAliasQ) -> status 
		Do Case
			Case _sCodStatus == '1'
				_sStatus := "Ativo"
			Case _sCodStatus == '2'
				_sStatus := "Vendido"
			Case _sCodStatus == '3'
				_sStatus := "Recebido"
			Case _sCodStatus == '4'
				_sStatus := "Inativo"
		EndCase

		oSection1:Cell("COLUNA1")	:SetBlock   ({|| (_sAliasQ) -> Cod_Associado   	})
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| (_sAliasQ) -> Nome     		})
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| (_sAliasQ) -> Loja      		})
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| (_sAliasQ) -> N_Vale       	})
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| (_sAliasQ) -> Valor    	    })
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| Stod((_sAliasQ)-> Ini_Vigencia)})
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| Stod((_sAliasQ)-> Fim_Vigencia)})
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| _sStatus                	    })

		oSection1:PrintLine()
		
		(_sAliasQ) -> (dbskip ())
	Enddo
	oSection1:Finish()
	(_sAliasQ) -> (dbclosearea ())
Return
//
// -------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                      TIPO TAM DEC VALID F3     Opcoes                      				Help
	aadd (_aRegsPerg, {01, "Vigencia INI            ?", "D", 8, 0,  "",  "   ", {},                         						""})
    aadd (_aRegsPerg, {02, "Vigencia Final          ?", "D", 8, 0,  "",  "   ", {},                         						""})
    aadd (_aRegsPerg, {03, "Associado de            ?", "C",11, 0,  "",  "SA1", {},                         						"Associado Inicial"})
	aadd (_aRegsPerg, {04, "Filial Associado de     ?", "C", 2, 0,  "",  "SA1", {},                         						""})
    aadd (_aRegsPerg, {05, "Associado até           ?", "C",11, 0,  "",  "SA1", {},                         						"Associado Final"})
    aadd (_aRegsPerg, {06, "Filial Associado até    ?", "C", 2, 0,  "",  "SA1", {},                         						""})
    aadd (_aRegsPerg, {07, "Vale de                 ?", "C", 7, 0,  "",  "MDD", {},                         						""})
    aadd (_aRegsPerg, {08, "Vale Até                ?", "C", 7, 0,  "",  "MDD", {},                         						""})
	aadd (_aRegsPerg, {09, "Status                  ?", "N", 1, 0,  "",  "   ", { "Todos", "Ativo","Vendido","Recebido","Inativo"},  ""})

     U_ValPerg (cPerg, _aRegsPerg)
Return
