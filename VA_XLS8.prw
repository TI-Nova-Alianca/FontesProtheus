// Programa...: VA_XLS8
// Autor......: Robert Koch
// Data.......: 27/06/2011
// Cliente....: Alianca
// Descricao..: Exportacao de lancamentos contabeis para planilha.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function VA_XLS8 (_lAutomat)
	Local cCadastro := "Exportacao de lancamentos contabeis para planilha"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	private _sArqLog := U_NomeLog ()
	Private cPerg   := "VAXLS8"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	U_AvisaTI ('Programa ' + procname () + ', colocado na lista de fuzilamento em 19/08/2015, acaba de ser executado por ' + alltrim (cUserName) + '. Reveja sua lista!')

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo gerar uma")
		AADD(aSays,"exportacao de lancamentos contabeis para planilha")
		AADD(aSays,"")
		
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
Static Function _Gera()
	local _lContinua   := .T.
	local _sQuery      := ""
	local _sAliasQ     := ""
	local _nEmpFil	   := 0
	local _aSM0        := {}
	private _aEmpFil   := {}   // Deixar private para ser vista pelas funcoes de detalhamento
	private _sFilCT1   := ""
	private _sFiliais  := ""   // Deixar private para ser vista pelas funcoes de detalhamento

	procregua (4)
	incproc ()
	

	// Em 01/01/2011 iniciamos o uso de um novo plano de contas. O plano antigo ficou guardado com filial XX.
	if _lContinua
		if mv_par05 < stod ('20110101') .and. mv_par06 >= stod ('20110101')
			u_help ("Devido `a troca do plano de contas em 01/01/2011, esta consulta deve ser feita separadamente para periodos anteriores e posteriores a esaa data.")
			_lContinua = .F.
		endif
		if mv_par05 < stod ('20110101')
			_sFilCT1 = 'XX'
		else
			_sFilCT1 = '  '  // Tabela compartilhada
		endif
	endif


	// Define empresas e filiais a serem lidas.
	if _lContinua
		if mv_par01 == 1  // Apenas empresa atual
			if mv_par02 == 1  // Apenas filial atual
				_aEmpFil = {}
				aadd (_aEmpfil, {cEmpAnt, {cFilAnt}, cFilAnt, sm0 -> m0_nome})
			else
				_aEmpFil = U_LeSM0 ('6', cEmpAnt, '', '')
			endif
		else
			_aEmpFil = U_LeSM0 ('6', '', '04/10/20', '')
		endif
		if len (_aEmpFil) == 0
			_lContinua = .F.
		endif
	endif


	// Leitura de dados.
	if _lContinua
		_sQuery := "WITH CTE AS ("

		// Monta query em loop com todas as empresas (cada empresa tem sua tabela CT2)
		// unindo os resultados das empresas com a clausula UNION do SQL.
		for _nEmpFil = 1 to len (_aEmpfil)
			_sQuery += " SELECT '" + _aEmpFil [_nEmpFil, 1] + "' AS EMPRESA,"
			_sQuery +=        " SM0.M0_NOME AS DESC_EMP,"
			_sQuery +=        " CT2_FILIAL AS FILIAL,"
			_sQuery +=        " SM0.M0_FILIAL AS DESC_FIL,"
			_sQuery +=        " CT2_DEBITO AS CTA_DEB,"
			_sQuery +=        " ISNULL(CT1D.CT1_DESC01, '') AS DESC_CT_DB,"
			_sQuery +=        " CT2_CREDIT AS CTA_CRED,"
			_sQuery +=        " ISNULL(CT1C.CT1_DESC01, '') AS DESC_CT_CR,"
			_sQuery +=        " SUBSTRING(CT2_DATA, 7, 2) + '/' + SUBSTRING(CT2_DATA, 5, 2) + '/' + SUBSTRING(CT2_DATA, 1, 4) AS DATA,"
			_sQuery +=        " CASE CT2_DEBITO WHEN '' THEN 0 ELSE CT2_VALOR END AS VALOR_DEB,"
			_sQuery +=        " CASE CT2_CREDIT WHEN '' THEN 0 ELSE CT2_VALOR END AS VALOR_CRED,"
			_sQuery +=        " CT2_CCD AS CC_DEBITO,"
			_sQuery +=        " ISNULL(CTTD.CTT_DESC01, '') AS DESC_CC_DB,"
			_sQuery +=        " CT2_CCC AS CC_CREDITO,"
			_sQuery +=        " ISNULL(CTTC.CTT_DESC01, '') AS DESC_CC_CR,"
			_sQuery +=        " CT2_HIST + ISNULL((SELECT CT2_HIST"
			_sQuery +=                             " FROM " + U_SQLName ("CT2", _aEmpFil [_nEmpFil, 1]) + " AS HIST1 "
			_sQuery +=                            " WHERE HIST1.D_E_L_E_T_ = ''"
			_sQuery +=                              " AND HIST1.CT2_FILIAL = CT2.CT2_FILIAL"
			_sQuery +=                              " AND HIST1.CT2_DATA = CT2.CT2_DATA"
			_sQuery +=                              " AND HIST1.CT2_LOTE = CT2.CT2_LOTE"
			_sQuery +=                              " AND HIST1.CT2_SBLOTE = CT2.CT2_SBLOTE"
			_sQuery +=                              " AND HIST1.CT2_DOC = CT2.CT2_DOC"
			_sQuery +=                              " AND HIST1.CT2_SEQLAN = CT2.CT2_SEQLAN"
			_sQuery +=                              " AND HIST1.CT2_SEQUEN = CT2.CT2_SEQUEN"
			_sQuery +=                              " AND HIST1.CT2_EMPORI = CT2.CT2_EMPORI"
			_sQuery +=                              " AND HIST1.CT2_FILORI = CT2.CT2_FILORI"
			_sQuery +=                              " AND HIST1.CT2_SEQHIS = '002'), '')"
			_sQuery +=                 " + ISNULL((SELECT CT2_HIST"
			_sQuery +=                             " FROM " + U_SQLName ("CT2", _aEmpFil [_nEmpFil, 1]) + " AS HIST1 "
			_sQuery +=                            " WHERE HIST1.D_E_L_E_T_ = ''"
			_sQuery +=                              " AND HIST1.CT2_FILIAL = CT2.CT2_FILIAL"
			_sQuery +=                              " AND HIST1.CT2_DATA = CT2.CT2_DATA"
			_sQuery +=                              " AND HIST1.CT2_LOTE = CT2.CT2_LOTE"
			_sQuery +=                              " AND HIST1.CT2_SBLOTE = CT2.CT2_SBLOTE"
			_sQuery +=                              " AND HIST1.CT2_DOC = CT2.CT2_DOC"
			_sQuery +=                              " AND HIST1.CT2_SEQLAN = CT2.CT2_SEQLAN"
			_sQuery +=                              " AND HIST1.CT2_SEQUEN = CT2.CT2_SEQUEN"
			_sQuery +=                              " AND HIST1.CT2_EMPORI = CT2.CT2_EMPORI"
			_sQuery +=                              " AND HIST1.CT2_FILORI = CT2.CT2_FILORI"
			_sQuery +=                              " AND HIST1.CT2_SEQHIS = '003'), '') AS HISTORICO,"
			_sQuery +=        " CT2_EMPORI AS EMPR_ORI,"
			_sQuery +=        " SM0_ORI.M0_NOME AS DESC_EM_OR,"
			_sQuery +=        " CT2_FILORI AS FILIAL_ORI,"
			_sQuery +=        " SM0_ORI.M0_FILIAL AS DESC_FL_ORI"
			_sQuery += " FROM VA_SM0 AS SM0,"
			_sQuery +=      " VA_SM0 AS SM0_ORI,"
			_sQuery +=      U_SQLName ("CT2", _aEmpFil [_nEmpFil, 1]) + " AS CT2 "
			_sQuery +=      " LEFT JOIN " + U_SQLName ("CT1", _aEmpFil [_nEmpFil, 1]) + " AS CT1D"
			_sQuery +=           " ON (CT1D.CT1_FILIAL = '" + _sFilCT1 + "'"
			_sQuery +=           " AND CT1D.D_E_L_E_T_ = ''"
			_sQuery +=           " AND CT1D.CT1_CONTA  = CT2.CT2_DEBITO)"
			_sQuery +=      " LEFT JOIN " + U_SQLName ("CT1", _aEmpFil [_nEmpFil, 1]) + " AS CT1C"
			_sQuery +=           " ON (CT1C.CT1_FILIAL = '" + _sFilCT1 + "'"
			_sQuery +=           " AND CT1C.D_E_L_E_T_ = ''"
			_sQuery +=           " AND CT1C.CT1_CONTA  = CT2.CT2_DEBITO)"
			_sQuery +=      " LEFT JOIN " + U_SQLName ("CTT", _aEmpFil [_nEmpFil, 1]) + " AS CTTD"
			_sQuery +=           " ON (CTTD.CTT_FILIAL = '" + _sFilCT1 + "'"
			_sQuery +=           " AND CTTD.D_E_L_E_T_ = ''"
			_sQuery +=           " AND CTTD.CTT_CUSTO  = CT2.CT2_CCD)"
			_sQuery +=      " LEFT JOIN " + U_SQLName ("CTT", _aEmpFil [_nEmpFil, 1]) + " AS CTTC"
			_sQuery +=           " ON (CTTC.CTT_FILIAL = '" + _sFilCT1 + "'"
			_sQuery +=           " AND CTTC.D_E_L_E_T_ = ''"
			_sQuery +=           " AND CTTC.CTT_CUSTO  = CT2.CT2_CCC)"
			_sQuery +=  " WHERE CT2.D_E_L_E_T_  = ''"
			_sQuery +=    " AND CT2.CT2_DATA    BETWEEN '" + dtos (mv_par05) + "' AND '" + dtos (mv_par06) + "'"
			_sQuery +=    " AND CT2.CT2_FILIAL  IN " + FormatIn (_aEmpFil [_nEmpFil, 3], '/')
			_sQuery +=    " AND (CT2.CT2_DEBITO BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
			_sQuery +=     " OR  CT2.CT2_CREDIT BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "')"
			_sQuery +=    " AND (CT2.CT2_CCD    BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
			_sQuery +=     " OR  CT2.CT2_CCC    BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "')"
 			_sQuery +=    " AND CT2_DC != '4'"  // Continuacao historico
 			_sQuery +=    " AND SM0.M0_CODIGO = '" + _aEmpFil [_nEmpFil, 1] + "'"
 			_sQuery +=    " AND SM0.M0_CODFIL = CT2.CT2_FILIAL"
 			_sQuery +=    " AND SM0_ORI.M0_CODIGO = CT2.CT2_EMPORI"
 			_sQuery +=    " AND SM0_ORI.M0_CODFIL = CT2.CT2_FILORI"
			_sQuery += iif (_nEmpFil < len (_aEmpFil), " UNION ALL ", "")
		next
		_sQuery += ")"
		_sQuery += " SELECT * "
		_sQuery +=   " FROM CTE "
		_sQuery +=  " ORDER BY EMPRESA, FILIAL, DATA"
		u_log (_sQuery)
		_sAliasQ = GetNextAlias ()
		DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)

		incproc ("Gerando arquivo de exportacao")
		processa ({ || U_Trb2XLS (_sAliasQ, .T., .T.)})
		(_sAliasQ) -> (dbclosearea ())
		dbselectarea ("CT2")
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                                 Help
	aadd (_aRegsPerg, {01, "Empresas para selecao         ", "N", 1,  0,  "",   "   ", {"Atual", "Todas"},                    "Indica se apresenta apenas a empresa atual para a selecao ou todas."})
	aadd (_aRegsPerg, {02, "Filiais (quando empresa atual)", "N", 1,  0,  "",   "   ", {"Atual", "Selecionar"},               "Indica se apresenta apenas a filial atual para a selecao ou todas."})
	aadd (_aRegsPerg, {03, "Conta contabil inicial        ", "C", 20, 0,  "",   "CT1", {},                                    "Codigo da conta contabil inicial a ser considerada."})
	aadd (_aRegsPerg, {04, "Conta contabil final          ", "C", 20, 0,  "",   "CT1", {},                                    "Codigo da conta contabil final a ser considerada."})
	aadd (_aRegsPerg, {05, "Data inicial                  ", "D", 8,  0,  "",   "   ", {},                                    "Data inicial para leitura dos dados das colunas mensais."})
	aadd (_aRegsPerg, {06, "Data final                    ", "D", 8,  0,  "",   "   ", {},                                    "Data final para leitura dos dados das colunas mensais."})
	aadd (_aRegsPerg, {07, "Centro de custo inicial       ", "C", 9,  0,  "",   "CTT", {},                                    "Codigo do centro de custo inicial a ser considerado."})
	aadd (_aRegsPerg, {08, "Centro de custo final         ", "C", 9,  0,  "",   "CTT", {},                                    "Codigo do centro de custo final a ser considerado."})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
