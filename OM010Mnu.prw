// Programa...: OM010Mnu
// Autor......: Robert Koch
// Data.......: 11/11/2015
// Descricao..: P.E. apos definicao de manu da tela de listas de precos (OMSA010)
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. apos definicao de manu da tela de listas de precos (OMSA010)
// #PalavasChave      #vendas #tabela_de_preco
// #TabelasPrincipais #DA0
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function OM010Mnu ()
	aadd (aRotina, {"Obs.internas"			, "U_MemoDA0 (da0 -> (recno ()), 'A', 'DA0_VACME2', 'DA0_VAOBS')"	,0,4,32,NIL})
	aadd (aRotina, {"Obs.impressas" 		, "U_MemoDA0 (da0 -> (recno ()), 'A', 'DA0_VACMEM', 'DA0_VAINST')"	,0,4,32,NIL})
	aadd (aRotina, {"Envia Mercanet"		, "U_AtuMerc ('DA0', da0 -> (recno ()))"							,0,4,32,NIL})
	aadd (aRotina, {"Atualiza Tabela" 		, "U_VA_ATPRC()"													,0,4,32,NIL})
	aadd (aRotina, {"Lista pre�o Alianca"	, "U_VA_LPR()"														,0,4,32,NIL})
	aadd (aRotina, {"T. Prc. Canal X UF"	, "U_VA_PRDXCLI()"													,0,4,32,NIL})
	aadd (aRotina, {"Exporta tabela"		, "U_VA_DA0EXP (da0 -> da0_filial, da0 -> da0_codtab)"				,0,4,32,NIL})
	aadd (aRotina, {"Importa tabela"		, "U_VA_DA0IMP ()"													,0,4,32,NIL})
	aadd (aRotina, {"Exclui produto"		, "U_VA_DA0PRO ()"													,0,4,32,NIL})
	aadd (aRotina, {"Log altera��o" 		, "U_VA_DA0LOG (da0 -> da0_filial, da0 -> da0_codtab)"				,0,4,32,NIL})
	aadd (aRotina, {"Imprime Tabelas" 		, "U_VA_DA0TAB()"													,0,4,32,NIL})
	aadd (aRotina, {"Atu.Discrep�ncia" 		, "U_VA_PERMAX()"													,0,4,32,NIL})
	
return


