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
// 04/05/2022 - Robert - Desabilitada verificacao local dos empenhos (sem utilidade) - GLPI 11994
// 05/08/2022 - Robert - Bloqueia empenhos negativos (GLPI 12441)
// 08/08/2022 - Robert - Verifica inconsistencia de estoue nos itens empenhados (GLPI 11994)
// 13/10/2022 - Robert - Novos parametros funcao U_ConsEst. Liberacao para grupo 155.
// 25/10/2022 - Robert - Quando tem empenho negativo nao bloqueia mais. Apenas notifica o PCP.
// 05/01/2023 - Robert - Abreviadas algumas mensagens, para mostrar via telnet.
// 17/04/2023 - Robert - Mostrar ultima mensagem da etiqueta, quando nao puder apontar.
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
		_sMsg = "Troca de data bloqueada nesta rotina."
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

	if _lRet .and. m->d3_local != sc2 -> c2_local
		u_help ("Apontamento deve ser feito no almox.indicado na OP (" + sc2 -> c2_local + ").",, .t.)
		_lRet = .F.
	endif

	// Verifica consistencia com etiquetas, quando usadas.
	if _lRet .and. ! empty (m->d3_vaetiq)
		_lRet = _VerEtiq ()
	endif
	
//	// Integracao com Fullsoft
//	if _lRet
//		_lRet = _VerFull ()
//	endif
	if _lRet .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + m->d3_cod, 'B1_VAFULLW') == 'S' .and. empty (m->d3_vaetiq)
		u_help ("Produto controlado pelo Fullsoft: deve ser informado numero da etiqueta.",, .t.)
		_lRet = .F.
	endif

	// Verifica empenhos.
	if _lRet
		_lRet = _VerEmpenh ()
	endif

	// Verifica OP de retrabalho.
	if _lRet
		_lRet = _VerRetr ()
	endif


//	U_Log2 ('debug', '[' + procname () + ']retornando F para testes')
//	_lret = .f.

	U_ML_SRArea (_aAreaAnt)
return _lRet


// --------------------------------------------------------------------------
// Consiste dados da etiqueta, quando informada.
static function _VerEtiq ()
	local _lRet  := .T.
	local _oEtiq := NIL

	if ! empty (m->d3_vaetiq)
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
				if ! _lRet
					u_help (_oEtiq:UltMsg)
				endif
			endif
		endif
	endif
return _lRet


// --------------------------------------------------------------------------
// Consiste data do apontamento.
static function _VerData ()
	local _lRet     := .T.
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
				u_help ("Apontamento nao pode ser anterior a data de emissao da OP (" + dtoc (sc2 -> c2_emissao) + ").",, .t.)
				_lRet = .F.
			endif
			if _lRet .and. m->d3_emissao < sc2 -> c2_datpri
				_lRet = U_MsgNoYes ("Apontamento nao deveria ser menor que a data prevista de inicio da OP (" + dtoc (sc2 -> c2_datpri) + "). Confirma assim mesmo?")
			endif
			if _lRet .and. left (dtos (m->d3_emissao), 6) > left (dtos (sc2 -> c2_datprf), 6)
				u_help ("Apontamento nao pode estar em mes posterior da data prevista de termino da OP (" + dtoc (sc2 -> c2_datprf) + ").",, .t.)
				_lRet = .F.
			endif
		endif
	endif
return _lRet



/*
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
*/


// --------------------------------------------------------------------------
// Procura inconsistencias nos empenhos e verifica necessidade de ajusta-los.
static function _VerEmpenh ()
	local _lRet     := .T.
	local _oSQL     := NIL
	local _sEmpEnd  := ''
	local _sEmpNeg  := ''
	local _sMsgEmp  := ''
	local _oAviso   := NIL

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

	// Verifica se foi definida localizacao dos empenhos.
	if _lRet
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery += "SELECT ISNULL (STRING_AGG (RTRIM (D4_COD), ', '), '')"
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
		//_oSQL:Log ('[' + procname () + ']')
		_sEmpEnd := alltrim (_oSQL:RetQry ())
		if ! empty (_sEmpEnd)
			u_Help ("Falta informar endereco dos empenhos (" + _sEmpEnd + ")",, .t.)
			_lRet = .F.
		endif
	endif

	// Verifica se tem empenhos negativos (nao eh nosso procedimento normal,
	// pois gera devolucao de saldo para o estoque) - GLPI 12441
	if _lRet
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery += "SELECT ISNULL (STRING_AGG (RTRIM (D4_COD), ', '), '')"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD4") + " SD4 "
		_oSQL:_sQuery += " WHERE SD4.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SD4.D4_FILIAL  = '" + xfilial ("SD4") + "'"
		_oSQL:_sQuery +=   " AND SD4.D4_OP      = '" + M->D3_OP + "'"
		_oSQL:_sQuery +=   " AND SD4.D4_QUANT   < 0"
		//_oSQL:Log ('[' + procname () + ']')
		_sEmpNeg := alltrim (_oSQL:RetQry ())
		if ! empty (_sEmpNeg)
			u_Help ("Apenas um aviso: OP tem empenhos negativos!")
			_sMsgEmp := "A OP " + alltrim (m->d3_op)
			_sMsgEmp += " (finalidade " + alltrim (X3Combo ("C2_VAOPESP", sc2 -> c2_vaOpEsp)) + ")"
			_sMsgEmp += " contem empenho negativo dos seguintes itens: " + _sEmpNeg
			_sMsgEmp += ". Se essa for mesmo a intencao, apenas desconsidere esta mensagem."
			U_Log2 ('aviso', '[' + procname () + ']' + _sMsgEmp)

			// Como ha casos de reprocesso em que amgumas embalagens realmente
			// voltam para o estoque, optei por apenas notificar. Robert, 25/10/22
			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'A'
			_oAviso:DestinZZU  = {'047'}  // 047 = Grupo do PCP
			_oAviso:Titulo     = _sMsgEmp
			_oAviso:Texto      = "Verificado durante o apontamento"
			if ! empty (m->d3_vaetiq)
				_oAviso:Texto += " da etiqueta " + m->d3_vaetiq
			endif
			_oAviso:Texto     += " que " + _sMsgEmp
			_oAviso:Formato    = 'T'
			_oAviso:Origem     = procname () + ' - ' + procname (1)
			_oAviso:Grava ()

		endif
	endif


	// Verifica se tem alguma mensagem de inconsistencia entre tabelas de estoque.
	if _lRet
		sd4 -> (dbsetorder (2))  // D4_FILIAL, D4_OP, D4_COD, D4_LOCAL, R_E_C_N_O_, D_E_L_E_T_
		sd4 -> (dbseek (xfilial ("SD4") + m->d3_op, .F.))
		do while ! sd4 -> (eof ()) .and. sd4 -> d4_filial == xfilial ("SD4") .and. sd4 -> d4_op == m->d3_op
			if ! U_ConsEstq (sd4 -> d4_filial, sd4 -> d4_cod, sd4 -> d4_local, '155')
				_lRet = .F.
			endif
			sd4 -> (dbskip ())
		enddo
	endif
	//U_Log2 ('info', 'Finalizando ' + procname ())
return _lRet



// --------------------------------------------------------------------------
// Verifica OP de retrabalho / reprocesso.
static function _VerRetr ()
	local _lRet      := .T.
	local _lEhReproc := .F.
	local _sAlmRetr  := GetMv ("VA_ALMREPR")
	local _nSalDisp  := 0

	if _lRet
		_lEhReproc = (fBuscaCpo ("SC2", 1, xfilial ("SC2") + m->d3_op, "C2_VAOPESP") == 'R')
	endif
	if _lRet .and. _lEhReproc
		if _lRet .and. m->d3_quant > 0
			u_help ("OP retrab/reproc: qt.deve ser informada como PERDA.",, .t.)
			_lRet = .F.
		endif
	endif
	
	if _lRet .and. _lEhReproc
		sb2 -> (dbsetorder (1))  // B2_FILIAL+B2_COD+B2_LOCAL
		if ! sb2 -> (dbseek (xfilial ("SB2") + m->d3_cod + _sAlmRetr, .F.))
			u_help ("Item retrabalhado (" + alltrim (m->d3_cod) + ") deve estar disponivel no almoxarifado '" + _sAlmRetr + "', pois o apontamento de uma OP de retrabalho precisa gerar transferencia para o almoxarifado de integracao com o FullWMS, e neste caso nao ha de onde fazer essa transferencia.",, .t.)
			_lRet = .F.
		else
			_nSalDisp = sb2 -> b2_qatu - sb2 -> b2_reserva - sb2 -> b2_qaclass
			if m->d3_perda > _nSalDisp
				u_help ("Sld.disp.(" + cvaltochar (_nSalDisp) + ") do prod." + alltrim (m->d3_cod) + " no ax " + _sAlmRetr + " deve ser no minimo " + cvaltochar (m->d3_perda) + ", pois essa quantidade precisa ser transferida para o almoxarifado de integracao com FullWMS para entrada na expedicao.",, .t.)
				_lRet = .F.
			endif
		endif
	endif
return _lRet
