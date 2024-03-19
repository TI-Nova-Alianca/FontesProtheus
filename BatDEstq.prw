// Programa:   BatDEstq
// Autor:      Robert Koch
// Data:       25/11/2011
// Descricao:  Envia e-mail com disponibilidades de estoques (inicialmente a granel).
//             Criado para ser executado via batch.
// 
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Envia e-mail com disponibilidades de estoques (inicialmente a granel).
// #PalavasChave      #saldos #estoques #e-mail
// #TabelasPrincipais #SB1 #VA_FDISPONESTQ #SM0
// #Modulos           #EST
//
// Historico de alteracoes:
// 26/11/2011 - Robert - Passa a listar 'abertas' as colunas de empenhos.
// 07/10/2015 - Catia  - Tirado email do Flavio conforme solicitação dele chamado 1772 - GLPI
// 06/11/2015 - Robert - Funcao VA_DISPONESTQ do SQL renomeada para VA_FDISPONESTQ.
// 14/08/2018 - Robert - Desabilitada leitura das filiais 04/05/06/12/14.
// 08/07/2020 - Robert - Habilitada Sandra como destinataria para conferencias.
// 31/07/2023 - Robert - Incluido Heleno Facchin como destinatario.
// 18/11/2023 - Robert - Desabilitado envio para Rodrigo Colleoni.
// 18/03/2023 - Robert - Desabilitado envio para Jocemar Dalcorno.
//

// --------------------------------------------------------------------------
user function BatDEstq ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _sMsg      := ""
	local _sQuery    := ""
	local _aRetQry   := {}
	local _aTotFil   := {}
	local _aTotAcond := {}
	local _nLinha    := 0
	local _nLinAux   := 0
	local _sDestin   := ""
//	local _sArqLog2  := iif (type ("_sArqLog") == "C", _sArqLog, "")
//	_sArqLog := U_NomeLog (.t., .f.)
//	u_logIni ()
//	u_log ("Iniciando as", time ())

	// Busca dados por filial e por acondicionamento em uma mesma query devido
	// a ser muito demorada. Depois faz os acumulados usando arrays.
	_sQuery := " SELECT SALDOS.FILIAL + '-' + RTRIM(SM0.M0_FILIAL) AS FILIAL,"
	_sQuery +=        " ACONDICIONAMENTO, 
	_sQuery +=        " SUM (QUANT)               AS QUANT,"
	_sQuery +=        " SUM (SALDOS.EMP_ENTR_FUT) AS EMP_ENTR_FUT,"
	_sQuery +=        " SUM (SALDOS.EMP_PD_VENDA) AS EMP_PD_VENDA,"
	_sQuery +=        " SUM (EMP_OP)              AS EMP_OP,"
	_sQuery +=        " SUM (RESERVAS)            AS RESERVAS,"
	_sQuery +=        " SUM (SALDOS.QUANT"
	_sQuery +=           " - SALDOS.EMP_ENTR_FUT"
	_sQuery +=           " - SALDOS.EMP_PD_VENDA"
	_sQuery +=           " - EMP_OP"
	_sQuery +=           " - RESERVAS) AS DISPONIVEL,"
	_sQuery +=        " SUM (DE_TERC) AS DE_TERC,"
	_sQuery +=        " SUM (EM_TERC) AS EM_TERC"
	_sQuery += " FROM " + RetSQLName ("SB1") + " SB1, "
	_sQuery +=        " dbo.VA_FDISPONESTQ ('', 'zz', '', 'zzzzzzzzzzzzzz', '', 'zz', 'PA', 'VD', 'LT') AS SALDOS"
	_sQuery +=        " LEFT JOIN VA_SM0 SM0"
	_sQuery +=             " ON (SM0.D_E_L_E_T_ = ''"
	_sQuery +=             " AND SM0.M0_CODIGO = '" + cEmpAnt + "'"
	_sQuery +=             " AND NOT (SM0.M0_CODIGO = '01' AND SM0.M0_CODFIL = '04')"  // Filial desativada
	_sQuery +=             " AND NOT (SM0.M0_CODIGO = '01' AND SM0.M0_CODFIL = '05')"  // Filial desativada
	_sQuery +=             " AND NOT (SM0.M0_CODIGO = '01' AND SM0.M0_CODFIL = '06')"  // Filial desativada
	_sQuery +=             " AND NOT (SM0.M0_CODIGO = '01' AND SM0.M0_CODFIL = '12')"  // Filial desativada
	_sQuery +=             " AND NOT (SM0.M0_CODIGO = '01' AND SM0.M0_CODFIL = '14')"  // Filial desativada
	_sQuery +=             " AND SM0.M0_CODFIL = SALDOS.FILIAL)"
	_sQuery += " WHERE SALDOS.FILIAL  != '02'"  // Filial inativa que ficou com algumas sujeiras.
	_sQuery +=   " AND SB1.D_E_L_E_T_  = ''"
	_sQuery +=   " AND SB1.B1_TIPO    IN ('PA', 'PI', 'VD')"
	_sQuery +=   " AND SB1.B1_COD      = SALDOS.PRODUTO"
	_sQuery += " GROUP BY SALDOS.FILIAL + '-' + RTRIM(SM0.M0_FILIAL), ACONDICIONAMENTO"
	u_log (_squery)
	_aRetQry = U_Qry2Array (_sQuery)

	if len (_aRetQry) > 0

		// Monta uma nova array, totalizando-a por filial.
		_aTotFil = {}
		for _nLinha = 1 to len (_aRetQry)
			_nLinAux = ascan (_aTotFil, {|_aVal| _aVal [1] == _aRetQry [_nLinha, 1]})
			if _nLinAux == 0
				aadd (_aTotFil, {_aRetQry [_nLinha, 1], 0,0,0,0,0,0})
				_nLinAux = len (_aTotFil)
			endif
			_aTotFil [_nLinAux, 2] += _aRetQry [_nLinha, 3]
			_aTotFil [_nLinAux, 3] += _aRetQry [_nLinha, 4]
			_aTotFil [_nLinAux, 4] += _aRetQry [_nLinha, 5]
			_aTotFil [_nLinAux, 5] += _aRetQry [_nLinha, 6]
			_aTotFil [_nLinAux, 6] += _aRetQry [_nLinha, 7]
			_aTotFil [_nLinAux, 7] += _aRetQry [_nLinha, 8]
		next
		_aTotFil = asort (_aTotFil,,, {|_x, _y| _x [1] < _y [1]})  // Ordenacao
		
		// Adiciona linha com totais.
		_oAUtil := ClsAUtil():New (_aTotFil)
		aadd (_aTotFil, {"Totais", _oAUtil:TotCol (2), _oAUtil:TotCol (3), _oAUtil:TotCol (4), _oAUtil:TotCol (5), _oAUtil:TotCol (6), _oAUtil:TotCol (7)})
		
	
	
		// Monta uma nova array, totalizando-a por acondicionamento.
		_aTotAcond = {}
		for _nLinha = 1 to len (_aRetQry)
			_nLinAux = ascan (_aTotAcond, {|_aVal| _aVal [1] == _aRetQry [_nLinha, 2]})
			if _nLinAux == 0
				aadd (_aTotAcond, {_aRetQry [_nLinha, 2], 0,0,0,0,0,0})
				_nLinAux = len (_aTotAcond)
			endif
			_aTotAcond [_nLinAux, 2] += _aRetQry [_nLinha, 3]
			_aTotAcond [_nLinAux, 3] += _aRetQry [_nLinha, 4]
			_aTotAcond [_nLinAux, 4] += _aRetQry [_nLinha, 5]
			_aTotAcond [_nLinAux, 5] += _aRetQry [_nLinha, 6]
			_aTotAcond [_nLinAux, 6] += _aRetQry [_nLinha, 7]
			_aTotAcond [_nLinAux, 7] += _aRetQry [_nLinha, 8]
		next
		_aTotAcond = asort (_aTotAcond,,, {|_x, _y| _x [1] < _y [1]})  // Ordenacao

		// Adiciona linha com totais.
		_oAUtil := ClsAUtil():New (_aTotAcond)
		aadd (_aTotAcond, {"Totais", _oAUtil:TotCol (2), _oAUtil:TotCol (3), _oAUtil:TotCol (4), _oAUtil:TotCol (5), _oAUtil:TotCol (6), _oAUtil:TotCol (7)})



		// Monta mensagem em HTML para enviar no e-mail.
		_sMsg := '<H2 align="center">Disponibilidade de estoques em litros</H2>' + chr (13) + chr (10)
		_sMsg += '<H3 align="center">Posicao de ' + dtoc (date ()) + ' - ' + time () + '</H3>' + chr (13) + chr (10)

		// Cria objeto array com os dados de cada array e usa metodo de geracao de HTML com esses dados.
		_aCols = {}
		aadd (_aCols, {"Filial",          "left",  "@!"})
		aadd (_aCols, {"Estoque",         "right", "@E 999,999,999.99"})
		aadd (_aCols, {"(-)Entr.futura",  "right", "@E 999,999,999.99"})
		aadd (_aCols, {"(-)Ped.venda",    "right", "@E 999,999,999.99"})
		aadd (_aCols, {"(-)Ordens prod.", "right", "@E 999,999,999.99"})
		aadd (_aCols, {"(-)Reservas",     "right", "@E 999,999,999.99"})
		aadd (_aCols, {"Disponivel",      "right", "@E 999,999,999.99"})
		_oAUtil := ClsAUtil():New (_aTotFil)
		_sMsg += _oAUtil:ConvHTM ("", _aCols, 'width="95%" border="1" cellspacing="0" cellpadding="3" align="center"', .T.)

		_aCols = {}
		aadd (_aCols, {"Acondicionamento", "left",  "@!"})
		aadd (_aCols, {"Estoque",          "right", "@E 999,999,999.99"})
		aadd (_aCols, {"(-)Entr.futura",   "right", "@E 999,999,999.99"})
		aadd (_aCols, {"(-)Ped.venda",     "right", "@E 999,999,999.99"})
		aadd (_aCols, {"(-)Ordens prod.",  "right", "@E 999,999,999.99"})
		aadd (_aCols, {"(-)Reservas",      "right", "@E 999,999,999.99"})
		aadd (_aCols, {"Disponivel",       "right", "@E 999,999,999.99"})
		_oAUtil := ClsAUtil():New (_aTotAcond)
		_sMsg += _oAUtil:ConvHTM ("", _aCols, 'width="80%" border="1" cellspacing="0" cellpadding="3" align="center"', .T.)

		u_log (_smsg)
		//_sDestin += ";claudia.lionco@novaalianca.coop.br"
		//_sDestin += ";sandra.sugari@novaalianca.coop.br"
		//_sDestin += ";rodrigo.colleoni@novaalianca.coop.br"
		_sDestin += ";fernando.matana@novaalianca.coop.br"
		//_sDestin += ";jocemar.dalcorno@novaalianca.coop.br"
		_sDestin += ";heleno.facchin@novaalianca.coop.br"
		U_SendMail (_sDestin, "Disponibilidade de estoques em litros", _sMsg, {})
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	//u_logFim ()
	//_sArqLog = _sArqLog2
return .T.

