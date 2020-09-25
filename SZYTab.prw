// Programa...: SZYTab
// Autor......: Robert Koch
// Data.......: 15/04/2008
// Cliente....: Alianca
// Descricao..: Gera string com os codigos das tabelas amarradas ao vendedor informado.
//              Usado inicialmente para filtros em consultas padrao.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function SZYTab (_sVend)
	local _sRet := ""
	local _aAreaAnt := U_ML_SRArea ()
	szy -> (dbsetorder (1))  // ZY_FILIAL+ZY_VEND+ZY_FILTAB+ZY_CODTAB
	szy -> (dbseek (xfilial ("SZY") + _sVend, .T.))
	do while ! szy -> (eof ()) .and. szy -> zy_filial == xfilial ("SZY") .and. szy -> zy_vend == _sVend
		_sRet += szy -> zy_codtab + "/"
		szy -> (dbskip ())
	enddo
	U_ML_SRArea (_aAreaAnt)
return _sRet
