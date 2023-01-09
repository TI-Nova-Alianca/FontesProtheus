// Programa...: VA_RusDI
// Autor......: Robert Koch
// Data.......: 31/01/2022
// Descricao..: Define porta da impressora de ticket de cargas de safra
//              Foi criado um programa separado para possibilitar a chamada de mais de um local.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Define porta de impressora de ticket para safra
// #PalavasChave      #porta #impressora #ticket #safra
// #TabelasPrincipais #
// #Modulos           #COOP

// Historico de alteracoes:
// 06/01/2023 - Robert - Passa a ler impressora no parametro VA_ITKSAFR.
//

// --------------------------------------------------------------------------
User Function VA_RUSDI (_sFilial, _sIdFixo)
	U_Log2 ('debug', 'filial: ' + _sFilial)

	if ! empty (_sIdFixo)
		U_Log2 ('aviso', '[' + procname () + ']Recebi um ID fixo para impressora: ' + _sIdFixo)
		_sIdImpr = _sIdFixo
	else
		_sIdImpr = SuperGetMV ("VA_ITKSAFR", .F., '')
	endif

	if ! empty (_sIdImpr)
		_sPortTick = U_RetZX5 ('49', _sIdImpr, 'ZX5_49CAM')
	endif
	u_log2 ('debug', '_sIdImpr:' + _sIdImpr)
	u_log2 ('debug', '_sPortTick:' + _sPortTick)
	if ! empty (_sPortTick)
		_lImpTick = .T.
	endif

	// Se for base teste, evita enviar para a impressora padrao para nao causar confusao com a safra normal.
	if U_AmbTeste()
		_sPortTick := '\\192.168.1.3\siga\ticket.txt'
		U_help ('aviso', "Ambiente de TESTE. Vou redirecionar o ticket para o arquivo " + _sPortTick)
	endif

return
