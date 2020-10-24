// Programa...: MTA410T
// Autor......: ?
// Data.......: ?
// Descricao..: P.E. apos a gravacao do pedido de vendas.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada apos a gravacao do pedido de vendas
// #PalavasChave      #pedido_de_venda
// #TabelasPrincipais #SC5 SC6
// #Modulos           #FAT

// Historico de alteracoes:
// 17/04/2008 - Robert  - Chamada rotina U_FrtGrZZ1.
// 14/06/2013 - Leandro - Grava reservas automaticamente, quando solicitado
// 21/06/2013 - Leandro - Quando altera pedido, excluir reservas e faz todas novamente - mensagem para usuário
// 18/10/2013 - Robert  - Grava evento apos inclusao/alteracao do pedido.
// 18/11/2016 - Robert  - Envia atualizacao para o sistema Mercanet.
// 28/04/2017 - Robert  - Passa tambem o lote do produto e o pedido para a funcao VerEstq().
// 21/07/2020 - Robert  - Inseridas tags para catalogacao de fontes
// 24/10/2020 - Robert  - Desabilitada gravacao SC0 (reservas) cfe. campo C5_VARESER (nao usamos mais desde 2014).
//

// --------------------------------------------------------------------------
User Function MTA410T()
	local _aAreaAnt := U_ML_SRArea ()
	
	_VerTransp ()
	
// Nao usamos mais desde 2014	_VerReserv ()

	_EvtAlter ()

	U_AtuMerc ('SC5', sc5 -> (recno ()))
	
	U_ML_SRArea (_aAreaAnt)
return



// --------------------------------------------------------------------------
// Verifica se deixa ou nao a transportadora selecionada.
static function _VerTransp ()
	local _oSQL := NIL
	local _lDeixaTr := .F.
//	local _x := 0
	// Verifica se deixa ou nao a transportadora selecionada. Isso por que apenas o pessoal de logistica
	// pode selecionar a transportadora, exceto casos de filial, nao mov.estoque, FOB, etc.
	_lDeixaTr = .F.
	//
	// Frete FOB ou de filiais, pode deixar.
	if sc5 -> c5_tpfrete == "F" .or. cEmpAnt + cFilAnt != '0101'
		_lDeixaTr = .T.
	else
		// Se o usuario tem liberacao, pode deixar.
		if U_ZZUVL ('002', __cUserId, .F.)
			_lDeixaTr = .T.
		else
			// Se nenhum TES do pedido vai movimentar estoque, pode deixar.
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT COUNT (*)"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SC6") + " SC6, "
			_oSQL:_sQuery +=              RetSQLName ("SF4") + " SF4 "
			_oSQL:_sQuery +=  " WHERE SC6.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SC6.C6_FILIAL  = '" + xfilial ("SC6") + "'"
			_oSQL:_sQuery +=    " AND SC6.C6_NUM     = '" + sc6 -> c6_num + "'"
			_oSQL:_sQuery +=    " AND SF4.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SF4.F4_FILIAL  = '" + xfilial ("SF4") + "'"
			_oSQL:_sQuery +=    " AND SF4.F4_CODIGO  = SC6.C6_TES"
			_oSQL:_sQuery +=   " AND (SF4.F4_ESTOQUE = 'S' OR SF4.F4_VAFDEP = 'S')"
			if _oSQL:RetQry (1, .f.) == 0  // Nao vai movimentar estoque
				_lDeixaTr = .T.
			endif
		endif
	endif

	if _lDeixaTr
		U_FrtPv ("I")  // Grava previsao de frete na tabela ZZ1
	else
		reclock("SC5", .F.)
		Replace SC5->C5_TRANSP With ''
		msunlock()
	endif
return

/* Nao usamos mais desde 2014
// --------------------------------------------------------------------------
// Verifica se deve criar reserva de estoque para o pedido.
static function _VerReserv ()
	local _sSQL    := ""
	Local _temestq := ''
	Local _aSemEst := {}
	Local _saldob2 := 0
	local _aLiber    := {.F.,,}
	local _lContinua := .F.
	local _filres := ""
	local _aArea := getarea ()
	local _x := 0

	// Grava reservas automaticamente, quando solicitado
	If SC5->C5_VARESER == 'S'

		// se o campo de filial de embarque estiver preenchido, deve reservas para esta filial...senão, reserva para a matriz
		if empty(M->C5_VAFEMB)
			_filres := '01'
		else
			_filres := M->C5_VAFEMB
		endif

		_cNumDoc := GetSxeNum("SC0","C0_NUM")
		_cSolicit := TRIM(substr(UPPER(cUsuario),7,15))
		_lReserv := .T.

		DbSelectArea("SC6")
		DbSetOrder(1)
		DbSeek(xFilial('SC5') + SC5->C5_NUM, .f.)

		// verifica se todos os itens possuem quantidade suficiente para serem reservados
		Do While !eof() .and. xFilial('SC6') + SC5->C5_NUM == SC6->C6_FILIAL + SC6->C6_NUM

			// se for o produto genérico (9999) pula o registro, pois não é para considerar
			if alltrim(SC6->C6_PRODUTO) == '9999'
				DbSelectArea("SC6")
				DbSkip()
				loop
			endif

			// função padrão para verificar o estoque
			dbselectarea("SB2")
			dbsetorder(1)
			dbseek(_filres + SC6->C6_PRODUTO)
			if found()
				_saldob2 := saldosb2()
			endif
			dbselectarea("SB2")
			dbclosearea()

			// se a quantidade em estoque menos a quantidade vendida é menor que zero, é porque não tem estoque suficiente
			if (_saldob2 - SC6->C6_QTDVEN) < 0
				_lReserv := .F.
			endif

			// função customizada para verificar o estoque
			_temestq := U_VerEstq ('PV', SC6->C6_PRODUTO, _filres, SC6->C6_LOCAL, SC6->C6_QTDVEN, '', SC6->C6_LOCALIZ, SC6->C6_LOTECTL, sc5 -> c5_num)

			// se função retornar string, é porque não tem estoque suficiente
			if !empty(_temestq)
				_lReserv := .F.
			endif

			// verifica validação do SaldoSB2 e da função VerEstq
			if !empty(_temestq) .or. (_saldob2 - SC6->C6_QTDVEN) < 0
				// adiciona código e descrição para mostrar na mensagem depois
				aadd(_aSemEst,{SC6->C6_PRODUTO,SC6->C6_DESCRI})
			endif

			DbSelectArea("SC6")
			DbSkip()
		EndDo

		// só reserva se passar pelas duas validações e se todos os itens puderem ser reservados em sua quantidade total
		if _lReserv // .and. empty(_temestq) .and. SC6->C6_QTDVEN <= _saldob2

			// verifica se já tem reservas para o pedido em questão e deleta tudo, para depois incluir novamente
			dbselectarea("SC0")
			dbsetorder(3)
			dbseek(_filres + SC5->C5_NUM)
			if found()
				While !EOF() .and. SC0->C0_VAPEDID == SC5->C5_NUM

					// deleta todas reservas do pedido em questão e depois inclui de novo, para passar por todas validações novamente
					reclock ("SC0", .F.)
					SC0 -> (dbdelete ())
					msunlock ()

					dbselectarea("SB2")
					dbsetorder(1)
					dbseek(_filres + SC0->C0_PRODUTO)
					reclock("SB2")
					Replace SB2->B2_RESERVA With SB2->B2_RESERVA - SC0->C0_QUANT
					msunlock()

					dbselectarea("SC0")
					dbskip()
				enddo
			endif

			DbSelectArea("SC6")
			DbSetOrder(1)
			DbSeek(xFilial('SC5') + SC5->C5_NUM, .f.)

			Do While !eof() .and. xFilial('SC6') + SC5->C5_NUM == SC6->C6_FILIAL + SC6->C6_NUM

				dbselectarea("SC0")
				dbsetorder(1)
				dbseek(_filres + _cNumDoc)
				if found()
					reclock("SC0", .F.)
					Replace C0_QUANT With C0_QUANT + SC6->C6_QTDVEN
					Replace C0_QTDORIG With C0_QTDORIG + SC6->C6_QTDVEN
				else
					reclock("SC0", .T.)
					Replace C0_QUANT With SC6->C6_QTDVEN 
					Replace C0_QTDORIG With SC6->C6_QTDVEN
				endif
				
				Replace C0_FILIAL With _filres
				Replace C0_NUM With _cNumDoc
				Replace C0_TIPO With 'PD'
				Replace C0_SOLICIT With _cSolicit
				Replace C0_FILRES With _filres
				Replace C0_PRODUTO With SC6->C6_PRODUTO
				Replace C0_LOCAL With SC6->C6_LOCAL				
				Replace C0_VALIDA With MonthSum(date(),1)
				Replace C0_EMISSAO With date()
				Replace C0_DOCRES With SC5->C5_VEND1
				Replace C0_VAPEDID With SC5->C5_NUM
				msunlock()

				dbselectarea("SB2")
				dbsetorder(1)
				dbseek(_filres + SC6->C6_PRODUTO)
				reclock("SB2")
				Replace SB2->B2_RESERVA With SB2->B2_RESERVA + SC6->C6_QTDVEN
				msunlock()

				DbSelectArea("SC6")
				DbSkip()
			enddo
		else
			SC5->C5_VARESER := 'N'
		endif

		// Confirma sequenciais, se houver.
		do while __lSX8
			ConfirmSX8 ()
		enddo

		if len(_aSemEst) > 0
			_msg := 'Não foi possível realizar as reservas para este pedido, pois os seguinte itens estão com saldo insuficiente: ' + chr(13) + chr(10)
			for _x = 1 to len(_aSemEst)
				_msg += Alltrim(_aSemEst[_x][1]) + ' - ' + Alltrim(_aSemEst[_x][2]) + chr(13) + chr(10)
			next
			u_help (_msg)
		endif
	endif
	RestArea( _aArea )
Return(.t.)
*/


// --------------------------------------------------------------------------
// Grava evento quando houver alteracao do pedido.
static function _EvtAlter ()
	local _oEvento := NIL
	_oEvento := ClsEvent():new ()
	_oEvento:CodEven   = "SC5005"
	_oEvento:Texto     = iif (altera, "Alteracao ", iif (inclui, "Inclusao ", " Manutencao ")) + " manual do pedido"
	_oEvento:Cliente   = sc5 -> c5_cliente
	_oEvento:LojaCli   = sc5 -> c5_lojacli
	_oEvento:PedVenda  = sc5 -> c5_num
	_oEvento:Grava ()
return
