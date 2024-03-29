// Programa:   LkServer
// Autor:      Robert Koch
// Data:       10/05/2020
// Descricao:  Retorna nome / caminho de outros databases e linked servers para que o Protheus possa acessa-los.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Funcao que retorna caminhos/nomes de bancos de dados de outros sistemas.
// #PalavasChave      #auxiliar #uso_generico
// #TabelasPrincipais 
// #Modulos           #todos_modulos

// Historico de alteracoes:
// 22/06/2020 - Robert - Renomeado de LkSrvMer para LkServer e torna-se generico (recebe servidor destino por parametro)
// 10/11/2020 - Robert - Criado tratamento para FullWMS (logistica).
// 09/12/2020 - Robert - Criado tratamento para o BI_ALIANCA.
// 16/12/2020 - Robert - Criado tratamento para o Metadados.
// 20/01/2021 - Robert - Tratamento para ambiente TesteMedio no acesso ao BI_ALIANCA (criado database temporario em separado)
// 08/02/2021 - Robert - Criado tratamento para acessar o database TI (GLPI 9353)
// 23/02/2021 - Robert - Adicionado database BL01 (GLPI 9454).
// 25/03/2022 - Robert - Adicionado ambiente R33 (homologacao release33 do Protheus)
// 11/10/2020 - Robert - Criado linked server FullWMS TESTE (almox.01 logistica).
// 08/11/2022 - Robert - Passa a usar a funcao U_AmbTeste().
// 03/05/2023 - Robert - Ajustado BI_ALIANCA base teste.
//

// --------------------------------------------------------------------------
user function LkServer (_sQualSrv)
	local _sRetLk := ''
	local _lBaseTST := .F.
	
	// Define se deve apontar para o banco de producao ou de homologacao.
	if U_AmbTeste ()
		U_Log2 ('debug', '[' + procname () + ']Estou definindo linked server para base teste')
		_lBaseTST = .T.
		//u_logpcham ()
	endif

	do case

	// Nao usa linked server por que nao permite executar funcoes como consulta ao DRE industrial remotamente. (ainda nao descobri se tem como fazer)
	case upper (alltrim (_sQualSrv)) == 'BI_ALIANCA'
		if _lBaseTST
		//	_sRetLk = "BI_ALIANCA_teste.dbo"
//			if upper (alltrim (getenvserver ())) == 'TESTEMEDIO'
				_sRetLk = "BI_ALIANCA_testeMedio.dbo"
//			else
//				_sRetLk = "BI_ALIANCA_teste.dbo"
//			endif
		else
			_sRetLk = "BI_ALIANCA.dbo"
		endif

	// Nao usa linked server por que nao permite executar funcoes como FMEDICAO_CONTINUA_CARGA_SAFRA remotamente. (ainda nao descobri se tem como fazer)
	case upper (alltrim (_sQualSrv)) == 'BL01'
		if _lBaseTST
			_sRetLk = ""
		else
			_sRetLk = "BL01.dbo"
		endif

	case upper (alltrim (_sQualSrv)) == 'FULLWMS_AX01'
		if _lBaseTST
			_sRetLk = "LKSRV_FULLWMS_LOGISTICATESTE"  // Deve ser usado com OpenQuery por se tratar de banco Oracle. Configurado cfe. GLPI 5701
		else
			_sRetLk = "LKSRV_FULLWMS_LOGISTICA"  // Deve ser usado com OpenQuery por se tratar de banco Oracle. Configurado cfe. GLPI 5701
		endif
		// pode ser ser testado assim, para ver se diferencia da base quente:
		// SELECT RETORNO FROM openquery (LKSRV_FULLWMS_LOGISTICA,      'select max(dt_mov) as RETORNO from wms_mov_estoques_cd')
		// SELECT RETORNO FROM openquery (LKSRV_FULLWMS_LOGISTICATESTE, 'select max(dt_mov) as RETORNO from wms_mov_estoques_cd')

	case upper (alltrim (_sQualSrv)) == 'MERCANET'
		if _lBaseTST
			_sRetLk = "LKSRV_MERCANETHML.MercanetHML.dbo"
		else
			_sRetLk = "LKSRV_MERCANETPRD.MercanetPRD.dbo"
		endif

	case upper (alltrim (_sQualSrv)) == 'METADADOS'
		if _lBaseTST
//			if type ("_lGLPI9047") == 'L' .and. _lGLPI9047  // Preciso acessar enquando implemento este chamado
//				_sRetLk = "LKSRV_SIRH.SIRH.dbo"
//			else
				u_help ("Sem definicao de linked server do Metadados para ambiente de testes.",, .t.)
				_sRetLk = ""
//			endif
		else
			_sRetLk = "LKSRV_SIRH.SIRH.dbo"
		endif

	case upper (alltrim (_sQualSrv)) == 'NAWEB'
		if _lBaseTST
			_sRetLk = "LKSRV_NAWEB_TESTE.naweb_teste.dbo"
		else
			_sRetLk = "LKSRV_NAWEB.naweb.dbo"
		endif

	case upper (alltrim (_sQualSrv)) == 'TI'
		if _lBaseTST
			U_Log2 ('aviso', '[' + procname () + ']Usando o mesmo linked server da producao para database TI, pois nao tenho nada do tipo TI_TESTE')
			_sRetLk = "LKSRV_TI.TI.dbo"
		else
			_sRetLk = "LKSRV_TI.TI.dbo"
		endif

	otherwise
		u_help ("Sem definicao de LINKED SERVER para o sistema/banco de dados '" + _sQualSrv + "'",, .t.)
	endcase
return _sRetLk
