// Programa...: MA261Lin
// Autor......: Robert Koch
// Data.......: 10/09/2014
// Descricao..: P.E. 'Linha OK' na tela MATA261 (transferencias de estoque mod.II)
//
// Historico de alteracoes:
// 12/12/2014 - Robert - Verificacoes integracao Fullsoft.
// 15/01/2015 - Robert - Passa a chamar a funcao U_PodeMov () para validar troca de produtos.
// 27/01/2015 - Robert - Passa a validar parametros VA_ALMFULP, VA_ALMFULT, VA_ALMFULT
// 18/05/2016 - Robert - Novos parametros funcao LaudoEm().
// 03/06/2017 - Robert - Impede a transf. quando lote destino ja existir.
// 29/06/2017 - Robert - Impede a transf. quando lote destino ja existir e LoteDest != LoteOrig
// 16/01/2018 - Robert - Nao impede a transf. quando lote destino ja existir e LoteDest != LoteOrig e lote dest nao tiver saldo.
// 15/03/2018 - Robert - Data nao pode mais ser diferente de date().
// 02/04/2018 - Robert - Movimentacao retroativa habilitada para o grupo 084.
// 09/05/2018 - Robert - Ignora casos como mosto dessulfitado que volta para sulfitado, etc. (parametro VA_PRDTRAN)
// 14/05/2018 - Robert - Transf.entre produtos: exige lote dest.diferente do origem, para que seja gerado novo lote.
// 29/05/2018 - Robert - Leitura do parametro VA_PRDTRAN substituida pelo campo B1_VATROUT
// 29/10/2018 - Robert - Aceita transf. de itens do FullWMS quando chamada pela rotina de integracao (BatFullW)
// 27/03/2019 - Robert - Bloqueia transf.manual de alguns almoxarifados (iniciando pelo 66)
// 12/04/2019 - Robert - Nao pede confirmacao dos almox. do Fullsoft quando chamado a partir da classe ClsTrEstq.
// 25/04/2019 - Robert - Liberado (apenas para mim) transferir para um lote ja existente (GLPI 5769).
// 31/05/2019 - Robert - Liberado para grupo 069 transferir para um lote ja existente (GLPI 5769).
// 07/11/2019 - Robert - Bloqueia transf. AX 66 apenas na matriz por enqto
// 20/07/2020 - Robert - Acesso a transferir lote de estoque para outro lote jah existente passa a validar acesso 107 e nao mais 069.
//                     - Inseridas tags para catalogacao de fontes
// 07/08/2020 - Robert - Bloqueio transf. AX 66 e itens '4191/9998' (pallets) no AX 02
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada para validar transferencias de estoque.
// #PalavasChave      #validacao #transferencias_estoque
// #TabelasPrincipais #SD3
// #Modulos           #EST

// ------------------------------------------------------------------------------------
user function ma261Lin ()
	local _lRet      := .T.
	local _sProdOrig := ""
	local _sProdDest := ""
	local _sAlmOrig  := ""
	local _sAlmDest  := ""
	local _sEndDest  := ""
	local _sLoteOrig := ""
	local _sLoteDest := ""
	local _oSQL      := NIL
	local _aOcup     := {}
	local _nOcup     := 0
	local _aPallet   := {}
	local _nQuant    := 0
	local _nQtFinal  := 0
	local _sAlmFull  := ""
	local _sMsg      := ""
	local _sChvEx    := ""
//	local _sAlmBlq   := ''//'66/'  // Lista de almox bloqueados para digitacao direta no Protheus.
	local _lExigeZAG := .F.

	// Como os campos constam duas vezes no aCols, `as vezes preciso procurar a segunda ocorrencia.
	_sProdOrig = acols [N, _AchaCol ("D3_COD", 1)]
	_sProdDest = acols [N, _AchaCol ("D3_COD", 2)]
	_sLoteOrig = acols [N, _AchaCol ("D3_LOTECTL", 1)]
	_sLoteDest = acols [N, _AchaCol ("D3_LOTECTL", 2)]
	_sAlmOrig  = acols [N, _AchaCol ("D3_LOCAL", 1)]
	_sAlmDest  = acols [N, _AchaCol ("D3_LOCAL", 2)]
	_sEndOrig  = acols [N, _AchaCol ("D3_LOCALIZ", 1)]
	_sEndDest  = acols [N, _AchaCol ("D3_LOCALIZ", 2)]
	_nQuant    = acols [N, _AchaCol ("D3_QUANT", 1)]
	_sChvEx    = acols [N, _AchaCol ("D3_VACHVEX", 1)]

	// Alguns casos estao sendo bloqueados para que somente possam ser movimentados via tabela ZAG
	if _lRet
		if cFilAnt == '01'  // por enquanto apenas na Matriz (NAWeb ainda nao gera para outra filial destino)

			// Se nao estiver gerando pela rotina de solic.transf.estoque, verifica necessidade de bloquear.
			if ! 'ZAG' $ _sChvEx
				if ! _lExigeZAG .and. _sAlmOrig $ '66'
					u_help ("Almoxarifado '" + _sAlmOrig + "' nao pode mais ser movimentado diretamente por esta tela. Utilize NaWeb para solicitacoes de transferencia.",, .t.)
					_lExigeZAG = .T.
				endif
				if ! _lExigeZAG .and. _sAlmDest $ '66'
					u_help ("Almoxarifado '" + _sAlmDest + "' nao pode mais ser movimentado diretamente por esta tela. Utilize NaWeb para solicitacoes de transferencia.",, .t.)
					_lExigeZAG = .T.
				endif
				if ! _lExigeZAG .and. '02' $ _sAlmOrig + _sAlmDest .and. (alltrim (_sProdOrig) $ '4191/9998' .or. alltrim (_sProdDest) $ '4191/9998')
					u_help ("Produto(s) envolvido(s) nesta transferencia nao podem mais ser movimentados diretamente por esta tela. Utilize NaWeb para solicitacoes de transferencia.",, .t.)
					_lExigeZAG = .T.
				endif
			endif
		endif
	endif
	if _lRet .and. _lExigeZAG
		_lRet = .F.
	endif

	if _lRet .and. (da261Data != date () .or. dDataBase != date ())
		_sMsg = "Alteracao de data da movimentacao ou data base do sistema: bloqueada para esta rotina."
		if U_ZZUVL ('084', __cUserId, .F.)
			_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
		else
			u_help (_sMsg,, .t.)
			_lRet = .F.
		endif
	endif

	// Se nao informado lote destino, assume que seja o mesmo da origem.
	_sLoteDest = iif (empty (_sLoteDest), _sLoteOrig, _sLoteDest)

	if _lRet
		if _sProdOrig != _sProdDest

			// Ignora casos como mosto desulfitado que volta para sulfitado.
			u_log2 ('debug', 'Produto origem: ' + _sProdOrig)
			If Posicione ("SB1", 1, xfilial("SB1") + _sProdOrig, "B1_VATROUT") != "S"
				//_lRet = U_PodeMov ('E01')
				_sMsg = "Harry Potter usa o feiti�o 'Riddikulus' para transformar bichos-pap�es em outros objetos. Como n�o podemos usar magia fora de Hogwarts, voc� deve informar o produto destino igual ao produto origem."
				if U_ZZUVL ('119', __cUserId, .F.)
					_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
				else
					u_help (_sMsg,, .t.)
					_lRet = .F.
				endif
			endif
		endif
	endif
	if _lRet .and. ! empty (_sEndDest)
		sbe -> (dbsetorder (1))  // BE_FILIAL+BE_LOCAL+BE_LOCALIZ
		if ! sbe -> (dbseek (xfilial ("SBE") + _sAlmDest + _sEndDest, .F.))
			u_help ("Local / endereco destino nao cadastrado.",, .t.)
			_lRet = .F.
		endif
	endif

	// Verifica se consta algo no endereco destino. 		
	if _lRet .and. ! empty (_sEndDest)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " select BF_PRODUTO, BF_LOTECTL, BF_QUANT"
		_oSQL:_sQuery +=   " from " + RetSQLName ("SBF") + " SBF "
		_oSQL:_sQuery +=  " where SBF.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=    " and SBF.BF_FILIAL   = '" + xfilial ("SBF") + "'"
		_oSQL:_sQuery +=    " and SBF.BF_LOCAL    = '" + _sAlmDest + "'" 
		_oSQL:_sQuery +=    " and SBF.BF_LOCALIZ  = '" + _sEndDest + "'" 
		_oSQL:_sQuery +=    " and SBF.BF_QUANT   != 0" 
		_aOcup := aclone (_oSQL:Qry2Array ())
	endif
	if _lRet
		for _nOcup = 1 to len (_aOcup)
			if _aOcup [_nOcup, 1] != _sProdDest .and. sbe -> be_vaproun != 'N'
				u_help ("O endereco destino ja contem o produto '" + alltrim (_aOcup [_nOcup, 1]) + "' e foi configurado para nao aceitar mais de um produto.",, .t.)
				_lRet = .F.
				exit
			endif
		next
	endif
	if _lRet
		for _nOcup = 1 to len (_aOcup)
			if _aOcup [_nOcup, 1] == _sProdDest .and. sbe -> be_estfis == '000002' .and. _aOcup [_nOcup, 2] != _sLoteDest
				_lRet = u_MsgNoYes ("O endereco destino eh do tipo 'pulmao' e ja contem o lote '" + alltrim (_aOcup [_nOcup, 2]) + "' deste mesmo produto. Deseja juntar lotes diferentes nesse endereco?")
				exit
			endif
		next
	endif

	if _lRet .and. ! empty (_sEndDest) .and. sbe -> be_estfis $ '000001/000002'

		// Calcula quantidade final que vai ficar no endereco.
		_nQtFinal = _nQuant
		for _nOcup = 1 to len (_aOcup)
			if _aOcup [_nOcup, 1] == _sProdDest
				_nQtFinal += _aOcup [_nOcup, 3]
			endif
		next

		// Verifica se vai ficar acima da quantidade de um pallet.
		if ! fBuscaCpo ("SB1", 1, xfilial ("SB1") + _sProdDest, "B1_TIPO") $ "ME/"
			_aPallet := aclone (U_VA_QtdPal (_sProdDest, _nQtFinal))
			if sbe -> be_estfis == '000001' .and. len (_aPallet) > 2
				u_help ("A quantidade no endereco ficaria " + cvaltochar (_nQtFinal) + " e necessitaria " + cvaltochar (len (_aPallet)) + " pallets, o que nao cabe em enderecos de picking (maximo suportado por pallet: " + cvaltochar (_aPallet [1, 2]) + ").",, .t.)
				_lRet = .F.
			endif
			if sbe -> be_estfis == '000002' .and. len (_aPallet) > 1
				u_help ("A quantidade no endereco ficaria " + cvaltochar (_nQtFinal) + " e necessitaria " + cvaltochar (len (_aPallet)) + " pallets, o que nao cabe em enderecos de pulmao (maximo suportado por pallet: " + cvaltochar (_aPallet [1, 2]) + ").",, .t.)
				_lRet = .F.
			endif
		endif
	endif

	// Validacoes integracao com Fullsoft
//	if _lRet .and. cEmpAnt == '01' .and. cFilAnt == '01' .and. ! IsInCallStack ("U_BATFULLW")
	//u_log ('tipo da variavel:', type ("_lClsTrEst"))
	if type ("_lClsTrEst") == 'L' .and. _lClsTrEst == .T.  // Se estah sendo chamado de dentro dessa classe, vou assumir que as devidas verificacoes jah foram feitas.
		// Pode passar
		u_log2 ('info', 'aceitando transferencia por que vem de uma chamada da classe ClsTrEstq.')
	else
		if _lRet .and. cEmpAnt == '01' .and. cFilAnt == '01' .and. ! IsInCallStack ("U_BATFULLW")
			if fBuscaCpo ("SB1", 1, xfilial ("SB1") + _sProdDest, "B1_VAFULLW") == 'S'
				_sAlmFull = GetMv ("VA_ALMFULP",, '') + '/' + GetMv ("VA_ALMFULD",, '') + '/' + GetMv ("VA_ALMFULT",, '')
				if _sAlmOrig $ '01/' + _sAlmFull .or. _sAlmDest $ '01/' + _sAlmFull
					_sMsg = "Almoxarifados envolvidos na integracao com Fullsoft nao devem ser movimentados manualmente."
					if U_ZZUVL ('029', __cUserId, .F.)
						_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
					else
						u_help (_sMsg,, .t.)
						_lRet = .F.
					endif
				endif
			endif
		endif
	endif

	// Validacoes laudos tanques. Inicialmente pede confirmacao, mas a intencao eh bloquear se nao tiver laudo valido.
	if _lRet .and. ! empty (_sLoteOrig)
		if fBuscaCpo ("SB1", 1, xfilial ("SB1") + _sProdOrig, "B1_TIPO") $ "VD/"
			if empty (U_LaudoEm (_sProdOrig, _sLoteOrig, dA261Data))
				_lRet = U_MsgNoYes ("Nao encontrei laudo laboratorial valido para este produto/lote. Confirma a movimentacao assim mesmo?", .F.)
			endif
		endif
	endif

	if _lRet .and. ! empty (_sLoteDest) .and. _sLoteOrig != _sLoteDest
		sb8 -> (dbsetorder (5))  // B8_FILIAL+B8_PRODUTO+B8_LOTECTL+B8_NUMLOTE+DTOS(B8_DTVALID)
		if sb8 -> (dbseek (xfilial ("SB8") + _sProdDest + _sLoteDest, .F.))
				//if alltrim (cUserName) == 'robert.koch' // precisei para alguns ajustes retroativos... (GLPI 5769)
				if U_ZZUVL ('107', __cUserId, .F.)
					_lRet = U_MsgNoYes ("Ja existe o lote '" + _sLoteDest + "' para o produto '" + alltrim (_sProdDest) + "'. Confirma assim mesmo?")
				else
					U_help ("Ja existe o lote '" + _sLoteDest + "' para o produto '" + alltrim (_sProdDest),, .t.)
					_lRet = .F.
				endif
		endif
	endif

return _lRet



// -------------------------------------------------------------------
// Encontra campos no aHeader
static function _AchaCol (_sCampo, _nQual)
	local _nCol1 := 0
	local _nCol2 := 0
	local _nRet  := 0
	for _nCol1 = 1 to len (aHeader)
		if upper (alltrim (aHeader [_nCol1, 2])) == upper (alltrim (_sCampo))
			if _nQual == 1
				_nRet = _nCol1
				exit
			else
				for _nCol2 = _nCol1 + 1 to len (aHeader)
					if upper (alltrim (aHeader [_nCol2, 2])) == upper (alltrim (_sCampo))
						_nRet = _nCol2
						exit
					endif
				next
				exit
			endif
		endif
	next
return _nRet