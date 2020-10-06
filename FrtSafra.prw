// Programa...: FrtSafra
// Autor......: Robert Koch
// Data.......: 13/04/2018
// Descricao..: Gera titulos no financeiro para auxilio de frete aos associados sobre a safra.
//              A partir de 2017 a Cooperativa comecou a pagar frete conforme uvas de maior interesse
//              ou conforme distancias percorridas pelos associados para trazerem sua producao.
//
// Historico de alteracoes:
// 21/05/2018 - Robert - Calculo deve considerar distancia ida e volta (considerava apenas ida).
// 08/04/2019 - Catia  - include TbiConn.ch 
// 16/05/2019 - Robert - Valida preenchimento parametros
//                     - Criacao regras safra 2019
//                     - Grava evento com os parametros
// 22/05/2019 - Robert - Melhorada planilha de conferencia (colunas com total do associado e motivo de nao gerar frete)
//                     - Grava erros (caso existam) no arquivo de log e no evento (SZN).
// 01/07/2020 - Robert - Ajustes para gerar titulos de frete para a safra 2020 (agora jah calculados nas cargas de uva).
//

#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

// ------------------------------------------------------------------------------------
User Function FrtSafra ()
	local _lContinua   := .T.
	local cCadastro    := "Gera titulos a pagar ref auxilio frete safra para associados"
	local aSays        := {}
	local aButtons     := {}
	local nOpca        := 0
	local lPerg        := .F.
	local _nLock       := 0
	Private cPerg      := "FRTSAFRA"

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if _lContinua
		_lContinua = U_ZZUVL ('051', __cUserID, .T.)//, cEmpAnt, cFilAnt)
	endif

	// Somente uma estacao por vez.
	if _lContinua
		_nLock := U_Semaforo (procname (), .F.)
		if _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.",, .T.)
			return
		endif
	endif

	if _lContinua
		_ValidPerg ()
		Pergunte (cPerg, .F.)
		AADD(aSays,cCadastro)
		AADD(aSays,"")
		AADD(aSays,"")
		
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
	if mv_par02 < date ()
		u_help ("Data para pagamento nao pode ser menor que hoje.",, .T.)
		_lRet = .F.
	endif
	if empty (mv_par07) .or. empty (mv_par08)
		u_help ("Prefixo e parcela devem ser informados.",, .T.)
		_lRet = .F.
	endif
//	RestArea(_aArea)
Return(_lRet)



// --------------------------------------------------------------------------
Static Function _Calc ()
	local _oSQL      := NIL
	local _nDist     := 0
	local _nDistMin  := 0
	local _lContinua := .T.
	local _nFrete    := 0
//	local _nTotFrt   := 0
	local _nTotPeso  := 0
	local _oEvento   := NIL
	local _aTotAssoc := {}
	local _nTotAssoc := 0
	local _nValFre := 0
	local _sAssoc   := ""
	local _sLoja    := ""
	private _sErros  := ""

	u_logsx1 ()

	// Optei por fazer em separado pois costuma haver mudanca de uma safra para outra.
	do case
		case mv_par01 == '2018'
			// Busca cargas candidatas a receber reembolso de frete.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT C.FILIAL, C.CARGA, C.ASSOCIADO, C.LOJA_ASSOC AS LOJA, C.NOME_ASSOC AS NOME,"
			_oSQL:_sQuery +=       " SA2.A2_VANUCL AS NUCLEO, SA2.A2_CGC AS CPF, SA2.A2_VADTNAS AS DT_NASCIM,"
			_oSQL:_sQuery +=       " C.PRODUTO, C.DESCRICAO, C.COR, C.PESO_LIQ, "
			_oSQL:_sQuery +=       " C.CAD_VITIC, TALHOES.ZA8_KMF01 AS KM_F01, TALHOES.ZA8_KMF03 AS KM_F03, TALHOES.ZA8_KMF07 AS KM_F07, "
			_oSQL:_sQuery +=       " 0 AS KM_CALCULO, 0 AS FRETE, SPACE (100) AS OBS "
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SA2") + " SA2, "
			_oSQL:_sQuery +=            " VA_VCARGAS_SAFRA C"
			_oSQL:_sQuery +=     " LEFT JOIN (SELECT ZA8.ZA8_COD, SZ9.Z9_SEQ, ZA8.ZA8_KMF01, ZA8.ZA8_KMF03, ZA8.ZA8_KMF07"
			_oSQL:_sQuery +=                  " FROM " + RetSQLName ("ZA8") + " ZA8, "
			_oSQL:_sQuery +=                             RetSQLName ("SZ9") + " SZ9 "
			_oSQL:_sQuery +=                 " WHERE SZ9.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=                   " AND SZ9.Z9_FILIAL  = ZA8.ZA8_FILIAL"
			_oSQL:_sQuery +=                   " AND SZ9.Z9_IDZA8   = ZA8.ZA8_COD"
			_oSQL:_sQuery +=                   " AND ZA8.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=                   " AND ZA8.ZA8_FILIAL = '" + xfilial ("ZA8") + "'"
			_oSQL:_sQuery +=                ") AS TALHOES"
			_oSQL:_sQuery +=        " ON (TALHOES.ZA8_COD = C.PROPR_RURAL AND TALHOES.Z9_SEQ = C.TALHAO)"
			_oSQL:_sQuery += " WHERE SAFRA        = '" + mv_par01 + "'"
			_oSQL:_sQuery +=   " AND C.ASSOCIADO NOT IN ('001369', '003114')"  // PRODUCAO PROPRIA
			_oSQL:_sQuery +=   " AND C.ASSOCIADO + C.LOJA_ASSOC BETWEEN '" + mv_par03 + mv_par04 + "' AND '" + mv_par05 + mv_par06 + "'"
			_oSQL:_sQuery +=   " AND SA2.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
			_oSQL:_sQuery +=   " AND SA2.A2_COD     = C.ASSOCIADO"
			_oSQL:_sQuery +=   " AND SA2.A2_LOJA    = C.LOJA_ASSOC"
			_oSQL:_sQuery +=   " AND EXISTS (SELECT *"  // Quero ter certeza de que esta carga tem contranota valida.
			_oSQL:_sQuery +=                 " FROM VA_VNOTAS_SAFRA N"
			_oSQL:_sQuery +=                " WHERE N.SAFRA      = C.SAFRA"
			_oSQL:_sQuery +=                  " AND N.FILIAL     = C.FILIAL"
			_oSQL:_sQuery +=                  " AND N.ASSOCIADO  = C.ASSOCIADO"
			_oSQL:_sQuery +=                  " AND N.LOJA_ASSOC = C.LOJA_ASSOC"
			_oSQL:_sQuery +=                  " AND N.DOC        = C.CONTRANOTA"
			_oSQL:_sQuery +=                  " AND N.SERIE      = C.SERIE_CONTRANOTA"
			_oSQL:_sQuery +=                  " AND N.TIPO_NF    = 'E')"
			_oSQL:_sQuery += " ORDER BY ASSOCIADO, LOJA_ASSOC, FILIAL, CARGA, ITEMCARGA"
			_oSQL:Log ()
			_oSQL:Copy2Trb (.T.)
		
			procregua (_trb -> (reccount ()))
			_nTotPeso = 0
//			_nTotFrt = 0
			_trb -> (dbgotop ())
			do while ! _trb -> (eof ())
				incproc ()
				_nFrete = 0
				_nTotPeso += _trb -> peso_liq
				_nDist = 2 * iif (_trb -> filial == '03', _trb -> km_f03, iif (_trb -> filial == '07', _trb -> km_f07, iif (_trb -> filial $ '01/09', _trb -> km_f01, 0)))
				if _nDist <= 0
					_Erro ("Filial " + _trb -> filial + " associado " + _trb -> associado + " " + _trb -> nome + " sem distancia da propriedade " + _trb -> cad_vitic)
				endif
				_nDistMin = 20
				if _nDist < _nDistMin  // Passa a ser ida e volta, entao dobra distancia minima  --> 10
					reclock ('_trb', .F.)
					_trb -> obs = 'Distancia menor que ' + cvaltochar (_nDistMin) + ' Km'
					msunlock ()
				else
					reclock ('_trb', .F.)
					if _trb -> cor == 'T' .and. _trb -> nucleo $ 'PB/JC' .and. _trb -> filial $ '01/09'
						_nFrete = 0.05 * _trb -> peso_liq
						_trb -> km_calculo = 0
					else
						_nFrete = 0.15 * _trb -> peso_liq / 1000 * _nDist
						_trb -> km_calculo = _nDist
					endif
					_trb -> frete = round (_nFrete, 2)
					msunlock ()

//					_nTotFrt += _trb -> frete
				endif

				_trb -> (dbskip ())
			enddo

		case mv_par01 == '2019'
			// Busca cargas candidatas a receber reembolso de frete.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT C.FILIAL, C.CARGA, C.ASSOCIADO, C.LOJA_ASSOC AS LOJA, C.NOME_ASSOC AS NOME,"
			_oSQL:_sQuery +=       " SA2.A2_VANUCL AS NUCLEO, SA2.A2_CGC AS CPF, SA2.A2_VADTNAS AS DT_NASCIM,"
			_oSQL:_sQuery +=       " C.PRODUTO, C.DESCRICAO, C.COR, C.PESO_LIQ, "
			_oSQL:_sQuery +=       " C.CAD_VITIC, TALHOES.ZA8_KMF01 AS KM_F01, TALHOES.ZA8_KMF03 AS KM_F03, TALHOES.ZA8_KMF07 AS KM_F07, "
			_oSQL:_sQuery +=       " 0 AS KM_CALCULO, 0 AS FRETE, 0 AS TOT_ASSOC, SPACE (100) AS OBS, SPACE (100) AS MOTIVO"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SA2") + " SA2, "
			_oSQL:_sQuery +=            " VA_VCARGAS_SAFRA C"
			_oSQL:_sQuery +=     " LEFT JOIN (SELECT ZA8.ZA8_COD, SZ9.Z9_SEQ, ZA8.ZA8_KMF01, ZA8.ZA8_KMF03, ZA8.ZA8_KMF07"
			_oSQL:_sQuery +=                  " FROM " + RetSQLName ("ZA8") + " ZA8, "
			_oSQL:_sQuery +=                             RetSQLName ("SZ9") + " SZ9 "
			_oSQL:_sQuery +=                 " WHERE SZ9.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=                   " AND SZ9.Z9_FILIAL  = ZA8.ZA8_FILIAL"
			_oSQL:_sQuery +=                   " AND SZ9.Z9_IDZA8   = ZA8.ZA8_COD"
			_oSQL:_sQuery +=                   " AND ZA8.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=                   " AND ZA8.ZA8_FILIAL = '" + xfilial ("ZA8") + "'"
			_oSQL:_sQuery +=                ") AS TALHOES"
			_oSQL:_sQuery +=        " ON (TALHOES.ZA8_COD = C.PROPR_RURAL AND TALHOES.Z9_SEQ = C.TALHAO)"
			_oSQL:_sQuery += " WHERE SAFRA        = '" + mv_par01 + "'"
			_oSQL:_sQuery +=   " AND C.ASSOCIADO NOT IN ('001369', '003114')"  // PRODUCAO PROPRIA
			_oSQL:_sQuery +=   " AND C.ASSOCIADO NOT IN ('012373')"  // Vinhedos da quinta (empresa que entregou uva em Livramento em 2019)
			_oSQL:_sQuery +=   " AND C.ASSOCIADO + C.LOJA_ASSOC BETWEEN '" + mv_par03 + mv_par04 + "' AND '" + mv_par05 + mv_par06 + "'"
			_oSQL:_sQuery +=   " AND SA2.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
			_oSQL:_sQuery +=   " AND SA2.A2_COD     = C.ASSOCIADO"
			_oSQL:_sQuery +=   " AND SA2.A2_LOJA    = C.LOJA_ASSOC"
			_oSQL:_sQuery +=   " AND EXISTS (SELECT *"  // Quero ter certeza de que esta carga tem contranota valida.
			_oSQL:_sQuery +=                 " FROM VA_VNOTAS_SAFRA N"
			_oSQL:_sQuery +=                " WHERE N.SAFRA      = C.SAFRA"
			_oSQL:_sQuery +=                  " AND N.FILIAL     = C.FILIAL"
			_oSQL:_sQuery +=                  " AND N.ASSOCIADO  = C.ASSOCIADO"
			_oSQL:_sQuery +=                  " AND N.LOJA_ASSOC = C.LOJA_ASSOC"
			_oSQL:_sQuery +=                  " AND N.DOC        = C.CONTRANOTA"
			_oSQL:_sQuery +=                  " AND N.SERIE      = C.SERIE_CONTRANOTA"
			_oSQL:_sQuery +=                  " AND N.TIPO_NF    = 'E')"
			_oSQL:_sQuery += " ORDER BY ASSOCIADO, LOJA_ASSOC, FILIAL, CARGA, ITEMCARGA"
			_oSQL:Log ()
			_oSQL:Copy2Trb (.T.)
		
			procregua (_trb -> (reccount ()))
			_nTotPeso = 0
//			_nTotFrt = 0
			_trb -> (dbgotop ())
			do while ! _trb -> (eof ())
				incproc ()
				_nFrete = 0
				_nTotPeso += _trb -> peso_liq
				_nDist = 2 * iif (_trb -> filial == '03', _trb -> km_f03, iif (_trb -> filial == '07', _trb -> km_f07, iif (_trb -> filial $ '01/09', _trb -> km_f01, 0)))
				if _nDist <= 0
					_Erro ("Filial " + _trb -> filial + " associado " + _trb -> associado + " " + _trb -> nome + " sem distancia da propriedade " + _trb -> cad_vitic)
				endif
				_nDistMin = 20
				if _nDist < _nDistMin  // Passa a ser ida e volta, entao dobra distancia minima  --> 10
					reclock ('_trb', .F.)
					_trb -> obs = 'Distancia menor que ' + cvaltochar (_nDistMin) + ' Km'
					msunlock ()
				else
					reclock ('_trb', .F.)
					if _trb -> cor == 'T' .and. _trb -> nucleo $ 'PB/JC' .and. _trb -> filial $ '01/09'
						_nFrete = 0.05 * _trb -> peso_liq
						_trb -> km_calculo = 0
						_trb -> obs = 'Tintas de Farroupilha entregues na matriz'
					elseif _trb -> cor == 'T' .and. _trb -> nucleo $ 'SV/SG/FC/NP' .and. _trb -> filial $ '07'  // Clausula nova em relacao a 2018
						_nFrete = 0.05 * _trb -> peso_liq
						_trb -> km_calculo = 0
						_trb -> obs = 'Tintas de Caxias/Flores entregues em Farroupilha'
					else
						_nFrete = 0.15 * _trb -> peso_liq / 1000 * _nDist
						_trb -> km_calculo = _nDist
					endif
					_trb -> frete = round (_nFrete, 2)
					msunlock ()

//					_nTotFrt += _trb -> frete
				endif

				_trb -> (dbskip ())
			enddo

		case mv_par01 == '2020'
			// Busca cargas candidatas a receber reembolso de frete.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT C.FILIAL, C.CARGA, C.ASSOCIADO, C.LOJA_ASSOC AS LOJA, C.NOME_ASSOC AS NOME,"
			_oSQL:_sQuery +=       " VALOR_FRETE AS FRETE, 0 AS TOT_ASSOC, SPACE (100) AS OBS, SPACE (100) AS MOTIVO"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SA2") + " SA2, "
			_oSQL:_sQuery +=            " VA_VCARGAS_SAFRA C"
			_oSQL:_sQuery += " WHERE SAFRA        = '" + mv_par01 + "'"
			_oSQL:_sQuery +=   " AND VALOR_FRETE  > 0"
			_oSQL:_sQuery +=   " AND C.ASSOCIADO + C.LOJA_ASSOC BETWEEN '" + mv_par03 + mv_par04 + "' AND '" + mv_par05 + mv_par06 + "'"
			_oSQL:_sQuery +=   " AND SA2.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
			_oSQL:_sQuery +=   " AND SA2.A2_COD     = C.ASSOCIADO"
			_oSQL:_sQuery +=   " AND SA2.A2_LOJA    = C.LOJA_ASSOC"
			_oSQL:_sQuery +=   " AND EXISTS (SELECT *"  // Quero ter certeza de que esta carga tem contranota valida.
			_oSQL:_sQuery +=                 " FROM VA_VNOTAS_SAFRA N"
			_oSQL:_sQuery +=                " WHERE N.SAFRA      = C.SAFRA"
			_oSQL:_sQuery +=                  " AND N.FILIAL     = C.FILIAL"
			_oSQL:_sQuery +=                  " AND N.ASSOCIADO  = C.ASSOCIADO"
			_oSQL:_sQuery +=                  " AND N.LOJA_ASSOC = C.LOJA_ASSOC"
			_oSQL:_sQuery +=                  " AND N.DOC        = C.CONTRANOTA"
			_oSQL:_sQuery +=                  " AND N.SERIE      = C.SERIE_CONTRANOTA"
			_oSQL:_sQuery +=                  " AND N.TIPO_NF    = 'E')"
			_oSQL:_sQuery += " ORDER BY ASSOCIADO, LOJA_ASSOC, FILIAL, CARGA, ITEMCARGA"
			_oSQL:Log ()
			_oSQL:Copy2Trb (.T.)

		otherwise
			u_help ("Sem tratamento para esta safra.",, .T.)
			_lContinua = .F.
	endcase


	// Calcula o valor total de cada associado e jah deixa pronto no arquivo de trabalho.
	_aTotAssoc = {}
	_trb -> (dbgotop ())
	do while ! _trb -> (eof ())
		_sAssoc = _trb -> associado
		_sLoja  = _trb -> loja
		_nValFre = 0
		do while ! _trb -> (eof ()) .and. _trb -> associado == _sAssoc .and. _trb -> loja == _sLoja
			incproc ('Associado ' + _sAssoc)
			_nValFre += _trb -> frete
			_trb -> (dbskip ())
		enddo
		aadd (_aTotAssoc, {_sAssoc, _sLoja, _nValFre})
	enddo
	// u_log2 ('INFO', _aTotAssoc)
	for _nTotAssoc = 1 to len (_aTotAssoc)
		_trb -> (dbgotop ())
		do while ! _trb -> (eof ())
			if _trb -> associado == _aTotAssoc [_nTotAssoc, 1] .and. _trb -> loja == _aTotAssoc [_nTotAssoc, 2]
				reclock ("_trb", .F.)
				_trb -> tot_assoc = _aTotAssoc [_nTotAssoc, 3]
				if _trb -> tot_assoc < mv_par09
					_trb -> Motivo = "Abaixo do valor minimo"
				endif
				msunlock ()
			endif
			_trb -> (dbskip ())
		enddo
	next


	if ! empty (_sErros)
		u_log2 ('erro', _sErros)
		u_showmemo ('Foram encontrados erros durante o processo:' + chr (13) + chr (10) + _sErros)
	endif

	if _lContinua
		_trb -> (dbgotop ())
		if U_MsgYesNo ("Deseja exportar para uma planilha para conferencia?")
			U_TRB2XLS ('_trb')
		endif
		if U_MsgNoYes ("Confirma a geracao dos titulos" + iif (! empty (_sErros), " mesmo com os erros apontados", "") + "?")

			// Grava evento para posterior consulta
			_oEvento := ClsEvent():new ()
			_oEvento:Texto = "Iniciando geracao de titulos de pagamento de frete safra a associados" + chr (13) + chr (10)
			if ! empty (_sErros)
				_oEvento:Texto += "Mesmo com as seguintes mensagens:" + chr (13) + chr (10) + _sErros
			endif
			_oEvento:LeParam (cPerg)
			_oEvento:CodEven = 'SZI003'
			_oEvento:Grava ()

			_GeraTit ()
		endif
	endif

	_trb -> (dbclosearea ())

return



// --------------------------------------------------------------------------
// Gera os titulos no financeiro.
static function _GeraTit ()
	local _sAssoc   := ""
	local _sLoja    := ""
	local _nValFre  := 0
	local _aAutoSE2 := {}
//	local _aRetParc := {}
	local _sNumTit  := '00000' + mv_par01
	local _sSafra   := mv_par01
	local _dVencto  := mv_par02
	local _sPref    := mv_par07
	local _sParcela := mv_par08
//	local _nVlrMin  := mv_par09
	local _sHist    := ""
//	local _aSld2017 := {}
//	local _nSld2017 := 0
	local _sChvEx   := "FRTSAFRA" + _sSafra
	local _sJahTem  := ""
	local _nQtGer   := 0
	local _nVlGer   := 0
	local _aBkpSX1  := {}
	private _sErroAuto := ""  // Deixar private para ser atualizada pela funcao U_HELP().

	// Ajusta parametros da rotina.
	cPerg = 'FIN050    '
	_aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
	U_GravaSX1 (cPerg, "04", 2)  // Contabiliza on-line = nao

	procregua (_trb -> (reccount ()))
	_trb -> (dbgotop ())
	do while ! _trb -> (eof ())
		_sAssoc = _trb -> associado
		_sLoja  = _trb -> loja
		_nValFre = _trb -> tot_assoc
		_sHist = 'Aux.frete safra ' + _sSafra

		if _nValFre > 0 .and. empty (_trb -> Motivo)

			// Verifica se jah gerou para este associado.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""                                                                                            
			_oSQL:_sQuery += " select E2_NUM"
			_oSQL:_sQuery +=   " from " + RetSQLName ("SE2") + " SE2 "
			_oSQL:_sQuery +=  " where SE2.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=    " and SE2.E2_FILIAL   = '" + xfilial ("SE2")   + "'"
			_oSQL:_sQuery +=    " and SE2.E2_FORNECE  = '" + _sAssoc   + "'"
			_oSQL:_sQuery +=    " and SE2.E2_LOJA     = '" + _sLoja    + "'"
			_oSQL:_sQuery +=    " and SE2.E2_PREFIXO  = '" + _sPref    + "'"
			_oSQL:_sQuery +=    " and SE2.E2_PARCELA  = '" + _sParcela + "'"
			_oSQL:_sQuery +=    " and SE2.E2_VACHVEX  = '" + _sChvEx   + "'"
			//_oSQL:Log ()
			_sJahTem = _oSQL:RetQry (1, .F.)
			if ! empty (_sJahTem)
				_Erro ("Associado " + _sAssoc + '/' + _sLoja + ' ja tem o titulo ' + _sJahTem + ' gerado para esta finalidade.')
			else
			
				// Gera titulo no contas a pagar.
				_aAutoSE2 := {}
				aadd (_aAutoSE2, {"E2_PREFIXO", _sPref,    NIL})
				aadd (_aAutoSE2, {"E2_NUM"    , _sNumTit,  Nil})
				aadd (_aAutoSE2, {"E2_TIPO"   , 'DP',      Nil})
				aadd (_aAutoSE2, {"E2_FORNECE", _sAssoc,   Nil})
				aadd (_aAutoSE2, {"E2_LOJA"   , _sLoja,    Nil})
				aadd (_aAutoSE2, {"E2_EMISSAO", ddatabase, Nil})
				aadd (_aAutoSE2, {"E2_VENCTO" , _dVencto,  Nil})
				aadd (_aAutoSE2, {"E2_VALOR"  , _nValFre,  Nil})
				aadd (_aAutoSE2, {"E2_HIST"   , _sHist,    Nil})
				aadd (_aAutoSE2, {"E2_PARCELA", _sParcela, Nil})
				aadd (_aAutoSE2, {"E2_VACHVEX", _sChvEx,   Nil})
				_aAutoSE2 := aclone (U_OrdAuto (_aAutoSE2))
				_nQtGer ++
				_nVlGer += _nValFre

				lMsErroAuto	:=	.f.
				lMsHelpAuto	:=	.f.
				_sErroAuto  := ''
				dbselectarea ("SE2")
				dbsetorder (1)
				MsExecAuto({ | x,y,z | Fina050(x,y,z) }, _aAutoSE2,, 3)
				if lMsErroAuto .or. ! empty (_sErroAuto)
					if ! empty (NomeAutoLog ())
						u_log2 ('erro', U_LeErro (memoread (NomeAutoLog ())))
					endif
					MostraErro ()
				else
					u_log2 ('info', 'Gerado titulo ' + se2 -> e2_num + '/' + se2 -> e2_prefixo + '-' + se2 -> e2_parcela + ' para assoc. ' + se2 -> e2_fornece + ' valor: ' + transform (se2 -> e2_valor, '@E 999,999.99'))
				endif
			endif
		else
			u_log2 ('info', 'Assoc/loja sem valor a gerar: ' + _sAssoc + '/' + _sLoja)
		endif

		// Descarta os demais registros deste associado (soh devo gerar um registro pelo total
		do while ! _trb -> (eof ()) .and. _trb -> associado == _sAssoc .and. _trb -> loja == _sLoja
			_trb -> (dbskip ())
		enddo

	enddo
	
	// Restaura parametros da rotina.
	U_SalvaSX1 (cPerg, _aBkpSX1)

	// Notifica setores que podem querer complementar custos dos produtos, contabilizar, etc.
	if _nQtGer > 0
		U_ZZUNU ({'116', '052'}, ;
		          "Geracao de titulos a pagar ref. frete safra", ;
		         "Aviso do sistema: foram gerados titulos a pagar para associados, referentes a frete da uva, na filial " + cFilAnt + chr (13) + chr (10) + ;
		         "Quantidade de titulos gerados: " + cvaltochar (_nQtGer) + ", somando o valor de $ " + cvaltochar (_nVlGer))
	endif

	u_help ("Processo finalizado. " + cvaltochar (_nQtGer) + " titulos gerados, somando o valor de $ " + cvaltochar (_nVlGer))
return



// --------------------------------------------------------------------------
static function _Erro (_sMsg)
	if ! _sMsg $ _sErros
		u_log2 ('Erro', _sMsg)
		_sErros += _sMsg + chr (13) + chr (10)
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes Help
	aadd (_aRegsPerg, {01, "Safra                         ", "C", 4,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {02, "Data para pagamento           ", "D", 8,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {03, "Associado inicial             ", "C", 6,  0,  "",   "SA2_AS", {},    ""})
	aadd (_aRegsPerg, {04, "Loja associado inicial        ", "C", 2,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {05, "Associado final               ", "C", 6,  0,  "",   "SA2_AS", {},    ""})
	aadd (_aRegsPerg, {06, "Loja associado final          ", "C", 2,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {07, "Gerar com qual prefixo?       ", "C", 3,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {08, "Gerar com qual parcela?       ", "C", 1,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {09, "Valor minimo a gerar titulo   ", "N", 6,  2,  "",   "      ", {},    ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
