// Programa:  VAVLRATF
// Autor:     Sandra Sugari/Robert Koch 
// Data:      04/11/2019
// Descricao: Execblock para substituir o parametro MV_VLRATF por falta de espaço na formula.
//
// Historico de alteracoes:
// 22/11/2019 - Sandra - Inclusão validação SF1->F1_VALIMP5, SF1->F1_VALIMP6
//

// --------------------------------------------------------------------------------------------------------------------------------

User Function VAVLRATF ()
	LOCAL _NRET:=0
    _NRET+=(SD1->D1_TOTAL-SD1->D1_VALDESC+SD1->D1_DESPESA+SD1->D1_VALFRE+SD1->D1_SEGURO)
	_NRET+=If(SF4->F4_CREDIPI=="S",0,SD1->D1_VALIPI)
	_NRET-=IIf(SF4->F4_CREDICM=="S",SD1->D1_VALICM,0)
	_NRET-=IIf(SF4->F4_CREDICM=="S",SD1->D1_ICMSCOM,0)
	_NRET-=IIf(SF4->F4_PISCRED='1',SF1->F1_VALIMP5,0)
	_NRET-=IIf(SF4->F4_PISCRED='1',SF1->F1_VALIMP6,0)
return _NRET	    	    
