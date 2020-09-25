//  Programa...: ML_ICM2
//  Autor......: Catia Cardoso
//  Data.......: 10/07/2019
//  Descricao..: Analise -  Apuracao Credito Presumido
// 
// Historico de alteracoes:
// 08/01/2020 - Andre   - Ajustado tamanho da tela, não estava aparecendo os botões.
//						  Acrescentado a seleção de filial.
//
// --------------------------------------------------------------------------
User Function ML_RICM2()

	cPerg   := "ML_RICM2"
	
	_ValidPerg()
	if Pergunte(cPerg,.T.)
	
		// Busca dados para impressao
		_sSQL := " select D2_FILIAL, D2_EMISSAO, D2_DOC, D2_SERIE, D2_COD"
		_sSQL += " 		, SB1.B1_DESC"
		_sSQL += " 		, SB1.B1_TIPO"
		_sSQL += " 		, D2_CLIENTE"
		_sSQL += " 		, SA1.A1_INSCR"
		_sSQL += " 		, D2_TES"
		_sSQL += " 		, D2_CF"
		_sSQL += " 		, D2_BASEICM, D2_PICM, D2_VALICM, D2_TOTAL"
		_sSQL += " 		, ((D2_BASEICM * '" + cvaltochar (mv_par05) + "') / 100) AS ICMS"
		_sSQL +=  " from " + RETSQLNAME ("SB1") + " SB1, "
		_sSQL +=             RETSQLNAME ("SD2") + " SD2, "
		_sSQL +=             RETSQLNAME ("SA1") + " SA1  "
		_sSQL += " where SA1.D_E_L_E_T_ != '*'"
		_sSQL +=   " AND SD2.D_E_L_E_T_ != '*'"
		_sSQL +=   " AND SB1.D_E_L_E_T_ != '*'"
		_sSQL +=   " and SA1.A1_FILIAL  = '" + xfilial ("SA1")  + "'"
		_sSQL +=   " and SB1.B1_FILIAL  = '" + xfilial ("SB1")  + "'"
//		_sSQL +=   " and SD2.D2_FILIAL  = '" + xfilial ("SD2")  + "'"
		_sSQL +=   " and SD2.D2_FILIAL  BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
		_sSQL +=   " and SA1.A1_COD     = D2_CLIENTE"
		_sSQL +=   " and SA1.A1_LOJA    = D2_LOJA"
		_sSQL +=   " and SB1.B1_COD     = D2_COD"
		_sSQL +=   " and SD2.D2_EMISSAO between '" + dtos (mv_par03) + "' and '" + dtos (mv_par04) + "'"
		_sSQL +=   " and SD2.D2_EST     = '" + GetMv ("MV_ESTADO") + "'"
		_sSQL +=   " and SD2.D2_TIPO   != 'D'"
		_sSQL +=   " and SD2.D2_TIPO   != 'B'"
		_sSQL +=   " and SD2.D2_CF     != '5151'"  // Transf. entre filiais
		_sSQL +=   " and SB1.B1_VAGCPI = '" + cvaltochar (mv_par06) + "'"
		_sSQL +=   " and SA1.A1_INSCR  != ''"
		if mv_par07 == 2
			_sSQL +=   " and SA1.A1_INSCR  != 'ISENTO'"
		endif
		_sSQL +=   " ORDER BY D2_FILIAL, D2_EMISSAO, D2_DOC, D2_COD"
		
	   //u_showmemo (_sSQL)
		   
		_aDados := U_Qry2Array(_sSQL)
		_aCols = {}
		
		aadd (_aCols, { 1,  "Filial"     ,   2,  "@D"})
		aadd (_aCols, { 2,  "Emissao"    ,  30,  "@D"})
		aadd (_aCols, { 3,  "Nota"    	 ,  30,  "@!"})
		aadd (_aCols, { 4,  "Serie"   	 ,  10,  "@!"})
		aadd (_aCols, { 5,  "Produto"    ,  30,  "@!"})
		aadd (_aCols, { 6,  "Descricao"  , 110,  "@!"})
		aadd (_aCols, { 7,  "Tipo"  	 ,  10,  "@!"})
		aadd (_aCols, { 8,  "Cliente"    ,  30,  "@!"})
		aadd (_aCols, { 9,  "Inscricao"  ,  40,  "@!"})
		aadd (_aCols, {10,  "TES"    	 ,  20,  "@!"})
		aadd (_aCols, {11,  "CF"  	     ,  20,  "@!"})
		aadd (_aCols, {12,  "Base ICMS"  ,  50,  "@E 9,999,999.99"})
		aadd (_aCols, {13,  "%ICMS"      ,  35,  "@E 999.99"})
		aadd (_aCols, {14,  "Valor ICMS" ,  50,  "@E 9,999,999.99"})
		aadd (_aCols, {15,  "Total Nota" ,  50,  "@E 9,999,999.99"})
		aadd (_aCols, {16,  "% ICMS"     ,  50,  "@E 9,999,999.99"})
		
		U_F3Array (_aDados, "Analise Credito Presumido", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -40 , "", "", .T., 'C' )
	endif	
return	

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	aadd (_aRegsPerg, {01, "Filial de                     ", "C", 2,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Filial ate                    ", "C", 2,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {03, "Data inicial emissao NF       ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {04, "Data final emissao NF         ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {05, "% credito presumido           ", "N", 6,  2,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {06, "Grupo a considerar            ", "C", 1,  0,  "",   "   ", {'Sucos', 'Vinhos'}, ""})
	aadd (_aRegsPerg, {07, "Considera inscr.est. ISENTO  ?", "N", 1,  0,  "",   "   ", {'Sim', 'Nao'},    ""})
	U_ValPerg (cPerg, _aRegsPerg)
return
