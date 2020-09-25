// Programa:  MSD2520
// Autor:     Robert Koch
// Data:      17/04/2008
// Cliente:   Alianca
// Descricao: P.E. antes da exclusao do SD2 (chamado na exclusao de NF de saida)
//            Criado inicialmente para tratamento de controles de fretes.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function MSD2520 ()
	local _aAreaAnt := U_ML_SRArea ()
	u_logIni ()
	if sd2 -> d2_tipo == "N"
		U_FrtNFS ("E")
	endif
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
Return
