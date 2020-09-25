// Programa...: VA_RUS2G
// Autor......: Robert Koch
// Data.......: 12/12/2019 (criado com base no VA_RUS2 de 18/01/2010)
// Descricao..: Gravacao dos dados da carga safra.
//
// Historico de alteracoes:
// 20/01/2020 - Robert - Novos parametros chamada geracao ticket safra.
// 20/02/2020 - Robert - Desabilitada gravacao do talhao na descricao do ZZA.
// 21/02/2020 - Robert  - Alteracoes na tabela ZZA passam a ser feitas em rotina externa (U_AtuZZA).
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

	u_logIni ()

	// Confere se jah existe este numero de carga (caso haja problema com os sequenciais).
	if _lContinua .and. inclui
		sze -> (dbsetorder (1))  // ZE_FILIAL+ZE_SAFRA+ZE_CARGA
		if sze -> (dbseek (xfilial ("SZE") + m->ze_safra + m->ze_carga, .F.))
			u_help ("Nao sera possivel gravar esta carga. Carga '" + m->ze_carga + "' ja existe.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. (inclui .or. altera)

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
		if type ("_RetGrvZZE") == 'C'
			_RetGrvZZE = sze -> ze_carga
			u_log ('_RetGrvZZE:', _RetGrvZZE)
		endif
	
		msunlock ("SZE")
		_nRegSZE = sze -> (recno ())
//		U_LOG ('SZE gravado - recno', _nRegSZE)
		
		// Gravacao de campos MEMO virtuais (se existirem no cabecalho) deve-se usar este exemplo:
		// MSMM (,,,m->ze_memo, 1, ,, "SZE", "ZE_CODMEM")
		

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
			
/*
			// Tratamento para o ZZA (arquivo para o programa de leitura de brix) eh feito de forma semelhante ao SZF.
			//
			// Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
			if inclui
				if zza -> (dbseek (xfilial ("ZZA") + m->ze_safra + m->ze_carga + GDFieldGet ("ZF_ITEM", _nLinha), .F.))
					if GDDeleted (_nLinha)  // Se estah deletado em aCols, preciso excluir do arquivo tambem.
						_GravaZZA ('D', _nLinha)
					else  // Alteracao
						_GravaZZA ('A', _nLinha)
					endif
				else  // A linha ainda nao existe no arquivo
					if ! GDDeleted (_nLinha)
						_GravaZZA ('I', _nLinha)
					endif
				endif
			endif
*/
		next
		
		// Confirma sequenciais, se houver.
		do while __lSX8
			ConfirmSX8 ()
		enddo

		// Atualiza tabela de comunicacao com leitor de grau.
		U_AtuZZA (sze -> ze_safra, sze -> ze_carga)

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
					u_help ("Erro na atualizacao da carga aglutinada '" + zzd -> zzd_CarOri + "'. Solicite manutencao do programa!")
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
				U_VA_RUSTk (1, _sPortTick, _nQViasTk1, {}, 'Bematech', .t.)
			elseif altera
				U_VA_RUSTk (2, _sPortTick, _nQViasTk2, {}, 'Bematech', .t.)
			endif
		endif

		// Verifica se deve gerar contranota agora.
		if altera .or. (inclui .and. m->ze_aglutin == "D")   // 2a. pesagem ou 1a. pesagem aglutinada
//			if m->ze_coop $ "000021/001369"
			if m->ze_coop $ "000021/001369" .or. m->ze_coop == '000026' .and. m->ze_safra == '2019'
				if empty (m->ze_nfger) .and. ! empty (m->ze_nfprod)
					if U_msgyesno ("Deseja gerar a contranota agora?")
						CursorWait ()
						U_VA_RUSN ()
						CursorArrow ()
					endif
				endif
			else
				if U_msgyesno ("Deseja imprimir recibo agora?")
					U_VA_RUSR ()
				endif
			endif
		endif

	elseif _nOpc == 5  // Exclusao

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
			_sMotCanc = space (TamSX3("ZE_MOVCANC")[1])
			_sMotCanc = U_Get ('Motivo do cancelamento', 'C', len (_sMotCanc), '@!', '', _sMotCanc, .F., '.T.')
			_lContinua = ! empty (_sMotCanc)
		endif

		if _lContinua

/*			// Tratamento para o ZZA (arquivo para o programa de leitura de brix)
			zza -> (dbsetorder (1))  // ZZA_FILIAL+ZZA_SAFRA+ZZA_CARGA+ZZA_PRODUT
			zza -> (dbseek (xfilial ("ZZA") + sze -> ze_safra + sze -> ze_carga, .T.))
			do while ! zza -> (eof ()) .and. zza -> zza_filial == xfilial ("ZZA") .and. zza -> zza_safra == sze -> ze_safra .and. zza -> zza_carga == sze -> ze_carga
				reclock ("ZZA", .F.)
				zza -> zza_status = 'C'
				msunlock ()
				zza -> (dbskip ())
			enddo
*/
			// Se houver campos memo no cabecalho, deletar com o exemplo abaixo:
			// MSMM (sze -> ze_codmem,,,,2)
	
			reclock ("SZE", .F.)
			sze -> ze_status = 'C'
			sze -> ze_moVcanc = _sMotCanc
			msunlock ()

			// Atualiza tabela de comunicacao com leitor de grau.
			U_AtuZZA (sze -> ze_safra, sze -> ze_carga)
		else
			u_help ('O cancelamento nao foi efetuado.') 
		endif

	endif
	u_logFim ()
Return _lContinua


/*
// --------------------------------------------------------------------------
// Gravacao do arquivo de dados para medidor de brix.
// Grava independentemente de usar ou nao a integracao com leitor de brix, por que
// pode ocorrer algum caso do usuario parametrizar a integracao como 'nao' para
// finalizar alguma carga perdida, e as demais cargas novas ficariam sem o ZZA.
// Conteudos possiveis para o campo ZZA_STATUS:
// 0 = carga cadastrada no Protheus, ainda nao pesada. Programa BL01 ignora-a;
// 1 = carga com 1a.pesagem pronta, pode descarregar. Programa BL01 lista-a para o usuario ao clicar no botao 'Filial/Safra/Carga';
// 2 = carga selecionada pelo usuario no programa BL01. Estah pronto para medir grau, ou jah medindo;
// 3 = usuario clicou botao 'Armazenar' no programa BL01 e jah gravou tambem o ZZA_GRAU.
// M = usuario (do Protheus) finalizou manualmente (ZZA_STATUS nao estava 3 por algum motivo).
static function _GravaZZA (_sQueFazer, _nLinha)
	if m->ze_aglutin != "D"  // Cargas aglutinadoras n�o precisam medir grau
		u_logDH ('Atualizando ZZA (opcao', _sQueFazer, ')')
		reclock ("ZZA", iif (_sQueFazer == 'I', .T., .F.))
		if _sQueFazer == 'D'
			zza -> (dbdelete ())
		else
			zza -> zza_filial = xfilial ("ZZA")
			zza -> zza_safra  = sze -> ze_safra
			zza -> zza_carga  = sze -> ze_carga
			zza -> zza_produt = GDFieldGet ("ZF_ITEM", _nLinha)
			zza -> zza_nprod  = alltrim (GDFieldGet ("ZF_DESCRI", _nLinha))  // + ' (talhao ' + GDFieldGet ("ZF_IDSZ9", _nLinha) + ')'
			zza -> zza_nassoc = sze -> ze_nomasso
			
			// Se nao informar peso bruto, nao considera a primeira pesagem pronta e nao libera para leitura de brix.
			//zza -> zza_status = iif (m->ze_pesobru == 0, '0', '1')

			// Se nao informar peso bruto, nao considera a primeira pesagem pronta e nao libera para leitura de brix.
			if m->ze_pesobru == 0
				zza -> zza_status = '0'
			elseif m->ze_pesotar > 0 .and. zza -> zza_status != '3' .and. val (GDFieldGet ("ZF_GRAU", _nLinha)) > 0  // Jah estah fazendo a segunda pesagem, sem finalizar no BL01. Vou alterar para [M]anual.
				u_log ('Alterando ZZA_STATUS para M por que jah estah sendo feita a segunda pesagem, mesmo sem finalizar no programa do grau.')
				zza -> zza_status = 'M'
			elseif m->ze_pesobru > 0 .and. m->ze_pesotar == 0
				zza -> zza_status = '1'
			else
				u_help ("Situacao nao prevista para gravacao do campo ZZA_STATUS. Revise programa.",, .t.)
			endif
			msunlock ()
			u_log ('ZZA_STATUS gravado:', zza -> zza_status)
		endif
	endif
return
*/