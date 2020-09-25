// Programa:  MT500Apo
// Autor:     Robert Koch
// Descricao: P.E. apos eliminar residuo do item (SC6) do pedido e ainda dentro da transacao.
//            Criado inicialmente para exportar dados para o sistema Mercanet.
//
// Historico de alteracoes:
// 11/09/2017 - Robert - Recalcula pesos e volumes no SC5.
//                     - Gravacao evento.
//

// --------------------------------------------------------------------------
user function MT500Apo ()
	local _aAreaAnt := U_ML_SRArea ()
	local _oEvento  := NIL
//	local _oSQL     := NIL

	// Atualiza pesos e volumes do pedido.
	_AtuPeso ()


	// Este P.E. eh chamado para cada item do pedido, mas no U_AtuMerc jah tem tratamento para duplicidades.
//	_oSQL := ClsSQL ():New ()
//	_oSQL:_sQuery  := "SELECT TOP 1 ALIAS + CHAVE1" 
//	_oSQL:_sQuery  += " FROM VA_INTEGR_MERCANET" 
//	_oSQL:_sQuery  += " ORDER BY DATA_GRAV DESC" 
//	if alltrim (_oSQL:RetQry (1, .F.)) != alltrim ("SC5" + sc5 -> c5_num)
		U_AtuMerc ("SC5", sc5 -> (recno ()))
//	endif

	
	// Grava evento para posterior consulta
	_oEvento := ClsEvent():new ()
	_oEvento:CodEven   = "SC5008"
	_oEvento:Texto     = "Eliminado residuo (qt=" + cvaltochar (sc6 -> c6_qtdven) + ")"
	_oEvento:Cliente   = sc6 -> c6_cli
	_oEvento:LojaCli   = sc6 -> c6_loja
	_oEvento:PedVenda  = sc6 -> c6_num
	_oEvento:Produto   = sc6 -> c6_produto
	_oEvento:Grava ()
	
	
	U_ML_SRArea (_aAreaAnt)
return


// --------------------------------------------------------------------------
static function _AtuPeso ()
	local _oSQL     := NIL

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "UPDATE SC5 "
	_oSQL:_sQuery += " SET C5_PESOL   = SC6.PESOLIQ, "
	_oSQL:_sQuery +=     " C5_PBRUTO  = SC6.PESOBRUTO, "
	_oSQL:_sQuery +=     " C5_VOLUME1 = SC6.QTVOLUMES "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SC5") + " SC5 "
	_oSQL:_sQuery +=    " INNER JOIN (SELECT C6_FILIAL,"
	_oSQL:_sQuery +=                       " C6_NUM,"
	_oSQL:_sQuery +=                       " SUM (CASE C6_BLQ WHEN 'R' THEN 0 ELSE C6_VAPLIQ END) AS PESOLIQ,"
	_oSQL:_sQuery +=                       " SUM (CASE C6_BLQ WHEN 'R' THEN 0 ELSE C6_VAPBRU END) AS PESOBRUTO,"
	_oSQL:_sQuery +=                       " SUM (CASE C6_BLQ WHEN 'R' THEN 0 ELSE C6_VAQTVOL END) AS QTVOLUMES"
	_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SC6")
	_oSQL:_sQuery +=                 " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                 " GROUP BY C6_FILIAL, C6_NUM"
	_oSQL:_sQuery +=                ") AS SC6"
	_oSQL:_sQuery +=                " ON (SC6.C6_FILIAL = C5_FILIAL"
	_oSQL:_sQuery +=                " AND SC6.C6_NUM    = C5_NUM)"
	_oSQL:_sQuery += " WHERE SC5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SC5.C5_FILIAL  = '" + sc5 -> c5_filial + "'"
	_oSQL:_sQuery +=   " AND SC5.C5_NUM     = '" + sc5 -> c5_num    + "'"
//	_oSQL:Log ()
	_oSQL:Exec ()
return
