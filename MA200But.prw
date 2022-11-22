// Programa:   MA200But
// Autor:      Robert Koch
// Data:       06/08/2015
// Descricao:  P.E. para inclusao de botoes na tela de manutencao de componentes de estruturas.
//             Criado inicialmente para chamar consulta de especificacoes tecnicas do componente.
// 
// Historico de alteracoes:
// 06/10/2015 - Robert - Passa extensao na chamada da visualizacao de especificacoes / imagem do produto.
// 21/11/2022 - Robert - Passa a buscar imagem em formato PNG e nao mais JPG
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
User Function MA200But()
	local _aRet := {}

	aadd (_aRet, {"LANDSCAPE", {|| _Menu ()}, "Especificos"})

Return _aRet



// --------------------------------------------------------------------------
static function _Menu ()
	local _aF3      := {}
	local _nF3      := 0
	local _aCols    := {}
	local _aAmbAnt  := U_SalvaAmb ()
	local _aAreaAnt := U_ML_SRArea ()

	// Colunas para menu de opcoes
	aadd (_aCols, {1, "Opcao",     100, ""})

	// Define opcoes a mostrar
	aadd (_aF3, {"Visualizar especificacoes produto", "Espec_produto"})
	aadd (_aF3, {"Visualizar imagem do produto",      "Imagem_produto"})
	aadd (_aF3, {"Cancelar",                          "Cancelar"})

	_nF3 = U_F3Array (_aF3, procname () + " - Opcoes", _aCols, oMainWnd:nClientWidth / 3, oMainWnd:nClientHeight / 1.5, "", "", .F.)
	do case

	case _nF3 != 0 .and. _aF3 [_nF3, 2] == "Espec_produto"
		U_EspPrd (m->g1_comp, 'PDF')

	case _nF3 != 0 .and. _aF3 [_nF3, 2] == "Imagem_produto"
		U_EspPrd (m->g1_comp, 'PNG')

	endcase

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)

return
