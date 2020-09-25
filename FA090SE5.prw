// Programa:   FA090SE5
// Autor:      Robert Koch
// Data:       11/10/2012
// Descricao:  P.E. apos gravacao do SE5 na tela FINA090 (baixa automatica de contas a pagar).
//             Criado inicialmente para atualizar conta corrente associados.
// 
// Historico de alteracoes:
// 03/01/2016 - Robert - Ajustes atualizacao SZI.
//

// --------------------------------------------------------------------------
user function FA090SE5 ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	// Atualiza (se for o caso) o arquivo SZI.
	if _lRet
		_AtuSZI ()
	endif

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return _lRet



// --------------------------------------------------------------------------
// Atualiza (se for o caso) o arquivo SZI.
static function _AtuSZI ()
    local _nRegSE5  := 0
    local _oCtaCorr := NIL

	if left (se2 -> e2_vachvex, 3) == "SZI"
		szi -> (dbsetorder (2))  // ZI_FILIAL+ZI_ASSOC+ZI_LOJASSO+ZI_SEQ
		if szi -> (dbseek (xfilial ("SZI") + substr (se2 -> e2_vachvex, 4), .F.))

			// Arquivo SE5 vem, algumas vezes, desposicionado. Robert, 20/12/2016.
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
//			u_log ('reg se5:', _nRegSE5)
			if _nRegSE5 > 0
				se5 -> (dbgoto (_nRegSE5))
//				u_log ('Vou atualizar SE5')
//				u_log ('SE2:', se2 -> e2_num, se2 -> e2_prefixo, se2 -> e2_parcela, SE2 -> E2_VACHVEX)
//				u_log ('SE5:', se5 -> e5_numero, se5 -> e5_prefixo, se5 -> e5_parcela, se5 -> e5_vachvex, se5 -> e5_seq)
				reclock ('SE5', .F.)
				se5 -> e5_vachvex = se2 -> e2_vachvex
				SE5 -> E5_VAUSER   := alltrim(cUserName)
				msunlock ()
			else
				u_log (procname () + ': Nao encontrei SE5')
			endif
				
		
			// Atualiza saldo conta corrente.
			_oCtaCorr := ClsCtaCorr():New (szi -> (recno ()))
			_oCtaCorr:AtuSaldo ()
			
		endif

	endif
return
