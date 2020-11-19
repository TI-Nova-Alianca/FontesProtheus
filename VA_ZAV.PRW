// Programa...: VA_ZAV
// Autor......: Catia Cardoso
// Data.......: 31/10/2016
// Descricao..: Comissao - Vendedor X Linha Formação Preço / Item
//
// ------------------------------------------------------------------------------------
//
// Historico de alteracoes:
// 27/02/2016 - Robert - Valida se o usuario tem acesso a alterar cadastros de vendedores / comissoes.
//

//#include "rwmake.ch"
User Function VA_ZAV()
//	AxCadastro("ZAV","Comissão Vendedor x Linha/Item",".T.","U_VALIDAZAV()")
	AxCadastro("ZAV","Comissão Vendedor x Linha/Item","U_ZZUVL ('046', __CUSERID, .T.)","U_ZZUVL ('046', __CUSERID, .T.) .and. U_VALIDAZAV()")
Return

// --------------------------------------------------------------------------
// Valida 'Tudo OK'
user function VALIDAZAV()
	local _lRet := .T.
	local _aAreaAnt := U_ML_SRArea ()
	
	// testa vendedor ativo
	if _lRet .and. fBuscaCpo ("SA3", 1, xfilial ("SA3") + m->ZAV_VEND, "A3_ATIVO") != "S"
		u_help ("Vendedor Inativo")
		_lRet = .F.
	endif
	// testa digitacao da linha ou do item
	if _lRet .and. EMPTY(m->ZAV_LINHA).and. EMPTY(m->ZAV_ITEM)
		u_help ("Informar a LINHA ou ITEM. Verifique! ")
		_lRet = .F.
	endif 
	// testa digitacao da linha ou do item
	if _lRet .and. ! EMPTY(m->ZAV_LINHA).and. ! EMPTY(m->ZAV_ITEM)
		u_help ("Informar a LINHA ou ITEM. Verifique! ")
		_lRet = .F.
	endif 
	// testa duplicidade
	if _lRet .and. inclui
		ZAV -> (dbsetorder (3))
		if ZAV -> (dbseek (xfilial ("ZAV") + m->ZAV_VEND + m->ZAV_LINHA + m->ZAV_ITEM, .F.))
			u_help ("Ja' existe registro desse vendedor para essa linha e/ou item. Verifique! ")
			_lRet = .F.
		endif
	endif
	U_ML_SRArea (_aAreaAnt)
return _lRet
