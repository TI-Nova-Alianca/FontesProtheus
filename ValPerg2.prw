// Programa.: ValPerg
// Autor....: Robert Koch
// Data.....: 15/09/2005
// Descricao: Cria e atualiza perguntas no SX1. Recebe como parametro duas arrays,
//            sendo a primeira no mesmo formato do arquivo SX1 e a segunda com as
//            linhas de texto de help de cada pergunta.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #generico
// #Descricao         #Cria e atualiza perguntas no SX1.
// #PalavasChave      #perguntas #perguntas_SX1 
// #TabelasPrincipais #SX1 
// #Modulos           #todos
//
// Historico de alteracoes:
// 08/01/2007 - Robert  - Passa a receber array de perguntas mais simplificada.
// 04/09/2007 - Robert  - Tratamento para reducao no numero de opcoes de uma combo.
// 06/12/2007 - Robert  - Tratamento para aumento de tamanho do X1_GRUPO no Protheus10
// 13/02/2008 - Robert  - Help das perguntas pode ser passado junto com a array de pergundas.
// 19/02/2008 - Robert  - Regrava help, mesmo que esteja vazio.
// 01/06/2010 - Robert  - Criada possibilidade de informar valores default na criacao das perguntas.
// 13/06/2010 - Robert  - Deleta perguntas duplicadas, se encontrar.
// 21/03/2016 - Robert  - Faltava ALLTRIM nas perguntas ao chamar PutSX1Help.
// 27/01/2021 - Robert  - Melhorados logs e inseridas tags para catalogo de fontes.
// 13/05/2021 - Claudia - Recriada a gravação da tabela SX1. GLPI: 8825
//                        Retirada a gravação do help (tabela sem opção de insert XB4)
//
//
// --------------------------------------------------------------------------------------------------
user function ValPerg2 (_cPerg, _aRegsOri, _aHelps, _aRespDef)
	local _aArea     := U_ML_SRArea ()
	local _i         := 0
	local _j         := 0
    local _x         := 0
	local _aRegs     := {}
	local _sSeq      := ""
	local _lNovaPerg := .F.
	local _nRespDef  := 0
    local _nNewPresel:= 0
	
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

			aadd (_aRegs, { _cPerg														, ;  // GRUPO
							strzero (_i, 2)												, ;  // ORDEM
							_aRegsOri [_i, 2]											, ;  // PERGUNT
							_aRegsOri [_i, 2]											, ;  // PERSPA
							_aRegsOri [_i, 2]											, ;  // PERENG
							"mv_ch" + _sSeq												, ;  // VARIAVL
							_aRegsOri [_i, 3]											, ;  // TIPO
							_aRegsOri [_i, 4]											, ;  // TAMANHO
							_aRegsOri [_i, 5]											, ;  // DECIMAL
							0															, ;  // Presel
							iif (len (_aRegsOri [_i, 8]) > 0, "C", "G")					, ;  // GSC
							_aRegsOri [_i, 6]											, ;  // Valid
							"mv_par" + strzero (_i, 2)									, ;  // Var01
							iif (len (_aRegsOri [_i, 8]) >= 1, _aRegsOri [_i, 8, 1], ""), ;  // Opcao 1
							iif (len (_aRegsOri [_i, 8]) >= 1, _aRegsOri [_i, 8, 1], ""), ;  // Opcao 1
							iif (len (_aRegsOri [_i, 8]) >= 1, _aRegsOri [_i, 8, 1], ""), ;  // Opcao 1
							""															, ;  // Cnt01
							""															, ;  // Var02
							iif (len (_aRegsOri [_i, 8]) >= 2, _aRegsOri [_i, 8, 2], ""), ;  // Opcao 2
							iif (len (_aRegsOri [_i, 8]) >= 2, _aRegsOri [_i, 8, 2], ""), ;  // Opcao 2
							iif (len (_aRegsOri [_i, 8]) >= 2, _aRegsOri [_i, 8, 2], ""), ;  // Opcao 2
							""															, ;  // Cnt02
							""															, ;  // Var03
							iif (len (_aRegsOri [_i, 8]) >= 3, _aRegsOri [_i, 8, 3], ""), ;  // Opcao 3
							iif (len (_aRegsOri [_i, 8]) >= 3, _aRegsOri [_i, 8, 3], ""), ;  // Opcao 3
							iif (len (_aRegsOri [_i, 8]) >= 3, _aRegsOri [_i, 8, 3], ""), ;  // Opcao 3
							""															, ;  // Cnt03
							""															, ;  // Var04
							iif (len (_aRegsOri [_i, 8]) >= 4, _aRegsOri [_i, 8, 4], ""), ;  // Opcao 4
							iif (len (_aRegsOri [_i, 8]) >= 4, _aRegsOri [_i, 8, 4], ""), ;  // Opcao 4
							iif (len (_aRegsOri [_i, 8]) >= 4, _aRegsOri [_i, 8, 4], ""), ;  // Opcao 4
							""															, ;  // Cnt04
							""															, ;  // Var05
							iif (len (_aRegsOri [_i, 8]) >= 5, _aRegsOri [_i, 8, 5], ""), ;  // Opcao 5
							iif (len (_aRegsOri [_i, 8]) >= 5, _aRegsOri [_i, 8, 5], ""), ;  // Opcao 5
							iif (len (_aRegsOri [_i, 8]) >= 5, _aRegsOri [_i, 8, 5], ""), ;  // Opcao 5
							""															, ;  // Cnt05
							_aRegsOri [_i, 7]											, ;  // F3
							""															, ;  // PYME
                            ""                                                          , ;  // GRPSXG
                            ""                                                          , ;  // HELP
                            ""                                                          , ;  // PICTURE
                            ""                                                          })   // IDFIL
			
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

	for _i := 1 to Len(_aRegs)

		_oSQL  := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += "     X1_GRUPO "
		_oSQL:_sQuery += "    ,X1_ORDEM "
		_oSQL:_sQuery += "    ,X1_PRESEL"
		_oSQL:_sQuery += " FROM SX1010  "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND X1_GRUPO = '" + _cPerg         + "'"
		_oSQL:_sQuery += " AND X1_ORDEM = '" + _aRegs [_i, 2] + "'"
		_aSX1 := aclone (_oSQL:Qry2Array ())	

		if Len(_aSX1) > 0
			_lNovaPerg := .F.

            _sGrupo    := _aSX1[1, 1]
            _sOrdem    := _aSX1[1, 2]
            _nPresel   := _aSX1[1, 3]

            _oSQL  := ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " SELECT"
            _oSQL:_sQuery += " 		COLUMN_NAME "
            _oSQL:_sQuery += " FROM INFORMATION_SCHEMA.COLUMNS"
            _oSQL:_sQuery += " WHERE TABLE_NAME = 'SX1010'"
            _oSQL:_sQuery += " AND COLUMN_NAME NOT IN ('D_E_L_E_T_', 'R_E_C_N_O_', 'R_E_C_D_E_L_')"
            _oSQL:_sQuery += " ORDER BY ORDINAL_POSITION "
            _aColunas := aclone (_oSQL:Qry2Array ())

            for _j := 1 to len(_aColunas)
                // Campos CNT nao sao gravados para preservar conteudo anterior.
                if _j <= Len(_aRegs[_i]) .and. left(_aColunas[_j,1], 6) != "X1_CNT" .and. _aColunas[_j,1] != "X1_PRESEL"
                    
                    _oSQL  := ClsSQL ():New ()
                    _oSQL:_sQuery := ""
                    if alltrim(_aColunas[_j, 1]) $ 'X1_TAMANHO/X1_DECIMAL/X1_PRESEL'
                        _oSQL:_sQuery += " UPDATE SX1010 SET " + alltrim(_aColunas[_j,1]) + " =  " + cvaltochar(_aRegs[_i, _j])
                    else
                        _oSQL:_sQuery += " UPDATE SX1010 SET " + _aColunas[_j,1] + " = '" + _aRegs[_i, _j]       + "'"
                    endif
                    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
                    _oSQL:_sQuery += " AND X1_GRUPO = '" + _cPerg         + "'"
                    _oSQL:_sQuery += " AND X1_ORDEM = '" + _aRegs [_i, 2] + "'"
                    _oSQL:Exec ()
                endif
            next

            if _aRegs [_i, 11] == "C"

                if _nPresel == 5 .and. empty(_aRegs [_i, 34])
                    _nNewPresel := 4
                endif
                if _nPresel == 4 .and. empty(_aRegs [_i, 29])
                    _nNewPresel := 3
                endif
                if _nPresel == 3 .and. empty(_aRegs [_i, 24])
                    _nNewPresel := 2
                endif
                if _nPresel == 2 .and. empty(_aRegs [_i, 19])
                    _nNewPresel := 1
                endif
            endif

            _oSQL  := ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " UPDATE SX1010 SET X1_PRESEL = " + cvaltochar(_nNewPresel) + ""
            _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
            _oSQL:_sQuery += " AND X1_GRUPO = '" + _cPerg         + "'"
            _oSQL:_sQuery += " AND X1_ORDEM = '" + _aRegs [_i, 2] + "'"
            _oSQL:Exec ()

            // Se for uma nova pergunta, verifica necessidade de gravar valores default
            _nRespDef = ascan (_aRespDef, {|_aVal| _aVal [1] == _sOrdem})
			if _nRespDef > 0
				U_GravaSX1 (_cPerg, _aRespDef [_nRespDef, 1], _aRespDef [_nRespDef, 2])
			endif

		else
			_lNovaPerg := .T.
            _sGrupo    := _cPerg
            _sOrdem    := _aRegs [_i, 2]
            _nPresel   := 0

            GrvNovoReg(_i, _aRegs)
		endif
	next
	
	// Deleta do SX1 as perguntas que nao constam em _aRegs
    _oSQL  := ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += "    X1_ORDEM "
    _oSQL:_sQuery += " FROM SX1010  "
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " AND X1_GRUPO = '" + _cPerg + "'"
    _aOrd := aclone (_oSQL:Qry2Array ())

    for _x:= 1  to Len(_aOrd)
        if ascan (_aRegs, {|_aVal| _aVal [2] == _aOrd[_x, 1]}) == 0
            _oSQL  := ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " UPDATE SX1010 SET D_E_L_E_T_ = '*' "
            _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
            _oSQL:_sQuery += " AND X1_GRUPO = '" + _cPerg       + "'"
            _oSQL:_sQuery += " AND X1_ORDEM = '" + _aOrd[_x, 1] + "'"
            _oSQL:Exec ()
        endif

        // Gera helps das perguntas
        //GravaHelp(_cPerg, _aOrd[_x, 1], _aHelps)
    next

	U_ML_SRArea (_aArea)
Return
//
// ------------------------------------------------------------------------------------
// Grava registro novo
Static Function GrvNovoReg(_i, _aRegs)
    _oSQL  := ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT MAX(R_E_C_N_O_) + 1 FROM SX1010 "
    _aRECNO := aclone (_oSQL:Qry2Array ())

    If Len(_aRECNO) > 0
        _nR_E_C_N_O_ := _aRECNO[1,1]	
    Endif

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " INSERT INTO [dbo].[SX1010] "
    _oSQL:_sQuery += "            ([X1_GRUPO]"      // 01
    _oSQL:_sQuery += "            ,[X1_ORDEM]"      // 02
    _oSQL:_sQuery += "            ,[X1_PERGUNT]"    // 03
    _oSQL:_sQuery += "            ,[X1_PERSPA]"     // 04
    _oSQL:_sQuery += "            ,[X1_PERENG]"     // 05
    _oSQL:_sQuery += "            ,[X1_VARIAVL]"    // 06
    _oSQL:_sQuery += "            ,[X1_TIPO]"       // 07
    _oSQL:_sQuery += "            ,[X1_TAMANHO]"    // 08
    _oSQL:_sQuery += "            ,[X1_DECIMAL]"    // 09
    _oSQL:_sQuery += "            ,[X1_PRESEL]"     // 10
    _oSQL:_sQuery += "            ,[X1_GSC]"        // 11
    _oSQL:_sQuery += "            ,[X1_VALID]"      // 12
    _oSQL:_sQuery += "            ,[X1_VAR01]"      // 13
    _oSQL:_sQuery += "            ,[X1_DEF01]"      // 14
    _oSQL:_sQuery += "            ,[X1_DEFSPA1]"    // 15
    _oSQL:_sQuery += "            ,[X1_DEFENG1]"    // 16
    _oSQL:_sQuery += "            ,[X1_CNT01]"      // 17
    _oSQL:_sQuery += "            ,[X1_VAR02]"      // 18
    _oSQL:_sQuery += "            ,[X1_DEF02]"      // 19
    _oSQL:_sQuery += "            ,[X1_DEFSPA2]"    // 20
    _oSQL:_sQuery += "            ,[X1_DEFENG2]"    // 21
    _oSQL:_sQuery += "            ,[X1_CNT02]"      // 22
    _oSQL:_sQuery += "            ,[X1_VAR03]"      // 23
    _oSQL:_sQuery += "            ,[X1_DEF03]"      // 24
    _oSQL:_sQuery += "            ,[X1_DEFSPA3]"    // 25
    _oSQL:_sQuery += "            ,[X1_DEFENG3]"    // 26
    _oSQL:_sQuery += "            ,[X1_CNT03]"      // 27
    _oSQL:_sQuery += "            ,[X1_VAR04]"      // 28
    _oSQL:_sQuery += "            ,[X1_DEF04]"      // 29
    _oSQL:_sQuery += "            ,[X1_DEFSPA4]"    // 30
    _oSQL:_sQuery += "            ,[X1_DEFENG4]"    // 31
    _oSQL:_sQuery += "            ,[X1_CNT04]"      // 32
    _oSQL:_sQuery += "            ,[X1_VAR05]"      // 33
    _oSQL:_sQuery += "            ,[X1_DEF05]"      // 34
    _oSQL:_sQuery += "            ,[X1_DEFSPA5]"    // 35
    _oSQL:_sQuery += "            ,[X1_DEFENG5]"    // 36
    _oSQL:_sQuery += "            ,[X1_CNT05]"      // 37
    _oSQL:_sQuery += "            ,[X1_F3]"         // 38
    _oSQL:_sQuery += "            ,[X1_PYME]"       // 39
    _oSQL:_sQuery += "            ,[X1_GRPSXG]"     // 40
    _oSQL:_sQuery += "            ,[X1_HELP]"       // 41
    _oSQL:_sQuery += "            ,[X1_PICTURE]"    // 42
    _oSQL:_sQuery += "            ,[X1_IDFIL]"      // 43
    _oSQL:_sQuery += "            ,[D_E_L_E_T_]"    // 44
    _oSQL:_sQuery += "            ,[R_E_C_N_O_]"    // 45
    _oSQL:_sQuery += "            ,[R_E_C_D_E_L_])" // 46
    _oSQL:_sQuery += "      VALUES "
    _oSQL:_sQuery += "            ("
    _oSQL:_sQuery += "             '" + _aRegs[_i, 1] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i, 2] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i, 3] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i, 4] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i, 5] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i, 6] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i, 7] + "'"
    _oSQL:_sQuery += "            , " + cvaltochar(_aRegs[_i, 8])
    _oSQL:_sQuery += "            , " + cvaltochar(_aRegs[_i, 9])
    _oSQL:_sQuery += "            , " + cvaltochar(_aRegs[_i,10])
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,11] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,12] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,13] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,14] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,15] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,16] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,17] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,18] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,19] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,20] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,21] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,22] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,23] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,24] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,25] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,26] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,27] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,28] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,29] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,30] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,31] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,32] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,33] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,34] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,35] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,36] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,37] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,38] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,39] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,40] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,41] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,42] + "'"
    _oSQL:_sQuery += "            ,'" + _aRegs[_i,43] + "'"
    _oSQL:_sQuery += "            ,'' "
    _oSQL:_sQuery += "            , " + cvaltochar(_nR_E_C_N_O_) + " "
    _oSQL:_sQuery += "            ,0)"
    _oSQL:Exec ()

Return
// //
// // ------------------------------------------------------------------------------------
// // Grava Help
// Static Function GravaHelp(_cPerg, _cOrd, _aHelps)
//     local cKey := ""
//     local _i   := 0

//     cKey := "P." + AllTrim(_cPerg) + AllTrim(_cOrd) + "." 
//     lExisteHelp := VerifHelp(cKey)

//     for _i := 1 to Len (_aHelps)
//         if lExisteHelp == .T.  // update
//             _oSQL  := ClsSQL ():New ()
//             _oSQL:_sQuery := ""
//             _oSQL:_sQuery += " UPDATE XB4"
//             _oSQL:_sQuery += " SET XB4_TIPO   = 'P'"
//             _oSQL:_sQuery += "    ,XB4_HELP   = '" + alltrim(_aHelps [_i, 2, 1]) + "'"
//             _oSQL:_sQuery += "    ,XB4_HLP40  = 'N'"
//             _oSQL:_sQuery += "    ,XB4_IDIOMA = 'pt-br'"
//             _oSQL:_sQuery += " FROM XB4"
//             _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
//             _oSQL:_sQuery += " AND XB4_CODIGO   = '" + cKey + "'"
//             _oSQL:Exec ()
//         else            // insert
//             _oSQL  := ClsSQL ():New ()
//             _oSQL:_sQuery := ""
//             _oSQL:_sQuery += " SELECT MAX(R_E_C_N_O_) + 1 FROM XB4 "
//             _aRECNO := aclone (_oSQL:Qry2Array ())

//             If Len(_aRECNO) > 0
//                 _nR_E_C_N_O_ := _aRECNO[1,1]	
//             Endif

//             _oSQL  := ClsSQL ():New ()
//             _oSQL:_sQuery := ""
//             _oSQL:_sQuery += " INSERT INTO [dbo].[XB4]"
//             _oSQL:_sQuery += "            ([XB4_CODIGO]"
//             _oSQL:_sQuery += "            ,[XB4_TIPO]"
//             _oSQL:_sQuery += "            ,[XB4_HLP40]"
//             _oSQL:_sQuery += "            ,[XB4_HELP]"
//             _oSQL:_sQuery += "            ,[XB4_HLPALT]"
//             _oSQL:_sQuery += "            ,[XB4_IDIOMA]"
//             _oSQL:_sQuery += "            ,[D_E_L_E_T_]"
//             _oSQL:_sQuery += "            ,[R_E_C_N_O_]" 
//             _oSQL:_sQuery += "            ,[R_E_C_D_E_L_])"
//             _oSQL:_sQuery += "      VALUES"
//             _oSQL:_sQuery += "            ("
//             _oSQL:_sQuery += "            '" + alltrim(cKey) + "'"
//             _oSQL:_sQuery += "            ,'P' "
//             _oSQL:_sQuery += "            ,'N' "
//             _oSQL:_sQuery += "            ,'" + alltrim(_aHelps [_i, 2]) + "'"
//             _oSQL:_sQuery += "            ,'' "
//             _oSQL:_sQuery += "            ,'pt-br'"
//             _oSQL:_sQuery += "            ,'' "
//             _oSQL:_sQuery += "            , " + cvaltochar(_nR_E_C_N_O_) + " "
//             _oSQL:_sQuery += "            , 0)"
//             _oSQL:Exec ()
//         endif
//     next
// Return
// //
// // ------------------------------------------------------------------------------------
// // Verifica se existe o help
// Static Function VerifHelp(cKey)
//     local _lRet := .F.
//     local _nQtd := 0

//     _oSQL:= ClsSQL ():New ()
//     _oSQL:_sQuery := ""
//     _oSQL:_sQuery += " SELECT "
//     _oSQL:_sQuery += " 	COUNT(*) "
//     _oSQL:_sQuery += " FROM XB4 "
//     _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
//     _oSQL:_sQuery += " AND XB4_CODIGO = '" + cKey + "' "
//     _aHlp := aclone (_oSQL:Qry2Array ())

//     If Len(_aHlp) > 0
//         _nQtd := _aHlp[1,1] 
//     EndIf

//     If _nQtd > 0
//         _lRet := .T.
//     Else
//         _lRet := .F.
//     EndIf
// Return _lRet
