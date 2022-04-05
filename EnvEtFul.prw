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
// 31/03/2022 - Robert - Passa a usar a classe ClsEtiq() - GLPI 11825
//

// ------------------------------------------------------------------------------------
User Function EnvEtFul (_sEtiq, _lMsg)
	Local _aAreaAnt := U_ML_SRArea ()
	local _oEtiq    := NIL
	_oEtiq := ClsEtiq ():New (_sEtiq)
	_oEtiq:EnviaFull (_lMsg)
	U_ML_SRArea (_aAreaAnt)
Return

/*
//	local _oSQL      := NIL
	local _dValidEtq := ctod ('')
//	local _aLoteNF   := {}
//	local _aLoteZAG  := {}
	local _sLoteEtq := ''
	local _lContinua := .T.

	u_log2 ('info', 'Verificando necessidade de enviar etiqueta ' + _sEtiq + ' para o FullWMS.')
	if _lContinua
		za1 -> (dbsetorder (1))  // ZA1_FILIAL+ZA1_CODIGO+ZA1_DATA+ZA1_OP
		if ! za1 -> (dbseek (xfilial ("ZA1") + _sEtiq, .F.))
			u_help ("Impossivel enviar etiqueta '" + _sEtiq + "' para o FullWMS: Etiqueta nao cadastrada!",, .t.)
			_lContinua = .F.
		endif
	endif

	// Validacoes abaixo migradas para ZA1_PEF()
	//if _lContinua .and. left (_sEtiq, 1) == '0'
	//	u_log2 ('aviso', "Etiquetas iniciadas por '0' sao geradas diretamente pelo FullWMS. Nao vou gerar tb_wms_etiquetas.")
	//	_lContinua = .F.
	//endif
	//
	//if _lContinua
	//	sb1 -> (dbsetorder(1))
	//	if ! sb1 -> (dbseek (xFilial ("SB1") + za1 -> za1_prod, .F.))
	//		u_Help ("Produto '" + alltrim (za1 -> za1_prod) + "' (informado na etiqueta) nao cadastrado.",, .t.)
	//		_lContinua = .F.
	//	endif
	//endif
	//
	//if _lContinua .and. sb1 -> b1_vafullw != 'S'
	//	U_Log2 ('info', "Produto '" + sb1 -> b1_cod + "' nao eh controlado pelo FullWMS. Nao ha necessidade de enviar etiqueta para o Full.")
	//	_lContinua = .F.
	//endif
	//
	//if _lContinua .and. ! empty (za1 -> za1_op)
	//	sc2 -> (dbsetorder(1))
	//	if ! sc2 -> (dbseek (xFilial ("SC2") + za1 -> za1_op, .F.))
	//		u_Help ("OP '" + za1 -> za1_op + "' (informada na etiqueta) nao cadastrada.",, .t.)
	//		_lContinua = .F.
	//	endif
	//endif
	//if _lContinua .and. za1 -> za1_impres != 'S'
	//	if _lMsg
	//		u_help ('Etiquetas sao exportadas para o FullWMS somente depois de impressas.',, .t.)
	//	endif
	//	_lContinua = .F.
	//endif

	// Verifica se pode enviar para o Full. Sei que algumas validacoes jah foram feitas antes,
	// como por exemplo no momento de apontar a producao, mas vou deixar o teste ser executado
	// novamente aqui por que esta rotina pode ser chamada de outros locais, inclusive manualmente.
	if _lContinua
		_lContinua = U_ZA1PEF (_sEtiq)
	endif

	// Busca lote e validade conforme origem da etiqueta.
	if _lContinua
		_dValidEtq = U_ZA1DVld (_sEtiq)
		_sLoteEtq  = U_ZA1Lote (_sEtiq)
	endif

	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "select count (*)"
		_oSQL:_sQuery +=  " from tb_wms_etiquetas"
		_oSQL:_sQuery += " where id = '" + cvaltochar (za1 -> za1_codigo) + "'"
		_oSQL:Log ()
		if _oSQL:RetQry () > 0
			u_help ("Impossivel enviar etiqueta '" + _sEtiq + "' para o FullWMS: Etiqueta jah existe na tabela tb_wms_etiquetas.", _oSQL:_sQuery, .t.)
		else
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " insert into tb_wms_etiquetas (id, coditem, lote, qtde, validade, empresa, cd, status)"
			_oSQL:_sQuery += " values (" + cvaltochar (za1 -> za1_codigo) + ","
			_oSQL:_sQuery +=          "'" + alltrim (za1 -> za1_prod) + "',"
			_oSQL:_sQuery +=          "'" + _sLoteEtq + "',"
			_oSQL:_sQuery +=          cvaltochar (za1 -> za1_quant) + ","
			_oSQL:_sQuery +=          "'" + dtos (_dValidEtq) + "',"
			_oSQL:_sQuery +=          "'01',"
			_oSQL:_sQuery +=          "'" + za1 -> za1_filial + "',"
			_oSQL:_sQuery +=          "'N')"  // N=ainda nao lida pelo Full
			_oSQL:Log ()
			if ! _oSQL:Exec ()
				U_help ("Erro ao enviar etiqueta para FullWMS: " + _oSQL:_sQuery,, .t.)
				_lRetEnv = .F.
			endif
		endif
	endif
	U_ML_SRArea (_aAreaAnt)
Return
*/

/*

// --------------------------------------------------------------------------
// Grava etiqueta na tabela de integracao.
static function _GravaEtq (_sEmprWMS, _sLote, _dValid)
	local _oSQL     := NIL
//	local _aQryWMS  := {}
	local _lEnviar  := .T.
	local _lRetEnv  := .T.
	local _sMsgNEnv := ''
//	local _sLinkSrv := ""

	// Busca o caminho do banco de dados do FullWMS (caminho jah foi validado antes
	// pelos outros programas que verificam se o item pode ser enviado para o Full)
//	_sLinkSrv = U_LkServer ('FULLWMS_AX' + _sEmprWMS)

	// Vai ser validado pelo SB1PEF()
	//// Verifica alguns cadastros que costumam dar problema no FullWMS.
	//// Consulta via linked server
	//if _lRetEnv .and. _lEnviar .and. ! empty (_sLinkSrv)
	//	_oSQL := ClsSQL ():New ()
	//	_oSQL:_sQuery := "SELECT REGIAO_ARMAZENAGEM, QTD_PALETE"
	//	_oSQL:_sQuery += " FROM openquery (" + _sLinkSrv + ","
	//	_oSQL:_sQuery += " 'select *"
	//	_oSQL:_sQuery +=  " from V_WMS_DADOS_LOGISTICOS"
	//	_oSQL:_sQuery += " where COD_ITEM = ''" + alltrim (za1 -> za1_prod) + "''"
	//	_oSQL:_sQuery += " ')"
	//	_oSQL:Log ()
	//	_aQryWMS = aclone (_oSQL:Qry2Array (.F., .F.))
//	//	u_log2 ('debug', _aQryWMS)
	//	if _lRetEnv .and. len (_aQryWMS) == 0
	//		_sMsgNEnv += "Nao encontrei nenhum cadastro de dados logisticos para o item '" + alltrim (za1 -> za1_prod) + "' no FullWMS."
	//		_lRetEnv = .F.
	//	endif
	//	if _lRetEnv .and. empty (_aQryWMS [1, 1])
	//		_sMsgNEnv += "Regiao de armazenagem nao informada."
	//		_lRetEnv = .F.
	//	endif
	//	if _lRetEnv .and. _aQryWMS [1, 2] < za1 -> za1_quant
	//		_sMsgNEnv += "Qtd.por pallet nos dados logisticos do FullWMS (" + cvaltochar (_aQryWMS [1, 2]) + "). Quantidade da etiqueta (" + cvaltochar (za1 -> za1_quant) + ") nao pode ser maior."
	//		_lRetEnv = .F.
	//	endif
	//endif
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

	// Vai ser validado pelo SB1PEF()
	//if _lRetEnv .and. _lEnviar
	//	_oSQL := ClsSQL ():New ()
	//	_oSQL:_sQuery := "select count (*)"
	//	_oSQL:_sQuery +=  " from v_wms_item"
	//	_oSQL:_sQuery += " where coditem = '" + alltrim (za1 -> za1_prod) + "'"
	//	_oSQL:Log ()
	//	if _oSQL:RetQry () == 0
	//		_lRetEnv = .F.
	//		_sMsgNEnv += "Produto ainda nao foi disponibilizado para o FullWMS (view v_wms_item). Verifique no cadastro se foi configurado para usar FullWMS."
	//	endif
	//endif

	if ! _lRetEnv
		u_help ("Nao vou enviar a etiqueta '" + za1 -> za1_codigo + "' para o FullWMS. " + _sMsgNEnv + " Voce pode tentar reenviar esta etiqueta mais tarde no programa de etiquetas para pallets.", _oSQL:_sQuery, .t.)
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
*/
