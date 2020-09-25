// Programa:  MTA242E
// Autor:     Robert Koch
// Data:      19/02/2009
// Descricao: P.E. apos a exclusao da desmontagem de produtos.
//            Criado inicialmente para atualizar tabela ZZ5.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function MTA242E ()
	local _aAreaAnt := U_ML_SRArea ()

	// Marca ZZ5 como estornado.
	zz5 -> (dbsetorder (2))  // ZZ5_FILIAL+ZZ5_DOCTR
	if zz5 -> (dbseek (xfilial ("ZZ5") + sd3 -> d3_doc, .F.))  // Nem todas as desmontagens sao originadas no ZZ5
		reclock ("ZZ5", .F.)
		zz5 -> zz5_estorn = "S"
		msunlock ()
	endif

	U_ML_SRArea (_aAreaAnt)
Return
