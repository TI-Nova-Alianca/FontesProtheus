// Programa:  VA_RTSAF
// Autor:     Robert Koch
// Data:      05/10/2020
// Descricao: Rateio custo estocagem cfe. GLPI 8609
//            Criado com base no ESXEST01 de Eduardo Candido (2012)

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Rateio de custos de estocagem e provisao de safra em cima das OPs de consumo de uva.
// #PalavasChave      #rateio #estocagem #provisao_compra_uva
// #TabelasPrincipais #SD3
// #Modulos           #EST

// Historico de alteracoes:
// 15/10/2020 - Robert - Melhorados logs.
//

#XTranslate .CCCodigo        => 1
#XTranslate .CCDescricao     => 2
#XTranslate .CCTipoMovimento => 3
#XTranslate .CCSaldoMO       => 4
#XTranslate .CCSaldoGGF      => 5
#XTranslate .CCSaldoSemGrupo => 6
#XTranslate .CCSaldoTransf   => 7
#XTranslate .CCSaldoApoio    => 8
#XTranslate .CCQtColunas     => 8

// --------------------------------------------------------------------------
User function VA_RTSAF (_lAuto)
	local cCadastro    := "Calculo correcao monetaria conta corrente associados"
	local aSays        := {}
	local aButtons     := {}
	local nOpca        := 0
	local lPerg        := .F.
	_lAuto := iif (_lAuto == NIL, .F., _lAuto)

	if ! u_zzuvl ('103', __cUserId, .T.)
		return
	endif

	Private cPerg := 'VA_RTSAF'
	ValidPerg()
	Pergunte(cPerg, .F.)

	if _lAuto
		nOpca = 1
	else
		nOpca = 0
		AADD(aSays,"Busca os saldos dos CC de receb/processamento e estocagem no mes e faz uma")
		AADD(aSays,"distribuicao desses saldos nas ordens OPs de safra (que consumiram uva).")
		AADD(aSays,"Gera requisicoes de mao de obra com movimentos 300/301/302/... nessas OPs.")
		AADD(aSays,"Adicionalmente pode-se informar valor de compra de safra a provisionar. Esse valor")
		AADD(aSays,"tambem vai ser distribuido nas mesmas OPs atraves do tipo de movimento 304.")
		AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
	 	FormBatch( cCadastro, aSays, aButtons )
	endif
	If nOpca == 1
		processa ({|| _MoveTe ()},"Processando ...")
	Endif
Return



// --------------------------------------------------------------------------
Static Function _TudoOK ()
return .T.



// --------------------------------------------------------------------------
Static Function _MoveTe ()
	local _nSaldo    := 0
	local _sChaveSD3 := "U_VA_RTSAF"
	local _lContinua := .T.
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _aCC       := {}
	local _nCC       := 0
	local _nADistr   := 0
	local _nSldMO    := 0
	local _nSldGGF   := 0
	local _nSldSGru  := 0
	local _nSldTra   := 0
	local _nSldApoio := 0
	local _nOP       := 0
	local _aOP       := {}
	local _nTotLitr  := 0
	local _sUltReqD3 := ''
	local _nCusto1   := 0

	u_logSX1 ()

	_ddfim := dtos(mv_par01)
	_ddini := substr(_ddfim,1,6) + '01'

	// Periodo nao pode estar fechado
	if stod (_ddfim) <= getmv ("MV_ULMES")
		u_help ("Periodo ja encerrado (MV_ULMES).",, .t.)
		_lContinua = .F.
	endif

	PROCREGUA (10)

	if _lContinua
		_oEvento := ClsEvent ():New ()
		_oEvento:Texto := "Iniciando processo de rateio de custo de estocagem"
		_oEvento:CodEven = 'SD3004'
		_oEvento:LeParam (cPerg)
		_oEvento:Grava ()
	endif

	// Monta array com os CC a serem processados, tipo de movimento a gerar para cada um e totais de cada um.
	// Obs.: caso seja alterado algum tipo de movimento aqui, deve-se ajustar os lctos.padrao do grupo 668.
	if _lContinua
		_aCC = {}
		aadd (_aCC, afill (array (.CCQtColunas), 0))
		_aCC [len (_aCC), .CCCodigo]        = cFilAnt + '1101'
		_aCC [len (_aCC), .CCDescricao]     = fBuscaCpo ("CTT", 1, xfilial ("CTT") + _aCC [len (_aCC), .CCCodigo], "CTT_DESC01")
		_aCC [len (_aCC), .CCTipoMovimento] = '300'
		aadd (_aCC, afill (array (.CCQtColunas), 0))
		_aCC [len (_aCC), .CCCodigo]        = cFilAnt + '1102'
		_aCC [len (_aCC), .CCDescricao]     = fBuscaCpo ("CTT", 1, xfilial ("CTT") + _aCC [len (_aCC), .CCCodigo], "CTT_DESC01")
		_aCC [len (_aCC), .CCTipoMovimento] = '301'
		aadd (_aCC, afill (array (.CCQtColunas), 0))
		_aCC [len (_aCC), .CCCodigo]        = cFilAnt + '1201'
		_aCC [len (_aCC), .CCDescricao]     = fBuscaCpo ("CTT", 1, xfilial ("CTT") + _aCC [len (_aCC), .CCCodigo], "CTT_DESC01")
		_aCC [len (_aCC), .CCTipoMovimento] = '302'
		aadd (_aCC, afill (array (.CCQtColunas), 0))
		_aCC [len (_aCC), .CCCodigo]        = cFilAnt + '1202'
		_aCC [len (_aCC), .CCDescricao]     = fBuscaCpo ("CTT", 1, xfilial ("CTT") + _aCC [len (_aCC), .CCCodigo], "CTT_DESC01")
		_aCC [len (_aCC), .CCTipoMovimento] = '303'

		// Linha adicional para o movimento de complemento de compra de uva. Apensar de nao ser um centro
		// de custo, a maioria dos tratamentos neste programa eh igual.
		if mv_par03 > 0
			aadd (_aCC, afill (array (.CCQtColunas), 0))
			_aCC [len (_aCC), .CCCodigo]        = 'PROVISAOUVA'
			_aCC [len (_aCC), .CCDescricao]     = 'PROVISAO COMPRA UVA'
			_aCC [len (_aCC), .CCTipoMovimento] = '304'
			_aCC [len (_aCC), .CCSaldoSemGrupo] = mv_par03 * -1  // Como os CC tem saldo a debito, posteriormente o sinal vai ser invertido.
		endif
		u_log2 ('info', _aCC)
	endif

	// Remove movimentos, se jah existirem
	if _lContinua
		incproc ('Exclusao de movimentos anteriores')
		for _nCC = 1 to len (_aCC)
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "UPDATE " + RetSQLName ("SD3")
			_oSQL:_sQuery += " SET D_E_L_E_T_ = '*'"
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ' '"
			_oSQL:_sQuery +=   " AND D3_FILIAL  = '"  + XFilial("SD3") + "'"
			_oSQL:_sQuery +=   " AND D3_EMISSAO BETWEEN '" + _ddini + "' AND '"  + _ddfim + "'"
			_oSQL:_sQuery +=   " AND D3_TM      = '" + _aCC [_nCC, .CCTipoMovimento] + "'"
			_oSQL:_sQuery +=   " AND D3_VACHVEX = '" + _sChaveSD3 + "'"
			_oSQL:Log ()
			if ! _oSQL:Exec ()
				u_help ('Nao foi possivel limpar movimentos anteriores',, .t.)
				_lContinua = .F.
				exit
			endif
		next
	endif


	// Cria lista de OPs 'de safra' (que consumiram uva).
	if _lContinua
		incproc ('Verificacao OPs de safra')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT CONSUMO.OP, CONSUMO.PROD_FINAL,"
		_oSQL:_sQuery +=       " (SELECT SUM (LITROS)"
		_oSQL:_sQuery +=          " FROM VA_VDADOS_OP PRODUCAO"
		_oSQL:_sQuery +=         " WHERE PRODUCAO.FILIAL = CONSUMO.FILIAL"
		_oSQL:_sQuery +=           " AND PRODUCAO.DATA BETWEEN '" + _ddini + "' AND '"  + _ddfim + "'"
		_oSQL:_sQuery +=           " AND PRODUCAO.OP = CONSUMO.OP"
		_oSQL:_sQuery +=           " AND PRODUCAO.TIPO_MOVTO = 'P') AS PROD_LITROS,"
		_oSQL:_sQuery +=           " 0 AS RAT_ESTOC,"
		_oSQL:_sQuery +=           " 0 AS RAT_SAFRA"
		_oSQL:_sQuery +=  " FROM VA_VDADOS_OP CONSUMO "
		_oSQL:_sQuery += " WHERE CONSUMO.FILIAL = '" + xfilial ("SD3") + "'"
		_oSQL:_sQuery +=   " AND CONSUMO.DATA BETWEEN '" + _ddini + "' AND '"  + _ddfim + "'"
		_oSQL:_sQuery +=   " AND CONSUMO.GRUPO = '0400'"
		_oSQL:_sQuery +=   " AND CONSUMO.TIPO_MOVTO = 'C'"
		_oSQL:_sQuery += " GROUP BY CONSUMO.FILIAL, CONSUMO.OP, CONSUMO.PROD_FINAL"
		_oSQL:Log ()
		_aOP := aclone (_oSQL:Qry2Array ())
		u_log2 ('debug', _aOP)
		if len (_aOP) == 0
			u_help ("Nao foi encontrada nenhuma OP que consumiu uva neste periodo.",, .t.)
			_lContinua = .F.
		else
			// Calcula o total de litragem apontada nas OPs para posterior calculo de proporcionalidade.
			for _nOP = 1 to len (_aOP)
				_nTotLitr += _aOP [_nOP, 3]
			next
		endif
	endif

	// Varre centros de custo a ratear e busca seus saldos.
	if _lContinua
		for _nCC = 1 to len (_aCC)

			// Nao eh um CC, mas fica na array por ter outros tratamentos semelhantes.
			if _aCC [_nCC, .CCCodigo] == 'PROVISAOUVA'
				loop
			endif

			incproc ('Verificacao saldos CC ' + _aCC [_nCC, .CCCodigo])

			// Busca saldo de contas de mao de obra.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT CT1_CONTA"
			_oSQL:_sQuery +=  " FROM " + Retsqlname("CT1") + " CT1"
			_oSQL:_sQuery += " WHERE " + Retsqlcond("CT1")
			_oSQL:_sQuery +=   " AND CT1_GRUPO = '0070'"
			_oSQL:Log ()
			_sAliasQ = _oSQL:Qry2Trb ()
			while !(_sAliasQ)->(eof())
				_nSaldo = MOVCUSTO((_sAliasQ)->CT1_CONTA,_aCC [_nCC, .CCCodigo], stod(_ddini),stod(_ddfim),"01", "1",3)
				if _nSaldo != 0
					u_log2 ('info', 'Saldo encontrado na cta ' + (_sAliasQ)->CT1_CONTA + ' / CC ' + _aCC [_nCC, .CCCodigo] + ': ' + transform (_nSaldo, "@E 999,999,999,999.99"))
				endif 
				_aCC [_nCC, .CCSaldoMO] += _nSaldo 
				(_sAliasQ)->(dbskip())
			enddo
			(_sAliasQ)->(dbclosearea())
		
		
			// Busca movimento de contas de GGF.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT CT1_CONTA"
			_oSQL:_sQuery +=  " FROM " + Retsqlname("CT1") + " CT1"
			_oSQL:_sQuery += " WHERE " + Retsqlcond("CT1")
			_oSQL:_sQuery +=   " AND CT1_GRUPO = '0080'"
			_oSQL:_sQuery +=   " AND CT1_CONTA NOT LIKE '7010110%'"
			_oSQL:Log ()
			_sAliasQ = _oSQL:Qry2Trb ()
			while !(_sAliasQ)->(eof())
				_nSaldo = MOVCUSTO((_sAliasQ)->CT1_CONTA,_aCC [_nCC, .CCCodigo], stod(_ddini),stod(_ddfim),"01", "1",3)
				if _nSaldo != 0
					u_log2 ('info', 'Saldo encontrado na cta ' + (_sAliasQ)->CT1_CONTA + ' / CC ' + _aCC [_nCC, .CCCodigo] + ': ' + transform (_nSaldo, "@E 999,999,999,999.99"))
				endif 
				_aCC [_nCC, .CCSaldoGGF] += _nSaldo 
				(_sAliasQ)->(dbskip())
			enddo
			(_sAliasQ)->(dbclosearea())
		
		
			// Busca movimento de contas sem grupo (nem mao de obra, nem GGF).
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT CT1_CONTA"
			_oSQL:_sQuery +=  " FROM " + Retsqlname ("CT1") + " CT1"
			_oSQL:_sQuery += " WHERE " + Retsqlcond ("CT1")
			_oSQL:_sQuery +=   " AND CT1_GRUPO NOT IN ('0070', '0080', '0110')"
			_oSQL:Log ()
			_sAliasQ = _oSQL:Qry2Trb ()
			while !(_sAliasQ)->(eof())
				_nSaldo = MOVCUSTO((_sAliasQ)->CT1_CONTA,_aCC [_nCC, .CCCodigo], stod(_ddini),stod(_ddfim),"01", "1",3)
				if _nSaldo != 0
					u_log2 ('info', 'Saldo encontrado na cta ' + (_sAliasQ)->CT1_CONTA + ' / CC ' + _aCC [_nCC, .CCCodigo] + ': ' + transform (_nSaldo, "@E 999,999,999,999.99"))
				endif 
				_aCC [_nCC, .CCSaldoSemGrupo] += _nSaldo
				(_sAliasQ)->(dbskip())
			enddo
			(_sAliasQ)->(dbclosearea())
		
		
			// Busca movimento de contas de transferencia de custo de um CC para outro.
			if mv_par02 == 2
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "SELECT CT1_CONTA"
				_oSQL:_sQuery +=  " FROM " + Retsqlname ("CT1") + " CT1"
				_oSQL:_sQuery += " WHERE " + Retsqlcond ("CT1")
				_oSQL:_sQuery +=   " AND CT1_CONTA LIKE '7010110%'"
				_oSQL:Log ()
				_sAliasQ = _oSQL:Qry2Trb ()
				while !(_sAliasQ)->(eof())
					_nSaldo = MOVCUSTO((_sAliasQ)->CT1_CONTA,_aCC [_nCC, .CCCodigo], stod(_ddini),stod(_ddfim),"01", "1",3)
					_aCC [_nCC, .CCSaldoTransf] += _nSaldo
					if _nSaldo != 0
						u_log2 ('info', 'Saldo encontrado na cta ' + (_sAliasQ)->CT1_CONTA + ' / CC ' + _aCC [_nCC, .CCCodigo] + ': ' + transform (_nSaldo, "@E 999,999,999,999.99"))
					endif 
					(_sAliasQ)->(dbskip())
				enddo
				(_sAliasQ)->(dbclosearea())
			endif


			// Busca saldo de contas de apoio.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT CT1_CONTA"
			_oSQL:_sQuery +=  " FROM " + Retsqlname("CT1") + " CT1"
			_oSQL:_sQuery += " WHERE " + Retsqlcond("CT1")
			_oSQL:_sQuery +=   " AND CT1_GRUPO = '0110'"
			_oSQL:Log ()
			_sAliasQ = _oSQL:Qry2Trb ()
			while !(_sAliasQ)->(eof())
				_nSaldo = MOVCUSTO ((_sAliasQ)->CT1_CONTA,_aCC [_nCC, .CCCodigo], stod(_ddini),stod(_ddfim),"01", "1", 3)
				if _nSaldo != 0
					u_log2 ('info', 'Saldo encontrado na cta ' + (_sAliasQ)->CT1_CONTA + ' / CC ' + _aCC [_nCC, .CCCodigo] + ': ' + transform (_nSaldo, "@E 999,999,999,999.99"))
				endif
				_aCC [_nCC, .CCSaldoApoio] += _nSaldo
				(_sAliasQ)->(dbskip())
			enddo
			(_sAliasQ)->(dbclosearea())
		next
		u_log2 ('info', 'Saldos por CC:')
		u_log2 ('info', _aCC)
	endif

	// Confere existencia (e deixa posicionado) do cadastro do produto usado para rateio.
	if _lContinua
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + "MMMSAFRA", .F.))
			u_help ("Produto a ser usado para apropriar o custo nao foi encontrado no cadastro.",, .t.)
			_lContinua = .F.
		endif
	endif


	// Distribui os saldos de cada CC proporcionalmente a litragem produzida por cada OP.
	if _lContinua
		for _nCC = 1 to len (_aCC)
			u_log2 ('info', 'Distribuindo ' + cvaltochar (_nCC) + 'o. CC (' + _aCC [_nCC, .CCCodigo] + ')')

			_nSldMO    = _aCC [_nCC, .CCSaldoMO]
			_nSldGGF   = _aCC [_nCC, .CCSaldoGGF]
			_nSldSGru  = _aCC [_nCC, .CCSaldoSemGrupo]
			_nSldTra   = _aCC [_nCC, .CCSaldoTransf]
			_nSldApoio = _aCC [_nCC, .CCSaldoApoio]
			_nADistr := (_nSldMO + _nSldGGF + _nSldSGru + _nSldTra + _nSldApoio) * -1
			_nSldMO *= -1
			_nSldGGF *= -1
			_nSldSGru *= -1

			U_LOG2 ('INFO', 'Valor a distribuir: ' + cvaltochar (_nADistr))
			if _nADistr > 0

				for _nOP = 1 to len (_aOP)

					// Encontra um movimento de requisicao desta OP para servir como base para replicacao.
					// Replica campos como NUMSEQ e equivalentes para tentar fazer com que
					// o processo de recalculo do custo medio considere estes novos registros.
					_sUltReqD3 := "SELECT TOP 1 *"
					_sUltReqD3 +=  " FROM " + RetSQLName ("SD3") + " SD3 "
					_sUltReqD3 += " WHERE D_E_L_E_T_ = ''"
					_sUltReqD3 +=   " AND D3_FILIAL = '" + xfilial ("SD3") + "'"
					_sUltReqD3 +=   " AND D3_OP = '" + _aOP [_nOP, 1] + "'"
					_sUltReqD3 +=   " AND D3_CF like 'RE%'"

					// Tenta buscar inicialmente uma requisicao de mao de obra
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := _sUltReqD3 + " AND D3_COD like 'MMM%'"
					_oSQL:_sQuery +=   " order by D3_NUMSEQ"
					//_oSQL:Log ()
					_sAliasQ = (_oSQL:Qry2Trb (.T.))
					if (_sAliasQ) -> (eof ())
						u_log2 ('aviso', 'Nao encontrei requisicao de mao de obra na OP ' + alltrim (_aOP [_nOP, 1]) + '. Vou pegar uma outra requisicao qualquer para replicar.')
						_oSQL := ClsSQL ():New ()
						_oSQL:_sQuery := _sUltReqD3
						_oSQL:_sQuery +=   " order by D3_NUMSEQ"
						//_oSQL:Log ()
						_sAliasQ = (_oSQL:Qry2Trb (.T.))
						if (_sAliasQ) -> (eof ())
							u_help ('Nao encontrei nenhuma requisicao na OP ' + alltrim (_aOP [_nOP, 1]) + '. Essa OP nao vai receber rateio.',, .t.)
							loop
						endif
					endif

					_nCusto1 = _aOP [_nOP, 3] * _nADistr / _nTotLitr

					if _nCusto1 > 0
						u_log2 ('info', 'gravando ' + sb1 -> b1_cod + ' na OP ' + (_sAliasQ)->d3_op + ' TM ' + _aCC [_nCC, .CCTipoMovimento] + ' $' + transform (_nCusto1, "@E 999,999,999,999.99999"))
						reclock ("SD3", .T.)
						sd3 -> d3_filial  := xFilial("SD3")
						sd3 -> d3_tm      := _aCC [_nCC, .CCTipoMovimento]
						sd3 -> d3_cod     := sb1 -> b1_cod
						sd3 -> d3_um      := sb1 -> b1_um
						sd3 -> d3_quant   := 0
						sd3 -> d3_custo1  := _nCusto1
						sd3 -> d3_cf      := (_sAliasQ)->d3_cf
						sd3 -> d3_op      := (_sAliasQ)->d3_op
						sd3 -> d3_local   := (_sAliasQ)->d3_local
						sd3 -> d3_doc     := (_sAliasQ)->d3_doc
						sd3 -> d3_emissao := (_sAliasQ)->d3_emissao
						sd3 -> d3_grupo   := sb1 -> b1_grupo
						sd3 -> d3_numseq  := (_sAliasQ)->d3_numseq
						sd3 -> d3_tipo    := sb1 -> b1_tipo
						sd3 -> d3_usuario := CUSERNAME
						sd3 -> d3_chave   := (_sAliasQ)->d3_chave
						sd3 -> d3_ident   := (_sAliasQ)->d3_ident
						sd3 -> d3_vamotiv := "RATEIO CUSTOS " + alltrim (_aCC [_nCC, 2])
						sd3 -> d3_vachvex := _sChaveSD3
						msunlock ()
					else
						u_log2 ('aviso', 'Valor ficaria zerado: ' + sb1 -> b1_cod + ' na OP ' + (_sAliasQ)->d3_op + ' TM ' + _aCC [_nCC, .CCTipoMovimento] + ' $' + transform (_nCusto1, "@E 999,999,999,999.99999"))
					endif

					(_sAliasQ)->(dbclosearea())
					dbselectarea ("SD3")

				next
			endif
		next

	endif

	if ! _lContinua
		u_help ("Processo cancelado.",, .t.)
	else
		u_help ("Processo de rateios finalizado.")
	endif
Return



// --------------------------------------------------------------------------
// Cria perguntas no SX1. Se a pergunta ja existir, atualiza. Se houver mais
// perguntas no SX1 do que as definidas aqui, deleta as excedentes do SX1.
Static Function ValidPerg()
	local _aRegsPerg := {}
	local _aDefaults := {}

	//                     PERGUNT                                 TIPO TAM DEC VALID F3  Opcoes          Help
	aadd (_aRegsPerg, {01, "Ultimo dia mes processamento        ", "D", 8,  0,  "",   "", {},             ""})
	aadd (_aRegsPerg, {02, "Ignora saldo ctas transferenc.      ", "N", 1,  0,  "",   "", {'Sim', 'Nao'}, ""})
	aadd (_aRegsPerg, {03, "Vlr.total a provisionar compra safra", "N", 18, 2,  "",   "", {},             ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
