// Programa.: FA080Pos
// Autor....: Robert Koch
// Data.....: 14/04/2008
// Descricao: P.E. apos carga de valores e antes de abrir a tela de baixa de titulos a pagar.
//            Criado inicialmente para alterar historico.
// 
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. apos carga de valores e antes de abrir a tela de baixa de titulos a pagar.
// #PalavasChave      #baixa #contas_a_pagar
// #TabelasPrincipais #SE5
// #Modulos           #FIN
//
// Historico de alteracoes:
// 22/08/2016 - Robert - Ajusta historico ao tamanho do E5_HISTOR.
//
//
// --------------------------------------------------------------------------
user function FA080POS()
	local _aAreaAnt := U_ML_SRArea()
	local _lLenha   := .f.
	
	// Verifica se eh titulo de compra de lenha.
	_lLenha  = "LENHA" $ se2 -> e2_hist
	cHist070 = alltrim(cHist070) + iif(_lLenha, " compra lenha", "") + " de " + se2 -> e2_fornece + "-" + fBuscaCpo("SA2", 1, xfilial("SA2") + se2 -> e2_fornece + se2 -> e2_loja, "A2_NOME")

	// Ajusta tamanho do historico ao campo do SE5, pois a partir do Protheus 12 o sistema deixava de gravar o historico. 
	cHist070 = left(cHist070, tamsx3("E5_HISTOR")[1])

	U_ML_SRArea(_aAreaAnt)
return
