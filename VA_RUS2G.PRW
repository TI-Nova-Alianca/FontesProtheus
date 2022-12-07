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
//

#include "totvs.ch"
#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
// Gravacao / exclusao dos registros.
user Function VA_RUS2G (_nOpc)
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

	u_log2 ('info', 'Iniciando ' + procname ())
	U_PerfMon ('I', 'Interno_VA_Rus2G')

	// Confere se jah existe este numero de carga (caso haja problema com os sequenciais).
	if _lContinua .and. inclui
		sze -> (dbsetorder (1))  // ZE_FILIAL+ZE_SAFRA+ZE_CARGA
		U_Log2 ('debug', 'Pesquisando SZE com >>' + xfilial ("SZE") + m->ze_safra + m->ze_carga + '<<')
		if sze -> (dbseek (xfilial ("SZE") + m->ze_safra + m->ze_carga, .F.))
			u_help ("Nao sera possivel gravar esta carga. Carga '" + m->ze_carga + "' ja existe.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. (inclui .or. altera)

		U_PerfMon ('I', 'Interno_VA_Rus2G_gravacao')

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

		// Variavel para retorno do numero da carga para a funcao de geracao automatica.
		if type ("_sRetSZECG") == 'C'
			_sRetSZECG = sze -> ze_carga
		endif
	
		msunlock ("SZE")
		_nRegSZE = sze -> (recno ())
		
		// Gravacao dos campos da getdados.
		//
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

			U_PerfMon ('L', 'Interno_VA_Rus2G_gravacao')
		next
		
		// Confirma sequenciais, se houver.
		do while __lSX8
			ConfirmSX8 ()
		enddo

		// Atualiza tabela de comunicacao com leitor de grau.
	//	U_Log2 ('debug', '[' + procname () + '] Gravei SZE e SZF e vou chamar a atualizacao do ZZA.')
		U_PerfMon ('I', 'Interno_VA_Rus2G_AtuZZA')
		U_AtuZZA (sze -> ze_safra, sze -> ze_carga)
		U_PerfMon ('L', 'Interno_VA_Rus2G_AtuZZA')

		// Grava relacionamento entre cargas de origem e de destino, em caso de aglutinacao de cargas.
		if m->ze_aglutin == "D"
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

		// Verifica se deve imprimir ticket em impressora termica.
		if _lImpTick
			if inclui
				U_PerfMon ('I', 'Impr_ticket1_safra')  // Para metricas de performance
				U_VA_RUSTk (1, _sPortTick, _nQViasTk1, {}, 'Bematech', .t.)
				U_PerfMon ('L', 'Impr_ticket1_safra')  // Para metricas de performance
			elseif altera
				U_VA_RUSTk (2, _sPortTick, _nQViasTk2, {}, 'Bematech', .t.)
			endif
		endif

		// Verifica se deve gerar contranota agora.
		if altera .or. (inclui .and. m->ze_aglutin == "D")   // 2a. pesagem ou 1a. pesagem aglutinada
			if m->ze_coop $ "000021/001369" .or. m->ze_coop == '000026' .and. m->ze_safra == '2019'
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

			// Atualiza tabela de comunicacao com leitor de grau.
			U_AtuZZA (sze -> ze_safra, sze -> ze_carga)

			if type ('_sMsgRetWS') == 'C'  // Variavel publica que estah disponivel quando execucao via web service.
				_sMsgRetWS += "Carga cancelada."
			endif
		else
			u_help ('O cancelamento nao foi efetuado.',, .t.)
		endif

	endif
	U_PerfMon ('L', 'Interno_VA_Rus2G')
	
Return _lContinua
