// Programa.: FA080PE
// Autor....: Andre Alves
// Data.....: 16/08/2019
// Descricao: P.E.Executado na saida da funcao de baixa, após a contabilização.
// 
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E.Executado na saida da funcao de baixa, após a contabilização
// #PalavasChave      #baixa #contas_a_pagar
// #TabelasPrincipais #SE5
// #Modulos           #FIN
//
// Historico de alteracoes:
// 16/09/2019 - Andre  - Gravacao do campo E5_VAUSER.
//
// --------------------------------------------------------------------------

#include "rwmake.ch"
User Function FA080PE()

	if empty(se5 -> e5_vaUser)
		RECLOCK("SE5",.F.)
			SE5->E5_VAUSER := alltrim(cUserName)
		MsUnlock()
	endif
	
Return()

