// Programa:  _Mata410
// Autor:     Robert Koch
// Data:      10/06/2010
// Descricao: Filtra vendedor para posterior chamada de tela de pedidos para representantes.
//
// Historico de alteracoes:
// 01/03/2017 - Robert - Chamada da funcao ConfirmSXC8() apos o MATA410 para tentar eliminar perda se sequencia de numero de pedidos.
//

// --------------------------------------------------------------------------
USER FUNCTION _MATA410 ()
	//local _xUsuario := upper(alltrim(cUserName))
	local _xMat_usu := ALLTRIM(__CUSERID)
	
	u_logId ()
//	u_log ('__cUerID:', __CUSERID)

	dbselectarea ("SA3")
	DbGoTop()
	Do WHile !eof()
//		u_log (sa3 -> a3_cod)
		If ALLTRIM(A3_CODUSR) == ALLTRIM(UPPER(_xMat_usu))
			// Cria variavel private com o codigo do vendedor, para os casos em que esta
			// rotina for acessada por um representante e que esse representante deva
			// visualizar apenas os seus registros.
			// Sugestao de filtro para F3 --> iif(type("_sCodRep")=="C", da0->da0_vend==_sCodRep, .T.)
//			u_log ('Achei no rep.', sa3 -> a3_cod)
			private _sCodRep := A3_COD
//			u_log ('_sCodRep:', _sCodRep)
			EXIT
		ENDIF
		DbSkip()
	EndDo

	if type ("_sCodRep") == "C"  // Eh representante. Vou filtrar os pedidos.
//		u_log ('_sCodRep no final:', _sCodRep)
		dbselectarea ("SC5")
		SET FILTER TO C5_VEND1 == _sCodRep
		
		// Chama tela de pedidos padrao.
		MATA410 ()
		
		// Confirma sequenciais, se houver.
		u_log ('Confirmando sequenciais (representante)')
		do while __lSX8
			ConfirmSX8 ()
		enddo
		
		dbselectarea ("SC5")
		SET FILTER TO
	else
		// Chama tela de pedidos padrao.
		MATA410 ()

		// Confirma sequenciais, se houver.
		u_log ('Confirmando sequenciais (tela padrao)')
		do while __lSX8
			ConfirmSX8 ()
		enddo
	endif
Return
