// Programa...: CargFull
// Autor......: Robert Koch
// Data.......: 15/12/2014
// Descricao..: Envia ou busca de volta carga do FullWMS.
//
// Historico de alteracoes:
// 10/07/2015 - Robert - Verifica se a carga tem transportadora antes de enviar para o FullWMS.
//

// --------------------------------------------------------------------------
User Function CargFull (_sQueFazer)
	local _sMsg        := ""
	local _oSQL        := NIL
	local _sNroDoc     := ""
	local _lContinua   := .T.
	local _aAreaAnt    := U_ML_SRArea ()

	if _lContinua .and. _sQueFazer == 'E'  // Enviar para Fullsoft
		if _lContinua .and. empty (dak -> dak_vatran)
			_lContinua = U_MsgNoYes ("Carga ainda nao tem transportadora definida. Deseja enviar para o FullWMS assim mesmo?")
		endif
		if _lContinua .and. dak -> dak_vafull == 'S'
			u_help ("Carga ja foi enviada para o FullWMS")
			_lContinua = .F.
		endif
		if _lContinua
			reclock ("DAK", .F.)
			dak -> dak_vafull = 'S'
			dak -> dak_blqcar = '1'
			msunlock ()
		endif 

	elseif _lContinua .and. _sQueFazer == 'C'  // Cancelar no Fullsoft
		if dak -> dak_vafull != 'S'
			u_help ("Carga nao foi enviada para o FullWMS")
			_lContinua = .F.
		endif

		if _lContinua
			// Monta chave de leitura da tabela de retornos do Fullsoft.
			// Importante: manter aqui o campo Saida_Id igual `a view V_WMS_PEDIDOS
			//_sSaida_Id = 'DAK' + dak -> dak_filial + dak -> dak_cod + dak -> dak_seqcar
			_sNroDoc = '20' + dak -> dak_filial + dak -> dak_cod

			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " select count (*)"
			_oSQL:_sQuery +=   " from tb_wms_pedidos"
			_oSQL:_sQuery +=  " where nrodoc   = '" + _sNroDoc + "'"
			_oSQL:_sQuery +=    " and status  != '9'"
			if _oSQL:RetQry () > 0
				_sMsg = "Separacao consta no Fullsoft. Exclua, antes, a solicitacao no Fullsoft."
				if U_ZZUVL ('029', __cUserId, .F.)
					_lContinua = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
				else
					u_help (_sMsg)
					_lContinua = .F.
				endif
			endif

			if _lContinua
				reclock ("DAK", .F.)
				dak -> dak_vafull = ''
				dak -> dak_blqcar = ''
				msunlock ()
			endif
		endif 
	endif
	
	U_ML_SRArea (_aAreaAnt)
return
