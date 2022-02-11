// Programa:  StManu
// Autor:     Robert Koch
// Data:      09/02/2022
// Descricao: P.E. no TotvsPDV para adicionar opcoes no menu da tela.
//            Criado inicialmente para definir tabela de precos.

// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function STMenu()
	Local _aRetMPDV := {}
	AAdd (_aRetMPDV, {"Alianca - Tabela precos", "U_STMenuTP ()"})
	//aRet[1][1] - Se Refere: ao Nome no Menu mostrado ao usuário
	//aRet[1][2] - Se Refere: à função que sera executada
Return _aRetMPDV


// --------------------------------------------------------------------------
user function STMenuTP ()
	local _aTabPrc   := {}
	local _aCols     := {}
	public _nTabPrPDV  := 0
	aadd (_aTabPrc, {1, 'Gondola'})
	aadd (_aTabPrc, {2, 'Caixa fechada'})
	aadd (_aTabPrc, {3, 'Funcionarios / associados'})
	aadd (_aTabPrc, {4, 'Venda para CNPJ'})
	aadd (_aTabPrc, {5, 'Feirinha'})
	aadd (_aTabPrc, {7, 'Promocoes'})
	aadd (_aTabPrc, {8, 'Tumelero'})
	aadd (_aCols, {1, 'Tabela', 30, ''})
	aadd (_aCols, {2, 'Descricao', 100, ''})
	_nTabPrPDV = u_F3Array (_aTabPrc, 'Tabela de precos a ser usada A PARTIR DE AGORA', _aCols, 400, 300)
	if _nTabPrPDV > 0
		// Preciso pegar o numero da lista de precos que encontra-se na primeira coluna da array de opcoes mostradas ao usuario.
		_nTabPrPDV = _aTabPrc [_nTabPrPDV, 1]
	endif
	U_Log2 ('debug', '[' + procname () + ']Tabela selecionada pelo usuario: ' + cvaltochar (_nTabPrPDV))

	// Adiciona ao 'log' da sessao, para ajudar o operador a rastrear alguma duvida.
	STFMessage("TabelaPrecos", "STOP", '[' + procname () + ']Selecionada tb.preco ' + cvaltochar (_nTabPrPDV))
return
