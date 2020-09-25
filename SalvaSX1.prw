// Programa:   SalvaSX1
// Autor:      Robert Koch
// Data:       02/08/2011
// Descricao:  Utilitario para salvar e restaurar backup de parametros no SX1 e profile do usuario.
// Utilizacao: Para salvar, informar o grupo de perguntas.
//             Para restaurar, informar o grupo de perguntas e a array gerada pelo backup.
//             Ex.:
//             user function teste ()
//                local _aAnt := U_SalvaSX1 (cPerg)
//                // ... procedimentos ...
//                U_SalvaSX1 (cPerg, _aAnt)
//             return
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function SalvaSX1 (_sPerg, _aRest)
	local _aAreaAtu := getarea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _aBak     := {}
	local _nRest    := 0
	local _xDado    := NIL

	// Se nao recebi a array a restaurar, entao presumo que seja para salvar.
	if valtype (_aRest) == "U"
		
		// Busca parametros atuais, inclusive do profile do usuario, se for o caso.
		Pergunte (_sPerg, .F.)
		
		// Salva somente as perguntas existentes no SX1 (o sistema tem pelo menos 40 variaveis private e nem todas sao usadas).
		_aBak = {}
		sx1 -> (dbseek (_sPerg, .T.))
		do while ! sx1 -> (eof ()) .and. sx1 -> (x1_grupo) = _sPerg
			aadd (_aBak, {sx1 -> x1_ordem, &("mv_par" + sx1 -> x1_ordem)})
			sx1 -> (dbskip ())
		enddo

	elseif valtype (_aRest) == "A"
		for _nRest = 1 to len (_aRest)
			U_GravaSX1 (_sPerg, _aRest [_nRest, 1], _aRest [_nRest, 2])
		next
	endif
	
	U_SalvaAmb (_aAmbAnt)
	restarea (_aAreaAtu)
return _aBak
