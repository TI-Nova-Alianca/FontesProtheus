// Programa...: FTSAFRA
// Autor......: Catia Cardoso	
// Data.......: 22/04/2017
// Descricao..: Agrupa notas de safra, gerando uma fatura com os vencimentos desejados conforme regra pagamento safra vigente
//
// Historico de alteracoes:
//
// 22/04/2017 - Catia  - Gerar a 1a.parcela da Safra de 2017
// 17/07/2017 - Catia  - Gerar a 2a.parcela da Safra de 2017 
// 26/03/2018 - Catia  - Gerar a 1a.parcela da Safra de 2018
// 28/03/2018 - Catia  - Alterado o historio da geracao das faturas
//            - Robert - Verifica se a data base encontra-se no mesmo mes dos titulos.
// 26/03/2019 - Robert - Criados parametros SAFRA e COND PAG
// 05/04/2019 - Robert - Criados parametros data emissao titulo (necessarios para rot.automatica)
//                     - Regua de processamento
// 06/07/2020 - Robert - Permite utilizar faturas na geracao de nova fatura. Verifica se E2_FATURA = 'NOTFAT'.
//                     - Gera fatura somente se tiver mais de 1 titulo para agrupar.
// 24/07/2020 - Robert - Verifica se existem faturas com NOTFAT (ficariam fora do processo) e confirma com o usuario.
//                      - Inseridas tags para catalogacao de fontes
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao
// #Descricao         #Gera faturas a pagar agrupando mais de um titulo, para pagamento de safra a associados.
// #PalavasChave      #safra #pagamento #conta_corrente_associados #fatura
// #TabelasPrincipais #SE2
// #Modulos           #COOP #FIN

#include "rwmake.ch"
#include "tbiconn.ch"

// --------------------------------------------------------------------------
user function FTSAFRA
	if cFilAnt != '01' .and. ! U_MsgNoYes ("Este programa destina-se inicialmente a ser executado na matriz. Confirma mesmo assim?")
		return
	endif

	private cPerg := "FTSAFRA"
	_ValidPerg ()
	if pergunte (cPerg, .T.)
		processa ({|| _gera ()})
	endif
return


// --------------------------------------------------------------------------
static function _Gera ()
	local _sQuery     := ""
	local _sMsgErro   := ""
	Local aFatPag     := {}
	local aTit        := {}
	local _wnumero    := ''
	local _sSafra     := ''
	local _sCondPag   := ''
	local _aTestCond  := {}
	local _nVcto      := 0
	local _sMsgVcto   := ''
	local _nTotGer    := 0
	local _dEmisIni   := ctod ('')
	local _dEmisFim   := ctod ('')
	local i			  := 0
	local t			  := 0
	local _oSQL       := NIL
	local _lContinua  := .T.
	private lMsHelpAuto := .F.
	private lMsErroAuto := .F.
	private _sErroAuto := ""  // Deixar private para que a funcao U_Help possa gravar possiveis mensagens durante as rotinas automaticas.

	u_log2 ('info', 'Iniciando processamento')
	u_logsx1 ()
	
	_sSafra = mv_par07
	_sCondPag = mv_par08
	_dEmisIni = mv_par09
	_dEmisFim = mv_par10
	
	if _lContinua
		// busca nro da proxima fatura
		_sQuery := ""
		_sQuery += " SELECT MAX(E2_NUM)"
		_sQuery += "   FROM " + RetSQLName ("SE2")
		_sQuery += "  WHERE D_E_L_E_T_ = ''"
		_sQuery += "    AND E2_FILIAL  = '" + cFilAnt + "'"
		_sQuery += "    AND E2_PREFIXO = '30'"
		_sQuery += "    AND E2_TIPO    = 'FAT'"
		_sQuery += "    AND E2_EMISSAO >= '" + _sSafra + "0101'"
		aFatura := U_Qry2Array(_sQuery)
		_wnumero = aFatura [1,1]
		
		if _wnumero < _sSafra + '00001'
			_wnumero = _sSafra + '00001'
		endif
		
		_wdataini = dtos (mv_par05)
		_wdatafim = dtos (mv_par06)
		_wfornini = mv_par01 + mv_par02
		_wfornfim = mv_par03 + mv_par04
		
		// Deixa WHERE pronto para usar em mais de um local.
		_sWhere := ""
		_sWhere += "   FROM " + RetSQLName ("SE2")
		_sWhere += "  WHERE D_E_L_E_T_ = ''"
		_sWhere += "    AND E2_FILIAL  = '" + xfilial ("SE2") + "'"
		_sWhere += "    AND E2_FORNECE + E2_LOJA BETWEEN '" + _wfornini + "' AND '" + _wfornfim + "'"
		_sWhere += "    AND E2_EMISSAO >= '" + _sSafra + "0101'"
		_sWhere += "    AND E2_VENCREA BETWEEN '" + _wdataini + "' AND '" + _wdatafim + "'"
		_sWhere += "    AND (E2_PREFIXO ='30' OR E2_PREFIXO ='31')"
		_sWhere += "    AND E2_SALDO   > 0"
		_sWhere += "    AND E2_TIPO IN " + FormatIn (mv_par11, '/')
	//	_sWhere += "    AND E2_FATURA != 'NOTFAT'"  // O sistema gera NOTFAT nesse campo para que faturas nao possam mais gerar novas faturas.
		_sWhere += "    AND EXISTS (SELECT 1" 
		_sWhere += "                  FROM " + RetSQLName ("SZI") + " AS SZI"
		_sWhere += "                 WHERE SZI.D_E_L_E_T_ = ''"
		_sWhere += "                   AND SZI.ZI_FILIAL  = E2_FILIAL"
		_sWhere += "                   AND SZI.ZI_ASSOC   = E2_FORNECE"
		_sWhere += "                   AND SZI.ZI_LOJASSO = E2_LOJA"
		_sWhere += "                   AND SZI.ZI_DOC     = E2_NUM"
		_sWhere += "                   AND SZI.ZI_SERIE   = E2_PREFIXO"
		_sWhere += "                   AND SZI.ZI_PARCELA = E2_PARCELA"
		_sWhere += "                   AND SZI.ZI_TM      = '13'"
		_sWhere += "                )"
	endif

	// Verifica se o usuario quer agrupar faturas nao agrupaveis (um engano comum)
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT COUNT (*), sum (E2_SALDO)"
		_oSQL:_sQuery += _sWhere
		_oSQL:_sQuery += " AND E2_FATURA = 'NOTFAT'"
		_aNotFat = aclone (_oSQL:Qry2Array ())
		if _aNotFat [1, 1] > 0
			_lContinua = U_MsgNoYes ("ATENCAO: A parametrizacao informada pretende abranger " + cvaltochar (_aNotFat [1, 1]) + " titulos, somando R$ " + cvaltochar (_aNotFat [1, 2]) + " que ja sao faturas e, portanto, NAO PODEM MAIS ser agrupadas. Confirma assim mesmo?")
		endif
	endif

	
	// Valida com o usuario o total previsto e os vencimentos a serem gerados.
	if _lContinua

		// Acrescenta clausula final ao WHERE
		_sWhere += "    AND E2_FATURA != 'NOTFAT'"  // O sistema gera NOTFAT nesse campo para que faturas nao possam mais gerar novas faturas.

		// seleciona fornecedores que precisa fazer o agrupamento
		_sQuery := ""
		_sQuery += " SELECT E2_FORNECE, E2_LOJA, SUM (E2_SALDO)"
		_sQuery += _sWhere
		_sQuery += " GROUP BY E2_FORNECE, E2_LOJA"
		_sQuery += " ORDER BY E2_FORNECE, E2_LOJA"
		u_log2 ('debug', _sQuery)
		aDados := U_Qry2Array(_sQuery)
		_nTotGer = 0
		for i=1 to len(aDados)
			_nTotGer += aDados [i, 3]
		next
		_aTestCond := condicao (_nTotGer, _sCondPag,, date ())
		_sMsgVcto = ''
		for _nVcto = 1 to len (_aTestCond)
			_sMsgVcto += dtoc (_aTestCond [_nVcto, 1]) + '  -  '
		next
		if ! U_MsgYesNo ("Saldo total de titulos encontrados para gerar fatura: " + cvaltochar (_nTotGer) + " ; a fatura vai ser gerada com a(s) seguinte(s) data(s) de vencimento:" + chr (10) + chr (13) + _sMsgVcto + chr (10) + chr (13) + "Confirma?")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		procregua (len(aDados))
		_nTotGer = 0
		for i=1 to len(aDados)
			_wfornece = aDados [i,1]
			_wloja    = aDados [i,2]
			_wnumero  = soma1 (_wnumero)
			aFatPag     := {}
			aTit        := {}
			incproc ("Associado " + _wfornece + " (" + cvaltochar (i) + " de " + cvaltochar (len(aDados)) + ")")
		
			// busca titulos do fornecedor
			_sQuery := ""
			_sQuery += " SELECT E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, '' "
			_sQuery += _sWhere
			_sQuery += "    AND E2_FORNECE = '" + _wfornece + "'"
			_sQuery += "    AND E2_LOJA    = '" + _wloja + "'"
			aTitulos :=aclone (U_Qry2Array(_sQuery))
			
			//u_showarray(aTitulos)
			
			for t=1 to len (aTitulos)
				aTitulos [t,5] = .F.
			next

			if len (aTitulos) < 2
				u_log2 ('info', 'Fornecedor ' + _wfornece + '/' + _wloja + ' tem apenas ' + cvaltochar (len (aTitulos)) + ' titulo(s). Nao vou gerar fatura.')
			else
				// seta campos do array da fatura a ser gerada		                                                                                         
				Aadd(aFatPag, "30 ")                                //-- Prefixo
				Aadd(aFatPag, "FAT")                                //-- Tipo
				Aadd(aFatPag, _wnumero)                             //-- Numero da Fatura (se o numero estiver em branco obtem pelo FINA290)
				Aadd(aFatPag, "120201    ")                         //-- Natureza
				Aadd(aFatPag, _dEmisIni)                            //-- Data emissao inicial
				Aadd(aFatPag, _dEmisFim)                            //-- Data emissao final
				Aadd(aFatPag, _wfornece)                            //-- Fornecedor
				Aadd(aFatPag, _wloja)                               //-- Loja
				Aadd(aFatPag, _wfornece)                            //-- Fornecedor para geracao
				Aadd(aFatPag, _wloja)                               //-- Loja do fornecedor para geracao
				Aadd(aFatPag, _sCondPag)                            //-- Condicao de pagto
				Aadd(aFatPag, 01)                                   //-- Moeda
				Aadd(aFatPag, aclone(aTitulos) )                    //-- ARRAY com os titulos da fatura (Prefixo,Numero,Parcela,Tipo,Título localizado na geracao de fatura (lógico). Iniciar com falso.)
				Aadd(aFatPag, 0)                                    //-- Valor de decrescimo
				Aadd(aFatPag, 0)                                    //-- Valor de acrescimo

				u_log2 ('info', 'Gerando fatura ' + _wnumero + ' para o fornecedor ' + _wfornece + '/' + _wLoja + ' agrupando os seguintes titulos:')
				u_log2 ('info', aTitulos)

				_sMsgErro = ''
				dbselectarea("SE2")
				dbsetorder(1)
				set filter to
				dbgotop ()
				lMsErroAuto  := .F.
				MsExecAuto( { |x,y| FINA290(x,y)},3,aFatPag,)
				If lMsErroAuto
					if ! empty (_sErroAuto)
						_sMsgErro += _sErroAuto + '; '
					endif
					if ! empty (NomeAutoLog ())
						_sMsgErro += U_LeErro (memoread (NomeAutoLog ())) + '; '
					endif
					u_help ('Rotina automatica retornou erro: ' + _sMsgErro,, .t.)
					MostraErro()
				else
					
					// Zera os saldos da conta corrente para os titulos aglutinados na fatura.
					_ZeraSZI (_wFornece, _wLoja, aTitulos)
												
					// altera o historio e deixa posicionado o E2 para cria conta corrente referente a este titulo.
					dbselectarea("SE2")
					dbsetorder(1)
					if dbseek(xfilial ("SE2") + '30 ' + _wnumero)
						reclock("SE2", .F.)
						SE2->E2_HIST := 'FAT.PAG.SAFRA ' + _sSafra // Quando juntava parcela A com B dava confusao --->  + '(' + SE2 -> E2_PARCELA + ')'
						MsUnLock()
						_nTotGer += se2 -> e2_valor
						_CriaSZI (_sSafra)
					endif
				endif
			endif
		next
	endif

	u_help ("Geracao de Faturas da SAFRA concluida. Valor total gerado: " + cvaltochar (_nTotGer))
return



// --------------------------------------------------------------------------
// Zera conta corrente dos titulos acumulados na fatura.
static function _ZeraSZI (_sFornece, _sLoja, _aTit)
	local _oSQL    := NIL
	local _nTit    := 0
	local _nRegSZI := 0

	for _nTit = 1 to len (_aTit)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " SELECT SZI.R_E_C_N_O_"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SZI") + " SZI, "
		_oSQL:_sQuery +=            RetSQLName ("SE2") + " SE2 "
		_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND SZI.ZI_FILIAL  = SE2.E2_FILIAL"
		_oSQL:_sQuery += " AND SZI.ZI_ASSOC   = SE2.E2_FORNECE"
		_oSQL:_sQuery += " AND SZI.ZI_LOJASSO = SE2.E2_LOJA"
		_oSQL:_sQuery += " AND SZI.ZI_DOC     = SE2.E2_NUM"
		_oSQL:_sQuery += " AND SZI.ZI_SERIE   = SE2.E2_PREFIXO"
		_oSQL:_sQuery += " AND SZI.ZI_PARCELA = SE2.E2_PARCELA"
		_oSQL:_sQuery += " AND SE2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND SE2.E2_FILIAL  = '" + xfilial ("SE2") + "'"
		_oSQL:_sQuery += " AND SE2.E2_FORNECE = '" + _sFornece + "'"
		_oSQL:_sQuery += " AND SE2.E2_LOJA    = '" + _sLoja + "'"
		_oSQL:_sQuery += " AND SE2.E2_PREFIXO = '" + _aTit [_nTit, 1] + "'"
		_oSQL:_sQuery += " AND SE2.E2_NUM     = '" + _aTit [_nTit, 2] + "'"
		_oSQL:_sQuery += " AND SE2.E2_PARCELA = '" + _aTit [_nTit, 3] + "'"
		_oSQL:_sQuery += " AND SE2.E2_TIPO    = '" + _aTit [_nTit, 4] + "'"
		_nRegSZI = _oSQL:RetQry ()
		if _nRegSZI > 0
			szi -> (dbgoto (_nRegSZI))
			reclock ("SZI", .F.)
			szi -> zi_saldo = 0
			msunlock ()
		endif
	next
return

// --------------------------------------------------------------------------
// Cria registro na conta corrente referenciando a fatura criada.
static function _CriaSZI (_sSafra)
	local _oCtaCorr := NIL

	_oCtaCorr := ClsCtaCorr():New ()
	_oCtaCorr:Assoc    = se2 -> e2_fornece
	_oCtaCorr:Loja     = se2 -> e2_loja
	_oCtaCorr:TM       = '13'
	_oCtaCorr:DtMovto  = se2 -> e2_EMISSAO
	_oCtaCorr:Valor    = se2 -> e2_valor
	_oCtaCorr:SaldoAtu = se2 -> e2_saldo
	_oCtaCorr:Usuario  = cUserName
	_oCtaCorr:Histor   = 'FAT.PAG.SAFRA ' + _sSafra  // + ' (' + se2 -> e2_parcela + ')'
	_oCtaCorr:MesRef   = strzero(month(_oCtaCorr:DtMovto),2)+strzero(year(_oCtaCorr:DtMovto),4)
	_oCtaCorr:Doc      = se2 -> e2_num
	_oCtaCorr:Serie    = se2 -> e2_prefixo
	_oCtaCorr:Origem   = "FTSAFRA"
	_oCtaCorr:Parcela  = se2 -> e2_parcela
	if _oCtaCorr:PodeIncl ()
		if ! _oCtaCorr:Grava (.F., .F.)
			U_help ("Erro na atualizacao da conta corrente para o associado '" + se2 -> e2_fornece + '/' + se2 -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg,, .t.)
		else
			if empty (se2 -> e2_vachvex)
				reclock ("SE2", .F.)
				se2 -> e2_vachvex = _oCtaCorr:ChaveExt ()
				msunlock ()
			endif
		endif
	else
		U_help ("Gravacao do SZI nao permitida na atualizacao da conta corrente para o associado '" + se2 -> e2_fornece + '/' + se2 -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg,, .t.)
	endif
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	aadd (_aRegsPerg, {01, "Produtor inicial              ", "C", 6,  0, "", "SA2", {}, "Codigo do produtor (fornecedor) inicial para geracao das notas."})
	aadd (_aRegsPerg, {02, "Loja produtor inicial         ", "C", 2,  0, "", "   ", {}, "Loja do produtor (fornecedor) inicial para geracao das notas."})
	aadd (_aRegsPerg, {03, "Produtor final                ", "C", 6,  0, "", "SA2", {}, "Codigo do produtor (fornecedor) final para geracao das notas."})
	aadd (_aRegsPerg, {04, "Loja produtor final           ", "C", 2,  0, "", "   ", {}, "Loja do produtor (fornecedor) final para geracao das notas."})
	aadd (_aRegsPerg, {05, "Titulos c/Vencimento de       ", "D", 8,  0, "", "",    {}, ""})
	aadd (_aRegsPerg, {06, "Titulos c/Vencimento ate      ", "D", 8,  0, "", "",    {}, ""})
	aadd (_aRegsPerg, {07, "Safra referencia              ", "C", 4,  0, "", "",    {}, ""})
	aadd (_aRegsPerg, {08, "Cond.pagto a usar             ", "C", 3,  0, "", "SE4", {}, ""})
	aadd (_aRegsPerg, {09, "Titulos com emissao de        ", "D", 8,  0, "", "",    {}, ""})
	aadd (_aRegsPerg, {10, "Titulos com emissao ate       ", "D", 8,  0, "", "",    {}, ""})
	aadd (_aRegsPerg, {11, "Tipos sep.barra Ex: NF/DP/FAT ", "C", 60, 0, "", "",    {}, ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
return
