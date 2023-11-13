// Programa...: VA_G1CPC
// Autor......: Robert Koch
// Data.......: 13/11/2023
// Descricao..: Tela para manutencao do campo G1_VACPCUS

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Cadastro
// #Descricao         #Tela para manutencao do campo G1_VACPCUS (especifico para custos, independente de engenharia)
// #PalavasChave      #cadastro #estruturas #considera_para_custo_reposicao
// #TabelasPrincipais #SG1
// #Modulos           #EST #PCP

// Historico de alteracoes:
//

// --------------------------------------------------------------------------------------------------
User Function VA_G1CPC ()
	Private cCadastro := "Estrutura para custos"
	Private cDelFunc  := ".F."
	Private cString   := "SG1"
	private aRotina   := {}
	
	aadd (aRotina, {"Pesquisar",   "AxPesqui"        , 0, 1})
	aadd (aRotina, {"Visualizar",  "AxVisual"        , 0, 2})
	aadd (aRotina, {"Visualizar",  "AxVisual"        , 0, 3})
	aadd (aRotina, {"Habilitar p/custo",   "U_VA_G1CP2 ('S')", 0, 4})
	aadd (aRotina, {"Desabilitar p/custo", "U_VA_G1CP2 ('N')", 0, 4})

	dbSelectArea("SG1")
	dbSetOrder(1)

	mBrowse(6,1,22,75,"SG1")
Return


// --------------------------------------------------------------------------
User Function VA_G1CP2 (_sOpcao)
	reclock ("SG1", .F.)
	sg1 -> G1_VACPCUS = _sOpcao
	msunlock ()
Return
