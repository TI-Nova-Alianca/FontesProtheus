// Programa:  ClsExtrCC
// Autor:     Robert Koch
// Data:      14/03/2019
// Descricao: Declaracao de classe para geracao de extrato da conta corrente de associados.
//            Criada com base no relatorio original (SZI_REL.PRW) e metodo ExtratoCC da classe ClsExtrCC.
//            Poderia trabalhar como uma include, mas prefiro declarar uma funcao de usuario
//            apenas para poder incluir no projeto e manter na pasta dos fontes.
//
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Classe
// #Descricao         #Gera dados para extrato de movimentacao de conta corrente de associados
// #PalavasChave      #extrato #conta_corrente #associados
// #TabelasPrincipais #SZI #SA2 #SE2 #SE5 #FK7 #FKA #FK2 #ZZM #ZX5
// #Modulos           #COOP
//
// Historico de alteracoes:
// 03/05/2019 - Robert - Busca historico detalhado (pelo SE5) usando a mesma funcao do SZI_REL.PRW.
// 20/09/2019 - Robert - Passa a buscar estornos do FK2 atraves da tabela FKA.
// 24/09/2019 - Robert - Criada funcionalidade de retornar dados em formato XML.
// 03/10/2019 - Robert - Implementada tag <somarApp> para uso pelo APP de associados.
// 08/11/2019 - Robert - Ajusta tag <somarApp> para TM=13 nao listar faturas e transf. entre filiais.
// 12/08/2020 - Robert - Criado parametro TMIgnorar para atender calculo de correcao monetaria, onde precisa ignorar TM=31.
// 13/08/2020 - Robert - Tratava campo ZX5_10CAPI como 'C' (quando o correto eh 'S') para movtos. de capital.
// 14/05/2024 - Robert - ZI_TM=11 busca pelo saldo, para que nao seja duplicado quando for feita a baixa (GLPI 15390)
//
// --------------------------------------------------------------------------
#include "protheus.ch"
#include "VA_Inclu.prw"


// Funcao declarada apenas para poder compilar este arquivo fonte.
user function ClsExtrCC ()
return


// ==========================================================================
CLASS ClsExtrCC

	// Declaracao das propriedades da Classe
	data Filiais
	data Cod_assoc
	data Loja_assoc
	data DataIni
	data DataFim
	data TMIni
	data TMFim
	data LerObs
	data LerComp3os
	data TipoExtrato
	data Dados
	data UltMsg
	data LinhaVazia
	data Resultado
	data FormaResult
	data TMIgnorar

	// Declaracao dos Metodos da classe
	METHOD New ()
	METHOD Gera ()
ENDCLASS


// --------------------------------------------------------------------------
// Construtor da classe.
METHOD New () Class ClsExtrCC
//	_aFiliais     = {}
	::Cod_assoc   = ''
	::Loja_assoc  = ''
	::DataIni     = ''
	::DataFim     = ''
	::TMIni       = ''
	::TMFim       = ''
	::LerObs      = .F.
	::LerComp3os  = .F.
	::TipoExtrato = ''
	::Dados       = {}
	::UltMsg      = ''
	::Resultado   = {}
	::FormaResult = 'A'  // Formato do resultado: [A]=Array (default) ou [X]=XML
	::TMIgnorar   = ''

	// Gera uma linha vazia para retorno. Serve como modelo para incluir novas linhas zeradas no extrato.
	::LinhaVazia  = aclone (array (.ExtrCCQtColunas))
	::LinhaVazia [.ExtrCCFilial]       = ''
	::LinhaVazia [.ExtrCCDescFil]      = ''
	::LinhaVazia [.ExtrCCData]         = ctod ('')
	::LinhaVazia [.ExtrCCPrefixo]      = ''
	::LinhaVazia [.ExtrCCTitulo]       = ''
	::LinhaVazia [.ExtrCCParcela]      = ''
	::LinhaVazia [.ExtrCCTM]           = ''
	::LinhaVazia [.ExtrCCHist]         = ''
	::LinhaVazia [.ExtrCCValorDebito]  = 0
	::LinhaVazia [.ExtrCCValorCredito] = 0
	::LinhaVazia [.ExtrCCFornAdt]      = ''
	::LinhaVazia [.ExtrCCLojaAdt]      = ''
	::LinhaVazia [.ExtrCCObs]          = ''
	::LinhaVazia [.ExtrCCSaldo]        = 0
return ::Self



// --------------------------------------------------------------------------
// Gera o extrato
METHOD Gera () Class ClsExtrCC
	local _aAreaAnt  := U_ML_SRArea ()
	local _sAliasQ   := ""
	local _lInverte  := .F.
	local _sDC       := ""
	local _nLinha    := 0
	local _dDtCorte  := stod ('20190101')
	local _lContinua := .T.
	local _aFiliais  := {}
	local _nPosFil   := 0
	local _aSaldoAnt := {}
	local _oSQL      := NIL
	local _dDataIni  := ctod ('')
	local _aDescriTM := {}
	local _sDescriTM := ''
	local _nDescriTM := 0
	local _lTagSomar := .F.
	local _sTMCapSld := ''
	if empty (::Cod_assoc)   ; _lContinua = .F. ; ::UltMsg += "Codigo do associado deve ser informado." ; endif
	if empty (::Loja_assoc)  ; _lContinua = .F. ; ::UltMsg += "Loja do associado deve ser informado."   ; endif
	if empty (::TipoExtrato) ; _lContinua = .F. ; ::UltMsg += "Tipo de extrato deve ser informado."     ; endif

	// Movimentos de capital, quando sao 'baixados' no financeiro, acabam aparecendo
	// mais de uma vez (uma a credido e uma a debito) e zerando um aou outro.
	// Ex.: TM 12 (integralizacao da joia inicial) soma ao capital. Quando esse
	// movimento for baixado (seja por pagamento normal ou por compensacao) com
	// notas de safra, vai aparecer anulando o movimento 12 original e, com isso,
	// zerando o capital.
	// A saida que encontramos foi mostrar esses movimentos pelo saldo (se jah
	// teve baixa, aparece apenas a linha, para historico, mas sem valor).
	_sTMCapSld := "('11', '12', '20')"
	
	// Como preciso retornar uma linha de saldos iniciais, vou partir do saldo mais recente (arquivo ZZM) e compor o extrato
	// completo, mas vou retornar apenas o periodo entre as datas solicitadas pelo usuario. Por isso, tenho duas variaveis
	// de data inicial: uma com a data que o usuario solicitou e outra com a data a partir da qual vou realmente gerar os
	// dados e compor o saldo. No final, retornarei apenas a parte final dos dados.

	// Busca saldo do ultimo fechamento para compor linha "saldo anterior" do extrato.
	if _lContinua

		// Busca o ultimo periodo fechado e calcula a partir dele. 
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT TOP 1 ZZM_CNSOCD, ZZM_CNSOCC, ZZM_CSOCD, ZZM_CSOCC, ZZM_DATA "
		_oSQL:_sQuery += "   FROM " + RetSQLName ("ZZM") + " ZZM "
		_oSQL:_sQuery +=  " WHERE ZZM.ZZM_FILIAL  = '" + xfilial ("ZZM") + "' "
		_oSQL:_sQuery +=    " AND ZZM.ZZM_ASSOC   = '" + ::Cod_assoc + "' "
		_oSQL:_sQuery +=    " AND ZZM.ZZM_LOJA    = '" + ::Loja_assoc + "' "
		_oSQL:_sQuery +=    " AND ZZM.D_E_L_E_T_  = '' "
		_oSQL:_sQuery +=    " AND ZZM.ZZM_DATA   <= '" + dtos (::DataIni) + "'"
		_oSQL:_sQuery +=  " ORDER BY ZZM_DATA DESC"
		_aSaldoAnt = aclone (_oSQL:Qry2Array (.F., .F.))
		//u_log ('saldo ant:', _aSaldoAnt)

		// Insere uma linha inicial de dados com os saldos iniciais.
		aadd (::Dados, aclone (::LinhaVazia))
		if len (_aSaldoAnt) == 1
			if ::TipoExtrato == 'N'  // Normal
				::Dados [1, .ExtrCCValorDebito]  = _aSaldoAnt [1, 1]
				::Dados [1, .ExtrCCValorCredito] = _aSaldoAnt [1, 2]
			elseif ::TipoExtrato == 'C'  // Capital social
				::Dados [1, .ExtrCCValorDebito]  = _aSaldoAnt [1, 3]
				::Dados [1, .ExtrCCValorCredito] = _aSaldoAnt [1, 4]
			endif
			::Dados [1, .ExtrCCSaldo] = ::Dados [1, .ExtrCCValorCredito] - ::Dados [1, .ExtrCCValorDebito]
			_dDataIni = stod (_aSaldoAnt [1, 5]) + 1  // Esta vai ser a data real de inicio de leitura dos lancamentos.
		else
			//u_log ('Nao encontrei ZZM anterior. Inicializando os saldos com zero.')
			_dDataIni = ctod ('')  // Esta vai ser a data real de inicio de leitura dos lancamentos.
		endif
		//u_log ('Data inicial para leitura:', _dDataIni)
	endif


	// A conta corrente iniciou antes do Protheus ter o tratamento das tabelas FK* no financeiro. Por isso, o extrato
	// vai ser gerado em duas partes: a antiga, ateh a data de corte, lendo o SE5; e a nova, buscando das tabelas FK*.
	if _lContinua

		// Parte antiga (antes da data de corte): leitura de movimentos pela tabela SE5
		if _dDataIni < _dDtCorte
			//u_log ('Iniciando leitura pela tabela SE5')

			// Busca dados usando uma CTE para facilitar a uniao das consultas de diferentes tabelas.
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "WITH _CTE AS ("
			

			// Busca conta corrente
			_oSQL:_sQuery += "SELECT 'SZI' AS ORIGEM, ZI_FILIAL AS FILIAL, "
			_oSQL:_sQuery +=       " ZI_DATA AS DATA, ZI_TM AS TIPO_MOV, ZX5.ZX5_10DESC AS DESC_TM, ZI_HISTOR AS HIST, ZI_ASSOC AS ASSOC, ZI_LOJASSO AS LOJASSO, ZI_CODMEMO AS CODMEMO,"
		//	_oSQL:_sQuery +=       " ZI_VALOR AS VALOR,"
			_oSQL:_sQuery +=       " CASE WHEN ZI_TM IN " + _sTMCapSld + " THEN ZI_SALDO ELSE ZI_VALOR END AS VALOR,"
			_oSQL:_sQuery +=       " '' AS E5_RECPAG, ZI_DOC AS NUMERO, ZI_SERIE AS PREFIXO, '' AS DOCUMEN, '' AS E5_SEQ,"
			_oSQL:_sQuery +=       " '' AS E5_MOTBX, ZI_PARCELA AS E5_PARCELA, '' AS E5_TIPODOC, '' AS FORNADT, '' AS LOJAADT, '' AS E5_ORIGEM"
			_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SZI") + " SZI, "
			_oSQL:_sQuery +=             RETSQLNAME ("ZX5") + " ZX5 "
			_oSQL:_sQuery += " WHERE ZX5.D_E_L_E_T_ = '' AND ZX5.ZX5_TABELA = '10' AND ZX5.ZX5_10COD = SZI.ZI_TM"
			if ::TipoExtrato == 'N'
				_oSQL:_sQuery += " AND ZX5.ZX5_10CAPI = 'N'"
			elseif ::TipoExtrato == 'C'
				_oSQL:_sQuery += " AND ZX5.ZX5_10CAPI = 'S'"
			endif
			_oSQL:_sQuery +=   " AND SZI.D_E_L_E_T_ != '*'"
			//_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   BETWEEN '" + ::FilialIni + "' AND '" + ::FilialFim + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC    = '" + ::Cod_assoc + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO  = '" + ::Loja_assoc + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_TM       BETWEEN '" + ::TMIni + "' AND '" + ::TMFim + "'"
			if ! empty (::TMIgnorar)
				_oSQL:_sQuery +=   " AND SZI.ZI_TM   NOT IN " + FormatIn (::TMIgnorar, '/')
			endif

			_oSQL:_sQuery +=   " AND SZI.ZI_DATA     BETWEEN '" + dtos (_dDataIni) + "' AND '" + dtos (::DataFim) + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_DATA     < '" + dtos (_dDtCorte) + "'"

			_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT *"  // Nao quero lcto que gerou movto bancario por que vai ser buscado posteriormente do SE5.
			_oSQL:_sQuery +=                     " FROM " + RETSQLNAME ("SE5") + " SE5 "
			_oSQL:_sQuery +=                    " WHERE SE5.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=                      " AND SE5.E5_VACHVEX  = 'SZI' + ZI_ASSOC + ZI_LOJASSO + ZI_SEQ"
			_oSQL:_sQuery +=                      " AND SE5.E5_TIPODOC  = 'PA'"  // Acho que VL tambem vai interessar posteriormente...
			_oSQL:_sQuery +=                      " AND SE5.E5_SITUACA != 'C'"
			_oSQL:_sQuery +=                      " AND SE5.E5_FILIAL   = SZI.ZI_FILIAL"
			_oSQL:_sQuery +=                      " AND dbo.VA_SE5_ESTORNO (SE5.R_E_C_N_O_) = 0)"

			// Busca movimento bancario ligado ao SZI.
			_oSQL:_sQuery += " UNION ALL "
			_oSQL:_sQuery += "SELECT 'SE5' AS ORIGEM, E5_FILIAL AS FILIAL, "
			_oSQL:_sQuery +=       " E5_DATA AS DATA, ZI_TM AS TIPO_MOV, ZX5.ZX5_10DESC AS DESC_TM, E5_HISTOR AS HIST, E5_CLIFOR AS ASSOC, E5_LOJA AS LOJASSO, ZI_CODMEMO AS CODMEMO,"
			_oSQL:_sQuery +=       " E5_VALOR AS VALOR, E5_RECPAG, E5_NUMERO AS NUMERO, E5_PREFIXO AS PREFIXO, E5_DOCUMEN AS DOCUMEN, E5_SEQ,"
			_oSQL:_sQuery +=       " E5_MOTBX, E5_PARCELA, E5_TIPODOC, E5_FORNADT AS FORNADT, E5_LOJAADT AS LOJAADT, E5_ORIGEM"
			_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SE5") + " SE5, "
			_oSQL:_sQuery +=             RETSQLNAME ("SZI") + " SZI, "
			_oSQL:_sQuery +=             RETSQLNAME ("ZX5") + " ZX5 "
			_oSQL:_sQuery += " WHERE ZX5.D_E_L_E_T_ = '' AND ZX5.ZX5_TABELA = '10' AND ZX5.ZX5_10COD = SZI.ZI_TM"
			if ::TipoExtrato == 'N'
				_oSQL:_sQuery += " AND ZX5.ZX5_10CAPI = 'N'"
			elseif ::TipoExtrato == 'C'
				_oSQL:_sQuery += " AND ZX5.ZX5_10CAPI = 'S'"
			endif
			_oSQL:_sQuery +=   " AND SE5.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=   " AND SZI.D_E_L_E_T_ != '*'"
			//_oSQL:_sQuery +=   " AND SE5.E5_FILIAL   BETWEEN '" + ::FilialIni + "' AND '" + ::FilialFim + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   = SE5.E5_FILIAL"
			_oSQL:_sQuery +=   " AND SE5.E5_CLIFOR   = '" + ::Cod_assoc + "'"
			_oSQL:_sQuery +=   " AND SE5.E5_LOJA     = '" + ::Loja_assoc + "'"
			_oSQL:_sQuery +=   " AND SE5.E5_DATA     BETWEEN '" + dtos (_dDataIni) + "' AND '" + dtos (::DataFim) + "'"
			_oSQL:_sQuery +=   " AND SE5.E5_DATA     < '" + dtos (_dDtCorte) + "'"
			_oSQL:_sQuery +=   " AND SE5.E5_SITUACA != 'C'"

			_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC    = SE5.E5_CLIFOR"
			_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO  = SE5.E5_LOJA"

			_oSQL:_sQuery +=   " AND SE5.E5_VACHVEX  = 'SZI' + ZI_ASSOC + ZI_LOJASSO + ZI_SEQ"
			_oSQL:_sQuery +=   " AND SZI.ZI_TM       BETWEEN '" + ::TMIni + "' AND '" + ::TMFim + "'"
			if ! empty (::TMIgnorar)
				_oSQL:_sQuery +=   " AND SZI.ZI_TM   NOT IN " + FormatIn (::TMIgnorar, '/')
			endif
			_oSQL:_sQuery +=   " AND dbo.VA_SE5_ESTORNO (SE5.R_E_C_N_O_) = 0"
			_oSQL:_sQuery += " ) "
			_oSQL:_sQuery += "SELECT _CTE.*, A2_NOME AS NOME, ZX5_10DESC AS DESC_TM, ZX5_10DC AS DEB_CRED, ZX5.ZX5_10CAPI"
			_oSQL:_sQuery +=  " FROM _CTE,"
			_oSQL:_sQuery +=         RETSQLNAME ("ZX5") + " ZX5, "
			_oSQL:_sQuery +=         RETSQLNAME ("SA2") + " SA2 "
			_oSQL:_sQuery += " WHERE SA2.A2_COD      = _CTE.ASSOC"
			_oSQL:_sQuery +=   " AND SA2.A2_LOJA     = _CTE.LOJASSO"
			_oSQL:_sQuery +=   " AND SA2.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=   " AND SA2.A2_FILIAL   = '" + xfilial ("SA2")  + "'"
			_oSQL:_sQuery +=   " AND ZX5.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=   " AND ZX5.ZX5_FILIAL  = '" + xfilial ("ZX5")  + "'"
			_oSQL:_sQuery +=   " AND ZX5.ZX5_TABELA  = '10'"
			_oSQL:_sQuery +=   " AND ZX5.ZX5_10COD   = _CTE.TIPO_MOV"

			// Ordenacao por varios campos por que, do contrario, a cada vez o relariorio traz uma nova ordenacao e fica dificil fazer comparativos...
		//	_oSQL:_sQuery += " ORDER BY DATA, TIPO_MOV, ORIGEM DESC, E5_SEQ, FILIAL, HIST, PREFIXO, NUMERO, E5_PARCELA"
			_oSQL:_sQuery += " ORDER BY DATA, TIPO_MOV, ORIGEM DESC, E5_SEQ, FILIAL, PREFIXO, NUMERO, E5_PARCELA, HIST"
			_oSQL:Log ()
			_sAliasQ = _oSQL:Qry2Trb (.F.)
			TCSetField (_sAliasQ, "DATA", "D")
			(_sAliasQ) -> (dbgotop ())                	
			do while ! (_sAliasQ) -> (eof ())

				// Verifica se o movimento deve ser tratado como debito ou como credito.
				_sDC = (_sAliasQ) -> deb_cred
				if (_sAliasQ) -> origem == 'SE5'
					_lInverte = .F.
					if _sDC == "D" .and. (_sAliasQ) -> e5_recpag == "R"
						_lInverte = ! _lInverte
					elseif _sDC == "C" .and. (_sAliasQ) -> e5_recpag == "P"
						_lInverte = ! _lInverte
					endif
					if (_sAliasQ) -> e5_motbx == "CMP" .and. (_sAliasQ) -> e5_tipodoc != 'CP'
						_lInverte = ! _lInverte
					endif
					if (_sAliasQ) -> e5_motbx == "NOR" .and. (_sAliasQ) -> tipo_mov == '15' .and. (_sAliasQ) -> e5_origem = 'SZI_TSF' 
						_lInverte = ! _lInverte
					endif

					if _lInverte
						if _sDC == "D"
							_sDC = "C"
						elseif _sDC == "C"
							_sDC = "D"
						endif
					endif
				endif

				// Gera nova linha para retorno.
				aadd (::Dados, aclone (::LinhaVazia))
				_nLinha = len (::Dados)
				::Dados [_nLinha, .ExtrCCFilial]       = (_sAliasQ) -> Filial
				::Dados [_nLinha, .ExtrCCData]         = (_sAliasQ) -> data
				::Dados [_nLinha, .ExtrCCPrefixo]      = (_sAliasQ) -> prefixo
				::Dados [_nLinha, .ExtrCCTitulo]       = (_sAliasQ) -> numero
				::Dados [_nLinha, .ExtrCCParcela]      = (_sAliasQ) -> e5_parcela
				::Dados [_nLinha, .ExtrCCTM]           = (_sAliasQ) -> tipo_mov
				::Dados [_nLinha, .ExtrCCValorDebito]  = iif (_sDC == 'D', (_sAliasQ) -> valor, 0)
				::Dados [_nLinha, .ExtrCCValorCredito] = iif (_sDC == 'C', (_sAliasQ) -> valor, 0)
				::Dados [_nLinha, .ExtrCCHist]         = alltrim ((_sAliasQ) -> hist)
		
				// Quando for baixa por compensacao, monta historico um pouco mais elaborado.
				if (_sAliasQ) -> e5_motbx == "CMP" .and. ! empty ((_sAliasQ) -> documen)
//					::Dados [_nLinha, .ExtrCCHist] = 'Compens.tit. ' + left ((_sAliasQ) -> documen, 13)
					::Dados [_nLinha, .ExtrCCHist] = _HistComp ((_sAliasQ) -> filial, (_sAliasQ) -> documen, (_sAliasQ) -> assoc, (_sAliasQ) -> lojasso, (_sAliasQ) -> fornadt, (_sAliasQ) -> lojaadt, (_sAliasQ) -> valor, ::LerComp3os)
		
					// Se foi compensacao contra outro fornecedor, busca seus dados.
					if ::LerComp3os .and. (_sAliasQ) -> assoc + (_sAliasQ) -> lojasso != (_sAliasQ) -> fornadt + (_sAliasQ) -> lojaadt
						::Dados [_nLinha, .ExtrCCFornAdt]   = (_sAliasQ) -> FornAdt
						::Dados [_nLinha, .ExtrCCLojaAdt]   = (_sAliasQ) -> LojaAdt
						::Dados [_nLinha, .ExtrCCHist] += ' de ' + (_sAliasQ) -> fornadt + '/' + (_sAliasQ) -> lojaadt + ' (' + alltrim (fBuscaCpo ("SA2", 1, xfilial ("SA2") + (_sAliasQ) -> fornadt + (_sAliasQ) -> lojaadt, "A2_NOME")) + ")"
					endif
					
				endif

				// Observacoes sao concatenadas com o historico.
				if ::LerObs .and. ! empty ((_sAliasQ) -> codmemo)
					::Dados [_nLinha, .ExtrCCObs] = alltrim (msmm ((_sAliasQ) -> codmemo,,,,3,,,'SZI'))
				endif
				(_sAliasQ) -> (dbskip ())
			enddo
			(_sAliasQ) -> (dbclosearea ())
			dbselectarea ("SM0")
		endif


		// Parte nova (a partir da data de corte): leitura pelas tabelas FK*
		// Busca dados usando uma CTE para facilitar a uniao das consultas de diferentes tabelas.
		if ::DataFim >= _dDtCorte
		//	u_log ('Iniciando leitura pelas tabelas FK')
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "WITH C AS ("
			
			// BUSCA LANCAMENTOS FEITOS NO SZI DENTRO DO INTERVALO SOLICITADO
			_oSQL:_sQuery += "SELECT 'SZI' AS ORIGEM, ZI_FILIAL AS FILIAL, " // + U_LeSM0 ('2', cEmpAnt, '', 'SZI', 'ZI_FILIAL', 'ZI_FILIAL') [2] + " AS DESCFIL, "
			_oSQL:_sQuery +=       " ZI_DATA AS DATA, ZI_TM AS TM, ZX5.ZX5_10DESC AS DESC_TM, ZI_HISTOR AS HIST, ZI_ASSOC AS ASSOC, ZI_LOJASSO AS LOJASSO, ZI_CODMEMO AS CODMEMO,"
//			_oSQL:_sQuery +=       " ZI_VALOR AS VALOR,"
			_oSQL:_sQuery +=       " CASE WHEN ZI_TM IN " + _sTMCapSld + " THEN ZI_SALDO ELSE ZI_VALOR END AS VALOR,"
			_oSQL:_sQuery +=       " ZI_DOC AS NUMERO, ZI_SERIE AS PREFIXO, '' AS SEQ, '' AS MOTBX, ZI_PARCELA AS PARCELA, '' AS FK2_DOC, ZI_ORIGEM, "
			_oSQL:_sQuery +=       " ZX5.ZX5_10DC AS DC"
			_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SZI") + " SZI, "
			_oSQL:_sQuery +=             RETSQLNAME ("ZX5") + " ZX5 "
			_oSQL:_sQuery += " WHERE ZX5.D_E_L_E_T_ = '' AND ZX5.ZX5_TABELA = '10' AND ZX5.ZX5_10COD = SZI.ZI_TM"
			if ::TipoExtrato == 'N'
				_oSQL:_sQuery += " AND ZX5.ZX5_10CAPI = 'N'"
			elseif ::TipoExtrato == 'C'
				_oSQL:_sQuery += " AND ZX5.ZX5_10CAPI = 'S'"
			endif
			_oSQL:_sQuery +=   " AND SZI.D_E_L_E_T_ != '*'"
			//_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   BETWEEN '" + ::FilialIni + "' AND '" + ::FilialFim + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC    = '" + ::Cod_assoc + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO  = '" + ::Loja_assoc + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_TM       BETWEEN '" + ::TMIni + "' AND '" + ::TMFim + "'"
			if ! empty (::TMIgnorar)
				_oSQL:_sQuery +=   " AND SZI.ZI_TM   NOT IN " + FormatIn (::TMIgnorar, '/')
			endif
			_oSQL:_sQuery +=   " AND SZI.ZI_DATA     BETWEEN '" + dtos (_dDataIni) + "' AND '" + dtos (::DataFim) + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_DATA     >= '" + dtos (_dDtCorte) + "'"

			// Busca movimento bancario ligado ao SZI.
			_oSQL:_sQuery += " UNION ALL "
			_oSQL:_sQuery += " SELECT 'FK2' AS ORIGEM, FK2.FK2_FILIAL FILIAL, 
			_oSQL:_sQuery +=        " FK2.FK2_DATA DATA, SZI.ZI_TM TM, ZX5.ZX5_10DESC AS DESC_TM, FK2.FK2_HISTOR HIST, SE2.E2_FORNECE ASSOC, SE2.E2_LOJA LOJASSO, ZI_CODMEMO AS CODMEMO,"
			_oSQL:_sQuery +=        " FK2.FK2_VALOR VALOR, SE2.E2_NUM NUMERO, SE2.E2_PREFIXO PREFIXO, FK2_SEQ AS SEQ, FK2.FK2_MOTBX AS MOTBX, SE2.E2_PARCELA AS PARCELA, FK2_DOC, '' AS ZI_ORIGEM,"
			_oSQL:_sQuery +=        " CASE WHEN (ZX5.ZX5_10DC = 'D' AND FK2.FK2_RECPAG = 'R')"
			_oSQL:_sQuery +=             " OR (ZX5.ZX5_10DC = 'C' AND FK2.FK2_RECPAG = 'P')"
			_oSQL:_sQuery +=             " OR (FK2.FK2_MOTBX = 'CMP' AND FK2.FK2_TPDOC != 'CP')"
			_oSQL:_sQuery +=             " OR (FK2.FK2_MOTBX = 'NOR' AND SZI.ZI_TM = '15' AND FK2.FK2_ORIGEM != 'SZI_TSF')"
			_oSQL:_sQuery +=        " THEN CASE WHEN ZX5.ZX5_10DC = 'D' THEN 'C' ELSE 'D' END ELSE ZX5.ZX5_10DC END AS DC"
			_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SZI") + " SZI, "
			_oSQL:_sQuery +=             RETSQLNAME ("FK2") + " FK2, "
			_oSQL:_sQuery +=             RETSQLNAME ("FK7") + " FK7, "
			_oSQL:_sQuery +=             RETSQLNAME ("SE2") + " SE2, "
			_oSQL:_sQuery +=             RETSQLNAME ("ZX5") + " ZX5 "
			_oSQL:_sQuery += " WHERE ZX5.D_E_L_E_T_ = '' AND ZX5.ZX5_TABELA = '10' AND ZX5.ZX5_10COD = SZI.ZI_TM"
			if ::TipoExtrato == 'N'
				_oSQL:_sQuery += " AND ZX5.ZX5_10CAPI = 'N'"
			elseif ::TipoExtrato == 'C'
				_oSQL:_sQuery += " AND ZX5.ZX5_10CAPI = 'S'"
			endif
			_oSQL:_sQuery += " AND FK2.D_E_L_E_T_ = '' AND FK2.FK2_FILIAL = FK7.FK7_FILIAL AND FK2.FK2_IDDOC = FK7.FK7_IDDOC"

			// Ignora movimentos estornados
			//_oSQL:_sQuery += " AND NOT EXISTS (SELECT * "
			//_oSQL:_sQuery += "                   FROM " + RetSQLName ("FK2") + " ESTORNO "
			//_oSQL:_sQuery += "                  WHERE ESTORNO.FK2_FILIAL = FK2.FK2_FILIAL"
			//_oSQL:_sQuery += "                    AND ESTORNO.FK2_IDDOC = FK2.FK2_IDDOC"
			//_oSQL:_sQuery += "                    AND ESTORNO.FK2_SEQ = FK2.FK2_SEQ"
			//_oSQL:_sQuery += "                    AND ESTORNO.FK2_TPDOC = 'ES')"
			// Pelo que entendi das tabelas FK, cada movimento gera um 'processo' na tabela FKA.
			// Caso o movimento seja estornado, cria-se novo registro na FKA com o mesmo processo
			// amarrando ao movimento de estorno.
			_oSQL:_sQuery += " AND NOT EXISTS (SELECT * "
			_oSQL:_sQuery +=                   " FROM " + RetSQLName ("FKA") + " FKA, "
			_oSQL:_sQuery +=                              RetSQLName ("FKA") + " FKA2, "
			_oSQL:_sQuery +=                              RetSQLName ("FK2") + " FK2_ESTORNO "
			_oSQL:_sQuery +=                  " WHERE FKA.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=                    " AND FKA.FKA_FILIAL   = FK2.FK2_FILIAL"
			_oSQL:_sQuery +=                    " AND FKA.FKA_IDORIG   = FK2.FK2_IDFK2"
			_oSQL:_sQuery +=                    " AND FKA.FKA_TABORI   = 'FK2'"
			_oSQL:_sQuery +=                    " AND FKA2.D_E_L_E_T_  = ''"
			_oSQL:_sQuery +=                    " AND FKA2.FKA_FILIAL  = FKA.FKA_FILIAL"
			_oSQL:_sQuery +=                    " AND FKA2.FKA_IDPROC  = FKA.FKA_IDPROC"
			_oSQL:_sQuery +=                    " AND FKA2.FKA_TABORI  = FKA.FKA_TABORI"
			_oSQL:_sQuery +=                    " AND FKA2.FKA_IDFKA  != FKA.FKA_IDFKA"
			_oSQL:_sQuery +=                    " AND FK2_ESTORNO.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=                    " AND FK2_ESTORNO.FK2_FILIAL = FKA2.FKA_FILIAL"
			_oSQL:_sQuery +=                    " AND FK2_ESTORNO.FK2_IDFK2  = FKA2.FKA_IDORIG"
			_oSQL:_sQuery +=                    " AND FK2_ESTORNO.FK2_TPDOC  = 'ES'"
			_oSQL:_sQuery +=                  " )"

			_oSQL:_sQuery += " AND FK7.D_E_L_E_T_ = '' AND FK7.FK7_FILIAL = SE2.E2_FILIAL AND FK7.FK7_ALIAS = 'SE2' AND FK7.FK7_CHAVE = SE2.E2_FILIAL + '|' + SE2.E2_PREFIXO + '|' + SE2.E2_NUM + '|' + SE2.E2_PARCELA + '|' + SE2.E2_TIPO + '|' + SE2.E2_FORNECE + '|' + SE2.E2_LOJA"
			_oSQL:_sQuery += " AND SE2.D_E_L_E_T_ = '' AND SE2.E2_FILIAL = SZI.ZI_FILIAL AND SE2.E2_PREFIXO = SZI.ZI_SERIE AND SE2.E2_NUM = SZI.ZI_DOC AND SE2.E2_PARCELA = SZI.ZI_PARCELA AND SE2.E2_FORNECE = SZI.ZI_ASSOC AND SE2.E2_LOJA = SZI.ZI_LOJASSO"
			_oSQL:_sQuery += " AND SE2.E2_FORNECE = '" + ::Cod_assoc + "'"
			_oSQL:_sQuery += " AND SE2.E2_LOJA    = '" + ::Loja_assoc + "'"
			_oSQL:_sQuery += " AND SZI.ZI_TM      BETWEEN '" + ::TMIni + "' AND '" + ::TMFim + "'"
			if ! empty (::TMIgnorar)
				_oSQL:_sQuery +=   " AND SZI.ZI_TM   NOT IN " + FormatIn (::TMIgnorar, '/')
			endif
			_oSQL:_sQuery += " AND FK2.FK2_TPDOC != 'ES'"  // Estornos
			_oSQL:_sQuery += " AND FK2.FK2_DATA   BETWEEN '" + dtos (_dDataIni) + "' AND '" + dtos (::DataFim) + "'"
			_oSQL:_sQuery += " AND FK2.FK2_DATA   >= '" + dtos (_dDtCorte) + "'"
			_oSQL:_sQuery += " AND SZI.D_E_L_E_T_ = ''"
			_oSQL:_sQuery += " )"
//			_oSQL:_sQuery += " SELECT C.ORIGEM, C.ASSOC, C.LOJASSO, C.FILIAL, C.DATA, C.PREFIXO, C.NUMERO, C.PARCELA, C.TM, C.DESC_TM, C.CODMEMO,"
			_oSQL:_sQuery += " SELECT C.ORIGEM, C.ASSOC, C.LOJASSO, C.FILIAL, C.DATA, C.PREFIXO, C.NUMERO, C.PARCELA, C.TM, C.DESC_TM, C.CODMEMO, C.ZI_ORIGEM,"
			_oSQL:_sQuery +=       " CASE C.DC WHEN 'D' THEN VALOR ELSE 0 END AS DEBITO,"
			_oSQL:_sQuery +=       " CASE C.DC WHEN 'C' THEN VALOR ELSE 0 END AS CREDITO,"

			// Monta subquery para buscar o associado com quem foi feita compensacao, quando 'compensado com outro fornecedor', e concatena com o historico.
			if ::LerComp3os
				_oSQL:_sQuery +=       " ISNULL (SE2_COMP.E2_FORNECE, '') AS FORNADT,"
				_oSQL:_sQuery +=       " ISNULL (SE2_COMP.E2_LOJA, '') AS LOJAADT, "
				
				// Tenta buscar os dados do titulo contra o qual foi compensado.
//				_oSQL:_sQuery +=       " CASE WHEN MOTBX = 'CMP' THEN 'Compens.tit. ' + SE2_COMP.E2_PREFIXO + '/' + SE2_COMP.E2_NUM + '-' + SE2_COMP.E2_PARCELA"
				_oSQL:_sQuery +=       " CASE WHEN MOTBX = 'CMP'"
				_oSQL:_sQuery +=            " THEN 'Compens.tit. '"
				_oSQL:_sQuery +=                 " + ISNULL (SE2_COMP.E2_PREFIXO + '/' + SE2_COMP.E2_NUM + '-' + SE2_COMP.E2_PARCELA"

				// Tratamento para o caso de compensar contra titulo de outro fornecedor
				_oSQL:_sQuery +=                           " + CASE WHEN SE2_COMP.E2_FORNECE + SE2_COMP.E2_LOJA != C.ASSOC + C.LOJASSO"
				_oSQL:_sQuery +=                                  " THEN ' #### de ' + SE2_COMP.E2_FORNECE + '/' + SE2_COMP.E2_LOJA + ' '"
				_oSQL:_sQuery +=                                         " + (SELECT RTRIM (A2_NOME)"
				_oSQL:_sQuery +=                                              " FROM " + RetSQLName ("SA2") + " ASSOC_COMP"
				_oSQL:_sQuery +=                                             " WHERE ASSOC_COMP.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=                                               " AND ASSOC_COMP.A2_FILIAL = '  '"
				_oSQL:_sQuery +=                                               " AND ASSOC_COMP.A2_COD = SE2_COMP.E2_FORNECE"
				_oSQL:_sQuery +=                                               " AND ASSOC_COMP.A2_LOJA = SE2_COMP.E2_LOJA)"
				_oSQL:_sQuery +=                                  " ELSE ''"
				_oSQL:_sQuery +=                              " END"
//				_oSQL:_sQuery +=                              " + ' (' + RTRIM (SE2_COMP.E2_HIST) + ')'"
				_oSQL:_sQuery +=                              " + ' (' + RTRIM (SE2_COMP.E2_HIST) + ')'"
				_oSQL:_sQuery +=                     ", '')"
				_oSQL:_sQuery +=            " ELSE C.HIST"
				_oSQL:_sQuery +=       " END AS HIST"
			else
				_oSQL:_sQuery +=       " '' AS FORNADT, '' AS LOJAADT, "
				_oSQL:_sQuery +=       " C.HIST"
			endif

			_oSQL:_sQuery += " FROM C "

			// JUNTA COM A TABELA FK7 PARA BUSCAR COMPENSACOES FEITAS COM OUTROS ASSOCIADOS.
			if ::LerComp3os
				_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("FK7") + " FK7_COMP "
				_oSQL:_sQuery +=      " JOIN " + RetSQLName ("SE2") + " SE2_COMP "
				_oSQL:_sQuery +=           " ON (SE2_COMP.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=           " AND SE2_COMP.E2_FILIAL = SUBSTRING (FK7_COMP.FK7_CHAVE, 1, 2)"
				_oSQL:_sQuery +=           " AND SE2_COMP.E2_PREFIXO = SUBSTRING (FK7_COMP.FK7_CHAVE, 4, 3)"
				_oSQL:_sQuery +=           " AND SE2_COMP.E2_NUM = SUBSTRING (FK7_COMP.FK7_CHAVE, 8, 9)"
				_oSQL:_sQuery +=           " AND SE2_COMP.E2_PARCELA = SUBSTRING (FK7_COMP.FK7_CHAVE, 18, 1)"
				_oSQL:_sQuery +=           " AND SE2_COMP.E2_TIPO = SUBSTRING (FK7_COMP.FK7_CHAVE, 20, 3)"
				_oSQL:_sQuery +=           " AND SE2_COMP.E2_FORNECE = SUBSTRING (FK7_COMP.FK7_CHAVE, 24, 6)"
				_oSQL:_sQuery +=           " AND SE2_COMP.E2_LOJA = SUBSTRING (FK7_COMP.FK7_CHAVE, 31, 2)"
				_oSQL:_sQuery +=           ")"
				_oSQL:_sQuery +=     " ON (C.MOTBX = 'CMP' AND SUBSTRING (C.FK2_DOC, 17, 6) + SUBSTRING (C.FK2_DOC, 23, 2) != C.ASSOC + C.LOJASSO" // DEVE SER DE OUTRO FORNECEDOR"
				_oSQL:_sQuery +=     " AND FK7_COMP.D_E_L_E_T_ = '' AND FK7_COMP.FK7_FILIAL = C.FILIAL AND FK7_COMP.FK7_ALIAS = 'SE2' "
				_oSQL:_sQuery +=     " AND FK7_COMP.FK7_CHAVE = C.FILIAL + '|' + SUBSTRING (C.FK2_DOC, 1, 3) + '|' + SUBSTRING (C.FK2_DOC, 4, 9) + '|' + SUBSTRING (C.FK2_DOC, 13, 1) + '|' + SUBSTRING (C.FK2_DOC, 14, 3) + '|' + SUBSTRING (C.FK2_DOC, 17, 6) + '|' + SUBSTRING (C.FK2_DOC, 23, 2)"
				_oSQL:_sQuery +=     ")"
			endif
		//	_oSQL:_sQuery += " order by ASSOC, LOJASSO, DATA, TM, ORIGEM DESC, SEQ, FILIAL, HIST, PREFIXO, NUMERO, PARCELA"
			_oSQL:_sQuery += " order by ASSOC, LOJASSO, DATA, TM, ORIGEM DESC, SEQ, FILIAL, PREFIXO, NUMERO, PARCELA, HIST"
		//	_oSQL:Log ()
			_sAliasQ = _oSQL:Qry2Trb (.F.)
			TCSetField (_sAliasQ, "DATA", "D")
			(_sAliasQ) -> (dbgotop ())
			do while ! (_sAliasQ) -> (eof ())

				// Gera nova linha para retorno.
				aadd (::Dados, aclone (::LinhaVazia))
				_nLinha = len (::Dados)
				::Dados [_nLinha, .ExtrCCFilial]       = (_sAliasQ) -> Filial
				::Dados [_nLinha, .ExtrCCData]         = (_sAliasQ) -> data
				::Dados [_nLinha, .ExtrCCPrefixo]      = (_sAliasQ) -> prefixo
				::Dados [_nLinha, .ExtrCCTitulo]       = (_sAliasQ) -> numero
				::Dados [_nLinha, .ExtrCCParcela]      = (_sAliasQ) -> parcela
				::Dados [_nLinha, .ExtrCCTM]           = (_sAliasQ) -> tM
				::Dados [_nLinha, .ExtrCCValorDebito]  = (_sAliasQ) -> DEBITO
				::Dados [_nLinha, .ExtrCCValorCredito] = (_sAliasQ) -> CREDITO
				::Dados [_nLinha, .ExtrCCFornAdt]      = (_sAliasQ) -> FornAdt
				::Dados [_nLinha, .ExtrCCLojaAdt]      = (_sAliasQ) -> LojaAdt
				::Dados [_nLinha, .ExtrCCHist]         = (_sAliasQ) -> hist
				::Dados [_nLinha, .ExtrCCOrigem]       = (_sAliasQ) -> origem
				::Dados [_nLinha, .ExtrCCZIOrigem]     = (_sAliasQ) -> zi_origem

				// Observacoes sao concatenadas com o historico.
				if ::LerObs .and. ! empty ((_sAliasQ) -> codmemo)
					::Dados [_nLinha, .ExtrCCObs] = alltrim (msmm ((_sAliasQ) -> codmemo,,,,3,,,'SZI'))
				endif

				(_sAliasQ) -> (dbskip ())
			enddo
			(_sAliasQ) -> (dbclosearea ())
			dbselectarea ("SM0")
		endif

		// Calcula coluna de saldo
		for _nLinha = 2 to len (::Dados)
			::Dados [_nLinha, .ExtrCCSaldo] = ::Dados [_nLinha - 1, .ExtrCCSaldo] + ::Dados [_nLinha, .ExtrCCValorCredito] - ::Dados [_nLinha, .ExtrCCValorDebito]
		next
	endif

	//u_log ('Dados internos antes:', ::Dados)

	// Preenche nomes das filiais. Optei por fazer fora das queries por que jah estavam bem grandes e para evitar trafego
	// de rede retornando repetidas vezes a mesma coisa. Veremos se vai ficar melhor...
	if _lContinua
		for _nLinha = 1 to len (::Dados)
			if ! empty (::Dados [_nLinha, .ExtrCCFilial])
				_nPosFil = ascan (_aFiliais, {|_aVal| _aVal [1] == ::Dados [_nLinha, .ExtrCCFilial]})
				if _nPosFil == 0
					aadd (_aFiliais, {::Dados [_nLinha, .ExtrCCFilial], alltrim (fBuscaCpo ("SM0", 1, cEmpAnt + ::Dados [_nLinha, .ExtrCCFilial], "M0_FILIAL"))})
	//				u_log (_aFiliais)
					_nPosFil = len (_aFiliais)
				endif
				::Dados [_nLinha, .ExtrCCDescFil] = _aFiliais [_nPosFil, 2]
			endif
		next
	endif

	//u_log ('Dados internos depois:', ::Dados)


	// Monta dados para retorno, filtrando somente o periodo de datas solicitadas pelo usuario.
	if _lContinua
		if ::FormaResult == 'A'  // Retornar em formato Array
			::Resultado = {}
			for _nLinha = 2 to len (::Dados)
				if ::Dados [_nLinha, .ExtrCCData] >= ::DataIni
				
					// Insere no retorno uma linha para mostrar o saldo inicial
					if len (::Resultado) == 0
						aadd (::Resultado, aclone (::LinhaVazia))
						::Resultado [1, .ExtrCCHist] = 'Saldo anterior'
						::Resultado [1, .ExtrCCSaldo] = ::Dados [_nLinha - 1, .ExtrCCSaldo]
					endif
					aadd (::Resultado, aclone (::Dados [_nLinha]))
				endif
			next

		elseif ::FormaResult == 'X'  // Retornar em formato XML
			::Resultado := "<assocCCorrente>"
			::Resultado +=    "<associado>" + ::Cod_assoc + "</associado>"
			::Resultado +=    "<loja>" + ::Loja_assoc + "</loja>"
			::Resultado +=    "<lctoCC>"
			for _nLinha = 2 to len (::Dados)
				if ::Dados [_nLinha, .ExtrCCData] >= ::DataIni
					// Insere no retorno uma linha para mostrar o saldo inicial
					if at ('<lctoCCItem>', ::Resultado) == 0  // Se ainda nao tem nenhum lcto
						::Resultado +=       "<lctoCCItem>"
						::Resultado +=          "<dtMovto></dtMovto>"
						::Resultado +=          "<tipoMov></tipoMov>"
						::Resultado +=          "<descMov></descMov>"
						::Resultado +=          "<hist>Saldo anterior</hist>"
						::Resultado +=          "<valor>0</valor>"
						::Resultado +=          "<dc></dc>"
						::Resultado +=          "<somarApp></somarApp>"
						::Resultado +=          "<saldo>" + cvaltochar (::Dados [_nLinha - 1, .ExtrCCSaldo]) + "</saldo>"
						::Resultado +=       "</lctoCCItem>"
					endif

					// Trabalha com uma lista de descricoes de tipo de movimento. Se jah na lista, usa. Senao, acrescenta.
					_nDescriTM = ascan (_aDescriTM, {|_aVal| _aVal [1] == ::Dados [_nLinha, .ExtrCCTM]})
					if _nDescriTM > 0
						_sDescriTM = _aDescriTM [_nDescriTM, 2]
					else
						_sDescriTM = alltrim (U_RetZX5 ('10', ::Dados [_nLinha, .ExtrCCTM], 'ZX5_10DESC'))
						aadd (_aDescriTM, {::Dados [_nLinha, .ExtrCCTM], _sDescriTM})
					endif

					::Resultado +=    "<lctoCCItem>"
					::Resultado +=          "<dtMovto>" + dtoc (::Dados [_nLinha, .ExtrCCData]) + "</dtMovto>"
					::Resultado +=          "<tipoMov>" + ::Dados [_nLinha, .ExtrCCTM] + "</tipoMov>"
					::Resultado +=          "<descMov>" + _sDescriTM + "</descMov>"
					::Resultado +=          "<hist>" + alltrim (::Dados [_nLinha, .ExtrCCHist]) + "</hist>"

					// Decide como deve preencher a tag indicando ao app de associados se deve somar ao total do tipo de movimento.
					_lTagSomar = .F.
					if ::Dados [_nLinha, .ExtrCCOrigem] == 'SZI'
						
						// Compra de safra: para nao misturar com as faturas e transf. entre filiais, verifica se eh a nota original
						if ::Dados [_nLinha, .ExtrCCTM] == '13'
							if alltrim(::Dados [_nLinha, .ExtrCCZIOrigem]) $ 'VA_GNF2/VA_GNF6'
								_lTagSomar = .T.
							endif
						else
							_lTagSomar = .T.
						endif
					endif

					if ::Dados [_nLinha, .ExtrCCValorDebito] > 0
						::Resultado +=          "<valor>" + cvaltochar (::Dados [_nLinha, .ExtrCCValorDebito]) + "</valor>"
						::Resultado +=          "<dc>D</dc>"
						::Resultado +=          "<somarApp>" + iif (_lTagSomar, 'D', '') + "</somarApp>"
					elseif ::Dados [_nLinha, .ExtrCCValorCredito] > 0
						::Resultado +=          "<valor>" + cvaltochar (::Dados [_nLinha, .ExtrCCValorCredito]) + "</valor>"
						::Resultado +=          "<dc>C</dc>"
						::Resultado +=          "<somarApp>" + iif (_lTagSomar, 'C', '') + "</somarApp>"
					endif

					::Resultado +=          "<saldo>" + cvaltochar (::Dados [_nLinha, .ExtrCCSaldo]) + "</saldo>"
					::Resultado +=    "</lctoCCItem>"
				endif
			next
			::Resultado +=    "</lctoCC>"
			::Resultado += "</assocCCorrente>"
		else
			::UltMsg += "Forma de retorno desconhecida ou sem tratamento."
		endif
	endif

/*
	// Preenche nomes das filiais. Optei por fazer fora das queries por que jah estavam bem grandes e para evitar trafego
	// de rede retornando repetidas vezes a mesma coisa. Veremos se vai ficar melhor...
	if _lContinua
		for _nLinha = 1 to len (::Resultado)
			if ! empty (::Resultado [_nLinha, .ExtrCCFilial])
				_nPosFil = ascan (::Filiais, {|_aVal| _aVal [1] == ::Resultado [_nLinha, .ExtrCCFilial]})
				if _nPosFil == 0
					aadd (::Filiais, {::Resultado [_nLinha, .ExtrCCFilial], alltrim (fBuscaCpo ("SM0", 1, cEmpAnt + ::Resultado [_nLinha, .ExtrCCFilial], "M0_FILIAL"))})
					_nPosFil = len (::Filiais)
				endif
				::Resultado [_nLinha, .ExtrCCDescFil] = ::Filiais [_nPosFil, 2]
			endif
		next
	endif
*/

	U_ML_SRArea (_aAreaAnt)
//	u_logFim (GetClassName (::Self) + '.' + procname ())
Return



// --------------------------------------------------------------------------
// Monta historico a ser listado em caso de compensacao de titulos.
Static Function _HistComp (_sFilial, _sDocumen, _sCliFor, _sLoja, _sFornAdt, _sLojaAdt, _nValor, _lLerComp3)
	local _sRet     := ""
	local _aRetQry  := {}
	local _oSQL     := NIL

	_sRet = 'Compens.tit. '

	// Busca dados do movimento atual amarrado ao movimento 'par' da compensacao para, a
	// partir deste, buscar dados da conta corrente (SZI).
	// Busca dados com TOP 1 por causa do problema na forma de gravacao do E5_DOCUMEN (ver comentario abaixo).
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT TOP 1 SE5_ORIG.E5_PREFIXO, SE5_ORIG.E5_NUMERO, SE5_ORIG.E5_PARCELA, ZI_HISTOR"
	_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SE5") + " SE5_ORIG, "
	_oSQL:_sQuery +=             RETSQLNAME ("SE5") + " SE5_COMP, "
	_oSQL:_sQuery +=             RETSQLNAME ("SZI") + " SZI "
	_oSQL:_sQuery += " WHERE SE5_COMP.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SE5_COMP.E5_FILIAL   = '" + _sFilial + "'"
	_oSQL:_sQuery +=   " AND SE5_COMP.E5_DOCUMEN  = '" + _sDocumen + "'"  // Registro atual do SE5
	_oSQL:_sQuery +=   " AND SE5_COMP.E5_CLIFOR   = '" + _sCliFor + "'"
	_oSQL:_sQuery +=   " AND SE5_COMP.E5_LOJA     = '" + _sLoja + "'"
	_oSQL:_sQuery +=   " AND SE5_COMP.E5_MOTBX    = 'CMP'"
	_oSQL:_sQuery +=   " AND SE5_COMP.E5_SITUACA != 'C'"
	_oSQL:_sQuery +=   " AND dbo.VA_SE5_ESTORNO (SE5_COMP.R_E_C_N_O_) = 0"
	_oSQL:_sQuery +=   " AND SE5_ORIG.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SE5_ORIG.E5_FILIAL   = SE5_COMP.E5_FILIAL"

	// o Registro que faz o 'par' da compensacao parece estar, algumas vezes, sem o codigo de fornecedor
	// dentro do campo E5_DOCUMEN. Parece ser em casos onde foi usado filtro 'considera titulos de
	// outros fornecedores' no momento da compensacao.
	_oSQL:_sQuery +=   " AND SE5_ORIG.E5_DOCUMEN LIKE SE5_COMP.E5_PREFIXO + SE5_COMP.E5_NUMERO + SE5_COMP.E5_PARCELA + SE5_COMP.E5_TIPO + '%'"  // Para ganho de performance.
	_oSQL:_sQuery +=   " AND (SE5_ORIG.E5_DOCUMEN  = SE5_COMP.E5_PREFIXO"
	_oSQL:_sQuery +=                             " + SE5_COMP.E5_NUMERO"
	_oSQL:_sQuery +=                             " + SE5_COMP.E5_PARCELA"
	_oSQL:_sQuery +=                             " + SE5_COMP.E5_TIPO"
	_oSQL:_sQuery +=                             " + SE5_COMP.E5_CLIFOR"
	_oSQL:_sQuery +=                             " + SE5_COMP.E5_LOJA"
	_oSQL:_sQuery +=   " OR (SE5_ORIG.E5_DOCUMEN  = SE5_COMP.E5_PREFIXO"
	_oSQL:_sQuery +=                            " + SE5_COMP.E5_NUMERO"
	_oSQL:_sQuery +=                            " + SE5_COMP.E5_PARCELA"
	_oSQL:_sQuery +=                            " + SE5_COMP.E5_TIPO"
	_oSQL:_sQuery +=                            " + SE5_COMP.E5_LOJA"
	_oSQL:_sQuery +=       " AND SE5_ORIG.E5_CLIFOR = SE5_COMP.E5_CLIFOR"
	_oSQL:_sQuery +=       " AND SE5_ORIG.E5_VALOR  = " + cvaltochar (_nValor)
	_oSQL:_sQuery +=   " ))"

	_oSQL:_sQuery +=   " AND SE5_ORIG.E5_SEQ      = SE5_COMP.E5_SEQ"
	_oSQL:_sQuery +=   " AND dbo.VA_SE5_ESTORNO (SE5_ORIG.R_E_C_N_O_) = 0"
	_oSQL:_sQuery +=   " AND SZI.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   = SE5_ORIG.E5_FILIAL"
	_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC    = SE5_ORIG.E5_CLIFOR"
	_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO  = SE5_ORIG.E5_LOJA"
	_oSQL:_sQuery +=   " AND SZI.ZI_SEQ      = SUBSTRING (SE5_ORIG.E5_VACHVEX, 12, 6)"
//	u_log (_oSQL:_sQuery)
	_aRetQry = aclone (_oSQL:Qry2Array (.F., .F.))
//	u_log (_aRetQry)
	
	// Se conseguir os dados pela query, eu prefiro.
	if len (_aRetQry) > 0
		_sRet += _aRetQry [1, 1] + '/' + _aRetQry [1, 2] + '-' + _aRetQry [1, 3]

		// Se foi compensacao contra outro fornecedor, busca seus dados.
		if _lLerComp3 .and. _sFornAdt + _sLojaAdt != _sCliFor + _sLoja
			_sRet += ' #### de ' + _sFornAdt + '/' + _sLojaAdt + ' ' + alltrim (left (fBuscaCpo ('SA2', 1, xfilial ('SA2') + _sFornAdt + _sLojaAdt, 'A2_NOME'), 20))
		endif

		// Acrescenta o historico do lancamento original da conta corrente.
		if ! empty (_aRetQry [1, 4])
			_sRet += " (" + alltrim (_aRetQry [1, 4]) + ")"
		endif
	else
		_sRet += left (_sDocumen, 13)

		// Se foi compensacao contra outro fornecedor, busca seus dados.
		if _lLerComp3 .and. _sFornAdt + _sLojaAdt != _sCliFor + _sLoja
			_sRet += ' #### de ' + _sFornAdt + '/' + _sLojaAdt + ' ' + alltrim (left (fBuscaCpo ('SA2', 1, xfilial ('SA2') + _sFornAdt + _sLojaAdt, 'A2_NOME'), 20))
		endif
	endif
return _sRet
