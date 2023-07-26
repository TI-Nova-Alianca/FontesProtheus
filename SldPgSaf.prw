// Programa:  SldSafr
// Autor:     Robert Koch
// Data:      26/07/2023
// Descricao: Consulta resumida de saldos de pagamento de safra.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Consulta
// #Descricao         #Consulta resumida (financeira) de saldos de pagamento de safra.
// #PalavasChave      #saldos #safra #pagamento
// #TabelasPrincipais #SE2
// #Modulos           #Coop

// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function SldPgSaf ()
	private cPerg := 'SLDPGSAF'

	// Verifica se o usuario tem acesso.
	if ! U_ZZUVL ('051')
		return
	endif

	_ValidPerg ()
	if pergunte (cPerg, .T.)
		processa ({|| _AndaLogo ()})
	endif
return



// --------------------------------------------------------------------------
static function _AndaLogo ()
	local _oSQL := NIL

	if mv_par01 < '2023'
		u_help ("Consulta disponivel somente a partir da safra 2023",, .t.)
		return
	endif

	procregua (10)
	incproc ('Consultando dados')

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "EXEC VA_SP_SALDOS_SAFRA"
	_oSQL:_sQuery += " '" + mv_par01 + "'"
	_oSQL:_sQuery += ",'" + mv_par02 + "'"
	_oSQL:_sQuery += ",'" + mv_par03 + "'"
	_oSQL:_sQuery += ",'" + mv_par04 + "'"
	_oSQL:_sQuery += ",'" + mv_par05 + "'"
	_oSQL:Log ('[' + procname () + ']')
	_oSQL:F3Array ('Saldos pagamento safra ' + mv_par01, .t.)

	// nao ficou muito bonito ---> _sHTML = _oSQL:Qry2HTM ('Saldos pagamento safra ' + mv_par01, NIL, 'width="90%" border="1" cellspacing="0" cellpadding="3" align="center"', .t., .t.)
	// nao ficou muito bonito ---> U_ShowHTM (_sHTML, 'N')
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                               Help
	aadd (_aRegsPerg, {01, "Safra                         ", "C", 4,  0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {02, "Associado inicial             ", "C", 6,  0,  "",   "SA2_AS", {},                                  ""})
	aadd (_aRegsPerg, {03, "Loja associado inicial        ", "C", 2,  0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {04, "Associado final               ", "C", 6,  0,  "",   "SA2_AS", {},                                  ""})
	aadd (_aRegsPerg, {05, "Loja associado final          ", "C", 2,  0,  "",   "      ", {},                                  ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
