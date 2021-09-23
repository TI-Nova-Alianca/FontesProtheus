//  Programa...: ML_RICM2
//  Autor......: Catia Cardoso
//  Data.......: 10/07/2019
//  Descricao..: Analise -  Apuracao Credito Presumido
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Analise -  Apuracao Credito Presumido
// #PalavasChave      #apuracao_credito_presumido  
// #TabelasPrincipais #SB1 #SD2
// #Modulos   		  #FIS #FAT #EST 
//
// Historico de alteracoes:
// 08/01/2020 - Andre   - Ajustado tamanho da tela, não estava aparecendo os botões.
//						  Acrescentado a seleção de filial.
// 06/05/2021 - Claudia - Incluido tags de customizações
// 13/09/2021 - Claudia - Tratamento para A1_INSCR. GLPI: 10797
// 23/09/2021 - CLaudia - Incluida a opção de relatorio por entradas. GLPI: 10891
//
// ----------------------------------------------------------------------------------
User Function ML_RICM2()
	Local _oSQL  	:= ClsSQL ():New ()
	cPerg   := "ML_RICM2"
	
	_ValidPerg()
	if Pergunte(cPerg,.T.)
	
		if mv_par08 == 2 	// saidas
			// Busca dados para impressao
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT "
			_oSQL:_sQuery += "     D2_FILIAL "
			_oSQL:_sQuery += "    ,D2_EMISSAO "
			_oSQL:_sQuery += "    ,D2_DOC "
			_oSQL:_sQuery += "    ,D2_SERIE "
			_oSQL:_sQuery += "    ,D2_COD "
			_oSQL:_sQuery += "    ,B1_DESC "
			_oSQL:_sQuery += "    ,B1_TIPO "
			_oSQL:_sQuery += "    ,D2_CLIENTE "
			_oSQL:_sQuery += "    ,A1_INSCR "
			_oSQL:_sQuery += "    ,D2_TES "
			_oSQL:_sQuery += "    ,D2_CF "
			_oSQL:_sQuery += "    ,D2_BASEICM "
			_oSQL:_sQuery += "    ,D2_PICM "
			_oSQL:_sQuery += "    ,D2_VALICM "
			_oSQL:_sQuery += "    ,D2_TOTAL "
			_oSQL:_sQuery += "    ,((D2_BASEICM * '" + cvaltochar(mv_par05) + "') / 100) AS ICMS"
			_oSQL:_sQuery += " FROM SD2010 SD2 "
			_oSQL:_sQuery += " INNER JOIN SB1010 SB1 "
			_oSQL:_sQuery += " 	ON (SB1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SB1.B1_FILIAL = '" + xfilial("SB1")  + "'"
			_oSQL:_sQuery += " 			AND SB1.B1_COD = D2_COD "
			_oSQL:_sQuery += "          AND SB1.B1_VAGCPI = '" + cvaltochar(mv_par06) + "'"
			_oSQL:_sQuery += " 		) "
			_oSQL:_sQuery += " INNER JOIN SA1010 SA1 "
			_oSQL:_sQuery += " 	ON (SA1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SA1.A1_FILIAL = '" + xfilial("SA1")  + "'"
			_oSQL:_sQuery += " 			AND SA1.A1_COD = D2_CLIENTE "
			_oSQL:_sQuery += " 			AND SA1.A1_LOJA = D2_LOJA "
			if mv_par07 == 2
				_oSQL:_sQuery += " 		AND (SA1.A1_INSCR <> 'ISENTO' OR SA1.A1_INSCR <> '') "
			endif
			_oSQL:_sQuery += " 		) "
			_oSQL:_sQuery += " WHERE SD2.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " AND SD2.D2_FILIAL BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
			_oSQL:_sQuery += " AND SD2.D2_EMISSAO BETWEEN '" + dtos(mv_par03) + "' and '" + dtos(mv_par04) + "'"
			_oSQL:_sQuery += " AND SD2.D2_EST = '" + GetMv("MV_ESTADO") + "'"
			_oSQL:_sQuery += " AND SD2.D2_TIPO <> 'D' "
			_oSQL:_sQuery += " AND SD2.D2_TIPO <> 'B' "
			_oSQL:_sQuery += " AND SD2.D2_CF <> '5151' "
			_oSQL:_sQuery += " ORDER BY D2_FILIAL, D2_EMISSAO, D2_DOC, D2_COD "
			_oSQL:Log ()
		
			_aDados := aclone (_oSQL:Qry2Array ())

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
			
			U_F3Array (_aDados, "Analise Credito Presumido - Saidas", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -40 , "", "", .T., 'C' )
		
		else // entradas
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT "
			_oSQL:_sQuery += "     D1_FILIAL "
			_oSQL:_sQuery += "    ,D1_EMISSAO "
			_oSQL:_sQuery += "    ,D1_DOC "
			_oSQL:_sQuery += "    ,D1_SERIE "
			_oSQL:_sQuery += "    ,D1_COD "
			_oSQL:_sQuery += "    ,B1_DESC "
			_oSQL:_sQuery += "    ,B1_TIPO "
			_oSQL:_sQuery += "    ,D1_FORNECE "
			_oSQL:_sQuery += "    ,A2_INSCR "
			_oSQL:_sQuery += "    ,D1_TES "
			_oSQL:_sQuery += "    ,D1_CF "
			_oSQL:_sQuery += "    ,D1_BASEICM "
			_oSQL:_sQuery += "    ,D1_PICM "
			_oSQL:_sQuery += "    ,D1_VALICM "
			_oSQL:_sQuery += "    ,D1_TOTAL "
			_oSQL:_sQuery += "    ,((D1_BASEICM * '" + cvaltochar(mv_par05) + "') / 100) AS ICMS"
			_oSQL:_sQuery += " FROM SD1010 SD1 "
			_oSQL:_sQuery += " INNER JOIN SB1010 SB1 "
			_oSQL:_sQuery += " 	ON (SB1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SB1.B1_FILIAL = '" + xfilial("SB1")  + "'"
			_oSQL:_sQuery += " 			AND SB1.B1_COD = SD1.D1_COD "
			_oSQL:_sQuery += "          AND SB1.B1_VAGCPI = '" + cvaltochar(mv_par06) + "'"
			_oSQL:_sQuery += " 		) "
			_oSQL:_sQuery += " INNER JOIN SA2010 SA2 "
			_oSQL:_sQuery += " 	ON (SA2.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SA2.A2_FILIAL = '" + xfilial("SA2")  + "'"
			_oSQL:_sQuery += " 			AND SA2.A2_COD    = SD1.D1_FORNECE "
			_oSQL:_sQuery += " 			AND SA2.A2_LOJA   = SD1.D1_LOJA "
			_oSQL:_sQuery += " 			AND SA2.A2_EST    = '" + GetMv("MV_ESTADO") + "'"
			if mv_par07 == 2
				_oSQL:_sQuery += " 		AND (SA2.A2_INSCR <> 'ISENTO' OR SA2.A2_INSCR <> '') "
			endif
			_oSQL:_sQuery += " 		)  "
			_oSQL:_sQuery += " WHERE SD1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " AND SD1.D1_FILIAL BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
			_oSQL:_sQuery += " AND SD1.D1_EMISSAO BETWEEN '" + dtos(mv_par03) + "' and '" + dtos(mv_par04) + "'"
			_oSQL:_sQuery += " AND SD1.D1_TIPO = 'D' "
			_oSQL:_sQuery += " AND SD1.D1_CF <> '5151' "
			_oSQL:_sQuery += " ORDER BY SD1.D1_FILIAL, SD1.D1_EMISSAO, SD1.D1_DOC, SD1.D1_COD "
			_oSQL:Log ()
		
			_aDados := aclone (_oSQL:Qry2Array ())

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
			
			U_F3Array (_aDados, "Analise Credito Presumido - Entradas", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -40 , "", "", .T., 'C' )

		endif
	endif	
return	
//
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
	aadd (_aRegsPerg, {08, "Tipo de NF                    ", "N", 1,  0,  "",   "   ", {'Entradas', 'Saídas'},    ""})
	U_ValPerg (cPerg, _aRegsPerg)
return
