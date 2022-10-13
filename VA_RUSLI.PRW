// Programa...: VA_RUSLI
// Autor......: Robert Koch
// Data.......: 24/01/2019
// Descricao..: Leitura das inspecoes no NaWeb
//
// Historico de alteracoes:
// 01/03/2019 - Robert - Criada tag .InspecoesSafraMisturaNoTombador
// 13/12/2019 - Robert - Adequacoes iniciais para safra 2020.
// 21/02/2020 - Robert - Eliminados alguns logs desnecessarios.
// 01/02/2021 - Robert - Comentariadas linhas de log.
// 11/03/2022 - Robert - Melhorados logs.
//                     - Criada opcao de simular, para conferencias posteriores.
//                     - Tratamento para dados lidos no NaWeb, que vem em formato caracter (GLPI 11745).
//

#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
user function va_rusLI (_nPesagem, _lSimular)
	local _lContinua  := .T.
	local _aAreaAnt   := U_ML_SRArea ()
	local _oSQL       := NIL
	local _oEvento    := NIL
	local _sAliasInsp := ""  // Deixar private para ser vista por outras rotinas.
	local _sInspBotr  := ''
	local _sInspGlom  := ''
	local _sInspAspe  := ''
	local _sInspPodr  := ''
	local _sInspAcid  := ''
	local _sInspMEst  := ''
//	local _sInspDesu  := ''
	local _sLinkSrv   := U_LkServer ('NAWEB')
	local _aClasUva   := {}
	local _sMsg       := ''

	if _lSimular
		u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Iniciando em modo de SIMULACAO')
	endif

	if type ("_oCarSaf") != 'O'
		private _oCarSaf  := ClsCarSaf ():New (sze -> (recno ()))
	endif

	// Verifica situacao do agendamento / inspecoes.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT SITUACAO,"
		_oSQL:_sQuery +=        " VAR_NAO_PREV_CAD_VIT as VarNaoPrev,"
		_oSQL:_sQuery +=        " ENTREGOU_CADERNO_CPO as EntrCad,"
		_oSQL:_sQuery +=        " BOTRYTIS_PATIO as BOTRYP, "
		_oSQL:_sQuery +=        " BOTRYTIS_TOMBADOR AS BOTRYT, "
		_oSQL:_sQuery +=        " GLOMERELLA_PATIO as GlomeP, "
		_oSQL:_sQuery +=        " GLOMERELLA_TOMBADOR as GlomeT, "
		_oSQL:_sQuery +=        " ASPERGILLUS_PATIO as AsperP, "
		_oSQL:_sQuery +=        " ASPERGILLUS_TOMBADOR as AsperT, "
		_oSQL:_sQuery +=        " PODRIDAO_ACIDA_PATIO as PodriP, "
		_oSQL:_sQuery +=        " PODRIDAO_ACIDA_TOMBADOR as PodriT, "
		_oSQL:_sQuery +=        " ACIDEZ_VOLATIL_PATIO as AcVolP, "
		_oSQL:_sQuery +=        " ACIDEZ_VOLATIL_TOMBADOR as AcVolT, "
		_oSQL:_sQuery +=        " MATERIAIS_ESTRANHOS_PATIO as MEstrP, "
		_oSQL:_sQuery +=        " MATERIAIS_ESTRANHOS_TOMBADOR as MEstrT, "
		_oSQL:_sQuery +=        " MISTURA_VARIEDADES as Mistu,"
		_oSQL:_sQuery +=        " AGENDAORI as AgendaOri"
		_oSQL:_sQuery +=   " FROM " + _sLinkSrv + ".VA_VINSPECOES_SAFRA_" + sze -> ze_safra
		_oSQL:_sQuery +=  " WHERE SAFRA  = '" + sze -> ze_safra  + "'"
		_oSQL:_sQuery +=    " AND FILIAL = '" + sze -> ze_filial + "'"
		_oSQL:_sQuery +=    " AND CARGA  = '" + sze -> ze_carga  + "'"
//		_oSQL:Log ()
		u_Log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']' + _oSQL:_sQuery)
		_sAliasInsp = _oSQL:Qry2Trb (.F.)

		// Alimenta array de inspecoes. Deve estar previamente criada como 'private' na rotina chamadora.
		_aRusInsp = aclone (afill (array (.InspecoesSafraQtColunas), ''))

		if (_sAliasInsp) -> (eof ())
			u_log2 ('aviso', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Sem retorno na consulta de inspecoes. Vou assumir valores padrao.')

			// Se nao encontrou inspecao, assume status vazio e nao conforme para facilitar nos testes posteriores.
			_aRusInsp [.InspecoesSafraSituacao]         = '   '
			_aRusInsp [.InspecoesSafraVarNaoPrevCadVit] = 'N'  // N='Nao teve nenhuma variedade nao prevista no cadastro viticola'
			_aRusInsp [.InspecoesSafraEntrCadCpo]       = 'S'  // S='entregou caderno de campo'
			_sInspBotr = ''
			_sInspGlom = ''
			_sInspAspe = ''
			_sInspPodr = ''
			_sInspAcid = ''
			_sInspMEst = ''
			//_sInspDesu = ''
			if _nPesagem == 2
				_sMsg = "A T E N C A O: Nao foi possivel buscar as inspecoes desta carga. Verifique se a inspecao foi feita e se foi feita sincronizacao do APP de safra. Se voce prosseguir, a classificacao final da uva VAI FICAR COMPROMETIDA."
				U_Log2 ('aviso', '[' + procname () + '][Carga:' + sze -> ze_carga + ']' + _sMsg)
				if ! _lSimular
					_lContinua = U_MsgNoYes (_sMsg + " Deseja continuar assim mesmo?")
					if _lContinua
						_oEvento := ClsEvent ():New ()
						_oEvento:Alias   = 'SZE'
						_oEvento:Texto   = 'Recebimento da carga ' + sze -> ze_carga + ' sem leitura das inspecoes no NaWeb'
						_oEvento:CodEven = 'SZE003'
						_oEvento:Fornece = sze -> ze_assoc
						_oEvento:LojaFor = sze -> ze_lojasso
						_oEvento:Recno   = sze -> (recno ())
						_oEvento:CodAlias = sze -> ze_safra + sze -> ze_carga
						_oEvento:Grava ()
					endif
				endif
			endif
		else
			_aRusInsp [.InspecoesSafraSituacao]          = (_sAliasInsp) -> situacao
			_aRusInsp [.InspecoesSafraVarNaoPrevCadVit]  = (_sAliasInsp) -> VarNaoPrev
			_aRusInsp [.InspecoesSafraEntrCadCpo]        = (_sAliasInsp) -> EntrCad
			_aRusInsp [.InspecoesSafraMisturaNoTombador] = (_sAliasInsp) -> Mistu
			_aRusInsp [.InspecoesSafraAgendaOri]         = (_sAliasInsp) -> AgendaOri

			// Se tem resultado na inspecao de tombador, melhor. Senao, pega a de patio.
			_sInspBotr = alltrim (iif (! empty ((_sAliasInsp) -> BotryT), (_sAliasInsp) -> BotryT, (_sAliasInsp) -> BotryP))
			_sInspGlom = alltrim (iif (! empty ((_sAliasInsp) -> GlomeT), (_sAliasInsp) -> GlomeT, (_sAliasInsp) -> GlomeP))
			_sInspAspe = alltrim (iif (! empty ((_sAliasInsp) -> AsperT), (_sAliasInsp) -> AsperT, (_sAliasInsp) -> AsperP))
			_sInspPodr = alltrim (iif (! empty ((_sAliasInsp) -> PodriT), (_sAliasInsp) -> PodriT, (_sAliasInsp) -> PodriP))
			_sInspAcid = alltrim (iif (! empty ((_sAliasInsp) -> AcVolT), (_sAliasInsp) -> AcVolT, (_sAliasInsp) -> AcVolP))
			_sInspMEst = alltrim (iif (! empty ((_sAliasInsp) -> MEstrT), (_sAliasInsp) -> MEstrT, (_sAliasInsp) -> MEstrP))
		endif
		(_sAliasInsp) -> (dbclosearea ())
		dbselectarea ("SZE")
//		U_LOG2 ('info', 'Finalizei a leitura das inspecoes com:')
//		u_log2 ('info', _aRusInsp)
	endif

	u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Inspecoes:')
	u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Situacao da carga no APP........: ' + _aRusInsp [.InspecoesSafraSituacao])
	u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Varied.nao prevista no cad.vitic: ' + _aRusInsp [.InspecoesSafraVarNaoPrevCadVit])
	u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Entrega cad.campo...............: ' + _aRusInsp [.InspecoesSafraEntrCadCpo])
	u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Mistura variedades no tombador..: ' + _aRusInsp [.InspecoesSafraMisturaNoTombador])
	u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Chave agenda original...........: ' + cvaltochar (_aRusInsp [.InspecoesSafraAgendaOri]))
	u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Botrytis........................: ' + _sInspBotr)
	u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Glomerella......................: ' + _sInspGlom)
	u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Aspergyllus.....................: ' + _sInspAspe)
	u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Podridoes.......................: ' + _sInspPodr)
	u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Acidez volatil..................: ' + _sInspAcid)
	u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Mat.estranho....................: ' + _sInspMEst)

	// Tratamento para dados retornados pelo sistema de inspecao
	if _lContinua
		if _nPesagem == 1
			if ! _aRusInsp [.InspecoesSafraSituacao] $ "LIB/SEG/CON/INS"
				_sMsg = "Carga nao localizada ou com status '" + _aRusInsp [.InspecoesSafraSituacao] + "' no sistema de agendamento / inspecao. Somente cargas com status LIB (liberadas), SEG (segregadas), CON (concluidas), INS (inspecionadas) na inspecao de patio devem ser recebidas. Se voce continuar o recebimento, pode nao ser possivel ler as inspecoes a partir do sistema de agenda/inspecao, podendo afetar a classificacao final da uva."
				if ! _lSimular
					_lContinua = U_MsgNoYes (_sMsg + " Deseja continuar assim mesmo?")
					if _lContinua
						_oEvento := ClsEvent ():New ()
						_oEvento:Alias   = 'SZE'
						_oEvento:Texto   = 'Recebimento da carga ' + sze -> ze_carga + ' sem leitura do status no NaWeb'
						_oEvento:CodEven = 'SZE002'
						_oEvento:Fornece = sze -> ze_assoc
						_oEvento:LojaFor = sze -> ze_lojasso
						_oEvento:Recno   = sze -> (recno ())
						_oEvento:CodAlias = sze -> ze_safra + sze -> ze_carga
						_oEvento:Grava ()
					endif
				endif
			endif
			if _lContinua .and. _aRusInsp [.InspecoesSafraVarNaoPrevCadVit] = 'S'  // Apareceram variedades nao previstas no cadastro viticola.
				if ! _lSimular
					reclock ("SZE", .F.)
					sze->ze_varnvit = 'S'
					msunlock ()
				endif
			endif
		endif
	endif

	if _lContinua
		if ! _lSimular
			reclock ("SZE", .F.)
			sze->ze_segreg = iif (_aRusInsp [.InspecoesSafraSituacao] == "SEG", 'S', 'N')
			msunlock ()
		endif
	endif

	// Atualiza itens da carga.
	if _lContinua
		sb1 -> (dbsetorder (1))
		szf -> (dbsetorder (1))  // filial + safra + carga + item
		szf -> (dbseek (xfilial ("SZF") + sze -> ze_safra + sze -> ze_carga, .T.))
		do while ! szf -> (eof ()) .and. szf -> zf_filial == xfilial ("SZF") .and. szf -> zf_safra == sze -> ze_safra .and. szf -> zf_carga == sze -> ze_carga

			if _nPesagem == 1  // Estou fazendo a 1a. pesagem
				if ! _lSimular
					reclock ("SZF", .F.)
					if _aRusInsp [.InspecoesSafraEntrCadCpo] == "S"  // Entregou o caderno de campo. Se respondeu 'sim' vou assumir que eh para todas as variedades da carga.
						szf -> zf_entrcad = 'S'
					endif
					msunlock ()
					u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Atualizei ZZF_ENTRCAD para ' + szf -> zf_entrcad)
				endif
			endif

			if _nPesagem == 2  // Estou fazendo a 2a. pesagem
				if ! sb1 -> (dbseek (xfilial ("SB1") + szf -> zf_produto, .F.))
					u_help ("Produto '" + szf -> zf_produto + "' nao localizado no cadastro.",, .t.)
					_lContinua = .F.
					exit
				else
					_aClasUva = {'','','','',''}  // Para o caso de nao encontrar nada.
					if sze -> ze_safra == '2019' .and. sb1 -> b1_varuva == 'F' .and. sb1 -> b1_vafcuva == 'F'
						_aClasUva = aclone (U_ClUva19 (szf -> zf_produto, val (szf -> zf_grau), szf -> zf_conduc, val (_sInspBotr), val (_sInspGlom), val (_sInspAspe), val (_sInspPodr), val (_sInspAcid), _sInspMEst, val (_sInspDesu)))
					elseif sze -> ze_safra == '2020'
						_aClasUva = aclone (U_ClUva20 (szf -> zf_produto, val (szf -> zf_grau), szf -> zf_conduc, val (_sInspBotr), val (_sInspGlom), val (_sInspAspe), val (_sInspPodr), val (_sInspAcid), _sInspMEst))
					elseif sze -> ze_safra == '2021'
				//		_aClasUva = aclone (U_ClUva21 (szf -> zf_produto, val (szf -> zf_grau), szf -> zf_conduc, val (_sInspBotr), val (_sInspGlom), val (_sInspAspe), val (_sInspPodr), val (_sInspAcid), _sInspMEst))
						_aClasUva = aclone (eval (&("{||U_ClUva" + right (sze -> ze_safra, 2) + " (szf -> zf_produto, val (szf -> zf_grau), szf -> zf_conduc, val (_sInspBotr), val (_sInspGlom), val (_sInspAspe), val (_sInspPodr), val (_sInspAcid), _sInspMEst)}")))
					elseif sze -> ze_safra == '2022'
						_aClasUva = aclone (U_ClUva22 (szf -> zf_produto, val (szf -> zf_grau), szf -> zf_conduc, _sInspBotr, _sInspGlom, _sInspAspe, _sInspPodr, _sInspAcid))
					elseif sze -> ze_safra == '2023'
						_aClasUva = aclone (U_ClUva23 (szf -> zf_produto, val (szf -> zf_grau), szf -> zf_conduc, _sInspBotr, _sInspGlom, _sInspAspe, _sInspPodr, _sInspAcid))
					else
						// A chamada com EVAL rodou bem, mas uma pesquisa nos fontes por CLUVA21, por exemplo, nao retorna nada. ---> _aClasUva = aclone (eval (&("{||U_ClUva" + right (sze -> ze_safra, 2) + " (szf -> zf_produto, val (szf -> zf_grau), szf -> zf_conduc, val (_sInspBotr), val (_sInspGlom), val (_sInspAspe), val (_sInspPodr), val (_sInspAcid), _sInspMEst)}")))
						u_help ("Sem tratamento para leitura de classificacao de uvas no programa " + procname ())
						_lContinua = .F.
						exit
					endif
//					u_log2 ('debug', '_aClasUva:')
//					u_log2 ('debug', _aClasUva)

					// Classificacao por grau ('Acucar') deve obrigatoriamente ser encontrada, pois nao fica carga sem grau informado.
					if ! _lSimular
						reclock ("SZF", .F.)
						szf -> zf_prm02 = _aClasUva [1]
						msunlock ()
					endif

					// Assume as classificoes calculadas somente se encontrou dados de inspecao no NaWeb. Senao, assume valores medios.
					if empty (_sInspBotr) .or. empty (_sInspGlom) .or. empty (_sInspAspe) .or. empty (_sInspPodr) .or. empty (_sInspAcid) .or. empty (_sInspMEst) //.or. empty (_sInspDesu)
						u_log2 ('aviso', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Nao tenho os dados de inspecoes. Assumindo valores medios (classificacao B).')
						if ! _lSimular
							reclock ("SZF", .F.)
							szf -> zf_prm03 = 'B'
							szf -> zf_prm04 = 'B'
							szf -> zf_prm05 = 'B'
							msunlock ()
						endif
					else
						if ! _lSimular
							reclock ("SZF", .F.)
							szf -> zf_prm03 = _aClasUva [2]
							szf -> zf_prm04 = _aClasUva [3]
							szf -> zf_prm05 = _aClasUva [4]
							msunlock ()
						endif
					endif
					if ! _lSimular
						reclock ("SZF", .F.)
						if szf -> zf_conduc == 'L'
							szf -> zf_clasABD = _aClasUva [1] // (comecamos a gravar em 2020, e neste ano obedece o acucar) --> [5]
							u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Classificacao final gravada no zf_clasABD = ' + szf -> zf_clasabd)
						elseif szf -> zf_conduc == 'E'
							szf -> zf_prm99 = _aClasUva [5]
							u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Classificacao final gravada no zf_prm99 = ' + szf -> zf_prm99)
						endif
						msunlock ()
					endif
				endif
			endif

			if type ('_aNovaClas') == 'A'  // Estou reprocessando GLPI 11746
				aadd (_aNovaClas, {szf -> zf_item, iif (szf -> zf_conduc == 'L', _aClasUva [1], _aClasUva [5])})
			endif

			szf -> (dbskip ())
		enddo
		if _lSimular
			//u_showarray (_aClasUva, 'Classificacoes encontradas')
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return _lContinua
