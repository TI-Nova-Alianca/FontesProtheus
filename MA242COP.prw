// Programa:  MA242COP
// Autor:     Robert Koch
// Data:      04/08/2020
// Descricao: Consulta consumos de uma OP (chamado inicialmente pelo P.E. MA242BUT) - GLPI 8259.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #consulta
// #PalavasChave      #consumo_em_op #desmontagem
// #TabelasPrincipais #SD3
// #Modulos           #PCP #EST

// Historico de alteracoes:
// 20/08/2020 - Robert - Permite informar parte do numero da OP, considerando como se fosse um lote de producao
//                     - Desconsidera itens consumidos do tipo BN
//

// --------------------------------------------------------------------------
user function MA242COP ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _oSQL      := NIL
	local _lContinua := .T.
	local _aRetOP    := {}
	local _nOP       := 0
	static _sOP      := space (tamsx3 ("D3_OP")[1])  // Declarada como STATIC para agilizar consultas repetitivas da mesma OP.

	if _lContinua
		_sOP = U_Get ('Informe OP ou lote de producao', 'C', tamsx3 ("D3_OP")[1], '', 'SC2', _sOP, .F., '.t.')
		if len (alltrim (_sOP)) < 8
			u_help ("Informe pelo menos 8 caracteres para representar um lote de producao.",, .t.)
			_lContinua = .F.
		endif
	endif

	// Como eh permitido ao usuario informar um numero de lote, e consideramos 'lote'='inicio do numero da OP', preciso
	// pesquisar as OPs usando LIKE. Alem disso, se encontrar mais de uma OP, preciso que o usuario selecione uma delas.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT C2_NUM + C2_ITEM + C2_SEQUEN + C2_ITEMGRD AS OP, dbo.VA_DTOC (C2_EMISSAO) AS EMISSAO, C2_QUANT AS QUANT_PREVISTA"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SC2") + " SC2 "
		_oSQL:_sQuery += " WHERE SC2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SC2.C2_FILIAL  = '" + xfilial ("SC2") + "'"
		_oSQL:_sQuery +=   " AND C2_NUM + C2_ITEM + C2_SEQUEN + C2_ITEMGRD LIKE '" + alltrim (_sOP) + "%'"
		_oSQL:_sQuery +=   " AND SC2.C2_PRODUTO = '" + cProduto + "'"
		_oSQL:Log ()
		_aRetOP = aclone (_oSQL:Qry2Array ())
		if len (_aRetOP) == 0
			u_help ("Nao foi possivel localizar nenhuma OP com numero / lote '" + alltrim (_sOP) + "' para o produto '" + alltrim (cProduto) + "'.",, .t.)
			_lContinua = .F.
		elseif len (_aRetOP) == 1
			_sOP = _aRetOP [1, 1]
		elseif len (_aRetOP) > 1
			_nOP = _oSQL:F3Array ('Mais de uma OP gerou esse lote. Selecione OP a ser consultada.')
			if _nOP == 0
				_lContinua = .F.
			else
				_sOP = _aRetOP [_nOP, 1]
			endif
		endif
	endif
//				if ! sc2 -> (dbseek (xfilial ("SC2") + _sOP, .F.))
//					u_help ("OP nao encontrada.",, .t.)
//					_lContinua = .F.
//				else
//					if sc2 -> c2_produto != cProduto
//						u_help ("Produto da OP (" + alltrim (sc2 -> c2_produto) + ") deve ser igual ao produto que esta sendo desmontado (" + alltrim (cProduto) + ").",, .t.)
//						_lContinua = .F.
//					endif
//				endif

	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "WITH C AS ("
		_oSQL:_sQuery += "SELECT D3_COD AS COMPONENTE,"
		_oSQL:_sQuery +=       " B1_DESC AS DESCRICAO,"
		_oSQL:_sQuery +=       " D3_TIPO AS TIPO,"
		_oSQL:_sQuery +=       " SUM (D3_QUANT) AS QUANTIDADE,"
		_oSQL:_sQuery +=       " SD3.D3_UM AS UN_MED,"
		_oSQL:_sQuery +=       " SUM (ROUND (D3_CUSTO1, 4)) AS CUSTO"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SD3") + " SD3 "
		_oSQL:_sQuery +=    " JOIN " + RetSQLName ("SB1") + " SB1 "
		_oSQL:_sQuery +=        " ON (SB1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=        " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
		_oSQL:_sQuery +=        " AND SB1.B1_COD     = SD3.D3_COD)"
		_oSQL:_sQuery += " WHERE SD3.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SD3.D3_FILIAL  = '" + xfilial ("SD3") + "'"
		_oSQL:_sQuery +=   " AND SD3.D3_OP      = '" + _sOP + "'"
		_oSQL:_sQuery +=   " AND SD3.D3_TIPO NOT IN ('AP', 'MO', 'GF', 'BN')"
		_oSQL:_sQuery +=   " AND SD3.D3_CF      LIKE 'RE%'"
		_oSQL:_sQuery +=   " AND SD3.D3_ESTORNO != 'S'"
		_oSQL:_sQuery += " GROUP BY SD3.D3_OP, D3_COD, D3_TIPO, B1_DESC, SD3.D3_UM"
		_oSQL:_sQuery += " )"
		_oSQL:_sQuery += " SELECT COMPONENTE, DESCRICAO, TIPO, QUANTIDADE, UN_MED, CUSTO"
		_oSQL:_sQuery += " , ROUND (SUM (CUSTO) OVER (PARTITION BY COMPONENTE) * 100 / SUM (CUSTO) OVER (), 2) AS PERCENT_PARTICIPACAO"
		_oSQL:_sQuery += " FROM C"
		_oSQL:_sQuery += " ORDER BY CUSTO DESC"
		_oSQL:Log ()
		_oSQL:F3Array ('Material consumido na OP ' + _sOP, .T.)
	endif

	U_ML_SRArea (_aAreaAnt)
return
