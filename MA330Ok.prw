// Programa:  MA330Ok
// Autor:     Robert Koch
// Descricao: P.E. de 'tudo ok' para iniciar o recalculo do custo medio.
//            Criado inicialmente para gravar evento.
//
// Historico de alteracoes:
// 10/10/2017 - Robert  - Migradas para ca as validacoes do CUSMED.prw
// 30/10/2019 - Cláudia - Ajustada rotina alterando verificações do programa VerCMed para ClsVerif. GLPI:6912
// 17/06/2020 - Robert  - Nome do semaforo fixado como 'CustoMedio' para compatibilidade com o programa BatCust.prw
//                      - Semaforo passa a ser unico (nao mais por empresa/filial) pois estamos rodando custo médio consolidado.
// 07/07/2020 - Robert  - Grava evento de inicio de processamento.
// 13/07/2020 - Robert  - Melhorado texto do evento de inicio de processamento.
//                      - Inseridas tags para catalogacao de fontes
// 27/07/2020 - Robert  - Verificacao de acesso: passa a validar acesso 115 e nao mais 069.
// 26/11/2022 - Robert  - Melhoria msg verificacao de pendencias.
// 03/11/2023 - Robert  - Na leitura do retorno da 'verif.alianca 04' entendia a primeira linha como um erro.
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada #validacao
// #PalavasChave      #custo_medio #evento
// #TabelasPrincipais #SD1 #SD2 #SD3 #SB2
// #Modulos           #EST

// --------------------------------------------------------------------------
user function MA330OK ()
	local _aAreaAnt := U_ML_SRArea ()
	local _lRet     := .T.
	local _oEvento  := NIL
	local _oVerif   := NIL
	local _oAvisos  := NIL
	local _aPartes  := {}
	local _nParte   := 0
	public _nLock   := 0  // Deixar public para ser visto pelo P.E. MA330FIM

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if _lRet
		_lRet = U_ZZUVL ('115', __cUserID, .T.)
	endif

	// Somente uma estacao por vez, inclusive por causa dos batches agendados.
	if _lRet
		_nLock := U_Semaforo ('CustoMedio', .T.)
		if _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina nesta empresa / filial.")
			_lRet = .F.
		endif
	endif

	// Faz algumas verificacoes previas.
	if _lRet .and. FunName () == "MATA330"
		_oVerif := ClsVerif():New (4)
		_oVerif:SetParam ('01', date ())
		_oVerif:SetParam ('02', date ())

		// Nao quero que mostre mensagens durante a execucao da verificacao.
		// Se tiver alguma mensagem, vou mostrar por aqui.
		_oVerif:ComTela = .F.

		_oVerif:Executa ()
		_oAvisos := ClsAUtil ():New (_oVerif:Result)
		U_Log2 ('debug', '[' + procname () + ']_oAvisos:')
		U_Log2 ('debug', _oAvisos:_aArray)
//		if len (_oAvisos:_aArray) > 0
		if len (_oAvisos:_aArray) > 1  // A primeira linha contem os titulos das colunas
			if type ("_oBatch") == 'O'
				_oBatch:Mensagens += 'Erros ou avisos impedem a execucao do calculo'
			endif
			u_F3Array (_oAvisos:_aArray)
			_lRet = .F.
		endif
	endif

	// Monta evento com os parametros utilizados.
	if _lRet
		_oEvento := ClsEvent():new ()
		_oEvento:Texto := "Iniciando recalculo custo medio" + chr (13) + chr (10)
		_oEvento:Texto += "Ambiente: " + GetEnvServer () + chr (13) + chr (10)
		if existblock ("MA330CP")
			_aPartes = U_MA330CP ()
			_oEvento:Texto += "Partes retornadas pelo MA330CP:" + chr (13) + chr (10)
			for _nParte = 1 to len (_aPartes)
				_oEvento:Texto += _aPartes [_nParte] + chr (13) + chr (10) //iif (_nParte < len (_aPartes), ' / ', '')
			next
		endif
		_oEvento:LeParam ('MTA330')
		_oEvento:CodEven = 'SD3003'
		_oEvento:Grava ()
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet

