// Programa...: MA331Fim
// Autor......: Cl�udia Lion�o
// Data.......: 26/12/2019
// Descricao..: P.E. apos o termino da contabiliza��o do custo medio.
//
// Historico de alteracoes:
// --------------------------------------------------------------------------
//
#include 'protheus.ch'
#include 'parmtype.ch'

User Function MA331FIM()
	Local _aAreaAnt := U_ML_SRArea ()
	Local ExpL1:= .T. 
	
	u_logIni ()

	Processa({|| U_CtbMedio (.T.)}, "Ajustando lctos contabeis")
	
	U_ML_SRArea (_aAreaAnt)
	
	u_logFim ()
Return ExpL1
