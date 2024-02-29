// Programa.: M410STTS
// Autor....: Jeferson Rech
// Data.....: jul/2005
// Descricao: P.E. Executado apos a atualizacao do pedido de venda.
//
// Tags de localização
// #TipoDePrograma    #Ponto_De_Entrada
// #PalavasChave      #PE #pontodeentrada #pedido #venda #pedidosdevendas #TudoOK
// #TabelasPrincipais #SC5 #SC6 
// #Modulos 		  #faturamento #FAT
//
// Historico de alteracoes:
// 27/02/2009 - Robert  - Pedidos jah nascem liberados de estoque na Vinicola
// 05/10/2009 - Robert  - Nao libera mais o estoque dos pedidos da Vinicola.
// 09/07/2015 - Robert  - Desabilitada exclusao do cliente 000001 e tratamento de banco/vendedor
//                      - Limpa tabela ZZS quando pedido gerado pelo EDI.
// 09/07/2016 - Robert  - Envia e-mails de aviso de bloqueio de preco / margem.
// 27/06/2017 - Robert  - Gera evento se duplicar C5_PEDCLI (GLPI 2728).
// 24/11/2019 - Robert  - Campo C5_VABLOQ passa a ter mais de uma posicao (GLPI 7000).
// 11/01/2022 - Claudia - Incluida validação para liberação de credito p/ ped.ecommerce. GLPI: 11270
// 04/05/2023 - Claudia - Incluida a validação para liberação de credito para loja. GLPI: 13521
// 05/05/2023 - Claudia - Alterada validação de lojas, incluindo a verificação das filiais. GLPI: 13533
// 21/09/2023 - Sandra  - Incluida a validação para liberação de credito R$ para loja. GLPI: 14260. 
// 25/01/2024 - Claudia - Melhorias no layout dos e-mails. GLPI: 14805
// 29/02/2024 - Robert  - Enviar e-mail bloqueio gerencial tipo S especifico de sucos - GLPI 14980
//

// --------------------------------------------------------------------------------------------------
User Function M410STTS()
	local _aAreaAnt := U_ML_SRArea()
	local _aAmbAnt  := U_SalvaAmb()

	if ! inclui .and. ! altera .and. sc5 -> (deleted())
		_LimpaZZS()
	endif

	// Verifica necessidade de envio de e-mails de avisos.
	_MailAviso()

	// Verifica se houve duplicidade de ordem de compra.
	_VerOC()

	// Libera pedidos de ecommerce
	if !empty(m->c5_pedecom) 
		_LibCred()
	endif
	// Libera pedidos da filial
	if alltrim(m->c5_vatipo) $('CC/CD/PIX/PX/R$') .and. alltrim(m->c5_filial) $ ('13/08')
		_LibCred()
	endif

	U_SalvaAmb(_aAmbAnt)
	U_ML_SRArea(_aAreaAnt)
Return
//
// --------------------------------------------------------------------------
// Limpa ZZS
static function _LimpaZZS()
	zzs -> (dbsetorder(3))  // ZZS_FILIAL+ZZS_NUMPED
	if zzs -> (dbseek(xfilial("ZZS") + sc5 -> c5_num, .F.))
		reclock("ZZS", .F.)
		zzs -> zzs_numped = ''
		zzs -> zzs_motivo = alltrim (zzs -> zzs_motivo) + ';nosso ped.' + sc5 -> c5_num + ' excluido'
		msunlock()
	endif
return
//
// --------------------------------------------------------------------------
// Verifica necessidade de envio de e-mails de avisos.
static function _MailAviso()
	local _sMsg    := ""

	if inclui .or. (altera .and. !Empty(sc5 -> C5_LIBEROK) .And. Empty(sc5 -> C5_BLQ))
		if 'P' $ m->c5_vaBloq  // Bloqueio por preco
			if type ("_sMsgPUltV") == "C"  // Variavel publica que deve ter sido criada pelo programa GrvLibPV 
				_sMsg += chr (13) + chr (10) + _sMsgPUltV
			endif
			U_ZZUNU('006', "Pedido de venda '" + m->c5_num + "' liberado por " + alltrim(cUserName) + " com precos menores que a ultima venda.", _sMsg) 
		endif

		//if 'M' $ m->c5_vaBloq  // Bloqueio por margem
		_nMargMin = GetMv("VA_MCPED1")
		if m->c5_vaMCont < _nMargMin .and. 'M' $ m->c5_vaBloq  // Bloqueio por margem
			_sMsg := "<html>"
			_sMsg += "<b>Pedido:</b>" + m->c5_num + "<br>"
			_sMsg += "<b>Cliente:</b>" + m->c5_cliente + '/' + m->c5_lojacli + ' - '
			if m->c5_tipo $ "BD"
				_sMsg += fBuscaCpo ("SA2", 1, xfilial("SA2") + m->c5_cliente + m->c5_lojacli, "A2_NOME") + "<br>"
			else
				_sMsg += fBuscaCpo ("SA1", 1, xfilial("SA1") + m->c5_cliente + m->c5_lojacli, "A1_NOME") + "<br>"
			endif
			_sMsg += "<b>Margem:</b>" + transform (m->c5_vaMCont, "@E 999,999.99%") + "<br>"
			_sMsg += "</html>"
			
			U_ZZUNU('006', "Pedido de venda '" + m->c5_num + "' liberado por " + alltrim(cUserName) + " abaixo da margem minima", _sMsg)
		endif

		if 'S' $ m->c5_vaBloq  // Bloqueio por preco
			U_ZZUNU ('158', "Pedido de venda '" + m->c5_num + "' (bloq.superint.) gravado por " + alltrim(cUserName), _sMsgPBSup)
		endif

	endif
return
//
// --------------------------------------------------------------------------
// Verifica se houve repeticao de ordem de compra
static function _VerOC()
	local _oSQL     := NIL
	local _nLinha   := 0
	local _sCodEven := 'SC5007'
	local _oEvento  := {}

	if (inclui .or. altera) .and. len(alltrim(m->c5_pedcli)) > 0
		_oSQL := ClsSQL():New()
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
		_aRetQry := aclone(_oSQL:Qry2Array(.F., .F.))

		if len(_aRetQry) > 0
			_oEvento := ClsEvent():New()
			_oEvento:CodEven   = _sCodEven
			_oEvento:Texto     = 'Repeticao ordem compra no pedido ' + m->c5_num
			for _nLinha = 1 to len(_aRetQry)
				_oEvento:Texto += chr (13) + chr (10) + _aRetQry [_nLinha, 1]
			next
			_oEvento:Cliente   = m->c5_cliente
			_oEvento:LojaCli   = m->c5_lojacli
			_oEvento:PedVenda  = m->c5_num
			_oEvento:Grava()
		endif
	endif
return
//
// --------------------------------------------------------------------------
// Libera pedidos de ecommerce/loja
static function _LibCred()
	Local _oSQL := ClsSQL():New()

	_oSQL:_sQuery := " UPDATE  SC9010 SET C9_BLCRED = '' "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ =''"
	_oSQL:_sQuery += " AND C9_FILIAL    ='"+ m->c5_filial   +"'"
	_oSQL:_sQuery += " AND C9_PEDIDO    ='"+ m->c5_num      +"'"
	_oSQL:Log()
	_oSQL:Exec()
return
