// Programa...: MT103FIN
// Autor......: Catia Cardoso
// Data.......: 08/02/2016
// Descricao..: P.E. para validar pasta duplicatas na entrada da nota fiscal.
//
// Historico de alteracoes:
// 02/10/2019 - Andre  - Adicionado valida��o para datas e valores das notas de entrada que possuem pedidos.
// 04/10/2019 - Andre  - Permitido alterar datas das parcelas em 2 dias para mais ou menos.
//
// --------------------------------------------------------------------------
User Function MT103FIN()
	local _aAreaAnt := U_ML_SRArea ()
	Local _aDupCols := PARAMIXB[2]
	local _lretOK   := .T.
	local _werro    := 0
	local _TemPed   := .F.
	local _wx		:= 0
	local _nLinha	:= 0
	
	For _wx := 1 to Len(_aDupCols)
		
		_wValor := _aDupCols[_wx][3]
		if _wValor > 0
			_wVenc := _aDupCols[_wx][2]
			If _wVenc < date()+1
        		_werro := 1
        	EndIf
		Endif        	
   	Next
   	
   	if _werro = 1 
   		u_help ("Data de Vencimento Inv�lida. Vencimento deve ser no minimo data atual + 1")
		_lretOK      := .F.
	endif
	
	For _nLinha := 1 to Len(aCols)
		If !GDDeleted( _nLinha )
			if ! empty (GDFIELDGET('D1_PEDIDO',_nLinha))
				_TemPed = .T.
			endif
		endif
	next						
	if _TemPed = .T.
	   _wValor := 0
		
	   For _wx := 1 to Len(_aDupCols)
	   	   _wValor += _aDupCols[_wx][3]
	   Next
		
	   _aVctos = aclone (Condicao (_wValor, ccondicao,, ddemissao ))
				
	   if  ! Len(_aDupCols) = Len(_aVctos)
	   		u_help('Quantidade de parcelas diferente da condi��o de pagamento')
		 	_lretOK := .F.
	   else
	   u_log(_aDupCols)
	   u_log(_aVctos)
	   		For _wx := 1 to Len(_aDupCols)
	   			//if ! _aDupCols[_wx][2] = _aVctos[_wx][1]
				if _aDupCols[_wx][2] < Daysub(_aVctos[_wx][1],3) .or. _aDupCols[_wx][2] > Daysum(_aVctos[_wx][1],3)  
				 	u_help('N�o se deve alterar datas de vencimento com varia��o maior do que 3 dias para notas com pedido.')
				 	_lretOK := .F.
				 	EXIT
				endif
				//if ABS ((GDFIELDGET('D1_VUNIT',_nLinha) - SC7->C7_PRECO) * 100 / SC7->C7_PRECO) > 5
				//if ! _aDupCols[_wx][3] = _aVctos[_wx][2]
				//if ABS ((_aDupCols[_wx][3] - _aVctos[_wx][2]) * 100 / _aVctos[_wx][2]) > 5 
				// 	u_help('Altera��o dos valores das parcelas para notas com pedido n�o deve ser maior que 5%.')
				// 	_lretOK := .F.
				// 	EXIT
				//endif
			Next
		endif
	endif
	U_ML_SRArea (_aAreaAnt)
	
Return _lretOK