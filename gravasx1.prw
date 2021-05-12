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
// Parametros:
// 1 - Grupo de perguntas a atualizar
// 2 - Codigo (ordem) da pergunta
// 3 - Dado a ser gravado
// 4 - Se desativa ou ativa o profile - Criado para os casos de contabilização off line
//
// Historico de alteracoes:
// 01/09/2005 - Robert  - Ajustes para trabalhar com profile de usuario (versao 8.11)
// 16/02/2006 - Robert  - Melhorias gerais
// 12/12/2006 - Robert  - Sempre grava numerico no X1_PRESEL
// 11/09/2007 - Robert  - Parametros tipo 'combo' podem receber informacao numerica ou caracter.
//                      - Testa existencia da variavel __cUserId
// 02/04/2008 - Robert  - Mostra mensagem quando tipo de dados for incompativel.
//                      - Melhoria geral nas mensagens.
// 03/06/2009 - Robert  - Tratamento para aumento de tamanho do X1_GRUPO no Protheus10
// 26/01/2010 - Robert  - Chamadas da msgalert trocadas por u_help.
// 29/07/2010 - Robert  - Soh trabalhava com profile de usuario na versao 8.
// 26/09/2013 - Robert  - Chama 2 atualizacoes de profile para tratar casos em que o usuario tem o acesso 
//						 '150 - Grava respostas parametros por empresa' 
// 09/07/2020 - Robert  - Melhorada gravacao de logs e mensagens.
// 21/10/2020 - Claudia - Ajuste da rotina incluindo scripts SQL. GLPI: 8690
// 11/05/2021 - Claudia - Ajustada a chamada para tabela SX1 devido a R27. GLPI: 8825
//
// ----------------------------------------------------------------------------------------------------------

user function GravaSX1 (_sGrupo, _sPerg, _xValor, _sDelProf)
	local _aAreaAnt  := U_ML_SRArea ()
	local _sUserName := ""
	local _lContinua := .T.
	local _x		 := 0

	// Monta array com cada pergunta e sua resposta em uma linha.
	_oSQL  := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	   X1_GRUPO"
	_oSQL:_sQuery += "    ,X1_ORDEM"
	_oSQL:_sQuery += "    ,X1_GSC"
	_oSQL:_sQuery += "    ,X1_TAMANHO"
	_oSQL:_sQuery += "    ,X1_DECIMAL"
	_oSQL:_sQuery += "    ,X1_TIPO"
	_oSQL:_sQuery += "    ,X1_PRESEL"
	_oSQL:_sQuery += "    ,X1_CNT01"
	_oSQL:_sQuery += " FROM SX1010 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND X1_GRUPO     = '" + alltrim(_sGrupo) + "'"
	_oSQL:_sQuery += " AND X1_ORDEM     = '" + alltrim(_sPerg)  + "'"
	_aSX1  = aclone (_oSQL:Qry2Array ())	

	If Len(_aSX1) > 0
		For _x:= 1 to Len(_aSX1)
			_sX1_GRUPO	 := _aSX1[_x, 1]
			_sX1_ORDEM   := _aSX1[_x, 2]
			_sX1_GSC	 := _aSX1[_x, 3]
			_nX1_TAMANHO := _aSX1[_x, 4]
			_nX1_DECIMAL := _aSX1[_x, 5]
			_nX1_TIPO    := _aSX1[_x, 6]
			_nX1_PRESEL  := _aSX1[_x, 7]
			_nX1_CNT01   := _aSX1[_x, 8]

			Do Case
				Case _sX1_GSC == "C"

					_nPresel := cvaltochar (_xValor)
					_oSQL  := ClsSQL ():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " UPDATE SX1010 "
					_oSQL:_sQuery += " SET  X1_PRESEL = " + _nPresel + ", X1_CNT01  = '' "
					_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
					_oSQL:_sQuery += " AND X1_GRUPO     = '" + alltrim(_sGrupo) + "'"
					_oSQL:_sQuery += " AND X1_ORDEM     = '" + alltrim(_sPerg)  + "'"
					_oSQL:Exec ()

				Case _sX1_GSC == "G"
					if valtype (_xValor) != _nX1_TIPO
						u_help ("Programa " + procname () + ": incompatibilidade de tipos: o parametro '" + _sPerg + "' do grupo de perguntas '" + _sGrupo + "' eh do tipo '" + _nX1_TIPO + "', mas o valor recebido eh do tipo '" + valtype (_xValor) + "' (conteudo: " + cvaltochar (_xValor) + ")." + _PCham ())
						_lContinua := .F.
					else

						if _nX1_TIPO == "D"
							_sCnt01 :=  dtoc(_xValor) 
						elseif _nX1_TIPO == "N"
							_sCnt01 := str(_xValor, _nX1_TAMANHO, _nX1_DECIMAL)
						elseif _nX1_TIPO == "C"
							_sCnt01 := _xValor
						endif

						_oSQL  := ClsSQL ():New ()
						_oSQL:_sQuery := ""
						_oSQL:_sQuery += " UPDATE SX1010 "
						_oSQL:_sQuery += " SET "
						_oSQL:_sQuery += "  X1_PRESEL = 0, X1_CNT01  = '" + _sCnt01 +"' "
						_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
						_oSQL:_sQuery += " AND X1_GRUPO     = '" + alltrim(_sGrupo) + "'"
						_oSQL:_sQuery += " AND X1_ORDEM     = '" + alltrim(_sPerg)  + "'"
						_oSQL:Exec ()

					endif

				otherwise
					u_help ("Programa " + procname () + ": tratamento para X1_GSC = '" + _sX1_GSC + "' ainda nao implementado." + _PCham ())
					_lContinua := .F.
			endcase
		Next
	Else
		u_help ("Programa " + procname () + ": grupo/pergunta '" + _sGrupo + "/" + _sPerg + "' nao encontrado no arquivo SX1.",, .t.)
		_lContinua := .F.
	EndIf
	
	if _lContinua

		if type ("__cUserId") == "C" .and. ! empty (__cUserId)
			psworder (1)  // Ordena arquivo de senhas por ID do usuario
			PswSeek(__cUserID)  // Pesquisa usuario corrente
			_sUserName := PswRet(1) [1, 1]

			_AtuProf (_sUserName, _sGrupo, _sPerg)
		endif
	endif
	
	U_ML_SRArea (_aAreaAnt)
return .T.
//
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
		//_oSQL:Log ()
		_oSQL:Exec ()
	else
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " INSERT INTO [dbo].[MP_SYSTEM_PROFILE] ([P_NAME],[P_PROG],[P_TASK],[P_TYPE],[P_DEFS],[P_EMPANT],[P_FILANT],[D_E_L_E_T_],[R_E_C_D_E_L_])"
		_oSQL:_sQuery += " VALUES('"+ _sUserName +"','" + _sGrupo +"','PERGUNTE','MV_PAR', Cast('" + ALLTRIM(_sMemoProf) + "' as VARBINARY(max)),'" + cEmpAnt +"','','', 0)"
		//_oSQL:Log ()
		_oSQL:Exec ()
	EndIf

return
//
//
// --------------------------------------------------------------------------
static Function _PCham ()
	local _i      := 0
	local _sPilha := "  Pilha de chamadas:"

	do while procname (_i) != ""
		_sPilha += ' ==> ' + procname (_i)
		_i++
	enddo
return _sPilha
