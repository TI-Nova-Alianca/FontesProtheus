// Programa...: F100BROW
// Autor......: Catia Cardoso	
// Data.......: 05/05/2015
// Descricao..: Cria botoes na tela de extrato bancario
//
// Historico de alteracoes:
// 13/05/2015 - Catia  - Prevista mais uma rotina de usuarios 043 - usuarios de conciliacao contabil
// 02/06/2015 - Catia  - Criada opcao disponibilidade - que permite alterar data de disponibilidade
// 15/08/2019 - Robert - Desabilitado botao 'corrige NCC' por que adequamos o processo (GLPI 6152)
//

// --------------------------------------------------------------------------
User Function F100BROW ()
	local _aRet := {}
	AAdd( aRotina, { "Exclui Despesa" , "U_VA_DESP()"    , 0, 1 } )
//	AAdd( aRotina, { "Corrige NCC"    , "U_VA_ALTNCC()"  , 0, 1 } )
	AAdd( aRotina, { "Disponibilidade", "U_VA_ALTDISPO()", 0, 1 } )
return _aRet



// --------------------------------------------------------------------------
user function VA_DESP()
	local _lRet := .T.
	if ! U_ZZUVL ('036', __cUserId, .F.) .and. ! U_ZZUVL ('043', __cUserId, .F.)
		u_help("Usuário sem permissão para executar essa rotina.")
		return
	endif
	// testa se eh uma despesa financeira
	if !'DESP BANC'$ se5 -> e5_naturez
		u_help("Lançamento não refere-se a uma despesa financeira.")
		_lRet = .F.		
	endif
	// testa parametro do financeiro
	if _lRet 
		_wdatafin = GetMv ("MV_DATAFIN")
		if dtos(ddatabase) < dtos(_wdatafin)
			u_help("Não são permitidas movimentações financeiras com datas menores que a data limite de movimentações no financeiro")
			_lRet = .F.
		endif
	endif
	if _lRet		
		if dtos(se5 -> e5_data) < dtos(_wdatafin)
			u_help("Data do lançamento é anterior a data limite de movimentações financeiras. Exclusão não permitida.")
			_lRet = .F.
		endif
	endif		
	// pede confirmação
	if _lRet
		_lConf = msgnoyes ("Confirma exclusão da despesa financeira ?","Excluir")
		if _lConf
			reclock ("SE5", .F.)
			dbdelete()
			msunlock ()      
		endif
	endif				
return



// --------------------------------------------------------------------------
user function VA_ALTDISPO()
	local _lRet := .T.
	if ! U_ZZUVL ('036', __cUserId, .F.) .and. ! U_ZZUVL ('043', __cUserId, .F.)
		u_help("Usuário sem permissão para executar essa rotina.")
		return
	endif
	// testa parametro do financeiro
	if _lRet 
		_wdatafin = GetMv ("MV_DATAFIN")
		if dtos(ddatabase) < dtos(_wdatafin)
			u_help("Não são permitidas movimentações financeiras com datas menores que a data limite de movimentações no financeiro")
			_lRet = .F.
		endif
	endif
	if _lRet		
		if dtos(se5 -> e5_data) < dtos(_wdatafin)
			u_help("Data do lançamento é anterior a data limite de movimentações financeiras. Alteração não permitida.")
			_lRet = .F.
		endif
	endif		
	// solicita nova data
	if _lRet
		_sOldDispo = se5 -> e5_dtdispo
		_sNewDispo = U_Get ("Data Disponibilidade", "D", 8, "@D", "", _sOldDispo, .F., '.t.')
		
		if dtos(_sNewDispo) < dtos(_wdatafin)
			u_help("Data do lançamento é anterior a data limite de movimentações financeiras. Alteração não permitida.")
			_lRet = .F.
		endif
		if _lRet
			reclock ("SE5", .F.)
				se5->e5_dtdispo = _sNewDispo
			msunlock ()      
		endif
	endif
return



// // --------------------------------------------------------------------------
// //--- roda acerto de saldos - para evitar problemas 
// static function SE8_ACERTA()

// 	Pergunte("FIN210",.F.)
	
// 	mv_par07 := msdate() - 5
	
// 	FINA210(.T.)

// return   
