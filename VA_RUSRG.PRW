// Programa...: VA_RUSRG
// Autor......: Robert Koch
// Data.......: 12/02/2020
// Descricao..: Reenvia carga para medicao de grau (desmembrado do VA_RUS.PRW)
//
// Historico de alteracoes:
// 24/02/2020 - Robert - Passa a permitir reenviar para grau tambem quando status '2' ou 'M'
//

// --------------------------------------------------------------------------
// Envia a carga para releitura de grau.
user function VA_RUSRG ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _lContinua := .T.
	local _sMsg      := ''

	if sze -> ze_pesobru <= 0
		u_help ("Carga ainda nao tem peso bruto. Efetue, antes, a primeira pesagem.")
		_lContinua = .F.
	endif

	if _lContinua
		if sze -> ze_status $ 'R/N/D/C'  // 1=Primeira pesagem OK;2=Segunda pesagem OK;R=Recibo impresso;N=NF gerada;D=Redirecionada;C=Cancelada
			u_help ("Status da carga nao permite mais ser reenviada para leitura de grau.")
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. sze -> ze_aglutin $ 'D/O'
		u_help ("Esta e´ uma carga aglutinada / aglutinadora.")
		_lContinua = .F.
	endif

	if _lContinua
		zza -> (dbsetorder (1))  // ZZA_FILIAL+ZZA_SAFRA+ZZA_CARGA+ZZA_PRODUT
		szf -> (dbsetorder (1))  // filial + safra + carga + item
		szf -> (dbseek (xfilial ("SZF") + sze -> ze_safra + sze -> ze_carga, .T.))
		do while ! szf -> (eof ()) .and. szf -> zf_filial == xfilial ("SZF") .and. szf -> zf_safra == sze -> ze_safra .and. szf -> zf_carga == sze -> ze_carga
			if zza -> (dbseek (xfilial ("ZZA") + szf -> zf_safra + szf -> zf_carga + szf -> zf_item, .F.))
				if zza -> zza_status == '1'
					u_help ("Status do item " + zza -> zza_nprod + " ja encontra-se como 'aguardando leitura do grau'.")
				elseif zza -> zza_status == '2'
					if U_MsgNoYes ("Item " + zza -> zza_nprod + " encontra-se com status 'em descarga' na tabela de integracao com medidor de grau. Deseja reiniciar o status?")
						reclock ("ZZA", .F.)
						zza -> zza_status = iif (sze -> ze_pesobru <= 0, '0', '1')
						msunlock ()
					endif
				elseif zza -> zza_status $ '3/M'
					_sMsg = "Status do item " + zza -> zza_nprod + " encontra-se 'concluido' na tabela de integracao com o medidor de grau (resultado: " + cvaltochar (zza -> zza_grau) + " gravado em " + zza -> zza_inist3 + "."
					
					// Se foi gravado com grau zero, deve ter dado algum problema, ou clicaram em 'armazenar' sem medir nada.
					if zza -> zza_grau = 0
						if u_msgNoYes (_sMsg + " Deseja reenviar para nova medicao?")
							reclock ("ZZA", .F.)
							zza -> zza_status = iif (sze -> ze_pesobru <= 0, '0', '1')
							msunlock ()
						endif
					else
						u_help (_sMsg + " Reenvio para medicao de grau nao permitida, pois ja contem valor no grau.")
					endif
				endif
			endif
			szf -> (dbskip ())
		enddo
	endif

	U_ML_SRArea (_aAreaAnt)
return
