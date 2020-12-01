// Programa...: VA_RUSCF
// Autor......: Robert Koch
// Data.......: 01/07/2020
// Descricao..: Calcula e retorna o frete (a pagar posteriormente ao associado) sobre a carga de safra.
//              O pagamento de frete jah existe ha alguns anos, mas era calculado sempre em programas especificos.
//
// Historico de alteracoes:
//

// ------------------------------------------------------------------------------------
User Function va_rusCF (_lRegrav)
	local _lContinua := .T.
	local _oSQL      := NIL
	local _lDeveCalc := .F.
	local _nFrtItem  := 0
	local _lFrtSafOK := .T.
	local _oAssoc    := NIL

	// Nao permite duas sessoes alterando a mesma carga. Usa a funcao SoftLock para que mostre a mensagem 'registro em uso por fulano'
	if _lContinua
		softlock ("SZE")
	endif

	if _lContinua .and. sze -> ze_status == "C"
		u_help ("Carga cancelada.")
		_lContinua = .F.
	endif
	if _lContinua .and. sze -> ze_status == "D"
		u_help ("Carga redirecionada.")
		_lContinua = .F.
	endif
	if _lContinua .and. sze -> ze_status == "1" .and. sze -> ze_aglutin != 'D'
		u_help ("Falta segunda pesagem")
		_lContinua = .F.
	endif
	if _lContinua .and. sze -> ze_aglutin == "O"
		u_help ("Carga aglutinada em outra.")
		_lContinua = .F.
	endif

	// Somente calcula frete para associados.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT dbo.VA_FTIPO_FORNECEDOR_UVA ('" + sze -> ze_assoc   + "'"
		_oSQL:_sQuery +=                                   ", '" + sze -> ze_lojasso + "'"
		_oSQL:_sQuery +=                                   ", '" + dtos (sze -> ze_data) + "')"
		if ! alltrim (_oSQL:RetQry (1, .F.)) $ 'ASSOCIADO/EX ASSOCIADO'
			u_log2 ('info', 'Fornecedor ' + sze -> ze_assoc + '/' + sze -> ze_lojasso + ' nao eh associado nem ex associado nesta data. Nao deve calcular frete.')
			_lDeveCalc = .F.
		else
			_lDeveCalc = .T.
			_oAssoc := ClsAssoc():New (sze -> ze_assoc, sze -> ze_lojasso)
		endif
	endif

	if _lContinua
		sb1 -> (dbsetorder (1))
		szf -> (dbsetorder (1))  // filial + safra + carga + item
		szf -> (dbseek (sze -> ze_filial + sze -> ze_safra + sze -> ze_carga, .T.))
		do while _lContinua ;
			.and. ! szf -> (eof ()) ;
			.and. szf -> zf_filial == sze -> ze_filial ;
			.and. szf -> zf_safra  == sze -> ze_safra ;
			.and. szf -> zf_carga  == sze -> ze_carga

			if ! sb1 -> (dbseek (xfilial ("SB1") + szf -> zf_produto, .F.))
				u_help ("Produto nao cadastrado: " + szf -> zf_produto,, .t.)
				_lContinua = .F.
				_lFrtSafOK = .F.
				exit
			endif

			if _lDeveCalc
				u_log2 ('debug', 'Filial: ' + sze -> ze_filial + ' Safra: ' + sze -> ze_safra + ' Carga:' + sze -> ze_carga + ' Variedade: ' + alltrim (fbuscacpo ('SB1', 1, xfilial ("SB1") + szf -> zf_produto, 'B1_DESC')) + ' Associado: ' + sze -> ze_assoc + '-' + alltrim (fbuscacpo ('SA2', 1, xfilial ("SA2") + sze -> ze_assoc + sze -> ze_lojasso, 'A2_NOME')))
				if sze -> ze_safra == '2020'
					_nFrtItem = U_FrtSaf20 (_oAssoc:Nucleo, szf -> zf_cadviti, sze -> ze_filial, szf -> zf_peso, sb1 -> b1_vacor)
				else
					_nFrtItem = 0
					u_help ("[" + procname () + "] Sem tratamento de calculo de frete para esta safra.",, .t.)
					_lContinua = .F.
					_lFrtSafOK = .F.
				endif
			else
				_nFrtItem = 0
			endif

			// Posso estar executando para regravar, ou apenas para simulacoes.
			if _lRegrav
				if _nFrtItem >= 0  // maior ou igual por que posso estar recalculando, e no recalculo gerou zero.
					reclock ("SZF", .F.)
					szf -> zf_valfret = _nFrtItem
					msunlock ()
				endif
			else
				u_log2 (iif (szf -> zf_valfret == _nFrtItem, 'info', 'aviso'), 'Carga ' + szf -> zf_carga + ' Prod.' + alltrim (szf -> zf_produto) + ' Frete simulado: ' + transform (_nFrtItem, '@E 999,999.99') + '   Valor atual: ' + transform (szf -> zf_valfret, '@E 999,999.99'))
			endif
			szf -> (dbskip ())
		enddo
	endif
return _lFrtSafOK
