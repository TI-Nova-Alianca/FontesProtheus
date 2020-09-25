// Programa...: VALPALREL
// Autor......: Júlio Pedroni
// Data.......: 04/05/2017
// Descricao..: Validações de parâmetros de relatórios.
//
// Historico de alteracoes:
//

// ----------------------------------------------------------------
User Function VALPARREL(_sCampo1, _sCampo2, _sStr, _sTipo, _lObriga)
	Local _lContinua := .T.
	
	If _lContinua = .T. .and. _lObriga .and. Empty(AllTrim(_sCampo2)) 
		U_Help("O campo '" + AllTrim(_sStr) + "' deve ser preenchido.")
		_lContinua = .F.
	EndIf
	
	If _lContinua
		Do Case
			Case _sTipo == 'MES'
				If Val(_sCampo1) < 1 .or. Val(_sCampo1) > 12
					U_Help("O campo '" + AllTrim(_sStr) + "' deve ser preenchido entre 01 e 12.")
					_lContinua = .F.
				EndIf
			Case _sTipo == 'ANO'
				If Len(AllTrim(_sCampo1)) <> 4 .or. Val(AllTrim(_sCampo1)) < 1900 
					U_Help("O campo '" + AllTrim(_sStr) + "' deve possuir 4 digitos.")
					_lContinua = .F.
				EndIf
			Case _sTipo == 'INTERVALO'
				If AllTrim(_sCampo1) > AllTrim(_sCampo2)
					U_Help(_sStr + " inicial nao pode ser maior que final.")
					_lContinua = .F.
				EndIf
		EndCase
	EndIf
	
return _lContinua