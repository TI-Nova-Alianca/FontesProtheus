// Programa...: BatBlUsr
// Autor......: Robert Koch
// Data.......: 18/11/2019
// Descricao..: Verifica necessidade debloquear usuarios em ferias, afastados e desligados.
//
// Historico de alteracoes:
// 13/12/2019 - Robert - Parametro invalido na chamada da funcao PswBlock().
// 26/02/2020 - Robert - Passa a validar o campo CODIGOCOMPLEMENTAR da view do Metadados.
//                     - Melhoria nos logs.
// 03/02/2020 - Robert - Passa a validar a matricula pelo campo CONTRATO e nao mais pelo CRACHA na view do Metadados.
// 03/03/2020 - Robert - Passa a validar por CPF (ocorre repeticao de matriculas e diferentes filiais no Metadados).
// 19/03/2020 - Robert - Nao validava corretamente o campo OP05.
// 12/03/2021 - Robert - Passa a validar por codigo de 'pessoa' e nao mais por CPF.
// 03/05/2021 - Robert - Passa a bloquear somente usuarios que nao autenticam pelo dominio.
// 02/03/2022 - Robert - Pequena melhoria nos logs.
// 11/08/2022 - Robert - Bloqueia demitidos (antes ignorava-os, se autenticassem pelo A.D.)
// 01/09/2022 - Robert - Melhorias ClsAviso.
// 02/10/2022 - Robert - Removido atributo :DiasDeVida da classe ClsAviso.
// 19/04/2023 - Robert - Passa a bloquear sempre, independente ddo usuario
//                       autenticar pelo A.D., por que estamos tendo muitas
//                       aplicacoes que nao usam mais A.D. (Meu Protheus, MntNG, Telnet, ...)
//

// --------------------------------------------------------------------------
user function BatBlUsr ()
	local _oSQL      := NIL
	local _aUsers    := {}
	local _nUser     := 0
	local _aPswRet   := {}
	local _aPessoa   := {}
	local _nPessoa   := 0
	local _sPessoa   := ''
	local _sIdUser   := ''
	local _oAviso    := NIL
	local _sOp05     := ''
	local _sEmFerias := ''
	local _sSitFol   := ''
	local _sQueFazer := ''
//	local _lUsaAD    := .F.
	local _sMotAlter := ''

	// Monta lista de pessoas encontradas no Metadados.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT PESSOA, SITUACAO, EM_FERIAS, NOME, isnull (OP05, '1') as OP05 "
	_oSQL:_sQuery +=  " FROM LKSRV_SIRH.SIRH.dbo.VA_VFUNCIONARIOS"
	_oSQL:_sQuery += " WHERE CONTRATO IS NOT NULL"
	_oSQL:_sQuery += " ORDER BY NOME"
	_oSQL:Log ()
	_aPessoa := aclone (_oSQL:Qry2Array (.F., .F.))
	if len (_aPessoa) == 0
		u_log2 ('erro', 'Nao foi possivel ler as pessoas do Metadados')
		_oBatch:Mensagens += 'Nao foi possivel ler as pessoas do Metadados'
		_oBatch:Retorno = 'N'
	else
		// Monta lista de usuarios do sistema
		_aUsers := aclone (FwSfAllUsers ())
		
		// Ondena por nome
		_aUsers = asort (_aUsers,,, {|_x, _y| upper (_x [3]) < upper (_y [3])})
		procregua (len (_aUsers))
		
		// Seleciona indice 1 (por codigo de usuario) no arquivo de senhas
		PswOrder(1)
		
		// Processa cada usuario
		for _nUser = 1 to len (_aUsers)
			_sIdUser  = _aUsers [_nUser, 2]
			_sMotAter = ''

			// Alguns usuarios jah sei que nao preciso ou nao devo verificar
			if upper (left (_aUsers [_nUser, 3], 4)) == 'REP_' .or. upper (alltrim (_aUsers [_nUser, 3])) $ 'ADMINISTRADOR/CUPOM.CX/CUPOM.03/CUPOM.08/CUPOM.10/CUPOM.13/CUPOM LOJA 3/CUPOM SANDRA/SANDRA.SUGARI2/CUPOM.TI/MANUTENCAO/SIGALOJA/4FX/CUPOM.VALE/APP.MNTNG/SUPORTE.TOTVS'
				loop
			endif

			u_log2 ('info', 'Verificando usuario ' + _sIdUser + ' ' + _aUsers [_nUser, 3])

// De momento nao estou mais usando			// Verifica se o usuario faz autenticacao pelo dominio.
// De momento nao estou mais usando			_oSQL := ClsSQL ():New ()
// De momento nao estou mais usando			_oSQL:_sQuery := "SELECT COUNT (*)"
// De momento nao estou mais usando			_oSQL:_sQuery +=  " FROM SYS_USR_SSIGNON"
// De momento nao estou mais usando			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
// De momento nao estou mais usando			_oSQL:_sQuery += " AND SYS_USR_SSIGNON.USR_ID = '" + _sIdUser + "'"
// De momento nao estou mais usando			_oSQL:_sQuery += " AND UPPER(USR_SO_DOMINIO) = 'VINHOS-ALIANCA'"
// De momento nao estou mais usando			_oSQL:_sQuery += " AND USR_SO_USERLOGIN != ''"
// De momento nao estou mais usando			// _oSQL:Log ()
// De momento nao estou mais usando			if _oSQL:RetQry (1, .f.) > 0
// De momento nao estou mais usando				U_Log2 ('info', 'Usuario ' + _sIdUser + ' ' + _aUsers [_nUser, 3] + ' autentica pelo A.D.')
// De momento nao estou mais usando				_lUsaAD = .T.
// De momento nao estou mais usando			else
// De momento nao estou mais usando				_lUsaAD = .F.
// De momento nao estou mais usando			endif

			if ! PswSeek (_sIdUser, .T.)
				u_log2 ('aviso', 'ID de usuario nao localizado: ' + _sIdUser)
				_oBatch:Mensagens += 'ID de usuario nao localizado: '+ _sIdUser
				_oBatch:Retorno = 'N'
				loop
			endif

		//	u_log2 ('INFO', '---------------------------------------------------------------------------')
			_aPswRet := PswRet ()
			//u_log2 ('debug', _aPswRet)

			// Onde buscar a 'pessoa' do usuario: optei por informar no campo CARGO no sigacfg.
			if ! 'PESSOA ' $ upper (_aPswRet [1, 13])
				if ! _aPswRet [1, 17]  // Usuario ativo gera log como 'aviso'
					u_log2 ('aviso', 'O codigo da pessoa deve ser informado no campo CARGO do cadastro de usuarios, no formato: PESSOA XXXXXXXXXXX seguido da descricao do cargo.')
				else
					u_log2 ('info', 'O codigo da pessoa deve ser informado no campo CARGO do cadastro de usuarios, no formato: PESSOA XXXXXXXXXXX seguido da descricao do cargo.')
				endif
			else
				_sPessoa = StrTokArr (_aPswRet [1, 13], ' ')[2]
				if empty (_sPessoa)
					u_log2 ('aviso', "'Pessoa' nao informada no cadastro do usuario")
				else
					_nPessoa = ascan (_aPessoa, {| _aVal | _aVal [1] == val (_sPessoa)})
					if _nPessoa == 0
						u_log2 ('debug', "Pessoa '" + _sPessoa + "' nao encontrada no Metadados.") //, ou nao encontra-se em situacao que precise bloquear.")
					else
						// u_log2 ('debug', 'Pessoa localizada na array lida do Metadados, na posicao ' + cvaltochar (_nPessoa) + ':' + cvaltochar (_aPessoa [_nPessoa, 1]) + ' ' + _aPessoa [_nPessoa, 4])

						// // Como nao tenho (ateh o momento) opcao de desbloquear via AdvPl, nem vou verificar os bloqueados.
						// if ! _aPswRet [1, 17]

							// Define o que deve ser feito com este usuario, conforme CodigoComplementar:
							// 1 = conforme situacao da folha (ativo/demitido/afastado/ferias/...)
							// 2 = bloquear (vai ser demitido / encontra-se com atestado / ...)
							// 3 = nunca bloquear (diretoria, etc.)
							_sSitFol   = alltrim (_aPessoa [_nPessoa, 2])
							_sEmFerias = alltrim (_aPessoa [_nPessoa, 3])
							_sOp05     = alltrim (_aPessoa [_nPessoa, 5])
							if _sOp05 == '1'
								if _sSitFol != '1' .or. _sEmFerias == 'S'  // .and. ! _lUsaAD  // Se usa AD, jah foi bloqueado lah.
									_sQueFazer = 'B'
									_sMotAlter = 'Cfe.sit.folha-em ferias'
								else
									_sQueFazer = 'L'
									_sMotAlter = 'Cfe.sit.folha-nao esta em ferias'
								endif
							elseif _sOp05 == '2'
								_sQueFazer = 'B'
								_sMotAlter = 'Opcao 2(bloquear) no Metadados'
							elseif _sOp05 == '3'
								_sQueFazer = 'L'
								_sMotAlter = 'Opcao 3(nunca bloquear) no Metadados'
							endif

							if _sSitFol $ '3/4'
								U_Log2 ('info', '[' + procname () + ']demitido!')
								_sQueFazer = 'B'
								_sMotAlter = 'Demitido no Metadados'
							endif
						
							U_LOG2 ('INFO', 'situacao...: ' + _sSitFol)
							u_log2 ('INFO', 'em ferias..: ' + _sEmFerias)
							u_log2 ('INFO', 'OP05.......: ' + _sOp05)
							u_log2 ('INFO', '_sQueFazer.: ' + _sQueFazer)

							if _sQueFazer == 'B'
								if ! _aPswRet [1, 17]
									u_log2 ('aviso', 'Bloqueando ' + _sIdUser + '-' + _aUsers [_nUser, 3] + ': ' + _sMotAlter)
									PswBlock (_sIdUser)

									_oAviso := ClsAviso ():New ()
									_oAviso:Tipo       = 'I'
									_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
									_oAviso:Texto      = 'Bloqueando ' + _sIdUser + '-' + _aUsers [_nUser, 3] + ' no Protheus: ' + _sMotAlter
									_oAviso:Origem     = procname ()
									_oAviso:Grava ()
								endif
							else
								if _aPswRet [1, 17]
									u_log2 ('aviso', 'Usuario deveria ser desbloqueado no Protheus por motivo ' + _sMotAlter)
									_oAviso := ClsAviso ():New ()
									_oAviso:Tipo       = 'A'
									_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
									_oAviso:Texto      = 'Usuario ' + _sIdUser + '-' + _aUsers [_nUser, 3] + ' deveria ser desbloqueado no Protheus: ' + _sMotAlter
									_oAviso:Origem     = procname ()
									_oAviso:Grava ()
								endif
							endif
						// endif
					endif
				endif
			endif
		next

		_oBatch:Retorno = 'S'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
	endif

return .T.
