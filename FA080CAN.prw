// Programa.: FA080CAN
// Autor....: Cláudia Lionço
// Data.....: 21/10/2024
// Descricao: P.E. Cancela/Exclui baixas a pagar
//            Criado inicialmente para atualização do saldo conta corrente associados.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. Cancela/Exclui baixas a pagar
// #PalavasChave      #baixa #contas_a_pagar 
// #TabelasPrincipais #SE5 #SZI
// #Modulos           #FIN
//
// Historico de alteracoes:
//
// ------------------------------------------------------------------------------------
User Function FA080CAN()
	Local _aAreaAnt := U_ML_SRArea()

	_AtuSZI()

	U_ML_SRArea(_aAreaAnt)
Return .T.
//
// --------------------------------------------------------------------------
// Atualiza saldo SZI
Static Function _AtuSZI ()
    local _oCtaCorr := NIL

	if left (se2 -> e2_vachvex, 3) == "SZI"
		szi -> (dbsetorder (2))  // ZI_FILIAL+ZI_ASSOC+ZI_LOJASSO+ZI_SEQ
		if szi -> (dbseek (xfilial ("SZI") + substr (se2 -> e2_vachvex, 4), .F.))
		
			// Atualiza saldo conta corrente.
			_oCtaCorr := ClsCtaCorr():New (szi -> (recno ()))
			_oCtaCorr:AtuSaldo ()
			
		endif
	endif
Return


