// Programa:   BatMetaF
// Autor:      Robert Koch
// Data:       03/06/2016
// Descricao:  Verifica necessidade de integracoes Metadados X financeiro e gera batches para isso.
//             Nao faz a integracao imediatamente por que uma unica sequencia do Metadados pode
//             gerar titulos em mais de uma filial.
//
// Historico de alteracoes:
// 10/06/2019 - Robert - Melhorias geracao arquivo de log.
//

// --------------------------------------------------------------------------
user function BatMetaF ()
	//local _oSQL     := NIL
	local _lRet     := .T.
	//local _oBatch2  := NIL

	U_Log2 ('info', "Iniciando execucao")

	U_MetaFin (.T.)
	_oBatch:Retorno = 'S'

	U_Log2 ('info', "Finalizando execucao")
	U_Log2 ('info', "")
return _lRet
