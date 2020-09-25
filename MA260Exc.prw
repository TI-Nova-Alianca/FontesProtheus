// Programa...: MT260Exc
// Autor......: Robert Koch
// Data.......: 04/03/2017
// Descricao..: P.E. apos estorno transf. internas
//              Criado inicialmente para atualizar tabela ZAG.
//
// Historico de alteracoes:
// 17/08/2018 - Robert - Grava evento de estorno.
//

// ----------------------------------------------------------------
user function MA260Exc ()
	local _aAreaAnt := U_ML_SRArea ()
	local _oTrEstq  := NIL

	// Verifica se deve gravar evento gerado em P.E. anterior.
	if type ('_oEvtEstF') == 'O'
		_oEvtEstF:Grava ()
	endif

	if left (sd3 -> d3_vaChvEx, 3) == 'ZAG'
//		U_SendMail ("robert.koch@novaalianca.coop.br", "falta estornar ClsTrEstq no " + procname (), "vai corrigir isso, tche!", {})
		zag -> (dbsetorder (1))
		if zag -> (dbseek (xfilial ("ZAG") + substr (sd3 -> d3_vaChvEx, 4, 10), .F.))
			_oTrEstq := ClsTrEstq ():New (zag -> (recno ()))
			if valtype (_oTrEstq) == 'O'
				_oTrEstq:Estorna ()
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return
