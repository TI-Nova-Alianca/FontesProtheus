// Programa..: VA_FINVEN
// Autor.....: Claudia Lionço
// Data......: 28/08/2024
// Descricao.: Relatorio Financeiro de vendas
// 
// #TipoDePrograma    #relatorio
// #Descricao         Relatorio Financeiro de Vendas
// #PalavasChave      #vendas #titulos #vendas 
// #TabelasPrincipais #SE1 #SF2 #SA1 #SC5
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
// 28/08/2024 - Claudia - Relatorio baseado no relatorio ML_FIN.prw.
//                        Alterado modelo de relatorio e retirado coluna de cidade/estado. GLPI: 15918
//
// ------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_FINVEN()
	Private oReport
	Private cPerg := "VA_FINVEN"
	
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
	Local oBreak1

	oReport := TReport():New("VA_FINVEN","Relatorio Financeiro de Vendas",cPerg,{|oReport| PrintReport(oReport)},"Relatório Financeiro de Vendas")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Título"		,	    					,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Cliente"		,       					,70,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Num.Banco"		,       					,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA4", 	"" ,"Emissão"		,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Vencto "	    ,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Valor"	        , "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Cod.Bco"		,       					,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    
    //oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA0"),"Total")
    TRFunction():New(oSection1:Cell("COLUNA6")	,,"SUM"	,oBreak1,"Total"          , "@E 99,999,999.99", NIL, .T., .F.,.F.)
    

Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local _x        := 0
    Local _aPar     := {}
	
    oSection1:Init()
	oSection1:SetHeaderSection(.T.)

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += "     E1_NUM + ' ' + E1_PREFIXO + '/' + E1_PARCELA AS TITULO "
    _oSQL:_sQuery += "    ,F2_CLIENTE + '-' + A1_NOME AS CLIENTE "
    _oSQL:_sQuery += "    ,E1_NUMBCO AS NUM_BCO "
    _oSQL:_sQuery += "    ,F2_EMISSAO AS EMISSAO "
    _oSQL:_sQuery += "    ,E1_VENCTO AS VENCTO "
    _oSQL:_sQuery += "    ,E1_VALOR AS VALOR "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		WHEN E1_PORT2 <> '   ' THEN LTRIM(E1_PORT2) "
    _oSQL:_sQuery += " 		ELSE LTRIM(C5_BANCO) "
    _oSQL:_sQuery += " 	END AS BANCO "
    _oSQL:_sQuery += " FROM " + RetSQLName("SE1") + " SE1 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName("SF2") + " SF2 "
    _oSQL:_sQuery += " 	ON SF2.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SF2.F2_FILIAL   = '" + xfilial("SF2") + "'"
    _oSQL:_sQuery += " 		AND SF2.F2_DOC      = SE1.E1_NUM "
    _oSQL:_sQuery += " 		AND SF2.F2_SERIE    = SE1.E1_PREFIXO "
    _oSQL:_sQuery += " 		AND SF2.F2_ESPECIE != 'CF' "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName("SA1") + " SA1 "
    _oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SA1.A1_FILIAL = '" + xfilial("SA1") + "'"
    _oSQL:_sQuery += " 		AND SA1.A1_COD    = SF2.F2_CLIENTE "
    _oSQL:_sQuery += " 		AND SA1.A1_LOJA   = SF2.F2_LOJA "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName("SC5") + " SC5 "
    _oSQL:_sQuery += " 	ON (SC5.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND SC5.C5_FILIAL = '" + xfilial("SC5") + "'"
    _oSQL:_sQuery += " 			AND SC5.C5_NOTA   = SF2.F2_DOC "
    _oSQL:_sQuery += " 			AND SC5.C5_SERIE  = SF2.F2_SERIE) "
    _oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND SE1.E1_FILIAL = '" + xfilial("SE1") + "'"
    _oSQL:_sQuery += " AND SE1.E1_NUM     BETWEEN '" + mv_par04 + "' AND '" + mv_par05 + "'"
    _oSQL:_sQuery += " AND SE1.E1_EMISSAO BETWEEN '" + dtos(mv_par01) + "' AND '" + dtos(mv_par02) + "'"
    _oSQL:_sQuery += " AND SE1.E1_PREFIXO = '"  + mv_par03 + "'"
    _oSQL:_sQuery += " AND SE1.E1_TIPO != 'NCC' "
    _oSQL:_sQuery += " ORDER BY E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, SC5.C5_CLIENTE "
    _aFina := aclone(_oSQL:Qry2Array())

	For _x:=1 to Len(_aFina)
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aFina[_x, 1] })       // Título
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aFina[_x, 2] })       // Cliente
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aFina[_x, 3] })       // Num.Banco
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| stod(_aFina[_x, 4]) }) // Emissao
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| stod(_aFina[_x, 5]) }) // Vencto
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aFina[_x, 6] })       // Valor 
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aFina[_x, 7] })       // Cod.Bco
		
		oSection1:PrintLine()
	Next

    oSection1:Finish()

    _oSQL:= ClsSQL ():New()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " WITH C "
    _oSQL:_sQuery += " AS "
    _oSQL:_sQuery += " ( "
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += "     CASE "
    _oSQL:_sQuery += " 		    WHEN E1_PORT2 <> '   ' THEN LTRIM(E1_PORT2) "
    _oSQL:_sQuery += " 		    ELSE LTRIM(C5_BANCO) "
    _oSQL:_sQuery += " 	    END AS BANCO "
    _oSQL:_sQuery += "    ,COUNT(E1_NUM) AS QTD "
    _oSQL:_sQuery += "    ,SUM(E1_VALOR) AS TOTAL "
    _oSQL:_sQuery += " FROM " + RetSQLName("SE1") + " SE1 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName("SF2") + " SF2 "
    _oSQL:_sQuery += " 	ON SF2.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SF2.F2_FILIAL   = '" + xfilial("SF2") + "'"
    _oSQL:_sQuery += " 		AND SF2.F2_DOC      = SE1.E1_NUM "
    _oSQL:_sQuery += " 		AND SF2.F2_SERIE    = SE1.E1_PREFIXO "
    _oSQL:_sQuery += " 		AND SF2.F2_ESPECIE != 'CF' "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName("SA1") + " SA1 "
    _oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SA1.A1_FILIAL = '" + xfilial("SA1") + "'"
    _oSQL:_sQuery += " 		AND SA1.A1_COD    = SF2.F2_CLIENTE "
    _oSQL:_sQuery += " 		AND SA1.A1_LOJA   = SF2.F2_LOJA "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName("SC5") + " SC5 "
    _oSQL:_sQuery += " 	ON (SC5.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND SC5.C5_FILIAL = '" + xfilial("SC5") + "'"
    _oSQL:_sQuery += " 			AND SC5.C5_NOTA   = SF2.F2_DOC "
    _oSQL:_sQuery += " 			AND SC5.C5_SERIE  = SF2.F2_SERIE) "
    _oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND SE1.E1_FILIAL = '" + xfilial("SE1") + "'"
    _oSQL:_sQuery += " AND SE1.E1_NUM     BETWEEN '" + mv_par04 + "' AND '" + mv_par05 + "'"
    _oSQL:_sQuery += " AND SE1.E1_EMISSAO BETWEEN '" + dtos(mv_par01) + "' AND '" + dtos(mv_par02) + "'"
    _oSQL:_sQuery += " AND SE1.E1_PREFIXO = '"  + mv_par03 + "'"
    _oSQL:_sQuery += " AND SE1.E1_TIPO != 'NCC' "
    _oSQL:_sQuery += " GROUP BY E1_PORT2, C5_BANCO "
    _oSQL:_sQuery += " ) "
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   BANCO "
    _oSQL:_sQuery += "    ,SUM(QTD) AS QTD "
    _oSQL:_sQuery += "    ,SUM(TOTAL) AS TOTAL "
    _oSQL:_sQuery += " FROM C "
    _oSQL:_sQuery += " GROUP BY BANCO "
    _oSQL:_sQuery += " ORDER BY BANCO "
    _aTot := aclone(_oSQL:Qry2Array())

    oReport:ThinLine()
    For _x:=1 to Len(_aTot)
        oReport:SkipLine(1)
        _nLinha:= _PulaFolha(_nLinha)
        oReport:PrintText("Banco:                   " + PADL(_aTot[_x, 1],20,' '),, 100)
        _nLinha:= _PulaFolha(_nLinha)
        oReport:PrintText("Qtd.Títulos:             " + PADL(_aTot[_x, 2],20,' '),, 100)
        _nLinha:= _PulaFolha(_nLinha)
        oReport:PrintText("Valor Total:             " + PADL('R$' + Transform(_aTot[_x, 3], "@E 999,999,999.99"),20,' '),, 100)
        oReport:SkipLine(1)
    Next
    
    _aPar := U_ImpParTRep()
    oReport:ThinLine()
    oReport:ThinLine()
    oReport:PrintText("Parametros utilizados:",, 100)
    oReport:ThinLine()
    For _x:=1 to Len(_aPar)
        _nLinha:= _PulaFolha(_nLinha)
        oReport:PrintText(_aPar[_x],, 100)
    Next
    oReport:ThinLine()
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
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg()
	local _aRegsPerg := {}
	local _aDefaults := {}
	local _aTamDoc   := aclone(TamSX3("D2_DOC"))
	
	//                     PERGUNT                           TIPO TAM                    DEC  VALID  F3      Opcoes Help
	aadd(_aRegsPerg, {01, "Data de emissao de            ", "D", 8,                       0,  "",   "   ",  {},    ""})
	aadd(_aRegsPerg, {02, "Data de emissao ate           ", "D", 8,                       0,  "",   "   ",  {},    ""})
	aadd(_aRegsPerg, {03, "Serie da NF                   ", "C", 3,                       0,  "",   "   ",  {},    ""})
	aadd(_aRegsPerg, {04, "Nota Inicial                  ", "C", _aTamDoc [1], _aTamDoc [2],  "",   "   ",  {},    ""})
	aadd(_aRegsPerg, {05, "Nota Final                    ", "C", _aTamDoc [1], _aTamDoc [2],  "",   "   ",  {},    ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
