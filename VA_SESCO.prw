// Programa...: VA_SESCO
// Autor......: Robert Koch
// Data.......: 02/10/2019
// Descricao..: Exportacao de dados contabeis para o SESCOOP.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function VA_SESCO (_lAutomat)
	Local cCadastro := "Exportacao de dados para SESCOOP"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VASESCO"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa ({|lEnd| _Gera()})
	else
		AADD(aSays,"Este programa tem como objetivo gerar um")
		AADD(aSays,"arquivo de exportacao de dados contabeis para o SESCOOP,")
		AADD(aSays,"em layout pre-definido.")
		
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return



// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet



// --------------------------------------------------------------------------
Static Function _Gera ()
	local _oSQL       := NIL
	local _sAliasQ    := NIL
	local _nHdl       := 0
	local _nQtTotAs   := 0
	local _nQtAsAtiv  := 0
	local _nQtFunc    := mv_par04  // Por enquanto nao sei como buscar do Metadados.
	local _nQtAdmis   := mv_par05  // Por enquanto nao sei como buscar do Metadados.
	local _nQtDemis   := mv_par06  // Por enquanto nao sei como buscar do Metadados.
	local _sIniFim    := alltrim (sm0 -> m0_cgc) + ';' + cvaltochar (val (mv_par02)) + ';' + cvaltochar (val (mv_par01))
	local _dUltDiaMes := lastday (stod (mv_par01 + mv_par02 + '01'))
	//local _dUDMesAnt  := ctod ('')

	procregua (100)
	incproc ('Buscando saldos contabeis')

	// Cria arquivo para gravacao dos dados.
	_nHdl = fcreate(alltrim (mv_par03), 0)
	fwrite (_nHdl, 'inicio;' + _sIniFim + chr (13) + chr (10))

	incproc ("Buscando dados contabeis")

	// Exporta dados contabeis
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
/*	_oSQL:_sQuery += "WITH C AS ("
	_oSQL:_sQuery += " SELECT CT1_CONTA, CT1.CT1_DESC01, CT1.CT1_NORMAL,"  // 1=Devedora;2=Credora
	_oSQL:_sQuery +=        " ISNULL((SELECT CTS_FORMUL" //, CTS_DESCCG,CTS_CT1INI, CTS_CT1FIM"
	_oSQL:_sQuery +=                  " FROM " + RetSQLName ("CTS") + " CTS "
	_oSQL:_sQuery +=                 " WHERE CTS.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                   " AND CTS.CTS_FILIAL = '" + xfilial ("CTS") + "'"
	_oSQL:_sQuery +=                   " AND CTS.CTS_CODPLA = '517'"
	_oSQL:_sQuery +=                   " AND CTS.CTS_CT1INI <= CT1.CT1_CONTA"
	_oSQL:_sQuery +=                   " AND CTS.CTS_CT1FIM >= CT1.CT1_CONTA"
	_oSQL:_sQuery +=        " ), '') AS GRUPO_SESCOOP,"
	_oSQL:_sQuery +=        " ISNULL ("
	_oSQL:_sQuery +=                " (SELECT SUM (CQ0_DEBITO - CQ0_CREDIT)"
	_oSQL:_sQuery +=                         " FROM " + RetSQLName ("CQ0") + " CQ0 "
	_oSQL:_sQuery +=                        " WHERE CQ0.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                          " AND CQ0.CQ0_CONTA  = CT1_CONTA"
	_oSQL:_sQuery +=                          " AND CQ0.CQ0_TPSALD = '1'"
	_oSQL:_sQuery +=                          " AND CQ0.CQ0_DATA  <= '" + dtos (_dUltDiaMes) + "'"
	_oSQL:_sQuery +=                        "), 0)"
	_oSQL:_sQuery +=                " AS SALDO_CQ0, "
	_oSQL:_sQuery +=        " ISNULL ("
	_oSQL:_sQuery +=                " (SELECT SUM (CQ2_DEBITO - CQ2_CREDIT)"
	_oSQL:_sQuery +=                         " FROM " + RetSQLName ("CQ2") + " CQ2 "
	_oSQL:_sQuery +=                        " WHERE CQ2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                          " AND CQ2.CQ2_CONTA  = CT1_CONTA"
	_oSQL:_sQuery +=                          " AND CQ2.CQ2_TPSALD = '1'"
	_oSQL:_sQuery +=                          " AND CQ2.CQ2_DATA   BETWEEN '" + mv_par01 + "0101' AND '" + dtos (_dUltDiaMes) + "'"
	_oSQL:_sQuery +=                        "), 0)"
	_oSQL:_sQuery +=                " AS SALDO_CQ2 "
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("CT1") + " CT1 "
	_oSQL:_sQuery += " WHERE CT1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND CT1.CT1_CLASSE = '2'"  // 1=Sintetica;2=Analitica
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += " SELECT GRUPO_SESCOOP"
	// para verificar valores ---> _oSQL:_sQuery +=        " ,CT1_CONTA, CT1_DESC01,CASE WHEN CT1_NORMAL = '1' THEN 'Devedora' ELSE 'Credora' END AS NATUREZA"
	_oSQL:_sQuery +=        " ,SUM (CASE WHEN SUBSTRING (CT1_CONTA, 1, 1) IN ('1', '2') THEN SALDO_CQ0 ELSE SALDO_CQ2 END) AS SALDO"
	_oSQL:_sQuery += " FROM C"
	_oSQL:_sQuery += " WHERE GRUPO_SESCOOP != ''"
	_oSQL:_sQuery += " GROUP BY GRUPO_SESCOOP"
	// para verificar valores ---> _oSQL:_sQuery += " GROUP BY CT1_CONTA, CT1_DESC01, GRUPO_SESCOOP, CT1_NORMAL"
	_oSQL:_sQuery += " ORDER BY GRUPO_SESCOOP"
*/

	// Monta clausula WITH para definir o plano de contas da SESCOOP
	_oSQL:_sQuery += " WITH "
	_oSQL:_sQuery += " PLANO_SESCOOP AS "
	_oSQL:_sQuery += " (             SELECT '1.0'       AS CTA, 'Ativo'                                                AS DESCRICAO, '1'    AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1'       AS CTA, 'Ativo Circulante'                                     AS DESCRICAO, '2'    AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.1'     AS CTA, 'Caixa e Equivalentes de Caixa'                        AS DESCRICAO, '997'  AS COD_CTA, '997'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.2'     AS CTA, 'Ativos Financeiros (Aplicações Financeiras)'          AS DESCRICAO, '1409' AS COD_CTA, '1409' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.3'     AS CTA, 'Créditos'                                             AS DESCRICAO, '1410' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.3.1'   AS CTA, 'Cooperados'                                           AS DESCRICAO, '1411' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.3.1.1' AS CTA, 'Cooperados - Valores a Receber'                       AS DESCRICAO, '5'    AS COD_CTA, '5'    AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.3.1.2' AS CTA, '(-) Perdas Estimadas c/ CLD - Cooperados'             AS DESCRICAO, '785'  AS COD_CTA, '785'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.3.1.3' AS CTA, '(-) Ajuste a Valor Presente - Cooperados'             AS DESCRICAO, '1412' AS COD_CTA, '1412' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.3.2'   AS CTA, 'Clientes'                                             AS DESCRICAO, '1413' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.3.2.1' AS CTA, 'Clientes - Valores a Receber'                         AS DESCRICAO, '6'    AS COD_CTA, '6'    AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.3.2.2' AS CTA, '(-) Perdas Estimadas c/ CLD - Clientes'               AS DESCRICAO, '786'  AS COD_CTA, '786'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.3.2.3' AS CTA, '(-) Ajuste a Valor Presente - Clientes'               AS DESCRICAO, '1414' AS COD_CTA, '1414' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.3.3'   AS CTA, 'Outros Créditos'                                      AS DESCRICAO, '1417' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.3.3.1' AS CTA, 'Outros - Valores a Receber'                           AS DESCRICAO, '1418' AS COD_CTA, '1418' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.3.3.2' AS CTA, '(-) Perdas Estimadas c/ CLD - Outros'                 AS DESCRICAO, '787'  AS COD_CTA, '787'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.3.3.3' AS CTA, '(-) Ajuste a Valor Presente - Outros'                 AS DESCRICAO, '1419' AS COD_CTA, '1419' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.4'     AS CTA, 'Estoques'                                             AS DESCRICAO, '1416' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.4.1'   AS CTA, 'Estoque Próprio'                                      AS DESCRICAO, '1420' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.4.1.1' AS CTA, 'de Produtos Agropecuários'                            AS DESCRICAO, '1421' AS COD_CTA, '1421' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.4.1.2' AS CTA, 'de Bens de Fornecimento'                              AS DESCRICAO, '1422' AS COD_CTA, '1422' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.4.1.3' AS CTA, 'de Produtos Industrializados'                         AS DESCRICAO, '1423' AS COD_CTA, '1423' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.4.1.4' AS CTA, 'de Ativos Biológicos'                                 AS DESCRICAO, '1424' AS COD_CTA, '1424' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.4.1.5' AS CTA, 'Almoxarifados de Bens de Produção'                    AS DESCRICAO, '1425' AS COD_CTA, '1425' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.4.1.6' AS CTA, '(-) Ajustes Avaliação Patrimonial - Estoque'          AS DESCRICAO, '1477' AS COD_CTA, '1477' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.4.2'   AS CTA, 'Mercadorias em Depósito'                              AS DESCRICAO, '1426' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.4.2.1' AS CTA, 'de Cooperados'                                        AS DESCRICAO, '1427' AS COD_CTA, '1427' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.4.2.2' AS CTA, 'de Terceiros'                                         AS DESCRICAO, '1428' AS COD_CTA, '1428' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.1.5'     AS CTA, 'Dispêndios do Exercício Seguinte'                     AS DESCRICAO, '1415' AS COD_CTA, '1415' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2'       AS CTA, 'Ativo Não Circulante'                                 AS DESCRICAO, '1471' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.1'     AS CTA, 'Realizável a Longo Prazo'                             AS DESCRICAO, '10'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.1.1'   AS CTA, 'Cooperados - Longo Prazo'                             AS DESCRICAO, '938'  AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.1.1.1' AS CTA, 'Cooperados a Receber - L.P.'                          AS DESCRICAO, '941'  AS COD_CTA, '941'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.1.1.2' AS CTA, '(-) Perdas Estimadas c/ CLD - Cooperados L.P.'        AS DESCRICAO, '942'  AS COD_CTA, '942'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.1.1.3' AS CTA, '(-) Ajuste a Valor Presente - Cooperados L.P.'        AS DESCRICAO, '1433' AS COD_CTA, '1433' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.1.2'   AS CTA, 'Clientes - Longo Prazo'                               AS DESCRICAO, '939'  AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.1.2.1' AS CTA, 'Clientes a Receber - L.P.'                            AS DESCRICAO, '943'  AS COD_CTA, '943'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.1.2.2' AS CTA, '(-) Perdas Estimadas c/ CLD - Clientes L.P.'          AS DESCRICAO, '944'  AS COD_CTA, '944'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.1.2.3' AS CTA, '(-) Ajuste a Valor Presente - Clientes L.P.'          AS DESCRICAO, '1434' AS COD_CTA, '1434' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.1.3'   AS CTA, 'Estoques em Formação'                                 AS DESCRICAO, '1483' AS COD_CTA, '1483' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.1.4'   AS CTA, 'Outros - Longo Prazo'                                 AS DESCRICAO, '940'  AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.1.4.1' AS CTA, 'Outros Valores a Receber -L.P'                        AS DESCRICAO, '1432' AS COD_CTA, '1432' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.1.4.2' AS CTA, 'Depósitos Judiciais'                                  AS DESCRICAO, '1435' AS COD_CTA, '1435' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.1.4.3' AS CTA, '(-) Perdas Estimadas c/ CLD - Outros L.P.'            AS DESCRICAO, '946'  AS COD_CTA, '946'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.1.4.4' AS CTA, '(-) Ajuste a Valor Presente - Outros L.P.'            AS DESCRICAO, '1436' AS COD_CTA, '1436' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.2'     AS CTA, 'Investimentos'                                        AS DESCRICAO, '1474' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.2.1'   AS CTA, 'Sociedades Cooperativas'                              AS DESCRICAO, '1437' AS COD_CTA, '1437' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.2.2'   AS CTA, 'Propriedades p/ Investimentos'                        AS DESCRICAO, '1439' AS COD_CTA, '1439' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.2.3'   AS CTA, 'Outros Investimentos'                                 AS DESCRICAO, '1501' AS COD_CTA, '1501' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.2.4'   AS CTA, '(-) Ajustes Avaliação Patrimonial - Investim'         AS DESCRICAO, '1478' AS COD_CTA, '1478' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3'     AS CTA, 'Imobilizado'                                          AS DESCRICAO, '649'  AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.1'   AS CTA, 'Bens Corpóreos'                                       AS DESCRICAO, '13'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.1.1' AS CTA, 'Imóveis e Instalações'                                AS DESCRICAO, '668'  AS COD_CTA, '668'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.1.2' AS CTA, 'Máquinas E Equipamentos'                              AS DESCRICAO, '776'  AS COD_CTA, '776'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.1.3' AS CTA, 'Móveis e Utensílios'                                  AS DESCRICAO, '671'  AS COD_CTA, '671'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.1.4' AS CTA, 'Veículos e Máquinas Agrícolas'                        AS DESCRICAO, '1484' AS COD_CTA, '1484' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.1.5' AS CTA, 'Outros Bens Corpóreos'                                AS DESCRICAO, '666'  AS COD_CTA, '666'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.1.6' AS CTA, 'Ativo Biológico de Produção'                          AS DESCRICAO, '1692' AS COD_CTA, '1692' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.1.7' AS CTA, 'Direito de Uso de Ativos'                             AS DESCRICAO, '1983' AS COD_CTA, '1983' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.2'   AS CTA, '(-) Depreciação Acumulada'                            AS DESCRICAO, '678'  AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.2.1' AS CTA, '(-) Depreciação Acumulada - Imóveis e Instala'        AS DESCRICAO, '703'  AS COD_CTA, '703'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.2.2' AS CTA, '(-) Depreciação Acumulada - Maquinas E Equipamentos'  AS DESCRICAO, '673'  AS COD_CTA, '673'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.2.3' AS CTA, '(-) Depreciação Acumulada - Móveis E Utensíli'        AS DESCRICAO, '879'  AS COD_CTA, '879'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.2.4' AS CTA, '(-) Depreciação Acumulada - Veículos e Máquin'        AS DESCRICAO, '1485' AS COD_CTA, '1485' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.2.5' AS CTA, '(-) Depreciação Acumulada - Outros Bens Corpó'        AS DESCRICAO, '880'  AS COD_CTA, '880'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.2.6' AS CTA, '(-) Redução de Exploração Ativo Biológico'            AS DESCRICAO, '1693' AS COD_CTA, '1693' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.2.7' AS CTA, '(-) Depreciação/Amortização - Direito de Uso Ativos'  AS DESCRICAO, '1984' AS COD_CTA, '1984' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.3'   AS CTA, '(-) Ajustes Avaliação Patrimonial - Bens Corp'        AS DESCRICAO, '1479' AS COD_CTA, '1479' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.3.4'   AS CTA, 'Imobilizações em Andamento'                           AS DESCRICAO, '1835' AS COD_CTA, '1835' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.4'     AS CTA, 'Intangível'                                           AS DESCRICAO, '1440' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.4.1'   AS CTA, 'Bens Incorpóreos'                                     AS DESCRICAO, '1441' AS COD_CTA, '1441' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.4.2'   AS CTA, '(-) Ajustes Avaliação Patrimonial - Bens Intangível'  AS DESCRICAO, '1480' AS COD_CTA, '1480' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.5'     AS CTA, 'Diferido'                                             AS DESCRICAO, '15'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.5.1'   AS CTA, 'Ativo Diferido'                                       AS DESCRICAO, '794'  AS COD_CTA, '794'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.2.5.2'   AS CTA, '(-) Amortização Acumulada'                            AS DESCRICAO, '113'  AS COD_CTA, '113'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.3'       AS CTA, 'Compensação (Ativo)'                                  AS DESCRICAO, '679'  AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '1.3.1'     AS CTA, 'Compensação - Ativo'                                  AS DESCRICAO, '722'  AS COD_CTA, '722'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.0'       AS CTA, 'Passivo e Patrimônio Líquido'                         AS DESCRICAO, '16'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.1'       AS CTA, 'Passivo Circulante'                                   AS DESCRICAO, '302'  AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.1.1'     AS CTA, 'Obrigações'                                           AS DESCRICAO, '999'  AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.1.1.1'   AS CTA, 'Empréstimos e Financiamentos'                         AS DESCRICAO, '17'   AS COD_CTA, '17'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.1.1.2'   AS CTA, 'Cooperados Valores a Pagar'                           AS DESCRICAO, '18'   AS COD_CTA, '18'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.1.1.3'   AS CTA, 'Fornecedores'                                         AS DESCRICAO, '19'   AS COD_CTA, '19'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.1.1.4'   AS CTA, 'Tributárias e Fiscais'                                AS DESCRICAO, '929'  AS COD_CTA, '929'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.1.1.5'   AS CTA, 'Sociais e Trabalhistas'                               AS DESCRICAO, '1445' AS COD_CTA, '1445' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.1.1.6'   AS CTA, 'Outras Obrigações'                                    AS DESCRICAO, '20'   AS COD_CTA, '20'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.1.1.7'   AS CTA, 'Arrendamento Mercantil a Pagar'                       AS DESCRICAO, '1985' AS COD_CTA, '1985' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.1.1.8'   AS CTA, '(-) Ajustes a Valor Presente - Curto Prazo'           AS DESCRICAO, '1481' AS COD_CTA, '1481' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.2'       AS CTA, 'Passivo Não Circulante'                               AS DESCRICAO, '1472' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.2.1'     AS CTA, 'Obrigações - Longo Prazo'                             AS DESCRICAO, '21'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.2.1.1'   AS CTA, 'Empréstimos e Financiamentos - L.P.'                  AS DESCRICAO, '317'  AS COD_CTA, '317'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.2.1.2'   AS CTA, 'Cooperados Valores a Pagar - L.P.'                    AS DESCRICAO, '318'  AS COD_CTA, '318'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.2.1.3'   AS CTA, 'Fornecedores - L.P.'                                  AS DESCRICAO, '1446' AS COD_CTA, '1446' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.2.1.4'   AS CTA, 'Tributárias - L.P.'                                   AS DESCRICAO, '1447' AS COD_CTA, '1447' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.2.1.5'   AS CTA, 'Sociais e Trabalhistas - L.P.'                        AS DESCRICAO, '1448' AS COD_CTA, '1448' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.2.1.6'   AS CTA, 'Provisões Fiscais - L.P.'                             AS DESCRICAO, '1449' AS COD_CTA, '1449' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.2.1.7'   AS CTA, 'Outras Obrigações - L.P.'                             AS DESCRICAO, '320'  AS COD_CTA, '320'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.2.1.8'   AS CTA, 'Arrendamento Mercantil a Pagar - LP'                  AS DESCRICAO, '1986' AS COD_CTA, '1986' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.2.1.9'   AS CTA, '(-) Ajustes a Valor Presente - L.P.'                  AS DESCRICAO, '1482' AS COD_CTA, '1482' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3'       AS CTA, 'Patrimônio Líquido'                                   AS DESCRICAO, '22'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3.1'     AS CTA, 'Capital Social Integralizado'                         AS DESCRICAO, '1375' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3.1.1'   AS CTA, 'Capital Social Subscrito'                             AS DESCRICAO, '23'   AS COD_CTA, '23'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3.1.2'   AS CTA, '(-) Capital a Integralizar'                           AS DESCRICAO, '24'   AS COD_CTA, '24'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3.2'     AS CTA, 'Reserva de Capital'                                   AS DESCRICAO, '25'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3.2.1'   AS CTA, 'Doações e Subvenções Fiscais'                         AS DESCRICAO, '1486' AS COD_CTA, '1486' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3.2.2'   AS CTA, 'Outras Reservas de Capital'                           AS DESCRICAO, '1487' AS COD_CTA, '1487' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3.3'     AS CTA, 'Ajuste de Avaliação Patrimonial.'                     AS DESCRICAO, '1502' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3.3.1'   AS CTA, 'Ajuste Avaliação Patrimonial'                         AS DESCRICAO, '1343' AS COD_CTA, '1343' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3.3.2'   AS CTA, 'Reserva de Reavaliação'                               AS DESCRICAO, '122'  AS COD_CTA, '122'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3.4'     AS CTA, 'Reserva de Sobras'                                    AS DESCRICAO, '1450' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3.4.1'   AS CTA, 'Reserva Legal'                                        AS DESCRICAO, '26'   AS COD_CTA, '26'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3.4.2'   AS CTA, 'RATES /FATES'                                         AS DESCRICAO, '1549' AS COD_CTA, '1549' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3.4.3'   AS CTA, 'Outras Reservas'                                      AS DESCRICAO, '27'   AS COD_CTA, '27'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3.5'     AS CTA, 'Sobra/Perda Líquida a Disposição da AGO'              AS DESCRICAO, '28'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3.5.1'   AS CTA, 'Sobras / Perdas do Exercício'                         AS DESCRICAO, '856'  AS COD_CTA, '856'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.3.5.2'   AS CTA, 'Sobras/Perdas Aguardando Deliberação AGO'             AS DESCRICAO, '1045' AS COD_CTA, '1045' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.4'       AS CTA, 'Compensação (Passivo)'                                AS DESCRICAO, '680'  AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '2.4.1'     AS CTA, 'Compensação - Passivo'                                AS DESCRICAO, '735'  AS COD_CTA, '735'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.0'       AS CTA, 'Contas de Resultado'                                  AS DESCRICAO, '29'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.1'       AS CTA, 'Ingressos e Receitas Brutas (Liq. Devolução)'         AS DESCRICAO, '30'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.1.1'     AS CTA, 'de Vendas'                                            AS DESCRICAO, '642'  AS COD_CTA, '642'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.1.2'     AS CTA, 'Receitas Operacionais de Serviços'                    AS DESCRICAO, '135'  AS COD_CTA, '135'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.2'       AS CTA, '(-) Deduções e Impostos/Contrib. Vendas/Serviços'     AS DESCRICAO, '1497' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.3'       AS CTA, 'Ingressos e Receitas Líquidas'                        AS DESCRICAO, '32'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.4'       AS CTA, '(-) Dispêndios e Custos'                              AS DESCRICAO, '33'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.4.1'     AS CTA, 'Repasse a Cooperados - Vendas'                        AS DESCRICAO, '1489' AS COD_CTA, '1489' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.4.2'     AS CTA, 'Repasse a Cooperados - Serviços'                      AS DESCRICAO, '1490' AS COD_CTA, '1490' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.4.3'     AS CTA, 'Dispêndios e Custos de Vendas'                        AS DESCRICAO, '1491' AS COD_CTA, '1491' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.4.4'     AS CTA, 'Dispêndios e Custos de Serviços'                      AS DESCRICAO, '1492' AS COD_CTA, '1492' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.5'       AS CTA, '(=) Sobra/Margem Bruta=Margem de Contribuição'        AS DESCRICAO, '34'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.6'       AS CTA, '(-) Dispêndios e Despesas Operacionais'               AS DESCRICAO, '35'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.6.1'     AS CTA, 'Comerciais'                                           AS DESCRICAO, '36'   AS COD_CTA, '36'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.6.2'     AS CTA, 'de Pessoal'                                           AS DESCRICAO, '37'   AS COD_CTA, '37'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.6.3'     AS CTA, 'Administrativas'                                      AS DESCRICAO, '38'   AS COD_CTA, '38'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.6.4'     AS CTA, 'Tributárias'                                          AS DESCRICAO, '39'   AS COD_CTA, '39'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.6.5'     AS CTA, 'Técnicas'                                             AS DESCRICAO, '40'   AS COD_CTA, '40'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.6.6'     AS CTA, 'de Depreciação'                                       AS DESCRICAO, '800'  AS COD_CTA, '800'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.6.7'     AS CTA, 'Outras'                                               AS DESCRICAO, '641'  AS COD_CTA, '641'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.7'       AS CTA, 'Outros Resultados Operacionais'                       AS DESCRICAO, '1493' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.7.1'     AS CTA, 'Outros Ingressos e Receitas Operacionais'             AS DESCRICAO, '47'   AS COD_CTA, '47'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.7.2'     AS CTA, '(-) Outros Dispêndios Operacionais e Patrimoniais'    AS DESCRICAO, '48'   AS COD_CTA, '48'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.8'       AS CTA, 'Resultado de Equivalência Patrimonial'                AS DESCRICAO, '1457' AS COD_CTA, '1457' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.9'       AS CTA, 'Resultado de Operações Com Coligadas/Controla'        AS DESCRICAO, '644'  AS COD_CTA, '644'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.10'      AS CTA, 'Sobra/Perda Operacional (Antes Result Financ)'        AS DESCRICAO, '41'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.11'      AS CTA, 'Resultado Financeiro Líquido'                         AS DESCRICAO, '42'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.11.1'    AS CTA, 'Ingressos e Receitas Financeiras'                     AS DESCRICAO, '43'   AS COD_CTA, '43'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.11.2'    AS CTA, '(-) Dispêndios e Despesas Financeiras'                AS DESCRICAO, '44'   AS COD_CTA, '44'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.12'      AS CTA, '(=) Sobra/Perda Exercício=Resultado Liq.Oper.'        AS DESCRICAO, '45'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.13'      AS CTA, '(-) Provisão de Impostos S/ Resultado'                AS DESCRICAO, '1458' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.13.1'    AS CTA, 'Provisão IRPJ'                                        AS DESCRICAO, '647'  AS COD_CTA, '647'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.13.2'    AS CTA, 'Provisão CSLL'                                        AS DESCRICAO, '1459' AS COD_CTA, '1459' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.14'      AS CTA, 'Sobra/Perda Líquida Exercício (Antes Ajustes)'        AS DESCRICAO, '1494' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.15'      AS CTA, '(+/-) Ajustes Legais'                                 AS DESCRICAO, '1460' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.15.1'    AS CTA, '(-) Destinação Reserva de Incentivos Fiscais'         AS DESCRICAO, '1461' AS COD_CTA, '1461' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.15.2'    AS CTA, '(-) Créditos Fiscais a Realizar'                      AS DESCRICAO, '1462' AS COD_CTA, '1462' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.15.3'    AS CTA, '(+) Realização Reserva Reavaliação'                   AS DESCRICAO, '1463' AS COD_CTA, '1463' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.16'      AS CTA, 'Sobra/Perda Líquida Exercício (Antes Destin)'         AS DESCRICAO, '49'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.17'      AS CTA, '(+/-) Destinações Legais e Estatutárias'              AS DESCRICAO, '50'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.17.1'    AS CTA, '(-) Reserva Legal'                                    AS DESCRICAO, '52'   AS COD_CTA, '52'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.17.2'    AS CTA, '(-) RATES / FATES'                                    AS DESCRICAO, '638'  AS COD_CTA, '638'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.17.3'    AS CTA, '(-) Part. resultado / antecipação sobras'             AS DESCRICAO, '51'   AS COD_CTA, '51'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.17.4'    AS CTA, '(-) Capitalização'                                    AS DESCRICAO, '639'  AS COD_CTA, '639'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.17.5'    AS CTA, '(-) Outras Reservas/Especificar'                      AS DESCRICAO, '53'   AS COD_CTA, '53'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.17.6'    AS CTA, '(+) Utilização de Reservas'                           AS DESCRICAO, '54'   AS COD_CTA, '54'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '3.18'      AS CTA, 'Sobras ou Perdas a Disposição da AGO'                 AS DESCRICAO, '55'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.0'       AS CTA, 'Informações Complementares'                           AS DESCRICAO, '56'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.1'       AS CTA, 'Compras'                                              AS DESCRICAO, '1467' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.1.1'     AS CTA, 'Compras e Fixações Acumuladas de Cooperados'          AS DESCRICAO, '57'   AS COD_CTA, '57'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.1.2'     AS CTA, 'Compras Acum.Terceiros (Prod.Mp.Insumos,Etc)'         AS DESCRICAO, '60'   AS COD_CTA, '60'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.2'       AS CTA, 'Devoluções/Cancelamento de Vendas e Serviços'         AS DESCRICAO, '1496' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.2.1'     AS CTA, 'Devoluções de Ingressos/Receitas de Vendas'           AS DESCRICAO, '646'  AS COD_CTA, '646'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.2.2'     AS CTA, 'Devoluções de Ingressos/Receitas de Serviços'         AS DESCRICAO, '1451' AS COD_CTA, '1451' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.3'       AS CTA, 'Composição Dos Impostos s/ Vendas e Serviços.'        AS DESCRICAO, '1811' AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.3.1'     AS CTA, 'ICMS'                                                 AS DESCRICAO, '645'  AS COD_CTA, '645'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.3.2'     AS CTA, 'IPI'                                                  AS DESCRICAO, '1453' AS COD_CTA, '1453' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.3.3'     AS CTA, 'PIS'                                                  AS DESCRICAO, '1454' AS COD_CTA, '1454' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.3.4'     AS CTA, 'COFINS'                                               AS DESCRICAO, '1455' AS COD_CTA, '1455' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.3.5'     AS CTA, 'ISS'                                                  AS DESCRICAO, '1456' AS COD_CTA, '1456' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.3.6'     AS CTA, 'INSS'                                                 AS DESCRICAO, '1695' AS COD_CTA, '1695' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.4'       AS CTA, 'Exportações Acumuladas'                               AS DESCRICAO, '58'   AS COD_CTA, '58'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.5'       AS CTA, 'Importações Acumuladas'                               AS DESCRICAO, '59'   AS COD_CTA, '59'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.6'       AS CTA, 'Depreciações Apropriadas no Custo ou Estoque'         AS DESCRICAO, '1495' AS COD_CTA, '1495' AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.7'       AS CTA, 'Detalhamento das Receitas Totais - Líquidas'          AS DESCRICAO, '62'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.7.1'     AS CTA, 'Cereais/Grãos/Oleoginosas'                            AS DESCRICAO, '63'   AS COD_CTA, '63'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.7.2'     AS CTA, 'Pecuários'                                            AS DESCRICAO, '64'   AS COD_CTA, '64'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.7.3'     AS CTA, 'Industrializados'                                     AS DESCRICAO, '65'   AS COD_CTA, '65'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.7.4'     AS CTA, 'Insumos Agropecuários'                                AS DESCRICAO, '66'   AS COD_CTA, '66'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.7.5'     AS CTA, 'Bens de Fornecimento (mercado/loja/prod.vet)'         AS DESCRICAO, '67'   AS COD_CTA, '67'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.7.6'     AS CTA, 'Hortifruticultura'                                    AS DESCRICAO, '68'   AS COD_CTA, '68'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.7.7'     AS CTA, 'Serviços'                                             AS DESCRICAO, '69'   AS COD_CTA, '69'   AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.7.8'     AS CTA, 'Outros'                                               AS DESCRICAO, '70'   AS COD_CTA, ''     AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.7.8.1'   AS CTA, 'Produtos Agropecuários'                               AS DESCRICAO, '795'  AS COD_CTA, '795'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.7.8.2'   AS CTA, 'Produtos Comerciais / Consumo'                        AS DESCRICAO, '796'  AS COD_CTA, '796'  AS CTA_TXT"
	_oSQL:_sQuery +=     " UNION ALL SELECT '4.7.8.3'   AS CTA, 'Outros Produtos'                                      AS DESCRICAO, '810'  AS COD_CTA, '810'  AS CTA_TXT"
	//_oSQL:_sQuery +=     " UNION ALL SELECT '5.0'       AS CTA, 'Informações Sociais e Políticas'                      AS DESCRICAO, '1084' AS COD_CTA, ''     AS CTA_TXT"
	//_oSQL:_sQuery +=     " UNION ALL SELECT '5.1'       AS CTA, 'Quantidade de Associados Total'                       AS DESCRICAO, '1466' AS COD_CTA, '1466' AS CTA_TXT"
	//_oSQL:_sQuery +=     " UNION ALL SELECT '5.2'       AS CTA, 'Quantidade de Associados Ativos'                      AS DESCRICAO, '1085' AS COD_CTA, '1085' AS CTA_TXT"
	//_oSQL:_sQuery +=     " UNION ALL SELECT '5.3'       AS CTA, 'Quantidade de Funcionários'                           AS DESCRICAO, '1086' AS COD_CTA, '1086' AS CTA_TXT"
	//_oSQL:_sQuery +=     " UNION ALL SELECT '5.4'       AS CTA, 'Quantidade de Admissões no Mês'                       AS DESCRICAO, '1465' AS COD_CTA, '1465' AS CTA_TXT"
	//_oSQL:_sQuery +=     " UNION ALL SELECT '5.5'       AS CTA, 'Quantidade de Demissões no Mês'                       AS DESCRICAO, '1464' AS COD_CTA, '1464' AS CTA_TXT"
	_oSQL:_sQuery += " )"
	
	// Clausula WITH para buscar o relacionamento de-para entre o plano de contas da SESCOOP e o nosso, que
	// foi definido usando a visao gerencial 517
	_oSQL:_sQuery += " ,DE_PARA AS"
	_oSQL:_sQuery += " ( SELECT CTS_FORMUL, CT1_CONTA, CT1_DESC01"
	_oSQL:_sQuery +=     " FROM " + RetSQLName ("CTS") + " CTS,"
	_oSQL:_sQuery +=                RetSQLName ("CT1") + " CT1"
	_oSQL:_sQuery +=    " WHERE CTS.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=      " AND CTS.CTS_FILIAL = '" + xfilial ("CTS") + "'"
	_oSQL:_sQuery +=      " AND CTS.CTS_CODPLA in " + FormatIn (alltrim (mv_par08), '/')
	_oSQL:_sQuery +=      " AND CTS.CTS_CT1INI <= CT1.CT1_CONTA"
	_oSQL:_sQuery +=      " AND CTS.CTS_CT1FIM >= CT1.CT1_CONTA"
	_oSQL:_sQuery +=      " AND CT1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=      " AND CT1.CT1_FILIAL = '" + xfilial ("CT1") + "'"
	_oSQL:_sQuery +=      " AND CT1.CT1_CLASSE = '2'"
	_oSQL:_sQuery += " )"

	// Clausula WITH para juntar o resultado do DE_PARA com os valores (saldos) das nossas contas
	_oSQL:_sQuery += " ,VALORES AS"
	_oSQL:_sQuery += " (SELECT PLANO_SESCOOP.CTA, PLANO_SESCOOP.CTA_TXT, PLANO_SESCOOP.DESCRICAO, DE_PARA.CT1_CONTA, DE_PARA.CT1_DESC01"

	// Contas 1 e 2: busca o saldo acumulado do periodo.
	_oSQL:_sQuery +=        ", CASE WHEN SUBSTRING(CT1_CONTA, 1, 1) IN ('1', '2')"
	_oSQL:_sQuery +=             " THEN ISNULL ((SELECT SUM(CQ0_DEBITO - CQ0_CREDIT)"
	_oSQL:_sQuery +=                             " FROM " + RetSQLName ("CQ0") + " CQ0 "
	_oSQL:_sQuery +=                            " WHERE CQ0.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                              " AND CQ0.CQ0_CONTA = CT1_CONTA"
	_oSQL:_sQuery +=                              " AND CQ0.CQ0_TPSALD = '1'"
	_oSQL:_sQuery +=                              " AND CQ0.CQ0_DATA  <= '" + dtos (_dUltDiaMes) + "'), 0)"
//	if month (_dUltDiaMes) > 1
//		_dUDMesAnt  := lastday (stod (mv_par01 + tira1 (mv_par02) + '01'))  // Quando for janeiro, vai dar mes = '00' mas nesse caso nao devo passar por aqui...
//		_oSQL:_sQuery +=                " - ISNULL ((SELECT SUM(CQ0_DEBITO - CQ0_CREDIT)"
//		_oSQL:_sQuery +=                             " FROM " + RetSQLName ("CQ0") + " CQ0 "
//		_oSQL:_sQuery +=                            " WHERE CQ0.D_E_L_E_T_ = ''"
//		_oSQL:_sQuery +=                              " AND CQ0.CQ0_CONTA = CT1_CONTA"
//		_oSQL:_sQuery +=                              " AND CQ0.CQ0_TPSALD = '1'"
//		_oSQL:_sQuery +=                              " AND CQ0.CQ0_DATA  <= '" + dtos (_dUDMesAnt) + "'), 0)"
//	endif
	
	// Demais contas: saldo acumulado.
	_oSQL:_sQuery +=             " ELSE ISNULL ((SELECT SUM(CQ2_DEBITO - CQ2_CREDIT)"
	_oSQL:_sQuery +=                             " FROM CQ2010 CQ2"
	_oSQL:_sQuery +=                            " WHERE CQ2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                              " AND CQ2.CQ2_CONTA = CT1_CONTA"
	_oSQL:_sQuery +=                              " AND CQ2.CQ2_TPSALD = '1'"
	_oSQL:_sQuery +=                              " AND CQ2.CQ2_DATA   BETWEEN '" + mv_par01 + "0101' AND '" + dtos (_dUltDiaMes) + "'), 0)"
//	_oSQL:_sQuery +=                              " AND CQ2.CQ2_DATA   BETWEEN '" + mv_par01 + mv_par02 + "01' AND '" + dtos (_dUltDiaMes) + "'), 0)"
/*
	if month (_dUltDiaMes) > 1
		_dUDMesAnt  := lastday (stod (mv_par01 + tira1 (mv_par02) + '01'))  // Quando for janeiro, vai dar mes = '00' mas nesse caso nao devo passar por aqui...
		_oSQL:_sQuery +=                " - ISNULL ((SELECT SUM(CQ2_DEBITO - CQ2_CREDIT)"
		_oSQL:_sQuery +=                                 " FROM CQ2010 CQ2"
		_oSQL:_sQuery +=                                " WHERE CQ2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                                  " AND CQ2.CQ2_CONTA = CT1_CONTA"
		_oSQL:_sQuery +=                                  " AND CQ2.CQ2_TPSALD = '1'"
		_oSQL:_sQuery +=                                  " AND CQ2.CQ2_DATA   BETWEEN '" + mv_par01 + "0101' AND '" + dtos (_dUDMesAnt) + "'), 0)"
	endif
*/
	_oSQL:_sQuery +=             " END AS SALDO"
	_oSQL:_sQuery +=  " FROM PLANO_SESCOOP "
	
	// usa LEFT JOIN por que todas as contas analiticas (CTA_TXT != '') do plano da SESCOOP devem ser exportadas, mesmo que com valor zerado.
	_oSQL:_sQuery +=       " LEFT JOIN DE_PARA ON (DE_PARA.CTS_FORMUL = PLANO_SESCOOP.CTA_TXT)"
	_oSQL:_sQuery += " )"
	
	if mv_par07 == 1  // Gerar uma planilha detalhada para conferencia de valores
		_oSQL:_sQuery += " SELECT * FROM VALORES ORDER BY CTA"
	else  // Gerar o arquivo para upload no site da SESCOOP
		_oSQL:_sQuery += " SELECT CTA_TXT, SUM (SALDO) AS SALDO"
		_oSQL:_sQuery +=   " FROM VALORES"
		_oSQL:_sQuery +=  " WHERE CTA_TXT != ''"
		_oSQL:_sQuery +=  " GROUP BY CTA, CTA_TXT"
		_oSQL:_sQuery +=  " ORDER BY CTA"  // A SESCOOP solicita nesta mesma ordenacao.
	endif
	_oSQL:Log ()

	if mv_par07 == 1  // Gerar uma planilha detalhada para conferencia de valores
		_oSQL:Qry2XLS (.F., .F., .F.)
	else
		_sAliasQ = _oSQL:Qry2Trb (.f.)
		do while ! (_sAliasQ) -> (eof ())
			fwrite (_nHdl, alltrim ((_sAliasQ) -> cta_txt) + ';' + cvaltochar (int (abs ((_sAliasQ) -> SALDO * 100))) + '+' + chr (13) + chr (10))
			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())

		incproc ("Buscando dados de associados")

		// Leitura dos associados.
		// Se tem algum lancamento no SZI, eh por que foi ou ainda eh associado.
		// Se varrer todo o SA2 ficaria demorado demais para tentar instanciar cada um como associado.
		// Busca codigo e loja base para nao repetir a mesma pessoa.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery += "SELECT A2_COD, A2_LOJA"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SA2") + " SA2 "
		_oSQL:_sQuery += " WHERE SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
		_oSQL:_sQuery +=   " AND SA2.A2_COD = SA2.A2_VACBASE"
		_oSQL:_sQuery +=   " AND SA2.A2_LOJA = SA2.A2_VALBASE"

		// testes --> _oSQL:_sQuery +=   " AND SA2.A2_COD <= '000200'"

		_oSQL:_sQuery +=   " AND EXISTS (SELECT *"
		_oSQL:_sQuery +=                 " FROM " + RetSQLName ("SZI") + " SZI "
		_oSQL:_sQuery +=                " WHERE SZI.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                  " AND SZI.ZI_ASSOC   = SA2.A2_COD"
		_oSQL:_sQuery +=                  " AND SZI.ZI_LOJASSO = SA2.A2_LOJA"
		_oSQL:_sQuery +=                  " AND SZI.ZI_DATA   <= '" + dtos (_dUltDiaMes) + "')"
		_oSQL:_sQuery += " ORDER BY A2_COD"
		_oSQL:Log ()
		_sAliasQ = _oSQL:Qry2Trb ()
		procregua ((_sAliasQ) -> (reccount ()))
		do while ! (_sAliasQ) -> (eof ())
			u_log ((_sAliasQ) -> a2_cod)

			// Instancia classe para verificacao dos dados do associado.
			_oAssoc := ClsAssoc():New ((_sAliasQ) -> a2_cod, (_sAliasQ) -> a2_loja)
			incproc (_oAssoc:Nome)

			if _oAssoc:EhSocio (_dUltDiaMes)
				_nQtTotAs ++
			endif
			if _oAssoc:Ativo (_dUltDiaMes)
				_nQtAsAtiv ++
			endif
			(_sAliasQ) -> (dbskip ())
		enddo

		// Quantidade total de associados
		fwrite (_nHdl, '1466;' + cvaltochar (int (_nQtTotAs * 100)) + '+' + chr (13) + chr (10))

		// Quantidade de associados ativos
		fwrite (_nHdl, '1085;' + cvaltochar (int (_nQtAsAtiv * 100)) + '+' + chr (13) + chr (10))

		// Quantidade de funcionarios
		fwrite (_nHdl, '1086;' + cvaltochar (int (_nQtFunc * 100)) + '+' + chr (13) + chr (10))

		// Quantidade de admissoes no mes
		fwrite (_nHdl, '1465;' + cvaltochar (int (_nQtAdmis * 100)) + '+' + chr (13) + chr (10))

		// Quantidade de demissoes no mes
		fwrite (_nHdl, '1464;' + cvaltochar (int (_nQtDemis * 100)) + '+' + chr (13) + chr (10))

		fwrite (_nHdl, 'fim;' + _sIniFim + chr (13) + chr (10))
		fclose (_nHdl)
	endif

	dbselectarea ("CT1")
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                                Help
	aadd (_aRegsPerg, {01, "Ano (com 4 digitos)           ", "C", 4,  0,  "",   "      ", {},                                   ""})
	aadd (_aRegsPerg, {02, "Mes (com 2 digitos)           ", "C", 2,  0,  "",   "      ", {},                                   ""})
	aadd (_aRegsPerg, {03, "Arquivo destino               ", "C", 60, 0,  "",   "      ", {},                                   ""})
	aadd (_aRegsPerg, {04, "Quantidade de funcionarios    ", "N", 6,  0,  "",   "      ", {},                                   ""})
	aadd (_aRegsPerg, {05, "Admissoes no mes              ", "N", 6,  0,  "",   "      ", {},                                   ""})
	aadd (_aRegsPerg, {06, "Demissoes no mes              ", "N", 6,  0,  "",   "      ", {},                                   ""})
	aadd (_aRegsPerg, {07, "Conferencia valores contabeis?", "N", 1,  0,  "",   "      ", {'Sim (planilha)', 'Nao(gera arq.)'}, ""})
	aadd (_aRegsPerg, {08, "Visoes ger.(ex:517/518/519)  ?", "C", 60, 0,  "",   "      ", {},                                   ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
