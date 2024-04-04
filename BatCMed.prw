// Programa:   BatCMed
// Autor:      Robert Koch
// Data:       14/06/2010
// Descricao:  Recalculo do custo medio em batch.
//
// Historico de alteracoes:
// 04/05/2011 - Robert  - Passa a usar a data atual como data limite.
//                      - Contas contabeis a inibir passam a ser de '' a 'ZZZZ...'.
// 11/01/2015 - Robert  - Passa a enviar e-mail de aviso em caso de falha.
// 10/10/2016 - Robert  - Chama a rotina U_CusMed() e nao mais o MATA330() para dar tratamentos adicionais.
// 17/10/2016 - Robert  - Grava mensagens no objeto _oBatch.
// 13/07/2017 - Robert  - Alterado parametro 'calcula mao de obra' para N
// 11/04/2019 - Robert  - Passa a calcular filiais consolidadas (GLPI 5699).
// 18/06/2019 - Robert  - Removido tratamento de nome de arquivo de log (jah vem pronto da rotina que dispara os batches).
// 03/10/2019 - Cláudia - Alterada busca de verificações de <Campo D3_NUMSEQ não pode ter repetição> e <Recursividade>
// 13/02/2020 - Robert  - Eliminadas filiais 05 e 06; acrescentada filial 16.
// 22/05/2020 - Robert  - Parametro 'apagar estornos' mudado de S para N
// 13/08/2021 - Robert  - Alterado parametro 'mov.int.valorizados' de 'depois' para 'antes'.
// 28/03/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

// --------------------------------------------------------------------------
user function BatCMed ()
	local _dDataLim := ctod ("")
	local _oSQL     := NIL
	local _sMsg     := ""
	local _lRet     := .T.
	local _lRecurs  := .F.
	local _aFiliais := {}
//	local _sArqLog2 := iif (type ("_sArqLog") == "C", _sArqLog, "")
//	_sArqLog := procname () + "_EmpFil_" + cNumEmp + ".log"  // U_NomeLog (.t., .f.)
	u_logIni ()
	u_log ("Iniciando em", date (), time ())

	if type ("_oBatch") != 'O'
		_oBatch := ClsBatch ():New ()
	endif

	_dDataLim = dDataBase

	// Monta lista de filiais a serem consideradas no calculo.
	u_log ('Montando lista de filiais')
	dbSelectArea("SM0")
//	u_log ('lendo SM0 da empresa', cEmpAnt)
	dbSeek(cEmpAnt)
	Do While ! Eof() .And. SM0->M0_CODIGO == cEmpAnt
//		u_log ('testando filial >>' + SM0->M0_CODFIL + '<<')
		If alltrim (SM0->M0_CODFIL) $ "01/03/07/08/09/10/11/13/16"
//			u_log ('adicionando filial', SM0->M0_CODFIL)
			Aadd(_aFiliais,{.T., SM0->M0_CODFIL, SM0->M0_filial, SM0->M0_CGC, .F.,})
		EndIf
		dbSkip()
	EndDo
	u_log ('filiais:', _aFiliais)

	//	_aErros := aclone (u_VerCMed (23, _dDataLim))
	//	u_log ('Erros vercmed:', _aErros)
	//	if len (_aErros) > 0

	_oVerif := ClsVerif():New (61) // Campo D3_NUMSEQ não pode ter repetição
	_oVerif:Executa ()
	
	if len (_oVerif:Result) > 1
		_sMsg = "Erro tipo 61 impede o recalculo automatico do custo medio na filial '" + cFilAnt + "'. Execute 'verificacoes custo medio'."
		if type ("oMainWnd") == "O"  // Se tem interface com o usuario
			u_help (_sMsg)
		else
			U_ZZUNU ({'009'}, "Erro recalc.custo medio filial " + cFilAnt, _sMsg)
		endif
		_lRet = .F.
		_oBatch:Mensagens += _sMsg
	endif	
	
	if _lRet
		u_log ('Verificando recursividade')
		//	if len (u_VerCMed (25, _dDataLim)) > 0
		_RecRet := _Recurs()
		if len (_RecRet) > 0
			_sMsg = "Encontrada recursividade na movimentacao. O recalculo automatico do custo medio na filial '" + cFilAnt + "' vai ser executado com a opcao 'gera estrutura pela movimentacao = NAO'."
			if type ("oMainWnd") == "O"  // Se tem interface com o usuario
				u_help (_sMsg)
			endif
			_lRecurs = .T.
		endif
	endif

	u_help ("Foi")
	if _lRet .and. ! empty (_dDataLim)
		cPerg := "MTA330"
		U_GravaSX1 (cPerg, "01", _dDataLim)  // Data limite final
		U_GravaSX1 (cPerg, "02", 2)	// Mostra lctos contabeis: s/n
		U_GravaSX1 (cPerg, "03", 2)	// Aglutina lctos contabeis: s/n
		U_GravaSX1 (cPerg, "04", 1)	// Atualiza arq. movtos: s/n
		U_GravaSX1 (cPerg, "05", 0)	// % aumento MOD
		U_GravaSX1 (cPerg, "06", 2)	// C.C.: contab/extracontab
		U_GravaSX1 (cPerg, "07", '1')  // cta.contabil a inibir de
		U_GravaSX1 (cPerg, "08", '312ZZZZZZZZ')  // cta.contabil a inibir ate
		U_GravaSX1 (cPerg, "09", 2)	// apagar estornos: s/n
		U_GravaSX1 (cPerg, "10", 3)	// gerar lcto contabil: s/n/mantem
		U_GravaSX1 (cPerg, "11", iif (_lRecurs, 2, 1))	// gerar estrut pela movim.: s/n
		U_GravaSX1 (cPerg, "12", 3)	// contab on-line por: consumo/producao/ambas
		U_GravaSX1 (cPerg, "13", 2)	// calcula mao de obra: s/n
		U_GravaSX1 (cPerg, "14", 2)	// metodo apropriacao: sequencial/mensal/diaria
		U_GravaSX1 (cPerg, "15", 1)	// recalc.niveis estrut: s/n
		U_GravaSX1 (cPerg, "16", 1)	// mostra seq. calculo: nao/medio/fifo
		U_GravaSX1 (cPerg, "17", 2)	// seq.processam. fifo: data+seq/medio
		U_GravaSX1 (cPerg, "18", 1)	// mov.int.valorizados:antes/depois
		U_GravaSX1 (cPerg, "19", 2)	// recalc.custos transportes: s/n (aplica-se a conh.frete, para atualizar o custo do produto comprado).
		U_GravaSX1 (cPerg, "20", 3)	// recalc.custos por: todas filiais/corrente/seleciona
		U_GravaSX1 (cPerg, "21", 2)	// custo em partes: s/n
		pergunte (cPerg, .F.)
		u_log ("Executando recalculo do custo medio com os seguintes parametros:")
		U_LogSX1 (cPerg)
		MATA330 (.T., _aFiliais)

		// Procura status de 'processo encerrado' no log do ultimo recalculo do custo medio.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT (*)"
		_oSQL:_sQuery +=   " FROM VA_VSTATUS_CUSTO_MEDIO"
		_oSQL:_sQuery +=  " WHERE EMPRESA = '" + cEmpAnt + "'"
		_oSQL:_sQuery +=    " AND FILIAL  = '" + cFilAnt + "'"
		_oSQL:_sQuery +=    " AND DT_ULT_RECALC != ''"
		u_log (_oSQL:_sQuery)
		_oSQL:F3Array ('Status das filiais')
		u_log (_oSQL:_xRetQry)
		
		if _oSQL:RetQry () == 0
			_sMsg := "O ultimo recalculo automatico do custo medio nao foi finalizado corretamente na filial '" + cFilAnt + "'. Execute-o manualmente e verifique possiveis mensagens."
			_sMsg += "Parametros utilizados:" + chr (13) + chr (10) + U_LogSX1 (cPerg)
			_oBatch:Mensagens += _sMsg
			u_log ('enviando a seguinte msg para os usuarios:', _sMsg)
			if type ("oMainWnd") == "O"  // Se tem interface com o usuario
				u_help (_sMsg)
			else
				U_ZZUNU ({'009'}, "Erro recalc.custo medio filial " + cFilAnt, _sMsg)
			endif
			_lRet = .F.
		endif
	endif

	_oBatch:Retorno = 'S'

	u_logFim ()
return _lRet

// Verifica recursividade na movimentacao.
// Criado com base na funcao MATR331 de Rodrigo de A Sartorio.
static function _Recurs ()
	local _sAliasQ 	:= ""
	local _aListaReg:= {}
	local _aRet 	:= {}
	local _nReg 	:= 0
	local _nx 		:= 0
	local _aCampos 	:= {}
	local _aArqTrb 	:= {}
	local _sAnoMes 	:= substr (dtos (GetMv ("MV_ULMES") + 1), 1, 6)
	
	u_logini ()
	// Cria arquivo de trabalho.
	AADD(_aCampos,{"CODIGO"		,"C",Len(SB1->B1_COD)	,0})
	AADD(_aCampos,{"COMPONENTE"	,"C",Len(SB1->B1_COD)	,0})
	AADD(_aCampos,{"OP"			,"C",Len(SD3->D3_OP)	,0})
	AADD(_aCampos,{"ARMAZEM"	,"C",Len(SD3->D3_LOCAL)	,0})
	AADD(_aCampos,{"MOVIMENTO"	,"C",Len(SD3->D3_TM)	,0})
	AADD(_aCampos,{"EMISSAO"	,"D",8					,0})
	AADD(_aCampos,{"DOCUMENTO"	,"C",Len(SD3->D3_DOC)	,0})
	AADD(_aCampos,{"REGISTRO"	,"N",20					,0})
	AADD(_aCampos,{"G1NIVEL"	,"C",2					,0})
	AADD(_aCampos,{"G1NIVINV"	,"C",2					,0})
	U_ArqTrb ('Cria', '_trb', _aCampos, {'CODIGO+COMPONENTE+OP'}, @_aArqTrb)
	
	// Popula arquivo de trabalho.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT D3_FILIAL,D3_OP,D3_LOCAL,D3_TM,D3_DOC,D3_COD,D3_EMISSAO,SD3.R_E_C_N_O_ SD3RECNO, C2_PRODUTO"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3, "
	_oSQL:_sQuery +=             RetSQLName ("SC2") + " SC2 "
	_oSQL:_sQuery += " WHERE SD3.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SD3.D3_FILIAL  = '" + xfilial ("SD3") + "'"
	_oSQL:_sQuery +=   " AND SD3.D3_ESTORNO != 'S'"
	_oSQL:_sQuery +=   " AND SD3.D3_OP      != ''"
	_oSQL:_sQuery +=   " AND SD3.D3_COD     != 'MANUTENCAO'"
	_oSQL:_sQuery +=   " AND SD3.D3_CF      NOT LIKE 'PR%'"
	_oSQL:_sQuery +=   " AND SD3.D3_EMISSAO BETWEEN '" + _sAnoMes + "01' AND '" + dtos (lastday (stod (_sAnoMes + '01'))) + "'"
	_oSQL:_sQuery +=   " AND SC2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SC2.C2_FILIAL  = SD3.D3_FILIAL"
	_oSQL:_sQuery +=   " AND SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN + SC2.C2_ITEMGRD = SD3.D3_OP"
	_oSQL:_sQuery += " ORDER BY D3_FILIAL,D3_OP,D3_COD,D3_EMISSAO"
	u_log (_oSQL:_sQuery)
	_sAliasQ := _oSQL:Qry2Trb (.f.)
	
	do while ! (_sAliasQ)->(Eof())
		RecLock('_trb', .T.)
		Replace CODIGO		With (_sAliasQ) -> c2_produto
		Replace COMPONENTE  With (_sAliasQ) -> D3_COD
		Replace OP			With (_sAliasQ) -> D3_OP
		Replace ARMAZEM     With (_sAliasQ) -> D3_LOCAL
		Replace MOVIMENTO   With (_sAliasQ) -> D3_TM 
		Replace EMISSAO     With stod ((_sAliasQ) -> D3_EMISSAO)
		Replace DOCUMENTO   With (_sAliasQ) -> D3_DOC 
		Replace REGISTRO    With (_sAliasQ) -> SD3RECNO
		Replace G1NIVEL     With "01"
		Replace G1NIVINV    With "99"
		MsUnLock()
		(_sAliasQ) -> (dbSkip ())
	End
	
	// Varre com recursividade o arquivo de trabalho
	_trb -> (dbGotop())
	do while ! _trb -> (Eof ())
		// Checa recursividade
		IF _trb -> G1NIVEL == "01"
			_aListaReg:={}
			if ! _MR331Niv(_trb -> COMPONENTE, _trb -> G1NIVEL, _aListaReg)
				_nReg:=_trb -> (Recno())
				For _nx:=1 to Len(_aListaReg)
					_trb -> (dbGoto (_aListaReg[_nx]))
					aadd (_aRet, {_trb -> componente, _trb -> armazem, _trb -> movimento, _trb -> documento, _trb -> emissao, _trb -> op, _trb -> codigo})
				Next
				_trb -> (dbGoto(_nReg))
			Endif
		EndIf
		_trb -> (dbSkip())
	Enddo
	U_ArqTrb ('FechaTodos',,,, @_aArqTrb)
	u_log (_aRet)
	u_logfim ()
return _aRet

// --------------------------------------------------------------------------
// Acerta os niveis das estruturas no temporario.
// Criado com base na funcao MR331Nivel de Rodrigo de A Sartorio
Static Function _MR331Niv(cComp,cNivel,_aListaReg)
	Local nRec    := Recno()
	Local nSalRec := 0
	Local lRet    := .T.
	Local lEof    := .F.
	Local nAcho   := 0
	Local cSeek   := ""
	
	dbselectarea ('_trb')
	
	If dbSeek(cComp)
		While !Eof() .and. cComp==CODIGO
			nSalRec:=Recno()
			cSeek  := COMPONENTE
			dbSeek(cSeek)	
			lEof := Eof()
			dbGoto(nSalRec)
	
			IF Val(cNivel) >= 98  // Testa Erro de estrutura
				lRet := .F.
			Endif
	
			If Val(cNivel)+1 > Val(G1NIVEL) .and. lRet
				RecLock('_trb',.F.)
				Replace G1NIVEL  With Strzero(Val(cNivel)+1,2)
				Replace G1NIVINV With Strzero(100-Val(G1NIVEL),2,0)
				MsUnLock()
				If !lEof
					lRet := _MR331Niv(COMPONENTE,G1NIVEL,_aListaReg)
				Endif
			Endif	
			
			IF !lRet
				IF Val(cNivel) < 98  // Houve erro (no nivel posterior)
					nAcho  := ASCAN(_aListaReg,nSalRec)
					// Adiciona, na lista, o registro que originou o erro
					If nAcho == 0
						AADD(_aListaReg,nSalRec)
					EndIf
				EndIf		
				Exit
			Endif
			dbSkip()
		End
	EndIf
	_trb->(dbGoto(nRec))
Return(lRet)
