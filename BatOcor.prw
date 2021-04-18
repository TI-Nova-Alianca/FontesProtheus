// Programa:   BatOcor
// Autor:      Robert Koch
// Data:       13/11/2019
// Descricao:  Importacao de arquivos do proceda.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Leitura e importacao de arquivos de EDI padrao Mercador/Proceda (ocorrencias entregas NF)
// #PalavasChave      #batch #frete #ocorrencias #proceda #importacao
// #TabelasPrincipais #SZN #SF2 #SF1
// #Modulos           #FAT #OMS

// Historico de alteracoes:
// ??/??/???? - Andre? - Gravacao evento
// 11/03/2021 - Robert - Deleta arquivo quando jah importado.
//                     - Nao fechava arquivos apos a leitura e nao permitia deletar.
// 18/04/2021 - Robert - Importa evento, mesmo que a NF tenha sido cancelada (GLPI 5735).
//                     - Criado tratamento para fretes sobre NF de entrada (GLPI 5735).
//                     - Importa observacoes e texto livre, caso informado (GLPI 5735).
//                     - Criadas tags para catalogo de fontes.
//

// --------------------------------------------------------------------------
user function BatOcor ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _nDir      := 0
	local _aDir      := {}
	local _nLock     := 0
	local _lContinua := .T.
	Local cLinha     := ''
	local _nQtArqImp := 0
	local _nQtArqErr := 0
	local _nQtArqDup := 0

	_oBatch:Retorno = 'S'  // Ateh prova em contrario, retorno = ok

	// Controla acesso via semaforo para evitar chamadas concorrentes, pois a importacao e a exportacao sao
	// agendadas separadamente nas rotinas de batch. A principio, o problema seria apenas a geracao de logs misturados.
	if _lContinua
		_nLock := U_Semaforo (procname () + cEmpAnt + cFilAnt, .F.)
		if _nLock == 0
			u_log2 ('info', "Bloqueio de semaforo.")
			_lContinua = .F.
			_oBatch:Retorno = 'N'
		endif
	endif

	if _lContinua 
		_aDir = Directory ("\PROCEDA\*.TXT")
		_aDir = asort (_aDir,,, {|_x, _y| _x [1] < _y [1]})
		if len (_aDir) == 0
			U_Log2 ('info', 'Nenhum arquivo a importar.')
			_lContinua = .F.
		endif
	endif
	if _lContinua 
		for _nDir = 1 to len (_aDir)
			u_log2 ('info', "Lendo arquivo " + _aDir [_nDir, 1])
			cArq := "\PROCEDA\" + _aDir [_nDir, 1]
			cArqDest := "\PROCEDA\IMPORTADO\" + _aDir [_nDir, 1]
			if file (cArqDest)
				_nQtArqDup ++
				u_log2 ('aviso', "Arquivo " + cArq + " ja importado.")
				// U_Log2 ('debug', 'deletando arquivo >>' + cArq + '<<')
				delete file (cArq)
				loop
			else
				_aDados := {}
				cLinha = ""
				FT_FUSE(cArq)
				ProcRegua(FT_FLASTREC())
				FT_FGOTOP()
				While !FT_FEOF()
					IncProc("Lendo arquivo texto EDI...")
					cLinha = FT_FREADLN() + chr(13) + chr(10)
					AADD (_aDados,cLinha)
					FT_FSKIP()
				EndDo
				FT_FUSE()  // Fecha arquivo
				if _Grava (_aDados) = .T.
					U_Log2 ('debug', 'Funcao _Grava() retornou .T.')
					_nQtArqImp ++
					_Move ("\PROCEDA\" + _aDir [_nDir, 1], "Importado")
				else
					U_Log2 ('debug', 'Funcao _Grava() retornou .F.')
					_nQtArqErr ++
					_Move ("\PROCEDA\" + _aDir [_nDir, 1], "Erro")
				endif
			endif
		next
	endif

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif

	_oBatch:Mensagens += cvaltochar (_nQtArqImp) + ' arq.lidos; ' + cvaltochar (_nQtArqDup) + ' arq.ja importados; ' + cvaltochar (_nQtArqErr) + ' arq.c/erro.'

	U_ML_SRArea (_aAreaAnt)
return (_oBatch:Retorno == 'N')



// --------------------------------------------------------------------------
// Move o arquivo importado para uma subpasta, para evitar nova tentativa de importacao.
Static Function _Move (_sArq, _sDest)
	local _sDrvRmt  := ""
	local _sDirRmt  := ""
	local _sArqRmt  := ""
	local _sExtRmt  := ""
	local _sArqDest := ""

	// Separa drive, diretorio, nome e extensao.
	SplitPath (_sArq, @_sDrvRmt, @_sDirRmt, @_sArqRmt, @_sExtRmt )

	// Cria diretorio, caso nao exista
	makedir (_sDirRmt + _sDest)

	// Copia o arquivo e depois deleta do local original.
	_sArqDest = _sArqRmt
	U_Log2 ('debug', 'Movendo >>' + _sDirRmt + _sArqRmt + _sExtRmt + '<< para >>' + _sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt + '<<')
	copy file (_sDirRmt + _sArqRmt + _sExtRmt) to (_sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt)
	
	if ! file (_sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt)
		u_help ("Erro ao mover arquivo " + _sArqRmt + _sExtRmt,, .t.)
	else
		U_Log2 ('debug', 'Apagando arquivo movido >>' + _sDirRmt + _sArqRmt + _sExtRmt + '<<')
		delete file (_sDirRmt + _sArqRmt + _sExtRmt)
	endif

return

// --------------------------------------------------------------------------
Static Function _Grava (_aDados)
	local _nLinha    := 0
	local _oEvento   := NIL
	local _lRet      := .T.
	local _sTransp   := ''
	local _sOcor     := ''
	local _sDescProc := ''
	local _sSerie    := ''
	local _sNota     := ''
	local _sData     := ''
	local _dData     := ctod ('')
	local _sPedido   := ''
	local _sFilNF    := ''
	local _oSQL      := NIL
	local _sNFEntSai := ''
	local _sHrEvt    := ''
	local _sCodObs   := ''
	local _sTxtLivre := ''

	for _nLinha = 1 to LEN (_aDados)
		// U_Log2 ('debug', 'lendo linha ' + cvaltochar (_nLinha) + ' --> ' + _aDados[_nLinha])
		if _nLinha = 1 .and. substr (_aDados[_nLinha],1,3) != '000'
			u_log ('erro', 'Formato de arquivo invalido.')
			_lRet := .F.
			exit
		endif
		if substr (_aDados[_nLinha],1,3) = '341'
			_sCGC := substr (_aDados[_nLinha],4,14)
			sa4->(dbsetorder(3))
			if ! sa4->(dbseek(xfilial('SA4') + _sCGC,.F.))
				u_help ('CNPJ ' + _sCGC + ' NÃO CADASTRADO COMO TRANSPORTADORA.',, .t.)
				_lRet := .F.
				exit
			else
				_sTransp := sa4->a4_cod
				// U_Log2 ('debug', 'transp: ' + _stransp)
			endif
		endif
		if _lRet .and. substr (_aDados[_nLinha],1,3) = '342'
			if empty (_sTransp)	
				U_Log2 ('erro', 'Encontrei registro tipo 342, mas nao tenho transportadora definida.')
				_lRet := .F.
				exit
			endif
			_sCGC      := substr (_aDados[_nLinha],4,14)
			_sSerie    := substr (_aDados[_nLinha],18,3)
			_sNota     := '0' + substr (_aDados[_nLinha],21,8) // Layout contempla 8 posicoes apenas
			_sOcor     := substr (_aDados[_nLinha],29,2)
			_sData     := substr (_aDados[_nLinha],31,8)
			_dData     := stod (substr (_sData,5,4) + substr (_sData,3,2) + substr (_sData,1,2)) 
			_sHrEvt    := substr (_aDados[_nLinha],39,2) + ':' + substr (_aDados[_nLinha],41,2) + ':00'
			_sCodObs   := substr (_aDados[_nLinha],43,2)
			_sTxtLivre := substr (_aDados[_nLinha],45,70)

			_sDescProc = alltrim (u_retZX5('51',_sOcor,'ZX5_51DESC'))
			if empty (_sDescProc)
				u_log2 ('erro', "Ocorrencia '" + _sOcor + "' nao cadastrada na tabela 51 do ZX5.")
				_lRet := .F.
				exit
			endif
			if _sCodObs == '01'
				_sDescProc += ' Obs: ' + 'Devol/recusa total'
			elseif _sCodObs == '02'
				_sDescProc += ' Obs: ' + 'Devol/recusa parcial'
			elseif _sCodObs == '03'
				_sDescProc += ' Obs: ' + 'Aceite/entrega por acordo'
			endif
			if ! empty (_sTxtLivre)
				_sDescProc += ' Obs: ' + alltrim (_sTxtLivre)
			endif

			// Vou considerar registros deletados por que quero gravar os eventos, mesmo que a nota tenha sido cancelada.
			set deleted off

			if substr (_sCGC,1,8) != substr (sm0->m0_cgc,1,8)
				u_log2 ('info', 'Ocorrencia com CGC de outra empresa.(' + _sCGC + '). Vou verificar se eh nota de entrada.')
				sa2 -> (dbsetorder (3))  // A2_FILIAL, A2_CGC, R_E_C_N_O_, D_E_L_E_T_
				if sa2 -> (dbseek (xfilial ("SA2") + _sCGC, .F.))
					U_Log2 ('info', 'CGC cadastrado como fornecedor: ' + sa2 -> a2_cod)
					_sFilNF = cFilAnt  // Por enquanto vou assumir que fretes sobre entradas sejam destinados a matriz (ainda nao achei onde pegar isso no arq.ocorrencias)
					_sNFEntSai = 'E'  // Frete sobre NF de entrada.
					sf1 -> (dbsetorder (1))  // F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO, R_E_C_N_O_, D_E_L_E_T_
					if ! sf1->(dbseek(_sFilNF + _sNota + _sSerie + sa2 -> a2_cod + sa2 -> a2_loja,.F.))
						u_log2 ('erro', "NF de entrada '" + _sNota + '/' + _sSerie + "' nao encontrada.")
						_lRet := .F.
						exit
					endif
				else
					U_Log2 ('info', 'CGC cadastrado como fornecedor: ' + sa2 -> a2_cod)
					_lRet := .F.
					exit
				endif
			else
				_sNFEntSai = 'S'  // Frete sobre NF de saida.
				if substr (_sCGC,11,2) != cFilAnt
					u_log2 ('info', 'Ocorrencia se refere a NF de outra Filial. CGC: ' + _sCGC)
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += "SELECT M0_CODFIL"
					_oSQL:_sQuery +=  " FROM SYS_COMPANY"
					_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=   " AND M0_CGC  = '" + _sCGC + "'"
					_sFilNF = alltrim (_oSQL:RetQry (1, .F.))
				else
					_sFilNF = cFilAnt
				endif
				sf2->(dbsetorder(1))
				if ! sf2->(dbseek(_sFilNF + _sNota + _sSerie,.F.))
					u_log2 ('erro', "NF de saida '" + _sNota + '/' + _sSerie + "' nao encontrada.")
					_lRet := .F.
					exit
				else
					if _sOcor == '01' .and. empty (sf2 -> f2_vaDtEnt)
						// U_Log2 ('debug', 'atualizando f2_vaDtEnt')
						reclock ("SF2", .f.)
						sf2 -> f2_vaDtEnt = _dDATA
						msunlock ()
					endif

					// Posiciona SD2 para buscar numero do pedido.
					sd2->(dbsetorder(3))
					if sd2->(dbseek(_sFilNF + _sNota + _sSerie,.F.))
						_sPedido := sd2->d2_pedido
					else
						_sPedido := ''
					endif
				endif
			endif

			u_log2 ('info', 'Dt:' + _sData + ' Fil:' + _sFilNF + ' NF(' + _sNFEntSai + '):' + _sNota + ' Ocor:' + _sOcor + ' ' + _sDescProc)

			_oEvento := ClsEvent():new ()
			_oEvento:Filial     = _sFilNF
			_oEvento:Texto      = ALLTRIM(_sDescProc)
			if _sNFEntSai == 'S'
				_oEvento:CodEven    = "SF2009"
				_oEvento:NFSaida    = _sNota
				_oEvento:SerieSaid  = _sSerie
				_oEvento:PedVenda   = _sPedido
				_oEvento:Cliente    = sf2 -> f2_cliente
				_oEvento:LojaCli    = sf2 -> f2_loja
			elseif _sNFEntSai == 'E'
				_oEvento:CodEven    = "SF1009"
				_oEvento:NFEntrada  = _sNota
				_oEvento:SerieEntr  = _sSerie
				_oEvento:Fornece    = sf1 -> f1_fornece
				_oEvento:LojaFor    = sf1 -> f1_loja
			endif
			_oEvento:DtEvento   = _dDATA
			_oEvento:HrEvento   = _sHrEvt // substr (_aDados[_nLinha],39,2) + ':' + substr (_aDados[_nLinha],41,2) 
			_oEvento:CodProceda = _sOcor
			_oEvento:Transp	    = _sTransp
			_oEvento:TranspReds = ''
			// _oEvento:Log ()
			_oEvento:GravaNovo ()

			set deleted on
		endif

		if _lRet .and. substr (_aDados[_nLinha],1,3) = '343'
			U_Log2 ('aviso', 'Nao fiz tratamento para registro tipo 343 (redespacho) por que nao informa a NF a qual se refere.')
		endif

		U_Log2 ('info', '')  // Para gerar linha em branco
	next

Return _lRet
