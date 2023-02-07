// Programa...: VA_RUSED
// Autor......: Robert Koch
// Data.......: 05/02/2023
// Descricao..: Eliminacao definitiva de uma carga de safra (e tabelas relacionadas).

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Eliminacao definitiva de uma carga de safra (e tabelas relacionadas).
// #PalavasChave      #safra #carga #delecao #eliminacao #limpeza
// #TabelasPrincipais #SZE #SZF
// #Modulos           #COOP

// Historico de alteracoes:
//

//#include "totvs.ch"
//#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
user Function VA_RUSED (_sSafra, _sCarga)
	local _lContinua := .T.
	local _oCarSaf   := NIL
	local _aResult   := {}
	local _aAreaAnt  := U_ML_SRArea ()
	private cPerg    := "VA_RUSED"

	u_log2 ('info', 'Iniciando ' + procname ())
	_ValidPerg ()

	// Se recebi uma carga por parametro, ja informo-a nas perguntas.
	if _sCarga != NIL
		SetMVValue (cPerg, "MV_PAR01", _sSafra)
		SetMVValue (cPerg, "MV_PAR02", _sCarga)
		SetMVValue (cPerg, "MV_PAR03", _sCarga)
	else
		_lContinua = pergunte (cPerg, .t.)
	endif


	sze -> (dbsetorder (1))  // ZE_FILIAL+ZE_SAFRA+ZE_CARGA
	sze -> (dbseek (xfilial ("SZE") + mv_par01 + mv_par02, .t.))
	do while _lContinua ;
		.and. sze -> ze_filial == xfilial ("SZE") ;
		.and. sze -> ze_safra  == mv_par01 ;
		.and. sze -> ze_carga  <= mv_par03

		_oCarSaf  := ClsCarSaf ():New ()
		_oCarSaf:GeraAtrib ('SZE')  // Alimenta objeto com dados da tabela
		if empty (_oCarSaf:Carga)
			aadd (_aResult, {'ERRO', sze -> ze_carga, "Impossivel instanciar carga!"})
		else
			if _oCarSaf:ExclDef ()
				aadd (_aResult, {'OK', sze -> ze_carga, "Carga excluida"})
			else
				aadd (_aResult, {'ERRO', sze -> ze_carga, _oCarSaf:UltMsg})
			endif
		endif

		sze -> (dbskip ())
	enddo

	// Mostra resultado
	_aCols = {}
	aadd (_aCols, {1, 'Resultado',  30, ''})
	aadd (_aCols, {2, 'Carga',      40, ''})
	aadd (_aCols, {3, 'Mensagens', 240, ''})
	u_F3Array (_aResult, "Resultado do processo", _aCols)

	U_ML_SRArea (_aAreaAnt)
Return _lContinua


// --------------------------------------------------------------------------
// Cria Perguntas no SX1
static function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}

	// Perguntas para a entrada da rotina
	//                     PERGUNT                           TIPO TAM DEC VALID F3       Opcoes                             Help
	aadd (_aRegsPerg, {01, "Safra                         ", "C", 4,  0,  "",   "",      {},                                ""})
	aadd (_aRegsPerg, {02, "Carga inicial                 ", "C", 4,  0,  "",   "",      {},                                ""})
	aadd (_aRegsPerg, {03, "Carga final                   ", "C", 4,  0,  "",   "",      {},                                ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
