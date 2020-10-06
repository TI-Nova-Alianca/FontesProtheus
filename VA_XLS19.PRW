// Programa...: VA_XLS19
// Autor......: Robert Koch
// Data.......: 25/05/2012
// Descricao..: Exportacao de dados gerais de associados para planilha.
//
// Historico de alteracoes:
// 19/08/2014 - Robert - Incluido parametro de ativos/inativos/ambos.
// 11/09/2014 - Robert - Passa a buscar por codigo e loja base.
//                       Passa a buscar todos os associados, independente de situacao.
// 29/10/2015 - Robert - Incluido campo a2_email.
// 12/11/2015 - Robert - Incluido nucleo do associado.
// 16/11/2015 - Robert - Incluidos parametros para desconsiderar bloqueados' em com 'capital a restituir'.
// 26/01/2016 - Robert - Verifica se o usuario tem acesso pela tabela ZZU.
// 17/03/2017 - Robert - Incluidos CEP e UF.
// 02/09/2017 - Robert - Incluidas diversas colunas e parametros para unificar varios relatorios de associados.
// 02/10/2017 - Robert - Coluna de capital a resgatar passa a ler tag .QtCapTotalResgatesEmAberto.
// 13/03/2018 - Robert - Acrescentados dados de banco, agencia e conta.
// 19/11/2018 - Robert - Passa a buscar nucleo e subnucleo do cadastro de grupos familiares.
//                     - Leitura de patriarca desabilitada (passa a tratar pelo grupo familiar)
// 01/02/2019 - Robert - Criado parametro de data de referencia; passa a usar para todas as leituras e validacoes.
//                     - Criada coluna de total de resgates em aberto na data x resgates em aberto em qualquer data.
// 22/02/2019 - Robert - Removida coluna 'resgates em aberto nesta data'
//                     - Criado parametro 'listar ultima safra'
// 04/02/2020 - Andre  - Adicionado campo A2_VAOBS no relatório.
// 10/08/2020 - Robert - Somente alimentava coluna 'ultima safra' junto com os dados de capital social.
//                     - Inseridas tags para catalogacao de fontes.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Exporta dados gerais de associados para planilha.
// #PalavasChave      #dados_gerais_associados
// #TabelasPrincipais SZI
// #Modulos           #COOP

#include "VA_INCLU.PRW"

// --------------------------------------------------------------------------
User Function VA_XLS19 (_lAutomat)
	Local cCadastro := "Exportacao de dados gerais de associados para planilha"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	Private cPerg   := "VAXLS19"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T.)//, cEmpAnt, cFilAnt)
		return
	endif

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo gerar uma")
		AADD(aSays,"exportacao de dados gerais de associados")
		AADD(aSays,"para planilha eletronica.")
		
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return



// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
	
	
	
// --------------------------------------------------------------------------
Static Function _Gera()
	local _oSQL      := NIL
	local _oAssoc    := NIL
	local _aLinVazia := {}
	local _sInscr    := ""
	local _sAliasQ   := ""
	local _aCotas    := {}
	local _aCampos   := {}
	local _nOcorr	 := 0
	private aHeader  := {}  // Para simular a exportacao de um GetDados.
	private aCols    := {}  // Para simular a exportacao de um GetDados.
	private N        := {}  // Para simular a exportacao de um GetDados.
	private inclui   := .T.  // Para nao reclamar do inicializador padrao em alguns campos virtuais.

	// Se tem algum lancamento no SZI, eh por que foi ou ainda eh associado.
	// Se varrer todo o SA2 ficaria demorado demais para tentar instanciar cada um como associado.
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery += "SELECT A2_COD, A2_LOJA"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SA2") + " SA2 "
	_oSQL:_sQuery += " WHERE SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
	_oSQL:_sQuery +=   " AND SA2.A2_VACBASE + SA2.A2_VALBASE BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
	// PEGA APENAS O CODIGO E LOJA BASE PARA NAO REPETIR O MESMO ASSOCIADO.
	_oSQL:_sQuery +=   " AND SA2.A2_COD = SA2.A2_VACBASE"
	_oSQL:_sQuery +=   " AND SA2.A2_LOJA = SA2.A2_VALBASE"


// BACA TEMPORARIO - ROBERT
//_oSQL:_sQuery +=   " AND SA2.A2_CGC IN ('61866903004','52950816053','54613779049','88959740004','31184707049','62743805072','27720284020','48264652034','91454107049','88812693091','01659397022','56592744049','02688484087','35656948072','50226134091','37057154020','50329367072','70285772015','88281108053','00017544084','06005195034','40141543000','34374345000','94124922000','76131602034','22348093049','58811826004','35841435000','93945868068','99063352972','56418779053','32801262072','89235576920','61917389000','54881455087')"

	_oSQL:_sQuery +=   " AND EXISTS (SELECT *"
	_oSQL:_sQuery +=                 " FROM " + RetSQLName ("SZI") + " SZI "
	_oSQL:_sQuery +=                " WHERE SZI.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                  " AND SZI.ZI_ASSOC   = SA2.A2_COD"
	_oSQL:_sQuery +=                  " AND SZI.ZI_LOJASSO = SA2.A2_LOJA"
	_oSQL:_sQuery +=                  " AND SZI.ZI_DATA   <= '" + dtos (mv_par11) + "')"
	_oSQL:_sQuery += " ORDER BY A2_NOME"
	_sAliasQ = _oSQL:Qry2Trb ()

	if ! (_sAliasQ) -> (eof ())
		procregua ((_sAliasQ) -> (reccount ()))

		_aCampos = {'A2_COD', 'A2_LOJA', 'A2_NOME', 'A2_CGC', 'A2_VACORIG', 'A2_VADTNAS', 'A2_VADTFAL', 'A2_VAFUNC', 'A2_VARG', 'A2_VAOBS'}

		if mv_par07 == 1  // Listar dados de contato
			aadd (_aCampos, 'A2_TEL')
			aadd (_aCampos, 'A2_VACELUL')
			aadd (_aCampos, 'A2_EMAIL')
			aadd (_aCampos, 'A2_END')
			aadd (_aCampos, 'A2_MUN')
			aadd (_aCampos, 'A2_EST')
			aadd (_aCampos, 'A2_CEP')
			aadd (_aCampos, 'A2_VACONJU')
			aadd (_aCampos, 'A2_VACPFCO')
			aadd (_aCampos, 'A2_VACAVIS')
			aadd (_aCampos, 'A2_VALAVIS')
			aadd (_aCampos, 'A2_VANAVIS')
			aadd (_aCampos, 'A2_BANCO')
			aadd (_aCampos, 'A2_AGENCIA')
			aadd (_aCampos, 'A2_NUMCON')
		endif 

		if mv_par08 == 1  // Listar dados referentes a DAP
			aadd (_aCampos, 'A2_VAPOSSE')
			aadd (_aCampos, 'A2_VAAPDAP')
			aadd (_aCampos, 'A2_VANRDAP')
			aadd (_aCampos, 'A2_VAMNDAP')
			aadd (_aCampos, 'A2_VASTDAP')
			aadd (_aCampos, 'A2_VAENDAP')
			aadd (_aCampos, 'A2_VAEMDAP')
			aadd (_aCampos, 'A2_VAVLDAP')
			aadd (_aCampos, 'A2_VAQBDAP') 
		endif

		// Gera aHeader para posterior organizacao e exportacao dos dados.
		aHeader = aclone (U_GeraHead ('SA2', .F., {}, _aCampos, .T.))
		
		aadd (aHeader, {'Nucleo',    'ZAN_NUCLEO', '', 20, 0, '', '', 'C'})
		aadd (aHeader, {'Subnucleo', 'ZAN_SUBNUC', '', 20, 0, '', '', 'C'})

		// Campos gerados.
		if mv_par07 == 1  // Listar dados de contato
			aadd (aHeader, {'Tel.avisador',       'TelAvisad',  '', 14, 0, '', '', 'C'})
		endif
		aadd (aHeader, {'Inscr.est.',         'Inscr',      '', 20, 0, '', '', 'C'})
		aadd (aHeader, {'Data filiacao',      'DtAssoc',    '', 10, 0, '', '', 'D'})
		aadd (aHeader, {'Data saida',         'DtDemis',    '', 10, 0, '', '', 'D'})
		aadd (aHeader, {'Ativo',              'Ativo',      '', 1,  0, '', '', 'C'})
		aadd (aHeader, {'Motivo inativ',      'MotInativ',  '', 30, 0, '', '', 'C'})

		if mv_par10 == 1  // Listar data da ultima safra.
			aadd (aHeader, {'Ultima safra ate ' + dtoc (mv_par11),  'UltSafra',   '', 4,  0, '', '', 'C'})
		endif
		if mv_par06 == 1  // Listar dados relacionados a cotas capitais
			aadd (aHeader, {'Idade em ' + dtoc (mv_par11),          'Idade',      '', 3,  0, '', '', 'N'})
			aadd (aHeader, {'Anos de assoc.em ' + dtoc (mv_par11),  'Anos_Assoc', '', 3,  0, '', '', 'N'})
			aadd (aHeader, {'Capital social em ' + dtoc (mv_par11), 'CapSocial',  '', 18, 2, '', '', 'N'})
			aadd (aHeader, {'Resg.aberto qquer.data',               'TotResgat',  '', 18, 2, '', '', 'N'})
			aadd (aHeader, {'Integraliz em aberto',                 'A_Integral', '', 18, 2, '', '', 'N'})
		endif

		if mv_par09 == 1  // Listar dados do patriarca
			aadd (aHeader, {'Grupo familiar',      'ZAN_COD',    '', 6,  0, '', '', 'C'})
			aadd (aHeader, {'Nome grupo familiar', 'ZAN_DESCRI', '', 60, 0, '', '', 'C'})
		endif

		_aLinVazia = aclone (U_LinVazia (aHeader))

		do while ! (_sAliasQ) -> (eof ())

			// Instancia classe para verificacao dos dados do associado.
			_oAssoc := ClsAssoc():New ((_sAliasQ) -> a2_cod, (_sAliasQ) -> a2_loja)
			incproc (_oAssoc:Nome)

			if mv_par05 == 1
				if ! _oAssoc:EhSocio (mv_par11) .or. ! _oAssoc:Ativo (mv_par11)
					u_log ('Associado', _oAssoc:Codigo, _oAssoc:Loja, 'inativo')
					(_sALiasQ) -> (dbskip ())
					loop
				endif
			endif
			if mv_par05 == 2
				if _oAssoc:EhSocio (mv_par11) .or. _oAssoc:Ativo (mv_par11)
					u_log ('Associado', _oAssoc:Codigo, _oAssoc:Loja, 'ativo')
					(_sALiasQ) -> (dbskip ())
					loop
				endif
			endif

			// Busca dados de cota capital.
			_aCotas = aclone (_oAssoc:SldQuotCap (mv_par11))

			aadd (aCols, aclone (_aLinVazia))
			N = len (aCols)
			GDFieldPut ('A2_VACORIG', _oAssoc:CoopOrigem)
			GDFieldPut ('A2_COD',     _oAssoc:Codigo)
			GDFieldPut ('A2_LOJA',    _oAssoc:Loja)
			GDFieldPut ('A2_NOME',    alltrim (_oAssoc:Nome))
			GDFieldPut ('A2_VADTNAS', _oAssoc:DtNascim)
			GDFieldPut ('A2_VADTFAL', _oAssoc:DtFalecim)
			GDFieldPut ('DtDemis',    _oAssoc:DtSaida (mv_par11))
			GDFieldPut ('DtAssoc',    _oAssoc:DtEntrada (GDFieldGet ('DtDemis')))  // Quando tiver data de saida, busca a entrada correspondente.
			GDFieldPut ('A2_CGC',     _oAssoc:CPF)
			GDFieldPut ('A2_VARG',    _oAssoc:RG)
			GDFieldPut ('A2_VAFUNC',  _oAssoc:FUNCAO)
			//GDFieldPut ('A2_VAOBS',   _oAssoc:OBSERVACAO)
			GDFieldPut ('ZAN_NUCLEO', _oAssoc:Nucleo + ' - ' + alltrim (X3Combo ("ZAN_NUCLEO", _oAssoc:Nucleo)))
			GDFieldPut ('ZAN_SUBNUC', _oAssoc:SubNucleo + ' - ' + alltrim (U_RetZX5("36", _oAssoc:SubNucleo, 'ZX5_36DESC')))
			GDFieldPut ('Ativo',      iif (_oAssoc:Ativo (mv_par11), 'Ativo', 'Inativo'))
			GDFieldPut ('MotInativ',  _oAssoc:MotInativ)

			if mv_par10 == 1
				GDFieldPut ('UltSafra',   _oAssoc:UltSafra (mv_par11))
			endif

			if mv_par06 == 1  // Listar dados relacionados a cotas capitais
				GDFieldPut ('UltSafra',   _oAssoc:UltSafra (mv_par11))
				GDFieldPut ('CapSocial',  _aCotas [.QtCapSaldoNaData])
				GDFieldPut ('TotResgat',  _aCotas [.QtCapTotalResgatesEmAberto])
				GDFieldPut ('A_Integral', _aCotas [.QtCapIntegralizEmAbertoEnquantoSocio])
				GDFieldPut ('Idade',      _oAssoc:IdadeEm (mv_par11))
				GDFieldPut ('Anos_Assoc', _oAssoc:TmpAssoc (mv_par11))
			endif

			if mv_par07 == 1  // Listar dados de contato
				GDFieldPut ('A2_TEL',     alltrim (_oAssoc:Telefone))
				GDFieldPut ('A2_VACELUL', alltrim (_oAssoc:Celular))
				GDFieldPut ('A2_EMAIL',   alltrim (_oAssoc:EMail))
				GDFieldPut ('A2_END',     alltrim (_oAssoc:Endereco))
				GDFieldPut ('A2_MUN',     alltrim (_oAssoc:Municipio))
				GDFieldPut ('A2_EST',     alltrim (_oAssoc:UF))
				GDFieldPut ('A2_CEP',     alltrim (_oAssoc:CEP))
				GDFieldPut ('A2_VACONJU', alltrim (_oAssoc:NomeConju))
				GDFieldPut ('A2_VACPFCO', alltrim (_oAssoc:CPFConju))
				GDFieldPut ('A2_VACAVIS', alltrim (_oAssoc:CodAvisad))
				GDFieldPut ('A2_VALAVIS', alltrim (_oAssoc:LojAvisad))
				GDFieldPut ('A2_BANCO',   fBuscaCpo ("SA2", 1, xfilial ("SA2") + _oAssoc:CodBase + _oAssoc:LojaBase, "A2_BANCO"))
				GDFieldPut ('A2_AGENCIA', fBuscaCpo ("SA2", 1, xfilial ("SA2") + _oAssoc:CodBase + _oAssoc:LojaBase, "A2_AGENCIA"))
				GDFieldPut ('A2_NUMCON',  fBuscaCpo ("SA2", 1, xfilial ("SA2") + _oAssoc:CodBase + _oAssoc:LojaBase, "A2_NUMCON"))
				if ! empty (_oAssoc:CodAvisad)
					GDFieldPut ('A2_VANAVIS', alltrim (fBuscaCpo ("SA2", 1, xfilial ("SA2") + _oAssoc:CodAvisad + _oAssoc:LojAvisad, "A2_NOME")))
					GDFieldPut ('TelAvisad',  alltrim (fBuscaCpo ("SA2", 1, xfilial ("SA2") + _oAssoc:CodAvisad + _oAssoc:LojAvisad, "A2_TEL")))
				endif
			endif

			if mv_par08 == 1  // Listar dados referentes a DAP
				GDFieldPut ('A2_VAAPDAP', alltrim (x3combo ('A2_VAAPDAP', _oAssoc:DAPAptidao)))
				GDFieldPut ('A2_VANRDAP', alltrim (_oAssoc:DAPNumero))
				GDFieldPut ('A2_VAMNDAP', alltrim (_oAssoc:DAPMotivo))
				GDFieldPut ('A2_VASTDAP', alltrim (x3combo ('A2_VASTDAP', _oAssoc:DAPnoMDA)))
				GDFieldPut ('A2_VAENDAP', alltrim (_oAssoc:DAPEnquadr))
				GDFieldPut ('A2_VAEMDAP', _oAssoc:DAPEmissao)
				GDFieldPut ('A2_VAVLDAP', _oAssoc:DAPValidad)
				GDFieldPut ('A2_VAQBDAP', alltrim (x3combo ('A2_VAQBDAP', _oAssoc:DAPBenef)))
				GDFieldPut ('A2_VAPOSSE', alltrim (x3combo ('A2_VAPOSSE', _oAssoc:Posse)))
			endif

			if mv_par09 == 1  // Listar dados do patriarca/grupo familiar
				GDFieldPut ('ZAN_COD', _oAssoc:GrpFam)
				if ! empty (_oAssoc:GrpFam)
					GDFieldPut ('ZAN_DESCRI', alltrim (fBuscaCpo ("ZAN", 1, xfilial ("ZAN") + _oAssoc:GrpFam, "ZAN_DESCRI")))
				endif
			endif

			// Dados que podem ter mais que uma ocorrencia.
			_sInscr = ''
			for _nOcorr = 1 to len (_oAssoc:aInscrEst)
				_sInscr += alltrim (_oAssoc:aInscrEst [_nOcorr]) + iif (_nOcorr < len (_oAssoc:aInscrEst), ', ', '')
			next
			GDFieldPut ('Inscr', _sInscr)

			(_sAliasQ) -> (dbskip ())
		enddo

		incproc ("Gerando arquivo de exportacao")
		processa ({ || U_AcolsXLS (aCols, .T.)})
	else
		u_help ("Nao ha dados gerados.")
	endif

return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes          Help
	aadd (_aRegsPerg, {01, "Codigo base associado inicial ", "C", 6,  0,  "",   "SA2_AS", {},             ""})
	aadd (_aRegsPerg, {02, "Loja base associado inicial   ", "C", 2,  0,  "",   "      ", {},             ""})
	aadd (_aRegsPerg, {03, "Codigo base associado final   ", "C", 6,  0,  "",   "SA2_AS", {},             ""})
	aadd (_aRegsPerg, {04, "Loja base associado final     ", "C", 2,  0,  "",   "      ", {},             ""})
	aadd (_aRegsPerg, {05, "Lista ativos / inativos       ", "N", 1,  0,  "",   "      ", {'Ativo', 'Inativos', 'Todos'}, ""})
	aadd (_aRegsPerg, {06, "Lista cap.social/baixas       ", "N", 1,  0,  "",   "      ", {'Sim', 'Nao'}, ""})
	aadd (_aRegsPerg, {07, "Lista endereco/tel/contato    ", "N", 1,  0,  "",   "      ", {'Sim', 'Nao'}, ""})
	aadd (_aRegsPerg, {08, "Lista dados referentes a DAP  ", "N", 1,  0,  "",   "      ", {'Sim', 'Nao'}, ""})
	aadd (_aRegsPerg, {09, "Lista grupo familiar          ", "N", 1,  0,  "",   "      ", {'Sim', 'Nao'}, ""})
	aadd (_aRegsPerg, {10, "Lista ultima safra            ", "N", 1,  0,  "",   "      ", {'Sim', 'Nao'}, ""})
	aadd (_aRegsPerg, {11, "Data de referencia            ", "D", 8,  0,  "",   "      ", {},             ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
