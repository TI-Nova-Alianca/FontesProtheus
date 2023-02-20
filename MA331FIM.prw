// Programa...: MA331Fim
// Autor......: Cl�udia Lion�o
// Data.......: 26/12/2019
// Descricao..: P.E. apos o termino da contabiliza��o do custo medio.

// Historico de alteracoes:
// 20/02/2023 - Robert  - Desabilitada chamada do U_CtbMedio() por que vamos comecar
//                        a contabilizar usando consumo/producao e nao mais consumo/ambos.
//

// --------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function MA331FIM()
	Local _aAreaAnt := U_ML_SRArea ()
	Local ExpL1:= .T. 
	
	u_logIni ()

//	Processa({|| U_CtbMedio (.T.)}, "Ajustando lctos contabeis")
	
	U_ML_SRArea (_aAreaAnt)
	
	u_logFim ()
Return ExpL1
