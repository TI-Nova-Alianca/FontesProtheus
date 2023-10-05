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
	aadd (aRotina, {"Obs.internas"	, "U_MemoDA0 (da0 -> (recno ()), 'A', 'DA0_VACME2', 'DA0_VAOBS')"	,0,4,32,NIL})
	aadd (aRotina, {"Obs.impressas" , "U_MemoDA0 (da0 -> (recno ()), 'A', 'DA0_VACMEM', 'DA0_VAINST')"	,0,4,32,NIL})
	//aadd (aRotina, {"Exporta tabela", "U_VA_DA0EXP (da0 -> da0_filial, da0 -> da0_codtab)"				,0,4,32,NIL})
	//aadd (aRotina, {"Importa tabela", "U_VA_DA0IMP ()"													,0,4,32,NIL})
	aadd (aRotina, {"Log alteração" , "U_VA_DA0LOG (da0 -> da0_filial, da0 -> da0_codtab)"				,0,4,32,NIL})
	aadd (aRotina, {"Envia Mercanet", "U_AtuMerc ('DA0', da0 -> (recno ()))"							,0,4,32,NIL})
return
