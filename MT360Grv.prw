// Programa:  MT360Grv
// Autor:     Robert Koch
// Data:      10/11/2016
// Descricao: P.E. apos a confirmacao da inclusao e alteracao de cadastro de cond.pagto.
//            Criado inicialmente para enviar atualizacao para sistema Mercanet.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #Ponto de entrada apos a confirmacao da inclusao e alteracao de cadastro de cond.pagto. Inicialmente atualiza dados para sistema Mercanet.
// #PalavasChave      #atualiza #mercanet
// #TabelasPrincipais #SE4
// #Modulos           #FAT

// Historico de alteracoes:
// 14/09/2020 - Robert - Criado tratamento para campo E4_VAEXMER.
//                     - Criados tags para catalogo de fontes.
//

// --------------------------------------------------------------------------
user function MT360Grv ()
// deve enviar independente do conteudo --->	if se4 -> e4_vaexmer == 'S'
	U_AtuMerc ('SE4', se4 -> (recno ()))
//	endif
return
