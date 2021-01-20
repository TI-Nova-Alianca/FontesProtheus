// Programa:   LkServer
// Autor:      Robert Koch
// Data:       10/05/2020
// Descricao:  Retorna nome / caminho de outros databases e linked servers para que o Protheus possa acessa-los.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Funcao que retorna caminhos/nomes de bancos de dados de outros siatemas.
// #PalavasChave      #auxiliar #uso_generico
// #TabelasPrincipais 
// #Modulos           #todos_modulos

// Historico de alteracoes:
// 22/06/2020 - Robert - Renomeado de LkSrvMer para LkServer e torna-se generico (recebe servidor destino por parametro)
// 10/11/2020 - Robert - Criado tratamento para FullWMS (logistica).
// 09/12/2020 - Robert - Criado tratamento para o BI_ALIANCA.
// 16/12/2020 - Robert - Criado tratamento para o Metadados.
// 20/01/2021 - Robert - Tratamento para ambiente TesteMedio no acesso ao BI_ALIANCA (criado database temporario em separado)
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

	case upper (alltrim (_sQualSrv)) == 'FULLWMS_AX01'
		if _lBaseTST
			_sRetLk = ""  // Nao existe ainda (precisa instalar bastante coisa; ver GLPI 5701
		else
			_sRetLk = "LKSRV_FULLWMS_LOGISTICA"  // Deve ser usado com OpenQuery por se tratar de banco Oracle.
		endif

	// Nao usa linked server por que nao permite executar funcoes como consulta ao DRE industrial remotamente. (ainda nao descobri se tem como fazer)
	case upper (alltrim (_sQualSrv)) == 'BI_ALIANCA'
		if _lBaseTST
		//	_sRetLk = "BI_ALIANCA_teste.dbo"
			if upper (alltrim (getenvserver ())) == 'TESTEMEDIO'
				_sRetLk = "BI_ALIANCA_testeMedio.dbo"
			else
				_sRetLk = "BI_ALIANCA_teste.dbo"
			endif
		else
			_sRetLk = "BI_ALIANCA.dbo"
		endif

	case upper (alltrim (_sQualSrv)) == 'METADADOS'
		if _lBaseTST
			u_help ("Sem definicao de linked server do Metadados para ambiente de testes.",, .t.)
			_sRetLk = ""
		else
			_sRetLk = "LKSRV_SIRH.SIRH.dbo"
		endif

	otherwise
		u_help ("Sem definicao de LINKED SERVER para o sistema/banco de dados '" + _sQualSrv + "'",, .t.)
	endcase
return _sRetLk
