// Programa:  ESXEST01
// Autor:     Eduardo Candido
// Data:      2012
// Descricao: Rateio custo estocagem (ajuste do custo dos produtos VD conforme despesa dos CC)

/*
Descritivo das operações feitas pelo programa ESXEST01 (rateio custo estocagem)

A finalidade do programa é buscar os saldos dos centros de custos de estocagem no mês, e distribuir esses saldos entre os itens de granel mais representativos em estoque.
A forma de gerar essa distribuição é gerando entradas de valor em cada item. Como a quantidade não é alterada, automaticamente obtém-se um aumento do custo médio.

O programa verifica os saldos contábeis dos centros de custo abaixo (onde XX = filial):
XX1101
XX1102
XX1201
XX1202

Para cada centro de custo, são lidas as contas contábeis abaixo:
- contas 7010110...    (transferências de um CC para outro)
- contas do grupo 0070 (mão de obra)
- contas do grupo 0080 (GGF)
- contas do grupo 0110 (apoio)
- outras contas        (contas sem grupo)

A soma desses saldos será distribuída entre os produtos em estoque que atendam às seguintes condições:
- ser do tipo VD;
- não ser 'de terceiros' (campo B1_AGREGCU diferente de '1');
- não ter mão de obra (item MMM) em sua estrutura;
- Possuir saldo mínimo de 0,01 litro em estoque no último dia do mês em questão.


Considerações adicionais:
- Para o CC XX1101 são gerados movimentos de estoque tipo 300
- Para o CC XX1102 são gerados movimentos de estoque tipo 301
- Para o CC XX1201 são gerados movimentos de estoque tipo 302
- Para o CC XX1202 são gerados movimentos de estoque tipo 303
- O programa gera dados somente para a filial atual.
- Em caso de nova execução no mesmo mês, os movimentos anteriores serão automaticamente apagados.
- Atualmente os movimentos gerados por este programa são contabilizados pelo lcto.padrão 668.
*/

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Gera entrada de valor em itens tipo VD para agregar custo de estocagem
// #PalavasChave      #rateio #estocagem
// #TabelasPrincipais #SD3
// #Modulos           #EST

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
// 04/12/2019 - Claudia - Quando houver erros no processo, será impressa apenas uma vez a mensagem e finalizado o processo, conforme GLPI: 6921
// 21/01/2020 - Robert  - Campos D3_VAMO e D3_VAGGF nao eram consultados e serao excluidos.
// 20/07/2020 - Robert  - Permissao para executar passa a validar acesso 103 e nao mais 069.
//                      - Inseridas tags para catalogacao de fontes
// 11/12/2020 - Robert  - Ignora centros de custo de recebimento e processamento (por enquanto apenas base teste) por que serao processados pelo VA_RTSAF.TLPP
//


// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

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
User function ESXEST01()

	if ! u_zzuvl ('103', __cUserId, .T.)
		return
	endif

	Private cPerg   := Padr("ESXEST01",Len(SX1->X1_GRUPO))

	u_logId ()

	ValidPerg()
	if Pergunte(cPerg, .T.)
		processa ({|| _esxest01a()},"Processando ...")
	endif
Return



// --------------------------------------------------------------------------
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
	local _nADistr   := 0
	local _aRequis   := {}
	local _aCols     := {}
	local _nSldMO    := 0
	local _nSldGGF   := 0
	local _nSldSGru  := 0
	local _nSldTra   := 0
	local _nSldApoio := 0
	local _oEvento   := NIL

	u_logIni ()
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

//		// por enquanto, apenas na base de testes
		if U_MsgNoYes ("Deseja apropriar CC de recebimento / processamento?")
			aadd (_aCC, afill (array (.CCQtColunas), 0))
			_aCC [len (_aCC), .CCCodigo]        = cFilAnt + '1101'
			_aCC [len (_aCC), .CCDescricao]     = fBuscaCpo ("CTT", 1, xfilial ("CTT") + _aCC [len (_aCC), .CCCodigo], "CTT_DESC01")
			_aCC [len (_aCC), .CCTipoMovimento] = '300'
			aadd (_aCC, afill (array (.CCQtColunas), 0))
			_aCC [len (_aCC), .CCCodigo]        = cFilAnt + '1102'
			_aCC [len (_aCC), .CCDescricao]     = fBuscaCpo ("CTT", 1, xfilial ("CTT") + _aCC [len (_aCC), .CCCodigo], "CTT_DESC01")
			_aCC [len (_aCC), .CCTipoMovimento] = '301'
		endif
		aadd (_aCC, afill (array (.CCQtColunas), 0))
		_aCC [len (_aCC), .CCCodigo]        = cFilAnt + '1201'
		_aCC [len (_aCC), .CCDescricao]     = fBuscaCpo ("CTT", 1, xfilial ("CTT") + _aCC [len (_aCC), .CCCodigo], "CTT_DESC01")
		_aCC [len (_aCC), .CCTipoMovimento] = '302'
		aadd (_aCC, afill (array (.CCQtColunas), 0))
		_aCC [len (_aCC), .CCCodigo]        = cFilAnt + '1202'
		_aCC [len (_aCC), .CCDescricao]     = fBuscaCpo ("CTT", 1, xfilial ("CTT") + _aCC [len (_aCC), .CCCodigo], "CTT_DESC01")
		_aCC [len (_aCC), .CCTipoMovimento] = '303'
		u_log (_aCC)
	endif

	// Remove movimentos, se jah existirem
	if _lContinua
		incproc ('Exclusao de movimentos anteriores')
//		for _nCC = 1 to len (_aCC)
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "UPDATE " + RetSQLName ("SD3")
			_oSQL:_sQuery += " SET D_E_L_E_T_ = '*'"
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ' '"
			_oSQL:_sQuery +=   " AND D3_FILIAL  = '"  + XFilial("SD3") + "'"
			_oSQL:_sQuery +=   " AND D3_EMISSAO BETWEEN '" + _ddini + "' AND '"  + _ddfim + "'"
//			_oSQL:_sQuery +=   " AND D3_TM      = '" + _aCC [_nCC, .CCTipoMovimento] + "'"
			_oSQL:_sQuery +=   " AND D3_VACHVEX = '" + _sChaveSD3 + "'"
			_oSQL:Log ()
			if ! _oSQL:Exec ()
				u_help ('Nao foi possivel limpar movimentos anteriores',, .t.)
				_lContinua = .F.
			//	exit
			endif
//		next
	endif


	// Cria array com os produtos do tipo VD e seus saldos em estoque na data final do periodo.
	// Somente aqueles que nao tem mao de obra na estrutra (os demais custeiam pelo "AO-, GF- e AP-")
	if _lContinua
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
		_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                     " FROM " + RETSQLNAME ("SG1") + " SG1 "
		_oSQL:_sQuery +=                    " WHERE SG1.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=                      " AND SG1.G1_FILIAL   = '" + xfilial ("SG1") + "'"
		_oSQL:_sQuery +=                      " AND SG1.G1_COD      = SB1.B1_COD"
		_oSQL:_sQuery +=                      " AND SG1.G1_INI     <= '" + _dDFim + "'"
		_oSQL:_sQuery +=                      " AND SG1.G1_FIM     >= '" + _dDFim + "'"
		_oSQL:_sQuery +=                      " AND SG1.G1_COMP    LIKE 'MMM%'"
		_oSQL:_sQuery +=                    ")"
		_oSQL:_sQuery += " )"
		_oSQL:_sQuery += " SELECT C.*, SUM (SALDOESTQ) OVER () AS ESTQ_TOT"
		_oSQL:_sQuery +=  " FROM C"
		//_oSQL:_sQuery += " WHERE SALDOESTQ > 0"
		_oSQL:_sQuery += " WHERE SALDOESTQ > 0.01"  // Evita pegar produtos com saldo muito pequeno
		_oSQL:Log ()
		_aEstq = aclone (_oSQL:Qry2Array ())
		if len (_aEstq) == 0
			u_help ("Nao foi encontrado nenhum produto com estoque em " + dtoc (stod (_dDFim)) + " e que precise rateio.",, .t.)
			_lContinua = .F.
		else
			_nTotEstq = _aEstq [1, 4]
		endif
		u_log ('Estoques:', _aEstq)
	endif

	// Varre centros de custo criados a partir do desmembramento do antigo CC 'cantina'
	// e busca seus saldos.
	if _lContinua
		for _nCC = 1 to len (_aCC)
			u_logIni (_aCC [_nCC, .CCCodigo])
			incproc ('Verificacao saldos CC ' + _aCC [_nCC, .CCCodigo])

			// Busca saldo de contas de mao de obra.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT CT1_CONTA"
			_oSQL:_sQuery +=  " FROM " + Retsqlname("CT1") + " CT1"
			_oSQL:_sQuery += " WHERE " + Retsqlcond("CT1")
			_oSQL:_sQuery +=   " AND CT1_GRUPO = '0070'"
			u_log (_oSQL:_sQuery)
			_sAliasQ = _oSQL:Qry2Trb ()
			while !(_sAliasQ)->(eof())
				_nSaldo = MOVCUSTO((_sAliasQ)->CT1_CONTA,_aCC [_nCC, .CCCodigo], stod(_ddini),stod(_ddfim),"01", "1",3)
				if _nSaldo != 0
					u_log ('Saldo encontrado na cta', (_sAliasQ)->CT1_CONTA, '/ CC', _aCC [_nCC, .CCCodigo], ':', _nSaldo)
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
					u_log ('Saldo encontrado na cta', (_sAliasQ)->CT1_CONTA, '/ CC', _aCC [_nCC, .CCCodigo], ':', _nSaldo)
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
					u_log ('Saldo encontrado na cta', (_sAliasQ)->CT1_CONTA, '/ CC', _aCC [_nCC, .CCCodigo], ':', _nSaldo)
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
						u_log ('Saldo encontrado na cta', (_sAliasQ)->CT1_CONTA, '/ CC', _aCC [_nCC, .CCCodigo], ':', _nSaldo)
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
			u_log (_oSQL:_sQuery)
			_sAliasQ = _oSQL:Qry2Trb ()
			while !(_sAliasQ)->(eof())
				_nSaldo = MOVCUSTO ((_sAliasQ)->CT1_CONTA,_aCC [_nCC, .CCCodigo], stod(_ddini),stod(_ddfim),"01", "1", 3)
				if _nSaldo != 0
					u_log ('Saldo encontrado na cta', (_sAliasQ)->CT1_CONTA, '/ CC', _aCC [_nCC, .CCCodigo], ':', _nSaldo)
				endif 
				_aCC [_nCC, .CCSaldoApoio] += _nSaldo 
				(_sAliasQ)->(dbskip())
			enddo
			(_sAliasQ)->(dbclosearea())

			u_logFim (_aCC [_nCC, .CCCodigo])
		next
		u_log ('Saldos por CC:')
		u_log (_aCC)
	endif


	// Distribui os saldos de cada CC proporcionalmente aos estoques dos produtos.
	if _lContinua
		lErrAj := .F.
		procregua (len (_aCC) * len (_aEstq))
		for _nCC = 1 to len (_aCC)
			u_logIni (_aCC [_nCC, .CCCodigo])
			incproc ('Processando CC ' + _aCC [_nCC, .CCCodigo])
			
			_nSldMO    = _aCC [_nCC, .CCSaldoMO]
			_nSldGGF   = _aCC [_nCC, .CCSaldoGGF]
			_nSldSGru  = _aCC [_nCC, .CCSaldoSemGrupo]
			_nSldTra   = _aCC [_nCC, .CCSaldoTransf]
			_nSldApoio = _aCC [_nCC, .CCSaldoApoio]

			_nADistr := (_nSldMO + _nSldGGF + _nSldSGru + _nSldTra + _nSldApoio) * -1
			u_log ('Valor a distribuir:', _nADistr)
		
			_nSldMO *= -1
			_nSldGGF *= -1
			_nSldSGru *= -1
			for _nEstq = 1 to len (_aEstq)
				incproc ('CC ' + alltrim (_aCC [_nCC, .CCCodigo]) + ' - Prod. ' + _aEstq [_nEstq, 1])
				_nQtd = _aEstq [_nEstq, 3]
		
				// Gera, para cada produto, uma movimentacao de custo proporcional a seu estoque.
				_nCusMvTot = _nQtd * _nADistr / _nTotEstq

				u_log ('Prod. ' + _aEstq [_nEstq, 1], '_nCusMvTot:', _nCusMvTot)
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
					u_log (_aRequis)
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
					Endif
				endif
			next
			u_logFim (_aCC [_nCC, .CCCodigo])
			If lErrAj == .T.
				u_help ("Processo cancelado!",, .t.)
				Exit
			EndIf		
		next
	endif
	if ! _lContinua
		u_help ("Processo cancelado.",, .t.)
	else
		_aCols = {}
		aadd (_aCols, {.CCCodigo,        'C.custo',         90, ''})
		aadd (_aCols, {.CCDescricao,     'Descricao',      140, ''})
		aadd (_aCols, {.CCSaldoMO,       'Saldo MO',        50, '@E 999,999,999,999.99'})
		aadd (_aCols, {.CCSaldoGGF,      'Saldo GGF',       50, '@E 999,999,999,999.99'})
		aadd (_aCols, {.CCSaldoSemGrupo, 'Saldo sem grupo', 50, '@E 999,999,999,999.99'})
		aadd (_aCols, {.CCSaldoTransf,   'Saldo Transf',    50, '@E 999,999,999,999.99'})
		aadd (_aCols, {.CCSaldoApoio,    'Saldo apoio',     50, '@E 999,999,999,999.99'})
		aadd (_aCols, {.CCTipoMovimento, 'Tipo movto',      30, ''})
		U_F3Array (_aCC, "Valores rateados", _aCols, NIL,  NIL, 'Valores rateados sobre estoque total de ' + cvaltochar (_nTotEstq) + ' litros')
	endif
Return



// --------------------------------------------------------------------------
// Cria perguntas no SX1. Se a pergunta ja existir, atualiza. Se houver mais
// perguntas no SX1 do que as definidas aqui, deleta as excedentes do SX1.
// --------------------------------------------------------------------------
Static Function ValidPerg()
	local _aRegsPerg := {}
	local _aDefaults := {}

	//                     PERGUNT                           TIPO TAM DEC VALID F3  Opcoes          Help
	aadd (_aRegsPerg, {01, "Ultimo dia mes processamento  ", "D", 8,  0,  "",   "", {},             ""})
	aadd (_aRegsPerg, {02, "Ignora saldo ctas transferenc.", "N", 1,  0,  "",   "", {'Sim', 'Nao'}, ""})

	aadd (_aDefaults, {"02", 2})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
