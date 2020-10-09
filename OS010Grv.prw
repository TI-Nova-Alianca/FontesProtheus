// Programa:  OS010Grv
// Autor:     Robert Koch
// Descricao: P.E. apos a gravacao da tabela de precos.
//            Criado inicialmente para exportar dados para Mercanet.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #Ponto de entrada apos gravacao da tabela de precos.
// #PalavasChave      #tabela_de_precos_de_venda
// #TabelasPrincipais #DA0 #DA1
// #Modulos           #FAT

// Historico de alteracoes:
// 24/08/2017 - Robert - Posiciona a tabela DA0 antes de chamar a atualizacao do Mercanet.
// 09/10/2020 - Robert - Melhorados logs
//                     - Inseridas tags para catalogo de fontes.
//

// --------------------------------------------------------------------------
user function OS010Grv ()
	local _aAreaAnt := U_ML_SRArea ()

//	u_log2 ('debug', 'Iniciando ' + procname ())
//	u_log2 ('debug', paramixb)
	if paramixb [1] == 1  // Usuario confirmou
//		u_log2 ('debug', 'usuario confirmou a tela')
		if paramixb [2] == 3 .or. paramixb [2] == 4  // Inclusao ou alteracao
			da0 -> (dbsetorder (1))
			if da0 -> (dbseek (xfilial ("DA0") + m->da0_codtab, .F.))  // O alias DA0 nao chega aqui posicionado.
//				u_log2 ('debug', 'encontrou DA0')
				U_AtuMerc ('DA0', da0 -> (recno ()))
			else
				u_log2 ('aviso', 'Nao encontrei codigo ' + m->da0_codtab + ' na tabela DA0 para enviar atualizacao ao Mercanet.')
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return
