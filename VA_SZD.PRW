// Programa...: VA_SZD
// Autor......: Robert Koch
// Data.......: 18/01/2010
// Descricao..: Tela de manutencao de cadastro de associados de outras cooperativas.
//
// Historico de alteracoes:
// 26/01/2016 - Robert - Rotina restrita ao grupo 045 do ZZU.
//

// --------------------------------------------------------------------------
User Function va_szd()

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T., cEmpAnt, cFilAnt)
		return
	endif

	axcadastro ("SZD", "u_vaszda()", ".T.")
	
return

User Function va_szda ()

local _lRet := .T.

		If posicione ('SA2', 1, xFilial ('SA2') + M->ZD_FORNECE + M->ZD_LOJA, 'A2_TIPO') != 'F'
			MsgAlert ('Associado deve ser pessoa fisica')
			_lRet = .F.
		endif
	
		if u_EhAssoc (M->ZD_FORNECE, M->ZD_LOJA, dDatabase)
			MsgAlert ('Este Fornecedor é nosso associado')
			_lRet = .F.
		endif
		
		
Return _lRet