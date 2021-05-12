// Programa..: F3SX5
// Autor.....: Robert Koch - TCX021
// Data......: 30/05/2008
// Descricao.: Browse de uma tabela do SX5 para ser chamado via F3.
//
// Como usar: Será necessário incluir 3 registros no SXB:
//            Exemplo usando uma consulta chamada "CJC", que executa um execblock que posiciona o SRA:
//            primeiro registro:
//            xb_alias = "CJC"
//            xb_tipo = "1"
//            xb_seq = "01"
//            xb_coluna = "RE"
//            xb_contem = "SRA"
//             
//            segundo registro:
//            xb_alias = "CJC"
//            xb_tipo = "2"
//            xb_seq = "01"
//            xb_coluna = "01"
//            xb_contem = "U_ML_CJC()"   <-- nome do programa a ser executado
//             
//            terceiro registro:
//            xb_alias = "CJC"
//            xb_tipo = "5"
//            xb_seq = "01"
//            xb_contem = "SRA->RA_MAT"
//             
//            Obs.1: O execblock ja deve deixar o SRA posicionado.
//            Obs.2: O execblock deve retornar .T. para que a consulta seja aceita.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #generico
// #Descricao         #Browse de uma tabela do SX5 para ser chamado via F3
// #PalavasChave      #SX5 #SX5_F3 #F3 
// #TabelasPrincipais #SX5
// #Modulos           #todos
//
// Historico de alteracoes:
// 12/05/2021 - Claudia - Ajustada a chamada SX5 para R27. GLPI: 8825
//
// -----------------------------------------------------------------------------------
#include "rwmake.ch"

User Function F3SX5 (_sTabela)
	local _aOpcoes  := {}
	local _nOpcao   := 0
	local _aAreaAnt := U_ML_SRArea ()
	local _aCampos  := {}
	local _x        := 0

	_oSQL  := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += "     X5_CHAVE"
	_oSQL:_sQuery += "    ,X5_DESCRI"
	_oSQL:_sQuery += "    ,X5_DESCSPA"
	_oSQL:_sQuery += "    ,X5_DESCENG"
	_oSQL:_sQuery += "    ,R_E_C_N_O_"
	_oSQL:_sQuery += " FROM SX5010"
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND X5_FILIAL = '" + xfilial ("SX5") + "'"
	_oSQL:_sQuery += " AND X5_TABELA = '" + _sTabela + "'"
	_aSX5 := aclone (_oSQL:Qry2Array ())	

	For _x := 1 to Len(_aSX5)
		aadd (_aOpcoes, {_aSX5[_X,1], _aSX5[_X,2], _aSX5[_X,3], _aSX5[_X,4], _aSX5[_X,5] })
	Next

	_aCampos = {}
	aadd (_aCampos, {1, "Chave",      30, ""})
	aadd (_aCampos, {2, "Descricao1", 50, ""})
	aadd (_aCampos, {3, "Descricao2", 50, ""})
	aadd (_aCampos, {4, "Descricao3", 50, ""})

	_nOpcao = u_F3Array (_aOpcoes, "Selecione opcao:", _aCampos, NIL, NIL, "", "", .F.)

	U_ML_SRArea (_aAreaAnt)
	
	// Deixa o SX5 posicionado no registro selecionado.
	sx5 -> (dbsetorder (1))
	if _nOpcao > 0
		sx5 -> (dbgoto (_aOpcoes [_nOpcao, 5]))
	endif
return (_nOpcao > 0)
