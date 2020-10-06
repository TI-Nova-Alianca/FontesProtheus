// Programa...: SZI_DS
// Autor......: Robert Koch
// Data.......: 19/04/2016
// Descricao..: Gera na cta.corrente de associados movimento de distribuicao de sobras do exercicio.
//
// Historico de alteracoes:
// 29/01/2019 - Robert - GLPI5254 - Movtos tipo 13 transferidos de outras filiais eram considerados duas vezes.
//                                - Desconsiderava associados desligados na data base.
//                                - Grava log de evento de geracao do calculo.
// 01/02/2019 - Robert - Desconsidera quem teve movimentos tipo 11, 17 e 27
//                     - Mostra todos os associados, com motivo pelo qual foram desconsiderados no calculo.
//

// --------------------------------------------------------------------------
User Function szi_ds ()
	local _lContinua   := .T.
	local cCadastro    := "Distribuicao de sobras do exercicio"
	local aSays        := {}
	local aButtons     := {}
	local nOpca        := 0
	local lPerg        := .F.
	local _nLock       := 0
	Private cPerg      := "SZI_DS"
	u_logId ()
	u_logIni ()

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if _lContinua
		_lContinua = U_ZZUVL ('051', __cUserID, .T.)//, cEmpAnt, cFilAnt)
	endif

	// Somente uma estacao por vez.
	if _lContinua
		_nLock := U_Semaforo (procname (), .F.)
		if _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.")
			return
		endif
	endif

	if _lContinua
		_ValidPerg ()
		Pergunte (cPerg, .F.)
		u_logsx1 ()
		
		AADD(aSays,cCadastro)
		AADD(aSays,"Este programa gera movimentos na conta corrente de associados,")
		AADD(aSays,"rateando o total a distribuir com base no valor de cada um na safra base.")
		
		AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
		
	 	FormBatch( cCadastro, aSays, aButtons )
	
		If nOpca == 1
			Processa( {|lEnd| _Calc ()})
		Endif
	
		// Libera semaforo.
		if _nLock > 0
			U_Semaforo (_nLock)
		endif
	endif
return
	
	
	
// --------------------------------------------------------------------------
Static Function _TudoOk()
//	Local _aArea    := GetArea()
	Local _lRet     := .T.
//	RestArea(_aArea)
Return(_lRet)



// --------------------------------------------------------------------------
Static Function _Calc ()
	local _lContinua  := .T.
	local _oSQL       := NIL
	local _nVlADist   := mv_par01
	local _sSafraBas  := mv_par02
	local _oCtaCorr   := NIL
	local _aAssoc     := {}
	local _nAssoc     := 0
	local _nTotDist   := 0
	local _oAux       := NIL
	local _aCols      := {}
	local _oAssoc     := NIL
	local _sLinInf    := ""
	local _oEvento    := NIL
	local _sPrefixo   := ''
	local _sTM        := '19'
	local _sMemCalc   := ''
	local _sMesRef    := '12' + _sSafraBas

	u_logsx1 ()

	// Busca os associados para as quais deve ser distribuido valor.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT ZI_ASSOC, ZI_LOJASSO, A2_NOME, "
		_oSQL:_sQuery +=        " SUM (CASE WHEN ZI_TM = '13' THEN 1 else -1 end * ZI_VALOR),"
		_oSQL:_sQuery +=        " 0,"

		// Resgates devem ocorrer apenas uma vez por ano.
		_oSQL:_sQuery +=        " CASE WHEN EXISTS (SELECT *"
		_oSQL:_sQuery +=                            " FROM " + RetSqlName ("SZI") + " JA_TEM "
		_oSQL:_sQuery +=                           " WHERE JA_TEM.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=                             " AND JA_TEM.ZI_TM       = '" + _sTM + "'"
		_oSQL:_sQuery +=                             " AND JA_TEM.ZI_ASSOC    = SZI.ZI_ASSOC"
		_oSQL:_sQuery +=                             " AND JA_TEM.ZI_LOJASSO  = SZI.ZI_LOJASSO"
		_oSQL:_sQuery +=                             " AND JA_TEM.ZI_MESREF   = '" + _sMesRef + "')"
		_oSQL:_sQuery +=             " THEN 'JA TEM VALOR GERADO NESTE ANO; '"
		_oSQL:_sQuery +=             " ELSE ''"
		_oSQL:_sQuery +=             " END"
		_oSQL:_sQuery +=             " + "

		// Associados que ja resgataram capital ou tiveram baixa de cotas nao participam mais.
		// Considera qualquer data, pois posso estar rodando anos retroativos e nao quero alterar o
		// capital de associados que ja resgataram cota.
		_oSQL:_sQuery +=        " CASE WHEN EXISTS (SELECT *"
		_oSQL:_sQuery +=                            " FROM " + RetSqlName ("SZI") + " RESGATE "
		_oSQL:_sQuery +=                           " WHERE RESGATE.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=                             " AND RESGATE.ZI_TM       in ('11', '27')"
		_oSQL:_sQuery +=                             " AND RESGATE.ZI_ASSOC    = SZI.ZI_ASSOC"
		_oSQL:_sQuery +=                             " AND RESGATE.ZI_LOJASSO  = SZI.ZI_LOJASSO)"
		_oSQL:_sQuery +=             " THEN 'JA TEM RESGATE OU BAIXA; '"
		_oSQL:_sQuery +=             " ELSE ''"
		_oSQL:_sQuery +=             " END"
		_oSQL:_sQuery +=             " + "

		// Associados que transferiram cota para alguem e se desligaram nao participam mais.
		_oSQL:_sQuery +=        " CASE WHEN EXISTS (SELECT *"
		_oSQL:_sQuery +=                            " FROM " + RetSqlName ("SZI") + " RESGATE "
		_oSQL:_sQuery +=                           " WHERE RESGATE.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=                             " AND RESGATE.ZI_TM       in ('17')"
		_oSQL:_sQuery +=                             " AND RESGATE.ZI_ASSOC    = SZI.ZI_ASSOC"
		_oSQL:_sQuery +=                             " AND RESGATE.ZI_LOJASSO  = SZI.ZI_LOJASSO)"
		_oSQL:_sQuery +=              " AND EXISTS (SELECT *"
		_oSQL:_sQuery +=                            " FROM " + RetSqlName ("SZI") + " RESGATE "
		_oSQL:_sQuery +=                           " WHERE RESGATE.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=                             " AND RESGATE.ZI_TM       in ('09')"
		_oSQL:_sQuery +=                             " AND RESGATE.ZI_ASSOC    = SZI.ZI_ASSOC"
		_oSQL:_sQuery +=                             " AND RESGATE.ZI_LOJASSO  = SZI.ZI_LOJASSO)"
		_oSQL:_sQuery +=             " THEN 'JA DESLIGOU-SE E TRANSFERIU COTAS; '"
		_oSQL:_sQuery +=             " ELSE ''"
		_oSQL:_sQuery +=             " END"

		_oSQL:_sQuery +=   " FROM " + RetSqlName ("SZI") + " SZI, "
		_oSQL:_sQuery +=              RetSqlName ("SA2") + " SA2 "
		_oSQL:_sQuery +=  " WHERE SA2.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " AND SA2.A2_FILIAL   = '" + xfilial ("SA2") + "'"
		_oSQL:_sQuery +=    " AND SA2.A2_COD      = SZI.ZI_ASSOC"
		_oSQL:_sQuery +=    " AND SA2.A2_LOJA     = SZI.ZI_LOJASSO"
		_oSQL:_sQuery +=    " AND SZI.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " AND SZI.ZI_TM       IN ('13', '22')"
		_oSQL:_sQuery +=    " AND SZI.ZI_FILORIG  = ''"
		_oSQL:_sQuery +=    " AND SZI.ZI_DATA     LIKE '" + _sSafraBas + "%'"
/*
		// Apenas uma vez por ano.
		_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                      " FROM " + RetSqlName ("SZI") + " JA_TEM "
		_oSQL:_sQuery +=                     " WHERE JA_TEM.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=                       " AND JA_TEM.ZI_TM       = '" + _sTM + "'"
		_oSQL:_sQuery +=                       " AND JA_TEM.ZI_ASSOC    = SZI.ZI_ASSOC"
		_oSQL:_sQuery +=                       " AND JA_TEM.ZI_LOJASSO  = SZI.ZI_LOJASSO"
//		_oSQL:_sQuery +=                       " AND JA_TEM.ZI_DATA     LIKE '" + left (dtos (dDataBase), 4) + "%')"
		_oSQL:_sQuery +=                       " AND JA_TEM.ZI_MESREF   = '" + _sMesRef + "')"
*/
/*
		// Associados que ja resgataram capital ou tiveram baixa de cotas nao participam mais.
		// Considera qualquer data, pois posso estar rodando anos retroativos e nao quero alterar o
		// capital de associados que ja resgataram cota.
		_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                      " FROM " + RetSqlName ("SZI") + " RESGATE "
		_oSQL:_sQuery +=                     " WHERE RESGATE.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=                       " AND RESGATE.ZI_TM       in ('11', '27')"
		_oSQL:_sQuery +=                       " AND RESGATE.ZI_ASSOC    = SZI.ZI_ASSOC"
		_oSQL:_sQuery +=                       " AND RESGATE.ZI_LOJASSO  = SZI.ZI_LOJASSO)"
*/
		_oSQL:_sQuery +=  " GROUP BY A2_NOME, ZI_ASSOC, ZI_LOJASSO"
		_oSQL:_sQuery +=  " ORDER BY A2_NOME, ZI_ASSOC, ZI_LOJASSO"
		_oSQL:Log ()
		_aAssoc = _oSQL:Qry2Array ()
		U_LOG (_aAssoc)


		// Alimenta array auxiliar com os produtores que ainda sao associados.
		// Quem entregou uva na safra base mas já se desassociou fica de fora.
		procregua (len (_aAssoc))
		_oAux := ClsAUtil ():New ()
		for _nAssoc = 1 to len (_aAssoc)
			incproc ()
			
//			// Associados com valor base negativo (provavelmente devendo multas) sao desconsiderados.
//			if _aAssoc [_nAssoc, 4] > 0
				aadd (_oAux:_aArray, aclone (_aAssoc [_nAssoc]))
//			endif

			if _oAux:_aArray [len (_oAux:_aArray), 4] < 0
				_oAux:_aArray [len (_oAux:_aArray), 6] = 'VLR.BASE NEGATIVO (' + cvaltochar (_oAux:_aArray [len (_oAux:_aArray), 4]) + '); '
			endif

			// Se tem motivo para nao distribuir, zera a base
			if ! empty (_oAux:_aArray [len (_oAux:_aArray), 6])
				_oAux:_aArray [len (_oAux:_aArray), 4] = 0
			endif
		next

		// Calcula valor proporcionalmente ao valor de safra de cada associado.
		_oAux:Dist3 (4, 5, _nVlADist, 2)
		u_log (_oAux:_aArray)


		// Calcula totais e confere distribuicao dos valores.
		_nTotDist = 0
		_nTGSafra = 0
		for _nAssoc = 1 to len (_oAux:_aArray)
			if _oAux:_aArray [_nAssoc, 5] < 0
				u_help ("Erro na distribuicao de valores. Associado '" + _oAux:_aArray [_nAssoc, 1] + " Ficou com valor negativo.")
				_lContinua = .F.
			endif
			if _oAux:_aArray [_nAssoc, 5] == 0 .and. empty (_oAux:_aArray [_nAssoc, 6])
				u_help ("Erro na distribuicao de valores. Associado '" + _oAux:_aArray [_nAssoc, 1] + " Ficou com valor zerado sem motivo.")
				_lContinua = .F.
			endif
			_nTGSafra += _oAux:_aArray [_nAssoc, 4]
			_nTotDist += _oAux:_aArray [_nAssoc, 5]
		next
		u_log (_nTotDist)
		if _nTotDist != _nVlADist
			u_help ("Erro na distribuicao de valores")
			_lContinua = .F.
		endif

		if _lContinua
			_aCols = {}
			aadd (_aCols, {1, 'Associado',         60, ''})
			aadd (_aCols, {2, 'Loja',              20, ''})
			aadd (_aCols, {3, 'Nome',             160, ''})
			aadd (_aCols, {4, 'Vlr.safra',         60, '@E 999,999,999.99'})
			aadd (_aCols, {5, 'Vlr.distribuido',   60, '@E 999,999,999.99'})
			aadd (_aCols, {6, 'Motivo zeramento', 160, ''})
			_sLinInf := 'Total safra base dos associados considerados: ' + transform (_oAux:TotCol (4), "@E 999,999,999.99") + '  '
			_sLinInf += 'Total distribuido: ' + transform (_nTotDist, "@E 999,999,999.99")
			U_F3Array (_oAux:_aArray, 'Distribuicao de sobras', _aCols, NIL, NIL, 'Previa da geracao de dados:', _sLinInf, .T., 'C')
			_lContinua = U_MsgYesNo ("Confirma a geracao dos dados na conta corrente?")
		endif

		if _lContinua
			_sPrefixo = U_RetZX5 ('10', _sTM, 'ZX5_10PREF')
			
			// Grava evento para posterior consulta.
			_oEvento := ClsEvent():new ()
			_oEvento:CodEven   = "SZI002"
			_oEvento:Texto     = "Iniciando calculo distribuicao sobras com os seguintes parametros:" + chr (13) + chr (10)
			_oEvento:Texto    += U_LogSX1 (cPerg) + chr (13) + chr (10)
			_oEvento:Texto    += "Numero de associados contemplados: " + cvaltochar (len (_oAux:_aArray)) + chr (13) + chr (10)
			_oEvento:Texto    += 'Vl.tot.geral safra: ' + cvaltochar (_nTGSafra) + chr (13) + chr (10)
			_oEvento:Alias     = "SZI"
			_oEvento:Grava ()

			procregua (len (_oAux:_aArray))
			for _nAssoc = 1 to len (_oAux:_aArray)
				if _oAux:_aArray [_nAssoc, 5] > 0  // Se tem valor gerado...
					incproc (_oAux:_aArray [_nAssoc, 3])

					// Monta string com memoria de calculo, a ser gravada no campo de observacoes do lcto.
					_sMemCalc := 'Gerado em ' + dtoc (date ()) + ' c/data base ' + dtoc (dDataBase) + chr (13) + chr (10)
					_sMemCalc += 'Distribuindo $' + cvaltochar (_nVlADist) + ' sobre tot.ger. de $' + cvaltochar (_nTGSafra) + ' (safra deste assoc: $' + cvaltochar (_oAux:_aArray [_nAssoc, 4]) + ')'
					_oCtaCorr = ClsCtaCorr():New ()
					_oCtaCorr:Assoc   = _oAux:_aArray [_nAssoc, 1]
					_oCtaCorr:Loja    = _oAux:_aArray [_nAssoc, 2]
					_oCtaCorr:TM      = _sTM
					_oCtaCorr:DtMovto = dDataBase
					_oCtaCorr:Valor   = _oAux:_aArray [_nAssoc, 5]
					_oCtaCorr:Histor  = 'DISTRIBUICAO SOBRA EXERC. ' + _sSafraBas                          
					_oCtaCorr:MesRef  = _sMesRef
					_oCtaCorr:Doc     = strtran (dtoc (dDataBase), '/', '')
					_oCtaCorr:Serie   = _sPrefixo
					_oCtaCorr:Parcela = '1'
					_oCtaCorr:Origem  = 'SZI_DS'
					_oCtaCorr:Obs     = _sMemCalc
					if ! _oCtaCorr:PodeIncl ()
						u_help ('Associado ' + _oCtaCorr:Assoc + '/' + _oCtaCorr:Loja + ' - ' + alltrim (_oAux:_aArray [_nAssoc, 3]) + chr (13) + chr (10) + _oCtaCorr:UltMsg)
						exit
					else
						if ! _oCtaCorr:Grava ()
							u_help (_oCtaCorr:UltMsg)
							exit
						endif
					endif
				endif
			next
		endif
		u_help ("Processo concluido.")
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                                                         TIPO TAM DEC VALID F3        Opcoes                              Help
	aadd (_aRegsPerg, {01, "Valor a distribuir            ", "N", 15, 2,  "",   "      ", {},                                 ""})
	aadd (_aRegsPerg, {02, "Safra base                    ", "C", 4,  0,  "",   "      ", {},                                 ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
