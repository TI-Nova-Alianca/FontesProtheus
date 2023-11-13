// Programa:  VA_XLS40
// Autor:     Robert Koch
// Data:      26/02/2018
// Descricao: Exportacao de planilha com calculo de precos de uvas safra

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Exportacao_para_planilha
// #Descricao         #Gera planilha com precos de uva calculados cfe. safra parametrizada.
// #PalavasChave      #precos_safra
// #TabelasPrincipais #ZX5 #SB1 #SB5
// #Modulos           #COOP

// Historico de alteracoes:
// 21/03/2019 - Robert  - Passa a usar a include VA_INCLU para compatibilidade com retorno da funcao de calculo de precos.
// 22/01/2020 - Robert  - Ajustes para safra 2020
//                      - Possibilidade de gerar tabela MOC da CONAB.
// 05/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25
// 04/01/2021 - Robert  - Tratamentos para safra 2021.
// 14/01/2022 - Robert  - Tratamento para safra 2022.
//                      - Criada opcao de exportar com descricao resumida.
// 26/04/2023 - Robert  - Tratamento para safra 2023.
// 11/11/2023 - Robert  - Tratamento para simulacao nov/20 (GLPI 14483).
//

#include "VA_INCLU.prw"

// --------------------------------------------------------------------------
user function VA_XLS40 (_lAutomat)
	Local cCadastro := "Exportacao de planilha com calculo de precos de uvas safra"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	// Verifica se o usuario tem liberacao para ver valores.
	if ! U_ZZUVL ('051', __cUserID, .F.)//, cEmpAnt, cFilAnt)
		u_help ("Usuario sem liberacao para esta rotina (grupo 051).")
		return
	endif

	u_help ("Sugestao: abrir planilha equivalente de safra anterior e aplicar, na planilha a ser gerada, somente as formatacoes.")

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



// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
	if mv_par01 >= '2021' .and. mv_par03 == 1
		u_help ("A partir da safra 2021 nao se usa mais operacao de 'entrada'. Somente 'compra'.",, .t.)
		_lRet = .F.
	endif
Return _lRet



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
	local _sProdIn   := ''
	local _aGprPrc   := {}
	private aHeader  := {}  // Para simular a exportacao de um GetDados.
	private aCols    := {}  // Para simular a exportacao de um GetDados.

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
	_oSQL:_sQuery := "SELECT F.*"
	_oSQL:_sQuery +=         ", DESCR_BASE DBASE,  DESCR_EM_CONVERSAO      DCONV,  DESCR_BORDADURA      DBORD,  DESCR_ORGANICA      DORG,  DESCR_FINA_CLAS_COMUM      DFINA_CLC,  DESCR_PARA_ESPUMANTE      DESPUM"
	_oSQL:_sQuery +=         ", DESC_RESUM DRBASE, DESC_RESUM_EM_CONVERSAO DRCONV, DESC_RESUM_BORDADURA DRBORD, DESC_RESUM_ORGANICA DRORG, DESC_RESUM_FINA_CLAS_COMUM DRFINA_CLC, DESC_RESUM_PARA_ESPUMANTE DRESPUM"
	_oSQL:_sQuery +=  " FROM VA_VFAMILIAS_UVAS F"

	// Faz um join com a tabela de grupos de precos na intencao de buscar os itens jah ordenados por grupo.
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


	// testes especificos
//	_oSQL:_sQuery +=   " AND COD_BASE IN ('9933','9926','99916','9966')"  // grupo da Lorena


	_oSQL:_sQuery += " ORDER BY ZX5_14.ZX5_14GRUP, F.COD_BASE, F.DESCR_BASE, DESCR_BORDADURA, DESCR_EM_CONVERSAO, DESCR_ORGANICA"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()

	do while ! (_sAliasQ) -> (eof ())
		
		// Comuns: adiciona a variedade base + organicas
		if mv_par02 == 1
			aadd (_aVaried, {(_sAliasQ) -> cod_base, alltrim ((_sAliasQ) -> cod_base) + '-' + alltrim (iif (mv_par05 == 1, (_sAliasQ) -> DBase, (_sAliasQ) -> DRBase))})
			if ! empty ((_sAliasQ) -> cod_em_conversao)
				aadd (_aVaried, {(_sAliasQ) -> cod_em_conversao, alltrim ((_sAliasQ) -> cod_em_conversao) + '-' + alltrim (iif (mv_par05 == 1, (_sAliasQ) -> DConv, (_sAliasQ) -> DRConv))})
			endif
			if ! empty ((_sAliasQ) -> cod_bordadura)
				aadd (_aVaried, {(_sAliasQ) -> cod_bordadura, alltrim ((_sAliasQ) -> cod_bordadura) + '-' + alltrim (iif (mv_par05 == 1, (_sAliasQ) -> DBord, (_sAliasQ) -> DRBord))})
			endif
			if ! empty ((_sAliasQ) -> cod_organica)
				aadd (_aVaried, {(_sAliasQ) -> cod_organica, alltrim ((_sAliasQ) -> cod_organica) + '-' + alltrim (iif (mv_par05 == 1, (_sAliasQ) -> DOrg, (_sAliasQ) -> DROrg))})
			endif
		endif
		
		// Vifineras espaldeira: adiciona a variedade base + espumante
		if mv_par02 == 2
			aadd (_aVaried, {(_sAliasQ) -> cod_base, alltrim ((_sAliasQ) -> cod_base) + '-' + alltrim (iif (mv_par05 == 1, (_sAliasQ) -> DBase, (_sAliasQ) -> DRBase))})
			if ! empty ((_sAliasQ) -> cod_para_espumante)
				aadd (_aVaried, {(_sAliasQ) -> cod_para_espumante, alltrim ((_sAliasQ) -> cod_para_espumante) + '-' + alltrim (iif (mv_par05 == 1, (_sAliasQ) -> DEspum, (_sAliasQ) -> DREspum))})
			endif
		endif

		// Vifineras latadas: adiciona apenas a variedade base (nao temos 'para espumante' na serra)
		if mv_par02 == 3
			aadd (_aVaried, {(_sAliasQ) -> cod_base, alltrim ((_sAliasQ) -> cod_base) + '-' + alltrim (iif (mv_par05 == 1, (_sAliasQ) -> DBase, (_sAliasQ) -> DRBase))})
		endif

		// Vifineras sem classificacao: adiciona apenas a variedade 'SC'
		if mv_par02 == 4
			if ! empty ((_sAliasQ) -> cod_fina_clas_comum)
				aadd (_aVaried, {(_sAliasQ) -> cod_fina_clas_comum, alltrim ((_sAliasQ) -> cod_fina_clas_comum) + '-' + alltrim (iif (mv_par05 == 1, (_sAliasQ) -> DFina_CLC, (_sAliasQ) -> DRFina_CLC))})
			endif
		endif
		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())
	//u_log ('_aVaried:', _aVaried)

	// Varre a array de variedades, buscando os precos de cada uma.
	_aTab = {}
	_aProd = {}
	_aPrecos = {}
	for _nVaried = 1 to len (_aVaried)
		_sProduto = _aVaried [_nVaried, 1]
		_sDescri = _aVaried [_nVaried, 2]
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
		elseif mv_par01 == '2021'
			if mv_par02 == 1
				_aPrecos  = aclone (U_PrcUva21 ('01', _sProduto, 15, 'B', 'L', .T., .F.)[4])
			elseif mv_par02 == 2
				_aPrecos  = aclone (U_PrcUva21 ('03', _sProduto, 15, 'B', 'E', .T., .F.)[4])
			elseif mv_par02 == 3
				_aPrecos  = aclone (U_PrcUva21 ('03', _sProduto, 15, 'B', 'L', .T., .F.)[4])
			elseif mv_par02 == 4
				_aPrecos  = aclone (U_PrcUva21 ('07', _sProduto, 15, 'B', 'L', .T., .F.)[4])
			endif
		elseif mv_par01 == '2022'
			if mv_par02 == 1
				_aPrecos  = aclone (U_PrcUva22 ('01', _sProduto, 15, 'B', 'L', .T., .F.)[4])
			elseif mv_par02 == 2
				_aPrecos  = aclone (U_PrcUva22 ('03', _sProduto, 15, 'B', 'E', .T., .F.)[4])
			elseif mv_par02 == 3
				_aPrecos  = aclone (U_PrcUva22 ('03', _sProduto, 15, 'B', 'L', .T., .F.)[4])
			elseif mv_par02 == 4
				_aPrecos  = aclone (U_PrcUva22 ('07', _sProduto, 15, 'B', 'L', .T., .F.)[4])
			endif
		elseif mv_par01 == '2023'
			if mv_par02 == 1
				_aPrecos  = aclone (U_PrcUva23 ('01', _sProduto, 15, 'B', 'L', .T., .F.)[4])
			elseif mv_par02 == 2
				_aPrecos  = aclone (U_PrcUva23 ('03', _sProduto, 15, 'B', 'E', .T., .F.)[4])
			elseif mv_par02 == 3
				_aPrecos  = aclone (U_PrcUva23 ('03', _sProduto, 15, 'B', 'L', .T., .F.)[4])
			elseif mv_par02 == 4
				_aPrecos  = aclone (U_PrcUva23 ('07', _sProduto, 15, 'B', 'L', .T., .F.)[4])
			endif
		elseif mv_par01 == 'S23A'  // Simulacao nov/20 (GLPI 14483)
			if mv_par02 == 1
				_aPrecos  = aclone (U_PrcUvaS1 ('01', _sProduto, 15, 'B', 'L', .T., .F.)[4])
			elseif mv_par02 == 2
				_aPrecos  = aclone (U_PrcUvaS1 ('03', _sProduto, 15, 'B', 'E', .T., .F.)[4])
			elseif mv_par02 == 3
				_aPrecos  = aclone (U_PrcUvaS1 ('03', _sProduto, 15, 'B', 'L', .T., .F.)[4])
			elseif mv_par02 == 4
				_aPrecos  = aclone (U_PrcUvaS1 ('07', _sProduto, 15, 'B', 'L', .T., .F.)[4])
			endif
		else
			u_help ('Sem tratamento de calculo para a safra informada.')
			exit
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
			//	U_Log2 ('debug', 'Procurando uma coluna para ' + _sDescri)
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
				//	U_Log2 ('debug', 'Encontrei precos compativeis na coluna ' + cvaltochar (_nCol))
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
				//	U_Log2 ('debug', 'Nao encontrei precos compativeis em nenhuma coluna. Criando nova.')
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
	aadd (_aTitulos, afill (array (len (_aProd [1])), ''))  // Linha onde vou escrever o nome da cooperativa
	aadd (_aTitulos, afill (array (len (_aProd [1])), ''))  // Linha onde vou escrever 'Tabela de preco...'
	aadd (_aTitulos, afill (array (len (_aProd [1])), ''))  // Linha onde vou escrever 'Posicao em ...'
	aadd (_aTitulos, afill (array (len (_aProd [1])), ''))  // Linha onde vou tentar colocar os codigos dos grupos da tabela
	_aTitulos [1, 1] = 'Cooperativa Nova Alianca Ltda'
	_aTitulos [2, 1] = 'Tabela preco de ' + iif (mv_par03 == 1, 'entrada', iif (mv_par03 == 2, 'compra', iif (mv_par03 == 3, 'MOC', ''))) + ' - gerada pelo sistema Protheus - para uvas ' + {'comuns', 'finas espaldeira', 'finas latadas', 'finas SC'}[mv_par02] + ' safra ' + mv_par01
	_aTitulos [3, 1] = 'Posicao em ' + dtoc (date ()) + ' - ' + time ()
	_aTitulos [4, 1] = 'Grau'

//	u_log (_aTitulos)
//	u_log (_aProd)

	// Tenta localizar qual grupo da tabela de precos gerou os valores.
	// Prefiro nao pegar direto da tabela e, sim, deixar o calculo rodar para cada variedade.
	// Assim, testo se a funcao estah funcionando e, se aparecer algum produto cujos
	// precos fiquem diferentes ou que nao esteja nos grupos, fica mais facil de visualizar.
	//
	// Nem vou atras disso se for uva fina sem classificacao.
	if mv_par02 != 4 .and. mv_par01 >= '2022'  // Tive essa ideia de Jerico neste ano.
		// Varre cada coluna de produtos e monta uma clausula IN para o SQL com todos os codigos.
		for _nCol = 2 to len (_aTitulos [1])  // A coluna 1 vai conter os graus e nao contem nenhum produto.
			_sProdIn = ''
			for _nProd = 1 to len (_aProd)
			//	u_log ('prod', _nProd)
				_sProdIn += left (_aProd [_nProd, _nCol], at ('-', _aProd [_nProd, _nCol]) - 1)
				_sProdIn += iif (_nProd < len (_aProd), '/', '')
			next
		//	u_log (_sProdIn)

			// Procura algum grupo de precos que contenha todos os produtos desta coluna.
			// Basicamente eh a mesma query do programa de calculo de precos.
			if mv_par01 $ '2022/2023/S23A'  // Espero poder apenas acrescentar aqui as proximas safras
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "SELECT DISTINCT ZX5_13.ZX5_13GRUP, ZX5_13.ZX5_13DESC, ZX5_13.ZX5_13GBAS"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZX5") + " ZX5_13, "
				_oSQL:_sQuery +=             RetSQLName ("ZX5") + " ZX5_14 "
				_oSQL:_sQuery += " WHERE ZX5_13.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND ZX5_13.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
				_oSQL:_sQuery +=   " AND ZX5_13.ZX5_TABELA = '13'"
				if mv_par03 == 3  // Tabela MOC nao diferencia entrada x compra
					_oSQL:_sQuery +=   " AND ZX5_13.ZX5_13GRUP LIKE 'M%'"
				elseif mv_par02 == 1
					_oSQL:_sQuery += " AND ZX5_13.ZX5_13GRUP like '1%'"  // Uvas comuns/americanas
				elseif mv_par02 == 2
					_oSQL:_sQuery += " AND ZX5_13.ZX5_13GRUP like '2%'"  // Viniferas espaldeira
				elseif mv_par02 == 3
					_oSQL:_sQuery += " AND ZX5_13.ZX5_13GRUP like '3%'"  // Viniferas latadas
				else
					_oSQL:_sQuery += " AND ZX5_13.ZX5_13GRUP 'nao quero encontrar nada neste caso'"
				endif
				_oSQL:_sQuery +=   " AND ZX5_13.ZX5_13SAFR = '" + mv_par01 + "'"
				_oSQL:_sQuery +=   " AND ZX5_14.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND ZX5_14.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
				_oSQL:_sQuery +=   " AND ZX5_14.ZX5_TABELA = '14'"
				_oSQL:_sQuery +=   " AND ZX5_14.ZX5_14SAFR = ZX5_13.ZX5_13SAFR"
				_oSQL:_sQuery +=   " AND ZX5_14.ZX5_14GRUP = ZX5_13.ZX5_13GRUP"
				_oSQL:_sQuery +=   " AND ZX5_14.ZX5_14PROD in " + FormatIn (_sProdIn, '/')
	//			_oSQL:Log ()
				_aGprPrc := aclone (_oSQL:Qry2Array (.F., .F.))
				// A intencao eh encontrar somente um grupo.
				if len (_aGprPrc) == 1
		//			U_Log2 ('debug', 'Encontrei o grupo ' + _aGprPrc [1, 1])

					// Insere na array de titulos, que vai mais tarde ser aglutinada na array final de retorno.
					_aTitulos [4, _nCol] = 'Grp.' + alltrim (_aGprPrc [1, 1]) + ' (' + alltrim (_aGprPrc [1, 2]) + ' gb ' + cvaltochar (_aGprPrc [1, 3]) + ')'
				endif
			else
				u_help ("Safra sem tratamento na leitura de grupos de precos",, .t.)
			endif
		next
	endif

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
		u_help ('Itens sem preco definido: ' + _sSemPreco,, .t.)
	endif
	u_aColsXLS (_aResult)
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                                                       Help
	aadd (_aRegsPerg, {01, "Safra                         ", "C", 4,  0,  "",   "      ", {},                                                          ""})
	aadd (_aRegsPerg, {02, "Tipo de lista                 ", "N", 1,  0,  "",   "      ", {'Comuns', 'Finas espaldeira', 'Finas latadas', 'Finas SC'}, ""})
	aadd (_aRegsPerg, {03, "Qual preco                    ", "N", 1,  0,  "",   "      ", {'Entrada', 'Compra', 'MOC'},                                ""})
	aadd (_aRegsPerg, {04, "Somente graus inteiros        ", "N", 1,  0,  "",   "      ", {'Todos com decimais', 'Apenas inteiros'},                   ""})
	aadd (_aRegsPerg, {05, "Nome das variedades           ", "N", 1,  0,  "",   "      ", {'Completa', 'Resumida'},                                    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
