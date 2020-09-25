// Programa:   FA050Upd
// Autor:      Robert Koch
// Data:       07/06/2016
// Descricao:  P.E. que valida incl/alt/excl de registros no contas a pagar (SE2).
//             Criado inicialmente para impedir manutencao de titulos gerados pelo Metadados.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function FA050Upd ()
	local _lRet := .T.

	if altera .and. se2 -> e2_origem == 'U_METAFI'
		u_help ("Titulo gerado pelo sistema Metadados. Manutencao manual nao permitida.")
		_lRet = .F.
	endif
return _lRet
