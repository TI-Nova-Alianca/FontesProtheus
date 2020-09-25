// Programa:   BatEXML
// Autor:      Catia Cardoso
// Data:       03/12/2018
// Descricao:  Exporta XML de notas de saida
//
// Historico de alteracoes:
// 06/08/2020 - Robert - Inseridos alguns logs
//                     - Criadas tags para catalogar fontes.
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Batch
// #Descricao         #Chama rotina de exportacao de XML de notas de saida para arquivo
// #PalavasChave      #XML #exporta_arquivo
// #TabelasPrincipais #SF2 #SPED050
// #Modulos           #FAT #FIS

// --------------------------------------------------------------------------
user function BatEXML (_sDestino, _sTipo)
	local _lRet      := .T.

	u_log2 ('info', 'Iniciando processamento')
	u_log2 ('info', 'Destino: ' + cvaltochar (_sDestino))
	u_log2 ('info', 'Tipo...: ' + cvaltochar (_sTipo))
	
	procregua (10)

	// _stipo = 1 = Notas de transferencias
	// _stipo = 2 = Notas com transportadora ou redespacho (E_Sales)
	// _stipo = 3 = Notas com titulos para o RED ASET
	
	// Exporta atquivos
	U_VA_EXPXML(_sDestino, _sTipo )
	
return _lRet
