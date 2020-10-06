// Programa...: VA_XLS20
// Autor......: Robert Koch
// Data.......: 08/02/2012
// Descricao..: Exportacao de dados da DAP juridica para planilha.
//
// Historico de alteracoes:
// 26/01/2016 - Robert - Verifica se o usuario tem acesso pela tabela ZZU.
//

// --------------------------------------------------------------------------
User Function VA_XLS20 (_lAutomat)
	Local cCadastro  := "DAP juridica"
	Local aSays      := {}
	Local aButtons   := {}
	Local nOpca      := 0
	Local lPerg      := .F.

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T.)//, cEmpAnt, cFilAnt)
		return
	endif

	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	private _sArqLog := U_NomeLog ()
	Private cPerg    := "VAXLS20"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	U_AvisaTI ('Programa ' + procname () + ', colocado na lista de fuzilamento em 19/08/2015, acaba de ser foi executado por ' + alltrim (cUserName) + '. Reveja sua lista!')

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo gerar uma")
		AADD(aSays,"exportacao de dados da DAP juridica")
		AADD(aSays,"para planilha eletronica.")
		
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return



// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
	
	
	
// --------------------------------------------------------------------------
Static Function _Gera()
	local _oSQL      := NIL
	local _oAssoc    := NIL
	local _aLinVazia := {}
	local _sAliasQ   := ""
	private aHeader  := {}  // Para simular a exportacao de um GetDados.
	private aCols    := {}  // Para simular a exportacao de um GetDados.
	private N        := 0

	procregua (10)
	
	// Busca lista de 'candidatos'.
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery += " SELECT A2_VACORIG, A2_COD, A2_LOJA, A2_NOME,"
	_oSQL:_sQuery +=        " dbo.VA_FORMATA_CGC (A2_CGC) AS A2_CGC,"
	_oSQL:_sQuery +=        " A2_VANRDAP,"
	_oSQL:_sQuery +=        " A2_VAENDAP,"
	_oSQL:_sQuery +=        " A2_VAEMDAP,"
	_oSQL:_sQuery +=        " A2_VASTDAP,"
	_oSQL:_sQuery +=        " A2_VAVLDAP,"
	_oSQL:_sQuery +=        " A2_VAQBDAP"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SA2") + " SA2"
	_oSQL:_sQuery +=  " WHERE SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
	_oSQL:_sQuery +=    " AND SA2.A2_VASTDAP IN ('C', 'S')"
	//
/*	// Se aparece com outra loja (pessoal com mais de 1 inscr. est.), nao me interessa.
	_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT * "
	_oSQL:_sQuery +=                      " FROM " + RetSQLName ("SA2") + " SA2_OUTRA "
	_oSQL:_sQuery +=                     " WHERE SA2_OUTRA.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                       " AND SA2_OUTRA.A2_COD     = SA2.A2_COD"
	_oSQL:_sQuery +=                       " AND SA2_OUTRA.A2_LOJA    < SA2.A2_LOJA)"
*/
	// Se aparece com outro codigo/loja (pessoal com mais de 1 inscr. est.), nao me interessa.
	_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT * "
	_oSQL:_sQuery +=                     " FROM " + RetSQLName ("SA2") + " SA2_OUTRA "
	_oSQL:_sQuery +=                    " WHERE SA2_OUTRA.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                      " AND SA2_OUTRA.A2_CGC     = SA2.A2_CGC"
	_oSQL:_sQuery +=                      " AND SA2_OUTRA.A2_COD + SA2_OUTRA.A2_LOJA < SA2.A2_COD + SA2.A2_LOJA)"

	_oSQL:_sQuery += " ORDER BY A2_VASTDAP, A2_NOME"
	u_log (_oSQL:_squery)
	_sAliasQ = _oSQL:Qry2Trb ()

	if ! (_sAliasQ) -> (eof ())
		procregua ((_sAliasQ) -> (reccount ()))

		aHeader = {}
		aHeader = aclone (U_GeraHead ('SA2', .F., {}, {'A2_VACORIG', 'A2_COD', 'A2_LOJA', 'A2_NOME', 'A2_CGC', 'A2_VANRDAP', 'A2_VASTDAP', 'A2_VAENDAP', 'A2_VAEMDAP', 'A2_VAVLDAP', 'A2_VAQBDAP'}, .T.))
		aadd (aHeader, {'Filiacao',   'DTENTRADA',  '', 8,  0,  '', '', 'D'})
		_aLinVazia = U_LinVazia (aHeader)

		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
			incproc ((_sAliasQ) -> a2_nome)

			// Instancia associado para verificacoes posteriores.
			_oAssoc := ClsAssoc():New ((_sAliasQ) -> a2_cod, (_sAliasQ) -> a2_loja)

			// Gera dados no aCols
			aadd (aCols, aclone (_aLinVazia))
			N = len (aCols)
			GDFieldPut ('A2_VACORIG', alltrim ((_sAliasQ) -> a2_vacorig))
			GDFieldPut ('A2_COD',     alltrim ((_sAliasQ) -> a2_cod))
			GDFieldPut ('A2_LOJA',    alltrim ((_sAliasQ) -> a2_loja))
			GDFieldPut ('A2_NOME',    alltrim ((_sAliasQ) -> a2_nome))
			GDFieldPut ('A2_CGC',     alltrim ((_sAliasQ) -> a2_cgc))
			GDFieldPut ('A2_VASTDAP', alltrim (x3combo ('A2_VASTDAP', (_sAliasQ) -> a2_vastdap)))
			GDFieldPut ('A2_VANRDAP', alltrim ((_sAliasQ) -> a2_vanrdap))
			GDFieldPut ('A2_VAENDAP', alltrim ((_sAliasQ) -> a2_vaendap))
			GDFieldPut ('A2_VAEMDAP', stod (alltrim ((_sAliasQ) -> a2_vaemdap)))
			GDFieldPut ('A2_VAVLDAP', stod (alltrim ((_sAliasQ) -> a2_vavldap)))
			GDFieldPut ('A2_VAQBDAP', alltrim (x3combo ('A2_VAQBDAP', (_sAliasQ) -> a2_vaqbdap)))
			GDFieldPut ('DTENTRADA',  _oAssoc:DtEntrada (mv_par01))

			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())
		dbselectarea ("SA2")

		incproc ("Gerando arquivo de exportacao")
		processa ({ || U_AcolsXLS (aCols, .T.)})
	else
		u_help ("Nao ha dados gerados.")
	endif

return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                           Help
	aadd (_aRegsPerg, {01, "Data referencia (emissao DAP) ", "D", 8,  0,  "",   "      ", {},                              ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
