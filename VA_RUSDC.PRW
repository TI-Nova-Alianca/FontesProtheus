// Programa...: VA_RUSDC
// Autor......: Robert Koch
// Data.......: 24/03/2016
// Descricao..: Informa que a carga foi devolvida (geralmente para casos em que foi informado grau errado, etc.)
//
// Historico de alteracoes:
// 29/03/2017 - Robert - Valida a NF informada.
//

// --------------------------------------------------------------------------
User Function va_rusDC ()
	local _lContinua := .T.
	local _sNFDevol  := ""
	local _oSQL      := NIL

	// A partir de 2023 estou comecando a migrar as cargas de safra para orientacao a objeto.
	if type ("_oCarSaf") != 'O'
		private _oCarSaf  := ClsCarSaf ():New (sze -> (recno ()))
	endif
	if empty (_oCarSaf:Carga)
		u_help ("Impossivel instanciar carga (ou carga invalida recebida).",, .t.)
		_lContinua = .F.
	endif

	if _lContinua .and. empty (sze -> ze_nfger)
		u_help ("Nao ha contranota gerada para esta carga.")
		_lContinua = .F.
	endif  
	if _lContinua
		do while .T.
			_sNFDevol = U_Get ('Informe numero da NF gerada para a devolucao', 'C', TamSX3 ("D2_DOC")[1], '', '', sze -> ze_nfdevol, .F., '.t.')
			if _sNFDevol != NIL
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "SELECT COUNT (*) FROM VA_VNOTAS_SAFRA_DEVOLVIDAS"
				_oSQL:_sQuery += " WHERE FILIAL       = '" + xfilial ("SZE") + "'"
				_oSQL:_sQuery +=   " AND SAFRA        = '" + sze -> ze_safra + "'"
				_oSQL:_sQuery +=   " AND FORNECEDOR   = '" + sze -> ze_assoc + "'"
				_oSQL:_sQuery +=   " AND LOJA         = '" + sze -> ze_lojasso + "'"
				_oSQL:_sQuery +=   " AND DOC          = '" + sze -> ze_nfger + "'"
				_oSQL:_sQuery +=   " AND SERIE        = '" + sze -> ze_serie + "'"
				_oSQL:_sQuery +=   " AND NF_DEVOLUCAO = '" + _sNFDevol + "'"
				_oSQL:Log ()
				if _oSQL:RetQry () == 0
					u_help ("Nota '" + _sNFDevol + "' nao consta como nota de devolucao de safra referindo a contranota '" + sze -> ze_nfger + "'.")
					loop
				endif
				reclock ("SZE", .F.)
				sze -> ze_nfdevol = _sNFDevol
				msunlock ()
				exit
			else
				exit
			endif
		enddo
	endif 
return
