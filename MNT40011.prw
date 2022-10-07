// Programa:  MNT40011
// Autor:     Robert Koch
// Data:      03/10/2022
// Descricao: P.E. Valida encerramento de OS
//            Criado por solicitacao via GLPI 12678


// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Valida encerramento de OS
// #PalavasChave      #pedidos_compra #OS #Ordem #Encerramento #Finalizacao #MNTA435
// #TabelasPrincipais #STJ #SC7
// #Modulos           #MNT

// --------------------------------------------------------------------------
user function MNT40011 ()
	local _lRet40011 := .T.
	local _sPdCom    := ''
	local _oSQL      := NIL

	U_Log2 ('debug', '[' + procname () + ']')

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT ISNULL (STRING_AGG (C7_NUM, ','), '')"
	_oSQL:_sQuery +=  " FROM (SELECT DISTINCT C7_NUM"
	_oSQL:_sQuery +=          " FROM " + RetSQLName ("SC7") + " SC7"
	_oSQL:_sQuery +=         " WHERE SC7.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=           " AND SC7.C7_FILIAL  = '" + xfilial ("SC7") + "'"
	_oSQL:_sQuery +=           " AND SC7.C7_OP      like '" + STJ->TJ_ORDEM + "%'"
	_oSQL:_sQuery +=           " AND SC7.C7_QUANT   > SC7.C7_QUJE"
	_oSQL:_sQuery +=           " AND SC7.C7_RESIDUO != 'S'"
	_oSQL:_sQuery +=        ") AS SUB"  // Tive que fazer uma subquery para poder usar STRING_AGG
	_oSQL:Log ('[' + procname () + ']')
	_sPdCom = alltrim (_oSQL:RetQry (1, .f.))
	if ! empty (_sPdCom)
		u_help ("Encerramento da OS nao permitido, pois tem o(s) seguinte(s) pedido(s) de compra vinculados: " + _sPdCom,, .t.)
		_lRet40011 = .F.
	endif
return _lRet40011
