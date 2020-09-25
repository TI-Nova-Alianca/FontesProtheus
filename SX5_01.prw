// Programa...: SX5_01
// Autor......: Robert Koch - TCX021
// Data.......: 19/10/2010
// Cliente....: Alianca
// Descricao..: Edicao de registros do SX5 com chave especifica
//
// Historico de alteracoes:
// 29/11/2014 - Robert - Passa a validar usuario pela tabela ZZU.
//

// --------------------------------------------------------------------------
User Function SX5_01 ()
	if U_ZZUVL ('027')
		U_EditSX5 ("01", "allwaystrue()", "allwaystrue()", 99, .T.)
	endif
return
