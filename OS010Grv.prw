// Programa:  OS010Grv
// Autor:     Robert Koch
// Descricao: P.E. apos a gravacao da tabela de precos.
//            Criado inicialmente para exportar dados para Mercanet.
//
// Historico de alteracoes:
// 24/08/2017 - Robert - Posiciona a tabela DA0 antes de chamar a atualizacao do Mercanet.
//

// --------------------------------------------------------------------------
user function OS010Grv ()
	local _aAreaAnt := U_ML_SRArea ()

	if paramixb [1] == 1  // Usuario confirmou
		if paramixb [2] == 3 .or. paramixb [2] == 4  // Inclusao ou alteracao
			da0 -> (dbsetorder (1))
			if da0 -> (dbseek (xfilial ("DA0") + m->da0_codtab, .F.))  // O alias DA0 nao chega aqui posicionado.
				U_AtuMerc ('DA0', da0 -> (recno ()))
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return
