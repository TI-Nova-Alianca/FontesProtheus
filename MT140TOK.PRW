// Programa...: MT140TOk
// Autor......: Andre Alves
// Data.......: 08/10/2019
// Descricao..: P.E. 'Tudo OK' da tela de pr� notas de entrada.
//
// Historico de alteracoes:
// 08/10/2019 - Andre  - Adicionado valida��o para n�o permitir altera��o maior do que 5% no valor unitario do item.
// 04/01/2023 - Robert - Nao vou validar preco por que estou executando de dentro do painel XML (GLPI 12979)
//

// -----------------------------------------------------------------------------------------------------------------------
User Function MT140TOK()
	Local _lRet 	:= .T.
	Local _nLinha	:= 0

	if IsInCallStack ('U_FBTRS006')
		U_Log2 ('aviso', '[' + procname () + ']Nao vou validar preco por que estou executando de dentro do painel XML (GLPI 12979)')
	else
		For _nLinha := 1 to Len(aCols)
			// Valida se a Linha Nao estiver deletada
			If !GDDeleted( _nLinha ) .And. _lRet
				_xCOD     := GDFieldGet( "D1_COD"     , _nLinha )
				_xQUANT   := GDFieldGet( "D1_QUANT"   , _nLinha )
				_xTES     := GDFieldGet( "D1_TES"     , _nLinha )
				_xCF      := GDFieldGet( "D1_CF"      , _nLinha )
				if ! empty (GDFIELDGET('D1_PEDIDO',_nLinha))
					SC7->(DBSETORDER(1))
					if SC7->(DBSEEK(xfilial('SC7') + GDFIELDGET('D1_PEDIDO',_nLinha) + GDFIELDGET('D1_ITEMPC',_nLinha)))
						
						//Permite ajustar diferenca de valor unit�rio
						if ABS ((GDFIELDGET('D1_VUNIT',_nLinha) - SC7->C7_PRECO) * 100 / SC7->C7_PRECO) > 5
							u_help ("Altera��o de valor unitario acima do permitido")
							_lRet = .F.
						endif
					endif
				endif
			endif
		next
	endif

return _lRet
