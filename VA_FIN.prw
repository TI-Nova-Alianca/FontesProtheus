// Programa.: VA_FIN
// Autor....: Cláudia Lionço
// Data.....: 16/11/2021
// Descricao: Relatorio Financeiro de vendas
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------
#include 'protheus.ch'
#include "totvs.ch"

User function VA_FIN()
	Private oReport
	Private cPerg   := "VA_FIN"
	
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

	oReport := TReport():New("VA_FIN","Relatorio Financeiro",cPerg,{|oReport| PrintReport(oReport)},"Relatorio Financeiro")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Título"		,	    				    ,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Cliente"		,       				    ,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Nome"		    ,       				    ,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"CNPJ/CPF"		,						    ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Endereço"	    ,	    				    ,45,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA6", 	"" ,"Municipio"	    ,	    				    ,20,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA7", 	"" ,"UF"	        ,	    				    ,05,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA8", 	"" ,"Banco"	        ,	    				    ,20,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA9", 	"" ,"Emissão"	    ,	    				    ,16,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"Vencimento"	,	    				    ,16,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA11", 	"" ,"Valor"	        , "@E 999,999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
    Local _aTotais  := {}
    Local _x        := 0
    Local _nTotQtd  := 0
    Local _nTotVlr  := 0

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT
    _oSQL:_sQuery += " 	   SE1.E1_NUM + '/' + SE1.E1_PREFIXO + '  ' + SE1.E1_PARCELA AS TITULO"
    _oSQL:_sQuery += "    ,SF2.F2_CLIENTE + '-' + F2_LOJA AS CLIENTE"
    _oSQL:_sQuery += "    ,SA1.A1_NOME AS NOME_CLIENTE"
    _oSQL:_sQuery += "    ,SA1.A1_CGC AS CGC"
    _oSQL:_sQuery += "    ,SA1.A1_END AS ENDERECO"
    _oSQL:_sQuery += "    ,SA1.A1_MUN AS MUNICIPIO"
    _oSQL:_sQuery += "    ,SA1.A1_EST AS UF"
    _oSQL:_sQuery += "    ,CASE"
    _oSQL:_sQuery += " 		WHEN SE1.E1_PORT2 <> '   ' THEN LTRIM(SE1.E1_PORT2)"
    _oSQL:_sQuery += " 		ELSE LTRIM(SC5.C5_BANCO)"
    _oSQL:_sQuery += " 	END AS BANCO"
    _oSQL:_sQuery += "    ,SE1.E1_NUMBCO AS NUMBCO"
    _oSQL:_sQuery += "    ,SF2.F2_EMISSAO AS EMISSAO"
    _oSQL:_sQuery += "    ,SE1.E1_VENCTO AS VENCIMENTO"
    _oSQL:_sQuery += "    ,SE1.E1_VALOR AS VALOR"
    _oSQL:_sQuery += " FROM  " + RetSQLName ("SE1") + " SE1 "
    _oSQL:_sQuery += " INNER JOIN  " + RetSQLName ("SF2") + " SF2 "
    _oSQL:_sQuery += " 	ON (SF2.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " 			AND SF2.F2_FILIAL   = '" + xfilial ("SF2") + "'"
    _oSQL:_sQuery += " 			AND SF2.F2_DOC      = SE1.E1_NUM"
    _oSQL:_sQuery += " 			AND SF2.F2_SERIE    = SE1.E1_PREFIXO"
    _oSQL:_sQuery += " 			AND SF2.F2_ESPECIE != 'CF')"
    _oSQL:_sQuery += " INNER JOIN  " + RetSQLName ("SA1") + " SA1 "
    _oSQL:_sQuery += " 	ON (SA1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " 			AND SA1.A1_FILIAL = '" + xfilial ("SA1") + "'"
    _oSQL:_sQuery += " 			AND SA1.A1_COD    = SF2.F2_CLIENTE"
    _oSQL:_sQuery += " 			AND SA1.A1_LOJA   = SF2.F2_LOJA"
    _oSQL:_sQuery += " 			AND SA1.A1_VACBASE BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
    _oSQL:_sQuery += " 		)"
    _oSQL:_sQuery += " LEFT JOIN  " + RetSQLName ("SC5") + " SC5 "
    _oSQL:_sQuery += " 	ON (SC5.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " 			AND SC5.C5_FILIAL = '" + xfilial ("SC5") + "'"
    _oSQL:_sQuery += " 			AND SC5.C5_NOTA   = SF2.F2_DOC"
    _oSQL:_sQuery += " 			AND SC5.C5_SERIE  = SF2.F2_SERIE"
    If !empty(mv_par07)
        _oSQL:_sQuery += " 			AND SC5.C5_BANCO = '" + mv_par07 + "' "
    EndIf
    _oSQL:_sQuery += " 		)"
    _oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " AND SE1.E1_FILIAL    = '" + xfilial ("SE1") + "'"
    _oSQL:_sQuery += " AND SE1.E1_NUM BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
    _oSQL:_sQuery += " AND SE1.E1_EMISSAO BETWEEN '" + dtos(mv_par01) + "' AND '" + dtos(mv_par02) + "'"
    _oSQL:_sQuery += " AND SE1.E1_PREFIXO IN ('10', 'TRS') "
    _oSQL:_sQuery += " AND SE1.E1_TIPO != 'NCC' "
    _oSQL:_sQuery += " ORDER BY E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO "
    u_log(_oSQL:_sQuery)
    
    dbUseArea(.T., "TOPCONN", TCGenQry(,,_oSQL:_sQuery), "TRA", .F., .T.)
	TRA->(DbGotop())
	
	oSection1:Init()
	oSection1:SetHeaderSection(.T.)
			
	While TRA->(!Eof())	
        _sBanco := TRA->BANCO + "-" + TRA->NUMBCO

        oSection1:Cell("COLUNA1")	:SetBlock   ({|| TRA->TITULO  	        })
        oSection1:Cell("COLUNA2")	:SetBlock   ({|| TRA->CLIENTE 	        })
        oSection1:Cell("COLUNA3")	:SetBlock   ({|| TRA->NOME_CLIENTE	    })
        oSection1:Cell("COLUNA4")	:SetBlock   ({|| TRA->CGC   	        })
        oSection1:Cell("COLUNA5")	:SetBlock   ({|| TRA->ENDERECO          })
        oSection1:Cell("COLUNA6")	:SetBlock   ({|| TRA->MUNICIPIO 	    })
        oSection1:Cell("COLUNA7")	:SetBlock   ({|| TRA->UF 	            })
        oSection1:Cell("COLUNA8")	:SetBlock   ({|| _sBanco  	            })
        oSection1:Cell("COLUNA9")	:SetBlock   ({|| STOD(TRA->EMISSAO)     })
        oSection1:Cell("COLUNA10")	:SetBlock   ({|| STOD(TRA->VENCIMENTO)  })
        oSection1:Cell("COLUNA11")	:SetBlock   ({|| TRA->VALOR 	        })

		oSection1:PrintLine()
		
		DBSelectArea("TRA")
		dbskip()
	Enddo
	oSection1:Finish()
	TRA->(DbCloseArea())

    // Totalizadores
    _oSQL:_sQuery := " WITH C "
    _oSQL:_sQuery += " AS "
    _oSQL:_sQuery += " ( "
    _oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += "	  CASE "
	_oSQL:_sQuery += "		    WHEN SE1.E1_PORT2 <> '   ' THEN LTRIM(SE1.E1_PORT2) "
	_oSQL:_sQuery += "		    ELSE LTRIM(SC5.C5_BANCO) "
	_oSQL:_sQuery += "	  END AS BANCO "
	_oSQL:_sQuery += "   ,SE1.E1_NUM AS TITULO "
	_oSQL:_sQuery += "   ,SE1.E1_VALOR AS VALOR "
    _oSQL:_sQuery += " FROM  " + RetSQLName ("SE1") + " SE1 "
    _oSQL:_sQuery += " INNER JOIN  " + RetSQLName ("SF2") + " SF2 "
    _oSQL:_sQuery += " 	ON (SF2.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " 			AND SF2.F2_FILIAL   = '" + xfilial ("SF2") + "'"
    _oSQL:_sQuery += " 			AND SF2.F2_DOC      = SE1.E1_NUM"
    _oSQL:_sQuery += " 			AND SF2.F2_SERIE    = SE1.E1_PREFIXO"
    _oSQL:_sQuery += " 			AND SF2.F2_ESPECIE != 'CF')"
    _oSQL:_sQuery += " INNER JOIN  " + RetSQLName ("SA1") + " SA1 "
    _oSQL:_sQuery += " 	ON (SA1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " 			AND SA1.A1_FILIAL = '" + xfilial ("SA1") + "'"
    _oSQL:_sQuery += " 			AND SA1.A1_COD    = SF2.F2_CLIENTE"
    _oSQL:_sQuery += " 			AND SA1.A1_LOJA   = SF2.F2_LOJA"
    _oSQL:_sQuery += " 			AND SA1.A1_VACBASE BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
    _oSQL:_sQuery += " 		)"
    _oSQL:_sQuery += " LEFT JOIN  " + RetSQLName ("SC5") + " SC5 "
    _oSQL:_sQuery += " 	ON (SC5.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " 			AND SC5.C5_FILIAL = '" + xfilial ("SC5") + "'"
    _oSQL:_sQuery += " 			AND SC5.C5_NOTA   = SF2.F2_DOC"
    _oSQL:_sQuery += " 			AND SC5.C5_SERIE  = SF2.F2_SERIE"
    If !empty(mv_par07)
        _oSQL:_sQuery += " 			AND SC5.C5_BANCO = '" + mv_par07 + "' "
    EndIf
    _oSQL:_sQuery += " 		)"
    _oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " AND SE1.E1_FILIAL    = '" + xfilial ("SE1") + "'"
    _oSQL:_sQuery += " AND SE1.E1_NUM BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
    _oSQL:_sQuery += " AND SE1.E1_EMISSAO BETWEEN '" + dtos(mv_par01) + "' AND '" + dtos(mv_par02) + "'"
    _oSQL:_sQuery += " AND SE1.E1_PREFIXO IN ('10', 'TRS') "
    _oSQL:_sQuery += " AND SE1.E1_TIPO != 'NCC' )"
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   BANCO "
    _oSQL:_sQuery += "    ,COUNT(TITULO) AS QTD "
    _oSQL:_sQuery += "    ,SUM(VALOR) AS TOTAL "
    _oSQL:_sQuery += " FROM C "
    _oSQL:_sQuery += " GROUP BY BANCO "
    u_log(_oSQL:_sQuery)
    _aTotais := aclone(_oSQL:Qry2Array())

    oReport:ThinLine()
    oReport:SkipLine(1)
    oReport:SkipLine(1)
    _nLinha:= _PulaFolha(_nLinha)
    oReport:PrintText("*** TOTAIS POR BANCO:" ,, 100)

    For _x := 1 to Len(_aTotais)
        _nLinha:= _PulaFolha(_nLinha)
        oReport:PrintText("Banco:"        + _aTotais[_x, 1] ,, 100)
        oReport:PrintText("Qtd. Títulos:" + alltrim(str(_aTotais[_x, 2])) ,, 100)
        oReport:PrintText("Valor Total :" + PADL('R$' + Transform(_aTotais[_x, 3], "@E 999,999,999.99"),20,' ') ,, 100)
        oReport:SkipLine(1)
        oReport:ThinLine()
        oReport:SkipLine(1)
        
        _nTotQtd += _aTotais[_x, 2]
        _nTotVlr += _aTotais[_x, 3]
    Next

    _nLinha:= _PulaFolha(_nLinha)
    oReport:PrintText("Total de Títulos:" + alltrim(str(_nTotQtd)) ,, 100)
    oReport:PrintText("Total Geral :" + PADL('R$' + Transform(_nTotVlr, "@E 999,999,999.99"),20,' ') ,, 100)
    oReport:SkipLine(1)
    oReport:ThinLine()
    oReport:SkipLine(1)
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
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aTamDoc   := aclone(TamSX3("D2_DOC"))
	
	//                     PERGUNT                           TIPO TAM                    DEC  VALID  F3      Opcoes Help
	aadd (_aRegsPerg, {01, "Data de emissao de            ", "D", 8,                       0,  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {02, "Data de emissao ate           ", "D", 8,                       0,  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {03, "N.F. Inicial                  ", "C", _aTamDoc [1], _aTamDoc [2],  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {04, "N.F. Final                    ", "C", _aTamDoc [1], _aTamDoc [2],  "",   "   ",  {},    ""})
    aadd (_aRegsPerg, {05, "Cod.Base de                   ", "C", 06,                      0,  "",   "SA1RED",  {},    ""})
    aadd (_aRegsPerg, {06, "Cod.Base ate                  ", "C", 06,                      0,  "",   "SA1RED",  {},    ""})
    aadd (_aRegsPerg, {07, "Banco                         ", "C", 03,                      0,  "",   "   ",  {},    ""})

	U_ValPerg (cPerg, _aRegsPerg, {})
Return

