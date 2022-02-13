// Programa...: EnvEtFul
// Autor......: Robert Koch
// Data.......: 19/07/2018
// Descricao..: Envia etiqueta para ser recebida pelo FullWMS.
//              Gerado Com base no SD3250I.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Envia etiquetas de pallets para o FullWMS, gravando-as na tabela tb_wms_etiquetas
// #PalavasChave      #etiqueta #FullWMS
// #TabelasPrincipais #ZA1
// #Modulos           #PCP

// Historico de alteracoes (do SD3250I, mantido para ter historico do calculo de data de validade dos lotes)
// 01/08/2017 - Robert - Passa a gravar a tabela tb_wms_etiquetas (era feito logo apos a impressao das etiquetas).
// 18/08/2017 - Robert - Valid.produto na gravacao de etiquetas para FullWMS (tb_wms_etiquetas) - GLPI 2981
//                          - Quando OP de reprocesso assume dt valid do lote original (C2_VADVORI), cfe informada pelo usuario.
//                          - Quando OP normal, calculava dt.valid.=ZA1_DATA+B1_PRVALID. Alterado para C2_DATPRI+B1_PRVALID para manter consistencia com a impressao da OP.
// 25/08/2017 - Robert - Passa a gravar a data de validade como C2_DATPRF+B1_PRVALID nas etiquetas.
//
// Historico de alteracoes (deste programa)
// 04/09/2018 - Robert - Implementada exportacao de etiq. de NF
//                     - Reestruturacao exportacao de etiq. de OP
//                     - Grava campo tb_wms_etiquetas.status=N
// 24/10/2018 - Robert - Separado tratamento por origem (OP / NF / tabela ZAG)
// 25/09/2019 - Robert - Nao considerava ZAG_ALMORI na busca do lote no SB8.
// 20/08/2020 - Robert - Envia para o Full somente se o item existir na view v_wms_item.
//                     - Inseridas tags para catalogar fontes.
// 10/11/2020 - Robert - Valida dados logisticos no Full (qt.pallet e regiao de armazenagem) antes de enviar a etiqueta (GLPI 8790)
// 24/01/2022 - Robert - Vamos usar etiquetas no AX02, mesmo sem integracao com FullWMS (GLPI 11515).
// 11/02/2022 - Robert - Desabilitado envio para Full quando etiq. de NF de entrada (nunca chegamos a usar).
//

// ------------------------------------------------------------------------------------
User Function EnvEtFul (_sEtiq, _lMsg)
	Local _aAreaAnt  := U_ML_SRArea ()
	local _oSQL      := NIL
	local _dValid    := ctod ('')
	local _aLoteNF   := {}
	local _aLoteZAG  := {}
	local _lContinua := .T.

	u_log2 ('info', 'Verificando necessidade de enviar etiqueta ' + _sEtiq + ' para o FullWMS.')
	if _lContinua
		za1 -> (dbsetorder (1))  // ZA1_FILIAL+ZA1_CODIGO+ZA1_DATA+ZA1_OP
		if ! za1 -> (dbseek (xfilial ("ZA1") + _sEtiq, .F.))
			u_help ("Etiqueta '" + _sEtiq + "' nao cadastrada.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. left (_sEtiq, 1) == '0'
		u_log2 ('aviso', "Etiquetas iniciadas por '0' sao geradas diretamente pelo FullWMS. Nao vou gerar tb_wms_etiquetas.")
		_lContinua = .F.
	endif

	if _lContinua
		sb1 -> (dbsetorder(1))
		if ! sb1 -> (dbseek (xFilial ("SB1") + za1 -> za1_prod, .F.))
			u_Help ("Produto '" + alltrim (za1 -> za1_prod) + "' (informado na etiqueta) nao cadastrado.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. sb1 -> b1_vafullw != 'S'
		U_Log2 ('info', "Produto '" + sb1 -> b1_cod + "' nao eh controlado pelo FullWMS. Nao ha necessidade de enviar etiqueta para o Full.")
		_lContinua = .F.
	endif

	if _lContinua .and. ! empty (za1 -> za1_op)
		sc2 -> (dbsetorder(1))
		if ! sc2 -> (dbseek (xFilial ("SC2") + za1 -> za1_op, .F.))
			u_Help ("OP '" + za1 -> za1_op + "' (informada na etiqueta) nao cadastrada.",, .t.)
			_lContinua = .F.
		endif
	endif
	if _lContinua .and. za1 -> za1_impres != 'S'
		if _lMsg
			u_help ('Etiquetas sao exportadas para o FullWMS somente depois de impressas.',, .t.)
		endif
		_lContinua = .F.
	endif

	// Busca validade do lote conforme origem da etiqueta.
	if _lContinua
		if ! empty (za1 -> za1_op)  // Etiqueta gerada por apontamento de producao
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT COUNT (*)"
			_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3 "
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND D3_FILIAL  = '" + za1 -> za1_filial + "'"
			_oSQL:_sQuery +=   " AND D3_OP      = '" + za1 -> za1_op     + "'"
			_oSQL:_sQuery +=   " AND D3_VAETIQ  = '" + za1 -> za1_codigo + "'"
			_oSQL:_sQuery +=   " AND D3_CF      LIKE 'PR%'"
		//	_oSQL:Log ()
			if _oSQL:RetQry () == 1
				u_log2 ('debug', 'Encontrei o apontamento')
				if sc2 -> c2_vaopesp == 'R'  // OP de reprocesso assume dt valid do lote original, cfe informada pelo usuario.
					_dValid = sc2 -> c2_vadvori
				else
					_dValid = sc2 -> c2_datprf + sb1 -> b1_prvalid
				endif
	
				_GravaEtq ('01', substr (za1 -> za1_op, 1, 8), _dValid)  // Sempre empresa 01 pois os produtos envasados devem ir para a logistica.
			else
				if _lMsg
					u_help ("Nao encontrei apontamento de producao correspondente. Nao vou exportar esta etiqueta para o FullWMS.", _oSQL:_sQuery, .t.)
				endif
			endif
		
		// Etiqueta gerada por entrada de NF
		elseif ! empty (za1 -> za1_doce)
			if .F. // Por enquanto nao estamos integrando NF de entrada com o Fullsoft. Na verdade da verdade, nunca usamos... Robert, 11/02/2022.
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "SELECT D1_LOTECTL, B8_DTVALID"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD1") + " SD1 "
				_oSQL:_sQuery +=  " LEFT JOIN " + RetSQLName ("SB8") + " SB8 "
				_oSQL:_sQuery +=       " ON (SB8.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=       " AND SB8.B8_FILIAL  = SD1.D1_FILIAL"
				_oSQL:_sQuery +=       " AND SB8.B8_LOTECTL = SD1.D1_LOTECTL"
				_oSQL:_sQuery +=       " AND SB8.B8_LOTEFOR = SD1.D1_LOTEFOR"
				_oSQL:_sQuery +=       " AND SB8.B8_PRODUTO = SD1.D1_COD"
				_oSQL:_sQuery +=       ")"
				_oSQL:_sQuery += " WHERE SD1.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND D1_FILIAL  = '" + za1 -> za1_filial + "'"
				_oSQL:_sQuery +=   " AND D1_DOC     = '" + za1 -> za1_doce   + "'"
				_oSQL:_sQuery +=   " AND D1_SERIE   = '" + za1 -> za1_seriee + "'"
				_oSQL:_sQuery +=   " AND D1_FORNECE = '" + za1 -> za1_fornec + "'"
				_oSQL:_sQuery +=   " AND D1_LOJA    = '" + za1 -> za1_lojaf  + "'"
				_oSQL:_sQuery +=   " AND D1_ITEM    = '" + za1 -> za1_item   + "'"
				_oSQL:_sQuery +=   " AND D1_COD     = '" + za1 -> za1_prod   + "'"
				_oSQL:Log ()
				_aLoteNF = aclone (_oSQL:Qry2Array ())
				if len (_aLoteNF) == 0
					u_help ("Nao encontrei a NF relacionada a esta etiqueta.",, .t.)
					_lContinua = .F.
				elseif len (_aLoteNF) == 1
					u_log2 ('debug', 'Encontrei a nota')
					_GravaEtq ('02', _aLoteNF [1, 1], _aLoteNF [1, 2])  // Sempre 02 pois as notas de compra devem ir para o almox.02.
				elseif len (_aLoteNF) > 1
					u_help ("Encontrei mais de uma NF relacionada a esta etiqueta.", _oSQL:_sQuery, .t.)
					_lContinua = .F.
				endif
			endif

		// Etiqueta gerada por solicitacao manual de transferencia.
		elseif ! empty (za1 -> za1_idZAG)
			if .f.  // Implantacao do FullWMS no AX 02 foi suspensa indefinidamente. Robert, 24/01/2022
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "SELECT ZAG_LOTORI, B8_DTVALID, ZAG_ALMDST"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZAG") + " ZAG "
				_oSQL:_sQuery +=  " LEFT JOIN " + RetSQLName ("SB8") + " SB8 "
				_oSQL:_sQuery +=       " ON (SB8.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=       " AND SB8.B8_FILIAL  = ZAG.ZAG_FILORI"
				_oSQL:_sQuery +=       " AND SB8.B8_LOTECTL = ZAG.ZAG_LOTORI"
				_oSQL:_sQuery +=       " AND SB8.B8_LOCAL   = ZAG.ZAG_ALMORI"
				_oSQL:_sQuery +=       " AND SB8.B8_PRODUTO = ZAG.ZAG_PRDORI"
				_oSQL:_sQuery +=       ")"
				_oSQL:_sQuery += " WHERE ZAG.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND ZAG.ZAG_FILIAL = '" + xfilial ("ZAG") + "'"
				_oSQL:_sQuery +=   " AND ZAG.ZAG_DOC    = '" + za1 -> za1_idZAG + "'"
				_oSQL:Log ()
				_aLoteZAG = aclone (_oSQL:Qry2Array ())
				if len (_aLoteZAG) == 0
					u_help ("Nao encontrei a solicitacao de transferencia '" + za1 -> za1_idZAG + "' relacionada a esta etiqueta.",, .t.)
					_lContinua = .F.
				elseif len (_aLoteZAG) == 1
					u_log2 ('debug', 'Encontrei o ZAG e o SB8')
	//				if _aLoteZAG [1, 3] == '02'  // Destina-se ao almox.02 (embalagens/insumos)
	//					_GravaEtq ('02', _aLoteZAG [1, 1], _aLoteZAG [1, 2])
					if _aLoteZAG [1, 3] == '01'  // Destina-se ao almox.01 (logistica)
						_GravaEtq ('01', _aLoteZAG [1, 1], _aLoteZAG [1, 2])
					else
						u_log2 ('aviso', 'Nao ha necessidade de enviar esta etiqueta para o FullWMS, pois nao tem lote informado no ZAG e/ou ax destino nao opera pelo FullWMS.')
					endif
				elseif len (_aLoteZAG) > 1
					u_help ("Encontrei mais de uma solicitacao de transferencia (ou mais de um lote) relacionada a esta etiqueta.", _oSQL:_sQuery, .t.)
					_lContinua = .F.
				endif
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
Return



// --------------------------------------------------------------------------
// Grava etiqueta na tabela de integracao.
static function _GravaEtq (_sEmprWMS, _sLote, _dValid)
	local _oSQL     := NIL
	local _aQryWMS  := {}
	local _lEnviar  := .T.
	local _lRetEnv  := .T.
	local _sMsgNEnv := ''
	local _sLinkSrv := ""

	// Busca o caminho do banco de dados do FullWMS
	_sLinkSrv = U_LkServer ('FULLWMS_AX' + _sEmprWMS)

	// Verifica alguns cadastros que costumam dar problema no FullWMS.
	// Consulta via linked server
	if _lRetEnv .and. _lEnviar .and. ! empty (_sLinkSrv)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT REGIAO_ARMAZENAGEM, QTD_PALETE"
		_oSQL:_sQuery += " FROM openquery (" + _sLinkSrv + ","
		_oSQL:_sQuery += " 'select *"
		_oSQL:_sQuery +=  " from V_WMS_DADOS_LOGISTICOS"
		_oSQL:_sQuery += " where COD_ITEM = ''" + alltrim (za1 -> za1_prod) + "''"
		_oSQL:_sQuery += " ')"
		_oSQL:Log ()
		_aQryWMS = aclone (_oSQL:Qry2Array (.F., .F.))
//		u_log2 ('debug', _aQryWMS)
		if _lRetEnv .and. len (_aQryWMS) == 0
			_sMsgNEnv += "Nao encontrei nenhum cadastro de dados logisticos para o item '" + alltrim (za1 -> za1_prod) + "' no FullWMS."
			_lRetEnv = .F.
		endif
		if _lRetEnv .and. empty (_aQryWMS [1, 1])
			_sMsgNEnv += "Regiao de armazenagem nao informada."
			_lRetEnv = .F.
		endif
		if _lRetEnv .and. _aQryWMS [1, 2] < za1 -> za1_quant
			_sMsgNEnv += "Qtd.por pallet nos dados logisticos do FullWMS (" + cvaltochar (_aQryWMS [1, 2]) + "). Quantidade da etiqueta (" + cvaltochar (za1 -> za1_quant) + ") nao pode ser maior."
			_lRetEnv = .F.
		endif
	endif
	if _lRetEnv .and. _lEnviar
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "select count (*)"
		_oSQL:_sQuery +=  " from tb_wms_etiquetas"
		_oSQL:_sQuery += " where id = '" + cvaltochar (za1 -> za1_codigo) + "'"
		_oSQL:Log ()
		if _oSQL:RetQry () > 0
			_lEnviar = .F.
			_sMsgNEnv += "Etiqueta jah existe na tabela tb_wms_etiquetas."
			u_log2 ('info', _sMsgNEnv)
		endif
	endif
	if _lRetEnv .and. _lEnviar
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "select count (*)"
		_oSQL:_sQuery +=  " from v_wms_item"
		_oSQL:_sQuery += " where coditem = '" + alltrim (za1 -> za1_prod) + "'"
		_oSQL:Log ()
		if _oSQL:RetQry () == 0
			_lRetEnv = .F.
			_sMsgNEnv += "Produto ainda nao foi disponibilizado para o FullWMS (view v_wms_item). Verifique no cadastro se foi configurado para usar FullWMS."
		endif
	endif

	if ! _lRetEnv
		u_help ("Nao vou enviar a etiqueta '" + za1 -> za1_codigo + "' para o FullWMS. " + _sMsgNEnv + " Voce pode reenviar esta etiqueta mais tarde no programa de etiquetas para pallets.", _oSQL:_sQuery, .t.)
	else
		if _lEnviar
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " insert into tb_wms_etiquetas (id, coditem, lote, qtde, validade, empresa, cd, status)"
			_oSQL:_sQuery += " values (" + cvaltochar (za1 -> za1_codigo) + ","
			_oSQL:_sQuery +=          "'" + alltrim (za1 -> za1_prod) + "',"
			_oSQL:_sQuery +=          "'" + _sLote + "',"
			_oSQL:_sQuery +=          cvaltochar (za1 -> za1_quant) + ","
			_oSQL:_sQuery +=          "'" + dtos (_dValid) + "',"
			_oSQL:_sQuery +=          "'" + _sEmprWMS + "',"
			_oSQL:_sQuery +=          "'" + za1 -> za1_filial + "',"
			_oSQL:_sQuery +=          "'N')"  // N=ainda nao lida pelo Full
			_oSQL:Log ()
			if ! _oSQL:Exec ()
				U_help ("Erro ao enviar etiqueta para FullWMS: " + _oSQL:_sQuery,, .t.)
				_lRetEnv = .F.
			endif
		endif
	endif
return _lRetEnv
