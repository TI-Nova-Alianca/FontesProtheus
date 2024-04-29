/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ SX5NOTA  ³ Autor ³    Jeferson Rech      ³ Data ³ Fev/2006 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Filtra para So Apresentar Series da Filial Posicionada     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Utilizacao³ Especifico para Clientes Microsiga                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   Data   ³ Programador   ³Manutencao Efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
// Historico de alteracoes:
// 19/06/2008 - Robert - Series liberadas na base 'teste'.
// 26/11/2008 - Robert - Somente serie NFE fica liberada. Para qualquer filial.
// 09/01/2009 - Robert - Todas as series liberadas na empresa 02.
// 30/04/2015 - Robert - Passa a liberar todas as series para usuarios do grupo 040.
// 04/01/2016 - Robert - Tratamento para parametro VA_SERSAFR.
// 20/11/2017 - Robert - Filtro especifico para serie 100 na tela de MDF-e
// 03/02/2021 - Robert - Para saber se estava gerando contranota de safra, testava rotina U_VA_RUS. Passa a testar U_VA_RUSN.
//

// --------------------------------------------------------------------------
User Function SX5NOTA ()
	Local _lRet     := .T.
	Local _xSERIE   := SX5->X5_CHAVE
	local _aAreaAnt := U_ML_SRArea ()
	local _lVeTodas := U_ZZUVL ('040', __cUserId, .F.)
	//local _lVeTodas := U_ZZUVL ('040', __cUserId, .F., cEmpAnt, cFilAnt)

	if IsInCallStack ("SPEDMDFE")
		if left (_xSERIE, 3) != "100"  // Serie especifica para os MDF-e
			_lRet = .F.
		endif
	else
//		if IsInCallStack ("U_VA_RUS") .or. IsInCallStack ("U_VA_GNF2") .or. IsInCallStack ("U_VA_GNF5")
		if IsInCallStack ("U_VA_RUSN") .or. IsInCallStack ("U_VA_GNF2") .or. IsInCallStack ("U_VA_GNF6") .or. IsInCallStack ("U_VA_GNF5")
			if ! left (_xSERIE, 3) $ GetMv ("VA_SERSAFR", .F., '')
				_lRet = .F.
			endif
		else
			if ! _lVeTodas
				if left (_xSERIE, 3) != "10 "
					_lRet = .F.
				endif
			endif
		endif
	endif

//	U_Log2 ('debug', '[' + procname () + ']Saindo com _lRet = ' + cvaltochar (_lRet))
	U_ML_SRArea (_aAreaAnt)
Return(_lRet)
