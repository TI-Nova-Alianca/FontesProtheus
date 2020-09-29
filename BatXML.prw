// Programa:   BatXML
// Autor:      Robert Koch
// Data:       01/08/2012
// Descricao:  Rotinas automatica ref. XML de notas de entrada.
//             Criado para ser executado via batch.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Batch
// #Descricao         #Importacao de arquivos XML de NFe, CTe, NFSe, ...
// #PalavasChave      #XML #NF-e #NFe #CT-e #CTe #importacao
// #TabelasPrincipais #ZZX
// #Modulos           #EST #COM

// Historico de alteracoes:
// 01/09/2012 - Robert - Passa a verificar chaves na SEFAZ.
// 21/02/2015 - Catia  - Revalidação passou para o REVALXML
// 23/09/2015 - Robert - Criada regua de processamento.
// 04/11/2019 - Robert - Nao chama mais a rotina de recepcao de e-mail (migrada para 'batch' separado).
// 28/09/2020 - Robert - Inseridas tags para catalogo de fontes
//                     - Melhorados alguns logs.
//

// --------------------------------------------------------------------------
user function BatXML (_sPath, _nMaxArq)
	local _nArq      := 0
	local _aDir      := {}
	local _nQtArq    := 0

	U_log2 ('info', '[' + procname () + '] Iniciando execucao.')

	procregua (10)

	// Importa arquivos que estiverem na pasta de importacao.
	_aDir = directory (_sPath + '*.xml')
	u_log2 ('info', cvaltochar (len (_aDir)) + ' arquivos para importar na pasta ' + _sPath)

	_nMaxArq := iif (_nMaxArq == NIL, 50, _nMaxArq)

	procregua (min (_nMaxArq, len (_aDir)))
	for _nArq = 1 to min (_nMaxArq, len (_aDir))  // Por enquanto, somente alguns arquivos por vez.
		incproc (_aDir [_nArq, 1])
		if _aDir [_nArq, 2] < 500000  // Limite de tamanho cfe. layout da SEFAZ
			u_log2 ('info', "Verificando arquivo " + _aDir [_nArq, 1])

			// Chama a mesma rotina de importacao manual da tela de manutencao de XML.
			if U_ZZXI (_sPath + _aDir [_nArq, 1])
				_nQtArq ++
			endif
		else
			U_AvisaTI ("Arquivo muito grande na pasta de importacao de XML: " + _aDir [_nArq, 1])
		endif
	next

	_oBatch:Mensagens = cvaltochar (_nQtArq) + " arq.importados. " + _oBatch:Mensagens

	U_log2 ('info', '[' + procname () + '] Finalizando execucao.')
return .t.
