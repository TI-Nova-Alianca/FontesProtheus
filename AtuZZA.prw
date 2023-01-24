// Programa...: AtuZZA
// Autor......: Robert Koch
// Data.......: 21/02/2020 (criado com base no VA_RUS2 de 18/01/2010)
// Descricao..: Gravacao dos dados da tabela ZZA (comunicacao com medidor de brix para safra).

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Gravacao dos dados da tabela ZZA (integracao com medidor de brix para safra).
// #PalavasChave      #grau #brix #babo #safra #integracao #Maseli #BL01
// #TabelasPrincipais #ZZA
// #Modulos           #coop

// Historico de alteracoes:
// 02/02/2021 - Robert - Testa se o campo zza_status estah vazio antes de gravar status 1 (pois eh chamado tb a partir da 2a.pesagem)
// 03/02/2021 - Robert - Ajuste gravacao ZZA_STATUS na primeira pesagem.
// 11/03/2022 - Robert - Melhorados logs.
//

// Possiveis situacoes para o campo ZZA_STATUS:
// 0 = carga cadastrada no Protheus, ainda nao pesada. Programa BL01 ignora-a;
// 1 = carga com 1a.pesagem pronta, pode descarregar. Programa BL01 lista-a para o usuario ao clicar no botao 'Filial/Safra/Carga';
// 2 = carga selecionada pelo usuario no programa BL01. Estah pronto para medir grau, ou jah medindo;
// 3 = usuario clicou botao 'Armazenar' no programa BL01 e jah gravou tambem o ZZA_GRAU.
// M = usuario (do Protheus) finalizou manualmente (ZZA_STATUS nao estava 3 por algum motivo).
// C = Carga cancelada no Protheus

// --------------------------------------------------------------------------
// Gravacao do arquivo de dados para medidor de brix.
// Grava independentemente de usar ou nao a integracao com leitor de brix, por que
// pode ocorrer algum caso do usuario parametrizar a integracao como 'nao' para
// finalizar alguma carga perdida, e as demais cargas novas ficariam sem o ZZA.
user function AtuZZA (_sSafra, _sCarga)
	local _aAreaAnt := U_ML_SRArea ()
//	u_log2 ('info', 'Iniciando ' + procname () + ' com parametros safra >>' + _sSafra + '<< e carga >>' + _sCarga + '<<')

//	COM O TEMPO, PRETENDO MIGRAR PARA O METODO ClsCarSaf:AtuZZA()

	sze -> (dbsetorder (1))  // ZE_FILIAL, ZE_SAFRA, ZE_CARGA
	if ! sze -> (dbseek (xfilial ("SZE") + _sSafra + _sCarga, .F.))
		u_help ("Carga nao localizada nesta filial/safra. Atualizacao da tabela ZZA nao pode ser feita.",, .t.)
	else
//		u_log2 ('debug', '[' + procname () + '] Pesquisei SZE com safra/carga ' + _sSafra + _sCarga + ' e parei no SZE com ' + sze -> ze_safra + sze -> ze_carga)
		if sze -> ze_aglutin != "D"  // Cargas aglutinadoras nao precisam medir grau
			zza -> (dbsetorder (1))  // ZZA_FILIAL, ZZA_SAFRA, ZZA_CARGA, ZZA_PRODUT
			szf -> (dbsetorder (1))  // filial + safra + carga + item
			szf -> (dbseek (xfilial ("SZF") + sze -> ze_safra + sze -> ze_carga, .T.))
			do while ! szf -> (eof ()) .and. szf -> zf_filial == xfilial ("SZF") .and. szf -> zf_safra == sze -> ze_safra .and. szf -> zf_carga == sze -> ze_carga
//				U_Log2 ('debug', 'Chave busca ZZA: >>' + xfilial ("ZZA") + sze -> ze_safra + sze -> ze_carga + szf -> zf_item + '<<')
				if ! zza -> (dbseek (xfilial ("ZZA") + sze -> ze_safra + sze -> ze_carga + szf -> zf_item, .F.))
					u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Incluindo ZZA')
					reclock ("ZZA", .T.)
				else
//					u_logtrb ('ZZA', .F.)
					u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Vou alterar ZZA (zza_status encontra-se com ' + zza -> zza_status + ')')
					reclock ("ZZA", .F.)
				endif
				zza -> zza_filial = xfilial ("ZZA")
				zza -> zza_safra  = sze -> ze_safra
				zza -> zza_carga  = sze -> ze_carga
				zza -> zza_produt = szf -> zf_item
				zza -> zza_nprod  = fBuscaCpo ("SB1", 1, xfilial ("SB1") + szf -> zf_produto, "B1_DESC")
				zza -> zza_nassoc = sze -> ze_nomasso

				if sze -> ze_status $ 'C/D'  // Carga [C]ancelada ou [D]irecionada para outra filial
					zza -> zza_status = 'C'
				elseif sze->ze_pesobru == 0
					zza -> zza_status = '0'
				elseif sze -> ze_pesotar > 0 .and. zza -> zza_status != '3' .and. val (szf -> zf_grau) > 0  // Jah fez a segunda pesagem, sem finalizar no BL01.
					u_log2 ('aviso', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Alterando ZZA_STATUS para M por que jah estah sendo feita a segunda pesagem, mesmo sem finalizar no programa do grau.')
					zza -> zza_status = 'M'
				elseif sze -> ze_pesobru > 0 .and. sze -> ze_pesotar == 0
					if empty (zza -> zza_status) .or. zza -> zza_status == '0'
						zza -> zza_status = '1'
					else
					endif
				elseif sze -> ze_pesobru > 0 .and. sze -> ze_pesotar > 0 .and. zza -> zza_status == '3'  // Segunda pesagem OK
//					u_log2 ('info', '[' + procname () + '] Nao preciso mudar o ZZA_STATUS')
				else
					u_help ("Situacao nao prevista para gravacao do campo ZZA_STATUS. Revise programa.",, .t.)
				endif
				msunlock ()
				szf -> (dbskip ())
//				u_log2 ('info', '[' + procname () + '] ZZA_STATUS gravado: ' + zza -> zza_status)
			enddo
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return
