// Programa:   MA260D3
// Autor:      Bruno Silva (DWT)
// Data:       25/07/2014
// Descricao:  P.E. apos a gravacao da tranferencia de produtos via ACD (telnet)
//             Criado inicialmente para bloquear lote destino.
//
// Historico de alteracoes:
// 22/08/2014 - Robert - Passa a chamar funcao U_BlqLot para compatibilizar com MA261D3
//

// --------------------------------------------------------------------------
User Function ACD150Gr()
	local _aAreaAnt := U_ML_SRArea ()
	U_LogIni ()
	
	// Bloqueia o lote no endereco destino
	U_BlqLot ('V')
	
	U_ML_SRArea (_aAreaAnt)
	U_LogFim ()
return
