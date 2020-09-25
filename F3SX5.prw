// Programa:  F3SX5
// Autor:     Robert Koch - TCX021
// Data:      30/05/2008
// Cliente:   Generico
// Descricao: Browse de uma tabela do SX5 para ser chamado via F3.
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
// Historico de alteracoes:
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
User Function F3SX5 (_sTabela)
	local _aOpcoes  := {}
	local _nOpcao   := 0
	local _aAreaAnt := U_ML_SRArea ()
	local _aCampos  := {}

	sx5 -> (dbsetorder (1))
	sx5 -> (dbseek (xfilial ("SX5") + _sTabela, .T.))
	do while ! sx5 -> (eof ()) .and. x5_filial == xfilial ("SX5") .and. x5_tabela == _sTabela
		aadd (_aOpcoes, {sx5 -> X5_CHAVE, sx5 -> X5_DESCRI, sx5 -> X5_DESCSPA, sx5 -> X5_DESCENG, sx5 -> (recno ())})
		sx5 -> (dbskip ())
	enddo

	_aCampos = {}
	aadd (_aCampos, {1, "Chave",      30, ""})
	aadd (_aCampos, {2, "Descricao1", 50, ""})
	aadd (_aCampos, {3, "Descricao2", 50, ""})
	aadd (_aCampos, {4, "Descricao3", 50, ""})

	_nOpcao = u_F3Array (_aOpcoes, "Selecione opcao:", _aCampos, NIL, NIL, "", "", .F.)

	U_ML_SRArea (_aAreaAnt)
	
	// Deixa o SX5 posicionado no registro selecionado.
	if _nOpcao > 0
		sx5 -> (dbgoto (_aOpcoes [_nOpcao, 5]))
	endif
return (_nOpcao > 0)
