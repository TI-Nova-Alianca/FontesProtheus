// Programa...: VlEsGP
// Autor......: Robert Koch
// Data.......: 17/08/2018
// Descricao..: Valida estorno de movimento de guarda de pallet
//              Criado como User Function para ser chamado do MA260Est e do MA261Est
//
// Historico de alteracoes:
//

// ----------------------------------------------------------------
user function VlEsGP ()
	local _lRet      := .T.
	local _sMsg      := ""
	local _sJustif   := ""
	public _oEvtEstF := NIL

	if ! empty (sd3 -> d3_vaetiq)
		_sMsg = "Movimentacao de pallet para FullWMS nao deve ser estornada manualmente."
		_lRet = .F.
		if U_ZZUVL ('029', __cUserId, .F.)
			if U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
				do while .T.
					_sJustif = U_Get ('Justificativa', 'C', 150, '', '', space (150), .F., '.T.')
					if _sJustif == NIL
						_lRet = .F.
						loop
					endif
					exit
				enddo
				
				_lRet = .T.
				
				// Cria evento dedo-duro para posterior gravacao em outro P.E. apos a efetivacao do movimento.
				_oEvtEstF := ClsEvent ():New ()
				_oEvtEstF:CodEven  = 'SD3002'
				_oEvtEstF:Texto    = 'Estorno guarda pallet ' + alltrim (sd3 -> d3_vaetiq) + '. Justif: ' + _sJustif
				_oEvtEstF:Produto  = sd3 -> d3_cod
				_oEvtEstF:Etiqueta = sd3 -> d3_vaetiq
				_oEvtEstF:OP       = sd3 -> d3_op
				
			endif
		else
			u_help (_sMsg)
			_lRet = .F.
		endif
	endif
return _lRet
