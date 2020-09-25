// Programa...: FrtNFS
// Autor......: Robert Koch
// Data.......: 05/05/2008
// Descricao..: Rotina de atualizacao do ZZ1 referente NF de saida.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function FrtNFS (_sIncExc, _sPedido)
	local _lContinua   := .T.
	local _aAmbAnt := U_SalvaAmb ()
	local _aAreaAnt := U_ML_SRArea ()

	if _lContinua
		if _sIncExc == "I"  // Inclusao de nota
			zz1 -> (dbsetorder (1))  // ZZ1_FILIAL + ZZ1_PVENDA
			if zz1 -> (dbseek (xfilial ("ZZ1") + _sPedido, .F.))
				if empty (zz1 -> zz1_docs)  // Soh grava a primeira nota (caso tenha mais que uma)
					reclock ("ZZ1", .F.)
					zz1 -> zz1_docs   = sf2 -> f2_doc
					zz1 -> zz1_series = sf2 -> f2_serie
					msunlock ()
				endif
			endif

		elseif _sIncExc == "E"  // Exclusao de nota
			zz1 -> (dbsetorder (1))  // ZZ1_FILIAL + ZZ1_PVENDA
			if zz1 -> (dbseek (xfilial ("ZZ1") + sd2 -> d2_pedido, .F.))
				reclock ("ZZ1", .F.)
				zz1 -> zz1_docs   = ""
				zz1 -> zz1_series = ""
				msunlock ()
			endif

		endif
	endif

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
	
return
