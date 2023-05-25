// Programa...: MATUCOMP
// Autor......: Cláudia Lionço
// Data.......: 17/03/2020
// Descricao..: P.E. utilizado para alterações automáticas nos complementos dos documentos fiscais 
//              após a emissão das Notas Fiscais.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #Alteracoes / ajustes complementos de documentos de entrada/saida
// #PalavasChave      #complementos #NF
// #TabelasPrincipais #SF1, SF2, CD5, CDL, CDE, CF8, CDB
// #Modulos           #FAT #COM #EST

// Historico de alteracoes:
// 24/05/2023 - Robert - Salvar e restaurar area de trabalho na entrada e saida do programa
//                     - Adicionadas tags para documentacao de fontes
//                     - Selecionar indices do SF1 e SF2 antes da pesquisa
//                     - Deixa de verificar tabela VA_SM0 e passa a verificar SYS_COMPANY.
//

#include 'protheus.ch'
#include 'parmtype.ch'

// -----------------------------------------------------------------------------------------------------------
User Function MATUCOMP()
	Local cEntSai  := ParamIXB[1]
	Local cSerie   := ParamIXB[2]
	Local cDoc     := ParamIXB[3]
	Local cCliefor := ParamIXB[4]
	Local cLoja    := ParamIXB[5]	
	Local cQuery   := ""
	local _aAreaAnt := U_ML_SRArea ()
	//Local x		   := 0
	
	// Entradas
//	If (IsInCallStack ("MATA910") .or. IsInCallStack ("MATA103")) .and. cEntSai = 'E' // Entradas ou aquisições de serviços do exterior
	If cEntSai = 'E' .or. (IsInCallStack ("MATA910") .or. IsInCallStack ("MATA103")) // Entradas ou aquisições de serviços do exterior
		
//		SF1->(dbSeek(xFilial("SF1") + cDoc + cSerie + cCliefor + cLoja))
//		If ALLTRIM(SF1 -> F1_EST) == 'EX' 		

		sf1 -> (dbsetorder (1))  // F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO, R_E_C_N_O_, D_E_L_E_T_
		if SF1->(dbSeek(xFilial("SF1") + cDoc + cSerie + cCliefor + cLoja), .f.) .and. ALLTRIM(SF1 -> F1_EST) == 'EX'
			cQuery := " SELECT"
			cQuery += " 	D1_FILIAL"
			cQuery += "    ,D1_SERIE"
			cQuery += "    ,D1_ITEM"
			cQuery += "    ,D1_FORNECE"
			cQuery += "    ,D1_LOJA"
			cQuery += "    ,D1_BASIMP6"
			cQuery += "    ,D1_ALQIMP6"
			cQuery += "    ,D1_VALIMP6"
			cQuery += "    ,D1_BASIMP5"
			cQuery += "    ,D1_ALQIMP5"
			cQuery += "    ,D1_VALIMP5"
			cQuery += "    ,D1_FORNECE"
			cQuery += "    ,D1_DESPESA"
			cQuery += "    ,M0_CGC"
			cQuery += "    ,M0_ESTCOB"
			cQuery += " FROM " + RetSqlName("SD1") + " SD1"
//			cQuery += " LEFT JOIN VA_SM0 SM0"
			cQuery += " LEFT JOIN SYS_COMPANY SM0"
			cQuery += " 	ON (SM0.D_E_L_E_T_ = ''"
			cQuery += " 			AND SM0.M0_CODIGO = '" + cEmpAnt + "'"
			cQuery += " 			AND SM0.M0_CODFIL = '" + SF1 -> F1_FILIAL + "')"
			cQuery += " WHERE SD1.D_E_L_E_T_ = ''"
			cQuery += " AND SD1.D1_DOC =     '" + SF1 -> F1_DOC     + "'"
			cQuery += " AND SD1.D1_SERIE =   '" + SF1 -> F1_SERIE   + "'"
			cQuery += " AND SD1.D1_FORNECE = '" + SF1 -> F1_FORNECE + "'"
			cQuery += " AND SD1.D1_LOJA =    '" + SF1 -> F1_LOJA    + "'"
				
			dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
			TRA->(DbGotop())

			While TRA->(!Eof())	
				RecLock("CD5",.T.)	
				
				CD5 -> CD5_FILIAL 	:= SF1 -> F1_FILIAL
				CD5 -> CD5_DOC 		:= SF1 -> F1_DOC
				CD5 -> CD5_SERIE	:= SF1 -> F1_SERIE
				CD5 -> CD5_ESPEC	:= SF1 -> F1_ESPECIE
				CD5 -> CD5_ITEM		:= TRA -> D1_ITEM
				CD5 -> CD5_FORNEC	:= SF1 -> F1_FORNECE
				CD5 -> CD5_LOJA		:= SF1 -> F1_LOJA
				CD5 -> CD5_DOCIMP	:= SF1 -> F1_DOC
				CD5 -> CD5_FILIAL 	:= TRA -> D1_FILIAL
				CD5 -> CD5_DOC 		:= SF1 -> F1_DOC
				CD5 -> CD5_SERIE	:= TRA -> D1_SERIE
				CD5 -> CD5_ESPEC	:= SF1 -> F1_ESPECIE
				CD5 -> CD5_ITEM		:= TRA -> D1_ITEM
				CD5 -> CD5_FORNEC	:= TRA -> D1_FORNECE
				CD5 -> CD5_LOJA		:= TRA -> D1_LOJA
				CD5 -> CD5_DOCIMP	:= SF1 -> F1_DOC
				CD5 -> CD5_BSPIS	:= TRA -> D1_BASIMP6
				CD5 -> CD5_ALPIS	:= TRA -> D1_ALQIMP6
				CD5 -> CD5_VLPIS	:= TRA -> D1_VALIMP6
				CD5 -> CD5_BSCOF	:= TRA -> D1_BASIMP5
				CD5 -> CD5_ALCOF	:= TRA -> D1_ALQIMP5
				CD5 -> CD5_VLCOF	:= TRA -> D1_VALIMP5
				CD5 -> CD5_DTDI		:= SF1 -> F1_EMISSAO
				CD5 -> CD5_CODFAB	:= TRA -> D1_FORNECE
				CD5 -> CD5_LOJFAB   := TRA -> D1_LOJA
				CD5 -> CD5_DSPAD	:= TRA -> D1_DESPESA
				CD5 -> CD5_CNPJAE	:= TRA -> M0_CGC
				CD5 -> CD5_UFTERC	:= TRA -> M0_ESTCOB	
				MsUnLock()
				
				DBSelectArea("TRA")
				dbskip()
			Enddo
			TRA->(DbCloseArea())
		EndIf
	EndIf
	
	// Saídas
	If cEntSai = 'S' // Saídas ou serviços para o exterior

//		SF2->(dbSeek(xFilial("SF2") + cDoc + cSerie + cCliefor + cLoja))
//		If ALLTRIM(SF2 -> F2_EST) == 'EX' 

		sf2 -> (dbsetorder (1))  // F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_FORMUL, F2_TIPO, R_E_C_N_O_, D_E_L_E_T_
		if SF2->(dbSeek(xFilial("SF2") + cDoc + cSerie + cCliefor + cLoja), .f.) .and. ALLTRIM(SF2 -> F2_EST) == 'EX'
			cQuery := " SELECT"
			cQuery += "		D2_ITEM"
			cQuery += "	   ,D2_COD"
			cQuery += "	   ,M0_CIDENT"
			cQuery += "	   ,M0_CGC"
			cQuery += "	   ,M0_ESTCOB"
			cQuery += "	FROM " + RetSqlName("SD2") + " SD2"
	//		cQuery += "	LEFT JOIN VA_SM0 SM0"
			cQuery += "	LEFT JOIN SYS_COMPANY SM0"
			cQuery += "		ON (SM0.D_E_L_E_T_ = ''"
			cQuery += "				AND SM0.M0_CODIGO = '" + cEmpAnt + "'"
			cQuery += "				AND SM0.M0_CODFIL = '" + SF1 -> F1_FILIAL + "')"
			cQuery += "	WHERE SD2.D_E_L_E_T_ = ''"
			cQuery += "	AND SD2.D2_DOC 		= '" + SF2 -> F2_DOC 	 + "'"
			cQuery += "	AND SD2.D2_SERIE 	= '" + SF2 -> F2_SERIE 	 + "'"
			cQuery += "	AND SD2.D2_CLIENTE 	= '" + SF2 -> F2_CLIENTE + "'"
			cQuery += "	AND SD2.D2_LOJA 	= '" + SF2 -> F2_LOJA	 + "'"

			dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
			TRA->(DbGotop())

			While TRA->(!Eof())
				RecLock("CDL",.T.)
				CDL -> CDL_FILIAL	:= SF2 -> F2_FILIAL
				CDL -> CDL_DOC 		:= SF2 -> F2_DOC
				CDL -> CDL_SERIE 	:= SF2 -> F2_SERIE
				CDL -> CDL_ESPEC 	:= SF2 -> F2_ESPECIE
				CDL -> CDL_CLIENT 	:= SF2 -> F2_CLIENTE
				CDL -> CDL_LOJA 	:= SF2 -> F2_LOJA
				CDL -> CDL_NUMDE 	:= SF2 -> F2_DOC
				CDL -> CDL_DTDE 	:= SF2 -> F2_EMISSAO
				CDL -> CDL_DTREG 	:= SF2 -> F2_EMISSAO
				CDL -> CDL_DTCHC 	:= SF2 -> F2_EMISSAO
				CDL -> CDL_DTAVB 	:= SF2 -> F2_EMISSAO
				CDL -> CDL_PAIS  	:= '105' // BRASIL
				CDL -> CDL_LOCEMB 	:= TRA -> M0_CIDENT
				CDL -> CDL_UFEMB	:= TRA -> M0_ESTCOB
				CDL -> CDL_LOCDES 	:= TRA -> M0_CIDENT
				CDL -> CDL_DOCORI 	:= SF2 -> F2_DOC
				CDL -> CDL_SERORI 	:= SF2 -> F2_SERIE
				CDL -> CDL_ITEMNF 	:= TRA -> D2_ITEM
				CDL -> CDL_PRODNF   := TRA -> D2_COD
				MsUnLock()
				DBSelectArea("TRA")
				dbskip()
			Enddo
			TRA->(DbCloseArea())
		EndIf
	EndIf

	U_ML_SRArea (_aAreaAnt)
Return
