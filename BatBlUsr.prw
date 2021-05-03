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
//

// -----------------------------------------------------------------------------------------------------------------
user function BatBlUsr ()

	local _oSQL      := NIL
	local _aUsers    := {}
	local _nUser     := 0
	local _aPswRet   := {}
	local _aPessoa   := {}
	local _nPessoa   := 0
	local _sPessoa   := ''
	local _sIdUser   := ''
//	local _oAviso    := NIL
	local _sOp05     := ''
	local _sEmFerias := ''
	local _sSitFol   := ''
	local _sQueFazer := ''

	// Monta lista de pessoas encontradas no Metadados.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT PESSOA, SITUACAO, EM_FERIAS, NOME, isnull (OP05, '1') as OP05 "
	_oSQL:_sQuery +=  " FROM LKSRV_SIRH.SIRH.dbo.VA_VFUNCIONARIOS"
	_oSQL:_sQuery += " WHERE CONTRATO IS NOT NULL"
	_oSQL:_sQuery += " ORDER BY NOME"
	_oSQL:Log ()
	_aPessoa := aclone (_oSQL:Qry2Array (.F., .F.))
	u_log (_aPessoa)
	if len (_aPessoa) == 0
		u_log ('Nao foi possivel ler as pessoas do Metadados')
		_oBatch:Mensagens += 'Nao foi possivel ler as pessoas do Metadados'
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
			_sIdUser = _aUsers [_nUser, 2]

			// Alguns usuarios jah sei que nao preciso ou nao devo verificar
			if upper (left (_aUsers [_nUser, 3], 4)) == 'REP_' .or. upper (alltrim (_aUsers [_nUser, 3])) $ 'ADMINISTRADOR/CUPOM.CX/CUPOM.03/CUPOM.08/CUPOM.10/CUPOM.13/CUPOM LOJA 3/CUPOM SANDRA/SANDRA.SUGARI2/CUPOM.TI/MANUTENCAO/SIGALOJA/4FX/CUPOM.VALE'
				loop
			endif

			u_log2 ('info', 'Verificando usuario ' + _sIdUser + ' ' + _aUsers [_nUser, 3])

			// Usuarios que autenticam pelo dominio nao preciso bloquear aqui, pois jah eh feito bloqueio pelo dominio.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT COUNT (*)"
			_oSQL:_sQuery +=  " FROM SYS_USR_SSIGNON"
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery += " AND SYS_USR_SSIGNON.USR_ID = '" + _sIdUser + "'"
			_oSQL:_sQuery += " AND UPPER(USR_SO_DOMINIO) = 'VINHOS-ALIANCA'"
			_oSQL:_sQuery += " AND USR_SO_USERLOGIN != ''"
			// _oSQL:Log ()
			if _oSQL:RetQry (1, .f.) > 0
				U_Log2 ('info', 'Ignorando usuario ' + _sIdUser + ' ' + _aUsers [_nUser, 3] + ' pois autentica pelo dominio.')
				loop
			endif

			if ! PswSeek (_sIdUser, .T.)
				u_log2 ('erro', 'ID de usuario nao localizado: ' + _sIdUser)
				_oBatch:Mensagens += 'ID de usuario nao localizado: '+ _sIdUser
				_oBatch:Retorno = 'N'
				loop
			endif

			u_log ('')
			_aPswRet := PswRet ()
			//u_log2 ('debug', _aPswRet)

			// Onde buscar a 'pessoa' do usuario: optei por informar no campo CARGO no sigacfg.
			if ! 'PESSOA ' $ upper (_aPswRet [1, 13])
				u_log2 ('aviso', 'O codigo da pessoa deve ser informado no campo CARGO do cadastro de usuarios, no formato: PESSOA XXXXXXXXXXX seguido da descricao do cargo.')
			else
				_sPessoa = StrTokArr (_aPswRet [1, 13], ' ')[2]
				if empty (_sPessoa)
					u_log2 ('aviso', "'Pessoa' nao informada no cadastro do usuario")
				else
					// _nPessoa = ascan (_aPessoa, {| _aVal | alltrim (_aVal [1]) == alltrim (_sPessoa)})
					_nPessoa = ascan (_aPessoa, {| _aVal | _aVal [1] == val (_sPessoa)})
					if _nPessoa == 0
						u_log2 ('debug', "Pessoa '" + _sPessoa + "' nao encontrada no Metadados.") //, ou nao encontra-se em situacao que precise bloquear.")
					else
						// u_log2 ('debug', 'Pessoa localizada na array lida do Metadados, na posicao ' + cvaltochar (_nPessoa) + ':' + cvaltochar (_aPessoa [_nPessoa, 1]) + ' ' + _aPessoa [_nPessoa, 4])

						// Define o que deve ser feito com este usuario, conforme CodigoComplementar:
						// 1 = conforme situacao da folha (ativo/demitido/afastado/ferias/...)
						// 2 = bloquear (vai ser demitido / encontra de atestado / ...)
						// 3 = nunca bloquear (diretoria, etc.)
						_sSitFol   = alltrim (_aPessoa [_nPessoa, 2])
						_sEmFerias = alltrim (_aPessoa [_nPessoa, 3])
						_sOp05     = alltrim (_aPessoa [_nPessoa, 5])
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

						U_LOG2 ('INFO', 'situacao...: ' + _sSitFol)
						u_log2 ('INFO', 'em ferias..: ' + _sEmFerias)
						u_log2 ('INFO', 'OP05.......: ' + _sOp05)
						u_log2 ('INFO', '_sQueFazer.: ' + _sQueFazer)

						//if _aPessoa [_nPessoa, 2] != '1' .or. _aPessoa [_nPessoa, 3] == 'S' .or. alltrim (_aPessoa [_nPessoa, 5]) == '2'
						if _sQueFazer == 'B'
							if ! _aPswRet [1, 17]
								u_log2 ('aviso', 'Bloqueando usuario ' + _sIdUser)
								PswBlock (_sIdUser)
							endif
						else
							if _aPswRet [1, 17]
								u_log2 ('aviso', 'Usuario deveria ser desbloqueado no Protheus.')
// ainda nao estamos monitorando.										_oAviso := ClsAviso ():New ()
// ainda nao estamos monitorando.										_oAviso:Tipo       = 'A'
// ainda nao estamos monitorando.										_oAviso:Destinatar = 'grpTI'
// ainda nao estamos monitorando.										_oAviso:Texto      = 'Usuario ' + _sIdUser + ' - Pessoa ' + alltrim (_aPessoa [_nPessoa, 1]) + ' - ' + alltrim (_aPessoa [_nPessoa, 4]) + ': deveria ser desbloqueado no Protheus.'
// ainda nao estamos monitorando.										_oAviso:Origem     = procname ()
// ainda nao estamos monitorando.										_oAviso:DiasDeVida = 5
// ainda nao estamos monitorando.										_oAviso:CodAviso   = '001'
// ainda nao estamos monitorando.										_oAviso:Grava ()
							endif
						endif
					endif
				endif
			endif
		next

		_oBatch:Retorno = 'S'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
	endif


/*
	local _oSQL      := NIL
	local _aUsu      := {}
	local _nUsu      := 0
	local _sOp05     := ''
	local _sEmFerias := ''
	local _sSitFol   := ''
	local _sQueFazer := ''

	// Monta lista de CPF encontrados no Metadados.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT SYS_USR.USR_ID, SYS_USR.USR_CODIGO, USR_MSBLQL, V.NOME, V.SITUACAO, V.EM_FERIAS, isnull (V.OP05, '1') as OP05"
	_oSQL:_sQuery +=  " FROM SYS_USR, LKSRV_SIRH.SIRH.dbo.VA_VFUNCIONARIOS V"
	_oSQL:_sQuery += " WHERE V.CONTRATO IS NOT NULL"
	_oSQL:_sQuery +=   " AND SYS_USR.USR_CARGO LIKE 'Pessoa ' + cast (V.PESSOA as varchar (max)) + '%' COLLATE DATABASE_DEFAULT"
	_oSQL:_sQuery += " ORDER BY NOME"
	_oSQL:Log ()
	_aUsu := aclone (_oSQL:Qry2Array (.F., .F.))
	//u_log (_aUsu)
	if len (_aUsu) == 0
		u_log2 ('erro', 'Nao encontrei nenhum registro relacionando usuarios do Protheus X pessoas do Metadados')
		_oBatch:Mensagens += 'Nenhum relacionamento Protheus X Metadados'
		_oBatch:Retorno = 'N'
	else
		for _nUsu = 1 to len (_aUsu)

			// Define o que deve ser feito com este usuario, conforme CodigoComplementar:
			// 1 = conforme situacao da folha (ativo/demitido/afastado/ferias/...)
			// 2 = bloquear (vai ser demitido / encontra de atestado / ...)
			// 3 = nunca bloquear (diretoria, etc.)
			_sSitFol   = alltrim (_aUsu [_nUsu, 5])
			_sEmFerias = alltrim (_aUsu [_nUsu, 6])
			_sOp05     = alltrim (_aUsu [_nUsu, 7])
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

			U_LOG2 ('INFO', '')
			U_LOG2 ('INFO', 'USUARIO....: ' + _aUsu [_nUsu, 1] + ' ' + _aUsu [_nUsu, 2])
			U_LOG2 ('INFO', 'situacao...: ' + _sSitFol)
			u_log2 ('INFO', 'em ferias..: ' + _sEmFerias)
			u_log2 ('INFO', 'OP05.......: ' + _sOp05)
			u_log2 ('INFO', '_sQueFazer.: ' + _sQueFazer)

			if _sQueFazer == 'B'
				if _aUsu [_nUsu, 3] != '1'
					u_log ('Bloqueando usuario ', _aUsu [_nUsu, 2])
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := "UPDATE SYS_USR SET USR_MSBLQL = '1'"
					_oSQL:_sQuery += " WHERE USR_ID = '" + _aUsu [_nUsu, 1] + "'"
					_oSQL:Log ()
					// nao deu certo por que o configurador reclama, depois, de erro de checksum --> _oSQL:Exec ()
				endif
			else
				if _aUsu [_nUsu, 3] != '2'
					u_log ('Desbloqueando usuario ', _aUsu [_nUsu, 2])
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := "UPDATE SYS_USR SET USR_MSBLQL = '2'"
					_oSQL:_sQuery += " WHERE USR_ID = '" + _aUsu [_nUsu, 1] + "'"
					_oSQL:Log ()
					// nao deu certo por que o configurador reclama, depois, de erro de checksum --> _oSQL:Exec ()
				endif
			endif
		next

		_oBatch:Retorno = 'S'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
	endif
*/
return .T.
