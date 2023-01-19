// Programa:   CtbMedio
// Autor:      Robert Koch
// Data:       13/09/2017
// Descricao:  Programa a ser usado no lugar do MATA331 (contabilizacao do custo medio) no menu.

// Historico de alteracoes:
// 04/12/2018 - Robert  - Passa a receber parametro indicando se deve apenas ajustar
//                        o campo CT2_ROTINA, sem abrir interface com usuario.
//                      - Passa a considerar tanto as rotinas MATA330 como MTA330C
//                        na filtragem de registros do CT2.
//                      - Verifica mv_par20 para saber se deve ajustar apenas a filial atual ou todas.
// 
// 26/12/2019 - Claudia - Retirada a chamada para a rotina MATA331(). 
//					      Será executada a rotina padrão pelo menu e executado o CtbMedio pelo P.E. MA331Fim e MA330Fim

// --------------------------------------------------------------------------
User function CtbMedio (_lSoAjuste)
	
	If _lSoAjuste != NIL .and. _lSoAjuste // Chamado nas rotinas MA330Fim e MA331Fim
		ML_CNT2 ()
	EndIf

Return
// --------------------------------------------------------------------------
// Rotina para gravação do campo CT2_ROTINA
Static Function ML_CNT2()
	local _oSQL := NIL
	
	// Muda origem dos lctos para que, ao rodar com opcao de 'contabiliza ambas', nao apague os lctos anteriores de consumo.
	If mv_par12 == 1
		ProcRegua(10)
		Pergunte("MTA330",.F.)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " UPDATE " + RetSqlName("CT2")
		_oSQL:_sQuery +=    " SET CT2_ROTINA = 'CTBA102'"
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		if mv_par20 == 2  // Se estiver rodando o medio apenas da filial atual.
			_oSQL:_sQuery +=    " AND CT2_FILIAL = '" + xFilial("CT2") + "'"
		endif
		_oSQL:_sQuery +=    " AND CT2_DATA   = '" + Dtos(mv_par01) + "'"
		_oSQL:_sQuery +=    " AND CT2_ROTINA IN ('MATA330   ', 'MTA330C   ')"
		_oSQL:Log ()
		if ! _oSQL:Exec ()
			if type ("_oBatch") == 'O'
				_oBatch:Mensagens += 'Erro UPD do CT2: ' + _oSQL:_sQuery
			endif
		endif
	Endif
Return
