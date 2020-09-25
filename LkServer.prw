// Programa:   LkServer
// Autor:      Robert Koch
// Data:       10/05/2020
// Descricao:  Retorna o nome do linked server para que o Protheus consulte o banco de dados do sistema Mercanet.
//
// Historico de alteracoes:
// 22/06/2020 - Robert - Renomeado de LkSrvMer para LkServer e torna-se generico (recebe servidor destino por parametro)
//

// --------------------------------------------------------------------------
user function LkServer (_sQualSrv)
	local _sRetLk := ''
	local _lBaseTST := .F.
	
	// Define se deve apontar para o banco de producao ou de homologacao.
	if "TESTE" $ upper (GetEnvServer())
		_lBaseTST = .T.
	endif

	do case
	case upper (alltrim (_sQualSrv)) == 'MERCANET'
		if _lBaseTST
			_sRetLk = "LKSRV_MERCANETHML.MercanetHML.dbo"
		else
			_sRetLk = "LKSRV_MERCANETPRD.MercanetPRD.dbo"
		endif
	case upper (alltrim (_sQualSrv)) == 'NAWEB'
		if _lBaseTST
			_sRetLk = "LKSRV_NAWEB_TESTE.naweb_teste.dbo"
		else
			_sRetLk = "LKSRV_NAWEB.naweb.dbo"
		endif
	otherwise
		u_help ("Sem definicao de 'linker server' para o banco de dados '" + _sQualSrv + "'",, .t.)
	endcase
return _sRetLk
