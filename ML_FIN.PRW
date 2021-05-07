// Programa..: ML_FIN
// Autor.....: Jeferson Rech
// Data......: Fev/2001
// Descricao.: Relatorio Financeiro de vendas
// 
// #TipoDePrograma    #relatorio
// #Descricao         Relatorio Financeiro de vendas
// #PalavasChave      #vendas #titulos #vendas 
// #TabelasPrincipais #SE1 #SF2 #SA1 #SC5
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
// 20/08/2009 - Robert  - Portado para SQL.
//                      - Ajuste perguntas para Protheus10.
// 02/02/2011 - Robert  - Ajustes para novo tamanho do campo E1_NUMBCO.
//                      - Criado parametro de linhas por pagina.
// 06/09/2012 - Elaine  - Alteracao na rotina _ValidPerg para tratar o tamanho do campo
//                        da NF com a funcao TamSX3 (ref mudancas do tamanho do campo da NF de 6 p/9 posicoes) 
// 02/06/2020 - Claudia - Incluido totalizadores de banco, conforme GLPI 7970
// 03/09/2020 - Cláudia - Incluido filtro de tipo de nota, retirando a impressão de NCC GLPI: 372
// 21/09/2020 - Cláudia - Alterado campo de Banco, buscando direto do titulo. GLPI: 8513
// 06/05/2021 - Claudia - Incluido tags de customizações
//
// --------------------------------------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "totvs.ch"

User Function ml_fin()
	cString   := "SF2"
	cDesc1    := "Este Programa Tem Como Objetivo a Impressao do Relatorio Financeiro"
	cDesc2    := "diario especifico para Cooperativa Agroindustrial Nova Alianca."
	cDesc3    := ""
	tamanho   := "M"
	aReturn   := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	nLastKey  := 0
	cPerg     := "ML_FIN"
	titulo    := "Relatorio Financeiro"
	wnrel     := "ML_FIN"
	nomeprog  := "ML_FIN"
	nTipo     := 0
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
	
	If nLastKey == 27
		Return
	Endif
	SetDefault(aReturn,cString)
	If nLastKey == 27
		Return
	Endif
	RptStatus({|| RptDetail()})
Return
//
// --------------------------------------------------------------------------
// Impressão
Static Function RptDetail()
	local _sQuery  := ""
	local _sAliasQ := ""
	local _nMaxLin := max (60, mv_par06)
	local _sImpLin := ""

	SetRegua(LastRec())
	nTipo := IIF(aReturn[4]==1,15,18)
	li    := 80
	m_pag := 1
	cabec1 := "Titulo        Cod.   Nome do Cliente                    Cidade                Num. Banco          Emissao  Vencto          Valor Bco"
	cabec2 := ""
	
	_sQuery := ""
	_sQuery += "SELECT E1_NUM, E1_PREFIXO, E1_PARCELA, E1_VALOR, E1_NUMBCO, E1_VENCTO, F2_EMISSAO, F2_CLIENTE, F2_LOJA, F2_BANCO, C5_BANCO, A1_NOME, A1_MUN, A1_EST, E1_PORT2"
	_sQuery +=  " FROM " + RetSQLName ("SE1") + " SE1, "
	_sQuery +=             RetSQLName ("SA1") + " SA1, "
	_sQuery +=             RetSQLName ("SF2") + " SF2 "
	_sQuery += " LEFT JOIN " + RetSQLName ("SC5") + " SC5 "
	_sQuery +=        " ON (SC5.D_E_L_E_T_ = ''"
	_sQuery +=        " AND SC5.C5_FILIAL  = '" + xfilial ("SC5") + "'"
	_sQuery +=        " AND SC5.C5_NOTA    = SF2.F2_DOC"
	_sQuery +=        " AND SC5.C5_SERIE   = SF2.F2_SERIE)"
	_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
	_sQuery +=   " AND SE1.E1_FILIAL  = '" + xfilial ("SE1") + "'"
	_sQuery +=   " AND SE1.E1_NUM     BETWEEN '" + mv_par04 + "' AND '" + mv_par05 + "'"
	_sQuery +=   " AND SE1.E1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery +=   " AND SE1.E1_PREFIXO = '"  + mv_par03 + "'"
	_sQuery +=   " AND SE1.E1_TIPO   != 'NCC'"
	_sQuery +=   " AND SA1.D_E_L_E_T_ = ''"
	_sQuery +=   " AND SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
	_sQuery +=   " AND SA1.A1_COD     = SF2.F2_CLIENTE"
	_sQuery +=   " AND SA1.A1_LOJA    = SF2.F2_LOJA"
	_sQuery +=   " AND SF2.D_E_L_E_T_ = ''"
	_sQuery +=   " AND SF2.F2_FILIAL  = '" + xfilial ("SF2") + "'"
	_sQuery +=   " AND SF2.F2_DOC     = SE1.E1_NUM"
	_sQuery +=   " AND SF2.F2_SERIE   = SE1.E1_PREFIXO"
	_sQuery +=   " AND SF2.F2_ESPECIE != 'CF'"  
	_sQuery += " ORDER BY E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO"
	u_log (_sQuery)
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
	TCSetField (alias (), "E1_VENCTO", "D")
	TCSetField (alias (), "F2_EMISSAO", "D")
	_xTotal := 0
	Do While ! (_sAliasQ) -> (Eof())
		If li>_nMaxLin
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		Endif
		_xDOC     := (_sAliasQ)->E1_NUM
		_xSERIE   := (_sAliasQ)->E1_PREFIXO
		_xPARCELA := (_sAliasQ)->E1_PARCELA
		_xVALOR   := (_sAliasQ)->E1_VALOR
		_xNUMBCO  := (_sAliasQ)->E1_NUMBCO
		_xVENCTO  := (_sAliasQ)->E1_VENCTO
		_xEMISSAO := (_sAliasQ)->F2_EMISSAO
		_xCLIENTE := (_sAliasQ)->F2_CLIENTE
		_xLOJA    := (_sAliasQ)->F2_LOJA
		_xBANCO := (_sAliasQ)->E1_PORT2
		If _xBANCO == Space(3)
			_xBANCO := (_sAliasQ)->C5_BANCO
		Endif
		_xNOME  := (_sAliasQ)->A1_NOME
		_xMUN   := (_sAliasQ)->A1_MUN
		_xEST   := (_sAliasQ)->A1_EST
		
		If li>_nMaxLin
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		Endif

		_sImpLin := ""
		_sImpLin += _xDOC+" "+_xSERIE+"/"+_xPARCELA + "  "
		_sImpLin += _xCLIENTE+" "+Left(_xNOME,34) + " "
		_sImpLin += Left(_xMUN,18)+" "+_xEST + " "
		_sImpLin += Left(_xNUMBCO,18) + "  "
		_sImpLin += dtoc (_xEMISSAO) + " "
		_sImpLin += dtoc (_xVENCTO) + " "
		_sImpLin += transform (_xVALOR, "@E 9,999,999.99") + " "
		_sImpLin += _xBANCO
		@ li, 0 psay _sImpLin
		li:=li+1
		_xTotal := _xTotal + _xVALOR
		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("SE1")

	li:=li+1
	@ li, 096 PSAY "** Total"
	@ li, 110 PSAY _xTotal   Picture "@E 999,999,999,999.99"
	li += 2
	
	// IMPRIME TOTAIS POR BANCO
	_ImprimeTotais(_nMaxLin)
	
	U_ImpParam (_nMaxLin)

	If aReturn[5] == 1
		Set Printer To
		DbCommitAll()
		ourspool(wnrel)
	Endif
	
	MS_FLUSH() // libera fila de relatorios em spool (Tipo Rede Netware)
Return
//
// --------------------------------------------------------------------------
// Totalizadores
Static function _imprimeTotais(_nMaxLin)
	local _aDados := {}
	local _x	  := 0

	_sQuery := ""
	_sQuery += " WITH C
	_sQuery += " AS
	_sQuery += " (SELECT
	_sQuery += " 		CASE
	_sQuery += " 			WHEN E1_PORT2 <> '   ' THEN LTRIM(E1_PORT2)"
	_sQuery += " 			ELSE LTRIM(C5_BANCO)"
	_sQuery += " 		END AS BANCO"
	_sQuery += " 	   ,COUNT(E1_NUM) AS QTD"
	_sQuery += " 	   ,SUM(E1_VALOR) AS TOTAL"
	_sQuery += " 	FROM " + RetSQLName ("SE1") + " SE1 "
	_sQuery += " 	INNER JOIN " + RetSQLName ("SF2") + " SF2 "
	_sQuery += " 		ON (SF2.D_E_L_E_T_ = ''"
	_sQuery += " 		AND SF2.F2_FILIAL = '" + xfilial ("SF2") + "'"
	_sQuery += " 		AND SF2.F2_DOC = SE1.E1_NUM"
	_sQuery += " 		AND SF2.F2_SERIE = SE1.E1_PREFIXO"
	_sQuery += " 		AND SF2.F2_ESPECIE != 'CF')"
	_sQuery += " 	LEFT JOIN " + RetSQLName ("SC5") + " SC5 "
	_sQuery += " 		ON (SC5.D_E_L_E_T_ = ''"
	_sQuery += " 		AND SC5.C5_FILIAL = '" + xfilial ("SC5") + "'"
	_sQuery += " 		AND SC5.C5_NOTA = SF2.F2_DOC"
	_sQuery += " 		AND SC5.C5_SERIE = SF2.F2_SERIE)"
	_sQuery += " 	WHERE SE1.D_E_L_E_T_ = ''"
	_sQuery += " 	AND SE1.E1_FILIAL = '" + xfilial ("SE5") + "'"
	_sQuery += "    AND SE1.E1_NUM     BETWEEN '" + mv_par04 + "' AND '" + mv_par05 + "'"
	_sQuery += " 	AND SE1.E1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += " 	AND SE1.E1_PREFIXO = '"  + mv_par03 + "'"
	_sQuery += " 	AND SE1.E1_TIPO != 'NCC'"
	_sQuery += " 	GROUP BY E1_PORT2"
	_sQuery += " 			,C5_BANCO)"
	_sQuery += " SELECT"
	_sQuery += " 	BANCO"
	_sQuery += "    ,SUM(QTD)"
	_sQuery += "    ,SUM(TOTAL)"
	_sQuery += " FROM C"
	_sQuery += " GROUP BY BANCO"

	_aDados := U_Qry2Array(_sQuery)
	
	li:=li+1
	li:=li+1
	@ li, 005 PSAY '************** Totais por Banco ************** '
	li:=li+1
	li:=li+1
	For _x:=1 to len(_aDados)
		If li>_nMaxLin
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		Endif
		li:=li+1
		@ li, 015 PSAY 'Banco:                  ' + _aDados[_x, 1]
		li:=li+1
		@ li, 015 PSAY 'Qnt.Títulos:   ' + transform (_aDados[_x, 2], "@E 999999999999") 
		li:=li+1
		@ li, 015 PSAY 'Valor Total: R$' + transform (_aDados[_x, 3], "@E 9,999,999.99") 
		li:=li+1
		li:=li+1
		If li>_nMaxLin
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		Endif
	
	Next
		
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	local _aTamDoc   := aclone (TamSX3 ("D2_DOC"))
	
	//                     PERGUNT                           TIPO TAM                    DEC  VALID  F3      Opcoes Help
	aadd (_aRegsPerg, {01, "Data de emissao de            ", "D", 8,                       0,  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {02, "Data de emissao ate           ", "D", 8,                       0,  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {03, "Serie da NF                   ", "C", 3,                       0,  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {04, "N.F. Inicial                  ", "C", _aTamDoc [1], _aTamDoc [2],  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {05, "N.F. Final                    ", "C", _aTamDoc [1], _aTamDoc [2],  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {06, "Maximo de linhas por pagina  ?", "N", 02,                      0,  "",   "   ",  {},    ""})
	
	aadd (_aDefaults, {"06", 70})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return

