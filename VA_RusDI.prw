// Programa...: VA_RusDI
// Autor......: Robert Koch
// Data.......: 31/01/2022
// Descricao..: Define porta da impressora de ticket de cargas de safra
//              Foi criado um programa separado para possibilitar a chamada de mais de um local.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function VA_RUSDI (_sFilial)
	U_Log2 ('debug', 'filial: ' + _sFilial)
	// As variaveis tratadas aqui jah devem ter escopo PRIVATE no programa chamador.
	do case
	case _sFilial == '01'
		_sIdImpr = '11'
		_sPortTick = U_RetZX5 ('49', _sIdImpr, 'ZX5_49CAM')
	case _sFilial == '07'
		_sIdImpr = '08'
		_sPortTick = U_RetZX5 ('49', _sIdImpr, 'ZX5_49CAM')
	otherwise
		_sIdImpr = ''
		_sPortTick = ''
		u_log2 ('aviso', "Impressora de ticket nao definida para a filial '" + cFilAnt + "'. Nao vou solicitar impressao.")
	endcase
	u_log2 ('debug', '_sIdImpr:' + _sIdImpr)
	u_log2 ('debug', '_sPortTick:' + _sPortTick)
	if ! empty (_sPortTick)
		_lImpTick = .T.
	endif

	
	
	// durante TESTES. apagar depois!
//	_sPortTick := '\\192.168.1.3\siga\ticket.txt'



return
