// Programa...: _Mta460B
// Autor......: Robert Koch
// Data.......: 29/03/2014
// Descricao..: Para ser chamado no menu em lugar do MATA460B (faturamento por cargas OMS).
//
// Historico de alteracoes:
// 23/07/2014 - Robert - Monitor do SPED substituido por rotina customizada.
// 12/02/2015 - Robert - Matodo ConsChv() trocado por ConsAutori() na consulta de autorizacao do SPED.
// 30/04/2015 - Robert - Funcao _SPED passada para U_SpedAut ()
// 09/03/2017 - Robert - Passa a controlar semaforo concorrente com o U__MATA460().
// 22/08/2019 - Robert - Chama envio de XML mesmo em ambiente de teste (jah tem verificacao no U_SPEDAut)
// 25/02/2020 - Robert - Passa a trabalhar com a array _aNComSono para saber quais as notas geradas. Antes apenas usava apenas uma
//                       faixa de numeracao, com a possibilidade de ter notas inutilizadas ou de entrada (formulário próprio) no meio.
// 31/07/2020 - Robert - Melhorados avisos e logs.
//                     - Inseridas tags para catalogacao de fontes
// 20/10/2021 - Robert  - Variavel _sSerie passa a ser lida na array _aNComSono (GLPI 11112)
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao
// #Descricao         #Mascaramento da tela de faturamento de cargas.
// #PalavasChave      #faturamento #MATA460 #preparacao_documento_saida #carga #logistica #OMS #expedicao
// #TabelasPrincipais #SF2 #DAK #DAI
// #Modulos           #FAT #OMS

#include "rwmake.ch"

// --------------------------------------------------------------------------
user function _Mta460B ()
	//local _sQuery    := ""
	local _sNFIni    := ""
	local _sNFFim    := ""
	local _sSerie    := ''  //"10 "
	local _lContinua := .T.
	local _nLock     := 0
	local _nNComSono := 0
	private _aNComSono := {}  // Deixar como private para ser vista por outros P.E. (lista de notas a ser transmitida para a SEFAZ)

	if _lContinua
		_nLock := U_Semaforo ('faturamento' + cEmpAnt + xfilial ("SC9"))
		if _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina nesta empresa/filial.")
			_lContinua = .F.
			
			// Para os tristes e vergonhosos casos de travamento de servico...
			if alltrim (upper (cUserName)) == "ROBERT.KOCH" .and. msgnoyes ("Devo ignorar o semaforo?","Ignorar")
				_lContinua = .T.
			endif
		endif
	endif

	if _lContinua
			
		// Tela padrao de preparacao de doctos.
		u_log ('Chamando MATA460B')
		MATA460B ()
		u_log ('Retornou do MATA460B')

		// Libera semaforo
		U_Semaforo (_nLock)

		// Se foram geradas notas, chama rotina de transmissao para o SEFAZ.
		u_log ('notas geradas:', _aNComSono)
		if len (_aNComSono) > 0 .and. U_MsgYesNo ("Voce gerou " + cvaltochar (len (_aNComSono)) + ' notas. Deseja transmiti-las para a SEFAZ agora?')

			// Antes de enviar uma faixa para a SEFAZ, verifica se teve lacuna na numeracao.
			// Reordena para ter certeza
			_aNComSono = asort (_aNComSono,,, {|_x, _y| _x [1] < _y [1]})

			// Varre a lista de notas e marca a posicao 2 com .T. naquelas cuja proxima nota nao for sequencia.
			for _nNComSono = 1 to len (_aNComSono)
				if _nNComSono < len (_aNComSono)
					if val (_aNComSono [_nNComSono + 1, 1]) > val (_aNComSono [_nNComSono, 1]) + 1
						_aNComSono [_nNComSono, 2] = .t.
					endif
				endif
			next
			u_log (_aNComSono)

			// Chama telas de transmissao e de impressao de boletos a cada quebra de sequencia.
			if ascan (_aNComSono, {|_aVal| _aVal [2] == .T.}) > 0
				u_help ("Foram geradas notas com quebra de sequencia. Por esse motivo, vai ser feita mais de uma transmissao para a SEFAZ.")
			endif
			_nNComSono = 1
			do while .t.  //_nNComSono <= len (_aNComSono)
				_sNFIni = _aNComSono [_nNComSono, 1]
				_sNFFim = _aNComSono [_nNComSono, 1]
				_sSerie = _aNComSono [_nNComSono, 3]
				do while .t. //_nNComSono <= len (_aNComSono)
					_sNFFim = _aNComSono [_nNComSono, 1]
					_sSerie = _aNComSono [_nNComSono, 3]
					if _aNComSono [_nNComSono, 2] == .T.  // A proxima nota vai ter lacuna na numeracao.
						u_log ('Processar:', _sNFIni, _sNFFim)
						U_SPEDAut ('S', _sSerie, _sNFIni, _sNFFim)
						U_BolAuto (_sSerie, _sNFIni, _sNFFim)
						_sNFIni = _aNComSono [_nNComSono + 1, 1]
					endif
					_nNComSono ++
					if _nNComSono > len (_aNComSono)
						exit
					endif
				enddo
				if _nNComSono > len (_aNComSono)
					exit
				endif
			enddo
			u_log ('Processar:', _sNFIni, _sNFFim)
			U_SPEDAut ('S', _sSerie, _sNFIni, _sNFFim)
			U_BolAuto (_sSerie, _sNFIni, _sNFFim)
		endif
	endif
	u_logFim ()
return
