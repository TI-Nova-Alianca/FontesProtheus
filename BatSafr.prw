// Programa:   BatSafr
// Autor:      Robert Koch
// Data:       28/12/2011
// Descricao:  Envia e-mail com inconsistencias encontradas durante a safra.
//             Criado para ser executado via batch.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Verificacoes e processamentos diversos durante periodo de safra
// #PalavasChave      #safra0
// #TabelasPrincipais #SF1 SD1 $SZE #SZF
// #Modulos           #COOP

// Historico de alteracoes:
// 06/03/2012 - Robert - Nao considerava cargas aglutinadas.
// 13/03/2012 - Robert - Criada verificacao de cadastros viticolas nao renovados.
// 06/02/2013 - Robert - Separados os tipos de verificacao via parametro na chamada da funcao.
//                     - Passa a validar a safra atual pela data doo sistema.
// 18/06/2015 - Robert - View VA_NOTAS_SAFRA renomeada para VA_VNOTAS_SAFRA
// 18/01/2016 - Robert - Desconsidera fornecedor 003114 no teste de cargas (transferencias da linha Jacinto para matriz)
// 25/01/2016 - Robert - Envia avisos para o grupo 045.
// 16/01/2019 - Robert - Incluido grupo 047 no aviso de cargas sem contranota.
// 17/01/2021 - Robert - Criada verificacao tipo 3 (parcelamento das notas de compra).
// 01/02/2021 - Robert - Criado parametro que permite ajustar os titulos, para casos especificos de recalculo de frete (ainda nao testado/usado).
// 12/03/2021 - Robert - Migrado e-mail diario de acompanhamento da safra do U_BatCSaf() para este programa.
//                     - Implementada geracao do SZI e verificacao de inconsistencias SZI x SE2 (GLPI 9592).
// 03/04/2021 - Robert - Recalcula saldo do SZI antes de enviar aviso de diferenca com o SE2.
// 07/05/2021 - Robert - Removidas algumas linhas comentariadas.
// 20/07/2021 - Robert - Removido e-mail paulo.dullius e inserido monica.rodrigues
// 12/01/2022 - Robert - Melhorias nomes arquivos de log, e-mail acompanhamento.
// 17/01/2022 - Robert - Ajuste nomes conselheiros.
// 19/01/2022 - Robert - Ajuste nomes e e-mail conselheiros.
// 28/01/2022 - Robert - E-mail de acompanhamento de safra passa a enviar para lista de distribuicao acomp.safra@novaalianca.coop.br
// 18/02/2022 - Robert - Passa a dar 2 dias antes de transferir titulos para a matriz (para necessidades de cancelar alguma nota recente).
// 28/02/2022 - Robert - Ajuste conferencia parcelamento (a coop. nao paga FUNRURAL para nao associados e PJ).
// 08/11/2022 - Robert - Removidas algumas linhas comentariadas.
// 02/03/2023 - Robert - Aviso de contranotas sem carga passa a usar ClsAviso.
// 15/02/2023 - Robert - Passa a mandar avisos pelo NaWeb e nao mais por e-mail.
// 03/03/2023 - Robert - Campo VA_VNOTAS_SAFRA.TIPO_FORNEC passa a ter novo conteudo.
// 06/03/2023 - Robert - Batch agendado na matriz para receber transf.do SZI passa a ter menos prioridade.
// 13/03/2023 - Robert - Novos parametros FINA090. EXecuta apenas 10 registros por vez (temporariamente).
// 16/03/2023 - Robert - Criado controle de semaforo nas static functions.
// 15/01/2024 - Robert - Ajuste para nao validar cadastro fornecedor 005567 ref. FUNRURAL
// 16/01/2024 - Robert - Removida filial 09 do e-mail diario de acompanhamento de safra.
// 23/01/2024 - Robert - Criada verificacao de inspecoes.
//

// --------------------------------------------------------------------------
user function BatSafr (_sQueFazer)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _sMsg      := ""
	local _aCols     := {}
	local _aSemNota  := {}
	local _oSQL      := NIL
	local _sArqLgOld := ''
	local _oAViso    := NIL

	_sQueFazer = iif (_sQueFazer == NIL, '', _sQueFazer)

	U_Log2 ('info', 'Iniciando ' + procname () + ' com _sQueFazer=' + _sQueFazer)

	// Como esta funcao faz diversas tarefas, vou gerar log em arquivos separados.
	_sArqLgOld = _sArqLog
	U_MudaLog (procname () + "_" + _sQueFazer + ".log")

	// Procura cargas sem contranota.
	if _sQueFazer == 'CargasSemContranota'
		_aSemNota = {}
		dbselectarea ("SZE")
		set filter to &('ZE_FILIAL=="' + xFilial("SZE") + '".And.ze_safra=="'+cvaltochar (year (date ()))+'".and.ze_coop$"000021".and.empty(ze_nfger).and.dtos(ze_data)<"' + dtos (ddatabase) + '".and.ze_aglutin!="O".and.!ze_status$"C/D"')
		dbgotop ()
		do while ! eof ()
			aadd (_aSemNota, {"Filial/carga '" + sze -> ze_filial + '/' + sze -> ze_carga + "' de " + dtoc (sze -> ze_data) + " sem contranota!", sze -> ze_nomasso})
			dbskip ()
		enddo
		set filter to
	
		if len (_aSemNota) > 0
			_aCols = {}
			aadd (_aCols, {"Mensagem",        "left",  "@!"})
			aadd (_aCols, {"Associado",       "left",  "@!"})
			_oAUtil := ClsAUtil():New (_aSemNota)
			_sMsg += _oAUtil:ConvHTM ("", _aCols, 'width="80%" border="1" cellspacing="0" cellpadding="3" align="center"', .F.)
			U_Log2 ('aviso', _sMsg)
		//	U_ZZUNU ({'045', '047'}, "Inconsistencias cargas safra", _sMsg)
			_oAviso := ClsAviso():new ()
			_oAviso:Tipo       = 'A'  // I=Info;A=Aviso;E=Erro
			_oAviso:Titulo     = "Cargas sem contranota"
			_oAviso:Texto      = _sMsg
			_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
			_oAviso:Origem     = procname ()
			_oAviso:Formato    = 'H'  // [T]exto ou [H]tml
			_oAviso:Grava ()
		else
			U_Log2 ('info', 'Nenhuma inconsistencia encontrada.')
		endif

	// Verifica contranotas com cadastro viticola desatualizado
	// Em desuso. A partir de 2021 trabalha-se com codigo SIVIBE e os cadastros de propriedades
	// rurais (antigos cad.viticolas) estao no NaWeb
	elseif _sQueFazer == '2'
		U_Log2 ('aviso', 'Verificacao em desuso!')

	// Verifica composicao das parcelas das notas. Em 2021 jah estamos fazendo 'compra' durante a safra.
	// Como as primeiras notas sairam erradas, optei por fazer esta rotina de novo para identifica-las
	// e manter monitoramento.
	elseif _sQueFazer == 'ConferirParcelamento' .and. year (date ()) >= 2021
		_ConfParc ()

	// Verifica contranotas "sem carga". Isso indica possivel problema nas amarracoes entre tabelas.
	elseif _sQueFazer == 'ContranotasSemCarga'
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT DISTINCT 'Filial:' + FILIAL + ' Assoc:' + ASSOCIADO + '-' + RTRIM (NOME_ASSOC) + ' Contranota:' + DOC"
		_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
		_oSQL:_sQuery +=  " WHERE SAFRA   = '" + cvaltochar (year (date ())) + "'"
		_oSQL:_sQuery +=    " AND TIPO_NF != 'V'"
		_oSQL:_sQuery +=    " AND (CARGA = '' OR CARGA IS NULL)"
		u_log (_oSQL:_sQuery)
		_aCols = {}
		aadd (_aCols, {"Mensagem",        "left",  "@!"})
		_oAUtil := ClsAUtil():New (_oSQL:Qry2Array ())
		if len (_oAUtil:_aArray) > 0
			_sMsg := "Contranotas sem carga (provavel inconsistencia entre tabelas)"
			_sMsg += "<BR>"
			_sMsg += _oAUtil:ConvHTM ("", _aCols, 'width="80%" border="1" cellspacing="0" cellpadding="3" align="center"', .F.)
			U_Log2 ('aviso', _smsg)
			_oAviso := ClsAviso():new ()
			_oAviso:Tipo       = 'A'  // I=Info;A=Aviso;E=Erro
			_oAviso:Titulo     = "Contranotas sem carga"
			_oAviso:Texto      = _sMsg
			_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
			_oAviso:Origem     = procname ()
			_oAviso:Formato    = 'H'  // [T]exto ou [H]tml
			_oAviso:Grava ()
		else
			U_Log2 ('info', 'Nenhuma inconsistencia encontrada.')
		endif

	// Verifica frete
	elseif _sQueFazer == 'ConferirFrete' //'5'
		_ConfFrt ()
	
	// Envia e-mail de acompanhamento de totais de safra
	elseif _sQueFazer == 'MailAcompanhamento' //'6'
		_MailAcomp ()
	
	// Gera titulos na conta corrente referentes as notas de compra (a partir de 2021 geramos direto como compra) - GLPI 9592
	// Esses titulos nao sao gerados no momento de emissao da contranota por que fica muito demorado.
	elseif _sQueFazer == 'GerarSZI'  //'7'
		_GeraSZI ()

	// Confere conta corrente (SZI) x titulos referentes as notas de compra (a partir de 2021 geramos direto como compra) - GLPI 9592
	elseif _sQueFazer == 'ConferirSZI' //'8'
		_ConfSZI ()

	// Transfere (das filiais para a matriz) os titulos de nao associados.
	elseif _sQueFazer == 'TransfTitNaoAssocParaMatriz'  //'9'
		_TransFil ()
	
	elseif _sQueFazer == 'TransfSZIParaMatriz' //'8'
		_TrSZIMat ()

	// Confere alguns cadastros basicos
	elseif _sQueFazer == 'ConfCadastros'
		_ConfCadas ()

	// Confere inspecoes no NaWeb
	elseif _sQueFazer == 'ConfInspecoes'
		_ConfInsp ()

	else
		u_help ("Sem definicao para o que fazer quando parametro = '" + _sQueFazer + "'.",, .T.)
		//_oBatch:Retorno += "Sem definicao para verificacao '" + _sQueFazer + "'."
	endif

	// Volta log para o nome original, apenas para 'fechar' o processo.
	_sArqLog = _sArqLgOld

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	U_Log2 ('info', 'Finalizando ' + procname ())
return .T.



// --------------------------------------------------------------------------
// Conferencia de alguns cadastros basicos
static function _ConfCadas ()
	local _oSQL     := NIL
	local _aFornece := {}
	local _nFornece := 0
//	local _sForNCad := ''
//	local _sPrdNCad := ''
	local _oAviso   := NIL
	local _aProdut  := {}
	local _nProdut  := 0
	local _sMsg     := ''

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT distinct GX0001_ASSOCIADO_CODIGO, GX0001_ASSOCIADO_LOJA"
	_oSQL:_sQuery +=  " FROM GX0001_AGENDA_SAFRA"
	_oSQL:_sQuery += " WHERE GX0001_ASSOCIADO_RESTRICAO = ''"
	_oSQL:_sQuery +=   " AND GX0001_ASSOCIADO_CODIGO != '005567'"  // Unico caso de PJ
	_oSQL:_sQuery += " ORDER BY GX0001_ASSOCIADO_CODIGO, GX0001_ASSOCIADO_LOJA"
	_oSQL:Log ('[' + procname () + ']')
	_aFornece = aclone (_oSQL:Qry2Array (.f., .f.))
	sa2 -> (dbsetorder (1))
	for _nFornece = 1 to len (_aFornece)
		if ! sa2 -> (dbseek (xfilial ("SA2") + _aFornece [_nFornece, 1] + _aFornece [_nFornece, 2], .f.))
			_sMsg += 'Fornecedor ' + _aFornece [_nFornece, 1] + '/' + _aFornece [_nFornece, 2] + ' nao localizado <br>'
		else
			if sa2 -> a2_tipo == 'F'
				if len (alltrim (sa2 -> a2_cgc)) != 11
					_sMsg += 'Fornecedor ' + _aFornece [_nFornece, 1] + '/' + _aFornece [_nFornece, 2] + ": CPF com tamanho invalido <br>"
				endif
			elseif sa2 -> a2_tipo == 'J'
				if len (alltrim (sa2 -> a2_cgc)) != 14
					_sMsg += 'Fornecedor ' + _aFornece [_nFornece, 1] + '/' + _aFornece [_nFornece, 2] + ": CNPJ com tamanho invalido <br>"
				endif
			endif
			if sa2 -> a2_tiporur != 'F'
				_sMsg += 'Fornecedor ' + _aFornece [_nFornece, 1] + '/' + _aFornece [_nFornece, 2] + ': Campo A2_TIPORUR deveria conter F <br>'
			endif
			if sa2 -> a2_tpessoa != 'PF'
				_sMsg += 'Fornecedor ' + _aFornece [_nFornece, 1] + '/' + _aFornece [_nFornece, 2] + ': Campo A2_TPESSOA deveria conter PF <br>'
			endif
			if sa2 -> a2_recinss != 'S'
				_sMsg += 'Fornecedor ' + _aFornece [_nFornece, 1] + '/' + _aFornece [_nFornece, 2] + ': Campo A2_RECINSS deveria conter S <br>'
			endif
		endif
	next
	//
	// Conferencia produtos
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT B1_COD"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=   " AND B1_GRUPO   = '0400'"
	_oSQL:_sQuery += " ORDER BY B1_COD"
	_oSQL:Log ('[' + procname () + ']')
	_aProdut = aclone (_oSQL:Qry2Array (.f., .f.))
	sa2 -> (dbsetorder (1))
	for _nProdut = 1 to len (_aProdut)
		if ! sb1 -> (dbseek (xfilial ("SB1") + _aProdut [_nProdut, 1], .f.))
			_sPrdNCad += 'Produto ' + _aProdut [_nProdut, 1] + ' nao cadastrado <br>'
		else
			if sb1 -> b1_inss != 'S'
				_sMsg += 'Produto ' + _aProdut [_nProdut, 1] + ': Campo B1_INSS deveria conter S <br>'
			endif
		endif
	next
	if ! empty (_sMsg)
		_oAviso := ClsAviso():new ()
		_oAviso:Tipo       = 'A'  // I=Info;A=Aviso;E=Erro
		_oAviso:Titulo     = "Inconsist.cadastro p/safra"
		_oAviso:Texto      = _sMsg
		_oAviso:DestinZZU  = {'122', '019'}  // 122 = grupo da TI
		_oAviso:Origem     = procname ()
		_oAviso:Formato    = 'H'  // [T]exto ou [H]tml
		_oAviso:Grava ()
	endif

	// Conferencia tabela ZZA (integracao com programa de medicao de grau)
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT COUNT (*)"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZZA")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '*'"
	_oSQL:Log ('[' + procname () + ']')
	if _oSQL:RetQry (1, .f.) > 0
		_oAviso := ClsAviso():new ()
		_oAviso:Tipo       = 'E'  // I=Info;A=Aviso;E=Erro
		_oAviso:Titulo     = "Tabela ZZA nao pode ter registros deletados"
		_oAviso:Texto      = "A tabela " + RetSQLName ("ZZA") + " nao pode ter registros deletados, pois o programa BL01, que integra com ela, desconhece esse conceito."
		_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
		_oAviso:Origem     = procname ()
		_oAviso:Formato    = 'T'  // [T]exto ou [H]tml
		_oAviso:Grava ()
	endif
return


// --------------------------------------------------------------------------
// Conferencia de alguns dados das cargas X inspecoes no NaWeb
static function _ConfInsp ()
	local _oSQL     := NIL
	local _oAviso   := NIL
	local _sAliasQ   := ''
	local _sMsg     := ''
	local _sLinkSrv   := U_LkServer ('NAWEB')

	if empty (_sLinkSrv)
		_oAviso := ClsAviso():new ()
		_oAviso:Tipo       = 'E'  // I=Info;A=Aviso;E=Erro
		_oAviso:Titulo     = "Sem definicao de linked server para NaWeb"
		_oAviso:Texto      = "Impossivel rodar verificacao de safra " + procname ()
		_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
		_oAviso:Origem     = procname ()
		_oAviso:Formato    = 'T'  // [T]exto ou [H]tml
		_oAviso:Grava ()
	else
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT P.FILIAL, P.CARGA, P.SEGREGADA, isnull (N.SITUACAO, 'NULL') as SITUACAO"
		_oSQL:_sQuery += " FROM VA_VCARGAS_SAFRA P"
		_oSQL:_sQuery +=   " LEFT JOIN " + _sLinkSrv + ".VA_VINSPECOES_SAFRA_" + cvaltochar (year (date ())) + " N "
		_oSQL:_sQuery +=      " ON (N.SAFRA  = P.SAFRA"
		_oSQL:_sQuery +=      " AND N.FILIAL = P.FILIAL"
		_oSQL:_sQuery +=      " AND N.CARGA  = P.CARGA)"
		_oSQL:_sQuery += " WHERE P.SAFRA = '" + cvaltochar (year (date ())) + "'"
		_oSQL:_sQuery +=   " AND P.STATUS != 'C'"  // Cancelada
		_oSQL:_sQuery +=   " AND P.AGLUTINACAO != 'O'"  // Aglutinada em outra carga
		_oSQL:_sQuery +=   " AND P.PESO_LIQ > 0"  // Para evitar cargas 'em recebimento'
		_oSQL:_sQuery +=   " AND P.CONTRANOTA != ''"
		_oSQL:_sQuery +=   " AND P.NF_DEVOLUCAO = ''"  // Para evitar cargas devolvidas'
		_oSQL:_sQuery += " ORDER BY P.FILIAL, P.CARGA"
		_oSQL:Log ('[' + procname () + ']')
		_sAliasQ := _oSQL:Qry2Trb (.f.)
		do while ! (_sAliasQ) -> (eof ())
		//	U_Log2 ('debug', '[' + procname () + ']F' + (_sAliasQ) -> filial + ' Carga ' + (_sAliasQ) -> carga + ' >>' + alltrim (upper ((_sAliasQ) -> Situacao)) + '>> x >>' + (_sAliasQ) -> segregada + '<<')
			if alltrim (upper ((_sAliasQ) -> Situacao)) == 'NULL'
				_sMsg += 'F' + (_sAliasQ) -> filial + ' Carga ' + (_sAliasQ) -> carga + ': Inspecao nao encontrada no NaWeb.<br>'
			else
				if alltrim (upper ((_sAliasQ) -> Situacao)) == 'SEG' .and. (_sAliasQ) -> segregada != 'S'
					_sMsg += 'F' + (_sAliasQ) -> filial + ' Carga ' + (_sAliasQ) -> carga + ': Segregada SOMENTE no NaWeb.<br>'
				endif
			endif
			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())
		dbselectarea ("SB1")
		U_Log2 ('debug', '[' + procname () + ']_sMsg: ' + _sMsg)
		if ! empty (_sMsg)
			_oAviso := ClsAviso():new ()
			_oAviso:Tipo       = 'A'  // I=Info;A=Aviso;E=Erro
			_oAviso:Titulo     = "Inconsist.inspecoes Protheus X NaWeb"
			_oAviso:Texto      = _sMsg
			_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
			_oAviso:Origem     = procname ()
			_oAviso:Formato    = 'H'  // [T]exto ou [H]tml
			_oAviso:Grava ()
		endif
	endif
return


// Conferencia frete
// --------------------------------------------------------------------------
static function _ConfFrt ()
	local _oSQL      := NIL
	local _sAliasQ   := ''
	local _sMsg      := ''
	local _nLock     := 0

	_nLock := U_Semaforo (procname ())
	if _nLock == 0
		return
	endif

	U_Log2 ('info', 'Iniciando ' + procname ())

	sf1 -> (dbsetorder (1))  // F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO, R_E_C_N_O_, D_E_L_E_T_

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, dbo.VA_DTOC (DATA) AS DATA, SUM (VALOR_FRETE) AS VLR_FRT"
	_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
	_oSQL:_sQuery +=  " WHERE SAFRA   = '" + cvaltochar (year (date ())) + "'"
	_oSQL:_sQuery +=    " AND TIPO_NF = 'C'"
//	_oSQL:_sQuery +=    " AND FILIAL  = '" + cFilAnt + "'"
	_oSQL:_sQuery +=    " AND DATA   != '20220307'"  // Nesse dia as notas sairam realmente sem frete, que foi complementado no dia 09.
	_oSQL:_sQuery += " GROUP BY SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, DATA"
	_oSQL:_sQuery += " ORDER BY SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE"
	_oSQL:Log ()
	_sAliasQ := _oSQL:Qry2Trb (.F.)
	do while ! (_sAliasQ) -> (eof ())
		_sMsg = ''
		if ! sf1 -> (dbseek ((_sAliasQ) -> filial + (_sAliasQ) -> doc + (_sAliasQ) -> serie + (_sAliasQ) -> associado + (_sAliasQ) -> loja_assoc, .F.))
			_sMsg += "Arquivo SF1 nao localizado" + chr (13) + chr (10)
		else
			if (_sAliasQ) -> vlr_frt != sf1 -> f1_despesa
				_sMsg += "Frete no ZF_VALFRET (" + cvaltochar ((_sAliasQ) -> vlr_frt) + ") diferente do campo F1_DESPESA (" + cvaltochar (sf1 -> f1_despesa) + ")" + chr (13) + chr (10)
			endif
		endif
		if ! empty (_sMsg)
			U_Log2 ('erro', 'Inconsistencia frete safra - filial: ' + (_sAliasQ) -> filial + ' NF: ' + (_sAliasQ) -> doc + ' forn: ' + (_sAliasQ) -> associado)
			U_Log2 ('erro', _sMsg)
			//u_zzunu ({'999'}, 'Inconsistencia frete safra - F.' + (_sAliasQ) -> filial + ' NF: ' + (_sAliasQ) -> doc + ' forn: ' + (_sAliasQ) -> associado, _sMsg)
			_oAviso := ClsAviso():new ()
			_oAviso:Tipo       = 'A'  // I=Info;A=Aviso;E=Erro
			_oAviso:Titulo     = "Inconsist.frete safra"
			_oAviso:Texto      = 'Filial ' + (_sAliasQ) -> filial + ' NF: ' + (_sAliasQ) -> doc + ' forn: ' + (_sAliasQ) -> associado + chr (13) + chr (10) + _sMsg
			_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
			_oAviso:Origem     = procname ()
			_oAviso:Formato    = 'T'  // [T]exto ou [H]tml
			_oAviso:Grava ()
		endif
		(_sAliasQ) -> (dbskip ())
	enddo

	// Libera semaforo
	U_Semaforo (_nLock)

	U_Log2 ('info', 'Finalizando ' + procname ())
return



// --------------------------------------------------------------------------
// Confere parcelas geradas nas notas de compra da safra.
static function _ConfParc ()
	local _sAliasQ   := ''
	local _oSQL      := NIL
	local _aParcPrev := {}
	local _sMsg      := ''
	local _aParcReal := {}
	local _nParc     := 0
	local _nSomaPrev := 0
	local _nSomaSE2  := 0
	local _lPagaFUNR := .F.
	local _nUvaFrt   := 0
	local _lQueroTX  := .F.
	local _nValorTX  := 0
	local _lErrFunr  := .F.
	local _lErrParc  := .F.
	local _nLock     := 0

	_nLock := U_Semaforo (procname ())
	if _nLock == 0
		return
	endif

	U_Log2 ('info', 'Iniciando ' + procname ())

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, GRUPO_PAGTO"
	_oSQL:_sQuery +=       ", SUM (VALOR_TOTAL) AS VLR_UVAS, SUM (VALOR_FRETE) AS VLR_FRT, DATA AS EMISSAO, SUM(VLR_FUNRURAL) AS CONTSOC"
	_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
	_oSQL:_sQuery +=  " WHERE SAFRA   = '" + cvaltochar (year (date ())) + "'"
	_oSQL:_sQuery +=    " AND TIPO_NF IN ('C', 'V')"
	_oSQL:_sQuery +=    " AND FILIAL = '" + cFilAnt + "'"
	_oSQL:_sQuery +=    " AND NOT (TIPO_NF = 'V' AND DATA = '20220309')"  // COMPLEMENTOS DE FRETE GLPI 11721

	// temporario
	if 'ROBERT' $ upper (GetEnvServer ())
		_oSQL:_sQuery +=    " AND DOC IN ('000026266')"
	endif




	_oSQL:_sQuery += " GROUP BY SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, GRUPO_PAGTO, DATA"
	_oSQL:_sQuery += " ORDER BY SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, GRUPO_PAGTO"
	_oSQL:Log ()
	_sAliasQ := _oSQL:Qry2Trb (.F.)
	do while ! (_sAliasQ) -> (eof ())
		_sMsg = ''
		U_Log2 ('info', 'Iniciando F' + (_sAliasQ) -> filial + ' NF' + (_sAliasQ) -> doc + ' forn:' + (_sAliasQ) -> associado)
		if empty ((_sAliasQ) -> grupo_pagto)
			_sMsg += 'Contranota safra sem grupo para pagamento - Filial: ' + (_sAliasQ) -> filial + ' NF: ' + (_sAliasQ) -> doc + chr (13) + chr (10)
		else

			sf1 -> (dbsetorder (1))  // F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO, R_E_C_N_O_, D_E_L_E_T_
			if ! sf1 -> (dbseek ((_sAliasQ) -> filial + (_sAliasQ) -> doc + (_sAliasQ) -> serie + (_sAliasQ) -> associado + (_sAliasQ) -> loja_assoc, .F.))
				_sMsg += "Arquivo SF1 nao localizado" + chr (13) + chr (10)
			else
				_lErrParc = .F.

				// Nao associados e pessoas juridicas: a coop nao paga o FUNRURAL
				sa2 -> (dbsetorder (1))
				sa2 -> (dbseek (xfilial ("SA2") + (_sAliasQ) -> associado + (_sAliasQ) -> loja_assoc, .F.))
				_lPagaFUNR = .T.
				_nAlqFunru = iif (sa2 -> a2_tipo == 'J', 1.5, 1.5)
				if sa2 -> a2_tipo == 'J' .or. ! U_EhAssoc ((_sAliasQ) -> associado, (_sAliasQ) -> loja_assoc, stod ((_sAliasQ) -> emissao))
					_lPagaFUNR = .F.
					U_Log2 ('aviso', 'Fornecedor NAO recebe o FUNRURAL')
				endif

				// Verifica se tem erro (independente se vamos reembolsar) o FUNRURAL
				_lErrFunr = .F.
				if sa2 -> a2_tipo = 'F' .and. sa2 -> a2_tiporur = 'F' .and. sa2 -> a2_tpessoa = 'PF' .and. sa2 -> a2_recinss = 'S'
					_lQueroTX = .T.
				else
					_lQueroTX = .F.
				endif
			//	U_Log2 ('debug', '[' + procname () + ']Quero TX? ' + cvaltochar (_lQueroTX))
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += "SELECT SUM (E2_VALOR)"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("SE2") + " SE2"
				_oSQL:_sQuery += " WHERE SE2.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND SE2.E2_FILIAL  = '" + xfilial ("SE2") + "'"
				_oSQL:_sQuery +=   " AND SE2.E2_NUM     = '" + (_sAliasQ) -> doc + "'"
				_oSQL:_sQuery +=   " AND SE2.E2_PREFIXO = '" + (_sAliasQ) -> SERIE + "'"
				_oSQL:_sQuery +=   " AND SE2.E2_FORNECE = '000119'"  // INPS
				_oSQL:_sQuery +=   " AND SE2.E2_LOJA    = '00'"
				_oSQL:_sQuery +=   " AND SE2.E2_TIPO    = 'TX'"
			//	_oSQL:Log ('[' + procname () + ']')
				_nValorTX = _oSQL:RetQry (1, .f.)
			//	U_Log2 ('debug', '[' + procname () + ']Achei TX? ' + cvaltochar (_nValorTX))
				if _lQueroTX .and. _nValorTX == 0
					_sMsg += "Deveria ter calculado FUNRURAL para este fornecedor" + chr (13) + chr (10)
					_lErrFunr = .T.
				elseif ! _lQueroTX .and. _nValorTX > 0
					_sMsg += "NAO deveria ter calculado FUNRURAL para este fornecedor (achei titulo TX no valor de $" + cvaltochar (_nValorTX) + ')' + chr (13) + chr (10)
					_lErrFunr = .T.
				elseif ROUND ((_sAliasQ) -> contsoc, 2) != _nValorTX
					_sMsg += "Gerou FUNRURAL errado (" + cvaltochar (_nValorTX) + ") no SE2 (devia ser " + cvaltochar (ROUND ((_sAliasQ) -> contsoc, 2)) + ") para este fornecedor" + chr (13) + chr (10)
					_lErrFunr = .T.
				endif

				// Se tem erro no FUNRURAL, deve ser consertado antes de revisar parcelas.
				if ! _lErrFunr
					// Gera array de parcelas reais (SE2)
					_aParcReal = {}
					_nSomaSE2  = 0
					se2 -> (dbsetorder (6))  // E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO
					se2 -> (dbseek ((_sAliasQ) -> filial + (_sAliasQ) -> associado + (_sAliasQ) -> loja_assoc + (_sAliasQ) -> serie + (_sAliasQ) -> doc, .T.))
					do while ! se2 -> (eof ()) ;
						.and. se2 -> e2_filial  == (_sAliasQ) -> filial ;
						.and. se2 -> e2_fornece == (_sAliasQ) -> associado ;
						.and. se2 -> e2_loja    == (_sAliasQ) -> loja_assoc ;
						.and. se2 -> e2_prefixo == (_sAliasQ) -> serie ;
						.and. se2 -> e2_num     == (_sAliasQ) -> doc

						_nSomaSE2 += se2 -> e2_valor

						if se2 -> e2_valor != se2 -> e2_vlcruz
							_sMsg += 'Parcela ' + se2 -> e2_parcela + ' no SE2 diferenca entre e2_valor (' + cvaltochar (se2 -> e2_valor) + ') x e2_vlcruz (' + cvaltochar (se2 -> e2_vlcruz) + ')' + chr (13) + chr (10)
							_lErrParc = .T.
						endif

						// Calcula o % de participacao de cada parcela sobre o total do valor das uvas
						aadd (_aParcReal, {se2 -> e2_vencto, se2 -> e2_valor * 100 / (_sAliasQ) -> vlr_uvas, se2 -> e2_valor, se2 -> e2_parcela})

						se2 -> (dbskip ())
					enddo

					// Gera array de parcelas previstas cfe. regras de pagamento.
					_aParcPrev = U_VA_RusPP ((_sAliasQ) -> safra, (_sAliasQ) -> grupo_pagto, (_sAliasQ) -> vlr_uvas, sf1 -> f1_despesa, stod ((_sAliasQ) -> emissao))
					_nSomaPrev = 0
					for _nParc = 1 to len (_aParcPrev)
						if ! _lPagaFUNR .and. _nParc == 1
							_aParcPrev [_nParc, 4] -= round (((_sAliasQ) -> vlr_uvas + sf1 -> f1_despesa) * _nAlqFunru / 100, 2)
						endif
						_nSomaPrev += _aParcPrev [_nParc, 4]
					next

		//			U_Log2 ('aviso', 'como estah no SE2:')
		//			U_Log2 ('aviso', _aParcReal)

					if len (_aParcReal) != len (_aParcPrev)
						_sMsg += 'Encontrei qt.diferente (' + cvaltochar (len (_aParcReal)) + ') de parcelas no SE2 do que o previsto (' + cvaltochar (len (_aParcPrev)) + ')' + chr (13) + chr (10)
						_lErrParc = .T.
					else

						// apenas verifica
						for _nParc = 1 to len (_aParcReal)

							if _aParcReal [_nParc, 1] != _aParcPrev [_nParc, 2]
								_sMsg += "Diferenca nas datas - linha " + cvaltochar (_nParc) + " Real: " + dtoc (_aParcReal [_nParc, 1]) + ' X prev: ' + dtoc (_aParcPrev [_nParc, 2])
								_lErrParc = .T.
							endif

							// Em caso de nao associado ou pessoa juridica, vou ter a diferenca do valor do FUNRURAL, que nao pagaremos.
							// if ! _lPagaFUNR .and. _nParc == 1
							// 	if round (_aParcReal [_nParc, 3], 2) != round (_aParcPrev [_nParc, 4] - ((_sAliasQ) -> vlr_uvas + (_sAliasQ) -> vlr_frt) * 1.5 / 100, 2)
							// 		_sMsg += "Diferenca nos valores de uva SEM FUNRURAL - linha " + cvaltochar (_nParc) + " Parcela real: " + cvaltochar (round (_aParcReal [_nParc, 3], 2)) + " prevista: " + cvaltochar (round (_aParcPrev [_nParc, 4], 2))
							// 	endif
							// else
							// 	if round (_aParcReal [_nParc, 3], 2) != round (_aParcPrev [_nParc, 4], 2)
							// 		_sMsg += "Diferenca nos valores de uva - linha " + cvaltochar (_nParc) + " Parcela real: " + cvaltochar (round (_aParcReal [_nParc, 3], 2)) + " prevista: " + cvaltochar (round (_aParcPrev [_nParc, 4], 2))
							// 	endif
							// endif
							_nVlParcRe = round (_aParcReal [_nParc, 3], 2)
							_nVlParcPr = round (_aParcPrev [_nParc, 4], 2)
							//u_log (_nVlParcRe, _nVlParcPr)
							//if ! _lPagaFUNR .and. _nParc == 1
							//	_nVlParcPr -= round (((_sAliasQ) -> vlr_uvas + (_sAliasQ) -> vlr_frt) * _nAlqFunru / 100, 2)
							//endif
							if _nVlParcRe != _nVlParcPr
								_sMsg += "Diferenca nos valores de uva - linha " + cvaltochar (_nParc) + " Parcela real: " + cvaltochar (_nVlParcRe) + " prevista: " + cvaltochar (_nVlParcPr) + '<br>'
								_lErrParc = .T.
							endif
						next
					endif

					// Em caso de nao associado ou pessoa juridica, vou ter a diferenca do valor do FUNRURAL, que nao pagaremos.
					if ! _lPagaFUNR
						_nUvaFrt = round ((_sAliasQ) -> vlr_uvas + sf1 -> f1_despesa - ((_sAliasQ) -> vlr_uvas + sf1 -> f1_despesa) * 1.5 / 100, 2)
					else
						_nUvaFrt = round ((_sAliasQ) -> vlr_uvas + sf1 -> f1_despesa, 2)
					endif
					if _nSomaSE2 != _nUvaFrt
						_sMsg += "Soma dos titulos no SE2 (" + cvaltochar (_nSomaSE2) + ") diferente de valor das uvas + frete (" + cvaltochar (_nUvaFrt) + ") <br><br>"
					endif

					// Em caso de nao associado ou pessoa juridica, vou ter a diferenca do valor do FUNRURAL, que nao pagaremos.
					if ! _lPagaFUNR
						if round (_nSomaSE2, 2) != round (sf1 -> f1_valbrut - sf1 -> f1_valbrut * 1.5 / 100, 2)
							_sMsg += "Soma do E2_VALOR (" + cvaltochar (round (_nSomaSE2, 2)) + ") diferente do F1_VALBRUT (" + cvaltochar (round (sf1 -> f1_valbrut - sf1 -> f1_valbrut * 1.5 / 100, 2)) + ") SEM FUNRURAL <br><br>" 
						endif
					else
						if _nSomaSE2 != sf1 -> f1_valbrut
							_sMsg += "Soma do E2_VALOR (" + cvaltochar (_nSomaSE2) + ") diferente do F1_VALBRUT (" + cvaltochar (sf1 -> f1_valbrut) + ") <br><br>"
						endif
					endif

					if (_sAliasQ) -> vlr_frt != sf1 -> f1_despesa
						if dtos (sf1 -> f1_emissao) != '20220307'  // Dia que nao gerou frete nas notas. Foi complementado depois.
							_sMsg += "Frete no ZF_VALFRET (" + cvaltochar ((_sAliasQ) -> vlr_frt) + ") diferente do campo F1_DESPESA (" + cvaltochar (sf1 -> f1_despesa) + ")" + chr (13) + chr (10)
						endif
					endif
				endif
			endif
		endif
		if ! empty (_sMsg)
			U_Log2 ('erro', 'F' + (_sAliasQ) -> filial + ' NF: ' + (_sAliasQ) -> doc + ' forn: ' + (_sAliasQ) -> associado + '/' + (_sAliasQ) -> loja_assoc + ':')
			U_Log2 ('erro', strtran (_sMsg, '<br', chr (13) + chr (10)))
			if _lErrParc
				U_Log2 ('aviso', 'como estah no SE2:')
				U_Log2 ('aviso', _aParcReal)
				U_Log2 ('aviso', 'como deveria estar no SE2:')
				U_Log2 ('aviso', _aParcPrev)
			endif

			// Hoje estou fazendo ajustes no programa e nao quero enviar avisos
			if date () != stod ('20230330')
				_oAviso := ClsAviso():new ()
				_oAviso:Tipo       = 'E'  // I=Info;A=Aviso;E=Erro
				_oAviso:Titulo     = 'Verif.parcelamento safra NF ' + (_sAliasQ) -> doc + ' forn ' + (_sAliasQ) -> associado
				_oAviso:Texto      = _sMsg
				_oAviso:DestinZZU  = {'122'}  // Grupo 122 = TI
				_oAviso:Origem     = procname (1)+'.'+procname ()  // Acrescentar aqui o que for interessante para rastrear posteriormente
				_oAviso:Formato    = 'T'  // [T]exto ou [H]tml
				_oAviso:DiasDeVida = 10  // Dias para exclusao automatica (default Erro=90;Aviso=60;Info=30)
				_oAviso:Grava ()
			endif
		endif
		(_sAliasQ) -> (dbskip ())
	enddo

	// Libera semaforo
	U_Semaforo (_nLock)

	U_Log2 ('info', 'Finalizando ' + procname ())
return



// --------------------------------------------------------------------------
static function _MailAcomp ()
	local _sMsg   := ""
	local _oSQL   := NIL
	local _sSafra := U_IniSafra ()
	local _aCols  := {}
	local _nLock     := 0

	_nLock := U_Semaforo (procname ())
	if _nLock == 0
		return
	endif

	U_Log2 ('info', 'Iniciando ' + procname ())

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C AS ("
	_oSQL:_sQuery += " SELECT FILIAL, PRODUTO, DESCRICAO, GRAU, PESO_LIQ"
	_oSQL:_sQuery += " FROM VA_VCARGAS_SAFRA"
	_oSQL:_sQuery += " WHERE SAFRA = '" + _sSafra + "'"
	_oSQL:_sQuery += " AND STATUS != 'C'"  // Cancelada
	_oSQL:_sQuery += " AND AGLUTINACAO != 'O'"  // Aglutinada em outra carga
	_oSQL:_sQuery += " AND PESO_LIQ > 0"  // Para evitar cargas 'em recebimento'
	_oSQL:_sQuery += " AND NF_DEVOLUCAO = ''"  // Para evitar cargas devolvidas'
	_oSQL:_sQuery += " )"
	
	// Agrupado por variedade
	_oSQL:_sQuery += " SELECT PRODUTO, DESCRICAO"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '01' THEN PESO_LIQ ELSE 0 END) AS KG_F01"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '01' AND C2.PRODUTO = C.PRODUTO), 0), 1) AS GRAU_F01"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '03' THEN PESO_LIQ ELSE 0 END) AS KG_F03"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '03' AND C2.PRODUTO = C.PRODUTO), 0), 1) AS GRAU_F03"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '07' THEN PESO_LIQ ELSE 0 END) AS KG_F07"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '07' AND C2.PRODUTO = C.PRODUTO), 0), 1) AS GRAU_F07"
//	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '09' THEN PESO_LIQ ELSE 0 END) AS KG_F09"
//	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '09' AND C2.PRODUTO = C.PRODUTO), 0), 1) AS GRAU_F09"
	_oSQL:_sQuery += " , SUM (PESO_LIQ) AS KG_GERAL"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.PRODUTO = C.PRODUTO), 0), 1) AS GRAU_GERAL"
	_oSQL:_sQuery += " FROM C"
	_oSQL:_sQuery += " GROUP BY PRODUTO, DESCRICAO"
	
	// Linha com totais no final
	_oSQL:_sQuery += " UNION ALL"
	_oSQL:_sQuery += " SELECT 'TOTAIS', 'ZZZZZZZZZZZZZZ'"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '01' THEN PESO_LIQ ELSE 0 END) AS KG_F01"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '01'), 0), 1) AS GRAU_F01"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '03' THEN PESO_LIQ ELSE 0 END) AS KG_F03"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '03'), 0), 1) AS GRAU_F03"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '07' THEN PESO_LIQ ELSE 0 END) AS KG_F07"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '07'), 0), 1) AS GRAU_F07"
//	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '09' THEN PESO_LIQ ELSE 0 END) AS KG_F09"
//	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '09'), 0), 1) AS GRAU_F09"
	_oSQL:_sQuery += " , SUM (PESO_LIQ) AS KG_GERAL"
//	_oSQL:_sQuery += " , 0 AS GRAU_GERAL"
	_oSQL:_sQuery += " , ROUND(ISNULL((SELECT SUM(PESO_LIQ * GRAU) / SUM(PESO_LIQ) FROM C AS C2), 0), 1) AS GRAU_GERAL"
	_oSQL:_sQuery += " FROM C"

	_oSQL:_sQuery += " ORDER BY DESCRICAO"
	_oSQL:Log ()

	_aCols = {}
	aadd (_aCols, {'Variedade',  'left' ,  ''})
	aadd (_aCols, {'Descricao',  'left' ,  ''})
	aadd (_aCols, {'Kg F01',     'right',  '@E 999,999,999'})
	aadd (_aCols, {'Grau F01',   'right',  '@E 99.9'})
	aadd (_aCols, {'Kg F03',     'right',  '@E 999,999,999'})
	aadd (_aCols, {'Grau F03',   'right',  '@E 99.9'})
	aadd (_aCols, {'Kg F07',     'right',  '@E 999,999,999'})
	aadd (_aCols, {'Grau F07',   'right',  '@E 99.9'})
//	aadd (_aCols, {'Kg F09',     'right',  '@E 999,999,999'})
//	aadd (_aCols, {'Grau F09',   'right',  '@E 99.9'})
	aadd (_aCols, {'Kg geral',   'right',  '@E 999,999,999'})
	aadd (_aCols, {'Grau geral', 'right',  '@E 99.9'})

	_sMsg = _oSQL:Qry2HTM ("Acompanhamento cargas safra " + _sSafra, _aCols, "", .T., .F.)
	if len (_oSQL:_xRetQry) > 1
		u_log2 ('debug', _sMsg)

		// Envia para o contato principal dos associados e os demais como copia oculta.
		U_SendMail ("karina.moraes@novaalianca.coop.br", "Acompanhamento cargas safra", _sMsg, {}, NIL, NIL, 'acomp.safra@novaalianca.coop.br')

	endif

	// Libera semaforo
	U_Semaforo (_nLock)
return



// --------------------------------------------------------------------------
// Gera entrada na conta corrente do associado, com base nos titulos gerados no financeiro.
static function _GeraSZI ()
	local _sAliasQ   := ''
	local _oCtaCorr  := NIL
	local _sSafrComp := strzero (year (dDataBase), 4)
	local _nLock     := 0

	_nLock := U_Semaforo (procname ())
	if _nLock == 0
		return
	endif

	U_Log2 ('info', 'Iniciando ' + procname ())

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT E2_FILIAL, E2_FORNECE, E2_LOJA, E2_NOMFOR, E2_EMISSAO, E2_VENCREA, E2_NUM, E2_PREFIXO, E2_TIPO"
	_oSQL:_sQuery +=        ",E2_VALOR, E2_SALDO, E2_HIST, R_E_C_N_O_, E2_LA, E2_PARCELA, V.GRUPO_PAGTO"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2, "
	_oSQL:_sQuery +=          " VA_VNOTAS_SAFRA V"
	_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SE2.E2_FILIAL  = '" + xfilial ("SE2") + "'"
	_oSQL:_sQuery +=    " AND SE2.E2_VACHVEX = ''"
	_oSQL:_sQuery +=    " AND V.SAFRA        = '" + _sSafrComp + "'"
	_oSQL:_sQuery +=    " AND V.FILIAL       = SE2.E2_FILIAL"
	_oSQL:_sQuery +=    " AND V.ASSOCIADO    = SE2.E2_FORNECE"
	_oSQL:_sQuery +=    " AND V.LOJA_ASSOC   = SE2.E2_LOJA"
	_oSQL:_sQuery +=    " AND V.SERIE        = SE2.E2_PREFIXO"
	_oSQL:_sQuery +=    " AND V.DOC          = SE2.E2_NUM"
	_oSQL:_sQuery +=    " AND V.TIPO_NF      IN ('C', 'V')"
	_oSQL:_sQuery +=    " AND V.TIPO_FORNEC  LIKE '1%'"  // 1-ASSOCIADO
	_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"  // Ainda nao deve existir na conta corrente
	_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SZI") + " SZI "
	_oSQL:_sQuery +=                 " WHERE SZI.ZI_FILIAL  = SE2.E2_FILIAL"
	_oSQL:_sQuery +=                   " AND SZI.ZI_ASSOC   = SE2.E2_FORNECE"
	_oSQL:_sQuery +=                   " AND SZI.ZI_LOJASSO = SE2.E2_LOJA"
	_oSQL:_sQuery +=                   " AND SZI.ZI_SERIE   = SE2.E2_PREFIXO"
	_oSQL:_sQuery +=                   " AND SZI.ZI_DOC     = SE2.E2_NUM"
	_oSQL:_sQuery +=                   " AND SZI.ZI_PARCELA = SE2.E2_PARCELA"
	_oSQL:_sQuery +=                   " AND SZI.ZI_TM      = '13')"
	_oSQL:_sQuery +=  " ORDER BY SE2.E2_FORNECE, SE2.E2_LOJA, SE2.E2_NUM, SE2.E2_PREFIXO, SE2.E2_PARCELA"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb (.T.)
	procregua ((_sAliasQ) -> (reccount ()))
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())

		// Quero gerar tudo com a mesma data de emissao da nota
		dDataBase = (_sAliasQ) -> e2_EMISSAO

		//u_log ('Filial:' + (_sAliasQ) -> e2_filial, 'Forn:' + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + ' ' + (_sAliasQ) -> e2_nomfor, 'Emis:', (_sAliasQ) -> e2_emissao, 'Vcto:', (_sAliasQ) -> e2_vencrea, 'Doc:', (_sAliasQ) -> e2_num+'/'+(_sAliasQ) -> e2_prefixo, 'Tipo:', (_sAliasQ) -> e2_tipo, 'Valor: ' + transform ((_sAliasQ) -> e2_valor, "@E 999,999,999.99"), 'Saldo: ' + transform ((_sAliasQ) -> e2_saldo, "@E 999,999,999.99"), (_sAliasQ) -> e2_hist)

		_oCtaCorr := ClsCtaCorr():New ()
		_oCtaCorr:Assoc      = (_sAliasQ) -> e2_fornece
		_oCtaCorr:Loja       = (_sAliasQ) -> e2_loja
		_oCtaCorr:TM         = '13'
		_oCtaCorr:DtMovto    = (_sAliasQ) -> e2_EMISSAO
		_oCtaCorr:Valor      = (_sAliasQ) -> e2_valor
		_oCtaCorr:SaldoAtu   = (_sAliasQ) -> e2_saldo
		_oCtaCorr:Usuario    = cUserName
		_oCtaCorr:Histor     = (_sAliasQ) -> e2_hist
		_oCtaCorr:MesRef     = strzero(month(_oCtaCorr:DtMovto),2)+strzero(year(_oCtaCorr:DtMovto),4)
		_oCtaCorr:Doc        = (_sAliasQ) -> e2_num
		_oCtaCorr:Serie      = (_sAliasQ) -> e2_prefixo
		_oCtaCorr:Parcela    = (_sAliasQ) -> e2_parcela
		_oCtaCorr:Origem     = 'BATSAFR'
		_oCtaCorr:Safra      = _sSafrComp
		_oCtaCorr:GrpPgSafra = (_sAliasQ) -> GRUPO_PAGTO
		if _oCtaCorr:PodeIncl ()
			if ! _oCtaCorr:Grava (.F., .F.)
				U_help ("Erro na atualizacao da conta corrente para o associado '" + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
				_lContinua = .F.
			else
				se2 -> (dbgoto ((_sAliasQ) -> r_e_c_n_o_))
				if empty (se2 -> e2_vachvex)  // Soh pra garantir...
					reclock ("SE2", .F.)
					se2 -> e2_vachvex = _oCtaCorr:ChaveExt ()
					msunlock ()
				endif

			endif
		else
			U_help ("Gravacao do SZI nao permitida na atualizacao da conta corrente para o associado '" + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
			_lContinua = .F.
		endif
		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("SZE")

	// Libera semaforo
	U_Semaforo (_nLock)

	U_Log2 ('info', 'Finalizando ' + procname ())
return


// --------------------------------------------------------------------------
// Confere consistencia da conta corrente de associados X parcelas geradas nas notas de compra da safra.
static function _ConfSZI ()
	local _sAliasQ   := ''
	local _oSQL      := NIL
	local _sMsg      := ''
	local _aRegSZI   := {}
	local _sSafrComp := strzero (year (dDataBase), 4)
	local _oCtaCorr  := NIL
	local _nQtErros  := 0
	local _nRegE2Mat := 0
	local _sFornece  := ''
	local _nLock     := 0

	_nLock := U_Semaforo (procname ())
	if _nLock == 0
		return
	endif


	U_Log2 ('info', 'Iniciando ' + procname ())

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT E2_FILIAL, E2_FORNECE, E2_LOJA, E2_NUM, E2_PREFIXO, E2_PARCELA, E2_VALOR, E2_HIST, E2_SALDO, E2_VENCREA"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2"
	_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SE2.E2_FILIAL  = '" + xfilial ("SE2") + "'"
	_oSQL:_sQuery +=    " AND SE2.E2_EMISSAO < '" + dtos (dDataBase - 3) + "'"  // A transf.p/matriz eh feita alguns dias depois (para dar tempo de cancelar a contranota no dia seguinte, se precisar)
	_oSQL:_sQuery +=    " AND EXISTS (SELECT *"  // Precisa ser nota de safra
	_oSQL:_sQuery +=                  " FROM VA_VNOTAS_SAFRA V"
	_oSQL:_sQuery +=                 " WHERE V.SAFRA       = '" + _sSafrComp + "'"
	_oSQL:_sQuery +=                   " AND V.FILIAL      = SE2.E2_FILIAL"
	_oSQL:_sQuery +=                   " AND V.ASSOCIADO   = SE2.E2_FORNECE"
	_oSQL:_sQuery +=                   " AND V.LOJA_ASSOC  = SE2.E2_LOJA"
	_oSQL:_sQuery +=                   " AND V.SERIE       = SE2.E2_PREFIXO"
	_oSQL:_sQuery +=                   " AND V.DOC         = SE2.E2_NUM"
	_oSQL:_sQuery +=                   " AND V.TIPO_NF     IN ('C', 'V')"
	_oSQL:_sQuery +=                   " AND V.TIPO_FORNEC LIKE '1%'"  // 1-ASSOCIADO
	_oSQL:_sQuery +=                 ")"
	_oSQL:_sQuery +=  " ORDER BY SE2.E2_FORNECE, SE2.E2_LOJA, SE2.E2_NUM, SE2.E2_PREFIXO, SE2.E2_PARCELA"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb (.T.)
	procregua ((_sAliasQ) -> (reccount ()))
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		_sMsg = ''
		
		// Gerar log a cada titulo fica bastante lento. Vou apenas gerar na troca de fornecedor.
		if (_sAliasQ) -> e2_fornece != _sFornece
			U_Log2 ('info', 'Verificando titulos do fornecedor ' + (_sAliasQ) -> e2_fornece)
			_sFornece = (_sAliasQ) -> e2_fornece
		endif

		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " SELECT R_E_C_N_O_ "
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SZI") + " SZI "
		_oSQL:_sQuery +=  " WHERE SZI.ZI_FILIAL  = '" + (_sAliasQ) -> e2_filial + "'"
		_oSQL:_sQuery +=    " AND SZI.ZI_ASSOC   = '" + (_sAliasQ) -> e2_fornece + "'"
		_oSQL:_sQuery +=    " AND SZI.ZI_LOJASSO = '" + (_sAliasQ) -> e2_loja + "'"
		_oSQL:_sQuery +=    " AND SZI.ZI_SERIE   = '" + (_sAliasQ) -> e2_prefixo + "'"
		_oSQL:_sQuery +=    " AND SZI.ZI_DOC     = '" + (_sAliasQ) -> e2_num + "'"
		_oSQL:_sQuery +=    " AND SZI.ZI_PARCELA = '" + (_sAliasQ) -> e2_parcela + "'"
		_oSQL:_sQuery +=    " AND SZI.ZI_TM      = '13'"
		//_oSQL:Log ()
		_aRegSZI = _oSQL:RetFixo (1, 'Procurando registro no SZI ref. titulo NF compra safra', .F.)
		if len (_aRegSZI) == 0
			_sMsg += "Nao localizado registro na tabela SZI para parcela da nota de compra: " + _oSQL:_sQuery + chr (13) + chr (10)
			_sMsg += _oSQL:_sQuery
		else
			szi -> (dbgoto (_aRegSZI [1,1]))
		//	U_Log2 ('info', "Verificando SZI: FILIAL/DOC/SERIE/PARC " + szi -> zi_filial + ' ' + szi -> zi_doc + '/' + szi -> zi_serie + '-' + szi -> zi_parcela)
			if szi -> zi_valor != (_sAliasQ) -> e2_valor
				_sMsg += "SZI: FILIAL/DOC/SERIE/PARC " + szi -> zi_filial + ' ' + szi -> zi_doc + '/' + szi -> zi_serie + '-' + szi -> zi_parcela + " Valor do SZI (" + cvaltochar (szi -> zi_valor) + ") diferente do SE2 (" + cvaltochar ((_sAliasQ) -> e2_valor) + ")." + chr (13) + chr (10)
				_sMsg += _oSQL:_sQuery
			endif
			if szi -> zi_saldo != (_sAliasQ) -> e2_saldo
				// Tenta recalcular o saldo do SZI. Se ainda continuar errado, temos problemas.
				_oCtaCorr := ClsCtaCorr ():New (szi -> (recno ()))
				_oCtaCorr:AtuSaldo ()
				if szi -> zi_saldo != (_sAliasQ) -> e2_saldo
					_sMsg += "SZI: FILIAL/DOC/SERIE/PARC " + szi -> zi_filial + ' ' + szi -> zi_doc + '/' + szi -> zi_serie + '-' + szi -> zi_parcela + " Saldo do SZI (" + cvaltochar (szi -> zi_saldo) + ") diferente do SE2 (" + cvaltochar ((_sAliasQ) -> e2_saldo) + ")." + chr (13) + chr (10)
					_sMsg += _oSQL:_sQuery
				endif
			endif
			if (_sAliasQ) -> e2_filial != '01'
				if szi -> zi_saldo > 0
					_sMsg += "SZI: FILIAL/DOC/SERIE/PARC " + szi -> zi_filial + ' ' + szi -> zi_doc + '/' + szi -> zi_serie + '-' + szi -> zi_parcela + " deveria ter sido transferido para a matriz." + chr (13) + chr (10)
				else
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := " SELECT count (*) "
					_oSQL:_sQuery +=   " FROM " + RetSQLName ("SZI") + " SZI "
					_oSQL:_sQuery +=  " WHERE SZI.ZI_FILIAL  = '01'"
					_oSQL:_sQuery +=    " AND SZI.ZI_ASSOC   = '" + szi -> zi_assoc + "'"
					_oSQL:_sQuery +=    " AND SZI.ZI_LOJASSO = '" + szi -> zi_lojasso + "'"
					_oSQL:_sQuery +=    " AND SZI.ZI_SERIE   = '" + szi -> zi_serie + "'"
					_oSQL:_sQuery +=    " AND SZI.ZI_DOC     = '" + szi -> zi_doc + "'"
					_oSQL:_sQuery +=    " AND SZI.ZI_PARCELA = '" + szi -> zi_parcela + "'"
					_oSQL:_sQuery +=    " AND SZI.ZI_FILORIG = '" + szi -> zi_filial + "'"
					_oSQL:_sQuery +=    " AND SZI.ZI_TM      = '13'"
					// _oSQL:Log ()
					if _oSQL:RetQry (1, .f.) == 0
						_sMsg += "SZI: FILIAL/DOC/SERIE/PARC " + szi -> zi_filial + ' ' + szi -> zi_doc + '/' + szi -> zi_serie + '-' + szi -> zi_parcela + " transferencia nao apareceu no SZI da matriz." + chr (13) + chr (10)
					else
						_oSQL := ClsSQL ():New ()
						_oSQL:_sQuery := " SELECT R_E_C_N_O_ "
						_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2 "
						_oSQL:_sQuery +=  " WHERE SE2.E2_FILIAL  = '01'"
						_oSQL:_sQuery +=    " AND SE2.E2_FORNECE = '" + szi -> zi_assoc + "'"
						_oSQL:_sQuery +=    " AND SE2.E2_LOJA    = '" + szi -> zi_lojasso + "'"
						_oSQL:_sQuery +=    " AND SE2.E2_PREFIXO = '" + szi -> zi_serie + "'"
						_oSQL:_sQuery +=    " AND SE2.E2_NUM     = '" + szi -> zi_doc + "'"
						_oSQL:_sQuery +=    " AND SE2.E2_PARCELA = '" + szi -> zi_parcela + "'"
				//		_oSQL:Log ()
						_nRegE2Mat = _oSQL:RetQry (1, .f.)
						if _nRegE2Mat == 0
							_sMsg += "SZI: FILIAL/DOC/SERIE/PARC " + szi -> zi_filial + ' ' + szi -> zi_doc + '/' + szi -> zi_serie + '-' + szi -> zi_parcela + " transferencia nao apareceu no SE2 da matriz." + chr (13) + chr (10)
						else
							se2 -> (dbgoto (_nRegE2Mat))
							if se2 -> e2_valor != (_sAliasQ) -> e2_valor
								_sMsg += "SZI: FILIAL/DOC/SERIE/PARC " + szi -> zi_filial + ' ' + szi -> zi_doc + '/' + szi -> zi_serie + '-' + szi -> zi_parcela + " transferencia apareceu no SE2 com valor diferente! Na filial: " + cvaltochar ((_sAliasQ) -> e2_valor) + ' na matriz: ' + cvaltochar (se2 -> e2_valor) + chr (13) + chr (10)
							endif
							if se2 -> e2_vencrea != (_sAliasQ) -> e2_vencrea
								_sMsg += "SZI: FILIAL/DOC/SERIE/PARC " + szi -> zi_filial + ' ' + szi -> zi_doc + '/' + szi -> zi_serie + '-' + szi -> zi_parcela + " transferencia apareceu no SE2 com dt.vencto diferente! Na filial: " + dtoc ((_sAliasQ) -> e2_vencrea) + ' na matriz: ' + dtoc ((se2 -> e2_vencrea)) + chr (13) + chr (10)
							endif
						endif
					endif
				endif
			endif
		endif

		if ! empty (_sMsg)
			_nQtErros ++
			U_Log2 ('erro', _sMsg)
			_oAviso := ClsAviso():new ()
			_oAviso:Tipo       = 'A'  // I=Info;A=Aviso;E=Erro
			_oAviso:Titulo     = "Incons. SZI x SE2 safra"
			_oAviso:Texto      = 'Inconsistencia SZI x SE2 safra - filial: ' + (_sAliasQ) -> e2_filial + chr (13) + chr (10) + _sMsg
			_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
			_oAviso:Origem     = procname ()
			_oAviso:Formato    = 'H'  // [T]exto ou [H]tml
			_oAviso:Grava ()
		endif
		(_sAliasQ) -> (dbskip ())
	enddo
	U_Log2 ('info', 'Quantidade de inconsistencias encontradas: ' + cvaltochar (_nQtErros))

	// Libera semaforo
	U_Semaforo (_nLock)

	U_Log2 ('info', 'Finalizando ' + procname ())
return



// --------------------------------------------------------------------------
// Transfere o titulo para a matriz (quando nao associado)
static function _TransFil ()
	local _lContinua := .T.
	local _aTit      := afill (array (19), '')
	local _oSQL      := NIL
	local _aBanco    := {}
	local _sAliasQ   := ''
	local _sSafrComp := strzero (year (dDataBase), 4)
	local _sFilDest  := '01'
	local _dDtBxTran := ctod ('')
	local _sHistSE5  := ''
	local _sTxtJSON  := ''
	local _oBatchDst := NIL
	local _nLock     := 0
	Private lMsErroAuto := .F.

	_nLock := U_Semaforo (procname ())
	if _nLock == 0
		_lContinua = .F.
	endif

	
	u_log2 ('info', 'Iniciando ' + procname ())
	
	// A transferencia de saldo entre filiais eh feita atraves de conta financeira transitoria. Para isso,
	// o saldo deve ser baixado na filial de origem atraves de conta transitoria e deve ser feita inclusao
	// de novo movimento na filial destino.

	if _lContinua .and. cFilAnt == '01'
		U_Log2 ('erro', 'Transf.de titulos nao se aplica a matriz.')
		_lContinua = .F.
	endif

	// Procura a conta transitoria (eh diferente para cada filial).
	if _lContinua

		// Ajusta parametros de contabilizacao para NAO, pois a rotina automatica nao aceita.
		cPerg = 'FIN090'
		_aBkpSX1 = U_SalvaSX1 (cPerg)
		U_GravaSX1 (cPerg, "03", 2)  // Contabiliza online = nao

		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery +=" SELECT top 1 A6_COD, A6_AGENCIA, A6_NUMCON"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SA6") + " SA6 "
		_oSQL:_sQuery += " WHERE SA6.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SA6.A6_FILIAL  = '" + xfilial ("SA6") + "'"
		_oSQL:_sQuery +=   " AND SA6.A6_CONTA   = '101010201099'"
		_aBanco := aclone (_oSQL:Qry2Array (.f., .f.))
		if len (_aBanco) == 0
			U_Log2 ('erro', 'Registro ref.bco/conta transitoria entre filiais nao encontrado na tabela SA6 para esta filial.')
			_lContinua = .F.
		endif
	endif

	// Busca titulos a pagar de notas de compra de safra de fornecedores NAO ASSOCIADOS.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT SE2.R_E_C_N_O_ as REGSE2, E2_FILIAL, E2_FORNECE, E2_LOJA, E2_NUM, E2_PREFIXO, E2_PARCELA, E2_VALOR, E2_HIST,E2_SALDO"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2"
		_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SE2.E2_FILIAL  = '" + xfilial ("SE2") + "'"
		_oSQL:_sQuery +=    " AND EXISTS (SELECT *"  // Precisa ser nota de safra
		_oSQL:_sQuery +=                  " FROM VA_VNOTAS_SAFRA V"
		_oSQL:_sQuery +=                 " WHERE V.SAFRA       = '" + _sSafrComp + "'"
		_oSQL:_sQuery +=                   " AND V.FILIAL      = SE2.E2_FILIAL"
		_oSQL:_sQuery +=                   " AND V.ASSOCIADO   = SE2.E2_FORNECE"
		_oSQL:_sQuery +=                   " AND V.LOJA_ASSOC  = SE2.E2_LOJA"
		_oSQL:_sQuery +=                   " AND V.SERIE       = SE2.E2_PREFIXO"
		_oSQL:_sQuery +=                   " AND V.DOC         = SE2.E2_NUM"
		_oSQL:_sQuery +=                   " AND V.TIPO_NF     IN ('C', 'V')"
		_oSQL:_sQuery +=                   " AND V.TIPO_FORNEC LIKE '2%'"  // 2-NAO ASSOCIADO
		_oSQL:_sQuery +=                ")"
		_oSQL:_sQuery +=    " AND SE2.E2_SALDO = E2_VALOR"

		// Nao quero pegar as de hoje para evitar transferir enquanto tem alguem gerando contranota, ou o outro batch gerando SZI.
		// Alem disso, deixo um tempo para o pessoal cancelar alguma nota recente se precisarem.
		_oSQL:_sQuery +=    " AND SE2.E2_EMISSAO < '" + dtos (date () - 2) + "'"

		_oSQL:_sQuery +=  " ORDER BY SE2.E2_FORNECE, SE2.E2_LOJA, SE2.E2_NUM, SE2.E2_PREFIXO, SE2.E2_PARCELA"
		_oSQL:Log ()
		_sAliasQ = _oSQL:Qry2Trb (.T.)
		procregua ((_sAliasQ) -> (reccount ()))
		(_sAliasQ) -> (dbgotop ())
		do while _lContinua .and. ! (_sAliasQ) -> (eof ())
			se2 -> (dbgoto ((_sAliasQ) -> RegSE2))
			_dDtBxTran = se2 -> e2_emissao  // Quero transferir para a matriz na mesma data da emissao
			ddatabase = se2 -> e2_emissao  // Quero transferir para a matriz na mesma data da emissao

			U_Log2 ('info', 'Registro do SE2 a ser baixado via conta transitoria: ' + cvaltochar (se2 -> (recno ())) + ' ' + se2 -> e2_num + '/' + se2 -> e2_prefixo + '-' + se2 -> e2_parcela + ' de ' + se2 -> e2_fornece + '/' + se2 -> e2_loja)
			if se2 -> e2_saldo <= 0 .or. se2 -> e2_saldo != se2 -> e2_valor
				U_Log2 ('erro', 'Titulo sem saldo no financeiro ou saldo diferente do valor original.')
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			// Documentacao cfe. TDN -->  https://tdn.totvs.com/pages/releaseview.action?pageId=645486009
			// aRetAuto [1] := aRecnos     (array contendo os Recnos dos registros a serem baixados)
			// aRetAuto [2] := cBanco      (Banco da baixa)
			// aRetAuto [3] := cAgencia    (Agencia da baixa)
			// aRetAuto [4] := cConta      (Conta da baixa)
			// aRetAuto [5] := cCheque     (Cheque da Baixa - apenas Contas a Pagar)
			// aRetAuto [6] := cLoteFin    (Lote Financeiro da baixa)
			// aRetAuto [7] := cNatureza   (Natureza do movimento bancario - apenas Contas a Pagar)
			// aRetAuto [8] := dBaixa      (Data da baixa)
			// aRetAuto [9] := nTipoBx     (1 = Baixa somente titulos que não estao em bordero ou nTipoBx -> 2 = Baixa somente titulos em bordero)
			// aRetAuto [10]:= cBcoDe      (Portador de)
			// aRetAuto [11]:= cBcoAte     (Portador Até)
			// aRetAuto [12]:= dVencIni    (Vencimento Inicial)
			// aRetAuto [13]:= dVencFim    (Vencimento Final)
			// aRetAuto [14]:= cBord090I   (Borderô Inicial)
			// aRetAuto [15]:= cBord090F   (Borderô  Final)
			// aRetAuto [16]:= cBenef090   (Beneficiário do Cheque)
			// aRetAuto [17]:= cHistor     (Historico do Cheque)
			// aRetAuto [18]:= lMultNat    (Rateio Multiplas naturezas)
			// aRetAuto [19]:= aVendor     (Array para a baixa de vendor)     
			// Exemplo:    MSExecAuto({|x, y| FINA090(x, y)}, 3, aRetAuto)
			// Para definir o Motivo de Baixa (caso não informado, o default é NORMAL): Private _cAutoMotBx := "DEBITO CC" 

			_aTit [1] = {se2 -> (recno ())}  // Formato de array por que pode baixar mais de um titulo por vez.
			_aTit [2] = _aBanco [1, 1]
			_aTit [3] = _aBanco [1, 2]
			_aTit [4] = _aBanco [1, 3]
			_aTit [5] = ''
			_aTit [6] = ''
			_aTit [7] = ''
			_aTit [8] = _dDtBxTran
			_aTit [9] = 1
			_aTit [10] = ''
			_aTit [11] = 'z'
			_aTit [12] = se2 -> e2_vencto
			_aTit [13] = se2 -> e2_vencrea
			_aTit [14] = ''
			_aTit [15] = ''
			_aTit [16] = ''
			_aTit [17] = ''
			_aTit [18] = .f.
			_aTit [19] = {}
			
			_sHistSE5 = 'TR.SLD.P/FIL.' + _sFilDest + ' REF.' + se2 -> e2_hist

			begin transaction
			lMsErroAuto = .F.
			MSExecAuto({|x,y| Fina090(x,y)},3,_aTit)
			If lMsErroAuto
				_lContinua = .F.
				U_Log2 ('erro', u_LeErro (memoread (NomeAutoLog ())))
			else

				// Arquivo SE5 vem, algumas vezes, desposicionado. Robert, 20/12/2016.
				se2 -> (dbgoto (_aTit [1, 1]))
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += "SELECT MAX (R_E_C_N_O_)"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("SE5") + " SE5 "
				_oSQL:_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND E5_FILIAL      = '" + se2 -> e2_filial  + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_CLIFOR  = '" + se2 -> e2_fornece + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_LOJA    = '" + se2 -> e2_loja    + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_PREFIXO = '" + se2 -> e2_prefixo + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_NUMERO  = '" + se2 -> e2_num     + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_PARCELA = '" + se2 -> e2_parcela + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_TIPO    = '" + se2 -> e2_tipo    + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_VACHVEX = ''"
				//_oSQL:Log ()
				_nRegSE5 = _oSQL:RetQry ()
				if _nRegSE5 > 0
					se5 -> (dbgoto (_nRegSE5))
					reclock ('SE5', .F.)
					se5 -> e5_vachvex = se2 -> e2_vachvex
					se5 -> e5_histor  = left (_sHistSE5, tamsx3 ("E5_HISTOR")[1])
					msunlock ()
					u_log2 ('info', 'Regravei historico do SE5 para: ' + se5 -> e5_histor)
				else
					u_log2 ('erro', 'Nao encontrei SE5 para atualizar historico e chave externa.')
				endif
				
				if fk2 -> fk2_valor == se2 -> e2_valor .and. fk2 -> fk2_motbx == 'NOR'  // Para ter mais certeza de que estah posicionado no registro correto.
					reclock ('FK2', .F.)
					fk2 -> fk2_histor = left (alltrim (fk2 -> fk2_histor) + ' ' + _sHistSE5, tamsx3 ("FK2_HISTOR")[1])
					msunlock ()
					u_log2 ('info', 'Regravei historico do FK2 para: ' + fk2 -> fk2_histor)
				endif

				// Prepara dados para geracao de objeto JSON para posterior gravacao de batch.
				_sTxtJSON := '{"EmpDest":"'    + cEmpAnt           + '"'
				_sTxtJSON += ',"FilDest":"'    + _sFilDest         + '"'
				_sTxtJSON += ',"DtBxTran":"'   + dtos (_dDtBxTran) + '"'
				_sTxtJSON += ',"e2_filial":"'  + se2 -> e2_filial  + '"'
				_sTxtJSON += ',"e2_num":"'     + se2 -> e2_num     + '"'
				_sTxtJSON += ',"e2_prefixo":"' + se2 -> e2_prefixo + '"'
				_sTxtJSON += ',"e2_parcela":"' + se2 -> e2_parcela + '"'
				_sTxtJSON += ',"e2_fornece":"' + se2 -> e2_fornece + '"'
				_sTxtJSON += ',"e2_loja":"'    + se2 -> e2_loja    + '"'
				_sTxtJSON += ',"e2_valor":"'   + cvaltochar (se2 -> e2_valor) + '"'  // Este eh mais por garantia de encontrar o titulo certo...
				_sTxtJSON += '}'

				// Se fez a baixa na filial de origem, agenda rotina batch para a inclusao na filial de destino.
				_oBatchDst := ClsBatch():new ()
				_oBatchDst:Dados    = 'Transf.sld.SE2 fil.' + cFilAnt + ' p/' + _sFilDest + '-Forn.' + se2 -> e2_fornece + '/' + se2 -> e2_loja
				_oBatchDst:EmpDes   = cEmpAnt
				_oBatchDst:FilDes   = _sFilDest
				_oBatchDst:DataBase = se2 -> e2_emissao
				_oBatchDst:Modulo   = 6  // Campo E2_VACHVEX nao eh gravado em alguns modulos... vai saber...
				_oBatchDst:Comando  = "U_BatTrSE2()"
				_oBatchDst:JSON     = _sTxtJSON
				_oBatchDst:Prioridade = 8  // Nao tenho grande urgencia na execucao deste batch
				if ! _oBatchDst:Grava ()
					_oBatch:Mensagens += "Erro gravacao batch filial destino"
					_oBatch:Retorno = 'N'
					_lContinua = .F.
				endif
			endif
			end transaction
			(_sAliasQ) -> (dbskip ())
		enddo
	endif

	// Libera semaforo
	U_Semaforo (_nLock)

	U_Log2 ('info', 'Finalizando ' + procname ())
return



// --------------------------------------------------------------------------
// Transfere para a matriz os registros do SZI que ainda tiverem saldo.
// Teoricamente isso jah foi feito quando o SZI foi gerado, mas pode ter sobrado alguma coisa.
static function _TrSZIMat ()
	local _oSQL      := NIL
	local _aRegSZI   := {}
	local _nRegSZI   := 0
	local _sSafrComp := strzero (year (dDataBase), 4)
	local _oCtaCorr  := NIL
	local _nLock     := 0

	_nLock := U_Semaforo (procname ())
	if _nLock == 0
		return
	endif

	U_Log2 ('info', 'Iniciando ' + procname ())
	if cFilAnt == '01'
		U_Log2 ('aviso', 'Nao ha necessidade de executar esta rotina na matriz.')
	else
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT SZI.R_E_C_N_O_"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2, "
		_oSQL:_sQuery +=              RetSQLName ("SZI") + " SZI "
		_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SE2.E2_FILIAL  = '" + xfilial ("SE2") + "'"
		_oSQL:_sQuery +=    " AND SE2.E2_FILIAL != '01'"  // Nao adianta olhar na matriz
		
		// Nao quero pegar as de hoje para evitar transferir enquanto tem alguem gerando contranota, ou o outro batch gerando SZI.
		// Alem disso, deixo um tempo para o pessoal cancelar alguma nota recente se precisarem.
		_oSQL:_sQuery +=    " AND SE2.E2_EMISSAO <= '" + dtos (date () - 3) + "'"
		
		_oSQL:_sQuery +=    " AND SZI.ZI_FILIAL  = SE2.E2_FILIAL"
		_oSQL:_sQuery +=    " AND SZI.ZI_ASSOC   = SE2.E2_FORNECE"
		_oSQL:_sQuery +=    " AND SZI.ZI_LOJASSO = SE2.E2_LOJA"
		_oSQL:_sQuery +=    " AND SZI.ZI_SERIE   = SE2.E2_PREFIXO"
		_oSQL:_sQuery +=    " AND SZI.ZI_DOC     = SE2.E2_NUM"
		_oSQL:_sQuery +=    " AND SZI.ZI_PARCELA = SE2.E2_PARCELA"
		_oSQL:_sQuery +=    " AND SZI.ZI_TM      = '13'"
		_oSQL:_sQuery +=    " AND SZI.ZI_SALDO   > 0"
		_oSQL:_sQuery +=    " AND EXISTS (SELECT *"  // Precisa ser nota de safra
		_oSQL:_sQuery +=                  " FROM VA_VNOTAS_SAFRA V"
		_oSQL:_sQuery +=                 " WHERE V.SAFRA       = '" + _sSafrComp + "'"
		_oSQL:_sQuery +=                   " AND V.FILIAL      = SE2.E2_FILIAL"
		_oSQL:_sQuery +=                   " AND V.ASSOCIADO   = SE2.E2_FORNECE"
		_oSQL:_sQuery +=                   " AND V.LOJA_ASSOC  = SE2.E2_LOJA"
		_oSQL:_sQuery +=                   " AND V.SERIE       = SE2.E2_PREFIXO"
		_oSQL:_sQuery +=                   " AND V.DOC         = SE2.E2_NUM"
		_oSQL:_sQuery +=                   " AND V.TIPO_NF     IN ('C', 'V')"
		_oSQL:_sQuery +=                   " AND V.TIPO_FORNEC LIKE '1%'"  // 1=ASSOCIADO
		_oSQL:_sQuery +=                ")"
		_oSQL:_sQuery +=  " ORDER BY SE2.E2_FORNECE, SE2.E2_LOJA, SE2.E2_NUM, SE2.E2_PREFIXO, SE2.E2_PARCELA"
		_oSQL:Log ()
		_aRegSZI = _oSQL:Qry2Array (.f., .f.)
		procregua (len (_aRegSZI))
		for _nRegSZI = 1 to len (_aRegSZI)
			_oCtaCorr := ClsCtaCorr():New (_aRegSZI [_nRegSZI, 1])
			_oCtaCorr:FilDest = '01'
			U_Log2 ('info', '[' + procname () + '](' + cvaltochar (_nRegSZI) + ' de ' + cvaltochar (len (_aRegSZI)) + ')Solicitando transferencia do saldo do docto ' + _oCtaCorr:Doc + '/' + _oCtaCorr:Parcela + ' para a matriz.')
			if ! _oCtaCorr:TransFil (_oCtaCorr:DtMovto)
				u_help ("A transferencia para outra filial nao foi possivel. " + _oCtaCorr:UltMsg,, .T.)
			endif
			FreeObj (_oCtaCorr)
		next
	endif

	// Libera semaforo
	U_Semaforo (_nLock)

	U_Log2 ('info', 'Finalizando ' + procname ())
return
