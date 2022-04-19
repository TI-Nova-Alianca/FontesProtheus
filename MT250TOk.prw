// Programa:   MT250TOk
// Autor:      Robert Koch
// Data:       16/12/2011
// Descricao:  P.E. 'Tudo OK' na tela de apontamento de producao.
//
// Historico de alteracoes:
// 24/05/2012 - Robert - Verifica inexistencia de empenhos.
// 13/08/2014 - Robert - Consiste quantidade da etiqueta, quando informada.
// 17/12/2014 - Robert - Validacoes data apontamento.
//                     - Validacoes integracao com Fullsoft.
// 27/01/2015 - Robert - Passa a validar parametros VA_ALMFULP, VA_ALMFULT, VA_ALMFULT
// 29/01/2015 - Robert - Nao permite apontamento sem etiqueta quando usa Fullsoft.
// 05/08/2015 - Robert - OP sem empenhos nao bloqueia mais, apenas pede confirmacao.
// 07/08/2015 - Robert - Tratamentos para OP de retrabalho.
//                     - Desabilitada verificacao de enderecamento.
// 14/08/2015 - Robert - OPs de retrabalho nao poderao mais ter empenhos.
// 03/09/2015 - Robert - Verifica se produto retrabalhado tem saldo no almox. de reprocesso.
// 25/10/2016 - Robert - Valida d3_emissao < c2_emissao.
// 04/04/2017 - Robert - Impede o uso de 'ganho de producao'.
// 10/04/2017 - Robert - Liberado o uso de 'ganho de producao'.
// 05/05/2017 - Robert - Bloqueado apontamento de OP sem empenhos.
// 09/05/2017 - Robert - Melhorada verificacao de empenhos para casos de OP externa.
// 11/05/2017 - Robert - Verifica local dos empenhos.
// 06/09/2017 - Robert - Pede confirmacao do usuario quando m->d3_emissao != sc2 -> c2_datprf
// 17/11/2017 - Robert - Bloqueada producao a maior e ganho quando produto tipo P.A.
// 04/05/2018 - Robert - Bloqueada movimentacao com data diferente da atual.
// 08/08/2018 - Robert - Exige TM=010 (ver comentario no local).
// 31/05/2019 - Robert - Impede apontamento se tiver empenho do mesmo item da OP.
// 07/06/2019 - Robert - Exige preenchimento dos campos D3_DADTPRD e D3_VATURNO.
// 07/07/2021 - Robert - Validacao do campo D3_VADTPRD passa a aceitar ateh D+4 (GLPI 10430).
// 13/07/2021 - Robert - Eliminadas perguntas simples e melhorados helps para execucao via web service (GLPI 10479)
// 06/12/2021 - Robert - Valida se o empenho jah foi enderecado (para evitar que o sistema requisite de onde quiser). GLPI 11076
// 27/03/2022 - Robert - Verificacao de etiquetas passada para classe ClsEtiq() - GLPI 11825.
// 18/04/2022 - Robert - Incluida chamada para funcao PerfMon().
//

// --------------------------------------------------------------------------
user function mt250tok ()
	local _aAreaAnt := U_ML_SRArea ()
	local _lRet     := .T.
	
	if _lRet .and. (empty (m->d3_vadtprd) .or. m->d3_vadtprd > date () + 4)  // GLPI 10430
		u_help ('Data real de producao nao pode ser vazia nem avancar muitos dias (descontando feriadoes)',, .t.)
		_lRet = .F.
	endif
	if _lRet .and. empty (m->d3_vaturno)
		u_help ('Turno de producao deve ser informado.',, .t.)
		_lRet = .F.
	endif

	// Desabilitado ateh termos definicao final. Robert, 11/04/2017 - 11:50h
	// Impede o uso de 'ganho de producao' por que isso significa magica ('produzimos mais sem gastar material adicional')
	// Boletim informativo em https://webmail.novaalianca.coop.br/service/home/~/?auth=co&loc=pt_BR&id=22109&part=2
	//if _lRet .and. m->d3_qtganho > 0
	//	u_help ("A opcao de 'ganho de producao' nao deve ser usada, pois nao requisita os empenhos proporcionalmente ao total produzido.")
	//	_lRet = .F.
	//endif

	// Ja tive alguns casos de passar com TM=200 mesmo nao existindo esse codigo no cadastro.
	// Talvez seja ateh problema no gatilho da etiqueta, pois a numeracao das mesmas inicia com 200, mas
	// nunca descobri o que ocorre...
	if _lRet .and. m->d3_tm != '010'
		u_help ("Apontamento de producao deveria usar tipo de movimento 010.",, .t.)
		_lRet = .F.
	endif
	
	if _lRet .and. (dDataBase != date () .or. m->d3_emissao != date ())
		_sMsg = "Alteracao de data da movimentacao ou data base do sistema: bloqueada para esta rotina."
		if U_ZZUVL ('084', __cUserId, .F.)
			_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
		else
			u_help (_sMsg,, .t.)
			_lRet = .F.
		endif
	endif
    
	if _lRet .and. (m->d3_qtganho > 0 .or. m->d3_qtmaior > 0) .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + m->d3_cod, "B1_TIPO") == 'PA'  
		u_help ("Para produto acabado nao deve ser produzida quantidade acima do previsto na OP.",, .t.)
		_lRet = .F.
	endif

	if _lRet
		_lRet = _VerData ()
	endif

	// Verifica consistencia com etiquetas, quando usadas.
	if _lRet .and. ! empty (m->d3_vaetiq)
		_lRet = _VerEtiq ()
//		_lRet = U_ZA1PAp (m->d3_vaetiq, m->d3_op, m->d3_cod, m->d3_quant, m->d3_perda, m->d3_parctot)
	endif
	
	// Integracao com Fullsoft
	if _lRet
		_lRet = _VerFull ()
	endif

	// Verifica empenhos.
	if _lRet
		_lRet = _VerEmpenh ()
	endif

	// Verifica OP de retrabalho.
	if _lRet
		_lRet = _VerRetr ()
	endif

	// Deixa registro pronto (a ser 'fechado' pelo P.E. SD3250i) para medicao de tempo de apontamento de producao.
	if _lRet
		U_PerfMon ('I', 'GravacaoMATA250')
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet


// --------------------------------------------------------------------------
// Consiste dados da etiqueta, quando informada.
static function _VerEtiq ()
	local _lRet  := .T.
	local _oEtiq := NIL

	if ! empty (m->d3_vaetiq)
//		za1 -> (dbsetorder (1))  // ZA1_FILIAL+ZA1_CODIGO+ZA1_DATA+ZA1_OP
//		if ! za1 -> (dbseek (xfilial ("ZA1") + m->d3_vaetiq, .F.))
//			u_help ("Etiqueta '" + m->d3_vaetiq + "' nao localizada.",, .t.)
//			_lRet = .F.
//		endif
//		if _lRet .and. (m->d3_quant + m->d3_perda) != za1 -> za1_quant
//			u_help ("Quantidade produzida + perdida nao pode ser diferente da quantidade da etiqueta.",, .t.)
//			_lRet = .F.
//		endif
		if _lRet .and. m->d3_parctot != 'P'
			u_help ("Quando informada etiqueta, a producao deve ser sempre 'Parcial'. Para encerrar a OP use opcao 'Encerrar'.",, .t.)
			_lRet = .F.
		endif
		if _lRet
			_oEtiq := ClsEtiq ():New (m->d3_vaetiq)
			if _lRet .and. m->d3_op != _oEtiq:OP
				u_help ("O.P. informada (" + m->d3_op + ") nao pode ser diferente da O.P. relacionada com a etiqueta (" + _oEtiq:OP + ").",, .t.)
				_lRet = .F.
			endif
			if _lRet .and. m->d3_cod != _oEtiq:Produto
				u_help ("Produto nao pode ser diferente do produto da etiqueta (" + _oEtiq:Produto + ").",, .t.)
				_lRet = .F.
			endif
			if _lRet
				_lRet = _oEtiq:PodeApont (m->d3_quant, m->d3_perda)
			endif
		endif
	endif
return _lRet


// --------------------------------------------------------------------------
// Consiste data do apontamento.
static function _VerData ()
	local _lRet     := .T.
//	local _oSQL     := NIL
//	local _aRetQry  := {}
    
    if _lRet
		if m->d3_emissao > date ()
			u_help ("Data de apontamento nao pode ser maior que a data atual.",, .t.)
			_lRet = .F.
		endif
	endif
	
	if _lRet
		sc2 -> (dbsetorder (1))
		if sc2 -> (dbseek (xfilial ("SC2") + m->d3_op, .F.))
			if _lRet .and. m->d3_emissao < sc2 -> c2_emissao
				u_help ("Data do movimento nao pode ser menor que a data de emissao da OP (" + dtoc (sc2 -> c2_emissao) + ").",, .t.)
				_lRet = .F.
			endif
			if _lRet .and. m->d3_emissao < sc2 -> c2_datpri
				_lRet = U_MsgNoYes ("Data do movimento nao deveria ser menor que a data prevista de inicio da OP (" + dtoc (sc2 -> c2_datpri) + "). Confirma assim mesmo?")
			endif
			if _lRet .and. left (dtos (m->d3_emissao), 6) > left (dtos (sc2 -> c2_datprf), 6)
				u_help ("Data do movimento nao pode estar em mes posterior da data prevista de termino da OP (" + dtoc (sc2 -> c2_datprf) + ").",, .t.)
				_lRet = .F.
			endif
		// Com o apontamento via web service, nao consigo mais colocar perguntas na tela -->	if _lRet .and. m->d3_emissao != sc2 -> c2_datprf
		// Com o apontamento via web service, nao consigo mais colocar perguntas na tela -->		_lRet = U_MsgNoYes ("Apontamento em data diferente da data prevista de termino da OP (" + dtoc (sc2 -> c2_datprf) + "). Confirma assim mesmo?")
		// Com o apontamento via web service, nao consigo mais colocar perguntas na tela -->	endif
		endif
	endif

	// Com o apontamento via web service, nao consigo mais colocar perguntas na tela.
	// if _lRet
	// 	_oSQL := ClsSQL():New ()
	// 	_oSQL:_sQuery += "SELECT MIN (D3_EMISSAO), MAX (D3_EMISSAO) "
	// 	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3 "
	// 	_oSQL:_sQuery += " WHERE SD3.D_E_L_E_T_  = ''"
	// 	_oSQL:_sQuery +=   " AND SD3.D3_FILIAL   = '" + xfilial ("SD3") + "'"
	// 	_oSQL:_sQuery +=   " AND SD3.D3_OP       = '" + M->D3_OP + "'"
	// 	_oSQL:_sQuery +=   " AND SD3.D3_CF      like 'PR%'"
	// 	_oSQL:_sQuery +=   " AND SD3.D3_ESTORNO != 'S'"
	// 	_aRetQry = aclone (_oSQL:Qry2Array ())
	// 	if ! empty (_aRetQry [1,1]) .and. ! empty (_aRetQry [1,2]) .and. _aRetQry [1,1] != _aRetQry [1,2] .and. m->d3_emissao < stod (_aRetQry [1,1]) .and. m->d3_emissao > stod (_aRetQry [1,2])
	// 		_lRet = U_MsgNoYes ("Esta OP ja tem apontamento(s) entre as datas de " + dtoc (stod (_aRetQry [1,1])) + " e " + dtoc (stod (_aRetQry [1,1])) + ". Seria interessante manter a producao no mesmo periodo. Confirma assim mesmo?")
	// 	elseif ! empty (_aRetQry [1,1]) .and. _aRetQry [1,1] == _aRetQry [1,2] .and. m->d3_emissao != stod (_aRetQry [1,1])
	// 		_lRet = U_MsgNoYes ("Esta OP ja tem apontamento(s) em " + dtoc (stod (_aRetQry [1,1])) + ". Seria interessante manter a producao no mesmo periodo. Confirma assim mesmo?")
	// 	endif
	// endif
return _lRet



// --------------------------------------------------------------------------
// Consiste integracao com Fullsoft.
static function _VerFull ()
	local _lRet     := .T.
	local _sAlmFull := GetMv ("VA_ALMFULP",, '')

	if _lRet .and. ! empty (_sAlmFull) .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + m->d3_cod, 'B1_VAFULLW') == 'S'
		if m->d3_local != _sAlmFull
			u_help ("Produto controlado pelo Fullsoft: OP deve ser apontada no almoxarifado de integracao (" + _sAlmFull + ").",, .t.)
			_lRet = .F.
		endif
		if empty (m->d3_vaetiq)
			u_help ("Produto controlado pelo Fullsoft: deve ser informado numero da etiqueta.",, .t.)
			_lRet = .F.
		endif
	endif
return _lRet



// --------------------------------------------------------------------------
// Procura inconsistencias nos empenhos e verifica necessidade de ajusta-los.
static function _VerEmpenh ()
	local _lRet     := .T.
	local _oSQL     := NIL
	local _aRetQry  := {}
	local _nRetQry  := 0
	local _sMsg     := ""
	local _sEmpEnd  := ''

	if _lRet
		sc2 -> (dbsetorder (1))
		if ! sc2 -> (dbseek (xfilial ("SC2") + m->d3_op, .F.))
			u_help ("OP nao encontrada no cadastro!",, .t.)
			_lRet = .F.
		endif
	endif

	if _lRet .and. sc2 -> c2_vaopesp == 'R'  // Reprocesso
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery += "SELECT COUNT (*)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD4") + " SD4 "
		_oSQL:_sQuery += " WHERE SD4.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SD4.D4_FILIAL  = '" + xfilial ("SD4") + "'"
		_oSQL:_sQuery +=   " AND SD4.D4_OP      = '" + M->D3_OP + "'"
		_oSQL:_sQuery +=   " AND SD4.D4_QUANT   > 0"
		if _oSQL:RetQry () > 0
			u_help ("OP de retrabalho nao deve ter empenhos. Os materiais devem ser requisitados manualmente.",, .t.)
			_lRet = .F.
		endif
	endif
	
	if _lRet .and. sc2 -> c2_vaopesp == 'E'  // OP externa
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := " WITH C AS ("
		_oSQL:_sQuery += " SELECT 'SD4' AS ORIGEM, D4_OP AS OP, D4_COD AS PRODUTO"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD4") + " SD4 "
		_oSQL:_sQuery += " WHERE SD4.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SD4.D4_FILIAL  = '" + xfilial ("SD4") + "'"
		_oSQL:_sQuery +=   " AND SD4.D4_OP      = '" + M->D3_OP + "'"
		_oSQL:_sQuery +=   " AND SD4.D4_QUANT   > 0"
		_oSQL:_sQuery += " UNION ALL"
		_oSQL:_sQuery += " SELECT 'SD1' AS ORIGEM, D1_OP AS OP, D1_COD AS PRODUTO
		_oSQL:_sQuery +=   " FROM " + RetSqlName ("SD1") + " SD1,"
		_oSQL:_sQuery +=              RetSqlName ("SF4") + " SF4"
 		_oSQL:_sQuery +=  " WHERE SF4.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SF4.F4_FILIAL  = '" + xfilial ("SF4") + "'"
		_oSQL:_sQuery +=    " AND SF4.F4_CODIGO  = SD1.D1_TES"
		_oSQL:_sQuery +=    " AND SF4.F4_ESTOQUE = 'S'"
		_oSQL:_sQuery +=    " AND SD1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SD1.D1_FILIAL  = '" + xFilial ("SD1") + "'"
		_oSQL:_sQuery +=    " AND SD1.D1_OP      = '" + M->D3_OP + "'"
		_oSQL:_sQuery += ")"
		_oSQL:_sQuery += " SELECT PRODUTO, COUNT (DISTINCT ORIGEM)"
		_oSQL:_sQuery += " FROM C"
		_oSQL:_sQuery += " GROUP BY PRODUTO"
		_oSQL:_sQuery += " HAVING COUNT (DISTINCT ORIGEM) > 1"
		if ! empty (_oSQL:Qry2Str (1, ', '))
			u_help ("OP do tipo externa: O(s) seguinte(s) materiais constam nos empenhos da OP, mas ja tiveram requisicao via NF. Elimine os empenhos ou exclua a NF: " + _oSQL:_xRetQry, _oSQL:_sQuery, .t.)
			_lRet = .F.
		endif
	endif

	if _lRet .and. ! sc2 -> c2_vaopesp $ 'E/R'
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery += "SELECT COUNT (*)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD4") + " SD4 "
		_oSQL:_sQuery += " WHERE SD4.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SD4.D4_FILIAL  = '" + xfilial ("SD4") + "'"
		_oSQL:_sQuery +=   " AND SD4.D4_OP      = '" + M->D3_OP + "'"
		_oSQL:_sQuery +=   " AND SD4.D4_QUANT   > 0"
		if _oSQL:RetQry () == 0
			u_Help ("Esta OP nao tem empenhos, ou ja foram zerados.",, .t.)
			_lRet = .F.
		endif
	endif

	// Verifica local (almox) dos empenhos.
	if _lRet
		_sMsg = ''
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery += "SELECT D4_COD, D4_LOCAL, dbo.VA_FLOC_EMP_OP ('" + cFilAnt + "', D4_COD) AS LOCEMP"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD4") + " SD4 "
		_oSQL:_sQuery += " WHERE SD4.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SD4.D4_FILIAL  = '" + xfilial ("SD4") + "'"
		_oSQL:_sQuery +=   " AND SD4.D4_OP      = '" + M->D3_OP + "'"
		_oSQL:_sQuery +=   " AND SD4.D4_QUANT   > 0"
		_aRetQry := aclone (_oSQL:Qry2Array (.F., .F.))
		for _nRetQry = 1 to len (_aRetQry)
			if _aRetQry [_nRetQry, 2] != _aRetQry [_nRetQry, 3]
				_sMsg += "Item " + alltrim (_aRetQry [_nRetQry, 1]) + ' - ' + alltrim (fBuscaCpo ("SB1", 1, xfilial ("SB1") + _aRetQry [_nRetQry, 1], "B1_DESC")) + " empenhado indevidamente no almox. '" + _aRetQry [_nRetQry, 2] + "' (alm.correto: " + _aRetQry [_nRetQry, 3] + ")." + chr (13) + chr (10)
			endif
		next
		if ! empty (_sMsg)
			_lRet = u_msgnoyes (_sMsg + chr (13) + chr (10) + "Confirma assim mesmo?")
		endif
	endif

	// Verifica se pode gerar recursividade
	if _lRet
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery += "SELECT COUNT (*)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD4") + " SD4 "
		_oSQL:_sQuery += " WHERE SD4.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SD4.D4_FILIAL  = '" + xfilial ("SD4") + "'"
		_oSQL:_sQuery +=   " AND SD4.D4_OP      = '" + M->D3_OP + "'"
		_oSQL:_sQuery +=   " AND SD4.D4_QUANT   > 0"
		_oSQL:_sQuery +=   " AND SD4.D4_COD     = '" + fBuscaCpo ("SC2", 1, xfilial ("SC2") + m->d3_op, "C2_PRODUTO") + "'"
		if _oSQL:RetQry () > 0
			u_Help ("Encontrei empenho do item '" + fBuscaCpo ("SC2", 1, xfilial ("SC2") + m->d3_op, "C2_PRODUTO") + "' (mesmo item a ser produzido pela OP). Remova esse empenho antes de apontar a OP para evitar recursividade.",, .t.)
			_lRet = .F.
		endif
	endif

	if _lRet
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery += "SELECT STRING_AGG (RTRIM (D4_COD), ', ')"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD4") + " SD4 "
		_oSQL:_sQuery += " WHERE SD4.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SD4.D4_FILIAL  = '" + xfilial ("SD4") + "'"
		_oSQL:_sQuery +=   " AND SD4.D4_OP      = '" + M->D3_OP + "'"
		_oSQL:_sQuery +=   " AND SD4.D4_QUANT   > 0"
		_oSQL:_sQuery +=   " AND EXISTS (SELECT *"
		_oSQL:_sQuery +=         " FROM " + RetSQLName ("SB1") + " SB1 "
		_oSQL:_sQuery +=        " WHERE SB1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=          " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
		_oSQL:_sQuery +=          " AND SB1.B1_COD     = SD4.D4_COD"
		_oSQL:_sQuery +=          " AND SB1.B1_LOCALIZ = 'S'"
		_oSQL:_sQuery +=          " AND ISNULL ((SELECT SUM (DC_QTDORIG)"
		_oSQL:_sQuery +=                         " FROM " + RetSQLName ("SDC") + " SDC "
		_oSQL:_sQuery +=                        " WHERE SDC.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                          " AND SDC.DC_FILIAL  = SD4.D4_FILIAL"
		_oSQL:_sQuery +=                          " AND SDC.DC_PRODUTO = SD4.D4_COD"
		_oSQL:_sQuery +=                          " AND SDC.DC_OP      = SD4.D4_OP), 0) < SD4.D4_QTDEORI)"
		_oSQL:Log ()
		_sEmpEnd := alltrim (_oSQL:RetQry ())
		if ! empty (_sEmpEnd)
			u_Help ("O(s) seguinte(s) item(s) controlam enderecamento: " + _sEmpEnd + ". Ainda nao foi definido o endereco desse(s) item(s) nos empenhos da OP '" + alltrim (m->d3_op) + "'. Apontamento nao permitido.",, .t.)
			_lRet = .F.
		endif
	endif
return _lRet



// --------------------------------------------------------------------------
// Verifica OP de retrabalho / reprocesso.
static function _VerRetr ()
	local _lRet      := .T.
	local _lEhReproc := .F.
	local _sAlmRetr  := GetMv ("VA_ALMREPR")
	local _nSalDisp  := 0

//	u_logIni ()
	if _lRet
		_lEhReproc = (fBuscaCpo ("SC2", 1, xfilial ("SC2") + m->d3_op, "C2_VAOPESP") == 'R')
	endif
	if _lRet .and. _lEhReproc
		if _lRet .and. m->d3_quant > 0
			u_help ("OP de retrabalho / reprocesso: a quantidade deve ser informada como 'perda'.",, .t.)
			_lRet = .F.
		endif
	endif
	
	if _lRet .and. _lEhReproc
		sb2 -> (dbsetorder (1))  // B2_FILIAL+B2_COD+B2_LOCAL
		if ! sb2 -> (dbseek (xfilial ("SB2") + m->d3_cod + _sAlmRetr, .F.))
			u_help ("O produto retrabalhado (" + alltrim (m->d3_cod) + ") deve estar disponivel no almoxarifado '" + _sAlmRetr + "', pois o apontamento de uma OP de retrabalho precisa gerar transferencia para o almoxarifado de integracao com o FullWMS, e neste caso nao ha de onde fazer essa transferencia.",, .t.)
			_lRet = .F.
		else
			_nSalDisp = sb2 -> b2_qatu - sb2 -> b2_reserva - sb2 -> b2_qaclass
			if m->d3_perda > _nSalDisp
				u_help ("Saldo disponivel (" + cvaltochar (_nSalDisp) + ") do produto '" + alltrim (m->d3_cod) + "' no almoxarifado '" + _sAlmRetr + "' deve ser no minimo " + cvaltochar (m->d3_perda) + ", pois essa quantidade precisa ser transferida para o almoxarifado de integracao com FullWMS para entrada na expedicao.",, .t.)
				_lRet = .F.
			endif
		endif
	endif
//	u_logFim ()
return _lRet
