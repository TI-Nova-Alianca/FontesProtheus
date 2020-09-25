// Programa:   FINA080
// Autor:      Robert Koch
// Data:       12/09/2016
// Descricao:  P.E. generico da baixa manual de contas a pagar.
//             Criado inicialmente para atualizar conta corrente de associados.
// 
// Historico de alteracoes:
// 26/09/2016 - Robert - Grava campo E5_VACHVEX para compatibilidade com versoes anteriores. Ver comentario no local.
// 03/01/2016 - Robert - Metodo AtuSaldo() da conta corrente nao recebe mais o saldo como parametro.
// 14/09/2017 - Robert - Nao grava mais o campo E5_VACHVEX pois agora jah vem do P.E. SE5FI080.
// 26/09/2017 - Robert - Volta a gravar o E5_VACHVEX por que o P.E. SE5FI080 me deixou na mao com tipo NDF.
//

// --------------------------------------------------------------------------
user function fina080 ()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _oCtaCorr := NIL

//	u_logIni ()
//	u_logPCham ()

//	u_log ('SE2:', se2 -> e2_num, se2 -> e2_prefixo, se2 -> e2_parcela, SE2 -> E2_VACHVEX)
	
	// Atualiza saldo da conta corrente de associados, quando for o caso.
	if ! IsInCallStack ("EVALGENERIC")  // Este P.E. eh chamado duas vezes, entao evito a chamada generica.
		if left (se2 -> e2_vachvex, 3) == 'SZI'

			// Grava E5_VACHVEX para compatibilidade com versao original do extrato de conta corrente.
			// Quando a versao nova (sem usar E5_VACHVEX) estiver funcional, poderah ser removido.
			if se5 -> (eof ())  // Situacao que parece ocorrer quando contabiliza off line no FINA080.
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += "SELECT MAX (R_E_C_N_O_)"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("SE5") + " SE5 "
				_oSQL:_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND E5_FILIAL      = '" + se2 -> e2_filial  + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_CLIFOR  = '" + se2 -> e2_fornece + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_LOJA    = '" + se2 -> e2_loja    + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_PREFIXO = '" + se2 -> e2_prefixo + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_NUMERO  = '" + se2 -> e2_num     + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_PARCELA = '" + se2 -> e2_parcela + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_TIPO    = '" + se2 -> e2_tipo    + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_VACHVEX = ''"
	//			_oSQL:Log ()
				_nRegSE5 = _oSQL:RetQry ()
				if _nRegSE5 > 0
					se5 -> (dbgoto (_nRegSE5))
				endif
			endif
			if ! se5 -> (eof ())
				u_log ('Vou atualizar SE5 (chvex contem:', se5 -> e5_vachvex,')')
				//u_log ('SE2:', se2 -> e2_num, se2 -> e2_prefixo, se2 -> e2_parcela, SE2 -> E2_VACHVEX)
				//u_log ('SE5:', se5 -> e5_numero, se5 -> e5_prefixo, se5 -> e5_parcela, se5 -> e5_vachvex, se5 -> e5_seq)
				reclock ("SE5", .F.)
				se5 -> e5_vachvex = se2 -> e2_vachvex
				SE5 -> E5_VAUSER := alltrim(cUserName)
				msunlock ()
				u_log ('Atualizei F5')
			endif
			
			szi -> (dbsetorder (2))  // ZI_FILIAL+ZI_ASSOC+ZI_LOJASSO+ZI_SEQ
			if szi -> (dbseek (xfilial ("SZI") + substr (se2 -> e2_vachvex, 4), .F.))
				_oCtaCorr := ClsCtaCorr ():New (szi -> (recno ()))
				_oCtaCorr:AtuSaldo ()
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
//	u_logFim ()
return
