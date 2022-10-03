// Programa...: CargFull
// Autor......: Robert Koch
// Data.......: 15/12/2014
// Descricao..: Envia ou busca de volta carga do FullWMS.
//
// Historico de alteracoes:
// 10/07/2015 - Robert - Verifica se a carga tem transportadora antes de enviar para o FullWMS.
// 16/09/2022 - Robert - Iniciada validacao de saldos com FullWMS (GLPI 12612)
// 27/09/2022 - Robert - Envia comparativo estq.Full x Protheus para todos os itens, mesmo sem diferenca de saldo.
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

		// Valida estoques entre os dois sistemas.
		if _lContinua
			_lContinua = _ValEstFul ()
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


// --------------------------------------------------------------------------
// Valida estoques entre Protheus e FullWMS
// A intencao eh nao enviar a carga se houver inconsistencias de saldos.
static function _ValEstFul ()
	local _lValEstq := .T.
	local _oSQL     := NIL
	local _aItemCar := {}
	local _nItemCar := 0
	local _sLinkSrv := ""
	local _aDifEstq := {}
	local _oDifEstq := NIL
	local _sMsgHTM  := ''
	local _aColsDif := {}
	local _oAviso   := NIL

	// Busca o caminho do banco de dados do FullWMS
	_sLinkSrv = U_LkServer ('FULLWMS_AX01')

	// Gera uma array com os itens da carga e saldo no Protheus
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "WITH ITENS AS"
	_oSQL:_sQuery += "("
	_oSQL:_sQuery +=  "SELECT DISTINCT B1_COD, B1_DESC, B1_UM"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SC9") + " SC9, "
	_oSQL:_sQuery +=              RetSQLName ("SB1") + " SB1, "
	_oSQL:_sQuery +=              RetSQLName ("DAI") + " DAI "
	_oSQL:_sQuery +=  " WHERE SC9.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SC9.C9_FILIAL  = '" + xfilial ("SC9") + "'"
	_oSQL:_sQuery +=    " AND SC9.C9_LOCAL   = '01'"
	_oSQL:_sQuery +=    " AND SC9.C9_PEDIDO  = DAI.DAI_PEDIDO"
	_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=    " AND SB1.B1_COD     = SC9.C9_PRODUTO"
	_oSQL:_sQuery +=    " AND SB1.B1_VAFULLW = 'S'"
	_oSQL:_sQuery +=    " AND DAI.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND DAI.DAI_FILIAL = '" + xfilial ("DAI") + "'"
	_oSQL:_sQuery +=    " AND DAI.DAI_COD    = '" + dak -> dak_cod + "'"
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += "SELECT ITENS.B1_COD, ITENS.B1_DESC, ITENS.B1_UM"
	_oSQL:_sQuery +=      ", SUM (CASE WHEN B2_LOCAL = '01' THEN B2_QATU ELSE 0 END) AS ESTQ_01"
	_oSQL:_sQuery +=      ", SUM (CASE WHEN B2_LOCAL = '11' THEN B2_QATU ELSE 0 END) AS ESTQ_11"
	_oSQL:_sQuery +=      ", SUM (CASE WHEN B2_LOCAL = '90' THEN B2_QATU ELSE 0 END) AS ESTQ_90"
	_oSQL:_sQuery +=      ", SUM (CASE WHEN B2_LOCAL = '91' THEN B2_QATU ELSE 0 END) AS ESTQ_91"
	_oSQL:_sQuery +=      ", 0 as Full_Lib"
	_oSQL:_sQuery +=      ", 0 as Full_Blq"
	_oSQL:_sQuery +=  " FROM ITENS,"
	_oSQL:_sQuery +=         RetSQLName ("SB2") + " SB2 "
	_oSQL:_sQuery += " WHERE SB2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SB2.B2_FILIAL  = '" + xfilial ("SB2") + "'"
	_oSQL:_sQuery +=   " AND SB2.B2_COD     = ITENS.B1_COD"
	_oSQL:_sQuery += " GROUP BY ITENS.B1_COD, ITENS.B1_DESC, ITENS.B1_UM"
	_oSQL:_sQuery += " ORDER BY ITENS.B1_COD"
	_oSQL:Log ('[' + procname () + ']')
	_aItemCar = aclone (_oSQL:Qry2Array (.f., .f.))
	U_Log2 ('debug', _aItemCar)

	// Varre a array de itens e preenche coluna com o saldo no FulLWMS.
	_oSQL := ClsSQL ():New ()
	for _nItemCar = 1 to len (_aItemCar)
		_oSQL:_sQuery := "SELECT SALDO"
		_oSQL:_sQuery += " FROM openquery (" + _sLinkSrv + ","
		_oSQL:_sQuery +=                  "' select nvl (sum (qtd), 0) as SALDO"
		_oSQL:_sQuery +=                   " from wms_estoques_cd"
		_oSQL:_sQuery +=                   " where situacao = ''L''"
		_oSQL:_sQuery +=                   " and item_cod_item_log = ''" + alltrim (_aItemCar [_nItemCar, 1]) + "''"
		_oSQL:_sQuery +=                  "')"
		_oSQL:Log ('[' + procname () + ']')
		_aItemCar [_nItemCar, 8] = _oSQL:RetQry (1, .f.)
	next
	//U_Log2 ('debug', _aItemCar)

	// Gera array so das diferencas, para envio de mensagem de monitoramento.
	_aDifEstq = {}
	for _nItemCar = 1 to len (_aItemCar)
	//	por enqto vou mandar todos os itens ---> if _aItemCar [_nItemCar, 4] != _aItemCar [_nItemCar, 3]
			// Ainda nao queremos bloquear ---> _lValEstq = .F.
			aadd (_aDifEstq, aclone (_aItemCar [_nItemCar]))
	//	endif
	next
	
	// Por enquanto, apenas manda msg de aviso para conferencia.
	if len (_aDifEstq) > 0
		//U_Log2 ('aviso', '[' + procname () + ']Conferencia estoque Full x Protheus') //Encontrados itens com diferenca de saldos Protheus x FullWMS')
		//U_Log2 ('aviso', _aDifEstq)

		// Monta mensagem em HTML (soh pra dar trabalho...)
		_aColsDif = {}
		aadd (_aColsDif, {'Produto',      'left',  ''})
		aadd (_aColsDif, {'Descricao',    'left',  ''})
		aadd (_aColsDif, {'U.M.',         'left',  ''})
		aadd (_aColsDif, {'Sld.AX01',     'right', '@E 999,999,999'})
		aadd (_aColsDif, {'Sld.AX11',     'right', '@E 999,999,999'})
		aadd (_aColsDif, {'Sld.AX90',     'right', '@E 999,999,999'})
		aadd (_aColsDif, {'Sld.AX91',     'right', '@E 999,999,999'})
		aadd (_aColsDif, {'Sld.FullWMS',  'right', '@E 999,999,999'})
		_oDifEstq := ClsAUtil ():New (_aDifEstq)
		_sMsgHTM = _oDifEstq:ConvHTM ('Comparativo estoques (Protheus X FullWMS) na carga ' + dak -> dak_cod, ;
									_aColsDif, ;
									'', ;
									.F., ;
									100)
	//	U_Log2 ('debug', '[' + procname () + ']' + _sMsgHTM)

		_oAviso := ClsAviso ():New ()
		_oAviso:Tipo       = 'A'
		_oAviso:DestinAvis = 'liane.lenzi'
		_oAviso:Titulo     = 'Diferenca estoque Protheus x FullWMS'
		_oAviso:Texto      = _sMsgHTM
		_oAviso:Formato    = 'H'
		_oAviso:Origem     = procname () + ' - ' + procname (1)
	//	_oAviso:Grava ()

		// Recebo copia para testes
		_oAviso:DestinAvis = 'robert.koch'
	//	_oAviso:Grava ()
	endif

return _lValEstq
