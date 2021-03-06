// Programa:  M410STTS
// Autor:     Jeferson Rech
// Data:      jul/2005
// Descricao: P.E. Executado apos a atualizacao do pedido de venda.
//
// Historico de alteracoes:
// 27/02/2009 - Robert - Pedidos jah nascem liberados de estoque na Vinicola
// 05/10/2009 - Robert - Nao libera mais o estoque dos pedidos da Vinicola.
// 09/07/2015 - Robert - Desabilitada exclusao do cliente 000001 e tratamento de banco/vendedor
//                     - Limpa tabela ZZS quando pedido gerado pelo EDI.
// 09/07/2016 - Robert - Envia e-mails de aviso de bloqueio de preco / margem.
// 27/06/2017 - Robert - Gera evento se duplicar C5_PEDCLI (GLPI 2728).
// 24/11/2019 - Robert - Campo C5_VABLOQ passa a ter mais de uma posicao (GLPI 7000).
//

// --------------------------------------------------------------------------
User Function M410STTS()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt := U_SalvaAmb ()

	if ! inclui .and. ! altera .and. sc5 -> (deleted ())
		_LimpaZZS ()
	endif

	// Verifica necessidade de envio de e-mails de avisos.
	_MailAviso ()

	// Verifica se houve duplicidade de ordem de compra.
	_VerOC ()

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
Return



// --------------------------------------------------------------------------
static function _LimpaZZS ()
	zzs -> (dbsetorder (3))  // ZZS_FILIAL+ZZS_NUMPED
	if zzs -> (dbseek (xfilial ("ZZS") + sc5 -> c5_num, .F.))
		reclock ("ZZS", .F.)
		zzs -> zzs_numped = ''
		zzs -> zzs_motivo = alltrim (zzs -> zzs_motivo) + ';nosso ped.' + sc5 -> c5_num + ' excluido'
		msunlock ()
	endif
return



// --------------------------------------------------------------------------
static function _MailAviso ()
	local _sMsg    := ""

	if inclui .or. (altera .and. !Empty (sc5 -> C5_LIBEROK) .And. Empty (sc5 -> C5_BLQ))
//		if m->c5_vaBloq = 'P'  // Bloqueio por preco
		if 'P' $ m->c5_vaBloq  // Bloqueio por preco
			if type ("_sMsgPUltV") == "C"  // Variavel publica que deve ter sido criada pelo programa GrvLibPV 
				_sMsg += chr (13) + chr (10) + _sMsgPUltV
			endif
			U_ZZUNU ('006', "Pedido de venda '" + m->c5_num + "' liberado por " + alltrim (cUserName) + " com precos menores que a ultima venda.", _sMsg) 
		endif

//		if m->c5_vaBloq = 'M'  // Bloqueio por margem
		if 'M' $ m->c5_vaBloq  // Bloqueio por margem
			_sMsg := "Pedido...:" + m->c5_num + chr (13) + chr (10)
			_sMsg += "Cliente..:" + m->c5_cliente + '/' + m->c5_lojacli + ' - '
			if m->c5_tipo $ "BD"
				_sMsg += fBuscaCpo ("SA2", 1, xfilial ("SA2") + m->c5_cliente + m->c5_lojacli, "A2_NOME") + chr (13) + chr (10)
			else
				_sMsg += fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->c5_cliente + m->c5_lojacli, "A1_NOME") + chr (13) + chr (10)
			endif
			_sMsg += "Margem...:" + transform (m->c5_vaMCont, "@E 999,999.99%") + chr (13) + chr (10)
			
			U_ZZUNU ('006', "Pedido de venda '" + m->c5_num + "' liberado por " + alltrim (cUserName) + " abaixo da margem minima", _sMsg)
		endif
	endif

return



// --------------------------------------------------------------------------
// Verifica se houve repeticao de ordem de compra.
static function _VerOC ()
//	local _sMsg     := ""
	local _oSQL     := NIL
//	local _aRetSQL  := {}
	local _nLinha   := 0
	local _sCodEven := 'SC5007'
	local _oEvento  := {}

	if (inclui .or. altera) .and. len (alltrim (m->c5_pedcli)) > 0
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT DISTINCT 'Ordem de compra ' + RTRIM (C5_PEDCLI) + ' ja informada no pedido ' + C5_NUM + ' de ' + dbo.VA_DTOC (C5_EMISSAO) as AVISO" 
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SC5") + " SC5 "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND C5_FILIAL  = '" + xfilial ("SC5") + "'"
		_oSQL:_sQuery +=   " AND C5_CLIENTE = '" + m->c5_cliente   + "'"
		_oSQL:_sQuery +=   " AND C5_LOJACLI = '" + m->c5_lojacli   + "'"
		_oSQL:_sQuery +=   " AND C5_NUM    != '" + m->c5_num       + "'"
		_oSQL:_sQuery +=   " AND C5_PEDCLI  = '" + m->c5_pedcli    + "'"
		_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT *" 
		_oSQL:_sQuery +=                     " FROM " + RetSQLName ("SZN") + " SZN " 
		_oSQL:_sQuery +=                    " WHERE SZN.D_E_L_E_T_ = ''" 
		_oSQL:_sQuery +=                      " AND ZN_FILIAL  = '" + xfilial ("SZN") + "'" 
		_oSQL:_sQuery +=                      " AND ZN_CLIENTE = C5_CLIENTE" 
		_oSQL:_sQuery +=                      " AND ZN_LOJACLI = C5_LOJACLI" 
		_oSQL:_sQuery +=                      " AND ZN_PEDVEND = C5_NUM" 
		_oSQL:_sQuery +=                      " AND ZN_CODEVEN = '" + _sCodEven + "'" 
		_oSQL:_sQuery +=                  " )"
//		_oSQL:Log ()
		_aRetQry := aclone (_oSQL:Qry2Array (.F., .F.))
		if len (_aRetQry) > 0
			_oEvento := ClsEvent ():New ()
			_oEvento:CodEven   = _sCodEven
			_oEvento:Texto     = 'Repeticao ordem compra no pedido ' + m->c5_num
			for _nLinha = 1 to len (_aRetQry)
				_oEvento:Texto += chr (13) + chr (10) + _aRetQry [_nLinha, 1]
			next
			_oEvento:Cliente   = m->c5_cliente
			_oEvento:LojaCli   = m->c5_lojacli
			_oEvento:PedVenda  = m->c5_num
			_oEvento:Grava ()
		endif
	endif
return
