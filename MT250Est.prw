// Programa...: MT250Est
// Autor......: Robert Koch
// Data.......: 09/12/2014
// Descricao..: P.E. para validar o estorno do apontamento de producao.
//              Criado inicialmente para integracao com Fullsoft.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Valida se vai permitir o estorno de apontamento de OP.
// #PalavasChave      #estorno_apontamento_OP #FULLWMS # ordem_de_producao
// #TabelasPrincipais #SD3
// #Modulos           #PCP #EST

// Historico de alteracoes:
// 17/08/2018 - Robert  - Grava evento quando envolver FullWMS.
// 28/05/2019 - Andre   - Adicionado validacao que não permite exclusao do apontamento sem antes excluir movimento de guarda.
// 13/06/2019 - Robert  - Verificava movimento de 'guarda' da etiqueta mesmo quando etiqueta vazia.
// 27/08/2019 - Cláudia - Incluida rotina _LibEst(liberar estorno) para verificar se usuário tem permissão para executar o processo.
// 15/10/2020 - Robert  - Validacao de acesso do usuario passa a ser feita antes de verificar o FullWMS (mais demorado).
//                      - Incluidas tags para catalogo de fontes.
// 03/03/2021 - Robert  - Desabilitado gravação do Evento
// 05/10/2021 - Robert  - Desabilitado contorno que permitia ao grupo 029 estornar apont.de etiq.jah vista pelço FullWMS (o pessoal estorna producao sem se importar em fazer o ajuste na integracao com FullWMS).
// 08/10/2021 - Robert  - Nao considerava status_protheus = 'C' na validacao da integracao com FullWMS (GLPI 10041).
// 05/10/2022 - Robert  - Valida tabela tb_wms_entrada pelo 'codfor' e nao mais por 'nrodoc'.
// 19/02/2024 - Robert  - Melhorada validacao campo status_protheus na leitura da tb_wms_entrada.
// 14/03/2024 - Robert  - Melhorada validacao campos status e status_protheus na leitura da tb_wms_entrada.
// 25/04/2024 - Robert  - Criado tratamento para desfazimento de guarda de pallet (GLPI 14965)
//

// ----------------------------------------------------------------
user function MT250Est ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	if ! U_ZZUVL ('090', __cUserId, .T.)
		_lRet = .F.
	endif

//	if _lRet
	if _lRet .and. ! empty (sd3 -> d3_vaetiq)
		_lRet = _VerFull ()
	endif
	
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return _lRet


// --------------------------------------------------------------------------
// Se foi um apontamento 'via etiqueta', eh por que trata-se de pallet de
// produto acabado (envasado). Essa etiqueta serve para 'enviar' o pallet
// para ser guardado no setor de logistica.
// Para permitir o estorno do apontamento, preciso verificar, antes, se a
// etiqueta encontra-se em uma situacao aceitavel para isso.
static function _VerFull ()
	local _lRet      := .T.
	local _oSQL      := NIL
	local _sMsg      := ""
	local _aStatFull := {}
	local _aDesfazim := {}
	public _oEvtEstF := NIL

	// Verifica se existe operacao de 'desfazimento de guarda' do pallet.
	// Isso significa que foi guardado normalmente, e que depois foi feita
	// uma solicitacao de transferencia de volta, com motivo 09 (especifico
	// para esta finalidade). Geralmente isso ocorre quando ha necessidade
	// de estornar o apontamento de producao por algum motivo.
	if _lRet .and. ! empty (sd3 -> d3_vaetiq)
		_lTemDesf = .F.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT ZAG_DOC, ZAG_SEQ, ZAG_EXEC"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZAG") + " ZAG "
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " AND ZAG_FILIAL  = '" + xfilial ("ZAG") + "'"
		_oSQL:_sQuery +=    " AND ZAG_OP      = '" + sd3 -> d3_op + "'"
		_oSQL:_sQuery +=    " AND ZAG_ETQREF  = '" + sd3 -> d3_vaetiq + "'"
		_oSQL:_sQuery +=    " AND ZAG_CODMOT  = '09'"
		_oSQL:Log ()
		_aDesfazim = aclone (_oSQL:Qry2Array (.f., .f.))
		if len (_aDesfazim) == 1 .and. _aDesfazim [1, 3] != 'S'
			_sMsg := "Encontrei a solic.transf. '" + _aDesfazim [1, 1] + '/' + _aDesfazim [1, 2] + "' para desfazimento de guarda da etiqueta '" + sd3 -> d3_vaetiq + "'. Entretanto, essa sol.transf. ainda nao foi executada."
			u_help (_sMsg, _oSQL:_sQuery, .t.)
			_lRet = .F.
		endif
	endif

	if _lRet .and. ! empty (sd3 -> d3_vaetiq)
		// Se tem operacao de desfazimento de guarda concluida, posso deixar estornar o apontamento.
		if len (_aDesfazim) == 1 .and. _aDesfazim [1, 3] == 'S'
			U_Log2 ('info', '[' + procname () + ']Encontrei a solic.transf. ' + _aDesfazim [1, 1] + '/' + _aDesfazim [1, 2] + ' para desfazimento de guarda da etiqueta. Nem vou conferir a tabela de integracao tb_wms_entrada.')
		else
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " select status, status_protheus"
			_oSQL:_sQuery +=   " from tb_wms_entrada"
			_oSQL:_sQuery +=  " where codfor = '" + sd3 -> d3_vaetiq + "'"
			_aStatFull = aclone (_oSQL:Qry2Array (.f., .f.))
			U_Log2 ('debug', _aStatFull)
			if len (_aStatFull) > 1
				_sMsg := "Encontrei a etiqueta '" + sd3 -> d3_vaetiq + "' MAIS DE UMA VEZ na tabela de integracao. Verifique!"
				u_help (_sMsg, _oSQL:_sQuery, .t.)
				_lRet = .F.
			elseif len (_aStatFull) == 1
				U_Log2 ('debug', '[' + procname () + '] >>' + _aStatFull [1, 1] + '<<')
				U_Log2 ('debug', '[' + procname () + '] >>' + _aStatFull [1, 2] + '<<')
				U_Log2 ('debug', '[' + procname () + ']' + cvaltochar (_aStatFull [1, 1] == '9'))
				U_Log2 ('debug', '[' + procname () + ']' + cvaltochar (empty (_aStatFull [1, 2])))
				if alltrim (_aStatFull [1, 1]) == '9' .and. empty (_aStatFull [1, 2])
					U_Log2 ('debug', '[' + procname () + ']Vou permitir o estorno por que a tarefa de recebimento foi excluida no Full e a transferencia entre AX no Protheus ainda nao foi executada.')
				elseif left (_aStatFull [1, 2], 1) == 'C'
					U_Log2 ('debug', '[' + procname () + ']Vou permitir o estorno por que a guarda do pallet foi abortada manualmente na tabela tb_wms_entrada.')
				else
					_sMsg := "Esta entrada de estoque ja foi aceita pelo FullWMS. Para estornar esta producao exclua, antes, a tarefa na tela de gerenciamento de recebimentos no FullWMS (pesquise a etiqueta no campo PLACA)." + chr (13) + chr (10) + chr (13) + chr (10)
					_sMsg += "Dados adicionais:" + chr (13) + chr (10)
					_sMsg += "Documento: " + sd3 -> d3_doc + chr (13) + chr (10)
					_sMsg += "Etiq/pallet: " + sd3 -> d3_vaetiq
					u_help (_sMsg, _oSQL:_sQuery, .t.)
					_lRet = .F.
				endif
			endif
		endif
	endif
	
	if _lRet .and. ! empty (sd3 -> d3_vaetiq)
		// Se tem operacao de desfazimento de guarda concluida, posso deixar estornar o apontamento.
		if len (_aDesfazim) == 1 .and. _aDesfazim [1, 3] == 'S'
			U_Log2 ('info', '[' + procname () + ']Encontrei a solic.transf. ' + _aDesfazim [1, 1] + '/' + _aDesfazim [1, 2] + ' para desfazimento de guarda da etiqueta. Nem vou conferri a transferencia original do envase para a logistica.')
		else
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT COUNT (*)"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD3") + " SD3 "
			_oSQL:_sQuery +=  " WHERE D_E_L_E_T_  = ''"
			_oSQL:_sQuery +=    " AND D3_FILIAL   = '" + xfilial ("SD3") + "'"
			_oSQL:_sQuery +=    " AND D3_VAETIQ   = '" + sd3 -> d3_vaetiq + "'"
			_oSQL:_sQuery +=    " AND D3_CF       = 'RE4'"
			_oSQL:_sQuery +=    " AND D3_ESTORNO != 'S'"
			_oSQL:_sQuery +=    " AND D3_LOCAL    = '" + sd3 -> d3_local + "'"
			_oSQL:_sQuery +=    " AND D3_COD      = '" + sd3 -> d3_cod + "'"
			_oSQL:Log ()
			if _oSQL:RetQry (1, .f.) > 0
				u_help ("Movimento de guarda (Transf.p/ax.01) do pallet ainda existe. É necessario excluir antes o movimento de guarda.", _oSQL:_sQuery, .t.)
				_lRet = .F.
			endif
		endif
	endif
return _lRet
