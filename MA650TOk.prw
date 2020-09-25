// Programa...: MA650TOk
// Autor......: Robert Koch
// Data.......: 01/12/2014
// Descricao..: P.E. 'Tudo OK' na inclusao de OP.
//
// Historico de alteracoes:
// 27/01/2015 - Robert  - Passa a validar parametros VA_ALMFULP, VA_ALMFULT, VA_ALMFULT
// 17/09/2015 - Robert  - Valida preenchimento do campo C2_VALTORI.
// 25/10/2016 - Robert  - Validacoes ref. revisoes de estruturas do produto.
// 11/11/2016 - Robert  - Valid. ref. revis. estrut. produto estendidas tb. p/ componente VD.
// 25/11/2016 - Robert  - Melhoria mensagem revisoes disponiveis.
// 07/02/2016 - Robert  - Verifica se a revisao do VD existe na tabela SG5.
// 18/08/2017 - Robert  - Valida lote e validade originais para OP de reprocesso.
// 15/10/2019 - Cláudia - Incluída validações no C2_VAEVENT - _VerEvent() GLPI: 6793
//
// ----------------------------------------------------------------
user function MA650TOk ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
   	local _aAmbAnt  := U_SalvaAmb ()

	if _lRet
		_lRet = _VerRepr ()
	endif

	if _lRet
		_lRet = _VerFull ()
	endif

	if _lRet
		_lRet = _VerRevis ()
	endif

//	if _lRet
//		_lRet = _VerEvent () 
//	endif
	
   	U_SalvaAmb (_aAmbAnt)
   	U_ML_SRArea (_aAreaAnt)
return _lRet
//
// --------------------------------------------------------------------------
// Verificacoes integracao com Fullsoft.
static function _VerFull ()
	local _lRet     := .T.
   	local _sMsg     := ""
	local _sAlmFull := GetMv ("VA_ALMFULP",, '')

	// Nao uso esta verificacao quando a OP estah sendo gerada pelo MRP, pois
	// nao consegui criar um gatilho nem ponto de entrada que trocasse o C2_LOCAL
	// para o almox. do Fullsoft. Tudo que consegui foi fazer a troca no ponto
	// de entrada MTA650I, que eh executado depois desta validacao. Robert, 21/12/2014.
	if empty (m->c2_seqmrp)
		if ! empty(_sAlmFull) .and. m->c2_local != _sAlmFull
			sb1 -> (dbsetorder (1))
			if sb1 -> (dbseek (xfilial ("SB1") + m->c2_produto, .F.)) .and. sb1 -> b1_vafullw == 'S'
				_sMsg = "Produto '" + alltrim (sb1 -> b1_cod) + "' controla armazenagem via Fullsoft. Producao deve ser apontada no almoxarifado '" + _sAlmFull + "'."
				if u_zzuvl ('029', __cUserId, .F.)
					_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
				else
					u_help (_sMsg)
					_lret = .F.
				endif
			endif
		endif
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Verificacoes revisoes estrutura.
static function _VerRevis ()
	local _lRet     := .T.
	local _sMsg     := ""
	local _oSQL     := NIL
	local _aRevis := {}
	local _nRevis := 0
	
	// Busca as revisoes de estrutura deste produto.
	if _lRet
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT G5_REVISAO," // + CASE WHEN G5_MSBLQL = '1' THEN '(BLOQUEADA)' ELSE '' END AS REVISAO, "
		_oSQL:_sQuery +=        " dbo.VA_DTOC (G5_DATAREV) AS DATA,"
		_oSQL:_sQuery +=        " rtrim (G5_OBS) AS OBS"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SG5") + " SG5 "
		_oSQL:_sQuery +=  " WHERE SG5.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SG5.G5_FILIAL  = '" + xfilial ("SG5") + "'"
		_oSQL:_sQuery += " AND G5_MSBLQL != '1'"
		_oSQL:_sQuery +=    " AND SG5.G5_PRODUTO = '" + m->c2_produto + "'"
		_oSQL:_sQuery += "ORDER BY G5_REVISAO"
		_aRevis := aclone (_oSQL:Qry2Array(.f., .f.))
	endif

	if _lRet .and. empty (m->c2_revisao) .and. len (_aRevis) > 1
		_sMsg = "O produto da OP tem revisoes de estrutura. Informe uma delas no campo '" + alltrim (RetTitle ("C2_REVISAO")) + chr (13) + chr (10) + chr (13) + chr (10)
		for _nRevis = 1 to len (_aRevis)
			_sMsg += _aRevis [_nRevis, 1] + ' ' + _aRevis [_nRevis, 2] + ' ' + _aRevis [_nRevis, 3] + chr (13) + chr (10)
		next
		u_help (_sMsg)
		_lRet = .F.
	endif
	
	if _lRet .and. ascan (_aRevis, {|_aVal| _aVal [1] == m->c2_revisao}) == 0 .and. len (_aRevis) > 0
		_sMsg = "Revise o campo '" + alltrim (RetTitle ("C2_REVISAO")) + "' (as revisoes disponiveis para este produto sao as seguintes):" + chr (13) + chr (10) + chr (13) + chr (10)
		for _nRevis = 1 to len (_aRevis)
			_sMsg += _aRevis [_nRevis, 1] + ' ' + _aRevis [_nRevis, 2] + ' ' + _aRevis [_nRevis, 3] + chr (13) + chr (10)
		next
		u_help (_sMsg)
		_lRet = .F.
	endif

	// Busca as revisoes do componente VD.
	if _lRet .and. ! empty (m->c2_vaCodVD)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT G5_REVISAO," // + CASE WHEN G5_MSBLQL = '1' THEN '(BLOQUEADA)' ELSE '' END AS REVISAO, "
		_oSQL:_sQuery +=        " dbo.VA_DTOC (G5_DATAREV) AS DATA,"
		_oSQL:_sQuery +=        " rtrim (G5_OBS) AS OBS"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SG5") + " SG5 "
		_oSQL:_sQuery +=  " WHERE SG5.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SG5.G5_FILIAL  = '" + xfilial ("SG5") + "'"
		_oSQL:_sQuery += " AND G5_MSBLQL != '1'"
		// Pelo que sei o sistema nao proibe o uso de rev. inativas --> _oSQL:_sQuery += " AND G5_STATUS != '2'"
		_oSQL:_sQuery +=    " AND SG5.G5_PRODUTO = '" + m->c2_vaCodVD + "'"
		_oSQL:_sQuery += "ORDER BY G5_REVISAO"
		_aRevis := aclone (_oSQL:Qry2Array(.f., .f.))

		if empty (m->c2_vaRevVD) .and. len (_aRevis) > 1
			_sMsg = "O componente tipo VD '" + alltrim (m->c2_vaCodVD) + "' da OP tem revisoes de estrutura. Informe uma delas no campo '" + alltrim (RetTitle ("C2_VAREVVD")) + chr (13) + chr (10) + chr (13) + chr (10)
			for _nRevis = 1 to len (_aRevis)
				_sMsg += _aRevis [_nRevis, 1] + ' ' + _aRevis [_nRevis, 2] + ' ' + _aRevis [_nRevis, 3] + chr (13) + chr (10)
			next
			u_help (_sMsg)
			_lRet = .F.
		endif
	
		if _lRet .and. ascan (_aRevis, {|_aVal| _aVal [1] == m->c2_varevvd}) == 0 .and. len (_aRevis) > 0
			_sMsg = "Revise o campo '" + alltrim (RetTitle ("C2_VAREVVD")) + "' (as revisoes disponiveis para este componente sao as seguintes):" + chr (13) + chr (10) + chr (13) + chr (10)
			for _nRevis = 1 to len (_aRevis)
				_sMsg += _aRevis [_nRevis, 1] + ' ' + _aRevis [_nRevis, 2] + ' ' + _aRevis [_nRevis, 3] + chr (13) + chr (10)
			next
			u_help (_sMsg)
			_lRet = .F.
		endif
	endif

	if _lRet .and. ! empty (m->c2_vaCodVD) .and. ! empty (m->c2_vaRevVD)
		sg5 -> (dbsetorder (1))  // G5_FILIAL+G5_PRODUTO+G5_REVISAO+DTOS(G5_DATAREV)
		if ! sg5 -> (dbseek (xfilial ("SG5") + m->c2_vaCodVD + m->c2_vaRevVD, .F.))
			u_help ("O cadastro da revisao '" + m->c2_vaRevVD + "' do item '" + m->c2_vaCodVD + "' nao foi encontrado." + chr (13) + chr (10) + chr (13) + chr (10) + ;
			        "Obs.: A lista de revisoes para as quais o " + m->c2_vaCodVD + " esta disponivel foi estrutura do produto, mas isso nao significa que os demais dados das revisoes, em si, estejam cadastrados. Verifique na tela 'Revisao Estruturas'")
			_lRet = .F.
		endif
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Verificacoes OP reprocesso.
static function _VerRepr ()
	local _lRet     := .T.
	
	if _lRet .and. m->c2_vaOPEsp != 'R'
		if ! empty (m->c2_vaLtOri)
			u_help ("O campo '" + alltrim (RetTitle ("C2_VALTORI")) + "' so deve ser informado quando para OP de reprocesso.")
			_lRet = .F.
		endif
		if ! empty (m->c2_vaDvOri)
			u_help ("O campo '" + alltrim (RetTitle ("C2_VADVORI")) + "' so deve ser informado quando para OP de reprocesso.")
			_lRet = .F.
		endif
	endif
	if _lRet .and. m->c2_vaOPEsp == 'R'
		if empty (m->c2_vaLtOri) .or. empty (m->c2_vaDFLOr) .or. empty (m->c2_vaDVOri)
			u_help ("Para OP de reprocesso devem ser informados o lote, fabricacao e validade originais.")
			_lRet = .F.
		endif
	endif
return _lRet
//
// --------------------------------------------------------------------------
//// Verificacoes de eventos produtivos
//static function _VerEvent ()
//	local _lRet := .T.
//	local _sCod	:= ""
//	
//	if _lRet .and. empty(m->c2_vaevent)
//		u_help("Código do evento produtivo é obrigatório. Verifique!")
//		_lRet := .F.
//	endif
//	
//	if _lRet
//		_sCod := fbuscacpo("ZBC",1,xfilial("ZBC")+ M->C2_VAEVENT,"ZBC_COD")
//		if empty(_sCod)
//			u_help("Código do evento produtivo não cadastrado. Verifique!")
//			_lRet := .F.
//		endif
//	endif
//return _lRet
