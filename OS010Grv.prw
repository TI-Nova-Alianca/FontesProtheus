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
// 20/12/2023 - Claudia - Programa passa enviar e-mail por batch. GLPI: 14643
//
// --------------------------------------------------------------------------
user function OS010Grv ()
	local _aAreaAnt := U_ML_SRArea ()

	if paramixb [1] == 1  // Usuario confirmou
		if paramixb [2] == 3 .or. paramixb [2] == 4  // Inclusao ou alteracao
			da0 -> (dbsetorder (1))
			if da0 -> (dbseek (xfilial ("DA0") + m->da0_codtab, .F.))  // O alias DA0 nao chega aqui posicionado.
				U_AtuMerc ('DA0', da0 -> (recno ()))
			else
				u_log2 ('aviso', 'Nao encontrei codigo ' + m->da0_codtab + ' na tabela DA0 para enviar atualizacao ao Mercanet.')
			endif

			// if paramixb [2] == 4 // envia e-mail de alteração
			// 	U_VA_DA0MAIL()
			// endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return
