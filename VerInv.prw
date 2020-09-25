// Programa:  Verinv
// Autor:     Robert Koch
// Data:      06/07/2015
// Descricao: Verificacoes diversas para inventario de estoques.
//
// Historico de alteracoes:
// 28/09/2015 - Robert - Criada verificacao de empenho com OP encerrada.
//

// --------------------------------------------------------------------------
User Function VerInv (_nQual)
	local _lContinua := .T.
	local _aRet      := {}
	local _sQuery    := ""
	local _aRetSQL   := {}
	local _aVerif    := {}
	local _aCols     := {}
	local _oSQL      := NIL
	local _nVerif	 := 0
	private _sArqLog := iif (type ("_sArqLog") == "C", _sArqLog, U_NomeLog ())

	_nQual     := iif (_nQual == NIL, 0, _nQual)

	_sProblema = 'O.P. em aberto'
	_sQuery := "SELECT '" + _sProblema + "' AS PROBLEMA,"
	_sQuery +=       " SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN + SC2.C2_ITEMGRD AS OP,"
	_sQuery +=       " SC2.C2_PRODUTO AS PRODUTO, SB1.B1_TIPO AS TIPO, SB1.B1_DESC AS DESCRICAO,"
	_sQuery +=       " dbo.VA_DTOC (SC2.C2_EMISSAO) AS EMISSAO, dbo.VA_DTOC (SC2.C2_DATPRF) AS DT_PREVISTA,"
	_sQuery +=       " SC2.C2_QUANT AS QT_PREVISTA, SC2.C2_QUJE AS QT_PRODUZIDA, SC2.C2_LOCAL AS ALMOX, SC2.C2_VAUSER AS USUARIO"
	_sQuery +=  " FROM " + RETSQLNAME ("SC2") + " SC2, "
	_sQuery +=             RETSQLNAME ("SB1") + " SB1 "
	_sQuery += " WHERE SC2.D_E_L_E_T_ = ''"
	_sQuery +=   " AND SC2.C2_FILIAL  = '" + xfilial ("SC2") + "'"
	_sQuery +=   " AND SC2.C2_TPOP != 'P'"
	_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
	_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_sQuery +=   " AND SB1.B1_COD = SC2.C2_PRODUTO"
	_sQuery +=   " AND SC2.C2_QUJE != 0"
	_sQuery +=   " AND SC2.C2_DATRF = ''"
	_sQuery += " ORDER BY C2_NUM, C2_ITEM, C2_SEQUEN, C2_ITEMGRD"
	aadd (_aVerif, {.F., "01 - " + _sProblema, _sQuery, .T.})


	_sProblema = 'Movimentacao com data futura'
	_sQuery := "SELECT '" + _sProblema + "' AS PROBLEMA,"
	_sQuery +=        " ORIGEM, EMISSAO, DOC, OP "
	_sQuery +=   " FROM (SELECT 'SD3' AS ORIGEM, D3_EMISSAO AS EMISSAO, D3_DOC AS DOC, D3_OP AS OP"
	_sQuery +=           " FROM " + RetSQLName ("SD3")
	_sQuery +=          " WHERE D_E_L_E_T_ = ''"
	_sQuery +=            " AND D3_FILIAL = '" + xfilial ("SD3") + "'"
	_sQuery +=            " AND D3_EMISSAO > '" + dtos (date ()) + "'"
	_sQuery +=            " AND D3_ESTORNO != 'S'"
	_sQuery +=          " UNION ALL"
	_sQuery +=         " SELECT 'SD2', D2_EMISSAO, D2_DOC, ''"
	_sQuery +=           " FROM " + RetSQLName ("SD2")
	_sQuery +=          " WHERE D_E_L_E_T_ = ''"
	_sQuery +=            " AND D2_FILIAL = '" + xfilial ("SD2") + "'"
	_sQuery +=            " AND D2_EMISSAO > '" + dtos (date ()) + "'"
	_sQuery +=          " UNION ALL"
	_sQuery +=         " SELECT 'SD1', D1_DTDIGIT, D1_DOC, ''"
	_sQuery +=           " FROM " + RetSQLName ("SD1")
	_sQuery +=          " WHERE D_E_L_E_T_ = ''"
	_sQuery +=            " AND D1_FILIAL = '" + xfilial ("SD1") + "'"
	_sQuery +=            " AND D1_DTDIGIT > '" + dtos (date ()) + "'"
	_sQuery +=          " ) AS TODOS"
	aadd (_aVerif, {.F., "02 - " + _sProblema, _sQuery, .T.})


	_sProblema = 'Empenho com saldo para OP encerrada'
	_sQuery := "SELECT '" + _sProblema + "' AS PROBLEMA,"
	_sQuery +=       " D4_OP AS OP, D4_COD AS PRODUTO, D4_LOCAL AS ALMOX, D4_QUANT AS QT_EMPENHO"
	_sQuery +=  " FROM " + RETSQLNAME ("SD4") + " SD4 "
	_sQuery += " WHERE SD4.D_E_L_E_T_ = ''"
	_sQuery +=   " AND SD4.D4_FILIAL  = '" + xfilial ("SD4") + "'"
	_sQuery +=   " AND SD4.D4_QUANT   > 0"
	_sQuery +=   " AND NOT EXISTS (SELECT *"
	_sQuery +=                     " FROM " + RETSQLNAME ("SC2") + " SC2 "
	_sQuery +=                    " WHERE SC2.D_E_L_E_T_ = ''"
	_sQuery +=                      " AND SC2.C2_FILIAL  = SD4.D4_FILIAL"
	_sQuery +=                      " AND SC2.C2_DATRF   = ''"
	_sQuery +=                      " AND SC2.C2_NUM + C2_ITEM + C2_SEQUEN + C2_ITEMGRD = D4_OP)"
	_sQuery += " ORDER BY D4_OP, D4_COD"
	aadd (_aVerif, {.F., "03 - " + _sProblema, _sQuery, .T.})


/* aINDA NAO LIBERADA POR QUE PRECISA CONTEMPLAR:
- NOTAS TIPO B/D DEVE OLGAR SA2 E NAO SA1
- NOTAS QUE NEM FOI DADO ENTRADA NA FILIAL DESTINO, FAZENDO DEVOLUCAO DIRETO NA FILIAL ORIGEM (SEMELHANTE A UM NAO ACEITE DE CLIENTE) EX.: NOTA 9283 DA F.10 PARA 01
	_sProblema = 'NF transf.de filiais nao classificada'
	_sQuery := "SELECT '" + _sProblema + "' AS PROBLEMA,"
	_sQuery +=        " D2_FILIAL AS FILIAL_ORIG, D2_DOC AS NF, D2_COD AS PRODUTO, B1_DESC AS DESCRICAO, D2_QUANT AS QUANT, D2_UM AS UM, dbo.VA_DTOC (D2_EMISSAO) AS EMISSAO"
	_sQuery += " from " + RetSQLName ("SD2") + " SD2, "
	_sQuery +=            RetSQLName ("SF4") + " SF4, "
	_sQuery +=            RetSQLName ("SB1") + " SB1, "
	_sQuery +=            RetSQLName ("SA1") + " SA1, "
	_sQuery +=        " VA_SM0 SM0"
	_sQuery += " where SD2.D_E_L_E_T_ != '*'"
	_sQuery += "   and SD2.D2_EMISSAO >= '" + dtos (date () - 60) + "'"  // Nota com mais de 60 dias jah seria demais...
	_sQuery += "   and SA1.D_E_L_E_T_ != '*'"
	_sQuery += "   and SA1.A1_FILIAL   = '" + xfilial ("SA1") + "'"
	_sQuery += "   and SA1.A1_COD      = SD2.D2_CLIENTE"
	_sQuery += "   and SA1.A1_LOJA     = SD2.D2_LOJA"
	_sQuery += "   and SA1.A1_CGC      = '" + sm0 -> m0_cgc + "'"
	_sQuery += "   and SF4.D_E_L_E_T_ != '*'"
	_sQuery += "   and SF4.F4_FILIAL   = '" + xfilial ("SF4") + "'"
	_sQuery += "   and SF4.F4_CODIGO   = SD2.D2_TES"
	_sQuery += "   and SF4.F4_ESTOQUE  = 'S'"
	_sQuery += "   and SB1.D_E_L_E_T_ != '*'"
	_sQuery += "   and SB1.B1_FILIAL   = '" + xfilial ("SB1") + "'"
	_sQuery += "   and SB1.B1_COD      = SD2.D2_COD"
	_sQuery += "   and SM0.D_E_L_E_T_ != '*'"
	_sQuery += "   and SM0.M0_CODFIL   = SD2.D2_FILIAL"
	_sQuery += "   and SM0.M0_CODIGO   = '" + cEmpAnt + "'"
	_sQuery += "   and NOT EXISTS (SELECT *"
	_sQuery +=                     " from " + RetSQLName ("SF1") + " SF1, "
	_sQuery +=                              + RetSQLName ("SA2") + " SA2, "
	_sQuery +=                            " VA_SM0 SM0_D "
	_sQuery +=                    " where SF1.D_E_L_E_T_ = ''"
	_sQuery +=                      " and SF1.F1_FILIAL  = '" + xfilial ("SF1") + "'"
	_sQuery +=                      " and SF1.F1_DOC     = SD2.D2_DOC"
	_sQuery +=                      " and SF1.F1_SERIE   = SD2.D2_SERIE"
	_sQuery +=                      " and SF1.F1_FORNECE = SA2.A2_COD"
	_sQuery +=                      " and SF1.F1_LOJA    = SA2.A2_LOJA"
	_sQuery +=                      " and SA2.D_E_L_E_T_ = ''"
	_sQuery +=                      " and SA2.A2_COD     = SF1.F1_FORNECE"
	_sQuery +=                      " and SA2.A2_LOJA    = SF1.F1_LOJA"
	_sQuery +=                      " and SA2.A2_CGC     = SM0.M0_CGC"
	_sQuery +=                      " and SM0_D.D_E_L_E_T_ = ''"
	_sQuery +=                      " and SM0_D.M0_CODIGO  = SM0.M0_CODIGO"
	_sQuery +=                      " and SM0_D.M0_CODFIL  = SM0.M0_CODFIL)"
	aadd (_aVerif, {.F., "03 - " + _sProblema, _sQuery, .T.})
*/
	u_log (_aVerif)

	// Sem interface (outra rotina solicitando dados)
	if _lContinua
		if _nQual != 0
			_sQuery = _aVerif [_nQual, 3]
			u_log (_squery)
			_aRetSQL := U_Qry2Array (_sQuery)
			if len (_aRetSQL) > 0
				u_log (_aRetSQL)
				_aRet = _aRetSQL
			endif
	
		// Com interface com o usuario
		else
			do while .T.
				_aCols = {}
				aadd (_aCols, {2, "Tipo de verificacao", 100, ""})
				U_MBArray (@_aVerif, "Selecione verificacoes a fazer", _aCols, 1)
				for _nVerif = 1 to len (_aVerif)
					if _aVerif [_nVerif, 1]
						CursorWait ()
						_aRetSQL := U_Qry2Array (_aVerif [_nVerif, 3], .F., .T.)
						CursorArrow ()
						if len (_aRetSQL) <= 1  // Primeira linha tem os nomes de campos
							u_help ("Nao foram encontradas pendencias do tipo " + _aVerif [_nVerif, 2])
						else
							u_showarray (_aRetSQL, "Pendencias do tipo " + _aVerif [_nVerif, 2])
						endif
					endif
					_aVerif [_nVerif, 1] = .F.
				next
				if ! msgyesno ("Deseja fazer nova consulta?")
					exit
				endif
			enddo
		endif
	endif
	u_logFim ()
return _aRet
