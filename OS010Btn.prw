// Programa...: OS010Btn
// Autor......: Robert Koch
// Data.......: 15/04/2008
// Cliente....: Alianca
// Descricao..: Cria botoes na enchoicebar da tela de manutencao de tabelas de precos (OMSA010)
//
// Historico de alteracoes:
// 24/11/2008 - Robert - Criado botao para releitura de custos.
//

// --------------------------------------------------------------------------
User Function OS010Btn ()
	local _aRet := {}
	aadd (_aRet,{"VENDEDOR", {|| U_SZYVen (m->da0_codtab, .T.)}, "Vendedores",     "Vend"})
	if altera
		aadd (_aRet,{"reload",   {|| U_VA_DA1AC ()},                 "Atualiza custo", "Custo"})
	endif
return _aRet
