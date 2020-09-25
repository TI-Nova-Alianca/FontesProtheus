// Programa...: M310CABEC
// Autor......: Andre Alves
// Data.......: 06/04/2020
// Descricao..: 
//              
//
// Historico de alteracoes:
// 06/04/2020 - Andre   - Criado par preencher Frete na tela de transferencia entre filiais.
//

// --------------------------------------------------------------------------------------
User Function M310CABEC

Local cProg  := PARAMIXB[1]
Local aCabec := PARAMIXB[2]
Local aPar   := PARAMIXB[3]
local _sTPFrete := ""
local _sTransp  := ""

	If cProg == 'MATA410' 
	    _sTPFrete = U_Get ("Informe o tipo de frete:", "C", 1, "", "", sc5 -> c5_tpfrete, .F., '.t.')
	   	aadd(aCabec,{'C5_TPFRETE',_sTPFrete,Nil})
	   	_sTransp = U_Get ("Informe a transportadora:", "C", 6, "", "SA4", sc5 -> c5_transp, .F., '.t.')
	   	aadd(aCabec,{'C5_TRANSP', _sTransp,Nil})
	endif

Return(aCabec)