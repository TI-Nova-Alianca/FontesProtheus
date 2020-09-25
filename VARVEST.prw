// Programa:  VARVEST
// Autor:     Marcio - Procdata
// Data:      18/10/2016
// Descrição: programa chamado por gatilho para alterar a revisão da estrutura no cadastro do produto VD.
//
// Historico de alteracoes:
// 15/02/2017 - Robert - Salvar area de trabalho.
//                     - Atualizar B1_LM com conteudo do G5_VALM, quando disponivel.
//

//#include 'protheus.ch'
//#include 'parmtype.ch'

// --------------------------------------------------------------------------
user function VARVEST(revisao)
	local _aAreaAnt := U_ML_SRArea ()
	local _nLM      := 0

	// Posiciona no SB1, para buscar o código que está no campo componente VD.
	DbSelectArea("SB1")
	DbSetOrder(1)
	DbSeek(xFilial()+M->C2_VACODVD,.F.)
	
	If Found()
		
		// Se houver lote multiplo informado no cadastro da revisao, leva-o para o produto VD.
		if ! empty (m->c2_vacodvd) .and. ! empty (m->c2_varevvd)
			sg5 -> (dbsetorder (1))  // G5_FILIAL+G5_PRODUTO+G5_REVISAO+DTOS(G5_DATAREV)
			if sg5 -> (dbseek (xfilial ("SG5") + m->c2_vacodvd + m->c2_varevvd, .F.)) .and. sg5 -> g5_valm > 0
				_nLM = sg5 -> g5_valm
			endif
		endif

		// grava o campo passado por parâmetro no campo de revisão no SB1		
		reclock("SB1",.F.)
		SB1->B1_REVATU   := revisao
		if _nLM > 0
			sb1 -> b1_lm = _nLM
		endif
		MsUnlock()
		
	Else
        Alert("Produto '" + M->C2_VACODVD + "' não encontrado no cadastro de produtos")
	Endif

	U_ML_SRArea (_aAreaAnt)
return M->C2_VAREVVD
