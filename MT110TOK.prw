// Programa: MT110TOK	
// Autor:    Catia Cardoso
// Data:     23/04/2019
// Funcao:   PE 'tudo OK' na manutencao de solicitacoes de compra.
//
// Historico de alteracoes:
//
// 24/04/2019 - Catia - Testar data de necessidade 
// ----------------------------------------------------------------------------------------------------------------------------------------------------
user function MT110TOK ()

	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _nLinha	:= 0
	
	For _nLinha := 1 to Len(aCols)
		// valida data de necessidade que obrigatoriamente tem que ser maior ou igual a data do sistema
		if ! empty (GDFieldGet ("C1_DATPRF"), _nLinha)
			if  ! GDDeleted (_nLinha) 
				if dtos(GDFieldGet ("C1_DATPRF", _nLinha) ) < dtos( DATE() )
					u_help ("Data de necessidade deve ser obrigatóriamente maior ou igual a data de digitação da solicitação.")
					_lRet = .F.
					exit
				endif	
			endif
		endif
	next	
	
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
	
return _lRet
