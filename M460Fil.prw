// Programa:   M460Fil
// Autor:      Robert Koch
// Data:       25/10/2010
// Descricao:  P.E. para filtragem dos pedidos na tela de preparacao de NF de saida (MATA460).
//
//             Obs.: este P.E. deve obrigatoriamente manter a consistencia de retorno com o M460QRY
//
// Historico de alteracoes:
// 05/11/2010 - Robert - Criado campo C9_VABLOQ.
//

// -------------------------------------------------------------------------- 
user function M460Fil ()
	local _sRet := ""
	if IsInCallStack ("MATA460A")  // Faturamento padrao (nao via carga)
		_sRet = "C9_VABLOQ='N' .and. empty(C9_CARGA)"
	else  // Faturamento via carga
		_sRet = "C9_VABLOQ='N' .and. !empty(C9_CARGA)"
	endif
return _sRet
