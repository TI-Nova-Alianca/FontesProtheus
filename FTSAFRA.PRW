// Programa...: FTSAFRA
// Autor......: Catia Cardoso	
// Data.......: 22/04/2017
// Descricao..: Agrupa notas de safra, gerando uma fatura com os vencimentos desejados conforme regra pagamento safra vigente

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao
// #Descricao         #Gera faturas a pagar agrupando mais de um titulo, para pagamento de safra a associados.
// #PalavasChave      #safra #pagamento #conta_corrente_associados #fatura
// #TabelasPrincipais #SE2
// #Modulos           #COOP #FIN

// Historico de alteracoes:
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
//                     - Inseridas tags para catalogacao de fontes
// 29/03/2021 - Robert - Gravacao atributo :Safra na conta corrente (GLPI 9592)
// 26/02/2022 - Robert - Gravacao do campo E2_VASAFRA (GLPI 11678)
// 22/04/2023 - Robert - Melhorias gerais GLPI 11433:
//                     - Filtrar titulos pelo campo E2_VASAFRA e nao mais apenas pela existencia do SZI (contemplar nao associados)
//                     - Tratamento campo E2_VAFRSAF: selecionar [uva/frete]; gravar na fatura.
//                     - Gera fatura sempre, mesmo que haja apenas 1 titulo do fornecedor (para evitar confusao)
//                     - Melhoradas mensagens, passa a usar FormBatch, semaforo e gravar/visualizar eventos.
//                     - Nao tratava faturas com mais de uma parcela (ateh entao, nunca foi o caso)
//                     - Gravacao com controle de transacao (dados adicionais e atualizacao do SZI)
//

#include "rwmake.ch"
#include "tbiconn.ch"

// --------------------------------------------------------------------------
user function FTSAFRA (_lAuto)
	Local cCadastro  := "Geracao de fatura para pagamento de safra"
	Local aSays      := {}
	Local aButtons   := {}
	Local nOpca      := 0
	Local lPerg      := .F.
	local _nLock     := 0
	local _lContinua := .T.
	private cPerg    := "FTSAFRA"
	private _sEvtFat := 'SE2005'

	_lAuto = iif (_lAuto == NIL, .F., _lAuto)

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if _lContinua .and. ! U_ZZUVL ('148', __cUserID, .T.)
		_lContinua = .F.
	endif

	if _lContinua .and. cFilAnt != '01' .and. ! U_MsgNoYes ("Este programa destina-se inicialmente a ser executado na matriz, pois o pagamento de safra nao eh feito pelas filiais. Confirma mesmo assim?")
		_lContinua = .F.
	endif

	if _lContinua
		u_help ('Confirme, a seguir, os parametros da tela de geracao de faturas, que serao ocupados durante o processo. Por padrao, os parametros de contabilizacao devem ser alterados para NAO.')
		if ! pergunte ('AFI290', .T.)
			u_help ("Processo cancelado.")
			_lContinua = .F.
		endif
	endif

	// Controle de semaforo. Como tenho apenas uma usuaria ateh entao, nem
	// vou implementar semaforos separados por filial.
	if _lContinua
		_nLock := U_Semaforo (procname (), .t.)
		if _nLock == 0
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_ValidPerg()
		Pergunte(cPerg,.F.)

		if _lAuto
			Processa( { |lEnd| _Gera (_lAuto) } )
		else
		PRIVATE INCLUI := .F.
			AADD(aSays,cCadastro)
			AADD(aSays,"")
			AADD(aSays,"")
			AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
			AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
			AADD(aButtons, { 15,.T.,{|| U_VA_SZNC ('EVENTO', _sEvtFat)}})
			AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
			FormBatch( cCadastro, aSays, aButtons)
			If nOpca == 1
				Processa( { |lEnd| _Gera (_lAuto) } )
			Endif
		endif
	endif

	// Libera semaforo
	U_Semaforo (_nLock)
return


// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	local _lRet := .T.
return _lRet


// --------------------------------------------------------------------------
static function _Gera (_lAuto)
	local _sQuery     := ""
	local _sMsgErro   := ""
	Local aFatPag     := {}
	local aTit        := {}
	local _wnumero    := ''
	local _sPrefFat   := '30 '
	local _sSafra     := ''
	local _sCondPag   := ''
	local _aTestCond  := {}
	local _nVcto      := 0
	local _sMsgConf   := ''
	local _nTotGer    := 0
	local _dEmisIni   := ctod ('')
	local _dEmisFim   := ctod ('')
	local _lFrtSaf    := .F.
	local i           := 0
	local t           := 0
	local _oSQL       := NIL
	local _lContinua  := .T.
	local _nQtFat     := 0
	local _oEvento    := NIL
	local _sTxtEvt    := ''
	local _nQtVctSaf  := 0
	local _nQtFatAlt  := 0
	private lMsHelpAuto := .F.
	private lMsErroAuto := .F.
	private _sErroAuto := ""  // Deixar private para que a funcao U_Help possa gravar possiveis mensagens durante as rotinas automaticas.

	u_log2 ('info', 'Iniciando processamento')

	// Salva parametros em variaveis locais por que a rotina de geracao de
	// faturas vai alterar as variaveis padrao.
	_sSafra   = mv_par07
	_sCondPag = mv_par08
	_dEmisIni = mv_par09
	_dEmisFim = mv_par10
	_lFrtSaf  = (mv_par12 == 2)
	
	_sTxtEvt := "Geracao faturas pagto safra " + _sSafra + chr (13) + chr (10)
	_sTxtEvt += "Data/hora inicio: " + dtoc (date ()) + ' ' + time () + chr (13) + chr (10)
	_sTxtEvt += "Parametros:" + chr (13) + chr (10)
	_sTxtEvt += u_logsx1 (cPerg) + chr (13) + chr (10)

	if _lContinua
		// busca nro da proxima fatura
		_sQuery := ""
		_sQuery += " SELECT MAX(E2_NUM)"
		_sQuery += "   FROM " + RetSQLName ("SE2")
		_sQuery += "  WHERE D_E_L_E_T_ = ''"
		_sQuery += "    AND E2_FILIAL  = '" + cFilAnt + "'"
		_sQuery += "    AND E2_PREFIXO = '" + _sPrefFat + "'"
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
	//	_sWhere += "    AND E2_EMISSAO >= '" + _sSafra + "0101'"
		_sWhere += "    AND E2_VASAFRA = '" + _sSafra + "'"
		_sWhere += "    AND E2_EMISSAO between '" + dtos (_dEmisIni) + "' AND '" + dtos (_dEmisFim) + "'"
		_sWhere += "    AND E2_VENCREA BETWEEN '" + _wdataini + "' AND '" + _wdatafim + "'"
		_sWhere += "    AND (E2_PREFIXO ='30' OR E2_PREFIXO ='31')"
		_sWhere += "    AND E2_SALDO   > 0"
		_sWhere += "    AND E2_TIPO IN " + FormatIn (alltrim (mv_par11), '/')
		_sWhere += "    AND E2_VAFRSAF " + iif (_lFrtSaf, "='S'", "!='S'")
	//	_sWhere += "    AND E2_FATURA != 'NOTFAT'"  // O sistema gera NOTFAT nesse campo para que faturas nao possam mais gerar novas faturas.
		// Agora posso filtrar pelo E2_VASAFRA e tratar, junto, os nao associados. --> _sWhere += "    AND EXISTS (SELECT 1" 
		// Agora posso filtrar pelo E2_VASAFRA e tratar, junto, os nao associados. --> _sWhere += "                  FROM " + RetSQLName ("SZI") + " AS SZI"
		// Agora posso filtrar pelo E2_VASAFRA e tratar, junto, os nao associados. --> _sWhere += "                 WHERE SZI.D_E_L_E_T_ = ''"
		// Agora posso filtrar pelo E2_VASAFRA e tratar, junto, os nao associados. --> _sWhere += "                   AND SZI.ZI_FILIAL  = E2_FILIAL"
		// Agora posso filtrar pelo E2_VASAFRA e tratar, junto, os nao associados. --> _sWhere += "                   AND SZI.ZI_ASSOC   = E2_FORNECE"
		// Agora posso filtrar pelo E2_VASAFRA e tratar, junto, os nao associados. --> _sWhere += "                   AND SZI.ZI_LOJASSO = E2_LOJA"
		// Agora posso filtrar pelo E2_VASAFRA e tratar, junto, os nao associados. --> _sWhere += "                   AND SZI.ZI_DOC     = E2_NUM"
		// Agora posso filtrar pelo E2_VASAFRA e tratar, junto, os nao associados. --> _sWhere += "                   AND SZI.ZI_SERIE   = E2_PREFIXO"
		// Agora posso filtrar pelo E2_VASAFRA e tratar, junto, os nao associados. --> _sWhere += "                   AND SZI.ZI_PARCELA = E2_PARCELA"
		// Agora posso filtrar pelo E2_VASAFRA e tratar, junto, os nao associados. --> _sWhere += "                   AND SZI.ZI_TM      = '13'"
		// Agora posso filtrar pelo E2_VASAFRA e tratar, junto, os nao associados. --> _sWhere += "                )"
	endif

	// Verifica se o usuario quer agrupar faturas nao agrupaveis (um engano comum)
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT COUNT (*), sum (E2_SALDO)"
		_oSQL:_sQuery += _sWhere
		_oSQL:_sQuery += " AND E2_FATURA = 'NOTFAT'"
		_aNotFat = aclone (_oSQL:Qry2Array ())
		if _aNotFat [1, 1] > 0
			_lContinua = .F.
			if U_MsgNoYes ("ATENCAO: A parametrizacao informada pretende abranger " + cvaltochar (_aNotFat [1, 1]) + " titulos, somando R$ " + cvaltochar (_aNotFat [1, 2]) + " que ja sao faturas e, portanto, NAO PODEM MAIS ser agrupadas. A contagem no final do processo nao vai ficar exeta. Confirma assim mesmo?")
				_lContinua = .t.
				_sTxtEvt += "Usuario confirmou parametrizacao envolvendo faturas (que nao poderao mais ser usadas em nova fatura)" + chr (13) + chr (10)
			endif
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
		_sTxtEvt += "Query para leitura de titulos a agrupar: " + _sQuery + chr (13) + chr (10)
		aDados := U_Qry2Array(_sQuery)
		_nTotGer = 0
		for i=1 to len(aDados)
			_nTotGer += aDados [i, 3]
		next
		if _nTotGer == 0
			u_help ("Nao foram encontrados titulos para agrupar") //, ou os fornecedores envolvidos possuem apenas 1 titulo, o que nao justifica a geracao de fatura.")
			_lContinua = .F.
		else
			_sMsgConf := "Foram encontrados titulos de " + cvaltochar (len (aDados)) + ' fornecedores.' + chr (13) + chr (10)
			_sMsgConf += "Saldo total: " + cvaltochar (_nTotGer) + chr (13) + chr (10)
			_sMsgConf += "Vencimentos previstos: " + chr (13) + chr (10)
			_aTestCond := condicao (_nTotGer, _sCondPag,, date ())
			_nQtVctSaf = len (_aTestCond)
			for _nVcto = 1 to len (_aTestCond)
				_sMsgConf += dtoc (_aTestCond [_nVcto, 1]) + chr (13) + chr (10)
			next
			_sMsgConf += chr (13) + chr (10) + "Confirma?"
			if ! _lAuto .and. ! U_MsgYesNo (_sMsgConf) //"Saldo total de titulos encontrados para gerar fatura: " + cvaltochar (_nTotGer) + " ; a fatura vai ser gerada com a(s) seguinte(s) data(s) de vencimento:" + chr (10) + chr (13) + _sMsgConf + chr (10) + chr (13) + "Confirma?")
				_lContinua = .F.
			else
				_sTxtEvt += _sMsgConf + chr (13) + chr (10)
			endif
		endif
	endif

	if _lContinua
		procregua (len(aDados))
		_nTotGer = 0
		_nQtFat = 0
		for i=1 to len(aDados)
			_wfornece = aDados [i,1]
			_wloja    = aDados [i,2]
			_wnumero  = soma1 (_wnumero)
			aFatPag     := {}
			aTit        := {}
			incproc ("Associado " + _wfornece + " (" + cvaltochar (i) + " de " + cvaltochar (len(aDados)) + ")")
		
			// busca titulos do fornecedor para serem agrupados na fatura.
			_sQuery := ""
			_sQuery += " SELECT E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, '' "
			_sQuery += _sWhere
			_sQuery += "    AND E2_FORNECE = '" + _wfornece + "'"
			_sQuery += "    AND E2_LOJA    = '" + _wloja + "'"
			aTitulos :=aclone (U_Qry2Array(_sQuery))

			for t=1 to len (aTitulos)
				aTitulos [t,5] = .F.
			next

			// seta campos do array da fatura a ser gerada
			Aadd(aFatPag, _sPrefFat)         //-- Prefixo
			Aadd(aFatPag, "FAT")             //-- Tipo
			Aadd(aFatPag, _wnumero)          //-- Numero da Fatura (se o numero estiver em branco obtem pelo FINA290)
			Aadd(aFatPag, "120201    ")      //-- Natureza
			Aadd(aFatPag, _dEmisIni)         //-- Data emissao inicial
			Aadd(aFatPag, _dEmisFim)         //-- Data emissao final
			Aadd(aFatPag, _wfornece)         //-- Fornecedor
			Aadd(aFatPag, _wloja)            //-- Loja
			Aadd(aFatPag, _wfornece)         //-- Fornecedor para geracao
			Aadd(aFatPag, _wloja)            //-- Loja do fornecedor para geracao
			Aadd(aFatPag, _sCondPag)         //-- Condicao de pagto
			Aadd(aFatPag, 01)                //-- Moeda
			Aadd(aFatPag, aclone(aTitulos))  //-- ARRAY com os titulos da fatura (Prefixo,Numero,Parcela,Tipo,Título localizado na geracao de fatura (lógico). Iniciar com falso.)
			Aadd(aFatPag, 0)                 //-- Valor de decrescimo
			Aadd(aFatPag, 0)                 //-- Valor de acrescimo

			u_log2 ('info', 'Gerando fatura ' + _wnumero + ' para o fornecedor ' + _wfornece + '/' + _wLoja + ' agrupando os seguintes titulos:')
			u_log2 ('info', aTitulos)

			_sMsgErro = ''
			begin transaction
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
				_sTxtEvt += "ERRO na geracao de fatura para fornecedor " + _nFornece + '/' + _wLoja + chr (13) + chr (10)
			else
				_nQtFat ++
				
				// Zera os saldos da conta corrente para os titulos aglutinados na fatura.
				_ZeraSZI (_wFornece, _wLoja, aTitulos)

				// altera o historio e deixa posicionado o E2 para cria conta corrente referente a este titulo.
				_nQtFatAlt = 0
				se2 -> (dbsetorder (1))  // E2_FILIAL, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, E2_FORNECE, E2_LOJA, R_E_C_N_O_, D_E_L_E_T_
				se2 -> (dbseek(xfilial ("SE2") + _sPrefFat + _wnumero, .t.))
				do while ! se2 -> (eof ()) ;
					.and. se2 -> e2_filial  == xfilial ("SE2") ;
					.and. se2 -> e2_prefixo == _sPrefFat ;
					.and. se2 -> e2_num     == _wNumero

					if se2 -> e2_fornece == _wFornece .and. se2 -> e2_loja == _wLoja
						reclock("SE2", .F.)
						SE2->E2_vaSafra = _sSafra
						if _lFrtSaf
							SE2->E2_HIST    = 'FAT.PAG.AUX.COMB.SAFRA ' + _sSafra
							SE2->E2_vaFrSaf = 'S'
						else
							SE2->E2_HIST    = 'FAT.PAG.SAFRA ' + _sSafra // Quando juntava parcela A com B dava confusao --->  + '(' + SE2 -> E2_PARCELA + ')'
							SE2->E2_vaFrSaf = 'N'
						endif
						MsUnLock()
						_nTotGer += se2 -> e2_valor
						_CriaSZI (_sSafra)
						_nQtFatAlt ++
					endif
					se2 -> (dbskip ())
				enddo
				if _nQtFatAlt != _nQtVctSaf
					u_help ("Eu deveria ter encontrado " + cvaltochar (_nQtVctSaf) + " parcelas geradas pela fatura, mas encontrei " + cvaltochar (_nQtFatAlt) + ". Verifique!",, .t.)
					_sTxtEvt += "ERRO: Eu deveria ter encontrado " + cvaltochar (_nQtVctSaf) + " parcelas geradas pela fatura, mas encontrei " + cvaltochar (_nQtFatAlt) + chr (13) + chr (10)
				endif
			endif
			end transaction
		next

		// Grava evento para posterior necessidade de rastreamento
		_sTxtEvt += "Processo finalizado." + chr (13) + chr (10)
		_sTxtEvt += "Geradas " + cvaltochar (_nQtFat) + " faturas, no valor de $ " + cvaltochar (_nTotGer) + chr (13) + chr (10)
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven    = _sEvtFat
		_oEvento:Texto      = _sTxtEvt
		_oEvento:Safra      = _sSafra
		_oEvento:Grava ()
	endif

	u_help ("Processo concluido. Foram geradas " + cvaltochar (_nQtFat) + " faturas, no valor de $ " + cvaltochar (_nTotGer))
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
	_oCtaCorr:Safra    = _sSafra
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
	
	aadd (_aRegsPerg, {01, "Produtor inicial              ", "C", 6,  0, "", "SA2", {},               "Codigo do produtor (fornecedor) inicial para geracao das notas."})
	aadd (_aRegsPerg, {02, "Loja produtor inicial         ", "C", 2,  0, "", "   ", {},               "Loja do produtor (fornecedor) inicial para geracao das notas."})
	aadd (_aRegsPerg, {03, "Produtor final                ", "C", 6,  0, "", "SA2", {},               "Codigo do produtor (fornecedor) final para geracao das notas."})
	aadd (_aRegsPerg, {04, "Loja produtor final           ", "C", 2,  0, "", "   ", {},               "Loja do produtor (fornecedor) final para geracao das notas."})
	aadd (_aRegsPerg, {05, "Titulos c/Vencimento de       ", "D", 8,  0, "", "",    {},               ""})
	aadd (_aRegsPerg, {06, "Titulos c/Vencimento ate      ", "D", 8,  0, "", "",    {},               ""})
	aadd (_aRegsPerg, {07, "Safra referencia              ", "C", 4,  0, "", "",    {},               ""})
	aadd (_aRegsPerg, {08, "Cond.pagto a usar             ", "C", 3,  0, "", "SE4", {},               ""})
	aadd (_aRegsPerg, {09, "Titulos com emissao de        ", "D", 8,  0, "", "",    {},               ""})
	aadd (_aRegsPerg, {10, "Titulos com emissao ate       ", "D", 8,  0, "", "",    {},               ""})
	aadd (_aRegsPerg, {11, "Tipos sep.barra Ex: NF/DP/FAT ", "C", 60, 0, "", "",    {},               ""})
	aadd (_aRegsPerg, {12, "Buscar uva ou frete/aux.comb.?", "N", 1,  0, "", "",    {'Uva', 'Frete'}, ""})

	U_ValPerg (cPerg, _aRegsPerg)
return
