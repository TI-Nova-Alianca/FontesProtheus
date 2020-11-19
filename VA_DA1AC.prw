// Programa...: VA_DA1AC
// Autor......: Robert Koch
// Data.......: 24/11/2008
// Cliente....: Alianca
// Descricao..: Atualiza custo de reposicao dos itens da tabela de precos.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function VA_DA1AC ()
	local _n := N
	local _aAreaAnt := U_ML_SRArea ()

	if msgyesno ("Este processo atualiza a coluna '" + alltrim (RetTitle ("DA1_CUSPR")) + "' com os dados atuais de custo dos produtos (campo '" + alltrim (RetTitle ("B1_CUSTD")) + "'). Confirma?","Confirmar")
		sb1 -> (dbsetorder (1))
		for N = 1 to len (aCols)
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

	U_ML_SRArea (_aAreaAnt)
return
