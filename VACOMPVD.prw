#include 'protheus.ch'
#include 'parmtype.ch'

// Autor: Marcio - Procdata
// Data: 18/10/2016
// Descrição: programa chamado por gatilho para buscar o componente do tipo VD na estrutura do produto da OP.
//
// Historico de alteracoes:
// 25/11/2016 - Robert - Executa somente quando o produto da OP for do tipo PA.
//                     - Nao validava G1_INI, G1_FIM, G1_REVINI e G1_REVFIM.
//

// --------------------------------------------------------------------------
user function VACOMPVD()
	local _aAreaAnt := U_ML_SRArea ()
	local _sRet     := ""

	if fBuscaCpo ("SB1", 1, xfilial ("SB1") + m->c2_produto, "B1_TIPO") == "PA"

		// Posiciona no SG1 para verificar estrutura do produto
		DbSelectArea("SG1")
		DbSetOrder(1)
		DbSeek(xFilial("SG1")+M->C2_PRODUTO,.F.)
	
		// Enquanto não for fim do arquivo (While not end of file) e o código da estrutura for o mesmo digitado na tela
		While !EoF() .and. sg1 -> g1_filial == xfilial ("SG1") .and. Alltrim(SG1->G1_COD) == Alltrim(M->C2_PRODUTO)
	
			if sg1 -> g1_ini <= m->c2_datpri .and. sg1 -> g1_fim >= m->c2_datpri .and. sg1 -> g1_revini <= m->c2_revisao .and. sg1 -> g1_revfim >= m->c2_revisao
			
				// Posiciona no SB1, usando os componentes da estrutura, para buscar tipo e código
				DbSelectArea("SB1")
				DbSetOrder(1)
				DbSeek(xFilial("SB1")+SG1->G1_COMP,.F.)
			
				// Se o tipo for VD, grava no campo do C2 da janela que está aberta o código do produto
				if Found() .and. SB1->B1_TIPO=="VD"
					_sRet = SB1->B1_COD
					exit  // Por enquanto, para no primeiro VD que encontrar. Como trataremos quando houver mais de um?
				endif
			endif
			
			DbSelectArea("SG1")
			DbSkip()
		EndDo
	endif

	U_ML_SRArea (_aAreaAnt)
return _sRet