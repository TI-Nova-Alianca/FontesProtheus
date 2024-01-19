// Programa:  VA_RELIRE
// Autor:     Cláudia Lionço
// Data:      07/11/2019
// Descricao: Relatorio IRE - Indice de rotação de estoque
//
// Historico de alteracoes:
// 11/11/2019 - Cláudia - Alterada a formula de Estoque médio. 
// 						  O retorno será em dias e não meses, conforme código comentado.
// 04/12/2019 - Cláudia - Incluído parâmetro de grupo de produto.
// 22/11/2022 - Robert  - Criado parametro para selecionar tipo de produto.
// 19/01/2024 - Claudia - Incluido parametros de linha comercial. GLPI: 14683
//
// --------------------------------------------------------------------------------------- 
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_RELIRE()
	Private oReport
	Private cPerg   := "VA_RELIRE"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
 
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	//Local oFunction

	oReport := TReport():New("VA_RELIRE","Indice de rotação de estoque",cPerg,{|oReport| PrintReport(oReport)},"Indice de rotação de estoque")
	TReport():ShowParamPage()
	
	oReport:ShowParamPage() // imprime parametros
	oReport:SetTotalInLine(.F.)
	//oReport:SetLandScape(.T.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	// produto/descrição do produto/filial/almox/EM Mes/Estoque medio/estoque do período/IRE
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Produto"		,,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Descrição"		,,40,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Filial"		,,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Almox"			,,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Qnt.Dias"		,,10,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Est.Médio"		,,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Est.Período"	,,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"IRE"			,,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"PME(Dias)"		,,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
Return(oReport)
//
Static Function PrintReport(oReport)
	Local oSection1  := oReport:Section(1)
	
	_IREDiario(oSection1)

Return
//-------------------------------------------------
// Calcula custo médio e retorna IRE impresso (diário)
Static Function _IREDiario(oSection1)
	Local _cQry1	:= ""
	Local _cQry2	:= ""
	Local _cQry3	:= ""
	Local _aProd	:= {}
	Local _aAlmox	:= {}
	Local _aEstoque := {}
	Local _aIRE		:= {}
	Local a			:= 0
	Local b			:= 0
	Local c			:= 0
	Local z			:= 0
	
	//BUSCA PRODUTO
	_cQry1 := " SELECT "
	_cQry1 += " 	B1_COD "
	_cQry1 += " FROM " + RetSqlName("SB1")
	_cQry1 += " WHERE D_E_L_E_T_ = '' "
	_cQry1 += " AND B1_TIPO = '" + mv_par06 + "'"  //'PA' "
	If !empty(mv_par05)
		_cQry1 += " AND B1_GRUPO = '" + alltrim(mv_par05) + "' "
	EndIf
	_cQry1 += " AND B1_COD BETWEEN    '" + mv_par03 + "' AND '" + mv_par04 + "' "
	_cQry1 += " AND B1_CODLIN BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "' "
	_aProd  := U_Qry2Array(_cQry1)

	For a := 1 to len(_aProd) // percorre produtos
		_sProduto := _aProd[a,1]
		
		// ESTOQUE DAS FILIAIS/ALMOX
		_cQry2 := " SELECT "
		_cQry2 += " 	B2_FILIAL AS FILIAL "
		_cQry2 += "    ,B2_LOCAL AS ALMOXARIFADO "
		_cQry2 += "    ,B2_QATU AS ESTOQUE "
		_cQry2 += " FROM  " + RetSqlName("SB2") + "  SB2"
		_cQry2 += " WHERE SB2.D_E_L_E_T_ = '' "
		_cQry2 += " AND B2_COD = '" + _sProduto + "' "
		_cQry2 += " AND B2_QATU != 0 "
		_cQry2 += " ORDER BY B2_FILIAL, B2_LOCAL "
		_aAlmox := U_Qry2Array(_cQry2)
		
		For b:= 1 to len(_aAlmox) // percorre filial e almoxarifado
			_sFilial	:= _aAlmox[b,1]
			_sAlmox 	:= _aAlmox[b,2]
			_DescProd	:= Posicione("SB1",1,xFilial("SB1") + _sProduto,"B1_DESC")

			_cQry3 := " WITH C "
			_cQry3 += " AS "
			_cQry3 += " (SELECT "
			_cQry3 += " 		DATA "
			_cQry3 += " 	   ,COUNT(DATA) AS QTD_DATA "
			_cQry3 += " 	   ,SUM(SALDO) AS SALDO "
			_cQry3 += " 	   ,SUM(SALDO) / COUNT(DATA) AS MEDIA_DIA "
			_cQry3 += " 	FROM dbo.VA_FKARDEX('" + _sFilial + "', '" + _sProduto + "', '" + _sAlmox + "', '" + DTOS(mv_par01) + "', '" + DTOS(mv_par02) + "') "
			_cQry3 += " 	WHERE (MOVIMENTO <> 'SALDO INICIAL') "
			_cQry3 += " 	GROUP BY DATA) "
			_cQry3 += " SELECT "
			_cQry3 += "     (SELECT "
			_cQry3 += " 			DATEDIFF(DAY, '" + DTOS(mv_par01)  + "', '" + DTOS(mv_par02) + "')) "
			_cQry3 += " 	AS QTD_DIAS_PERIODO "
			_cQry3 += "    ,CONVERT(DECIMAL(18,2), SUM(MEDIA_DIA) / (SELECT "
			_cQry3 += " 			DATEDIFF(DAY, '" + DTOS(mv_par01)  + "', '" + DTOS(mv_par02) + "'))) "
			_cQry3 += " 	AS ESTOQUE_MEDIO "
			_cQry3 += "    ,(SELECT "
			_cQry3 += "    		SUM(QT_ENTRADA) "
			_cQry3 += "    	FROM dbo.VA_FKARDEX('" + _sFilial + "', '" + _sProduto + "', '" + _sAlmox + "', '" + DTOS(mv_par01) + "', '" + DTOS(mv_par02) + "')"
			_cQry3 += "    	WHERE (CFOP = '' "
			_cQry3 += "    	OR CFOP = 'PR0' "
			_cQry3 += "    	OR CFOP = 'DE4' "
			_cQry3 += "    	OR CFOP = '1151' "
			_cQry3 += "    	OR CFOP = '1101' "
			_cQry3 += "    	OR CFOP = '2101' "
			_cQry3 += "    	OR CFOP = '1124')) "
			_cQry3 += "     AS ENTRADAS "
			_cQry3 += "    ,CONVERT(DECIMAL(18,2),(SELECT "
			_cQry3 += " 			SALDO AS SALDOFIN "
			_cQry3 += " 		FROM dbo.VA_FKARDEX('" + _sFilial + "', '" + _sProduto + "', '" + _sAlmox + "', '" + DTOS(mv_par01) + "', '" + DTOS(mv_par02) + "') "
			_cQry3 += " 		WHERE LINHA = (SELECT "
			_cQry3 += " 				MAX(LINHA) "
			_cQry3 += " 			FROM dbo.VA_FKARDEX('" + _sFilial + "', '" + _sProduto + "', '" + _sAlmox + "', '" + DTOS(mv_par01) + "', '" + DTOS(mv_par02) + "'))) "
			_cQry3 += " 	) AS ULTIMO_ESTOQUE "
			_cQry3 += " FROM C "
			_aEstoque := U_Qry2Array(_cQry3)

			For c:=1 to len(_aEstoque)
				_nQtdDias := _aEstoque[c,1]
				_sQtdDias := alltrim(str(_nQtdDias))
				_nEstMed  := ROUND(_aEstoque[c,2],2)
				_sEstMed  := alltrim(str(_nEstMed))
				_nUltEst  := _aEstoque[c,3] - _aEstoque[c,4]
				_sUltEst  := alltrim(str(_nUltEst))
				_nIRE     := ROUND(((_aEstoque[c,3] - _aEstoque[c,4])/_aEstoque[c,2]),2)
				_sIRE	  := alltrim(str(_nIRE))
				_nPME	  := ROUND(_nQtdDias/_nIRE,2)
				_sPME	  := alltrim(str(_nPME))
						
				AADD(_aIRE, {_sProduto, _DescProd, _sFilial, _sAlmox,  _sQtdDias, _sEstMed, _sUltEst, _sIRE, _sPME })
			Next
		Next
	Next
	// Imprime o IRE no relatório
	oSection1:Init()
	oSection1:SetHeaderSection(.T.)
	
	If len(_aIRE) > 0
		_sPrd := alltrim(_aIRE[1,1])
	EndIf
	//
	For z:=1 to len(_aIRE)
		If _sPrd != alltrim(_aIRE[z,1])
			oReport:PrintText(" ",,100)
			_sPrd := alltrim(_aIRE[z,1])
		EndIf
		
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| alltrim(_aIRE[z,1])})
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aIRE[z,2]	})
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aIRE[z,3]	})
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aIRE[z,4] })
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aIRE[z,5] })
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aIRE[z,6] })
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aIRE[z,7] })
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aIRE[z,8] })
		oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aIRE[z,9] })
		
		oSection1:PrintLine()
	Next
	oSection1:Finish()
Return
//-------------------------------------------------
// PERGUNTAS
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Data Inicial       ", "D", 8, 0,  "",  "   "		, {},                         					""})
    aadd (_aRegsPerg, {02, "Data Final         ", "D", 8, 0,  "",  "   "		, {},                         					""})
    aadd (_aRegsPerg, {03, "Produto de         ", "C",15, 0,  "",  "SB1"		, {},                         					""})
    aadd (_aRegsPerg, {04, "Produto até        ", "C",15, 0,  "",  "SB1"		, {},                         					""})
    aadd (_aRegsPerg, {05, "Grupo              ", "C", 4, 0,  "",  "SBM"		, {},                         					""})
    aadd (_aRegsPerg, {06, "Tipo de produto    ", "C", 2, 0,  "",  "02 "		, {},                         					""})
	aadd (_aRegsPerg, {07, "Linha Com. de      ", "C", 2, 0,  "",  "ZX539"		, {},                         					""})
	aadd (_aRegsPerg, {08, "Linha Com. Até     ", "C", 2, 0,  "",  "ZX539"		, {},                         					""})

    U_ValPerg (cPerg, _aRegsPerg)
Return

