// Programa:  IniSafra
// Autor:     Robert Koch
// Data:      12/12/2017
// Descricao: Inicializador para definir qual a safra ativa para a data atual. Criado com base no IniSZ9S() de Jeferson Rech (2004).
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function IniSafra (_dData)
	Local _xSAFRA   := "2000"
	Local _nMES     := Month(iif (_dData == NIL, Date(), _dData))
	
	If _nMES >=1 .And. _nMES <= 8
		_xSAFRA := StrZero(Year(Date()),4,0)
	ElseIf _nMES >=9 .And. _nMES <= 12
		_xSAFRA := StrZero(Year(Date()),4,0)
		_xSAFRA := Soma1(_xSAFRA)
	EndIf
Return _xSAFRA
