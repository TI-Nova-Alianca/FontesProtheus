// Programa:  MA330TRB
// Autor:     Robert Koch
// Data:      18/01/2023
// Descricao: P.E. permite alterar sequenciamento custo medio - GLPI 13038

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. permite alterar sequenciamento do calculo do custo medio
// #PalavasChave      #custo_medio #sequenciamento #trb #seq300
// #TabelasPrincipais #SD1 #SD2 #SD3
// #Modulos           #EST

// --------------------------------------------------------------------------
// Segundo documentacao Totvs, obedecer a ordenação:
// DTOS(TRB_DTBASE)+TRB_SEQPRO+TRB_ORDEM+TRB_NIVEL+TRB_NIVSD3+TRB_CHAVE+TRB_SEQ
User Function MA330TRB ()
	local _aAreaAnt := U_ML_SRArea ()
	local _oSQL     := NIL

	// Ajuste especifico para dezembro/2022 (GLPI 13038). Espero nao precisar mais!
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT CASE WHEN "
	_oSQL:_sQuery +=       " (SELECT MIN (TRB_DTORIG)"
	_oSQL:_sQuery +=          " FROM TRB" + cEmpAnt + "SP"
	_oSQL:_sQuery +=          " WHERE TRB_FILIAL != ''"
	_oSQL:_sQuery +=       " ) LIKE '202212%'"
	_oSQL:_sQuery +=       " AND "
	_oSQL:_sQuery +=       " (SELECT MAX (TRB_DTORIG)"
	_oSQL:_sQuery +=          " FROM TRB" + cEmpAnt + "SP"
	_oSQL:_sQuery +=          " WHERE TRB_FILIAL != ''"
	_oSQL:_sQuery +=       " ) LIKE '202212%'"
	_oSQL:_sQuery +=       " THEN 1 ELSE 0 END"
	_oSQL:Log ('[' + procname () + ']')
	if _oSQL:RetQry (1, .f.) == 1
		U_Log2 ('info', '[' + procname () + ']Estou rodando o mes fatidico.')

		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "UPDATE TRB" + cEmpAnt + "SP"
		_oSQL:_sQuery +=       " SET TRB_NIVEL = '99A'"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND TRB_ALIAS    = 'SD3'"
		_oSQL:_sQuery += " AND TRB_CF       = 'RE5'"
		_oSQL:_sQuery += " AND TRB_ORDEM    = '300'"
		_oSQL:_sQuery += " AND EXISTS (SELECT *"
		_oSQL:_sQuery +=               " FROM TRB01SP PAR"
		_oSQL:_sQuery +=              " WHERE PAR.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                " AND PAR.TRB_FILIAL = TRB01SP.TRB_FILIAL"
		_oSQL:_sQuery +=                " AND PAR.TRB_ALIAS  = 'SD1'"
		_oSQL:_sQuery +=                " AND PAR.TRB_TES    = '140'"
		_oSQL:_sQuery +=                " AND PAR.TRB_ORDEM  = '300'"
		_oSQL:_sQuery +=                " AND PAR.TRB_SEQ    = TRB01SP.TRB_SEQ"
		_oSQL:_sQuery +=                " AND PAR.TRB_COD    = TRB01SP.TRB_COD"
		_oSQL:_sQuery +=                " AND PAR.TRB_DOC    = TRB01SP.TRB_DOC)"
		_oSQL:Log ('[' + procname () + ']')
		if ! _oSQL:Exec ()
			U_help ("Erro ao ajustar sequenciamento do calculo. SQL: " + _oSQL:_sQuery)
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
Return
