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
// 20/04/2021 - Robert - Campo F2_DtEntr (padrao, mas atualmente vazio) substitui o campo customizado F2_vaDtEntr (GLPI 9884).
// 19/08/2021 - Robert - Gravava F2_DtEntr quando transp.redespacho. O correto eh aguardar entrega final (GLPI 10578).
// 22/10/2022 - Robert - Melhoradas mensagens evento para casos que tem redespacho (GLPI 12660)
//                     - Nao gravava atributo :TranspReds no evento.
// 03/03/2024 - Robert - Chamadas de metodos de ClsSQL() nao recebiam parametros.
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
			U_Log2 ('info', '[' + procname () + ']Lendo arquivo ' + _aDir [_nDir, 1])
			cArq := "\PROCEDA\" + _aDir [_nDir, 1]
			cArqDest := "\PROCEDA\IMPORTADO\" + _aDir [_nDir, 1]
			if file (cArqDest)
				_nQtArqDup ++
				u_log2 ('aviso', "Arquivo " + cArq + " ja importado.")
				// U_Log2 ('debug', 'deletando arquivo >>' + cArq + '<<')
				delete file (cArq)
				loop
			else

				// Faz a leitura de todas as linhas do arquivo para uma array
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
				
				// Move o arquivo para determinada pasta conforme teve ou nao
				// sucesso em interpretar/gravar as informacoes da array
				if _Grava (_aDados) = .T.
					//U_Log2 ('debug', 'Funcao _Grava() retornou .T.')
					_nQtArqImp ++
					_Move ("\PROCEDA\" + _aDir [_nDir, 1], "Importado")
				else
					U_Log2 ('erro', 'Problemas na interpretacao/gravacao dos dados.')
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

	_oBatch:Mensagens += cvaltochar (_nQtArqImp) + ' arq.lidos; ' + cvaltochar (_nQtArqDup) + ' arq.ja importados; ' + cvaltochar (_nQtArqErr) + ' arq.c/probl.'

	U_ML_SRArea (_aAreaAnt)
return (_oBatch:Retorno == 'S')



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
//	U_Log2 ('debug', 'Movendo >>' + _sDirRmt + _sArqRmt + _sExtRmt + '<< para >>' + _sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt + '<<')
	copy file (_sDirRmt + _sArqRmt + _sExtRmt) to (_sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt)
	
	if ! file (_sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt)
		u_help ("Erro ao mover arquivo " + _sArqRmt + _sExtRmt,, .t.)
	else
	//	U_Log2 ('debug', 'Apagando arquivo do local original >>' + _sDirRmt + _sArqRmt + _sExtRmt + '<<')
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
	local _sTrRedesp := ''

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
				u_help ('CNPJ ' + _sCGC + ' N�O CADASTRADO COMO TRANSPORTADORA.',, .t.)
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
			_sTrRedesp := ''

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

			// Vou considerar registros deletados por que quero gravar os
			// eventos da nota, mesmo que ela tenha sido cancelada.
			set deleted off

			if substr (_sCGC,1,8) != substr (sm0->m0_cgc,1,8)
				u_log2 ('aviso', 'Ocorrencia com CGC de outra empresa.(' + _sCGC + '). Vou verificar se eh nota de entrada.')
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
					U_Log2 ('erro', 'CGC NAO cadastrado como fornecedor: ' + sa2 -> a2_cod)
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
					// Posiciona SD2 para buscar numero do pedido.
					sd2->(dbsetorder(3))
					if sd2->(dbseek(_sFilNF + _sNota + _sSerie,.F.))
						_sPedido := sd2->d2_pedido
					else
						_sPedido := ''
					endif

					if _sOcor == '01' .and. empty (sf2 -> f2_DtEntr)
						u_log2 ('info', 'Dt:' + _sData + ' Fil:' + _sFilNF + ' NF(' + _sNFEntSai + '):' + _sNota + ' Ocor:' + _sOcor + ' ' + _sDescProc)
						U_Log2 ('debug', 'Vou comparar f2_redesp >>' + sf2 -> f2_redesp + '<< com _sTransp >>' + _sTransp + '<<')
						if ! empty (sf2 -> f2_redesp) .and. _sTransp != sf2 -> f2_redesp
							_sTrRedesp = sf2 -> f2_redesp
							U_Log2 ('info', 'Ocorrencia de entrega, mas a NF ' + sf2 -> f2_doc + ' tem transportadora de redespacho (' + sf2 -> f2_redesp + ') e, no momento, estou processando a transportadora ' + _sTransp + '. Entendo que nao seja a entrega definitiva.')
						else
							U_Log2 ('debug', 'atualizando f2_vaDtEnt da nota ' + _sNota + ' com ' + dtoc (_dDATA))

							// Grava evento temporario (nao estou descobrindo em que momento este campo eh atualizado)
							_oEvento := ClsEvent():new ()
							_oEvento:Filial     = _sFilNF
							_oEvento:Texto     := 'Atualizando campo F2_DTENTR de ' + dtoc (sf2 -> f2_DtEntr) + ' para ' + dtoc (_dDATA)
							_oEvento:Texto     += ' durante leitura das ocorrencias da transp. ' + _sTransp
							_oEvento:Texto     += ' cod.ocor.: ' + _sOcor
							_oEvento:Texto     += " Pilha: " + U_LogPCham ()
							_oEvento:CodEven    = "DEBUG"
							_oEvento:NFSaida    = _sNota
							_oEvento:SerieSaid  = _sSerie
							_oEvento:Cliente    = sf2 -> f2_cliente
							_oEvento:LojaCli    = sf2 -> f2_loja
							_oEvento:DiasValid = 60  // Manter o evento por alguns dias, depois disso vai ser deletado.
							_oEvento:Grava ()

							reclock ("SF2", .f.)
							sf2 -> f2_DtEntr = _dDATA
							msunlock ()
						endif
					endif

				endif
			endif


			_oEvento := ClsEvent():new ()
			_oEvento:Filial     = _sFilNF
			_oEvento:Texto      = ALLTRIM(_sDescProc)
			if ! empty (_sTrRedesp)
				_oEvento:Texto += '(transp.redespacho: ' + _sTrRedesp + ')'
			endif
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
			_oEvento:Transp     = _sTransp
			_oEvento:TranspReds = _sTrRedesp  // ''
			_oEvento:GravaNovo ()

			set deleted on
		endif

		if _lRet .and. substr (_aDados[_nLinha],1,3) = '343'
			U_Log2 ('aviso', 'Nao fiz tratamento para registro tipo 343 (redespacho) por que nao informa a NF a qual se refere.')
		endif

//		U_Log2 ('info', '')  // Para gerar linha em branco
	next

Return _lRet
