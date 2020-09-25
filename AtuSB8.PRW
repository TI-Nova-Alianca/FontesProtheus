// Programa...: DestLot
// Autor......: Robert Koch
// Data.......: 17/05/2017
// Descricao..: Abre campos especificos do SB8 para edicao.
//
// Historico de alteracoes:
// 08/03/2019 - Robert - Habilitada edicao do campo B8_VACRSIS.
// 04/03/2020 - Sandra - Inclusão dos campos B8_VALOJA, PRODUTO, LOCAL, DTVALID, SALDO, LOTEFOR, DATA, LOTECTL, CLIFOR, DOC, LOJA, SERIE
//
// --------------------------------------------------------------------------
User Function AtuSB8 ()
	Private cCadastro := "Alteracao de lotes"
	Private cDelFunc  := ".F."
	Private cString   := "SB8"
	Private aRotina   := {}
	
	aadd (aRotina, {"Pesquisar"			,  "AxPesqui"	, 0, 1})
	aadd (aRotina, {"Visualizar"		, "AxVisual"	, 0, 2})
	aadd (aRotina, {"Visualizar"		, "AxVisual"	, 0, 3})
	aadd (aRotina, {"Alterar"   		, "U_AtuSB8A ()", 0, 4})
	aadd (aRotina, {"Utilização do Lote", "U_AtuSB8A ()", 0, 5})
		                       
	dbSelectArea("SB8")
	dbSetOrder(1)	 
	                                	
	mBrowse(6,1,22,75,"SB8") //,,,,,,,,,,,,,,cExprFilTop)
Return
// --------------------------------------------------------------------------
//
User Function AtuSB8A () 
	local _aCampos := {}
	
	aadd (_aCampos, "B8_VADESTI")
	aadd (_aCampos, "B8_VASTVEN")
	aadd (_aCampos, "B8_VACLIEN")
	aadd (_aCampos, "B8_VALOJA")
	aadd (_aCampos, "B8_VACRSIS")
	aadd (_aCampos, "B8_PRODUTO")
	aadd (_aCampos, "B8_LOCAL")
	aadd (_aCampos, "B8_DTVALID")
	aadd (_aCampos, "B8_SALDO")
	aadd (_aCampos, "B8_LOTEFOR")
	aadd (_aCampos, "B8_DATA")
	aadd (_aCampos, "B8_LOTECTL")
	aadd (_aCampos, "B8_CLIFOR")
	aadd (_aCampos, "B8_DOC")
	aadd (_aCampos, "B8_LOJA")
	aadd (_aCampos, "B8_SERIE")
	
	AxAltera ("SB8",SB8->(recno()),4,_aCampos,_aCampos)	
Return
