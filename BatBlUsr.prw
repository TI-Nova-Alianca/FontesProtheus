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
//

// -----------------------------------------------------------------------------------------------------------------
user function BatBlUsr ()
	local _oSQL      := NIL
	local _aUsers    := {}
	local _nUser     := 0
	local _aPswRet   := {}
	local _aCPF      := {}
	local _nCPF      := 0
	local _sCPF      := ''
	local _sIdUser   := ''
	local _oAviso    := NIL
	local _sOp05     := ''
	local _sEmFerias := ''
	local _sSitFol   := ''
	local _sQueFazer := ''

	u_logIni ()

	// Monta lista de CPF encontrados no Metadados.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT CPF, SITUACAO, EM_FERIAS, NOME, isnull (OP05, '1') as OP05 "
	_oSQL:_sQuery +=  " FROM LKSRV_SIRH.SIRH.dbo.VA_VFUNCIONARIOS"
	_oSQL:_sQuery += " WHERE CONTRATO IS NOT NULL"
	_oSQL:_sQuery += " ORDER BY NOME"
	_oSQL:Log ()
	_aCPF := aclone (_oSQL:Qry2Array (.F., .F.))
	//u_log (_aCPF)
	if len (_aCPF) == 0
		u_log ('Nao foi possivel ler os CPF do Metadados')
		_oBatch:Mensagens += 'Nao foi possivel ler os CPF do Metadados'
		_oBatch:Retorno = 'N'
	else
		// Monta lista de usuarios do sistema
		_aUsers := aclone (FwSfAllUsers ())
		
		// Ondena por nome
		_aUsers = asort (_aUsers,,, {|_x, _y| upper (_x [3]) < upper (_y [3])})
		// u_log (_aUsers)
		procregua (len (_aUsers))
		
		// Seleciona indice 1 (por codigo de usuario) no arquivo de senhas
		PswOrder(1)
		
		// Processa cada usuario
		for _nUser = 1 to len (_aUsers)

			// Alguns usuarios jah sei que nao preciso ou nao devo verificar
			if upper (left (_aUsers [_nUser, 3], 4)) != 'REP_' .and. ! upper (alltrim (_aUsers [_nUser, 3])) $ 'ADMINISTRADOR/CUPOM.CX/CUPOM.03/CUPOM.08/CUPOM.10/CUPOM.13/CUPOM LOJA 3/CUPOM SANDRA/CUPOM.TI/MANUTENCAO/SIGALOJA'
				_sIdUser = _aUsers [_nUser, 2]
				if ! PswSeek (_sIdUser, .T.)
					u_log ('ID de usuario nao localizado:', _sIdUser)
					_oBatch:Mensagens += 'ID de usuario nao localizado: '+ _sIdUser
					_oBatch:Retorno = 'N'
				else
					u_log ('')
					_aPswRet := PswRet ()
					// u_log ('PrwRet:', _aPswRet)
					u_log ('Verificando usuario', _sIdUser, _aUsers [_nUser, 3])

					// Onde buscar o CPF do usuario: optei por informar no campo CARGO no sigacfg.
					if ! 'CPF ' $ upper (_aPswRet [1, 13])
						u_log ('O numero do CPF deve ser informado (apenas numeros) no campo CARGO do cadastro de usuarios, no formato: CPF XXXXXXXXXXX seguido da descricao do cargo.')
					else
						_sCPF = StrTokArr (_aPswRet [1, 13], ' ')[2]
						if empty (_sCPF)
							u_log ('CPF nao informado no cadastro do usuario')
						else
							_nCPF = ascan (_aCPF, {| _aVal | alltrim (_aVal [1]) == alltrim (_sCPF)})
							if _nCPF == 0
								u_log ("CPF '" + _sCPF + "' nao encontrado no Metadados.") //, ou nao encontra-se em situacao que precise bloquear.")
							else
								u_log ('CPF localizado na array lida do Metadados, na posicao', _nCPF, ':', _aCPF [_nCPF, 1], _aCPF [_nCPF, 4])

								// Define o que deve ser feito com este usuario, conforme CodigoComplementar:
								// 1 = conforme situacao da folha (ativo/demitido/afastado/ferias/...)
								// 2 = bloquear (vai ser demitido / encontra de atestado / ...)
								// 3 = nunca bloquear (diretoria, etc.)
								_sSitFol   = alltrim (_aCPF [_nCPF, 2])
								_sEmFerias = alltrim (_aCPF [_nCPF, 3])
								_sOp05     = alltrim (_aCPF [_nCPF, 5])
								if _sOp05 == '1'
									if _sSitFol != '1' .or. _sEmFerias == 'S'
										_sQueFazer = 'B'
									else
										_sQueFazer = 'L'
									endif
								elseif _sOp05 == '2'
									_sQueFazer = 'B'
								elseif _sOp05 == '3'
									_sQueFazer = 'L'
								endif

								U_LOG ('situacao...:', _sSitFol)
								u_log ('em ferias..:', _sEmFerias)
								u_log ('OP05.......:', _sOp05)
								u_log ('_sQueFazer.:', _sQueFazer)

								//if _aCPF [_nCPF, 2] != '1' .or. _aCPF [_nCPF, 3] == 'S' .or. alltrim (_aCPF [_nCPF, 5]) == '2'
								if _sQueFazer == 'B'
									if ! _aPswRet [1, 17]
										u_log ('Bloqueando usuario ', _sIdUser)
										PswBlock (_sIdUser)

//										// Gera aviso para a TI. Futuramente poderia bloquear. Ex.: PswBlock ("gabriela.bavaresco")  // Soh nao sei como desbloquear...
//										_oAviso := ClsAviso ():New ()
//										_oAviso:Tipo       = 'A'
//										_oAviso:Destinatar = 'grpTI'
//										_oAviso:Texto      = 'Bloqueando usuario ' + _sIdUser + ' - CPF ' + alltrim (_aCPF [_nCPF, 1]) + ' - ' + alltrim (_aCPF [_nCPF, 4]) + ': funcionario inativo/afastado/ferias.'
//										_oAviso:Origem     = procname ()
//										_oAviso:DiasDeVida = 5
//										_oAviso:CodAviso   = '001'
//										_oAviso:Grava ()

									endif
								else
									if _aPswRet [1, 17]
										u_log ('Usuario deveria ser desbloqueado no Protheus.')

										_oAviso := ClsAviso ():New ()
										_oAviso:Tipo       = 'A'
										_oAviso:Destinatar = 'grpTI'
										_oAviso:Texto      = 'Usuario ' + _sIdUser + ' - CPF ' + alltrim (_aCPF [_nCPF, 1]) + ' - ' + alltrim (_aCPF [_nCPF, 4]) + ': deveria ser desbloqueado no Protheus.'
										_oAviso:Origem     = procname ()
										_oAviso:DiasDeVida = 5
										_oAviso:CodAviso   = '001'
										_oAviso:Grava ()
									endif
								endif
							endif
						endif
					endif
				endif
			endif
		next

		_oBatch:Retorno = 'S'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
	endif

	u_logFim ()
return .T.
