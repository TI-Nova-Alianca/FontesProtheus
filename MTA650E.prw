// Programa:  MTA650E
// Autor:     Robert Koch
// Data:      21/11/2022
// Descricao: P.E. para validar a exclusao de Ordem de Producao

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #P.E. para validar a exclusao de Ordem de Producao
// #PalavasChave      #OP #ordem_de_producao #validar #exclusao
// #TabelasPrincipais #SC2
// #Modulos           #PCP #EST

// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function MTA650E ()
	local _lRet650E := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _oSQL     := NIL

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT count (*)"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZA1") + " ZA1"
	_oSQL:_sQuery += " WHERE ZA1.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=   " AND ZA1.ZA1_FILIAL  = '" + xfilial ("ZA1") + "'"
	_oSQL:_sQuery +=   " AND ZA1.ZA1_OP      = '" + sc2 -> c2_num + sc2 -> c2_item + sc2 -> c2_sequen + sc2 -> c2_itemgrd + "'"
	_oSQL:_sQuery +=   " AND ZA1.ZA1_APONT  != 'I'"
	_oSQL:Log ('[' + procname () + ']')
	if _oSQL:RetQry (1, .f.) > 0
		u_help ("Existe(m) etiqueta(s) relacionada(s) a esta OP. Para excluir a OP, inutilize antes a(s) etiqueta(s).", _oSQL:_sQuery, .t.)
		_lRet650E = .F.
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet650E
