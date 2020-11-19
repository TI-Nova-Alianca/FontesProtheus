// Programa: mata050
// Autor:    Robert Koch
// Data:     09/12/2008
// Funcao:   P.E. generico no cadastro de transportadoras.
//           Criado inicialmente para enviar e-mail para a filial.
//
// Historico de alteracoes:
// 26/06/2009 - Robert - Desabilitado envio de e-mail para a filial ref. manutencoes feitas no cadastro.
// 11/11/2014 - Robert - Integracao dom FullWMS
//

// --------------------------------------------------------------------------
User Function mata050 ()
	//local _oFullW := NIL
	private _sArqLog := U_NomeLog ()
	u_logId ()

	if altera
		_oEvento := ClsEvent():new ()
		processa ({||_oEvento:AltCadast ("SA4", m->a4_cod, sa4 -> (recno ()))})
	endif
	
Return
