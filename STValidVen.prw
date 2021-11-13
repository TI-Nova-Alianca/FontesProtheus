// Programa:  STValidVen
// Autor:     Robert Koch
// Data:      12/11/2021
// Descricao: P.E. no TotvsPDV para validar o codigo do vendedor.
//            Criado inicialmente para popular variavel '_lTumelero' a ser vista por outros P.E.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #Valida vendador no PDV e cria variavel para identificar Tumelero.
// #PalavasChave      #PDV #Tumelero #validacao #vendedor
// #TabelasPrincipais #SA3
// #Modulos           #PDV

// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function STValidVen ()
	local _aRetVldVd := {.t., ''}
	public _lTumelero := (alltrim (PARAMIXB [1]) == '135')  // Deixar PUBLIC para ser vista por outros P.E.
	if _lTumelero
		msgalert ("Assumindo venda para parceiro comercial (tabela de precos ' Tumelero ')", 'aviso')
	endif
Return _aRetVldVd
