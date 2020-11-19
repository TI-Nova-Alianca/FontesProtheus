// Programa...: SZYVen
// Autor......: Robert Koch
// Data.......: 15/04/2008
// Cliente....: Alianca
// Descricao..: Monta lista dos vendedores ligados `a tabela de precos informada.
//              Opcionalmente, mostra-os na tela.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function SZYVen (_sTabela, _lComTela)
	local _aAreaAnt := U_ML_SRArea ()
	local _aVend := {}
	local _aCampos := {}

	sa3 -> (dbsetorder (1))  // A3_FILIAL+A3_COD
	szy -> (dbsetorder (2))  // ZY_FILIAL+ZY_FILTAB+ZY_CODTAB+ZY_VEND
	szy -> (dbseek (xfilial ("SZY") + xfilial ("DA0") + _sTabela, .T.))
	do while ! szy -> (eof ()) .and. szy -> zy_filial == xfilial ("SZY") .and. szy -> zy_filtab == xfilial ("DA0") .and. szy -> zy_codtab == _sTabela
		aadd (_aVend, {szy -> zy_vend, "", ""})
		if sa3 -> (dbseek (xfilial ("SA3") + szy -> zy_vend, .F.))
			_aVend [len (_aVend), 2] = sa3 -> a3_nome
			_aVend [len (_aVend), 3] = iif (sa3 -> a3_ativo != "S", "Inativo", "Ativo")
		endif
		szy -> (dbskip ())
	enddo

	if _lComTela
		if len (_aVend) == 0
			u_help ("Tabela nao encontra-se ligada a nenhum vendedor.")
		else
			_aCampos = {}
			aadd (_aCampos, {1, "Vendedor", 50,  "@!"})
			aadd (_aCampos, {2, "Nome",     150, "@!"})
			aadd (_aCampos, {3, "Situacao", 50,  "@!"})
			U_F3Array (_aVend, "Vendedores ligados a esta tabela de precos", _aCampos)
		endif
	endif
	U_ML_SRArea (_aAreaAnt)
return _aVend
