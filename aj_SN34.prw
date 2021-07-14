// Programa...: Aj_SN34
// Descricao..: Ajusta depreciacao acumulada SN3 e SN4
// Data.......: 19/05/2021
// Autor......: Robert Koch

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento #ajuste
// #Descricao         #Executa procedure especifica para ajuste depreciacao acumulada SN3 e SN4 (GLPI 10239)
// #PalavasChave      #ajuste #depreciacao_acumulada
// #TabelasPrincipais #SN3 #SN4
// #Modulos           #ATF

// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function AJ_SN34 (_lAuto)
	private cPerg := "AJ_SN34"

	if ! U_ZZUVL ('129', __cUserID, .T.)
		return
	endif

	_ValidPerg ()
	pergunte (cPerg, .f.)
	if _lAuto != NIL .and. _lAuto
		processa ({|| _Gera (mv_par01, mv_par02)})
	else
		if pergunte (cPerg, .T.)
			processa ({|| _Gera (mv_par01, mv_par02)})
		endif
	endif
return



// --------------------------------------------------------------------------
static function _Gera (_sCodBase, _sItem)
	local _oSQL     := NIL
	local _aRetProc := {}

	procregua (10)
	incproc ()
	
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "EXEC SP_AJUSTA_DEPR_SN3_SN4 '" + _sCodBase + "', '" + _sItem + "'"
	_oSQL:Log ()
	_aRetProc = aclone (_oSQL:Qry2Array (.F., .F.))
	U_Log2 ('debug', _aRetProc)
	u_showarray (_aRetProc)
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}

	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Codigo base                   ", "C", 10, 0,  "",   "SN3", {},    ""})
	aadd (_aRegsPerg, {02, "Item                          ", "C", 4,  0,  "",   "   ", {},    ""})
	U_ValPerg (cPerg, _aRegsPerg)
Return
