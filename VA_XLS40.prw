// Programa:  VA_XLS40
// Autor:     Robert Koch
// Data:      26/02/2018
// Descricao: Exportacao de planilha com calculo de precos de uvas safra
//
// Historico de alteracoes:
// 21/03/2019 - Robert - Passa a usar a include VA_INCLU para compatibilidade com retorno da funcao de calculo de precos.
// 22/01/2020 - Robert - Ajustes para safra 2020
//                     - Possibilidade de gerar tabela MOC da CONAB.
// 05/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25
//
#include "VA_INCLU.prw"
//
// --------------------------------------------------------------------------
user function VA_XLS40 (_lAutomat)
	Local cCadastro := "Exportacao de planilha com calculo de precos de uvas safra"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	// Verifica se o usuario tem liberacao para ver valores.
	if ! U_ZZUVL ('051', __cUserID, .F., cEmpAnt, cFilAnt)
		u_help ("Usuario sem liberacao para esta rotina (grupo 051).")
		return
	endif

	Private cPerg   := "VAXLS40"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo gerar uma")
		AADD(aSays,"exportacao de planilha de precos de uvas para safra")
		
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return
//
// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
//
// --------------------------------------------------------------------------
Static Function _Gera()
	local _oSQL      := NIL
	local _sAliasQ   := NIL
	local _aVaried   := {}
	local _nVaried   := 0
	local _aTab      := {}
	local _aProd     := {}
	local _sProduto  := ''
	local _sDescri   := ''
	local _aPrecos   := {}
	local _aAux      := {}
	local _aTitulos  := {}
	local _aResult   := {}
	local _lProdOK   := .F.
	local _sSemPreco := ''
	local _nPreco	 := 0
	local _nCol		 := 0
	local _nProd	 := 0
	local _nTab		 := 0
	local _nPosPreco := 0
	private aHeader  := {}  // Para simular a exportacao de um GetDados.
	private aCols    := {}  // Para simular a exportacao de um GetDados.
	//u_logId ()

	// Posicao (na array retornada pela funcao de calculo de precos) relativa ao tipo de preco solicitado.
	if mv_par03 == 1
		_nPosPreco = .PrcUvaColPrcEntrada
	elseif mv_par03 == 2
		_nPosPreco = .PrcUvaColPrcCompra
	elseif mv_par03 == 3
		_nPosPreco = .PrcUvaColPrcMOC
	endif

	_sSemPreco := ''
	
	// Monta lista de variedades a serem listadas
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT *"
	_oSQL:_sQuery +=  " FROM VA_VFAMILIAS_UVAS F"
	_oSQL:_sQuery +=       " LEFT JOIN " + RetSQLName ("ZX5") + " ZX5_14 "
	_oSQL:_sQuery +=            " ON (ZX5_14.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=            " AND ZX5_14.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
	_oSQL:_sQuery +=            " AND ZX5_14.ZX5_TABELA = '14'"
	_oSQL:_sQuery +=            " AND ZX5_14.ZX5_14SAFR = '" + mv_par01 + "'"
	if mv_par02 == 1
		_oSQL:_sQuery +=        " AND ZX5_14.ZX5_14GRUP like '1%'"  // Lista comuns
	elseif mv_par02 == 2
		_oSQL:_sQuery +=        " AND ZX5_14.ZX5_14GRUP like '2%'"  // Lista finas espaldeira
	elseif mv_par02 == 3
		_oSQL:_sQuery +=        " AND ZX5_14.ZX5_14GRUP like '3%'"  // Lista finas latadas
	endif
	_oSQL:_sQuery +=            " AND ZX5_14.ZX5_14PROD = F.COD_BASE)"
	_oSQL:_sQuery += " WHERE FINA_COMUM = '" + iif (mv_par02 == 1, 'C', 'F') + "'"
	_oSQL:_sQuery +=   " AND COD_BASE NOT IN ('2684','9869','9930')"  // Desconsidera 'uva moida' e uvas de terceiros
	_oSQL:_sQuery += " ORDER BY ZX5_14.ZX5_14GRUP, F.COD_BASE, F.DESCR_BASE, DESCR_BORDADURA, DESCR_EM_CONVERSAO, DESCR_ORGANICA"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	
	do while ! (_sAliasQ) -> (eof ())
		
		// Comuns: adiciona a variedade base + organicas
		if mv_par02 == 1
			aadd (_aVaried, {(_sAliasQ) -> cod_base, alltrim ((_sAliasQ) -> cod_base) + '-' + alltrim ((_sAliasQ) -> descr_base)})
			if ! empty ((_sAliasQ) -> cod_em_conversao)
				aadd (_aVaried, {(_sAliasQ) -> cod_em_conversao, alltrim ((_sAliasQ) -> cod_em_conversao) + '-' + alltrim ((_sAliasQ) -> descr_em_conversao)})
			endif
			if ! empty ((_sAliasQ) -> cod_bordadura)
				aadd (_aVaried, {(_sAliasQ) -> cod_bordadura, alltrim ((_sAliasQ) -> cod_bordadura) + '-' + alltrim ((_sAliasQ) -> descr_bordadura)})
			endif
			if ! empty ((_sAliasQ) -> cod_organica)
				aadd (_aVaried, {(_sAliasQ) -> cod_organica, alltrim ((_sAliasQ) -> cod_organica) + '-' + alltrim ((_sAliasQ) -> descr_organica)})
			endif
		endif
		
		// Vifineras espaldeira: adiciona a variedade base + espumante
		if mv_par02 == 2
			aadd (_aVaried, {(_sAliasQ) -> cod_base, alltrim ((_sAliasQ) -> cod_base) + '-' + alltrim ((_sAliasQ) -> descr_base)})
			if ! empty ((_sAliasQ) -> cod_para_espumante)
				aadd (_aVaried, {(_sAliasQ) -> cod_para_espumante, alltrim ((_sAliasQ) -> cod_para_espumante) + '-' + alltrim ((_sAliasQ) -> descr_para_espumante)})
			endif
		endif

		// Vifineras latadas: adiciona apenas a variedade base (nao temos 'para espumante' na serra)
		if mv_par02 == 3
			aadd (_aVaried, {(_sAliasQ) -> cod_base, alltrim ((_sAliasQ) -> cod_base) + '-' + alltrim ((_sAliasQ) -> descr_base)})
		endif

		// Vifineras sem classificacao: adiciona apenas a variedade 'SC'
		if mv_par02 == 4
			if ! empty ((_sAliasQ) -> cod_fina_clas_comum)
				aadd (_aVaried, {(_sAliasQ) -> cod_fina_clas_comum, alltrim ((_sAliasQ) -> cod_fina_clas_comum) + '-' + alltrim ((_sAliasQ) -> descr_fina_clas_comum)})
			endif
		endif
		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())
	//u_log ('_aVaried:', _aVaried)

	// Varre a array de variedades, buscando os precos de daca uma.
	_aTab = {}
	_aProd = {}
	_aPrecos = {}
	for _nVaried = 1 to len (_aVaried)
		_sProduto = _aVaried [_nVaried, 1]
		_sDescri = _aVaried [_nVaried, 2]
		//u_logIni (_sDescri)
		if mv_par01 == '2019'
			if mv_par02 == 1
				_aPrecos  = aclone (U_PrcUva19 ('01', _sProduto, 15, 'B', 'L', .T.)[4])
			elseif mv_par02 == 2
				_aPrecos  = aclone (U_PrcUva19 ('03', _sProduto, 15, 'B', 'E', .T.)[4])
			elseif mv_par02 == 3
				_aPrecos  = aclone (U_PrcUva19 ('03', _sProduto, 15, 'B', 'L', .T.)[4])
			elseif mv_par02 == 4
				_aPrecos  = aclone (U_PrcUva19 ('07', _sProduto, 15, 'B', 'L', .T.)[4])
			endif
		elseif mv_par01 == '2020'
			if mv_par02 == 1
				_aPrecos  = aclone (U_PrcUva20 ('01', _sProduto, 15, 'B', 'L', .T.)[4])
			elseif mv_par02 == 2
				_aPrecos  = aclone (U_PrcUva20 ('03', _sProduto, 15, 'B', 'E', .T.)[4])
			elseif mv_par02 == 3
				_aPrecos  = aclone (U_PrcUva20 ('03', _sProduto, 15, 'B', 'L', .T.)[4])
			elseif mv_par02 == 4
				_aPrecos  = aclone (U_PrcUva20 ('07', _sProduto, 15, 'B', 'L', .T.)[4])
			endif
		else
			u_help ('Sem tratamento para a safra informada.')
		endif
		//u_log (_aPrecos)

		// Verifica se deve deixar apenas graus inteiros.
		_aAux = {}
		for _nPreco = 1 to len (_aPrecos)
			if mv_par04 == 1 .or. _aPrecos [_nPreco, 1] == int (_aPrecos [_nPreco, 1])
				aadd (_aAux, aclone (_aPrecos [_nPreco]))
			endif
		next
		_aPrecos = aclone (_aAux)
		//u_log ('_aPrecos:', _aPrecos)
		
		// Gera arrays (uma de produtos e uma de precos) agrupando em colunas conforme os precos forem iguais.
		// Nao gera simplesmente pelos grupos do ZX5 por que quero ter certeza de que os precos ficaram iguais.
		// Se alguma variedade retornar diferente, vai aparecer em coluna separada.
		//u_log ('vou pegar preco na coluna', _nPosPreco)
		if len (_aPrecos) > 0
		
			// Cria coluna para a primeira variedade
			if len (_aTab) == 0
				for _nPreco = 1 to len (_aPrecos)
					aadd (_aTab, {_aPrecos [_nPreco, 1], _aPrecos [_nPreco, _nPosPreco]})
				next
				aadd (_aProd, {'', _sDescri})
			else
				// Verifica se os precos se encaixam em alguma coluna ja presente
				_lIgual = .F.
				for _nCol = 2 to len (_aTab [1])  // primeira coluna = grau
					_lIgual = .T.
					for _nPreco = 1 to len (_aPrecos)
						if _aPrecos [_nPreco, _nPosPreco] != _aTab [_nPreco, _nCol]
							_lIgual = .F.
							exit
						endif
					next
					if _lIgual
						exit
					endif
				next
				
				// Precos estao iguais. Posso vincular a variedade a esta coluna da array.
				if _lIgual
					
					// Acrescenta descricao da variedade `a array de produtos referente a esta coluna.
					_lProdOK = .F.
					for _nProd = 1 to len (_aProd)
						if empty (_aProd [_nProd, _nCol])  // Cria linha apenas se necessario
							_aProd [_nProd, _nCol] = _sDescri
							_lProdOK = .T.
							exit
						endif
					next
					if ! _lProdOK
						aadd (_aProd, afill (array (len (_aProd [1])), ''))
						_aProd [len (_aProd), _nCol] = _sDescri
					endif
				
				// Nao encontrei nenhuma coluna (entre os precos jah existentes) que fosse igual aos precos desta variedade.
				else
					// Insere nova coluna
					for _nProd = 1 to len (_aProd)
						aadd (_aProd [_nProd], iif (_nProd == 1, _sDescri, ''))
					next
					for _nPreco = 1 to len (_aPrecos)
						aadd (_aTab [_nPreco], _aPrecos [_nPreco, _nPosPreco])
					next
				endif
			endif
		else
			// Acumula variedade na lista de problemas.
			_sSemPreco += iif (empty (_sSemPreco), '', ', ') + _sDescri
		endif
		//u_logFim (_sDescri)
	next
	
	// Cria array para linhas iniciais de titulo na planilha
	_aTitulos = {}
	aadd (_aTitulos, afill (array (len (_aProd [1])), ''))
	aadd (_aTitulos, afill (array (len (_aProd [1])), ''))
	aadd (_aTitulos, afill (array (len (_aProd [1])), ''))
	aadd (_aTitulos, afill (array (len (_aProd [1])), ''))
	_aTitulos [1, 1] = 'Cooperativa Nova Alianca Ltda'
	_aTitulos [2, 1] = 'Tabela preco de ' + iif (mv_par03 == 1, 'entrada', iif (mv_par03 == 2, 'compra', iif (mv_par03 == 3, 'MOC', ''))) + ' - gerada pelo sistema Protheus - para uvas ' + {'comuns', 'finas espaldeira', 'finas latadas', 'finas SC'}[mv_par02] + ' safra ' + mv_par01
	_aTitulos [3, 1] = 'Posicao em ' + dtoc (date ())

	// Junta arrays de titulos, produtos e de precos para poder gerar numa mesma planilha.
	_aResult = {}
	for _nProd = 1 to len (_aTitulos)
		aadd (_aResult, (aclone (_aTitulos [_nProd])))
	next
	for _nProd = 1 to len (_aProd)
		aadd (_aResult, (aclone (_aProd [_nProd])))
	next
	for _nTab = 1 to len (_aTab)
		aadd (_aResult, (aclone (_aTab [_nTab])))
	next
	//u_log (_aResult)
	if ! empty (_sSemPreco)
		u_help ('Itens sem preco definido: ' + _sSemPreco)
	endif
	u_aColsXLS (_aResult)
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                                                       Help
	aadd (_aRegsPerg, {01, "Safra                         ", "C", 4,  0,  "",   "      ", {},                                                          ""})
	aadd (_aRegsPerg, {02, "Tipo de lista                 ", "N", 1,  0,  "",   "      ", {'Comuns', 'Finas espaldeira', 'Finas latadas', 'Finas SC'}, ""})
	aadd (_aRegsPerg, {03, "Qual preco                    ", "N", 1,  0,  "",   "      ", {'Entrada', 'Compra', 'MOC'},                                ""})
	aadd (_aRegsPerg, {04, "Somente graus inteiros        ", "N", 1,  0,  "",   "      ", {'Todos com decimais', 'Apenas inteiros'},                   ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
