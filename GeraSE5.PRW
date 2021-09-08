// Programa...: GeraSE5
// Autor......: Robert Koch
// Data.......: 19/11/2012
// Descricao..: Gera movimentos no SE5 (tela 'Movimento bancario').
//              Criada, inicialmente, para atender a conta corrente de associados.
//
// Historico de alteracoes:
//
// 08/04/2019 - Catia  - include TbiConn.ch 
// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

user function GeraSE5 (_sOQueGera, _dData, _nValor, _sHistor, _sBanco, _sAgencia, _sNumCon, _sChvEx, _sMsgRet, _lCtOnLine, _sNatureza, _sFormPag)
	local _lContinua  := .T.
	local _aAutoSE5   := {}
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	local _sErro      := ""
	local cPerg       := ""
	local _aBkpSX1    := {}

	_sMsgRet := iif (_sMsgRet == NIL, '', cvaltochar (_sMsgRet))
	
//	u_logIni ()
//	u_log ("Parametros:", _sOQueGera, _dData, _nValor, _sHistor, _sBanco, _sAgencia, _sNumCon, _sChvEx, _sMsgRet, _lCtOnLine, _sNatureza)
	
	if _lContinua
		do case

		// Incluir movimento a receber.
		case _sOQueGera == 'IR'
			_aAutoSE5 = {}
			aadd (_aAutoSE5, {"E5_DATA",    _dData,     nil})
			aadd (_aAutoSE5, {"E5_MOEDA",   'M1',       nil})
			aadd (_aAutoSE5, {"E5_VALOR",   _nValor,    nil})
			aadd (_aAutoSE5, {"E5_BANCO",   _sBanco,    nil})
			aadd (_aAutoSE5, {"E5_AGENCIA", _sAgencia,  nil})
			aadd (_aAutoSE5, {"E5_CONTA",   _sNumCon,   nil})
			aadd (_aAutoSE5, {"E5_NATUREZ", _sNatureza, nil})
			aadd (_aAutoSE5, {"E5_HISTOR",  _sHistor,   nil})
			aadd (_aAutoSE5, {"E5_VACHVEX", _sChvEx,    nil})
			aadd (_aAutoSE5, {"E5_VASZIFP", _sFormPag,  nil})
			_aAutoSE5 = aclone (U_OrdAuto (_aAutoSE5))
			u_log2 ('DEBUG', _aAutoSE5)
	
			// Ajusta parametros da rotina.
			cPerg = 'AFI100'
			_aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
			U_GravaSX1 (cPerg, "04", iif (_lCtOnLine, 1, 2))
	
			lMsErroAuto	:=	.f.
			lMsHelpAuto	:=	.f.
			dbselectarea ("SE5")
			dbsetorder (1)
			MSExecAuto({|x,y,z| FinA100(x,y,z)},0,_aAutoSE5,4)
			if lMsErroAuto
				_sMsgRet += "Erro na rotina automatica de inclusao de movimento bancario: " + U_LeErro (memoread (NomeAutoLog ()))
				_lContinua = .F.
				MostraErro()
			endif
			U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina.
	
	
		// Cancelar movimento a receber (nao consegui usar 'exclusao' via rotina automatica).
		case _sOQueGera == 'CR'
			_aAutoSE5 = {}
			aadd (_aAutoSE5, {"E5_DATA",    _dData,     nil})
			aadd (_aAutoSE5, {"E5_MOEDA",   'M1',       nil})
			aadd (_aAutoSE5, {"E5_VALOR",   _nValor,    nil})
			aadd (_aAutoSE5, {"E5_BANCO",   _sBanco,    nil})
			aadd (_aAutoSE5, {"E5_AGENCIA", _sAgencia,  nil})
			aadd (_aAutoSE5, {"E5_CONTA",   _sNumCon,   nil})
			aadd (_aAutoSE5, {"E5_NATUREZ", _sNatureza, nil})
			aadd (_aAutoSE5, {"E5_HISTOR",  _sHistor,   nil})
			aadd (_aAutoSE5, {"E5_VACHVEX", _sChvEx,    nil})
			aadd (_aAutoSE5, {"E5_VASZIFP", _sFormPag,  nil})
			_aAutoSE5 = aclone (U_OrdAuto (_aAutoSE5))
			u_log2 ('debug', _aAutoSE5)
	
			// Ajusta parametros da rotina.
			cPerg = 'AFI100'
			_aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
			U_GravaSX1 (cPerg, "04", iif (_lCtOnLine, 1, 2))
	
			lMsErroAuto	:=	.f.
			lMsHelpAuto	:=	.f.
			dbselectarea ("SE5")
			dbsetorder (1)
			MSExecAuto({|x,y,z| FinA100(x,y,z)},0,_aAutoSE5,6)  // exclusao nao funcionou. Usando cancelamento.
			if lMsErroAuto
				_sMsgRet += "Erro na rotina automatica de cancelamento de movimento bancario: " + U_LeErro (memoread (NomeAutoLog ()))
				_lContinua = .F.
				MostraErro()
			else
				// No cancelamento alguns campos adicionais nao sao gravados.
				reclock ("SE5", .F.)
				if empty (se5 -> e5_vachvex) ; se5 -> e5_vachvex = _sChvEx   ; endif
				if empty (se5 -> e5_vauser)  ; se5 -> e5_vauser  = cUserName ; endif
				if empty (se5 -> e5_vaSZIFp) ; se5 -> e5_vaSZIFp = _sFormPag ; endif
				msunlock ()
			endif
			U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina.


		otherwise
			_sErro = '[' + procname () + "] Tipo de movimento nao definido para geracao do arquivo SE5."
			u_help (_sErro)
			_sMsgRet += _sErro
			_lContinua = .F.
		endcase
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
//	u_logFim ()
return _lContinua
