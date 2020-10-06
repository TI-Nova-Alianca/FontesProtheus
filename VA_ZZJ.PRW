// Programa:   VA_ZZJ
// Autor:      Robert Koch
// Data:       12/11/2012
// Descricao:  Tela de manutencao de cadastro de contas bancarias de associados.
// 
// Historico de alteracoes:
// 26/01/2016 - Robert - Verifica se o usuario tem acesso pela tabela ZZU.
//

// --------------------------------------------------------------------------
user function VA_ZZJ ()
   private aRotina   := {}  // Opcoes do menu
   private cCadastro := "Manutencao de contas bancarias associados."

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('051', __cUserID, .T.)//, cEmpAnt, cFilAnt)
		return
	endif

   aAdd(aRotina, {"Pesquisar"   , "AxPesqui",     0, 1})
   aAdd(aRotina, {"Visualizar"  , "AxVisual",     0, 2})
   aAdd(aRotina, {"Incluir"     , "U_VA_ZZJI ()", 0, 3})
   aAdd(aRotina, {"Alterar"     , "U_VA_ZZJA ()", 0, 4})
   aAdd(aRotina, {"Excluir"     , "AxDeleta",     0, 5})

   dbSelectArea ("ZZJ")
   dbSetOrder (1)
   mBrowse(0, 0, 100, 100, "ZZJ",,,,, 2)
return



// --------------------------------------------------------------------------
// Inclusao
User Function VA_ZZJI ()

	// Variaveis de manipulacao e controle de dados, tela, etc.
	private aHeader    := {}
	private aCols      := {}
	private N          := 1
	private aGets      := {}
	private aTela      := {}

	axinclui ("ZZJ", zzj -> (recno ()), 3, NIL, NIL, NIL, "U_VA_ZZJI1 ()")
return



// --------------------------------------------------------------------------
// Alteracao
User Function VA_ZZJA ()

	// Variaveis de manipulacao e controle de dados, tela, etc.
	private aHeader    := {}
	private aCols      := {}
	private N          := 1
	private aGets      := {}
	private aTela      := {}

	axaltera ("ZZJ", zzj -> (recno ()), 4, NIL, NIL, NIL, NIL, "U_VA_ZZJI1 ()")
return



// --------------------------------------------------------------------------
// Valida inclusao e alteracao.
User Function VA_ZZJI1 ()
	local _lRet     := .T.
	local _oAssoc   := NIL
	local _oSQL     := NIL
	local _aAreaZZJ := {}
	local _aJaExist := {}
	local _nJaExist := 0
	local _sMsg     := ""

	if _lRet
		_lRet = Obrigatorio (aGets, aTela)
	endif

	if _lRet
		_oAssoc := ClsAssoc():New (m->zzj_cbase, m->zzj_lbase)
		if ! _oAssoc:EhSocio ()
			u_help ("Codigo/loja '" + m->zzj_cbase + '/' + m->zzj_lbase + "' nao identificado como associado.")
			_lRet = .F.
		endif
	endif
	if _lRet .and. ! (_oAssoc:CodBase == m->zzj_cbase .and. _oAssoc:LojaBase == m->zzj_lbase)
		u_help ("Codigo/loja '" + m->zzj_cbase + '/' + m->zzj_lbase + "' nao identificado como 'base' de associado. Verifique se o associado tem mais de um cadastro e, nesse caso, informe codigo e loja base.")
		_lRet = .F.
	endif
	if _lRet
		_aAreaZZJ = zzj -> (getarea ())
		zzj -> (dbsetorder (1))
		if zzj -> (dbseek (xfilial ("ZZJ") + m->zzj_cbase + m->zzj_lbase + m->zzj_banco + m->zzj_agenci + m->zzj_conta, .F.))
			u_help ("Banco/agencia/conta ja cadastrado para este codigo/loja base de associado.")
			_lRet = .F.
		endif
		RestArea (_aAreaZZJ)
	endif
	if _lRet
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT ZZJ_CBASE, ZZJ_LBASE, A2_NOME, ZZJ_TITUL "
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZZJ") + " ZZJ, "
		_oSQL:_sQuery +=              RetSQLName ("SA2") + " SA2 "
		_oSQL:_sQuery +=  " WHERE ZZJ.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND ZZJ.ZZJ_FILIAL = '" + xfilial ("ZZJ") + "'"
		_oSQL:_sQuery +=    " AND ZZJ.ZZJ_BANCO  = '" + m->zzj_banco  + "'"
		_oSQL:_sQuery +=    " AND ZZJ.ZZJ_AGENCI = '" + m->zzj_agenci + "'"
		_oSQL:_sQuery +=    " AND ZZJ.ZZJ_CONTA  = '" + m->zzj_conta  + "'"
		_oSQL:_sQuery +=    " AND SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SA2.A2_FILIAL  = '" + xfilial ("ZZJ") + "'"
		_oSQL:_sQuery +=    " AND SA2.A2_COD     = ZZJ.ZZJ_CBASE"
		_oSQL:_sQuery +=    " AND SA2.A2_LOJA    = ZZJ.ZZJ_LBASE"
		_aJaExist = aclone (_oSQL:Qry2Array (.f., .f.))
		if len (_aJaExist) > 0
			if m->zzj_titul == '1'
				_nJaExist = ascan (_aJaExist, {|_aVal| _aVal [4] == '1'})
				if _nJaExist > 0
					u_help ("O associado '" + _aJaExist [_nJaExist, 1] + '/' + _aJaExist [_nJaExist, 1] + ;
					        "' - " + alltrim (_aJaExist [_nJaExist, 3]) + ;
					        " ja' consta como primeiro titular deste banco/agencia/conta.")
					_lRet = .F.
				endif
			else
				_sMsg = ""
				for _nJaExist = 1 to len (_aJaExist)
					_sMsg += _aJaExist [_nJaExist, 1] + '/' + _aJaExist [_nJaExist, 1] + "' - " + alltrim (_aJaExist [_nJaExist, 3]) + " (" + alltrim (X3Combo ("ZZJ_TITUL", _aJaExist [_nJaExist, 4])) + ")" + chr (13) + chr (10)
				next
				_lRet = msgnoyes ("Banco/agencia/conta ja cadastrada para o(s) associado(s) abaixo:" + chr (13) + chr (10) + _sMsg + chr (13) + chr (10) + "Confirma o uso desta conta tambem para o associado " + m->zzj_cbase + '/' + m->zzj_lbase + "?")
			endif
		endif
	endif
return _lRet
