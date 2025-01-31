// Programa.: ESXEST01
// Autor....: Eduardo Candido
// Data.....: 2012
// Descricao: Rateio custo estocagem, recebimento e processamento (ajuste do custo dos produtos VD conforme despesa dos CC)
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Gera entrada de valor em itens tipo VD para agregar custo de estocagem
// #PalavasChave      #rateio #estocagem
// #TabelasPrincipais #SD3
// #Modulos           #EST
//
// Historico de alteracoes:
// 16/05/2013 - Robert  - Criadas mensagens para depuracao.
// 26/08/2013 - Robert  - Passa a gravar campo D3_VACHVEX para controle da rotina.
// 25/10/2013 - Robert  - Passa a somar contas de transferencia separadamente.
// 10/06/2014 - Robert  - Quando o saldo estah credor, passa a assumir zero.
// 11/12/2015 - Robert  - Ajustes para novos CC (nov/2015).
// 15/03/2016 - Robert  - Tratamento para diversos CC.
//                      - Gera TM diferentes para cada CC (vai ser usado retroativo para jan/2016).
//                      - Melhorias diversas.
// 14/04/2016 - Robert  - Mostra o tipo de movimento gerado junto no browse de resultados.
// 16/09/2016 - Robert  - Passa a validar campo B1_AGREGCU na filtragem de produtos a receberem valor.
// 23/12/2016 - Robert  - Desconsidera estoque dos VD abaixo de 0.01 litro.
// 08/04/2019 - Catia   - include TbiConn.ch
// 15/07/2019 - Robert  - Marca SD3 como deletado (antes deletava fisicamente) na remocao de movtos. anteriores.
//                      - Verifica se o periodo encontra-se fechado.
//                      - Grava evento
// 12/11/2019 - Robert  - Valida se o usuario tem acesso a esta rotina.
// 04/12/2019 - Claudia - Quando houver erros no processo, será impressa apenas uma vez a mensagem e finalizado 
//                        o processo, conforme GLPI: 6921
// 21/01/2020 - Robert  - Campos D3_VAMO e D3_VAGGF nao eram consultados e serao excluidos.
// 20/07/2020 - Robert  - Permissao para executar passa a validar acesso 103 e nao mais 069.
//                      - Inseridas tags para catalogacao de fontes
// 11/12/2020 - Robert  - Ignora centros de custo de recebimento e processamento (por enquanto apenas base teste)
//                        por que serao processados pelo VA_RTSAF.TLPP
// 18/01/2021 - Robert  - Verifica parametro MV_DBLQMOV antes de executar.
// 25/01/2021 - Robert  - Incorporadas funcionalidades do VA_RTSAF (rateio recebimento e processamento safra) 
//                        para que fique num unico programa (GLPI 8609)
// 19/03/2021 - Robert  - Faltava tratamento para quando nao houvesse nenhum item em estoque que pudesse 
//                        receber o rateio (GLPI 9659).
// 14/05/2021 - Claudia - Retirado o Len(SX1->X1_GRUPO) devido a R27. GLPI: 8825
// 12/03/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
// 15/04/2024 - Robert  - Passa a gravar evento com memoria de calculo (GLPI 15248)
// 30/01/2025 - Claudia - Comentariada a query onde cria array com os produtos do tipo VD 
//                        e seus saldos em estoque na data final do periodo. GLPI: 16791
//
// -----------------------------------------------------------------------------------------------------------
#XTranslate .CCCodigo        => 1
#XTranslate .CCDescricao     => 2
#XTranslate .CCTipoMovimento => 3
#XTranslate .CCSaldoMO       => 4
#XTranslate .CCSaldoGGF      => 5
#XTranslate .CCSaldoSemGrupo => 6
#XTranslate .CCSaldoApoio    => 7
#XTranslate .CCObs           => 8
#XTranslate .CCMetodo        => 9
#XTranslate .CCVlDistribuir  => 10
#XTranslate .CCQtColunas     => 10

User function ESXEST01 (_lAutomat)
	Local cCadastro := "Rateio custo estocagem, recebimento e processamento"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	local _nLock    := 0
	private _lAuto  := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	private _sCodEvtR := 'SD3007'

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if U_ZZUVL ('103', __cUserID, .T.)

		// Controle de semaforo.
		_nLock := U_Semaforo (procname (), .t.)
		if _nLock != 0
			Private cPerg := "ESXEST01"
			_ValidPerg()
			Pergunte(cPerg,.F.)

			if _lAuto != NIL .and. _lAuto
				Processa( { |lEnd| _esxest01a() } )
			else
				AADD(aSays,cCadastro)
				AADD(aSays,"")
				AADD(aSays,"")
				AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
				AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
				AADD(aButtons, { 15,.T.,{|| U_VA_SZNC ('EVENTO', _sCodEvtR)}})
				AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
				FormBatch( cCadastro, aSays, aButtons)
				If nOpca == 1
					Processa( { |lEnd| _esxest01a() } )
				Endif
			endif
		endif
	endif

	// Libera semaforo
	U_Semaforo (_nLock)
Return
//
// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk ()
	local _lRet := .T.
return _lRet
//
// --------------------------------------------------------------------------
// Rotina
Static Function _esxest01a ()
	local _nSaldo    := 0
	local _sChaveSD3 := "U_ESXEST01"
	local _lContinua := .T.
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _aEstq     := {}
	local _nEstq     := 0
	local _nTotEstq  := 0
	local _aCC       := {}
	local _nCC       := 0
	local _aRequis   := {}
	local _aCols     := {}
	local _oEvento   := NIL
	local _aOPSafra  := {}
	local _sMemCalc  := ''

	_sMemCalc  += 'Rateio custos estocagem, recebimento e processamento.' + chr (13) + chr (10)
	_sMemCalc  += U_LogSX1 () + chr (13) + chr (10)

	_ddfim := dtos(mv_par01)
	_ddini := substr(_ddfim,1,6) + '01'

	// Periodo nao pode estar fechado
	if stod (_ddfim) <= getmv ("MV_ULMES")
		u_help ("Periodo ja encerrado (MV_ULMES).",, .t.)
		_lContinua = .F.
	endif

	if _lContinua .and. stod (_ddfim) <= getmv('MV_DBLQMOV',.F.,'20000101')
		u_help ('Processo nao pode rodar com bloqueio de data (MV_DBLQMOV)',, .T.)
		_lContinua = .F.
	endif

	PROCREGUA (10)
	
	// Monta array com os CC a serem processados, tipo de movimento a gerar para cada um e totais de cada um.
	// Obs.: caso seja alterado algum tipo de movimento aqui, deve-se ajustar os lctos.padrao do grupo 668.
	if _lContinua
		_aCC = {}

		aadd (_aCC, afill (array (.CCQtColunas), 0))
		_aCC [len (_aCC), .CCCodigo]        = U_TamFixo (cFilAnt + '1101', tamsx3 ("CTT_CUSTO")[1], ' ')
		_aCC [len (_aCC), .CCDescricao]     = fBuscaCpo ("CTT", 1, xfilial ("CTT") + _aCC [len (_aCC), .CCCodigo], "CTT_DESC01")
		_aCC [len (_aCC), .CCTipoMovimento] = '300'
		_aCC [len (_aCC), .CCObs]           = ''
		_aCC [len (_aCC), .CCMetodo]        = ''
		
		aadd (_aCC, afill (array (.CCQtColunas), 0))
		_aCC [len (_aCC), .CCCodigo]        = U_TamFixo (cFilAnt + '1102', tamsx3 ("CTT_CUSTO")[1], ' ')
		_aCC [len (_aCC), .CCDescricao]     = fBuscaCpo ("CTT", 1, xfilial ("CTT") + _aCC [len (_aCC), .CCCodigo], "CTT_DESC01")
		_aCC [len (_aCC), .CCTipoMovimento] = '301'
		_aCC [len (_aCC), .CCObs]           = ''
		_aCC [len (_aCC), .CCMetodo]        = ''

		aadd (_aCC, afill (array (.CCQtColunas), 0))
		_aCC [len (_aCC), .CCCodigo]        = U_TamFixo (cFilAnt + '1201', tamsx3 ("CTT_CUSTO")[1], ' ')
		_aCC [len (_aCC), .CCDescricao]     = fBuscaCpo ("CTT", 1, xfilial ("CTT") + _aCC [len (_aCC), .CCCodigo], "CTT_DESC01")
		_aCC [len (_aCC), .CCTipoMovimento] = '302'
		_aCC [len (_aCC), .CCObs]           = ''
		_aCC [len (_aCC), .CCMetodo]        = ''

		aadd (_aCC, afill (array (.CCQtColunas), 0))
		_aCC [len (_aCC), .CCCodigo]        = U_TamFixo (cFilAnt + '1202', tamsx3 ("CTT_CUSTO")[1], ' ')
		_aCC [len (_aCC), .CCDescricao]     = fBuscaCpo ("CTT", 1, xfilial ("CTT") + _aCC [len (_aCC), .CCCodigo], "CTT_DESC01")
		_aCC [len (_aCC), .CCTipoMovimento] = '303'
		_aCC [len (_aCC), .CCObs]           = ''
		_aCC [len (_aCC), .CCMetodo]        = ''

		u_log2 ('info', _aCC)
	endif

	// Remove movimentos anteriores, se existirem
	if _lContinua
		incproc ('Exclusao de movimentos anteriores')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "UPDATE " + RetSQLName ("SD3")
		_oSQL:_sQuery += " 		SET D_E_L_E_T_ = '*'"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ' '"
		_oSQL:_sQuery += " 		AND D3_FILIAL  = '"  + XFilial("SD3") + "'"
		_oSQL:_sQuery += " 		AND D3_EMISSAO BETWEEN '" + _ddini + "' AND '"  + _ddfim + "'"
		_oSQL:_sQuery += " 		AND (D3_VACHVEX = '" + _sChaveSD3 + "' or D3_VACHVEX = 'U_VA_RTSAF')"  // programa que vai sair de uso. Eliminar depois de limpar todos os movtos.
		_oSQL:Log ()
		if ! _oSQL:Exec ()
			u_help ('Nao foi possivel limpar movimentos anteriores',, .t.)
			_lContinua = .F.
		endif
	endif

	// Varre centros de custo criados a partir do desmembramento do antigo CC 'cantina'
	// e busca seus saldos.
	if _lContinua
		_sMemCalc += 'FASE 1 - Buscar saldos contabeis por CC' + chr (13) + chr (10)
		for _nCC = 1 to len (_aCC)
			incproc ('Verificacao saldos CC ' + _aCC [_nCC, .CCCodigo])
			_sMemCalc += chr (13) + chr (10)
			_sMemCalc += 'Verificacao saldos do CC ' + _aCC [_nCC, .CCCodigo] + chr (13) + chr (10)

			// Busca saldo de contas de mao de obra.
			_sMemCalc += '   Buscando saldos contas grupo 0070' + chr (13) + chr (10)
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := " SELECT CT1_CONTA"
			_oSQL:_sQuery += " FROM " + Retsqlname("CT1") + " CT1"
			_oSQL:_sQuery += " WHERE " + Retsqlcond("CT1")
			_oSQL:_sQuery += " AND CT1_GRUPO = '0070'"
			_oSQL:Log ()
			_sAliasQ = _oSQL:Qry2Trb (.f.)

			while !(_sAliasQ)->(eof())
				_nSaldo = MOVCUSTO((_sAliasQ)->CT1_CONTA,_aCC [_nCC, .CCCodigo], stod(_ddini),stod(_ddfim),"01", "1",3)
				if _nSaldo != 0
					u_log2 ('info', 'Saldo encontrado na cta ' + (_sAliasQ)->CT1_CONTA + '/ CC' + _aCC [_nCC, .CCCodigo] + ':' + cvaltochar (_nSaldo))
					_sMemCalc += '      Saldo cta. ' + alltrim ((_sAliasQ) -> CT1_CONTA) + ': ' + transform (_nSaldo, '@E 999,999,999,999.99') + chr (13) + chr (10)
				endif 
				_aCC [_nCC, .CCSaldoMO] += _nSaldo 
				(_sAliasQ)->(dbskip())
			enddo
			(_sAliasQ)->(dbclosearea())

			// Busca movimento de contas de GGF.
			_sMemCalc += '   Buscando saldos contas grupo 0080' + chr (13) + chr (10)
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT CT1_CONTA"
			_oSQL:_sQuery +=  " FROM " + Retsqlname("CT1") + " CT1"
			_oSQL:_sQuery += " WHERE " + Retsqlcond("CT1")
			_oSQL:_sQuery +=   " AND CT1_GRUPO = '0080'"
			_oSQL:_sQuery +=   " AND CT1_CONTA NOT LIKE '7010110%'"
			_oSQL:Log ()
			_sAliasQ = _oSQL:Qry2Trb (.f.)

			while !(_sAliasQ)->(eof())
				_nSaldo = MOVCUSTO((_sAliasQ)->CT1_CONTA,_aCC [_nCC, .CCCodigo], stod(_ddini),stod(_ddfim),"01", "1",3)

				if _nSaldo != 0
					u_log2 ('info', 'Saldo encontrado na cta ' + (_sAliasQ)->CT1_CONTA + '/ CC' + _aCC [_nCC, .CCCodigo] + ':' + cvaltochar (_nSaldo))
					_sMemCalc += '      Saldo cta. ' + alltrim ((_sAliasQ) -> CT1_CONTA) + ': ' + transform (_nSaldo, '@E 999,999,999,999.99') + chr (13) + chr (10)
				endif 
				_aCC [_nCC, .CCSaldoGGF] += _nSaldo 
				(_sAliasQ)->(dbskip())
			enddo
			(_sAliasQ)->(dbclosearea())
		
			// Busca saldo de contas de apoio.
			_sMemCalc += '   Buscando saldos contas grupo 0110' + chr (13) + chr (10)
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT CT1_CONTA"
			_oSQL:_sQuery +=  " FROM " + Retsqlname("CT1") + " CT1"
			_oSQL:_sQuery += " WHERE " + Retsqlcond("CT1")
			_oSQL:_sQuery +=   " AND CT1_GRUPO = '0110'"
			_oSQL:Log ()
			_sAliasQ = _oSQL:Qry2Trb (.f.)

			while !(_sAliasQ)->(eof())
				_nSaldo = MOVCUSTO ((_sAliasQ)->CT1_CONTA,_aCC [_nCC, .CCCodigo], stod(_ddini),stod(_ddfim),"01", "1", 3)
				if _nSaldo != 0
					u_log2 ('info', 'Saldo encontrado na cta ' + (_sAliasQ)->CT1_CONTA + '/ CC' + _aCC [_nCC, .CCCodigo] + ':' + cvaltochar (_nSaldo))
					_sMemCalc += '      Saldo cta. ' + alltrim ((_sAliasQ) -> CT1_CONTA) + ': ' + transform (_nSaldo, '@E 999,999,999,999.99') + chr (13) + chr (10)
				endif 
				_aCC [_nCC, .CCSaldoApoio] += _nSaldo 
				(_sAliasQ)->(dbskip())
			enddo
			(_sAliasQ)->(dbclosearea())

			// Busca movimento de contas sem grupo (nem mao de obra, nem GGF).
			_sMemCalc += '   Buscando saldos contas outros grupos' + chr (13) + chr (10)
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT CT1_CONTA"
			_oSQL:_sQuery +=  " FROM " + Retsqlname ("CT1") + " CT1"
			_oSQL:_sQuery += " WHERE " + Retsqlcond ("CT1")
			_oSQL:_sQuery +=   " AND CT1_GRUPO NOT IN ('0070', '0080', '0110')"
			_oSQL:Log ()
			_sAliasQ = _oSQL:Qry2Trb (.f.)

			while !(_sAliasQ)->(eof())
				_nSaldo = MOVCUSTO((_sAliasQ)->CT1_CONTA,_aCC [_nCC, .CCCodigo], stod(_ddini),stod(_ddfim),"01", "1",3)
				if _nSaldo != 0
					u_log2 ('info', 'Saldo encontrado na cta ' + (_sAliasQ)->CT1_CONTA + '/ CC' + _aCC [_nCC, .CCCodigo] + ':' + cvaltochar (_nSaldo))
					_sMemCalc += '      Saldo cta. ' + alltrim ((_sAliasQ) -> CT1_CONTA) + ': ' + transform (_nSaldo, '@E 999,999,999,999.99') + chr (13) + chr (10)
				endif 
				_aCC [_nCC, .CCSaldoSemGrupo] += _nSaldo
				(_sAliasQ)->(dbskip())
			enddo
			(_sAliasQ)->(dbclosearea())

		next
	endif

	// Cria array com os produtos do tipo VD e seus saldos em estoque na data final do periodo.
	// Somente aqueles que nao tem mao de obra na estrutra (os demais custeiam pelo "AO-, GF- e AP-")
	if _lContinua
		_sMemCalc += chr (13) + chr (10)
		_sMemCalc += "Fase 2 - Verificando saldos itens VD em estoque" + chr (13) + chr (10)
		incproc ('Verificacao saldos estoque')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "WITH C AS ("
		_oSQL:_sQuery += "SELECT B2_COD, B2_LOCAL,"
		_oSQL:_sQuery +=       " dbo.VA_SALDOESTQ (SB2.B2_FILIAL, SB2.B2_COD, SB2.B2_LOCAL, '" + _dDFim + "') AS SALDOESTQ"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SB2") + " SB2,"
		_oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1"
		_oSQL:_sQuery += " WHERE SB2.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND SB2.B2_FILIAL   = '"  + XFilial("SB2") + "' "
		_oSQL:_sQuery +=   " AND SB2.B2_COD      = B1_COD "
		_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND SB1.B1_FILIAL   = '"  + XFilial("SB1") + "' "
		_oSQL:_sQuery +=   " AND SB1.B1_TIPO     = 'VD' "
		_oSQL:_sQuery +=   " AND SB1.B1_AGREGCU != '1' "
		//_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT *"
		//_oSQL:_sQuery +=                     " FROM " + RETSQLNAME ("SG1") + " SG1 "
		//_oSQL:_sQuery +=                    " WHERE SG1.D_E_L_E_T_ != '*'"
		//_oSQL:_sQuery +=                      " AND SG1.G1_FILIAL   = '" + xfilial ("SG1") + "'"
		//_oSQL:_sQuery +=                      " AND SG1.G1_COD      = SB1.B1_COD"
		//_oSQL:_sQuery +=                      " AND SG1.G1_INI     <= '" + _dDFim + "'"
		//_oSQL:_sQuery +=                      " AND SG1.G1_FIM     >= '" + _dDFim + "'"
		//_oSQL:_sQuery +=                      " AND SG1.G1_COMP    LIKE 'MMM%'"
		//_oSQL:_sQuery +=                    ")"
		_oSQL:_sQuery += " )"
		_oSQL:_sQuery += " SELECT C.*, SUM (SALDOESTQ) OVER () AS ESTQ_TOT"
		_oSQL:_sQuery +=  " FROM C"
		_oSQL:_sQuery += " WHERE SALDOESTQ > 0.01"  // Evita pegar produtos com saldo muito pequeno
		_oSQL:Log ()
		_sMemCalc += "Query usada para leitura dos estoques: " + _oSQL:_sQuery + chr (13) + chr (10)

		_aEstq = aclone (_oSQL:Qry2Array (.f., .f.))

		if len (_aEstq) == 0
			u_help ("Nao encontrei nenhum item no estoque para onde possam ser distribuidos valores.")
		else
			_nTotEstq = _aEstq [1, 4]
		endif

		u_log2 ('info', 'Estoques:')
		u_log2 ('info', _aEstq)
		_sMemCalc += chr (13) + chr (10)
		_sMemCalc += "Saldos em estoque na data:" + chr (13) + chr (10)
		_sMemCalc += "Produto         Alm     Saldo estq" + chr (13) + chr (10)
		for _nEstq = 1 to len (_aEstq)
			_sMemCalc += _aEstq [_nEstq, 1] + ' '
			_sMemCalc += _aEstq [_nEstq, 2] + '  '
			_sMemCalc += transform (_aEstq [_nEstq, 3], "@E 999,999,999.99") + chr (13) + chr (10)
		next
	endif

	// Cria lista de OPs 'de safra' (que consumiram uva).
	// esta foi a query usada na primeira versao. provavelmente possa ser simplificada
	// para apenas verificar a existencia (ou nao) de OPs de safra.
	if _lContinua
		_sMemCalc += chr (13) + chr (10)
		_sMemCalc += "Fase 3 - Verificando se ha OPs de safra (consumindo uva) neste mes" + chr (13) + chr (10)
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
		_sMemCalc += "Query usada para leitura das OPs de safra: " + _oSQL:_sQuery + chr (13) + chr (10)

		_aOPSafra := aclone (_oSQL:Qry2Array (.f., .f.))
		u_log2 ('info', 'OPs de safra:')
		u_log2 ('info', _aOPSafra)
		_sMemCalc += "Encontrei " + cvaltochar (len (_aOPSafra)) + " OPs de safra." + chr (13) + chr (10)

		if len (_aOPSafra) == 0
			U_Log2 ('info', "Nao foi encontrada nenhuma OP que consumiu uva neste periodo.")
		endif
	endif

	// Define que tratamento vai ser feito para cada CC.
	if _lContinua
		_sMemCalc += chr (13) + chr (10)
		_sMemCalc += "Fase 4 - Verificando como vou tratar cada CC:" + chr (13) + chr (10)
		_sMemCalc += "- Os centros de custo de estocagem (asseptica e normal), por nao terem OPs, "
		_sMemCalc += "nao teriam os seus custos absorvidos em nenhum produto pelo metodo padrao "
		_sMemCalc += "do sistema (consumo de mao de obra em OP). Por isso, vou gerar movimentos "
		_sMemCalc += "de estoque (somente de valor) aumentando o custo dos produtos ali estocados. "
		_sMemCalc += "Posteriormente, um lancamento padrao executado pela rotina de custo medio vai "
		_sMemCalc += "ler esses movimentos e fazer uma saida, zerando os saldos dos centros de custo. "
		_sMemCalc += "Estes movimentos poderao ser encontrados na tabela "
		_sMemCalc += "SD3 filtrando a expressao " + _sChaveSD3 + " no campo D3_VACHVEX." + chr (13) + chr (10)
		_sMemCalc += "- Os centros de custo de recebimento e processamento de uva, se tiverem OPs "
		_sMemCalc += "no periodo, poderao ser tratados como os demais CC produtivos (absorvendo "
		_sMemCalc += "o custo via consumo de mao de obra nas OPs). Se nao for epoca de safra "
		_sMemCalc += "(e, portanto, nao houver OPs nesses CC), usarei o mesmo metodo dos CC de estocagem." + chr (13) + chr (10)
		for _nCC = 1 to len (_aCC)
			_aCC [_nCC, .CCVlDistribuir] = (_aCC [_nCC, .CCSaldoMO] + _aCC [_nCC, .CCSaldoGGF] + _aCC [_nCC, .CCSaldoSemGrupo] + _aCC [_nCC, .CCSaldoApoio]) * -1
			_aCC [_nCC, .CCMetodo] = 'ITEM'  // Inicialmente todos sao 'por item'
			if alltrim (_aCC [_nCC, .CCCodigo]) = cFilAnt + '1101' .or.  alltrim (_aCC [_nCC, .CCCodigo]) = cFilAnt + '1102'
				if len (_aOPSafra) > 0
					_aCC [_nCC, .CCMetodo] = 'OP'
				endif
			endif
		next
	endif
	u_log2 ('info', '_aCC com definicao de como vai ser tratado cada CC:')
	u_log2 ('info', _aCC)

	_sMemCalc += chr (13) + chr (10)
	_sMemCalc += "Resumo dos CC, valores e metodos de distribuicao:" + chr (13) + chr (10)
	_sMemCalc += chr (13) + chr (10)
	_sMemCalc += "CC        Descricao                 TM a gerar             MO            GGF          Apoio         Outros     Vl.a distr  Metodo    Obs" + chr (13) + chr (10)
	for _nCC = 1 to len (_aCC)
		_sMemCalc += _aCC [_nCC, .CCCodigo] + ' '
		_sMemCalc += U_TamFixo (_aCC [_nCC, .CCDescricao], 25) + ' '
		_sMemCalc += _aCC [_nCC, .CCTipoMovimento] + '        '
		_sMemCalc += transform (_aCC [_nCC, .CCSaldoMO], "@E 999,999,999.99") + ' '
		_sMemCalc += transform (_aCC [_nCC, .CCSaldoGGF], "@E 999,999,999.99") + ' '
		_sMemCalc += transform (_aCC [_nCC, .CCSaldoApoio], "@E 999,999,999.99") + ' '
		_sMemCalc += transform (_aCC [_nCC, .CCSaldoSemGrupo], "@E 999,999,999.99") + ' '
		_sMemCalc += transform (_aCC [_nCC, .CCVlDistribuir], "@E 999,999,999.99") + '  '
		_sMemCalc += U_TamFixo (_aCC [_nCC, .CCMetodo], 7, ' ') + ' '
		_sMemCalc += _aCC [_nCC, .CCObs]
		_sMemCalc += chr (13) + chr (10)
	next


	// Distribui os saldos de cada CC
	if _lContinua
		_sMemCalc += chr (13) + chr (10)
		_sMemCalc += "Fase 5 - Distribuicao dos valores" + chr (13) + chr (10)
		lErrAj := .F.
		procregua (len (_aCC) * len (_aEstq))
		for _nCC = 1 to len (_aCC)

			// Nao eh um CC, mas fica na array por ter outros tratamentos semelhantes.
			if _aCC [_nCC, .CCCodigo] == 'PROVISAOUVA'
				loop
			endif

			incproc ('Processando CC ' + _aCC [_nCC, .CCCodigo])
			_sMemCalc += chr (13) + chr (10)
			_sMemCalc += 'Iniciando rateio CC ' + _aCC [_nCC, .CCCodigo] + ' (valor a distribuir: ' + transform (_aCC [_nCC, .CCVlDistribuir], "@E 999,999,999.99") + ')' + chr (13) + chr (10)

			// Para casos de apropriacoes 'por OP' nao preciso gerar movimentos neste programa,
			// pois o custeio vai trabalhar da mesma forma que os outros CC produtivos, com
			// as requisicoes de mao de obra apontadas nas OP;
			if _aCC [_nCC, .CCMetodo] == 'OP'
				U_Log2 ('debug', 'CC ' + _aCC [_nCC, .CCCodigo] + ' vai gerar valores por OP de safra')
				// Como no inicio deste processo (final de 2020/inicio de 2021) estamos gerando retroativo
				// para testes e as OPs de safra nao tinham mao de obra, gero registros, caso nao existam.
				// Para ser honesto, acho que acabarei gerando essa mao de obra sempre automaticamente...
				_VerMOSaf (_aCC [_nCC, .CCCodigo], _aOPSafra, _sChaveSD3, @_sMemCalc)

			// Para casos de apropriacoes 'por item' significa que sao CC que nao possuem requisicao
			// nas OP e preciso gerar, neste programa, movimentos valorizados distribuindo o custo
			// entre os produtos existetes no estoque.
			elseif _aCC [_nCC, .CCMetodo] == 'ITEM'

				U_Log2 ('debug', 'CC ' + _aCC [_nCC, .CCCodigo] + ' vai gerar valores por item')
				u_log2 ('info', 'Valor a distribuir: ' + cvaltochar (_aCC [_nCC, .CCVlDistribuir]))
			
				for _nEstq = 1 to len (_aEstq)
					incproc ('CC ' + alltrim (_aCC [_nCC, .CCCodigo]) + ' - Prod. ' + _aEstq [_nEstq, 1])
					_nQtd = _aEstq [_nEstq, 3]
			
					// Gera, para cada produto, uma movimentacao de custo proporcional a seu estoque.
					_nCusMvTot = round (_nQtd * _aCC [_nCC, .CCVlDistribuir] / _nTotEstq, tamsx3 ('D3_CUSTO1')[2])

					u_log2 ('info', 'Prod. ' + _aEstq [_nEstq, 1] + '  _nCusMvTot: ' + cvaltochar (_nCusMvTot))
					if _nCusMvTot > 0
						_aRequis	:=	{}
						aadd( _aRequis, {"D3_FILIAL",  xFilial("SD3"), NIL})
						aadd( _aRequis, {"D3_TM",      _aCC [_nCC, .CCTipoMovimento], NIL})
						aadd( _aRequis, {"D3_COD",     _aEstq [_nEstq, 1], NIL})
						aadd( _aRequis, {"D3_QUANT",   0, NIL})
						aadd( _aRequis, {"D3_LOCAL",   _aEstq [_nEstq, 2], NIL})
						aadd( _aRequis, {"D3_CUSTO1",  _nCusMvTot, NIL})
						aadd( _aRequis, {"D3_EMISSAO", stod(_ddfim), NIL})
						aadd( _aRequis, {"D3_VACHVEX", _sChaveSD3, NIL})
						aadd( _aRequis, {"D3_VAMOTIV", "RATEIO CUSTOS " + alltrim (_aCC [_nCC, 2]), NIL})

						lMSErroAuto := .f.
						_sErroAuto  := ""
						u_log2 ('info', _aRequis)
						MSExecAuto({|x| MATA240(x)}, _aRequis)

						If lMsErroAuto
							if ! empty (_sErroAuto)
								u_help (_sErroAuto,, .t.)
							endif
							if ! empty (NomeAutoLog ())
								u_help ("Erro ao fazer o ajuste de valor de estoque: " + U_LeErro (memoread (NomeAutoLog ())),, .t.)
								lErrAj := .T.
								Exit
							else
								u_help ("Erro ao fazer o ajuste de valor de estoque",, .t.)
								mostraerro()
							endif
						else
							_sMemCalc += 'Gerado mov.' + sd3 -> d3_tm + ' para o item ' + sd3 -> d3_cod + ' (D3_NUMSEQ=' + sd3 -> d3_numseq + ')' + chr (13) + chr (10)
						Endif
					else
						U_Log2 ('debug', '[' + procname () + ']Valor a distribuir zerado ou negativo! Nao vou gerar movimentacao.')
						_sMemCalc += 'Valor a distribuir zerado ou negativo para o item ' + _aEstq [_nEstq, 1] + ' Nao vou gerar movimentacao.' + chr (13) + chr (10)
					endif
				next
			else
				u_help ("Sem tratamento para metodo de apropriacao '" + _aCC [_nCC, .CCMetodo] + "'.",, .T.)
			endif

			If lErrAj == .T.
				u_help ("Processo cancelado!",, .t.)
				Exit
			EndIf
		next
	endif

	if ! _lContinua
		u_help ("Processo cancelado.",, .t.)
		_sMemCalc = ''
	else
		U_Log2 ('info', 'Resumo das distribuicoes de valores realizadas:')
		U_Log2 ('info', _aCC)
		U_Log2 ('info', 'Processo finalizado.')
		_sMemCalc += 'Processo finalizado.' + chr (13) + chr (10)

		// Mostra resumo em tela.
		_aCols = {}
		aadd (_aCols, {.CCCodigo,        'C.custo',           60, ''})
		aadd (_aCols, {.CCDescricao,     'Descricao',        140, ''})
		aadd (_aCols, {.CCMetodo,        'Metodo',            40, ''})
		aadd (_aCols, {.CCTipoMovimento, 'Tipo movto',        40, ''})
		aadd (_aCols, {.CCSaldoMO,       'Saldo MO',          50, '@E 999,999,999,999.99'})
		aadd (_aCols, {.CCSaldoGGF,      'Saldo GGF',         50, '@E 999,999,999,999.99'})
		aadd (_aCols, {.CCSaldoSemGrupo, 'Saldo sem grupo',   50, '@E 999,999,999,999.99'})
		aadd (_aCols, {.CCSaldoApoio,    'Saldo apoio',       50, '@E 999,999,999,999.99'})
		aadd (_aCols, {.CCVlDistribuir,  'Total distribuido', 50, '@E 999,999,999,999.99'})
		U_F3Array (_aCC, "Valores rateados", _aCols, NIL,  NIL, 'Valores rateados sobre estoque total de ' + cvaltochar (_nTotEstq) + ' litros', '', .T.)

		// Grava evento para posterior historico.
		if ! empty (_sMemCalc)
			_oEvento := ClsEvent():new ()
			_oEvento:CodEven    = _sCodEvtR
			_oEvento:Texto      = _sMemCalc
			_oEvento:Grava ()

			u_log (_sMemCalc)

			// Mostra memoria de calculo em tela (preciso me exibir um pouco, neh?)
			U_ShowMemo (_sMemCalc)

		endif

	endif
Return
//
// --------------------------------------------------------------------------
// No momento em que estou implementando esta rotina, queremos aplicar retroativamente para jan/2020
// e sei que naquela safra nao havia mao de obra nas OP de safra. Entao implementei essa verificacao
// jah com a funcionalidade de incluir um registro de requisicao de MMM. A intencao, depois, eh ter
// essas MMM jah na estrutura das OP de safra.
static function _VerMOSaf (_sCC, _aOP, _sChaveSD3, _sMemCalc)
	local _oSQL      := NIL
	local _nOP       := 0
	local _lContinua := .T.
	local _oEvtOP    := NIL

	// Confere existencia (e deixa posicionado) do cadastro do produto usado para rateio.
	sb1 -> (dbsetorder (1))
	if _lContinua .and. ! sb1 -> (dbseek (xfilial ("SB1") + "MMM" + alltrim (_sCC), .F.))
		u_help ("Produto 'MMM" + alltrim (_sCC) + "' a ser usado para apropriar o custo nao foi encontrado no cadastro.",, .t.)
		_lContinua = .F.
	endif

	if _lContinua
		for _nOP = 1 to len (_aOP)
			_lOPOk = .T.

			// Encontra um movimento de requisicao de mao de obra nesna OP.
			// Ja pega campos necessarios para o caso de precisar criar novo registro.
			_sUltReqD3 := "SELECT TOP 1 D3_CF, D3_OP, D3_LOCAL, D3_DOC, D3_EMISSAO, D3_NUMSEQ, D3_CHAVE, D3_IDENT, D3_TM"
			_sUltReqD3 +=  " FROM " + RetSQLName ("SD3") + " SD3 "
			
			// Em 24/11/2020, sem motivo aparente, o SQL na base teste simplesmente decidiu que nao ia mais usar o indice
			// por OP na SEGUNDA execucao (quando inclui o campo D3_COD) desta query... tentei varias coisas sem sucesso...
			_sUltReqD3 += " with (index (SD30101)) "
		
			_sUltReqD3 += " WHERE D_E_L_E_T_ = ''"
			_sUltReqD3 +=   " AND D3_FILIAL = '" + xfilial ("SD3") + "'"
			_sUltReqD3 +=   " AND D3_OP = '" + _aOP [_nOP, 1] + "'"
			_sUltReqD3 +=   " AND D3_CF like 'RE%'"

			// Tento buscar inicialmente uma requisicao do CC que me interessa.
			U_Log2 ('debug', 'OP ' + _aOP [_nOP, 1] + ' procurando req. do CC ' + _sCC)
			_oSQL:= ClsSQL ():New ()
			_oSQL:_sQuery := _sUltReqD3 + " AND D3_COD = 'MMM" + _sCC + "'"
			_oSQL:_sQuery +=   " order by D3_NUMSEQ"
			_oSQL:Log ()
			_sAliasQ = (_oSQL:Qry2Trb (.T.))

			// Se a OP jah tem requisicao deste CC, nao preciso criar registro novo.
			if (_sAliasQ) -> (eof ())
				U_Log2 ('aviso', 'Nao encontrei requisicao do CC desejado (' + _sCC + ') na OP ' + alltrim (_aOP [_nOP, 1]) + '. Vou pegar uma outra requisicao de mao de obra para replicar.')

				// Tento buscar inicialmente uma requisicao de outra mao de obra.
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := _sUltReqD3 + " AND D3_COD like 'MMM%'"
				_oSQL:_sQuery +=   " order by D3_NUMSEQ"
				_oSQL:Log ()
				_sAliasQ = (_oSQL:Qry2Trb (.T.))

				if (_sAliasQ) -> (eof ())
					U_Log2 ('aviso', 'Nao encontrei requisicao de mao de obra na OP ' + alltrim (_aOP [_nOP, 1]) + '. Vou pegar uma outra requisicao qualquer para replicar.')
					_oSQL:= ClsSQL ():New ()
					_oSQL:_sQuery := _sUltReqD3
					_oSQL:_sQuery +=   " order by D3_NUMSEQ"
					_oSQL:Log ()
					_sAliasQ = (_oSQL:Qry2Trb (.T.))

					if (_sAliasQ) -> (eof ())
						U_help ('Nao encontrei nenhuma requisicao na OP ' + alltrim (_aOP [_nOP, 1]) + '. Essa OP nao vai receber rateio.',, .T.)
						_lOPOk = .F.
					endif
				endif
			endif

			// Replica campos como NUMSEQ e equivalentes para tentar fazer com que
			// o processo de recalculo do custo medio considere estes novos registros.
			if _lOPOk
				u_log2 ('info', 'gravando ' + sb1 -> b1_cod + ' na OP ' + (_sAliasQ)->d3_op)
				reclock ("SD3", .T.)
				sd3 -> d3_filial  := xFilial("SD3")
				sd3 -> d3_tm      := (_sAliasQ)->d3_tm
				sd3 -> d3_cod     := sb1 -> b1_cod
				sd3 -> d3_um      := sb1 -> b1_um
				sd3 -> d3_quant   := _aOP [_nOP, 3]
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
				sd3 -> d3_vamotiv := "RATEIO CUSTOS " + alltrim (_sCC)
				sd3 -> d3_vachvex := _sChaveSD3
				msunlock ()

				// Deixa uma reclamacao para o usuario ir atras de fazer o cadastramento da estrutura.
				U_Log2 ('aviso', "Inseri um registro de requisicao de mao de obra na OP '" + alltrim (_aOP [_nOP, 1]) + "' para poder fazer posterior apropriacao de custos, mas o correto seria que ja tivesse o item 'MMM" + _sCC + "' na estrutura do produto da OP.")
				_sMemCalc += "Inserido M.O. na OP " + alltrim (sd3 -> d3_op) + chr (13) + chr (10)

				// Grava um evento na OP para posterior consulta.
				_oEvtOP := ClsEvent():new ()
				_oEvtOP:CodEven    = 'SC2005'
				_oEvtOP:Texto      = "Inserido registro de requisicao de mao de obra na OP, para poder fazer posterior apropriacao de custos, mas o correto seria que ja tivesse o item 'MMM" + _sCC + "' na estrutura do produto da OP."
				_oEvtOP:Produto    = sd3 -> d3_cod
				_oEvtOP:OP         = sd3 -> d3_op
				_oEvtOP:DiasValid  = 720
				_oEvtOP:Grava ()
			endif

			(_sAliasQ)->(dbclosearea())
			dbselectarea ("SD3")
		next
	endif
return
//
// --------------------------------------------------------------------------
// Cria perguntas no SX1. Se a pergunta ja existir, atualiza. Se houver mais
// perguntas no SX1 do que as definidas aqui, deleta as excedentes do SX1.
// --------------------------------------------------------------------------
Static Function _ValidPerg()
	local _aRegsPerg := {}
	local _aDefaults := {}

	//                     PERGUNT                           TIPO TAM DEC VALID F3  Opcoes          Help
	aadd (_aRegsPerg, {01, "Ultimo dia mes processamento  ", "D", 8,  0,  "",   "", {},             ""})
	aadd (_aDefaults, {"02", 2})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return

