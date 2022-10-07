// Programa:  Mta390Mnu
// Autor:     Robert Koch
// Data:      05/10/2022
// Descricao: P.E. para adicionar botoes na tela MATA390 (manut.lotes estoque)
//            Criado inicialmente para gerar etiquetas para lotes (GLPI 12651)

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. para adicionar botoes na tela MATA390 (manut.lotes estoque)
// #PalavasChave      #ponto_de_entrada #lotes #etiquetas #GLPI 12651
// #TabelasPrincipais #SD5
// #Modulos           #EST

// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function Mta390Mnu ()
	local _aRotAdic := {}
	
	// Cria submenu de rotinas especificas.
	aadd (_aRotAdic, {"Gerar etiqueta"   , "U_ZA1SD5 ('G')", 0, 7, 0, nil})
	aadd (_aRotAdic, {"Imprimir etiqueta", "U_ZA1SD5 ('I')", 0, 7, 0, nil})

	aadd (aRotina, {"Especificos" ,_aRotAdic, 0 , 7,0,nil})
return
