// Programa...: BatTSS
// Autor......: Robert Koch
// Data.......: 20/11/2019
// Descricao..: Verifica inconsistencias no TSS / SPED
//
// Historico de alteracoes:
// 01/09/2022 - Robert - Melhorias ClsAviso.
// 02/10/2022 - Robert - Trocado grpTI por grupo 122 no envio de avisos.
// 03/03/2024 - Robert - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

// -----------------------------------------------------------------------------------------------------------------
user function BatTSS (_sTipoVer)
	local _oSQL      := NIL
	local _oAviso    := NIL
	local _oNFe      := NIL
	local _sReg656   := ''
	local _nQtAlt656 := 0
	local _nQtAlt4   := 0
	local _TSS0004   := ''

	_oBatch:Retorno = 'S'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente

	// Verifica casos em que a SEFAZ estiver retornando rejeicao 656 (uso indevido). Tivemos mais de uma situacao em que
	// o sistema recebe 656 e mesmo assim fica tentando reenviar inutilizacao de cupons (GLPI 6020 e 7054)
	// Abaixo explicacao da SEFAZ:
	//    "Por causa disso, foi estabelecida a regra de que uma mesma NF-e ou NFC-e pode ter no máximo 30 rejeições iguais.
	//     Se uma nota ultrapassar esse limite, então o ambiente de emissão ficará bloqueado para a empresa por uma hora.
	//     E se a empresa receber 50 bloqueios temporários, e mesmo assim a retransmissão em looping continuar acontecendo,
	//     então a empresa poderá ter um bloqueio permanente. Quando a empresa recebe um bloqueio permanente, então o
	//     desbloqueio somente pode ser feito por um fiscal da SEFAZ.
	if _sTipoVer == '656'
		_nQtAlt656 = 0
		sf3 -> (dbsetorder (5))  // F3_FILIAL, F3_SERIE, F3_NFISCAL, F3_CLIEFOR, F3_LOJA, F3_IDENTFT, R_E_C_N_O_, D_E_L_E_T_
		_oNFe := ClsNFe ():New ()
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "select INDEVIDO.ID_ENT,"
		_oSQL:_sQuery +=       " INDEVIDO.NFE_ID,"
		_oSQL:_sQuery +=       " SUM (CASE WHEN DATEDIFF (MINUTE, CAST (INDEVIDO.DTREC_SEFR + ' ' + INDEVIDO.HRREC_SEFR AS DATETIME), CURRENT_TIMESTAMP) <= 120 THEN 1 ELSE 0 END) AS QTOCORREC,"
		_oSQL:_sQuery +=       " COUNT (*) AS TOT_OCORR,"
		_oSQL:_sQuery +=       " ISNULL (SPED050.R_E_C_N_O_, 0) AS RECNO_050,"
		_oSQL:_sQuery +=       " ISNULL (SPED050.STATUS, '') AS STAT_050,"
		_oSQL:_sQuery +=       " ISNULL (SPED050.STATUSCANC, '') AS STCANC_050,"
		_oSQL:_sQuery +=       " ISNULL (SPED050.AMBIENTE, 0) AS AMBIENTE,"
		_oSQL:_sQuery +=       " ISNULL (SF3.R_E_C_N_O_, 0) as RECNO_SF3"
		_oSQL:_sQuery +=  " FROM SPED054 AS INDEVIDO"
		_oSQL:_sQuery +=       " LEFT JOIN SPED050 "
		_oSQL:_sQuery +=            " LEFT JOIN " + RetSQLName ("SF3") + " SF3"
		_oSQL:_sQuery +=            " ON (SF3.D_E_L_E_T_ = '' AND (SF3.F3_CFO >= '5' OR (SF3.F3_CFO < '5' AND SF3.F3_FORMUL = 'S'))"
		_oSQL:_sQuery +=            " AND SF3.F3_FILIAL  = '" + xfilial ("SF3") + "'"
		_oSQL:_sQuery +=            " AND SF3.F3_SERIE + SF3.F3_NFISCAL = SPED050.NFE_ID)"
		_oSQL:_sQuery +=       " ON (SPED050.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=       " AND SPED050.ID_ENT     = INDEVIDO.ID_ENT"
		_oSQL:_sQuery +=       " AND SPED050.NFE_ID     = INDEVIDO.NFE_ID)"
		_oSQL:_sQuery += " WHERE INDEVIDO.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND INDEVIDO.ID_ENT = '" + _oNFe:GetEntid () + "'"  // Filial atual
		_oSQL:_sQuery +=   " AND INDEVIDO.DTREC_SEFR >= '" + dtos (date () - 1) + "'"
		_oSQL:_sQuery +=   " AND INDEVIDO.CSTAT_SEFR = '656'"

		// Se depois do 656 teve uma autorizacao de inutilizacao/cancelamento, entao posso ignorar o problema.
		_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                     " FROM SPED054 AS MAIS_RECENTE"
		_oSQL:_sQuery +=                    " WHERE MAIS_RECENTE.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                      " AND MAIS_RECENTE.ID_ENT = INDEVIDO.ID_ENT"
		_oSQL:_sQuery +=                      " AND MAIS_RECENTE.NFE_ID = INDEVIDO.NFE_ID"
		_oSQL:_sQuery +=                      " AND MAIS_RECENTE.DTREC_SEFR + MAIS_RECENTE.HRREC_SEFR > INDEVIDO.DTREC_SEFR + INDEVIDO.HRREC_SEFR"
		_oSQL:_sQuery +=                      " AND MAIS_RECENTE.CSTAT_SEFR IN ('101','102')"
		_oSQL:_sQuery +=                      " AND MAIS_RECENTE.NFE_PROT != '')"

		_oSQL:_sQuery += " GROUP BY INDEVIDO.ID_ENT, INDEVIDO.NFE_ID, SPED050.R_E_C_N_O_, SPED050.STATUS, SPED050.STATUSCANC, SPED050.AMBIENTE, SF3.R_E_C_N_O_"
		_oSQL:Log ()
		_sReg656 = _oSQL:Qry2Trb (.F.)
		do while ! (_sReg656) -> (eof ())
			u_logIni ('Retorno_656 NFE_ID ' + alltrim ((_sReg656) -> nfe_id))
			
//			// Se teve algumas ocorrencias recentes, eh um candidato a problemas.
//			if (_sReg656) -> QtOcor24h > 5
//				u_log ((_sReg656) -> QtOcor24h, 'ocorrencias nas ultimas 24 horas')

				// Se teve rejeicao nas ultimas horas, entendo que continua com problema.
				if (_sReg656) -> QtOcorRec > 0
					u_log ((_sReg656) -> QtOcorRec, 'ocorrencias recentes')

					if (_sReg656) -> recno_050 == 0
						u_log ('Nao tem RECNO do SPED050')
						_oBatch:Mensagens += 'Nao encontrei correspondencia entre NFE_ID ' + alltrim ((_sReg656) -> nfe_id) + ' da tabela SPED054 com a SPED050'
						_oBatch:Retorno = 'N'
						(_sReg656) -> (dbskip ())
						loop
					endif

					if (_sReg656) -> ambiente != 1
						u_log ('Tudo bem, nao eh ambiente de producao')
						(_sReg656) -> (dbskip ())
						loop
					endif

					if (_sReg656) -> recno_sf3 == 0
						u_log ('Nao tem RECNO do SF3')
						_oBatch:Mensagens += 'Nao encontrei correspondencia entre NFE_ID ' + alltrim ((_sReg656) -> nfe_id) + ' da tabela SPED054 com a SF3'
						_oBatch:Retorno = 'N'
						(_sReg656) -> (dbskip ())
						loop
					else
						sf3 -> (dbgoto ((_sReg656) -> recno_sf3))
					endif

					if (_sReg656) -> stcanc_050 == 1
						u_log ('Alterando STATUSCANC')
						_oSQL := ClsSQL ():New ()
						_oSQL:_sQuery := "UPDATE SPED050 SET STATUSCANC = 2"
						_oSQL:_sQuery += " WHERE R_E_C_N_O_ = " + cvaltochar ((_sReg656) -> recno_050)
						_oSQL:Log ()
						if _oSQL:Exec ()
							_oAviso := ClsAviso ():New ()
							_oAviso:Tipo       = 'E'
							_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
							_oAviso:Texto      = 'Filial ' + cFilAnt + ' NFE_ID ' + alltrim ((_sReg656) -> nfe_id) + ' - alterando STATUSCANC de 1 para 2 na tabela SPED050 por que estamos recebendo rejeicao 656.'
							if ! empty (sf3 -> f3_dtcanc)
								_oAviso:Texto     += ' Documento ja consta como cancelado na tabela SF3.'
							endif
							_oAviso:Texto     += ' Provavelmente seja necessario reenvio manual para obtermos autorizacao da SEFAZ.'
							_oAviso:Origem     = procname ()
							_oAviso:Grava ()
							_nQtAlt656 ++
						else
							_oBatch:Mensagens += 'Erro no SQL: ' + _oSQL:_sQuery
							_oBatch:Retorno = 'N'
							exit
						endif
					else
						u_log ('Jah estah com statuscanc=1')
					endif
				endif
//			endif
			u_logFim ('Retorno_656 NFE_ID ' + alltrim ((_sReg656) -> nfe_id))
			(_sReg656) -> (dbskip ())
		enddo
		(_sReg656) -> (dbclosearea ())
		dbselectarea ('SM0')
	endif

	if _sTipoVer == 'Canc_TSS004'
		_nQtAlt4 = 0
		_oNFe := ClsNFe ():New ()
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " SELECT SPED050.R_E_C_N_O_ AS RECNO_050, NFE_ID, SPED050.STATUS AS STAT_050, SPED050.STATUSCANC AS STCANC_050, SPED050.AMBIENTE AS AMBIENTE"
		_oSQL:_sQuery +=        ",(SELECT COUNT (*)"
		_oSQL:_sQuery +=           " FROM TSS0004"
		_oSQL:_sQuery +=          " WHERE TSS0004.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=            " AND SPED050.R_E_C_N_O_ = CAST (SUBSTRING (TSS0004.LOGID, 9, 12) AS INT)) AS Qt_TSS0004"
		_oSQL:_sQuery +=   " FROM SPED050"
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND ID_ENT     = '" + _oNFe:GetEntid () + "'"  // Filial atual
		_oSQL:_sQuery +=    " AND DATE_NFE  >= '" + dtos (date () - 1) + "'"
		_oSQL:_sQuery +=    " AND STATUS     = 7"  // Cancelada
		_oSQL:_sQuery +=    " AND STATUSCANC = 1"  // 'Nao enviado'
		_oSQL:_sQuery +=    " AND AMBIENTE   = 1"  // Ambiente de producao
		_oSQL:Log ()
		_TSS0004 = _oSQL:Qry2Trb (.F.)
		do while ! (_TSS0004) -> (eof ())
			u_logIni ('TSS004 NFE_ID ' + alltrim ((_TSS0004) -> nfe_id))
			
			if (_TSS0004) -> Qt_TSS0004 > 100  // Talvez precise ajustar este numero.
				u_log ((_TSS0004) -> Qt_TSS0004, 'ocorrencias no TSS0004')
				u_log ('Alterando STATUSCANC')
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "UPDATE SPED050 SET STATUSCANC = 2"
				_oSQL:_sQuery += " WHERE R_E_C_N_O_ = " + cvaltochar ((_TSS0004) -> recno_050)
				_oSQL:Log ()
				if _oSQL:Exec ()
					_oAviso := ClsAviso ():New ()
					_oAviso:Tipo       = 'E'
					_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
					_oAviso:Texto      = 'Filial ' + cFilAnt + ' NFE_ID ' + alltrim ((_TSS0004) -> nfe_id) + ' - alterando STATUSCANC de 1 para 2 na tabela SPED050 por que tem muitos registros na tabela TSS0004.'
					_oAviso:Texto     += 'Verifique movimentacoes deste documento.'
					_oAviso:Origem     = procname ()
					_oAviso:Grava ()
					_nQtAlt4 ++
				else
					_oBatch:Mensagens += 'Erro no SQL: ' + _oSQL:_sQuery
					_oBatch:Retorno = 'N'
					exit
				endif
			endif
			u_logFim ('TSS004 NFE_ID ' + alltrim ((_TSS0004) -> nfe_id))
			(_TSS0004) -> (dbskip ())
		enddo
		(_TSS0004) -> (dbclosearea ())
		dbselectarea ('SM0')
	endif

	// Mensagem para retorno do batch
	_oBatch:Mensagens += cvaltochar (_nQtAlt656) + ' alter.STATUSCANC(ret.656); '
	_oBatch:Mensagens += cvaltochar (_nQtAlt4) + ' alter.STATUSCANC(excesso TSS0004); '
	
return .T.
