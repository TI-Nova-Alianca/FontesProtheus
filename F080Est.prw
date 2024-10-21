// Programa.: F080EST
// Autor....: Robert Koch
// Data.....: 27/07/2011
// Descricao: P.E. apos cancelamento de baixa manual de titulos a pagar.
//            Criado inicialmente para alimentar o campo E5_VACHVEX.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. apos cancelamento de baixa manual de titulos a pagar.
// #PalavasChave      #baixa #contas_a_pagar 
// #TabelasPrincipais #SE5 #SZI
// #Modulos           #FIN
//
// Historico de alteracoes:
//
// ------------------------------------------------------------------------------------
User Function F080EST()
	Local _aAreaAnt := U_ML_SRArea()
	
	u_logIni()
	
	if empty(se5 -> e5_vaUser)
		reclock("SE5", .F.)
			se5->e5_vachvex := se2 -> e2_vachvex
			se5->e5_vauser  := alltrim(cUserName)
		msunlock()
	endif

	U_ML_SRArea(_aAreaAnt)
	u_logFim()
Return .T.


