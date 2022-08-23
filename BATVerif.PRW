// Programa:   BatVerif
// Autor:      Robert Koch
// Data:       01/11/2016
// Descricao:  Batch de verificacoes gerais e envio por e-mail.
//             Criado para ser executado via batch.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Consulta
// #Descricao         #Execucao de verificacoes e envio de avisos
// #PalavasChave      #verificacoes #validacoes #avisos
// #TabelasPrincipais 
// #Modulos           #todos_modulos

// Historico de alteracoes:
// 18/06/2019 - Robert - Incluido tratamento para setor CML (comercial)
//                     - Removido tratamento de nome de arquivo de log (jah vem pronto da rotina que dispara os batches).
// 06/10/2020 - Robert - Criado tratamento para envio de avisos para a informatica
//                     - Melhorados logs
//                     - Inseridas tags para catalogo de fontes.
// 18/11/2020 - Robert - Maioria das validacoes estava desabilitada (para testes) desde 10/09/2020 e esqueci assim.
// 31/08/2021 - Robert - Melhorias controle de loop de execucao e monitor de performance (GLPI 10876).
// 23/08/2022 - Robert - Apenas alguns desvios condigionais para simulacoes (GLPI 12134)
//

// --------------------------------------------------------------------------
user function BatVerif ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _oVerif    := NIL
	local _nVerif    := 0
//	local _aRetVer   := {}
	local _sMsg      := ""
	local _sChvPerfM := ''

	u_log2 ('info', 'Iniciando execucao das verificacoes')

	// Executa cada verificacao e envia o resultado aos setores interessados.
	_nVerif = 1


	if "ROBERT" $ upper (GetEnvServer()) .and. dtos (date ()) == '20220823'  // Simulacoes
		_nVerif = 42
	endif


	do while .T.
		U_Log2 ('info', 'Vou ver se devo executar a verificacao ' + cvaltochar (_nVerif))
		_oVerif := ClsVerif ():New (_nVerif)
		if _nVerif > _oVerif:UltVerif  // Jah passei por todas.
			U_Log2 ('info', 'Cheguei ao final da lista')
			exit
		else
			if _oVerif:Ativa .and. _oVerif:ViaBatch
				u_log2 ('info', 'Verificacao ' + cvaltochar (_oVerif:Numero) + ' (' + _oVerif:Descricao + ') --> ' + _oVerif:Query)
				
				if _nVerif != 42 .and. "ROBERT" $ upper (GetEnvServer()) .and. dtos (date ()) == '20220823'  // Simulacoes
					U_Log2 ('aviso', '[' + procname () + ']caindo fora do loop (testes)')
					exit
				endif

				// Acompanhamento de performance de execucao de rotinas
				_sChvPerfM = 'BatVerif' + cvaltochar (_oVerif:Numero) + '_F' + cFilAnt
				U_PerfMon ('I', _sChvPerfM)

				if _oVerif:Executa ()
		
					// Vou persistir o tempo de execucao somente se a verificacao foi mesmo executada.
					U_PerfMon ('F', _sChvPerfM)

					if _oVerif:QtErros > 0

						// Prepara mensagem em formato HTM para envio por e-mail.
						_sMsg := _oVerif:ConvHTM (50)  // Converte poucas linhas para os e-mails nao ficarem pesados demais.

						// Envia aos setores interessados.
						if 'ENG' $ _oVerif:Setores
							_Envia (_oVerif, {'070'}, _sMsg)
						endif
						if 'CUS' $ _oVerif:Setores
							_Envia (_oVerif, {'069'}, _sMsg)
						endif
						if 'SAF' $ _oVerif:Setores
							_Envia (_oVerif, {'075'}, _sMsg)
						endif
						if 'FIS' $ _oVerif:Setores
							_Envia (_oVerif, {'019'}, _sMsg)
						endif
						if 'PCP' $ _oVerif:Setores
							_Envia (_oVerif, {'047'}, _sMsg)
						endif
						if 'CML' $ _oVerif:Setores
							_Envia (_oVerif, {'003'}, _sMsg)
						endif
						if 'INF' $ _oVerif:Setores
							_Envia (_oVerif, {'122'}, _sMsg)
						endif
					endif
				else
					U_help ("Problemas ao executar a verificacao '" + _oVerif:Descricao + ": " + _oVerif:UltMsg,, .T.)
				endif
			endif
		endif
		_nVerif ++
	enddo

	_oBatch:Retorno = 'S'
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_log2 ('info', 'Finalizando execucao das verificacoes')
return



// --------------------------------------------------------------------------
// Envia resultado da verificacao.
static function _Envia (_oVerif, _aGrupos, _sMsg)
	local _nGrupo  := 0
	local _aDest   := 0
	local _aIDs    := {}
	local _nID     := 0
	local _aEMails := {}
	local _nLiber  := 0

	if "ROBERT" $ upper (GetEnvServer()) .and. dtos (date ()) == '20220823'  // Simulacoes
		U_Log2 ('debug', 'Agora estaria enviando aviso para:')
		U_Log2 ('debug', _aGrupos)
		U_Log2 ('debug', _sMsg)
		return
	endif

	// Se a verificacao nao tem restricao de grupo, ja pode enviar para todos. 
	if empty (_oVerif:LiberZZU)
		U_ZZUNU (_aGrupos, "Verif.Protheus " + cvaltochar (_oVerif:Numero) + '-' + _oVerif:Descricao, _sMsg, .F.)
	else
	
		for _nGrupo = 1 to len (_aGrupos)

			// Verifica se cada usuario do grupo tem liberacao para esta verificacao.
			_aDest = aclone (U_ZZULD (_aGrupos [_nGrupo]))
			_aEMails = aclone (_aDest [2])
			_aIDs = aclone (_aDest [3])
			for _nID = 1 to len (_aIDs)
				for _nLiber = 1 to len (_oVerif:LiberZZU)
					if U_ZZUVL (_oVerif:LiberZZU [_nLiber], _aIDs [_nID], .F.)
						U_SendMail (_aEMails [_nID], "Verif.Protheus " + _oVerif:Descricao, _sMsg, {}, NIL, _aGrupos [_nGrupo])
						exit
					endif
				next
				u_log2 ('info', '')
			next
		next
	endif
return
