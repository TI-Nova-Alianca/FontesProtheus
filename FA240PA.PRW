// Programa:  FA240PA
// Autor:     Robert Koch
// Data:      20/03/2020
// Descricao: P.A. na geracao de bordero a pagar. Permite a inclusao de titulos
//            do tipo PA com movimento bancario.
//            Criado inicialmente para permitir gerar adto. de safra e enviar ao banco.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function FA240PA ()
	Local _lRet := .T.  // .T. - para o sistema permitir a seleção de PA (com mov. Bancário) na tela de borderô de pagamento e .F. - para não permitir.
	_lRet := U_MsgYesNo ("Ponto de entrada " + procname () + " - Permite selecionar PA?", .T.)
Return _lRet
