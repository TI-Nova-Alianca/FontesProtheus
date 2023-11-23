// Programa...: VA_RUS2G
// Autor......: Robert Koch
// Data.......: 12/12/2019 (criado com base no VA_RUS2 de 18/01/2010)
// Descricao..: Gravacao dos dados da carga safra.
//
// Historico de alteracoes:
// 20/01/2020 - Robert - Novos parametros chamada geracao ticket safra.
// 20/02/2020 - Robert - Desabilitada gravacao do talhao na descricao do ZZA.
// 21/02/2020 - Robert - Alteracoes na tabela ZZA passam a ser feitas em rotina externa (U_AtuZZA).
// 16/02/2021 - Robert - Implementada simulacao de geracao de contranota (GLPI 9420)
// 16/12/2021 - Robert - Novo formato de retorno da funcao U_GeraSZE()
// 16/02/2022 - Robert - Tratamentos para cancelamento de cargas chamado via web service (GLPI 11634)
// 11/03/2022 - Robert - Melhorados logs.
// 31/01/2023 - Robert - Tratamentos para gravacao de cargas compartilhadas.
// 03/02/2023 - Robert - Gravacao de eventos cfe. campos ZE_AlManPB,ZE_AlManPT, ZF_AlManGR
// 10/02/2023 - Robert - Gravacao evento cancelamento carga.
// 18/11/2023 - Robert - Versao inicial do metodo ClsCarSaf:PodeGravar().
//

#include "totvs.ch"
#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
// Gravacao / exclusao dos registros.
user Function VA_RUS2G (_nOpc, _oCarSaf)
	local _nCampo    := 0
	local _sCampo    := ""
	local _lContinua := .T.
	local _aCposFora := {}
	local _oSQL      := NIL
	local _sFrom     := ""
	local _nRegSZE   := 0
	local _sMotCanc  := ""
	local _nLinha    := 0
	local _nAglut    := 0
	local _nCompart  := 0

	u_log2 ('info', 'Iniciando ' + procname ())
	//U_PerfMon ('I', 'Interno_VA_Rus2G')

	if inclui .and. !_oCarSaf:PodeGravar ()
		_lContinua = .F.
		u_help (_oCarSaf:UltMsg,, .t.)
	endif

	// Confere se jah existe este numero de carga (caso haja problema com os sequenciais).
	if _lContinua .and. inclui
		sze -> (dbsetorder (1))  // ZE_FILIAL+ZE_SAFRA+ZE_CARGA
	//	U_Log2 ('debug', 'Pesquisando SZE com >>' + xfilial ("SZE") + m->ze_safra + m->ze_carga + '<<')
		if sze -> (dbseek (xfilial ("SZE") + m->ze_safra + m->ze_carga, .F.))
			u_help ("Nao sera possivel gravar esta carga. Carga '" + m->ze_carga + "' ja existe.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. (inclui .or. altera)

		//U_PerfMon ('I', 'Interno_VA_Rus2G_gravacao')

		// Gravacao dos campos da enchoice
		dbselectarea ("SZE")
		reclock ("SZE", inclui)
		for _nCampo := 1 to sze -> (FCount ())
			_sCampo = sze -> (FieldName (_nCampo))
			FieldPut (_nCampo, M->&(_sCampo))
		next
		
		// Campos que nao estao em uso mas devem ser gravados ou atualizados automaticamente.
		sze -> ze_filial = xfilial ("SZE")
		sze -> ze_status = iif (inclui, '1', '2')
		if altera
			sze -> ze_horsaid = time ()
		endif

		// Tratamento para cargas compartilhadas (que vieram no mesmo veiculo)
		// A lista de cargas compartilhadas eh guardada num campo caracter, em
		// formato de lista carga1/carga2/...
		for _nCompart = 1 to len (_oCarSaf:CCompart)
			if ! _oCarSaf:CCompart [_nCompart] $ sze -> ze_ccompar
				sze -> ze_ccompar = alltrim (sze -> ze_ccompar) + iif (empty (alltrim (sze -> ze_ccompar)), '', '/') + _oCarSaf:CCompart [_nCompart]
			endif
		next

		msunlock ("SZE")

		// Tratamento para cargas compartilhadas (que vieram no mesmo veiculo)
		// Preciso manter amarracao entre elas (cada carga aponta para as demais)
		// Para cada carga apontada pela atual, cria um vinculo reciproco.
		if len (_oCarSaf:CCompart) > 0
			_nRegSZE = sze -> (recno ())
			for _nCompart = 1 to len (_oCarSaf:CCompart)
				if ! sze -> (dbseek (_oCarSaf:Filial + _oCarSaf:Safra + _oCarSaf:CCompart [_nCompart], .F.))
					u_help ("Nao localizei a carga '" + _oCarSaf:CCompart [_nCompart] + "' para marcar ela como compartilhada com a carga atual (" + _oCarSaf:Carga + ")",, .t.)
				else
					if ! _oCarSaf:Carga $ sze -> ze_ccompar
						U_Log2 ('debug', '[' + procname () + ']Adicionando a carga atual (' + _oCarSaf:Carga + ') na lista de compartilhamento da carga ' + sze -> ze_carga)
						reclock ("SZE", .F.)
						sze -> ze_ccompar = alltrim (sze -> ze_ccompar) + iif (empty (alltrim (sze -> ze_ccompar)), '', '/') + _oCarSaf:Carga
						msunlock ()
					else
						U_Log2 ('debug', '[' + procname () + ']Carga atual (' + _oCarSaf:Carga + ') jah constava na lista de compartilhamento da carga ' + sze -> ze_carga)
					endif
				endif
			next
			// Reposiciona SZE apos atualizacao das cargas compartilhadas.
			sze -> (dbgoto (_nRegSZE))
		endif


		// Gravacao dos campos da getdados.
		// Monta lista de campos que nao estao no browse, com seu devido conteudo, para posterior gravacao.
		_aCposFora := {}
		aadd (_aCposFora, {"ZF_FILIAL", xfilial ("SZF")})
		aadd (_aCposFora, {"ZF_SAFRA", m->ze_safra})
		aadd (_aCposFora, {"ZF_CARGA", m->ze_carga})
		
		// Gravacao das linhas do aCols.
		SZF -> (dbsetorder (1))  // zf_FILIAL+zf_COD+zf_PRODUTO
		for _nLinha = 1 to len (aCols)
			
			// Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
			if szf -> (dbseek (xfilial ("SZF") + m->ze_safra + m->ze_carga + GDFieldGet ("ZF_ITEM", _nLinha) , .F.))
				
				// Se estah deletado em aCols, preciso excluir do arquivo tambem.
				if GDDeleted (_nLinha)
					reclock ("SZF", .F.)
					SZF -> (dbdelete ())
					msunlock ("SZF")
				else  // Alteracao
					reclock ("SZF", .F.)
					U_GrvACols ("SZF", _nLinha, _aCposFora)
					msunlock ("SZF")
				endif
				
			else  // A linha ainda nao existe no arquivo
				if ! GDDeleted (_nLinha)
					reclock ("SZF", .T.)
					U_GrvACols ("SZF", _nLinha, _aCposFora)
					msunlock ("SZF")
				endif
			endif

			//U_PerfMon ('L', 'Interno_VA_Rus2G_gravacao')
		next
		
		// Confirma sequenciais, se houver.
		do while __lSX8
			ConfirmSX8 ()
		enddo


		// Grava relacionamento entre cargas de origem e de destino, em caso de aglutinacao de cargas.
		if m->ze_aglutin == "D"
			_nRegSZE = sze -> (recno ())
			for _nAglut = 1 to len (_aAglut)
				reclock ("ZZD", .T.)
				zzd -> zzd_filial = xfilial ("ZZD")
				zzd -> zzd_safra  = m->ze_safra
				zzd -> zzd_carDes = m->ze_carga
				zzd -> zzd_ItDes  = _aAglut [_naglut, 1]
				zzd -> zzd_carOri = _aAglut [_naglut, 2]
				zzd -> zzd_ItOri  = _aAglut [_naglut, 3]
				msunlock ()

				// Muda o status das cargas aglutinadas.
				sze -> (dbsetorder (1))  // ZE_FILIAL+ZE_SAFRA+ZE_CARGA
				if ! sze -> (dbseek (xfilial ("SZE") + zzd -> zzd_Safra + zzd -> zzd_CarOri, .F.))
					u_help ("Erro na atualizacao da carga aglutinada '" + zzd -> zzd_CarOri + "'. Solicite manutencao do programa!",, .t.)
				else
					reclock ("SZE", .F.)
					sze -> ze_aglutin = 'O'
					msunlock ("SZE")
				endif
			next

			// Reposiciona SZE apos atualizacao das cargas aglutinadas.
			sze -> (dbgoto (_nRegSZE))
		endif


		_oCarSaf:GeraAtrib ("SZE")  // Atualiza atributos com o que foi gravado nos arquivos.
		_oCarSaf:Log ()

		// Atualiza tabela de comunicacao com leitor de grau.
		if _oCarSaf:PesoBruto > 0  // Sem 1a.pesagem, nem adianta enviar.
			_oCarSaf:AtuZZA (.F.)
		endif

		// Imprime ticket
		if inclui
			_oCarSaf:ImprimeTk (1)
		elseif altera
			_oCarSaf:ImprimeTk (2)
		endif

		// Verifica necessidade de gravar algum evento dedo-duro.
		if ! empty (m->ze_AlManPB)
			_oCarSaf:GrvEvt ('SZE006', alltrim (m->ze_AlManPB))
		endif
		if ! empty (m->ze_AlManPT)
			_oCarSaf:GrvEvt ('SZE006', alltrim (m->ze_AlManPT))
		endif
		for _nLinha = 1 to len (aCols)
			if ! GDDeleted (_nLinha) .and. ! empty (GDFieldGet ("ZF_ALMANGR", _nLinha))
				_oCarSaf:GrvEvt ('SZE007', 'Variedade ' + alltrim (GDFieldGet ("ZF_PRODUTO", _nLinha)) + ' ' + alltrim (GDFieldGet ("ZF_ALMANGR", _nLinha)))
			endif
		next

		// Verifica se jah pode gerar contranota.
		if altera .or. (inclui .and. m->ze_aglutin == "D")   // 2a. pesagem ou 1a. pesagem aglutinada
			if m->ze_coop $ "000021/001369" //.or. m->ze_coop == '000026' .and. m->ze_safra == '2019'
				if empty (m->ze_nfger) .and. ! empty (m->ze_nfprod)
					if U_msgyesno ("Deseja gerar a contranota agora?")
						CursorWait ()
						U_VA_RUSN (.F.)
						CursorArrow ()
					endif
				endif
			else
				if U_msgyesno ("Deseja imprimir recibo agora?")
					U_VA_RUSR ()
				endif
			endif
		endif

	elseif _nOpc == 5  // Exclusao (cancelar carga)

		// Se for carga gerada atraves da aglutinacao de outras, desmarca o flag
		// de aglutinacao das cargas originais e deleta a tabela de cargas relacionadas.
		if _lContinua .and. m->ze_aglutin == "D"
			_sFrom := ""
			_sFrom += " FROM " + RetSQLName ("SZE") + " SZE, "
			_sFrom +=            RetSQLName ("ZZD") + " ZZD "
			_sFrom += " WHERE SZE.D_E_L_E_T_ = ''"
			_sFrom +=   " AND ZZD.D_E_L_E_T_ = ''"
			_sFrom +=   " AND SZE.ZE_FILIAL  = '" + xfilial ("SZE") + "'"
			_sFrom +=   " AND ZZD.ZZD_FILIAL = '" + xfilial ("ZZD") + "'"
			_sFrom +=   " AND SZE.ZE_SAFRA   = '" + m->ze_safra + "'"
			_sFrom +=   " AND ZZD.ZZD_SAFRA  = '" + m->ze_safra + "'"
			_sFrom +=   " AND ZZD.ZZD_CARDES = '" + m->ze_carga + "'"
			_sFrom +=   " AND SZE.ZE_CARGA   = ZZD.ZZD_CARORI"
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery = "UPDATE SZE SET SZE.ZE_AGLUTIN = 'N' " + _sFrom
			_lContinua = _oSQL:Exec ()
			if _lContinua
				_oSQL:_sQuery = "UPDATE ZZD SET ZZD.D_E_L_E_T_ = '*' " + _sFrom
				_lContinua = _oSQL:Exec ()
			endif
		endif

		if _lContinua
			if type ('_sMotCanWS') == 'C'
				_sMotCanc = left (_sMotCanWS, TamSX3("ZE_MOVCANC")[1])
			else
				_sMotCanc = space (TamSX3("ZE_MOVCANC")[1])
				_sMotCanc = U_Get ('Motivo do cancelamento', 'C', len (_sMotCanc), '@!', '', _sMotCanc, .F., '.T.')
			endif
			if empty (_sMotCanc)
				u_help ("Deve ser informado um motivo para cancelamento da carga.",, .t.)
				_lContinua = .F.
			endif
		endif

		if _lContinua
			reclock ("SZE", .F.)
			sze -> ze_status = 'C'
			sze -> ze_moVcanc = _sMotCanc
			msunlock ()

			_oCarSaf:GeraAtrib ("SZE")  // Atualiza atributos com o que foi gravado nos arquivos.
			_oCarSaf:GrvEvt ('SZE010', 'Cancelamento carga c/motivo: ' + _sMotCanc)

			// Atualiza tabela de comunicacao com leitor de grau.
			_oCarSaf:AtuZZA (.F.)

			if type ('_sMsgRetWS') == 'C'  // Variavel publica que estah disponivel quando execucao via web service.
				_sMsgRetWS += "Carga cancelada."
			endif

		else
			u_help ('O cancelamento nao foi efetuado.',, .t.)
		endif

	endif
	
Return _lContinua
