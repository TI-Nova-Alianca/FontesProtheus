// Programa:  MT080GRV
// Autor:     Robert Koch
// Data:      21/08/2013
// Descricao: P.E. apos confirmação no cadastro de TES (ainda dentro da transacao).
//
// Historico de alteracoes:
// 21/08/2013 - Leandro DWT - Envia e-mail para Sara quando um TES é incluído
// 10/11/2016 - Robert  - Desabilitado envio de e-mail pois a conta nem existia mais,
//                      - Envia dados para atualizacao do Mercanet.
//

// --------------------------------------------------------------------------
user function MT080GRV ()
	local _aAreaAnt := U_ML_SRArea ()
	//local _oEvento := NIL

	U_AtuMerc ('SF4', sf4 -> (recno ()))

	U_ML_SRArea (_aAreaAnt)
Return
