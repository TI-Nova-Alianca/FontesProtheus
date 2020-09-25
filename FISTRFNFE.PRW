// Programa:   FISTRFNFE
// Autor:      Catia Cardoso
// Data:       25/02/20196
// Descricao:  P.E. no SPEDNFE para criar botoes - o browse do SPEDNFE esta posicionado no SF2
// 
// Historico de alteracoes:
// --------------------------------------------------------

#include 'protheus.ch'
User Function FISTRFNFE ()

	aadd(aRotina,{"Exportacao - COMPL" , "U_VA_DadosExport()"          ,0,2,0 ,NIL})

Return

User Function VA_DadosExport() 
	// CHAMA A ROTINA DE COMPLEMENTO DO MATA920 - PARA DIGITAR OS DADOS DA EXPORTACAO”
	if ! u_zzuvl ('088', __cUserId, .T.)
		return .F.
	endif
	Mata926(SF2->F2_DOC,SF2->F2_SERIE,SF2->F2_ESPECIE,SF2->F2_CLIENTE,SF2->F2_LOJA,"S",SF2->F2_TIPO)

Return .T. 
