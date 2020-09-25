// Programa: LJ140Exc
// Data:     01/02/2010
// Autor:    Robert Koch
// Funcao:   PE antes da exclusao do cupom fiscal no SigaLoja
//           Criado inicialmente apenas para gravar evento.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function LJ140EXC ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _oEvento   := NIL

	_oEvento := ClsEvent():new ()
	_oEvento:CodEven   = "SL1001"
	_oEvento:Texto     = "Excl. C.F. ref. NF/serie '" + sl1 -> l1_doc + "/" + sl1 -> l1_serie + "' - Valor: " + cvaltochar (sl1 -> l1_vlrtot)
	_oEvento:NFSaida   = sl1 -> l1_doc
	_oEvento:SerieSaid = sl1 -> l1_serie
	_oEvento:Cliente   = sl1 -> l1_cliente
	_oEvento:LojaCli   = sl1 -> l1_Loja
	_oEvento:Grava ()

	U_ML_SRArea (_aAreaAnt)
return
