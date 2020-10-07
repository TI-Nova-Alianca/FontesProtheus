// Programa:  Semaforo
// Autor:     Robert Koch - TCX021
// Data:      30/10/2006
// Descricao: Implementa semaforo via arquivo texto. Deve ser chamado passando-se
//            uma string de identificacao do processo a ser bloqueado ou o ID
//            (gerado pela propria funcao) para ser desbloqueado. Cuidado com a string
//            de identificacao, pois serah usada no nome do arquivo de lock.
//
//            Exemplo de uso:
//            user function teste ()
//               local _nLock := U_Semaforo ("TESTE_DE_LOCK")
//               // ... procedimentos ...
//               U_Semaforo (_nLock)
//            return

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Gera arquivo de semaforo para controle de acesso concorrente a rotinas especificas.
// #PalavasChave      #controle_semaforo
// #TabelasPrincipais 
// #Modulos           #todos_modulos

// Historico de alteracoes:
// 12/11/2008 - Robert - Criada opcao de trabalhar sem interface com o usuario.
// 24/10/2010 - Robert - Passa a usar a funcao u_help para mostrar mensagens.
// 18/11/2016 - Robert - Incluidos ambiente e porta do servico no arquivo de lock e na mensagem para usuario.
//                     - Passa a usar a funcao U_MsgYesNo em lugar da MsgYesNo, de forma que sempre poderia ser chamado com _lComTela=.T.
// 07/10/2020 - Robert - Inseridas tags para catalogo de fontes
//                     - Melhorados logs.
//

#include "fileio.ch"

// --------------------------------------------------------------------------
User Function Semaforo (_xParam, _lComTela)
	local _nHdl      := 0
	local _sArq      := ""
	local _sDados    := ""
	local _nTamDado  := 20
	local _lTenta    := .T.
	local _sProcesso := ""
	local _sMsg      := ""

	_lComTela := iif (_lComTela == NIL, .T., _lComTela)
	
	// Se o parametro informado for do tipo caracter, entendo que seja a descricao/codigo
	// do processo a ser bloqueado. Usarei esse codigo na criacao do arquivo de bloqueio.
	// Se o parametro informado for do tipo numero, entendo que seja o 'handle' do
	// arquivo de lock criado na chamada anterior e que deverah, portanto, ser desbloqueado.
	if valtype (_xParam) == "C"
		_sProcesso = _xParam
		_sArq := "\semaforo\" + procname () + "_" + alltrim (_xParam) + ".lck"
	elseif valtype (_xParam) == "N"
		FClose (_xParam)
		return 0
	else
		u_help ("Programa " + procname () + " recebeu parametro incorreto da funcao " + procname (1),, .t.)
		return 0
	endif
	
	// Cria o arquivo, caso ainda nao exista.
	if ! file (_sArq)
		_nHdl = FCreate (_sArq)
		if _nHdl == -1
			u_help ("Erro na criacao do arquivo de semaforo " + _sArq,, .t.)
			return 0
		else
			FClose (_nHdl)
		endif
	endif
	
	
	// Tenta abrir o arquivo para gravacao
	_lTenta = .T.
	do while _lTenta
		_nHdl = FOpen (_sArq, FO_WRITE + FO_DENYWRITE)
		if _nHdl == -1  // Nao consegui abrir para gravacao.
			_nHdl = FOpen (_sArq, FO_READ + FO_SHARED)
			if _nHdl == -1
				u_help ("Processo '" + _sProcesso + "' bloqueado. Nao foi possivel abrir o arquivo de bloqueio para saber qual o usuario que esta' bloqueando. Nome do arquivo: " + _sArq,, .t.)
				return 0
			else
				_sMsg := "Processo '" + _sProcesso + "' bloqueado." + chr (13) + chr (10) + chr (13) + chr (10)
				_sMsg += "Usuario: " + alltrim (freadstr (_nHdl, _nTamDado)) + chr (13) + chr (10)
				_sMsg += "Estacao: " + alltrim (fReadStr (_nHdl, _nTamDado)) + chr (13) + chr (10)
				_sMsg += "Data/hora: " + alltrim (fReadStr (_nHdl, _nTamDado)) + chr (13) + chr (10)
				_sMsg += "Rotina: " + alltrim (fReadStr (_nHdl, _nTamDado)) + chr (13) + chr (10)
				_sMsg += "Ambiente: " + alltrim (fReadStr (_nHdl, _nTamDado)) + chr (13) + chr (10)
				_sMsg += "Porta serv: " + alltrim (fReadStr (_nHdl, _nTamDado)) + chr (13) + chr (10)
				_sMsg += chr (13) + chr (10)
				if _lComTela
					_lTenta = U_MsgYesNo (_sMsg + "Deseja tentar novamente?")
				else
					u_log2 ('aviso', _sMsg)
					_lTenta = .F.
				endif
				FClose (_nHdl)
			endif
		else
			_sDados := padr (left (cUserName,                      _nTamDado), _nTamDado, " ")
			_sDados += padr (left (getcomputername (),             _nTamDado), _nTamDado, " ")
			_sDados += padr (left (dtoc (date ()) + "-" + time (), _nTamDado), _nTamDado, " ")
			_sDados += padr (left (procname (1),                   _nTamDado), _nTamDado, " ")
			_sDados += padr (left (GetEnvServer (),                _nTamDado), _nTamDado, " ")
			_sDados += padr (left (cvaltochar (GetServerPort ()),  _nTamDado), _nTamDado, " ")
			fwrite (_nHdl, _sDados)
			return _nHdl
		endif
	enddo
return 0
