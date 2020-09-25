// Programa...: VA_SZK
// Autor......: Robert Koch
// Data.......: 09/02/2011
// Descricao..: Tela de manutencao de cadastro de regioes virtuais.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function VA_SZK ()

	// Se passar tempo sem uso, vou descompilar. Robert, 03/08/2015
	U_AvisaTI ('Tentativa de uso do programa ' + procname () + ' por ' + cUserName)
	u_help ('Programa em revisao.')
	return


	private aRotina := {}
	aadd (aRotina, {"&Pesquisar" , "AxPesqui", 0, 1})
	aadd (aRotina, {"&Visualizar", "AxVisual", 0, 2})
	aadd (aRotina, {"&Incluir"   , "AxInclui", 0, 3})
	aadd (aRotina, {"&Alterar"   , "AxAltera", 0, 4})
	aadd (aRotina, {"&Excluir"   , "U_VA_SZKE ()", 0, 5})
	private cString   := "SZK"
	private cCadastro := "Regioes virtuais"
	dbselectarea ("SZK")
	dbSetOrder (1)
	mBrowse(,,,,"SZK",,,,,2)
return



// --------------------------------------------------------------------------
// Exclusao
user function VA_SZKE ()
	local _sQuery := ""

	CursorWait ()
	_sQuery := ""
	_sQuery += "SELECT COUNT (*)"
	_sQuery +=  " FROM " + RetSQLName ('SA1')
	_sQuery += " WHERE D_E_L_E_T_ = ''"
	_sQuery +=   " AND A1_FILIAL  = '" + xfilial ('SA1') + "'"
	_sQuery +=   " AND A1_VIRTUAL = '" + szk -> zk_codigo + "'"
	CursorArrow ()
	if U_RetSQL (_sQuery) > 0
		u_help ("Existe(m) cliente(s) amarrado(s) a esta regiao, impedindo sua exclusao.")
	else
		AxDeleta ("SZK", szk -> (recno ()), 5)
	endif
return
