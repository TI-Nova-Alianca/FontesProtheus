// Programa:  ValPerg
// Autor:     Robert Koch
// Data:      15/09/2005
// Descricao: Cria e atualiza perguntas no SX1. Recebe como parametro duas arrays,
//            sendo a primeira no mesmo formato do arquivo SX1 e a segunda com as
//            linhas de texto de help de cada pergunta.
//
// Historico de alteracoes:
// 08/01/2007 - Robert - Passa a receber array de perguntas mais simplificada.
// 04/09/2007 - Robert - Tratamento para reducao no numero de opcoes de uma combo.
// 06/12/2007 - Robert - Tratamento para aumento de tamanho do X1_GRUPO no Protheus10
// 13/02/2008 - Robert - Help das perguntas pode ser passado junto com a array de pergundas.
// 19/02/2008 - Robert - Regrava help, mesmo que esteja vazio.
// 01/06/2010 - Robert - Criada possibilidade de informar valores default na criacao das perguntas.
// 13/06/2010 - Robert - Deleta perguntas duplicadas, se encontrar.
// 21/03/2016 - Robert - Faltava ALLTRIM nas perguntas ao chamar PutSX1Help.
// 27/01/2021 - Robert - Melhorados logs e inseridas tags para catalogo de fontes.
//

// --------------------------------------------------------------------------
user function ValPerg (_cPerg, _aRegsOri, _aHelps, _aRespDef)
	local _aArea     := U_ML_SRArea ()
	local _i         := 0
	local _j         := 0
	local _aRegs     := {}
	local _sSeq      := ""
	local _lNovaPerg := .F.
	local _nRespDef  := 0
	
	// Compatibilidade com versoes antigas. Posso receber a array pronta com todos os campos ou uma mais
	// simples, apenas com os campos importantes. Nesse caso, tenho que montar a array completa.
	if len (_aRegsOri [1]) > 9
		_aRegs := aclone (_aRegsOri)
	else
		_aHelps = {}
		_sSeq := "1"
		for _i = 1 to len (_aRegsOri)
			if _aRegsOri [_i, 1] != _i
				u_help ("Funcao " + procname () + ": Recebi perguntas fora de ordem. Chamado pela funcao " + funname ())
				return
			endif
			aadd (_aRegs, {_cPerg, ;
			strzero (_i, 2), ;
			_aRegsOri [_i, 2], ;
			_aRegsOri [_i, 2], ;
			_aRegsOri [_i, 2], ;
			"mv_ch" + _sSeq, ;
			_aRegsOri [_i, 3], ;
			_aRegsOri [_i, 4], ;
			_aRegsOri [_i, 5], ;
			0, ;  // Presel
			iif (len (_aRegsOri [_i, 8]) > 0, "C", "G"), ;  // GSC
			_aRegsOri [_i, 6], ;  // Valid
			"mv_par" + strzero (_i, 2), ;  // Var01
			iif (len (_aRegsOri [_i, 8]) >= 1, _aRegsOri [_i, 8, 1], ""), ;  // Opcao 1
			iif (len (_aRegsOri [_i, 8]) >= 1, _aRegsOri [_i, 8, 1], ""), ;  // Opcao 1
			iif (len (_aRegsOri [_i, 8]) >= 1, _aRegsOri [_i, 8, 1], ""), ;  // Opcao 1
			"", ;  // Cnt01
			"", ;  // Var02
			iif (len (_aRegsOri [_i, 8]) >= 2, _aRegsOri [_i, 8, 2], ""), ;  // Opcao 2
			iif (len (_aRegsOri [_i, 8]) >= 2, _aRegsOri [_i, 8, 2], ""), ;  // Opcao 2
			iif (len (_aRegsOri [_i, 8]) >= 2, _aRegsOri [_i, 8, 2], ""), ;  // Opcao 2
			"", ;  // Cnt02
			"", ;  // Var03
			iif (len (_aRegsOri [_i, 8]) >= 3, _aRegsOri [_i, 8, 3], ""), ;  // Opcao 3
			iif (len (_aRegsOri [_i, 8]) >= 3, _aRegsOri [_i, 8, 3], ""), ;  // Opcao 3
			iif (len (_aRegsOri [_i, 8]) >= 3, _aRegsOri [_i, 8, 3], ""), ;  // Opcao 3
			"", ;  // Cnt03
			"", ;  // Var04
			iif (len (_aRegsOri [_i, 8]) >= 4, _aRegsOri [_i, 8, 4], ""), ;  // Opcao 4
			iif (len (_aRegsOri [_i, 8]) >= 4, _aRegsOri [_i, 8, 4], ""), ;  // Opcao 4
			iif (len (_aRegsOri [_i, 8]) >= 4, _aRegsOri [_i, 8, 4], ""), ;  // Opcao 4
			"", ;  // Cnt04
			"", ;  // Var05
			iif (len (_aRegsOri [_i, 8]) >= 5, _aRegsOri [_i, 8, 5], ""), ;  // Opcao 5
			iif (len (_aRegsOri [_i, 8]) >= 5, _aRegsOri [_i, 8, 5], ""), ;  // Opcao 5
			iif (len (_aRegsOri [_i, 8]) >= 5, _aRegsOri [_i, 8, 5], ""), ;  // Opcao 5
			"", ;  // Cnt05
			_aRegsOri [_i, 7], ;  // F3
			""})
			
			// Monta array de helps. Se nao foi informado, grava help vazio.
			if len (_aRegsOri [_i]) >= 9 .and. valtype (_aRegsOri [_i, 9]) == "C" .and. ! empty (_aRegsOri [_i, 9])
				aadd (_aHelps, {strzero (_i, 2), aclone (U_QuebraTXT (_aRegsOri [_i, 9], 40))})
			else
				aadd (_aHelps, {strzero (_i, 2), {"."}})
			endif

			_sSeq = soma1 (_sSeq)
		next
	endif
	
	// Verifica perguntas do tipo combo sem opcoes
	For _i := 1 to Len (_aRegs)
		if _aRegs [_i, 11] == "C" .and. empty (_aRegs [_i, 14])
			u_help ("Funcao " + procname () + ": Me foi solicitado que criasse a pergunta " + _aRegs [_i, 2] + " no grupo de perguntas " + _aRegs [_i, 1] + " como 'lista de opcoes', mas nao foi especificada nenhuma opcao. Provavel problema no programa " + funname (),, .T.)
			_aRegs [_i, 14] = "?"
		endif
	next
	
	// Ajusta tamanho do cPerg, pois na versao Protheus10 o tamanho das perguntas aumentou,
	// bem como posso estar executando um programa do P10 em versoes anteriores.
	_cPerg = padr (_cPerg, len (sx1 -> x1_grupo), " ")
	
	DbSelectArea ("SX1")
	DbSetOrder (1)
	For _i := 1 to Len (_aRegs)
		If ! DbSeek (_cPerg + _aRegs [_i, 2])
			//U_Log2 ('debug', 'Inserindo registro no SX1 para >>' + _cPerg + _aRegs [_i, 2] + '<<')
			RecLock ("SX1", .T.)
			_lNovaPerg = .T.
		else
			//U_Log2 ('debug', 'Atualizando registro no SX1 para >>' + _cPerg + _aRegs [_i, 2] + '<<')
			RecLock ("SX1", .F.)
			_lNovaPerg = .F.
		endif
		For _j := 1 to FCount ()
			
			// Campos CNT nao sao gravados para preservar conteudo anterior.
			If _j <= Len (_aRegs [_i]) .and. left (fieldname (_j), 6) != "X1_CNT" .and. fieldname (_j) != "X1_PRESEL"
				FieldPut (_j, _aRegs [_i, _j])
			Endif
		Next
		
		// Se for uma combo, verifica se a opcao atualmente selecionada no SX1 existe entre as opcoes. Isso por que
		// em alguns casos o programador pode fazer uma reducao do numero de opcoes e, se anteriormente estava
		// selecionada uma opcao que nao existe mais, ocorre erro de "array out fo bounds" ao ler as perguntas.
		if _aRegs [_i, 11] == "C"
			if sx1 -> x1_presel == 5 .and. empty (_aRegs [_i, 34])
				sx1 -> x1_presel = 4
			endif
			if sx1 -> x1_presel == 4 .and. empty (_aRegs [_i, 29])
				sx1 -> x1_presel = 3
			endif
			if sx1 -> x1_presel == 3 .and. empty (_aRegs [_i, 24])
				sx1 -> x1_presel = 2
			endif
			if sx1 -> x1_presel == 2 .and. empty (_aRegs [_i, 19])
				sx1 -> x1_presel = 1
			endif
		endif
		MsUnlock ()
		
		// Se for uma nova pergunta, verifica necessidade de gravar valores default
		if _lNovaPerg
			_nRespDef = ascan (_aRespDef, {|_aVal| _aVal [1] == sx1 -> x1_ordem})
			if _nRespDef > 0
				U_GravaSX1 (_cPerg, _aRespDef [_nRespDef, 1], _aRespDef [_nRespDef, 2])
			endif
		endif
		
		// Deleta perguntas duplicadas (existem casos onde execucoes de versoes antigas da
		// rotina de criacao de perguntas as deixaram duplicadas)
		sx1 -> (dbskip ())
		do while ! sx1 -> (eof ()) .and. sx1 -> x1_grupo == _cPerg .and. sx1 -> x1_ordem == _aRegs [_i, 2]
			//u_log2 ('debug', 'Deletando pergunta excedente: ' + sx1 -> x1_ordem)
			reclock ("SX1", .F.)
			dbdelete ()
			msunlock ()
			sx1 -> (dbskip ())
		enddo

	Next
	
	// Deleta do SX1 as perguntas que nao constam em _aRegs
	DbSeek (_cPerg, .T.)
	do while ! eof () .and. x1_grupo == _cPerg
		if ascan (_aRegs, {|_aVal| _aVal [2] == sx1 -> x1_ordem}) == 0
			//u_log2 ('debug', 'Deletando do SX1 as perguntas que nao constam em _sRegs: ' + sx1 -> x1_ordem)
			reclock ("SX1", .F.)
			dbdelete ()
			msunlock ()
		endif
		dbskip ()
	enddo

	// Gera helps das perguntas
	For _i := 1 to Len (_aHelps)
		//PutSX1Help ("P." + _cPerg + _aHelps [_i, 1] + ".", _aHelps [_i, 2], {}, {})
		PutSX1Help ("P." + alltrim (_cPerg) + _aHelps [_i, 1] + ".", _aHelps [_i, 2], {}, {})
	next

	U_ML_SRArea (_aArea)
Return
