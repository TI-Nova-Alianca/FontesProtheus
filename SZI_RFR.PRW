// Programa...: SZI_RFR
// Autor......: Robert Koch
// Data.......: 07/12/2021
// Descricao..: Gera restituicao de FUNRURAL na conta corrente de associados (GLPI 11359)
//              Eh costume da Cooperativa pagar o FUNRURAL sobre a compra da uva.
//              Alguns associados podem restituir esse valor para a Cooperativa como uma especie de multa.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Geracao de restituicao de FUNRURAL de associados sobre a compra da uva.
// #PalavasChave      #FUNRURAL #restituicao #associados #conta_corrente_associados
// #TabelasPrincipais #SZI #SE2
// #Modulos           #COOP

// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function SZI_RFR ()
	local _lContinua   := .T.
	local cCadastro    := "Gera restituicao de FUNRURAL conta corrente associados"
	local aSays        := {}
	local aButtons     := {}
	local nOpca        := 0
	local lPerg        := .F.
	local _nLock       := 0
	Private cPerg      := "SZI_RFR"

	u_log2 ('INFO', 'Iniciando processo de restituicao de FUNRURAL associados.')

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if _lContinua
		_lContinua = U_ZZUVL ('051', __cUserID, .T.)
	endif

	// Somente uma estacao por vez.
	if _lContinua
		_nLock := U_Semaforo (procname (), .F.)
		if _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.",, .t.)
			return
		endif
	endif

	if _lContinua
		_ValidPerg ()
		Pergunte (cPerg, .F.)
	endif

	if _lContinua
		AADD(aSays,"Este programa gera movimentos de restituicao de FUNRURAL")
		AADD(aSays," na conta corrente associados")
		AADD(aSays,"")
		
		AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
	
		If nOpca == 1
			u_logsx1 ()
			Processa( {|lEnd| _GodSaveMe ()})
		Endif

		// Libera semaforo.
		if _nLock > 0
			U_Semaforo (_nLock)
		endif
	endif
	u_log2 ('INFO', 'Processo de geracao de restituicao de FUNRURAL associados finalizado.')
return



// --------------------------------------------------------------------------
Static Function _TudoOk ()
	Local _lRet     := .T.
Return _lRet



// --------------------------------------------------------------------------
Static Function _GodSaveMe ()
	local _lContinua  := .T.
	local _oSQL       := NIL
	local _sSafraRef  := mv_par05  // Guarda em variaveis locais por que as 'mv_par' serao usadas por rotinas automaticas.
	local _sTMRFR     := '33'
	local _aAssoc     := {}
	local _nAssoc     := 0
	local _aCols      := {}
	local _oCtaCorr   := NIL
	local _sDoc       := strtran (dtoc (dDataBase), '/', '')
	local _sSerie     := U_RetZX5 ('10', _sTMRFR, 'ZX5_10PREF')

	if _lContinua .and. empty (_sSerie)
		u_help ("Nao foi possivel determinar o prefixo a ser usado na geracao dos movimentos, cfe. TM '" + _sTMRFR + "'. Processamento cancelado.",, .t.)
		_lContinua = .F.
	endif

	// Busca os associados para os quais pode ser gerada restituicao.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT ' ' AS OK, V.ASSOCIADO, V.LOJA_ASSOC, V.NOME_ASSOC"
		_oSQL:_sQuery +=       ", SUM (V.VLR_FUNRURAL)"
		_oSQL:_sQuery +=       ", STRING_AGG (RTRIM (V.DOC), ', ')"
		_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
		_oSQL:_sQuery +=  " WHERE V.SAFRA = '" + _sSafraRef + "'"
		_oSQL:_sQuery +=    " AND V.ASSOCIADO + V.LOJA_ASSOC BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
		_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                      " FROM " + RetSqlName ("SZI") + " SZI "
		_oSQL:_sQuery +=                     " WHERE SZI.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=                       " AND SZI.ZI_ASSOC = V.ASSOCIADO"
		_oSQL:_sQuery +=                       " AND SZI.ZI_LOJASSO = V.LOJA_ASSOC"
		_oSQL:_sQuery +=                       " AND SZI.ZI_TM = '" + _sTMRFR + "'"
		_oSQL:_sQuery +=                       " AND SZI.ZI_SAFRA = V.SAFRA)"
		_oSQL:_sQuery +=  " GROUP BY V.NOME_ASSOC, V.ASSOCIADO, V.LOJA_ASSOC"
		_oSQL:_sQuery +=  " HAVING SUM (V.VLR_FUNRURAL) > 0"
		_oSQL:_sQuery +=  " ORDER BY V.NOME_ASSOC, V.ASSOCIADO, V.LOJA_ASSOC"
		_oSQL:Log ()
		_aAssoc = _oSQL:Qry2Array ()
		if len (_aAssoc) == 0
			u_help ("Nao encontrei nenhum associado em condicoes de restituir FUNRURAL. Verifique se foi calculado FUNRURAL para a safra informada. Tambem nao pode ser gerado novo lcto para associado que ja tiver movimento '" + _sTMRFR + "' na conta corrente para esta safra.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		// Transforma a primeira coluna em valor logico para poder usar na funcao MBArray().
		for _nAssoc = 1 to len (_aAssoc)
			_aAssoc [_nAssoc, 1] = .F.
		next

		// Tela de selacao para o usuario marcar os associados a processar.
		_aCols = {}
		aadd (_aCols, {2,  'Associado',    6, ''})
		aadd (_aCols, {3,  'Loja',         2, ''})
		aadd (_aCols, {4,  'Nome',       120, ''})
		aadd (_aCols, {5,  'Valor total', 70, '@E 999,999,999.99'})
		U_MbArray (@_aAssoc, 'Selecione associados', _aCols, 1, NIL, NIL, '.T.')

		procregua (len (_aAssoc))
		for _nAssoc = 1 to len (_aAssoc)
			incproc ()
			if _aAssoc [_nAssoc, 1]
				_oAssoc := ClsAssoc():New (_aAssoc [_nAssoc, 2], _aAssoc [_nAssoc, 3])
				incproc (_oAssoc:Codigo + "/" + _oAssoc:Loja + ' - ' + _oAssoc:Nome)
				u_log2 ('info', 'Iniciando assoc: ' + _oAssoc:Codigo + "/" + _oAssoc:Loja + ' - ' + _oAssoc:Nome)

				// Gera novo movimento na conta corrente.
				_oCtaCorr := ClsCtaCorr():New ()
				_oCtaCorr:Assoc      = _oAssoc:Codigo
				_oCtaCorr:Loja       = _oAssoc:Loja
				_oCtaCorr:TM         = _sTMRFR
				_oCtaCorr:DtMovto    = dDataBase
				_oCtaCorr:Doc        = _sDoc
				_oCtaCorr:Serie      = _sSerie
				_oCtaCorr:MesRef     = substr (dtos (_oCtaCorr:DtMovto), 5, 2) + substr (dtos (_oCtaCorr:DtMovto), 1, 4)
				_oCtaCorr:Histor     = 'REST.FUNRURAL/FRETE/PREMIO SAFRA ' + _sSafraRef
				_oCtaCorr:Valor      = _aAssoc [1, 5]
				_oCtaCorr:Safra      = _sSafraRef
				_oCtaCorr:Obs        = "COBRANCA FUNRURAL SAFRA " + _sSafraRef + " REF.NF " + alltrim (_aAssoc [1, 6])
				if _oCtaCorr:PodeIncl ()
					if ! _oCtaCorr:Grava ()
						u_help ("Erro na inclusao do movimento na conta corrente.",, .t.)
						_lContinua = .F.
					else
						u_log2 ('info', 'Mov. incluido no SZI com seq.: ' + _oCtaCorr:SeqSZI)
					endif
				else
					u_help ("Inclusao do movimento na conta corrente nao permitida." + _oCtaCorr:UltMsg,, .T.)
					_lContinua = .F.
				endif
			endif
		next
	endif
return




// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                    Help
	aadd (_aRegsPerg, {01, "Produtor inicial              ", "C", tamsx3 ("A2_COD")[1],  0,  "",   "SA2_AS", {},    "Codigo associado inicial para filtragem de registros"})
	aadd (_aRegsPerg, {02, "Loja produtor inicial         ", "C", tamsx3 ("A2_LOJA")[1], 0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {03, "Produtor final                ", "C", tamsx3 ("A2_COD")[1],  0,  "",   "SA2_AS", {},    "Codigo associado final para filtragem de registros"})
	aadd (_aRegsPerg, {04, "Loja produtor final           ", "C", tamsx3 ("A2_LOJA")[1], 0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {05, "Safra referencia              ", "C", 6,                     0,  "",   "      ", {},    ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
