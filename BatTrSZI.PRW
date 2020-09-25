// Programa:   BatTrSZI
// Autor:      Robert Koch
// Data:       10/10/2012
// Descricao:  Gera lcto. de entrada de transf. de saldo na conta corrente de associados (SZI)
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
// 26/10/2015 - Robert - Criado atributo SeqOrig na classe ClsCtaCorr (passa a ser exigido para inclusao por transf. de outra filial).
// 06/11/2015 - Robert - Valida tambem o valor na leitura do SE5 para tratar casos de transf. parcial do titulo.
// 16/04/2016 - Robert - Busca forma pagto, bco, ag, conta, parcela e data vcto. do movimento original.
// 28/03/2018 - Robert - Nao buscava corretamente a data de vencimento do titulo na filial original.
// 29/07/2020 - Robert - Busca SE5 por num+pref_parc e nao mais por CHVEX.
//                     - Inseridas tags para catalogacao de fontes
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao
// #Descricao         #Batch que importa os lançamentos de conta corrente de associados transferidos de outra filial.
// #PalavasChave      #conta_corrente_associados #transferencia
// #TabelasPrincipais #SZI #SE2
// #Modulos           #COOP

// --------------------------------------------------------------------------
user function BatTrSZI (_sAssoc, _sLoja, _sSeqSZI, _sEmpOrig, _sFilOrig, _sFilDest, _sTM, _sDtMovto, _nValor)
	local _lContinua := .T.
	local _oCtaCorr  := NIL
	local _oAssoc    := NIL
	local _oSQL      := NIL
	local _aRegOri   := {}
	local _dVctoSE2  := ctod ('')

	u_log2 ('info', 'Associado: ' + _sAssoc + '/' + _sLoja + ' Seq SZI: ' + _sSeqSZI)

	if _lContinua .and. _sEmpOrig + _sFilDest != cNumEmp
		u_help ("Movimento nao destinado a esta empresa/filial.",, .t.)
		_lContinua = .F.
	endif
	if _lContinua
		_oAssoc := ClsAssoc():New (_sAssoc, _sLoja)
		if valtype (_oAssoc) != "O"
			u_help ("Nao foi possivel instanciar objeto ClsAssoc.",, .t.)
			_lContinua = .F.
		endif
	endif

	// Verifica movimento que originou este batch.
	if _lContinua
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT ZI_DOC, ZI_SERIE, ZI_MESREF, ZI_HISTOR, E5_VALOR, ZI_FORMPAG, ZI_BANCO, ZI_AGENCIA, ZI_NUMCON, E5_PARCELA"
		_oSQL:_sQuery +=  " FROM SZI" + _sEmpOrig + "0 SZI, "
		_oSQL:_sQuery +=       " SE5" + _sEmpOrig + "0 SE5, "
		_oSQL:_sQuery +=         RetSQLName ("SA6") + " SA6 "
		_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZI_FILIAL  = '" + _sFilOrig + "'"
		_oSQL:_sQuery +=   " AND ZI_ASSOC   = '" + _oAssoc:Codigo + "'"
		_oSQL:_sQUery +=   " AND ZI_LOJASSO = '" + _oAssoc:Loja + "'"
		_oSQL:_sQUery +=   " AND ZI_TM      = '" + _sTM + "'"
		_oSQL:_sQUery +=   " AND ZI_SALDO   = 0"
		_oSQL:_sQUery +=   " AND ZI_SEQ     = '" + _sSeqSZI + "'"
		_oSQL:_sQuery +=   " AND SE5.E5_FILIAL   = SZI.ZI_FILIAL"

	//	_oSQL:_sQuery +=   " AND SE5.E5_VACHVEX  = 'SZI' + SZI.ZI_ASSOC + SZI.ZI_LOJASSO + SZI.ZI_SEQ"
		_oSQL:_sQuery +=   " AND E5_FILIAL  = ZI_FILIAL"
		_oSQL:_sQuery +=   " AND E5_CLIFOR  = ZI_ASSOC"
		_oSQL:_sQUery +=   " AND E5_LOJA    = ZI_LOJASSO"
		_oSQL:_sQUery +=   " AND E5_NUMERO  = ZI_DOC"
		_oSQL:_sQUery +=   " AND E5_PREFIXO = ZI_SERIE"
		_oSQL:_sQUery +=   " AND E5_PARCELA = ZI_PARCELA"

		_oSQL:_sQuery +=   " AND SE5.E5_SITUACA != 'C'"
		_oSQL:_sQuery +=   " AND SE5.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND SE5.E5_FILORIG  = SZI.ZI_FILIAL"
		_oSQL:_sQUery +=   " AND SE5.E5_DATA     = '" + _sDtMovto + "'"
		_oSQL:_sQuery +=   " AND SE5.E5_BANCO    = A6_COD"
		_oSQL:_sQuery +=   " AND SE5.E5_AGENCIA  = A6_AGENCIA"
		_oSQL:_sQuery +=   " AND SE5.E5_CONTA    = A6_NUMCON"
		_oSQL:_sQuery +=   " AND SE5.E5_VALOR    = " + cvaltochar (_nValor)
		_oSQL:_sQuery +=   " AND dbo.VA_SE5_ESTORNO (SE5.R_E_C_N_O_) = 0"
		_oSQL:_sQuery +=   " AND SA6.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND SA6.A6_FILIAL   = SZI.ZI_FILIAL"
		_oSQL:_sQuery +=   " AND SA6.A6_CONTA    = '101010201099'"  // Conta transitoria entre filiais na contabilidade.
		//_oSQL:Log ()
		_aRegOri := aclone (_oSQL:Qry2Array (.f., .f.))
		if len (_aRegOri) == 0
			u_help ("Nao encontrei o movimento de baixa da conta corrente na filial de origem, ou a baixa nao foi feita via conta transitoria, ou ainda tem saldo na conta corrente, ou o valor nao confere.", "Consulta usada: " + _oSQL:_sQuery, .T.)
			_lContinua = .F.
		endif
	endif

	if _lContinua

		// Busca dados do SE2, caso exista (nem todos os movimentos geram SE2).
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""                                                                                            
		_oSQL:_sQuery += " SELECT TOP 1 E2_VENCTO"  // Soh deveria encontrar uma ocorrencia, mas usei TOP 1 para garantir.
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2 "
		_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ != '*'"
		//_oSQL:_sQuery +=    " AND SE2.E2_FILIAL   = '" + xfilial ("SE2")  + "'"
		_oSQL:_sQuery +=    " AND SE2.E2_FILIAL   = '" + _sFilOrig        + "'"
		_oSQL:_sQuery +=    " AND SE2.E2_FORNECE  = '" + _oAssoc:Codigo   + "'"
		_oSQL:_sQuery +=    " AND SE2.E2_LOJA     = '" + _oAssoc:Loja     + "'"
		_oSQL:_sQuery +=    " AND SE2.E2_NUM      = '" + _aRegOri [1, 1]  + "'"
		_oSQL:_sQuery +=    " AND SE2.E2_PREFIXO  = '" + _aRegOri [1, 2]  + "'"
		_oSQL:_sQuery +=    " AND SE2.E2_PARCELA  = '" + _aRegOri [1, 10] + "'"
		//_oSQL:Log ()
		_dVctoSE2 = _oSQL:RetQry ()

		_oCtaCorr := ClsCtaCorr():New ()
		_oCtaCorr:Assoc      = _oAssoc:Codigo
		_oCtaCorr:Loja       = _oAssoc:Loja
		_oCtaCorr:SeqOrig    = _sSeqSZI
		_oCtaCorr:TM         = _sTM
		_oCtaCorr:FilOrig    = _sFilOrig
		_oCtaCorr:DtMovto    = iif (stod (_sDtMovto) < dDataBase, dDataBase, stod (_sDtMovto))
		_oCtaCorr:Doc        = _aRegOri [1, 1]
		_oCtaCorr:Serie      = _aRegOri [1, 2]
		_oCtaCorr:MesRef     = _aRegOri [1, 3]
		_oCtaCorr:Histor     = 'TR.SLD.FIL.' + _sFilOrig + ' ' + _aRegOri [1, 4]
		_oCtaCorr:Valor      = _aRegOri [1, 5]
		_oCtaCorr:FormPag    = _aRegOri [1, 6]
		_oCtaCorr:Banco      = _aRegOri [1, 7]
		_oCtaCorr:Agencia    = _aRegOri [1, 8]
		_oCtaCorr:NumCon     = _aRegOri [1, 9]
		_oCtaCorr:Parcela    = _aRegOri [1, 10]
		_oCtaCorr:VctoSE2    = _dVctoSE2
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

	u_log2 ('info', 'Execucao finalizada.')
return _lContinua
