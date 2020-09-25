// Programa:  ExistZX5
// Autor:     Robert Koch
// Data:      10/03/2011
// Descricao: Verifica a existencia de tabela/chave no arquivo ZX5.
//
// Historico de alteracoes:
// 19/01/2012 - Robert - Se nao tiver indice especifico, verifica via query.
// 21/03/2012 - Robert - Criado tratamento para tabelas 12 e 23 a 34.
// 19/05/2016 - Robert - Procura sempre pelo campo <Tabela> + 'COD' por default.
// 19/06/2017 - Robert - Passa a usar metodo ExistChav() da classe ClsTabGen.
//

// --------------------------------------------------------------------------
User Function ExistZX5 (_sTabela, _sChave)
	local _lRet     := .T.
	local _oTabGen  := ClsTabGen ():New (_sTabela)
	
	if ! _oTabGen:ExistChav (_sChave)
		u_help (_oTabGen:UltMsg)
		_lRet = .F.
	endif
return _lRet
