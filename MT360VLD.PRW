#include "protheus.ch"

// Programa:  MT360VLD
// Autor:     Andr� Alves
// Data:      30/08/2018
// Descricao: Ponto de entrada utilizado para validar se o c�digo da condi��o n�o cont�m LETRA.

// Historico de alteracoes:
// 23/03/2019 - Robert - Desabilitado teste quando se usa cond.pagto. tipo B (campo vem com NIL).
// 22/03/2021 - Robert - Eliminada redefinicao da variavel _sCampo.
//

// --------------------------------------------------------------------------
// user function MT360VLD(_sCampo)
user function MT360VLD()
	local _sCampo    := alltrim (ReadVar ())
	local _lRet 	 := .T.
	
	if valtype (M->E4_CODIGO) == 'C'  // Quando se usa cond.pagto. tipo B este campo vem com NIL.
		do case
			case _sCampo $ "M->E4_CODIGO"
				_wcond = ALLTRIM(M->E4_CODIGO)
				if len (_wcond) !=  3
					U_Help ("Obrigatoriamente usar codigo com 3 digitos")
					_lRet = .F.
				endif

				case substring(M->E4_CODIGO,1,1) $ "A/B/C/D/E/F/G/H/I/J/K/L/M/N/O/P/Q/R/S/T/U/V/X/W/Y/Z/"
					U_Help ("N�o � permitido cadastrar condi��es de pagamento contendo LETRAS.")
					_lRet = .F.
				case substring(M->E4_CODIGO,2,1) $ "A/B/C/D/E/F/G/H/I/J/K/L/M/N/O/P/Q/R/S/T/U/V/X/W/Y/Z/"
					U_Help ("N�o � permitido cadastrar condi��es de pagamento contendo LETRAS.")
					_lRet = .F.
				case substring(M->E4_CODIGO,3,1) $ "A/B/C/D/E/F/G/H/I/J/K/L/M/N/O/P/Q/R/S/T/U/V/X/W/Y/Z/"
					U_Help ("N�o � permitido cadastrar condi��es de pagamento contendo LETRAS.")
					_lRet = .F.
		endcase
	endif
Return _lRet
