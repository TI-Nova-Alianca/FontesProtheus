// Programa...: ZA1
// Autor......: Robert Koch
// Data.......: 03/11/2022
// Descricao..: Funcoes genericas tabela ZA1 (geralmente chamadas via MBrowse)

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Funcoes genericas tabela ZA1 (geralmente chamadas via MBrowse)
// #PalavasChave      #etiquetas #pallets
// #TabelasPrincipais #ZA1
// #Modulos           #PCP #EST

// Historico de alteracoes:
// 10/02/2023 - Robert - Funcao ZA1SD5 passa a tratar a possibilidade de ter
//                       mais de uma etiqueta para o mesmo lote - GLPI 13134.
// 30/03/2023 - Robert - Novos parametros chamada impressao etiq. avulsa.
// 12/04/2023 - Robert - Criadas funcoes ZA1Inc() e ZA1ITOk() para inclusao manual.
//

// --------------------------------------------------------------------------
// Recebe chamada feita via botao 'imprime avulsa' do MBrowse do ZA1
user function ZA1ImpAv () 
	static _sImpr := '  '  // Static para que lembre da selecao anterior.

	_sImpr = U_Get ("Selecione impressora", 'C', 2, '', 'ZX549', _sImpr, .f., '.t.')
	U_Log2 ('debug', '[' + procname () + ']_sImpr >>' + cvaltochar (_sImpr) + '<<')
	if ! empty (_sImpr)
		// Instancia objeto para impressao.
		_oEtiq := ClsEtiq ():New (ZA1->ZA1_CODIGO)
		_oEtiq:Imprime (_sImpr)
	else
		u_help ("Impressao cancelada.")
	endif
return


// --------------------------------------------------------------------------
// Inclusao manual (via tela) de uma etiqueta.
user function ZA1Inc ()
	local _nLock    := 0
	local _lRetIncl := .F.
	private altera  := .F.
	private inclui  := .T.
	private aGets   := {}
	private aTela   := {}

	// Verifica se o usuario tem liberacao.
	if ! U_ZZUVL ('073', __cUserID, .T.)
		return
	endif
	if ! U_ZZUVL ('074', __cUserID, .T.)
		return
	endif

	// Controla semaforo, por que a numeracao deve ser unica.
	_nLock := U_Semaforo ('GeraNumeroZA1', .T.)  // Usar a mesma chave em todas as chamadas!
	if _nLock == 0
		u_help ("Bloqueio de semaforo na geracao de numero de etiqueta.",, .t.)
	else
		// Cria variáveis 'M->' aqui para serem vistas depois da inclusão.
		RegToMemory ("ZA1", inclui, inclui)

		// Na validacao da inclusao do registro, faz os tratamentos necessarios.
		axinclui ("ZA1", za1 -> (recno ()), 3, NIL, NIL, NIL, "U_ZA1ITOK ()")
	endif

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif
return _lRetIncl


// --------------------------------------------------------------------------
// Valida a inclusao (via tela) de uma etiqueta e gera dados adicionais.
user function ZA1ITOk ()
	local _lRetIncl := .F.
	local _oEtiq    := NIL
	_oEtiq := ClsEtiq():New ()
	_oEtiq:GeraAtrib ('M')  // Gerar a partir das variaveis M-> da tela.
	//u_logobj (_oEtiq, .t., .f.)
	_lRetIncl = _oEtiq:PodeIncl ()
	if ! _lRetIncl
		u_help ("Inclusao de etiq.nao permitida." + _oEtiq:UltMsg,, .t.)
	endif
	//U_Log2 ('debug', '[' + procname () + ']retornando ' + cvaltochar (_lRetIncl))
return _lRetIncl


// --------------------------------------------------------------------------
// Recebe chamadas feitas pelos botoes do MTA390MNU.
user function ZA1SD5 (_sQueFazer)
	local _aAreaAnt := U_ML_SRArea ()
	local _oEtiq    := CLsEtiq ():New ()
	local _sImpr    := space (2)
	local _oSQL     := NIL
	local _xRet     := NIL
	local _sEtiq    := ''
	local _aEtiq    := {}
	local _nEtiq    := 0
	local _sMsgMult := ''
	local _nQtMult  := 0
	local _sEtiqIni := ''
	local _sEtiqFim := ''

	if _sQueFazer == 'G'  // Gerar nova
		_xRet = ''
		_sEtiq = U_ZA1SD5 ('B')
		if ! empty (_sEtiq)
			u_help ("Ja existem etiquetas geradas para este registro.",, .t.)
		else
			_sMsgMult := "Preciso gerar etiquetas para "
			_sMsgMult += cvaltochar (sd5 -> d5_quant)
			_sMsgMult += ' ' + fBuscaCpo ("SB1", 1, xfilial ("SB1") + sd5 -> d5_produto, "B1_UM")
			_sMsgMult += ' do item ' + alltrim (sd5 -> d5_produto) + ' - ' + alltrim (fBuscaCpo ("SB1", 1, xfilial ("SB1") + sd5 -> d5_produto, "B1_DESC"))
			_sMsgMult += '. Caso deseje dividir em mais de uma etiqueta, informe agora a quantidade por etiqueta.'
			_nQtMult = U_Get (_sMsgMult, 'N', 12, '9999999.9999', '', _nQtMult, .f., '.t.')
			if _nQtMult == NIL  // Usuario cancelou
				u_help ("Geracao de etiquetas cancelada.",, .t.)
			else
				_nEtiq = 0
				do while _nEtiq < sd5 -> d5_quant
					aadd (_aEtiq, min (_nQtMult, sd5 -> d5_quant - _nEtiq))
					_nEtiq += _aEtiq [len (_aEtiq)]
					U_Log2 ('debug', _aEtiq)
				enddo
				if U_MsgYesNo ("Confirma a geracao de " + cvaltochar (len (_aEtiq)) + " etiquetas?")
					for _nEtiq = 1 to len (_aEtiq)
						if ! _oEtiq:NovaPorSD5 (sd5 -> d5_produto, sd5 -> d5_LoteCtl, sd5 -> d5_local, sd5 -> d5_NumSeq, _aEtiq [_nEtiq], len (_aEtiq), _nEtiq)
							exit
						else
							_sEtiqIni = iif (empty (_sEtiqIni), _oEtiq:Codigo, _sEtiqIni)
							_sEtiqFim = _oEtiq:Codigo
						endif
					//	if ! empty (_oEtiq:Codigo)
					//		_xRet = _oEtiq:Codigo  // Retorna o codigo da etiqueta gerada
					//		if u_msgyesno ("Etiqueta gerada: " + _oEtiq:Codigo + ". Deseja imprimi-la?")
					//			U_ZA1SD5 ('I')
					//		endif
					//	endif
					next
					u_help ("Etiqueta(s) gerada (s): de '" + _sEtiqIni + "' a '" + _sEtiqFim + "'.")
				endif
			endif
		endif
	elseif _sQueFazer == 'I'  // Imprimir
		_xRet = .t.
		_sEtiq = U_ZA1SD5 ('B')
		if empty (_sEtiq)
			u_help ("Nao encontrei etiquetas geradas para este registro (ou ja foram inutilizadas).",, .t.)
		else
			_aEtiq = U_SeparaCpo (_sEtiq, ',')
			if len (_aEtiq) > 0 .and. U_MsgYesNo ("Encontrei " + cvaltochar (len (_aEtiq)) + " etiquetas. Confirma impressao?")
				_sImpr = U_Get ("Selecione impressora", 'C', 2, '', 'ZX549', _sImpr, .f., '.t.')
				if ! empty (_sImpr)
					for _nEtiq = 1 to len (_aEtiq)
						_oEtiq := ClsEtiq ():New (_aEtiq [_nEtiq])
						if ! _oEtiq:Imprime (_sImpr)
							_xRet = .F.
							u_help (_oEtiq:UltMsg,, .t.)
							exit
						endif
					next
				endif
			endif
		endif
	
	elseif _sQueFazer == 'B'  // Buscar codigo das etiquetas geradas para este registro do SD5 (se existirem)
		_xRet = ''
		if sd5 -> d5_origlan == 'MAN'  // Ateh o momento, geram-se etiquetas somente para origem=MAN
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT STRING_AGG (ZA1_CODIGO, ',')"
			_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZA1") + " ZA1"
			_oSQL:_sQuery += " WHERE ZA1.D_E_L_E_T_  = ''"
			_oSQL:_sQuery +=   " AND ZA1.ZA1_FILIAL  = '" + xfilial ("ZA1")   + "'"
			_oSQL:_sQuery +=   " AND ZA1.ZA1_PROD    = '" + sd5 -> d5_produto + "'"
			_oSQL:_sQuery +=   " AND ZA1.ZA1_D5NSEQ  = '" + sd5 -> d5_numseq  + "'"
			_oSQL:_sQuery +=   " AND ZA1.ZA1_APONT  != 'I'"  // Se estiver inutilizada, ok
			_oSQL:Log ('[' + procname () + ']')
			_xRet = alltrim (_oSQL:RetQry (1, .f.))
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return _xRet
