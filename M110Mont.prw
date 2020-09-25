// Programa: M110Mont
// Autor:    Robert Koch
// Data:     30/12/2008
// Funcao:   PE apos montagem do aCols na tela de manutencao de solicitacoes de compra.
//           Criado inicialmente para tratamento de campo memo.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function m110Mont ()
	local _nLinha := 0

	// Se estah sendo feita uma copia de solicitacao jah existente, limpa campo com
	// codigo do memo, para que seja criado novo codigo apos gravar a solicitacao.
	if ParamIXB [3] == .T.
		for _nLinha = 1 to len (aCols)
			GDFieldPut ("C1_VACODM1", "", _nLinha)
		next
	endif

return
