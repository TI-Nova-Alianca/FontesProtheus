// Programa:  StQuant
// Autor:     Robert Koch
// Data:      13/11/2021
// Descricao: P.E. no TotvsPDV para validar o codigo do vendedor.
//            Criado inicialmente para popular variavel '_lTumelero' a ser vista por outros P.E.

// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function STQUANT()
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _nQualPrc  := 0
//	local _lFunAssoc := .F.
//	local _lCxFechad := .F.
	local _aRetQtVlr := {0, 0}
	local _aTabPrc   := {}
	local _aCols     := {}

//	U_Log2 ('debug', procname ())
//	U_Log2 ('debug', ParamIXB)
//	U_Log2 ('debug', sa1 -> a1_cod)
//	U_Log2 ('debug', sb1 -> b1_cod)

	// Nao pretendo mexer com a quantidade.
	_aRetQtVlr [1] = PARAMIXB[1]

/* Por enquanto vamos mostrar todas as opcoes
	// Verificar se eh funcionario ou associado
	_lFuncAssoc = .F.
	ai0 -> (dbsetorder (1))  // AI0_FILIAL, AI0_CODCLI, AI0_LOJA, R_E_C_N_O_, D_E_L_E_T_
	if ! ai0 -> (dbseek (xfilial ("AI0") + sa1 -> a1_cod + sa1 -> a1_loja, .F.))
		msgalert ("Cliente '" + sa1 -> a1_cod + '/' + sa1 -> a1_loja + "' nao encontrado na tabela de dados adicionais de clientes (AI0). Impossivel determinar se trata-se de funcionario ou associado.", 'erro')
	else
		if ai0 -> ai0_CliFun == '1' .or. ai0 -> ai0_associ == 'A'  // Eh funcionario ou associado ativo
			_lFunAssoc = .T.
		endif
	endif
*/

/* Por enquanto vamos mostrar todas as opcoes
	// Verifica a quantidade por caixa pra ver se deve ser considerada 'caixa fechada'
	_lCxFechad = .F.
	if empty (sb1 -> b1_codpai)
		msgalert ("Produto '" + alltrim (PARAMIXB[4]) + "' nao tem o codigo pai (em caixa) informado no cadastro. Impossivel verificar se trata-se de venda em caixa fechada.", 'erro')
	else
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + sb1 -> b1_codpai, .F.))
			msgalert ("Nao localizei cadastro do produto '" + alltrim (sb1 -> b1_codpai) + "' informado como produto pai (em caixa) do item '" + alltrim (PARAMIXB[4]) + "' na tabela SB1. Impossivel verificar se trata-se de venda em caixa fechada.", 'erro')
		else
			if empty (sb1 -> b1_qtdemb)
				msgalert ("Nao existe informacao de quantidade por embalagem no cadastro do produto '" + alltrim (sb1 -> b1_codpai) + "' informado como produto pai (em caixa) do item '" + alltrim (PARAMIXB[4]) + "' na tabela SB1. Impossivel verificar se trata-se de venda em caixa fechada.", 'erro')
			else
				U_Log2 ('debug', 'Verificando se a quantidade de venda (' + cvaltochar (PARAMIXB[1]) + ') eh maior ou igual ao b1_qtdemb (' + cvaltochar (sb1 -> b1_qtdemb) + ')')
				if PARAMIXB[1] >= sb1 -> b1_qtdemb
					_lCxFechad = .T.
				endif
			endif
		endif
	endif
	U_Log2 ('debug', '_lCxFechad: ' + cvaltochar (_lCxFechad))
	// Posiciona de volta no produto original da venda.
	sb1 -> (dbsetorder (1))
	sb1 -> (dbseek (xfilial ("SB1") + PARAMIXB[4], .F.))
*/

	// SA1 jah vem posicionado
	U_Log2 ('debug', 'tipo da variavel _lTumelero: ' + type ('_lTumelero'))
	if type ('_lTumelero') == 'L' .and. _lTumelero  // Tumelero (parceiro de vendas).
		//U_Log2 ('debug', '_lTumelero')
		_nQualPrc = 8
	elseif len (alltrim (sa1 -> A1_CGC)) == 14  // Tem CNPJ
		_nQualPrc = 4
	else
		aadd (_aTabPrc, {1, 'Gondola'})
		aadd (_aTabPrc, {2, 'Caixa fechada'})
// ainda nao liberado por que nao sabemos como vai funcionar a integracao --> aadd (_aTabPrc, {3, 'Funcionarios / associados'})
		aadd (_aTabPrc, {5, 'Feirinha'})
		aadd (_aTabPrc, {7, 'Promocoes'})
	endif

	// Se tem opcoes a mostrar para o usuario...
	if len (_aTabPrc) > 0
		aadd (_aCols, {1, 'Tabela', 30, ''})
		aadd (_aCols, {2, 'Descricao', 100, ''})
		_nQualPrc = u_F3Array (_aTabPrc, 'Tabela de precos', _aCols, 400, 300, 'Selecione tabela de precos', '', .F.)
		if _nQualPrc == 0  // Usuario deu ESC ou fechou a tela
			_aRetQtVlr [1] = 0
			_aRetQtVlr [2] = 0
		else
			// Preciso pegar o numero da lista de precos que encontra-se na primeira coluna da array de opcoes mostradas ao usuario.
			_nQualPrc = _aTabPrc [_nQualPrc, 1]
		endif
	endif

	U_Log2 ('debug', 'Tabela de preco a ser usada: ' + cvaltochar (_nQualPrc))

	// Encontra o preco do item na mesma tabela usada no venda assistida.
	if _nQualPrc > 0
		sb0 -> (dbsetorder (1))  // B0_FILIAL, B0_COD, R_E_C_N_O_, D_E_L_E_T_
		if ! sb0 -> (dbseek (xfilial ("SB0") + PARAMIXB[4], .F.))
			msgalert ("Produto '" + alltrim (PARAMIXB[4]) + "' nao encontrado na tabela de precos (SB0).", 'erro')
			_aRetQtVlr [1] = 0
			_aRetQtVlr [2] = 0
		else
			_aRetQtVlr [2] = sb0 -> &('b0_prv' + cvaltochar (_nQualPrc))
		endif
	endif
	U_Log2 ('debug', 'Preco a ser retornado: ' + cvaltochar (_aRetQtVlr [2]))

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
Return _aRetQtVlr
