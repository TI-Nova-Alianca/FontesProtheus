// Programa...: DispComp
// Autor......: Robert Koch
// Data.......: 02/04/2015
// Descricao..: Consulta disponibilidade de estoque dos itens empenhados nas OPs.
//
// Historico de alteracoes:
//

// ------------------------------------------------------------------------------------
user function DispComp (_sOP, _lDescob)
	local _oSQL     := NIL
	local _aAvisos  := {}
	local _aCols    := {}
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	u_logIni ()

	_sOP     := iif (_sOP == NIL, '', _sOP)
	_lDescob := iif (_lDescob == NIL, .F., _lDescob)

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT COMPONENTE, DESCRI_COMPON, ALMOX, NECESSIDADE_ACUMULADA, DISPONIVEL, OP, RTRIM (PROD_FINAL) + ' - ' + DESCRI_PRODUTO"
	_oSQL:_sQuery +=  " FROM VA_VDISPONIBILIDADE_EMPENHOS_OP V"
	_oSQL:_sQuery += " WHERE FILIAL = '" + cFilAnt + "'"
	if ! empty (_sOP)
		_oSQL:_sQuery +=   " AND OP = '" + _sOP + "'"
	endif
	if _lDescob
		_oSQL:_sQuery +=   " AND NECESSIDADE_ACUMULADA > DISPONIVEL"
	endif
	_oSQL:_sQuery += " ORDER BY ROWNUMBER"
	U_LOG (_oSQL:_sQuery)
	_aAvisos := aclone (_oSQL:Qry2Array ())
	if len (_aAvisos) > 0
		_aCols = {}
		aadd (_aCols, {1, 'Componente',     45, ''})
		aadd (_aCols, {2, 'Descricao',     170, ''})
		aadd (_aCols, {3, 'Almox',          25, ''})
		aadd (_aCols, {4, 'Necessidade',    45, '@E 999,999,999.99'})
		aadd (_aCols, {5, 'Disponivel',     45, '@E 999,999,999.99'})
		aadd (_aCols, {6, 'OP',             50, ''})
		aadd (_aCols, {7, 'Produto da OP', 200, ''})
		u_F3Array (_aAvisos, "Disponibilidade de empenhos", _aCols,,, iif (_lDescob, "Empenhos a descoberto", "Disponibilidade dos empenhos") + " para as OPs existentes", "Obs.: NECESSIDADE = empenhos de TODAS as OPs" + iif (_lDescob, ", mas apenas os empenhos a descoberto sao mostrados aqui.", "."))
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return
