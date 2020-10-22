// Programa...: GravaSX1
// Autor......: Robert Koch
// Data.......: 13/02/2002
// Cliente....: Generico
// Descricao..: Atualiza respostas das perguntas no SX1
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #PalavasChave      #parametros #perguntas #automacao #auxiliar #uso_generico
// #TabelasPrincipais #SX1 #PROFILE
// #Modulos           #todos_modulos
//
// Historico de alteracoes:
// 01/09/2005 - Robert - Ajustes para trabalhar com profile de usuario (versao 8.11)
// 16/02/2006 - Robert - Melhorias gerais
// 12/12/2006 - Robert - Sempre grava numerico no X1_PRESEL
// 11/09/2007 - Robert - Parametros tipo 'combo' podem receber informacao numerica ou caracter.
//                     - Testa existencia da variavel __cUserId
// 02/04/2008 - Robert - Mostra mensagem quando tipo de dados for incompativel.
//                     - Melhoria geral nas mensagens.
// 03/06/2009 - Robert - Tratamento para aumento de tamanho do X1_GRUPO no Protheus10
// 26/01/2010 - Robert - Chamadas da msgalert trocadas por u_help.
// 29/07/2010 - Robert - Soh trabalhava com profile de usuario na versao 8.
// 26/09/2013 - Robert - Chama 2 atualizacoes de profile para tratar casos em que o usuario tem o acesso '150 - Grava respostas parametros por empresa' 
// 09/07/2020 - Robert - Melhorada gravacao de logs e mensagens.
// 21/10/2020 - Claudia - Ajuste da rotina incluindo scripts SQL. GLPI: 8690
//
// --------------------------------------------------------------------------
// Parametros:
// 1 - Grupo de perguntas a atualizar
// 2 - Codigo (ordem) da pergunta
// 3 - Dado a ser gravado
//
user function GravaSX1 (_sGrupo, _sPerg, _xValor)
	local _aAreaAnt  := U_ML_SRArea ()
	local _sUserName := ""
	local _lContinua := .T.

	// Na versao Protheus10 o tamanho das perguntas aumentou.
	_sGrupo = padr (_sGrupo, len (sx1 -> x1_grupo), " ")

	if _lContinua
		if ! sx1 -> (dbseek (_sGrupo + _sPerg, .F.))
			u_help ("Programa " + procname () + ": grupo/pergunta '" + _sGrupo + "/" + _sPerg + "' nao encontrado no arquivo SX1.",, .t.)
			_lContinua = .F.
		endif
	endif
	
	if _lContinua
		// Atualizarei sempre no SX1. Depois vou ver se tem profile de usuario.
		do case
			case sx1 -> x1_gsc == "C"
				reclock ("SX1", .F.)
				sx1 -> x1_presel = val (cvaltochar (_xValor))
				sx1 -> x1_cnt01  = ""
				sx1 -> (msunlock ())
			case sx1 -> x1_gsc == "G"
				if valtype (_xValor) != sx1 -> x1_tipo
					u_help ("Programa " + procname () + ": incompatibilidade de tipos: o parametro '" + _sPerg + "' do grupo de perguntas '" + _sGrupo + "' eh do tipo '" + sx1 -> x1_tipo + "', mas o valor recebido eh do tipo '" + valtype (_xValor) + "' (conteudo: " + cvaltochar (_xValor) + ")." + _PCham ())
					_lContinua = .F.
				else
					reclock ("SX1", .F.)
					sx1 -> x1_presel = 0
					if sx1 -> x1_tipo == "D"
						sx1 -> x1_cnt01 = "'" + dtoc (_xValor) + "'"
					elseif sx1 -> x1_tipo == "N"
						sx1 -> x1_cnt01 = str (_xValor, sx1 -> x1_tamanho, sx1 -> x1_decimal)
					elseif sx1 -> x1_tipo == "C"
						sx1 -> x1_cnt01 = _xValor
					endif
					sx1 -> (msunlock ())
				endif
			otherwise
				u_help ("Programa " + procname () + ": tratamento para X1_GSC = '" + sx1 -> x1_gsc + "' ainda nao implementado." + _PCham ())
				_lContinua = .F.
		endcase
	endif
	
	// Atualiza parametros no profile do usuario.
	if _lContinua

		if type ("__cUserId") == "C" .and. ! empty (__cUserId)
			psworder (1)  // Ordena arquivo de senhas por ID do usuario
			PswSeek(__cUserID)  // Pesquisa usuario corrente
			_sUserName := PswRet(1) [1, 1]
			
			// Como alguns usuarios tem o acesso '150 - Grava respostas parametros por empresa' (administradores, por exemplo),
			// faz duas chamadas da rotina, uma com a empresa e uma sem.
			// A chamada de funcao "ChkPsw (150)" retorna se o usuario tem esse acesso, mas nao pode ser usada aqui por que
			// o sistema mostra msg ao usuario dizendo que 'apenas o Administrador tem acesso'...
			_AtuProf (_sUserName, _sGrupo, _sPerg)
			//_AtuProf (cEmpAnt + _sUserName, _sGrupo, _sPerg)

		endif
	endif
	
	U_ML_SRArea (_aAreaAnt)
return .T.
//--------------------------------------------------------------------------
// Atualiza perguntas no MP_SYSTEM_PROFILE - Tabela no BD
static function _AtuProf (_sUserName, _sGrupo, _sPerg)
	local _nLinha    := 0
	local _sMemoProf := ""
	local _aLinhas   := {}

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 		ISNULL(CONVERT(VARCHAR(2047), CONVERT(VARBINARY(2047), P_DEFS)), '') AS CONTEUDO"
	_oSQL:_sQuery += " FROM MP_SYSTEM_PROFILE"
	_oSQL:_sQuery += " WHERE P_NAME = '" + _sUserName + "'"
	_oSQL:_sQuery += " AND P_PROG   = '" + _sGrupo    + "'"
	_oSQL:_sQuery += " AND P_TASK   ='PERGUNTE'"
	_oSQL:_sQuery += " AND P_TYPE   = 'MV_PAR'"
	_oSQL:_sQuery += " AND P_EMPANT = '" + cEmpAnt + "'"
	_oSQL:_sQuery += " order by R_E_C_N_O_ desc"
	_oSQL:Log ()
	_aDados := aclone (_oSQL:Qry2Array ())

	 If len(_aDados) > 0
		// Carrega memo com o profile do usuario (o profile fica gravado em um campo memo)
		_sMemoProf := alltrim(_aDados[1,1])
		
		// Monta array com as linhas do memo (tem uma pergunta por linha)
		for _nLinha = 1 to MLCount (_sMemoProf)
			If alltrim (MemoLine (_sMemoProf,, _nLinha)) <> ""
				aadd (_aLinhas,  StrTran(alltrim (MemoLine (_sMemoProf,, _nLinha)),"'","") + chr (13) + chr (10))
			EndIf
		next
	EndIf
	// Monta uma linha com o novo conteudo do parametro atual.
	// Pos 1 = tipo (numerico/data/caracter...)
	// Pos 2 = '#'
	// Pos 3 = GSC
	// Pos 4 = '#'
	// Pos 5 em diante = conteudo.
	_sLinha = sx1 -> x1_tipo + "#" + sx1 -> x1_gsc + "#" + iif (sx1 -> x1_gsc == "C", cValToChar (sx1 -> x1_presel), sx1 -> x1_cnt01) + chr (13) + chr (10)
	_sLinha = StrTran(_sLinha,"'","")

	// Se foi passada uma pergunta que nao consta no profile, deve tratar-se
	// de uma pergunta nova, pois jah encontrei-a no SX1. Entao vou criar uma
	// linha para ela na array. Senao, basta regravar na array.
	if val(_sPerg) > len (_aLinhas)
		aadd (_aLinhas, _sLinha)
	else
		// Grava a linha de volta na array de linhas
		_aLinhas [val (_sPerg)] = _sLinha
	endif

	// Remonta memo para gravar no profile
	_sMemoProf = ""
	for _nLinha = 1 to len (_aLinhas)
		_sMemoProf += _aLinhas [_nLinha]
	next

	If len(_aDados) > 0
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " UPDATE MP_SYSTEM_PROFILE SET P_DEFS = Cast('" + ALLTRIM(_sMemoProf) + "' as VARBINARY(max))"
		_oSQL:_sQuery += " WHERE P_NAME = '" + _sUserName + "'"
		_oSQL:_sQuery += " AND P_PROG   = '" + _sGrupo    + "'"
		_oSQL:_sQuery += " AND P_TASK   ='PERGUNTE'"
		_oSQL:_sQuery += " AND P_TYPE   = 'MV_PAR'"
		_oSQL:_sQuery += " AND P_EMPANT = '" + cEmpAnt + "'"
		_oSQL:Log ()
		_oSQL:Exec ()
	else
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " INSERT INTO [dbo].[MP_SYSTEM_PROFILE] ([P_NAME],[P_PROG],[P_TASK],[P_TYPE],[P_DEFS],[P_EMPANT],[P_FILANT],[D_E_L_E_T_],[R_E_C_D_E_L_])"
		_oSQL:_sQuery += " VALUES('"+ _sUserName +"','" + _sGrupo +"','PERGUNTE','MV_PAR', Cast('" + ALLTRIM(_sMemoProf) + "' as VARBINARY(max)),'" + cEmpAnt +"','','', 0)"
		_oSQL:Log ()
		_oSQL:Exec ()
	EndIf

return


// // --------------------------------------------------------------------------
// // Encontra e atualiza profile deste usuario para a rotina / pergunta atual.
// // Enquanto o usuario nao alterar nenhuma pergunta, ficarah usando do SX1 e
// // seu profile nao serah criado.
// static function _AtuProf (_sUserName, _sGrupo, _sPerg)
// 	local _nLinha    := 0
// 	local _sMemoProf := ""

// 	If FindProfDef (_sUserName, _sGrupo, "PERGUNTE", "MV_PAR")

// 		// Carrega memo com o profile do usuario (o profile fica gravado em um campo memo)
// 		_sMemoProf := RetProfDef (_sUserName, _sGrupo, "PERGUNTE", "MV_PAR")
		
// 		// Monta array com as linhas do memo (tem uma pergunta por linha)
// 		_aLinhas = {}
// 		for _nLinha = 1 to MLCount (_sMemoProf)
// 			aadd (_aLinhas, alltrim (MemoLine (_sMemoProf,, _nLinha)) + chr (13) + chr (10))
// 		next

// 		// Monta uma linha com o novo conteudo do parametro atual.
// 		// Pos 1 = tipo (numerico/data/caracter...)
// 		// Pos 2 = '#'
// 		// Pos 3 = GSC
// 		// Pos 4 = '#'
// 		// Pos 5 em diante = conteudo.
// 		_sLinha = sx1 -> x1_tipo + "#" + sx1 -> x1_gsc + "#" + iif (sx1 -> x1_gsc == "C", cValToChar (sx1 -> x1_presel), sx1 -> x1_cnt01) + chr (13) + chr (10)

// 		// Se foi passada uma pergunta que nao consta no profile, deve tratar-se
// 		// de uma pergunta nova, pois jah encontrei-a no SX1. Entao vou criar uma
// 		// linha para ela na array. Senao, basta regravar na array.
// 		if val(_sPerg) > len (_aLinhas)
// 			aadd (_aLinhas, _sLinha)
// 		else
// 			// Grava a linha de volta na array de linhas
// 			_aLinhas [val (_sPerg)] = _sLinha
// 		endif

// 		// Remonta memo para gravar no profile
// 		_sMemoProf = ""
// 		for _nLinha = 1 to len (_aLinhas)
// 			_sMemoProf += _aLinhas [_nLinha]
// 		next
		
// 		// Grava o memo no profile
// 		WriteProfDef(_sUserName, _sGrupo, "PERGUNTE", "MV_PAR", ;  // Chave antiga
// 		_sUserName, _sGrupo, "PERGUNTE", "MV_PAR", ;  // Chave nova
// 		_sMemoProf)  // Novo conteudo do memo.
// 	endif
// return



// --------------------------------------------------------------------------
static Function _PCham ()
	local _i      := 0
//	local _sPilha := chr (13) + chr (10) + chr (13) + chr (10) + "Pilha de chamadas:"
	local _sPilha := "  Pilha de chamadas:"
	do while procname (_i) != ""
//		_sPilha += chr (13) + chr (10) + procname (_i)
		_sPilha += ' ==> ' + procname (_i)
		_i++
	enddo
return _sPilha
