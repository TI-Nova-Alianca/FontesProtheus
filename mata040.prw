// Programa: MATA040
// Autor:    Robert Koch
// Data:     02/09/06
// Funcao:   P.E. generico no cadastro de vendedores.
//           Criado inicialmente para gravar log de evento em caso de alteracao de cadastro.
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
User Function MATA040()
	local _oEvento  := NIL
	if altera
		_oEvento := ClsEvent():new ()
		_oEvento:AltCadast ("SA3", m->a3_cod, sa3 -> (recno ()))
	endif
Return
