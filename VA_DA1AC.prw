// Programa...: VA_DA1AC
// Autor......: Robert Koch
// Data.......: 24/11/2008
// Cliente....: Alianca
// Descricao..: Atualiza custo de reposicao dos itens da tabela de precos.
//
// Historico de alteracoes:
// 24/03/2021 - Robert - Incluidas chamadas do programa UsoRot para ver se esta rotina estah sendo usada.
//                     - Adequacao para usar variaveis locais em lacos FOR...NEXT
//

// --------------------------------------------------------------------------
User Function VA_DA1AC ()
	local _n        := N
	local _nLinha   := 0
	local _aAreaAnt := U_ML_SRArea ()

	// Quero ver se estao usando esta rotina
	U_UsoRot ('I', procname (), '')

	if msgyesno ("Este processo atualiza a coluna '" + alltrim (RetTitle ("DA1_CUSPR")) + "' com os dados atuais de custo dos produtos (campo '" + alltrim (RetTitle ("B1_CUSTD")) + "'). Confirma?","Confirmar")
		sb1 -> (dbsetorder (1))
		for _nLinha = 1 to len (aCols)
			N = _nLinha
			if ! sb1 -> (dbseek (xfilial ("SB1") + GDFieldGet ("DA1_CODPRO"), .F.))
				u_help ("Linha " + cvaltochar (N) + ": produto nao encontrado no cadastro!")
			else
				GDFieldPut ("DA1_CUSPR", sb1 -> b1_custd)
			endif
		next
		SysRefresh ()
		N = _n
		u_help ("Custos atualizados. Lembre-se de revisar cada produto.")
	endif

	// Quero ver se estao usando esta rotina
	U_UsoRot ('F', procname (), '')
	
	U_ML_SRArea (_aAreaAnt)
return
