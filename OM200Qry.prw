// Programa:  OM200Qry
// Autor:     Robert Koch
// Data:      27/05/2014
// Descricao: PE para filtro dos pedidos liberados a gerar carga no OMS
//
// Historico de alteracoes:
// 14/07/2020 - Robert - Permite filtrar por representante (GLPI 8161).
//                     - Inseridas tags para catalogacao de fontes
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada #filtro
// #PalavasChave      #montagem_de_cargas
// #TabelasPrincipais #SC5 #SC6 #SC9
// #Modulos           #OMS

// --------------------------------------------------------------------------
User Function OM200Qry ()
	local _sRet     := paramixb [1]
	local _sRepCarg := ''
	local _aAreaAnt := U_ML_SRArea ()

//	u_log2 ('debug', _sRet)
	do while .T.
		_sRepCarg = U_Get ('Filtrar pedidos por representante? (vazio=todos)', 'C', 6, '', 'SA3', space (6), .F., '.T.')
		if ! empty (_sRepCarg)
			sa3 -> (dbsetorder (1))
			if ! sa3 -> (dbseek (xfilial ("SA3") + _sRepCarg, .F.))
				u_help ("Representante '" + _sRepCarg + "' nao cadastrado.",, .t.)
				loop
			endif
		endif
		exit
	enddo
	if ! empty (_sRepCarg)
		_sRet += " AND SC5.C5_VEND1 = '" + _sRepCarg + "'"
	endif

	// Acrescenta filtro `a query padrao.
	_sRet += " AND C9_PEDIDO IN (SELECT C9_PEDIDO FROM VA_VPEDIDOS_PARA_CARGA WHERE C9_FILIAL = '" + xfilial ("SC9") + "')" // WHERE FILIAL = SC9.C9_FILIAL)"

//	u_log2 ('debug', _sRet)
	U_ML_SRArea (_aAreaAnt)
return _sRet
