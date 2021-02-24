// Programa:  ClsCtaCorr
// Autor:     Robert Koch
// Data:      03/08/2011
// Descricao: Declaracao de classe de representacao de movimentos da conta corrente dos associados da cooperativa.
//            Poderia trabalhar como uma include, mas prefiro declarar uma funcao de usuario
//            apenas para poder incluir no projeto e manter na pasta dos fontes.
//
// Historico de alteracoes:
// 02/09/2011 - Robert - Implementados metodos Grava, PodeIncl, GeraAtrib.
// 12/12/2011 - Robert - Implementados metodos Associar e Desassoc.
// 15/12/2011 - Robert - Permite ao usuario escolher se gera lctos. ao incluir movimento
//                       de associar/desassociar (para permitir inclusao de data de
//                       associacao de pessoas jah associadas antes de termos a cta.corrente).
// 05/01/2012 - Robert - Melhorias gerais geracao resgates quota capital no metodo 'Desassoc'.
// 20/01/2012 - Robert - Tratamentos para transferencia de saldo de quota capital.
// 17/04/2012 - Robert - Passa a permitir informar numero de parcelas para resgate de quota (desassociacao).
// 19/04/2012 - Robert - Metodo :SaldoEm considerava E5_VALOR + E5_VLDESCO e passa a considerar E5_VALOR + E5_VLDESCO - E5_VLJUROS - E5_VLMULTA.
//                     - Metodo :SaldoEm passa a desconsiderar E5_TIPODOC = 'JR'.
// 16/05/2012 - Robert - Funcao U_GeraSE2 recebe parametro adicional indicando se contabiliza online.
// 15/08/2012 - Robert - Metodo :SldQuotCap passa a usar codigo e loja base do associado.
// 02/09/2012 - Robert - Metodo :SaldoEm passa a buscar dados em funcao interna do SQL.
// 13/09/2012 - Robert - Passa a exigir forma de pagamento quando TM = 07.
// 11/10/2012 - Robert - Criado metodo TransFil e demais tratamentos para transf. saldo entre filiais.
// 20/11/2012 - Robert - Atributo OQueGera passa a ser um metodo, pois vai ser usado em mais lugares.
//                     - Criado tratamento para outros creditos com entrada de valor (gera SE5).
// 07/12/2012 - Robert - Permite incluir movimento 07 para ex-associado, mediante confirmacao.
// 10/12/2012 - Robert - Implementada geracao de DP no SE2 seguida de mov.bancario a receber no SE5.
// 07/03/2013 - Elaine - Method PodeIncl nao permite mais incluir se nao tiver um fornecedor informado caso o tipo de movimento for 03, 05 ou 06.             
// 15/08/2013 - Robert - Gravacao do campo ZI_ORIGEM.
// 16/08/2013 - Robert - Criado metodo HistTrFil.
// 29/07/2015 - Robert - Metodo HistTrFil substituido pelo HistBaixas (mais completo).
// 10/09/2015 - Robert - Leitura do parametro VA_USRCMCC trocada para validacao do grupo 051 da tabela ZZU.
// 11/09/2015 - Robert - Atributos TMCorrMonD e TMCorrMonC estavam sendo inicializados com conteudo invertido.
// 23/10/2015 - Robert - Transf. de saldo entre filiais libeada para qualquer tipo de movimento (antes era apenas TM=13).
// 26/10/2015 - Robert - Criado atributo SeqOrig (passa a ser exigido para inclusao por transf. de outra filial).
// 09/11/2015 - Robert - Ao gerar titulo tipo "DP+SE5_R" mandava a data de emissao em branco.
// 19/02/2016 - Robert - Criado tratamento para o campo ZI_PARCELA.
//                     - Funcao de geracao do SE2 passada de U_GeraSE2 para metodo interno desta classe.
//                     - Melhorada validacao de conta bancaria (para geracao de PA).
// 03/03/2016 - Robert - Exigia forma de pagamento 1 ou 2, mas temos novas opcoes (3 e 4).
// 26/04/2016 - Robert - Nao permite mais transferir saldo de movto tipo 07 entre filiais.
//                     - Criado atributo ::VctoSE2
//                     - Grava SE2 com parcela e vencimento sugeridos, quando possivel (util para casos de transf. entre filiais).
// 22/06/2016 - Robert - Permite inclusao quando nao socio, se tiver filial origem (pode ser transf. de saldo de cota, por exemplo).
// 23/06/2016 - Robert - Sugere datas para resgate de cota e permite ao usuario alterar.
// 11/08/2016 - Robert - Tratamento para a opcao '5' no campo ZX5_10GERI.
// 03/10/2016 - Robert - Passa a exigir nucleo / subnucleo informados no cadastro.
// 03/01/2016 - Robert - Criado metodo RecnoSE2().
//                     - Ajustes atualizacao do SE5 apos transf. saldo entre fiiais.
//                     - Metodo AtuSaldo() passa a buscar o saldo e fazer o ajuste (caso necessario), nao mais recebendo o saldo por parametro.  
// 12/01/2016 - Robert - Verifica saldo do capital antes de incluir movimento 27.
// 13/01/2016 - Robert - Rot.aut.geracao SE2 retornava erro em alguns casos mesmo tendo gravado o registro (mensagens de contabilizacao, por exemplo).
// 03/02/2017 - Robert - Tratamento para o tamanho do campo E5_HISTOR no update do SE5 no metodo GeraSE2().
// 06/02/2017 - Robert - Nao permite transferir saldo de movto que gerou mov.bancario no SE5.
// 14/06/2017 - Robert - Metodo GeraSE2() lia dados do SZI, exigindo que o arquivo estivesse posicionado.
// 06/09/2017 - Robert - Metodo PodeIncl() aceita movto.11 via confirmacao se for superusuario.
// 07/12/2017 - Robert - Gera SU5 no final do metodo Associar().
// 11/01/2018 - Catia  - Chamado 3350 - Nova validacao no conta corrente - nao permite incluir movimentos com o mesmo doc/prefixo/parcela - dava erro na rotina automatica do SE2
// 05/04/2018 - Robert - Eliminado campo zi_pjurmes (nunca fora usado)
// 15/05/2018 - Robert - Implementada gravacao da parcela no metodo Desassoc()
// 06/07/2018 - Robert - Busca saldo atual no SE2 para movtos a partir de 2018
// 21/01/2019 - Robert - Aceita movimento tipo 19 de ex assicoado.
// 29/01/2019 - Robert - Na exclusao do SZI, em vez de abrir tela para confirmar exclusao do titulo no financeiro, chama rotina automatica.
// 26/02/2019 - Robert - Data sugerida para inicio de resgate de sobras passa a ser sempre no ano seguinte.
// 05/03/2019 - Robert - Desabilitada chamada do metodo _oAssoc:GeraSU5 (associados agora sao cadastrados como clientes no SA1)
// 08/04/2019 - Catia  - include TbiConn.ch 
// 09/05/2019 - Robert - Pede confirmacao na inclusao manual de movimento tipo 19.
// 30/05/2019 - Robert - Grava FK2_HISTOR quando transferencia de saldo para outra filial.
// 06/12/2019 - Robert - Grava E2_VENCREA (estava ficando vazio)
// 21/01/2019 - Robert - Valida minimo de 15% do saldo de cota para transferir.
//                       Gera lctos de resgate somente para o codigo/loja base.
// 17/03/2020 - Robert - Passa a permitir inclusao de movtos que geram NDF (via solicitacao de confirmacao) - GLPI 7687
//                     - Comentariadas declaracoes de variaveis em desuso.
// 23/05/2020 - Robert - Criados tratamentos para :TM=31
//                     - Melhoradas algumas mensagens de erro e removidas linhas comentariadas
// 26/10/2020 - Robert - Na exclusao, exigia ZI_DATA = dDataBase. Agora exige E2_EMISSAO = dDataBase, que eh o que realmente importa.
// 08/01/2021 - Robert - Permite incluir TM 13 quando rotina U_VA_RUSN.
// 13/01/2021 - Robert - Permite incluir TM 16 quando ex socio.
//

// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"
#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
// Funcao declarada apenas para poder compilar este arquivo fonte.
user function ClsCtaCorr ()
return


// ==========================================================================
CLASS ClsCtaCorr

	// Declaracao das propriedades da Classe
	data Assoc
	data DebCred
	data Doc
	data DtMovto
	data Filial
	data FilDest
	data FilOrig
	data FormPag
	data Fornece
	data Histor
	data Loja
	data LojaFor
	data MesRef
	data Obs
	data Origem
	data Parcela
//	data PJurMes
	data RegSZI
	data SaldoAtu
	data SeqOrig
	data SeqSZI
	data Serie
	data TM
	data TMCapital
	data TMCorrMonC
	data TMCorrMonD
	data UltMsg
	data Usuario
	data Valor
	data Banco
	data Agencia
	data NumCon
	data VctoSE2

	// Declaracao dos Metodos da classe
	METHOD New ()
	METHOD AtuParcel ()
	METHOD Associar ()
	METHOD AtuSaldo ()
	METHOD AtuSldAsso ()
	METHOD ChaveExt ()
	METHOD Desassoc ()
	METHOD Exclui ()
	METHOD GeraAtrib ()
	METHOD GeraSE2 ()
	METHOD GeraSeq ()
	METHOD Grava ()
	METHOD HistBaixas ()
//	METHOD HistTrFil ()
	METHOD OQueGera ()
	METHOD PodeExcl ()
	METHOD PodeIncl ()
	METHOD RecnoSE2 ()
	METHOD SaldoEm ()
	METHOD TransFil ()
	METHOD VerifUser ()
ENDCLASS


// --------------------------------------------------------------------------
// Construtor.
METHOD New (_nRecno) Class ClsCtaCorr
	local _nRegSZI  := 0

	// Se receber numero de registro do SZI, alimenta atributos da classe com seus dados.
	if valtype (_nRecno) == "N"
		_nRegSZI = szi -> (recno ())
		szi -> (dbgoto (_nRecno))
		::GeraAtrib ("SZI")
		szi -> (dbgoto (_nRegSZI))
	else
		::GeraAtrib ("")
	endif
	
Return ::self



// --------------------------------------------------------------------------
// Trata casos em que, ao gravar o financeiro, eventualmente a parcela desejada jah
// exista e, nesse caso, eh necessario gerar uma nova.
METHOD AtuParcel (_sParc) Class ClsCtaCorr
	local _lContinua := .T.
	//u_logIni (GetClassName (::Self) + '.' + procname ())
	::Parcela = _sParc
	if ::RegSZI > 0  // Jah gravado no SZI
		szi -> (dbgoto (::RegSZI))
		if szi -> (recno ()) != ::RegSZI
			::UltMsg += "Nao foi possivel localizar o registro correspondente no arquivo SZI. Parcela nao vai ser atualizada."
			u_help (::UltMsg,, .t.)
			_lContinua = .F.
		else
			if szi -> zi_parcela != ::Parcela
				u_log ('[' + GetClassName (::Self) + '.' + procname () + '] Alterando parcela de', szi -> zi_parcela, 'para', ::Parcela)
				reclock ("SZI", .F.)
				szi -> zi_parcela = ::Parcela
				msunlock ()
			endif
		endif
	endif
	//u_logFim (GetClassName (::Self) + '.' + procname ())
return _lContinua



// --------------------------------------------------------------------------
// Procedimentos para associacao.
METHOD Associar () Class ClsCtaCorr
	local _lContinua := .T.
	local _oIntegr   := NIL

	u_logIni (GetClassName (::Self) + '.' + procname ())

	if _lContinua
		_oAssoc := ClsAssoc():New (::Assoc, ::Loja)
		if valtype (_oAssoc) != "O"
			_lContinua = .F.
		endif
	endif

	// Gera lancamento para integralizacao de capital.
	if _lContinua
		if msgyesno ("O registro de um novo associado costuma gerar uma pendencia para integralizacao de capital. Deseja gerar esse lancamento agora?")
			zx5 -> (dbsetorder (2))  // ZX5_FILIAL+ZX5_TABELA+ZX5_10COD
			if ! zx5 -> (dbseek (xfilial ("ZX5") + "10" + "12", .F.))
				u_help ("Tipo de movimento '12' nao cadastrado na tabela de movimentos de conta corrente.",, .t.)
				_lContinua = .F.
			else
				_oIntegr := ClsCtaCorr():New ()
				_oIntegr:Assoc      = ::Assoc
				_oIntegr:Loja       = ::Loja
				_oIntegr:TM         = '12'
				_oIntegr:DtMovto    = dDataBase
				_oIntegr:Doc        = ::Doc
				_oIntegr:Serie      = zx5 -> zx5_10Pref
				_oIntegr:MesRef     = ::MesRef
				_oIntegr:Histor     = "INTEGRALIZ.CAPITAL " + alltrim (_oAssoc:Nome)
				_oIntegr:Valor      = GetMV ("VA_VLRJOIA")  // Cfe. estatuto social 2013, corresp. 1.000 Kg de uva Isabel.
				if _oIntegr:PodeIncl ()
					_lContinua = _oIntegr:Grava ()
				else
					u_help ("Erro na geracao dos registros de integralizacao de capital.",, .t.)
					_lContinua = .F.
				endif
			endif
		endif
	endif

	u_logFim (GetClassName (::Self) + '.' + procname ())
return _lContinua



// --------------------------------------------------------------------------
// Atualiza saldo do movimento.
METHOD AtuSaldo () Class ClsCtaCorr
	local _lContinua := .T.
	local _nSaldo    := 0
	local _aAreaSE2  := {}

	//u_logIni (GetClassName (::Self) + '.' + procname ())
	::UltMsg = ""

	if _lContinua
		szi -> (dbgoto (::RegSZI))
		if szi -> (recno ()) != ::RegSZI
			::UltMsg += "Nao foi possivel localizar o registro correspondente no arquivo SZI. Saldo nao pode ser atualizado."
			u_help (::UltMsg,, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		// A partir de 2018 estou tentando manter 100% fiel ao financeiro.
		if ::DtMovto >= stod ('20180101')
			// Se tem titulo correspondente no financeiro, busca direto dele.
			_aAreaSE2 := se2 -> (getarea ())
			se2 -> (dbsetorder (6))  // E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO
			if se2 -> (dbseek (xfilial ("SE2") + ::Assoc + ::Loja + ::Serie + ::Doc + ::Parcela, .F.))
	//			u_log ('Encontrei SE2 com saldo ', se2 -> e2_saldo)
				//u_logtrb ('SE2')
				_nSaldo = se2 -> e2_saldo
			else
				u_log ('Nao Encontrei SE2. Pegando saldo pelo metodo tradicional.')
				_nSaldo = ::SaldoEm (date ())
			endif
			se2 -> (restarea (_aAreaSE2))
		else		 
			_nSaldo = ::SaldoEm (date ())
		endif
		
		if szi -> zi_saldo != _nSaldo
			u_log2 ('INFO', '[' + GetClassName (::Self) + '.' + procname () + '] Alterando saldo SZI doc ' + szi -> zi_doc + '/' + szi -> zi_serie + '-' + szi -> zi_parcela + ' de ' + CVALTOCHAR (szi -> zi_saldo) + ' para ' + cvaltochar (_nSaldo))
			reclock ("SZI", .F.)
			szi -> zi_saldo = _nSaldo
			msunlock ()
			::SaldoAtu = _nSaldo
	
			// Atualiza saldo do Associado
			::AtuSldAsso ()
		endif
	endif

	//u_logFim (GetClassName (::Self) + '.' + procname ())
return _lContinua



// --------------------------------------------------------------------------
// Atualiza saldo do associado.
METHOD AtuSldAsso () Class ClsCtaCorr
	local _lContinua := .T.
	local _oAssoc    := ""

	if _lContinua
		_oAssoc := ClsAssoc():New (::Assoc, ::Loja)
		if valtype (_oAssoc) == "O"
//			_oAssoc:AtuSaldo (::DtMovto)
			processa ({ || _oAssoc:AtuSaldo (::DtMovto)})
		else
			::UltMsg += " Nao foi possivel instanciar associado "
			_lContinua = .F.
		endif
	endif
return _lContinua



// --------------------------------------------------------------------------
// Gera chave externa para outros arquivos do sistema.
METHOD ChaveExt () Class ClsCtaCorr
return 'SZI' + ::Assoc + ::Loja + ::SeqSZI



// --------------------------------------------------------------------------
// Procedimentos para desassociacao.
METHOD Desassoc () Class ClsCtaCorr
	local _lContinua := .T.
	local _nQuota    := 0
	local _sAnoMes   := ""
	local _nParc     := 0
	local _oDUtil    := ClsDUtil():New ()
	local _oAUtil    := ClsAUtil():New ()
	local _oAssoc    := NIL
	local _dPrimVcto := ctod ('')
	local _dData     := ctod ('')
	local _nQtParcel := 0
	local _sJustif   := ""

	u_logIni (GetClassName (::Self) + '.' + procname ())

	if _lContinua
		_oAssoc := ClsAssoc():New (::Assoc, ::Loja)
		if valtype (_oAssoc) != "O"
			_lContinua = .F.
		endif
	endif
//	if _lContinua

	// Gera lctos de resgate somente para o codigo/loja base
	if _lContinua .and. (_oAssoc:Codigo + _oAssoc:Loja == _oAssoc:CodBase + _oAssoc:LojaBase)
		_nQuota = _oAssoc:SldQuotCap (::DtMovto) [1]
		u_log ("Saldo quota capital:", _nQuota)
		if msgyesno ("O desligamento de um associado deveria gerar lancamentos para resgate de saldo de quota capital." + chr (13) + chr (10) + ;
		             "Saldo a resgatar: " + alltrim (transform (_nQuota, "@E 999,999,999.99")) + chr (13) + chr (10) + ;
		             "Deseja gerar esses lancamentos agora?")
			if _nQuota == 0
				u_help ("Nao ha saldo de quota capital para este associado. Lancamentos de resgate nao serao gerados.")
			else
				zx5 -> (dbsetorder (2))  // ZX5_FILIAL+ZX5_TABELA+ZX5_10COD
				if ! zx5 -> (dbseek (xfilial ("ZX5") + "10" + "11", .F.))
					u_help ("Tipo de movimento '11' nao cadastrado na tabela de movimentos de conta corrente.",, .t.)
					_lContinua = .F.
				else

					// Para valores abaixo de 5000 pode ser em parcela unica.
					if _nQuota <= 6180  // Alterado de 5000 para 6180 em 26/02/2019
						_nQtParcel = 1
					else
						_nQtParcel = 5
					endif
					do while .T.
						_nQtParcel = U_Get ("Quantidade de parcelas para pagamento", "N", 2, "99", "", _nQtParcel, .F., ".T.")
						if _nQtParcel < 1
							loop
						endif
						if _nQuota > 5000 .and. _nQtParcel < 5
							_sJustif = U_Get ("Jutifique o uso de menos parcelas", "C", 80, "@!", "", space (80), .F., ".T.")
							if empty (_sJustif)
								loop
							endif
						endif
						exit
					enddo

					CursorWait ()
					
					// Inicia os pagtos no mes posterior `a realizacao (prevista) da assembleia (atualmente, abril).
					// Se for apos o termino de pagamentos da safra, joga para o ano seguinte.
					do while .T.
						// Sempre no ano seguinte.
						_dPrimVcto = stod (strzero (year (::DtMovto) + 1, 4) + '0401')
						_dPrimVcto = U_Get ("Data para primeiro resgate de cota capital", "D", 10, "@D", "", _dPrimVcto, .F., '.t.')
						if _dPrimVcto == NIL
							_dPrimVcto = ::DtMovto
						else
							exit
						endif
					enddo

					// Gera array de linhas com datas para distribuicao do saldo em parcelas anuais, cfe. estatuto.
					_oAUtil:_aArray = {}
					_sAnoMes = left (dtos (_dPrimVcto), 6)
					_dData = datavalida (stod (_sAnoMes + strzero (day (_dPrimVcto), 2)))
					for _nParc = 1 to _nQtParcel
						aadd (_oAUtil:_aArray, {_dData, 0})
						_sAnoMes = _oDUtil:SomaMes (_sAnoMes, 12)
						_dData = datavalida (stod (_sAnoMes + strzero (day (_dPrimVcto), 2)))

						// Tratamento para casos em que a data ficaria invalida (anos bissextos, por exemplo).
						if empty (_dData)
							_dData = datavalida (stod (_sAnoMes + strzero (day (_dPrimVcto) - 1, 2)))
						endif
						if empty (_dData)
							_dData = datavalida (stod (_sAnoMes + strzero (day (_dPrimVcto) - 2, 2)))
						endif

					next
					u_log (_oAUtil:_aArray)
					
					// Faz a distribuicao do saldo entre as parcelas.
					_oAUtil:Dist (2, _nQuota, 2, 'P')
					u_log ('parcelas distribuidas:', _oAUtil:_aArray)
			
					// Gera um novo movimento na conta corrente para cada parcela.
					CursorWait ()
					for _nParc = 1 to len (_oAUtil:_aArray)
						u_log ("Gerando parc. ", _nparc)
						_oParc := ClsCtaCorr():New ()
						_oParc:Assoc      = ::Assoc
						_oParc:Loja       = ::Loja
						_oParc:TM         = '11'
						_oParc:DtMovto    = _oAUtil:_aArray [_nParc, 1]
						_oParc:Doc        = ::Doc
						_oParc:Serie      = zx5 -> zx5_10Pref
						_oParc:MesRef     = strzero(month(_oParc:DtMovto),2)+strzero(year(_oParc:DtMovto),4)
						_oParc:Histor     = "RESG.CTA.CAP." + cvaltochar (_nParc) + "/" + cvaltochar (len (_oAUtil:_aArray)) + " " + alltrim (_oAssoc:Nome)
						_oParc:Valor      = _oAUtil:_aArray [_nParc, 2]
						_oParc:Obs        = _sJustif
						_oParc:Parcela    = cvaltochar (_nParc)
						if _oParc:PodeIncl ()
							_lContinua = _oParc:Grava (.F., .F.)
						else
							u_help ("Erro na geracao dos registros de resgate da quota capital. O desligamento nao pode ser gravado. Revise a possivel gravacao dos titulos de resgate de cota.",, .t.)
							_lContinua = .F.
							exit
						endif
					next
					CursorArrow ()
			
					// Mostra valores para informacao do usuario.
					if _lContinua
						u_F3Array (_oAUtil:_aArray, "Resgates", NIL, 350, 300, "Previsoes de resgates da quota capital gerados:", "Valor total: " + alltrim (transform (_nQuota, "@E 999,999.99")), .F.)
					endif
				endif
			endif
		endif
	endif
	u_logFim (GetClassName (::Self) + '.' + procname ())
return _lContinua



// --------------------------------------------------------------------------
// Exclui movimento.
METHOD Exclui () Class ClsCtaCorr
	local _lContinua := .T.
	local _aAutoSE2  := {}

	//u_logIni (GetClassName (::Self) + '.' + procname ())
	::UltMsg = ""

	u_log2 ('info', '[' + GetClassName (::Self) + '.' + procname () + '] Excluindo ZI_DOC = ' + ::Doc + '/' + ::Serie + '-' + ::Parcela + ' $ ' + transform (::Valor, "@E 999,999,999.99"))
	
	if _lContinua
		szi -> (dbgoto (::RegSZI))
		if szi -> (recno ()) != ::RegSZI
			::UltMsg += "Nao foi possivel localizar o registro correspondente no arquivo SZI. Exclusao nao sera' efetuada."
			u_help (::UltMsg,, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		// Se a chamada for feita para um registro do SZI jah deletado, eh por que a exclusao
		// estah sendo feita pela tela de manutencao do SZI e o registro do SZI jah foi deletado.
		// Faltaria, no caso, fazer as exclusoes de dados relacionados.
		if ! szi -> (deleted ())
			//u_log ('excluindo szi')
			reclock ("SZI", .F.)
			szi -> (dbdelete ())
			msunlock ()
			
		endif
		//u_log ('cod memo:', szi -> zi_CodMemo)

		// Exclui campo memo.
		if ! empty (szi -> zi_CodMemo)
			CursorWait ()
			msmm (szi -> zi_CodMemo,,,, 2,,, "SZI", "ZI_CODMEMO")
			Cursorarrow ()
		endif
	endif

	// Exclui movimentacao do SE2, caso exista.
	if _lContinua
		if ! U_TemNick ("SE2", "E2_VACHVEX")
			_lContinua = .F.
			::UltMsg += "Problema nos indices de arquivos (indice E2_VACHVEX nao encontrado). Acione suporte."
			u_help (::UltMsg,, .t.)
			U_AvisaTI (::UltMsg + " --> Falta indice no SE2 para exclusao de movto da conta corrente de associados na rotina " + procname ())
		endif
		if _lContinua
			se2 -> (dbOrderNickName ("E2_VACHVEX"))  // E2_FILIAL+E2_VACHVEX
			if se2 -> (dbseek (xfilial ("SE2") + ::ChaveExt (), .F.))

				// Descalculo de correcao monetaria nao abre tela para excluir titulo manualmente.
				if ::TM $ ::TMCorrMonC + ::TMCorrMonD

					if se2 -> e2_saldo != se2 -> e2_valor
						::UltMsg += "Este lancamento nao sera' excluido, pois o titulo relacionado a este movimento no modulo financeiro tem saldo diferente do valor original e nao foi excluido."
						u_help (::UltMsg,, .t.)
						_lContinua = .F.
					else
						reclock ("SE2", .F.)
						se2 -> (dbdelete ())
						msunlock ()
					endif
				else

					//u_help ("Este movimento gerou um titulo no financeiro e, para finalizar sua exclusao, confirme, antes, a exclusao do financeiro na tela a seguir.")
					//fina050 (NIL, NIL, 5)

					_aAutoSE2 := {}
					aadd (_aAutoSE2, {"E2_PREFIXO", se2 -> e2_prefixo, NIL})
					aadd (_aAutoSE2, {"E2_NUM"    , se2 -> e2_num,     Nil})
					aadd (_aAutoSE2, {"E2_PARCELA", se2 -> e2_parcela, Nil})
					aadd (_aAutoSE2, {"E2_TIPO"   , se2 -> e2_tipo,    Nil})
					aadd (_aAutoSE2, {"E2_FORNECE", se2 -> e2_fornece, Nil})
					aadd (_aAutoSE2, {"E2_LOJA"   , se2 -> e2_loja,    Nil})
					_aAutoSE2 := aclone (U_OrdAuto (_aAutoSE2))
					//u_log (_aAutoSE2)
					lMsErroAuto	:=	.f.
					lMsHelpAuto	:=	.f.
					dbselectarea ("SE2")
					dbsetorder (1)
					Processa({|| MsExecAuto({ | x,y,z | Fina050(x,y,z) }, _aAutoSE2,, 5)},"Excluindo titulo correspondente no financeiro.")
					if lMsErroAuto
						::UltMsg += U_LeErro (memoread (NomeAutoLog ())) + "; Este lancamento nao sera' excluido, pois o titulo relacionado a este movimento no modulo financeiro continua existindo."
						u_help (::UltMsg,, .t.)
						_lContinua = .F.
					endif
				endif
			endif
		endif
	endif

	// Estorna movimentacao do SE5, caso exista.
	if _lContinua .and. ::OQueGera () == "DP+SE5_R"
		if ! U_TemNick ("SE5", "E5_VACHVEX")
			_lContinua = .F.
			::UltMsg += "Problema nos indices de arquivos. Acione suporte."
			u_help (::UltMsg,, .t.)
			U_AvisaTI (::UltMsg + " --> Falta indice no SE5 para exclusao de movto da conta corrente de associados na rotina " + procname ())
		endif
		if _lContinua
			se5 -> (dbOrderNickName ("E5_VACHVEX"))  // E5_FILIAL+E5_VACHVEX
			if se5 -> (dbseek (xfilial ("SE5") + ::ChaveExt (), .F.))
				u_log ('vou gerar cancelamento do SE5 a receber')
				if ! U_GeraSE5 ("CR", ::DtMovto, ::Valor, ::Histor, ::Banco, ::Agencia, ::NumCon, ::ChaveExt (), @::UltMsg, iif (type ('_lCtOnLine') == 'L', _lCtOnLine, .F.), '110104', ::FormPag)
					::UltMsg += "Erro no estorno do movimento financeiro a receber. Este registro nao sera' excluido."
					_lContinua = .F.
				endif
			endif
		endif
	endif

	// Se deu algum problema na exclusao dos dados relacionados, recupera o registro no SZI e notifica o usuario.
	if ! _lContinua .and. szi -> (deleted ())
		::UltMsg += "Problemas no processamento. Este registro nao sera' excluido."
		u_help (::UltMsg,, .t.)
		reclock ("SZI", .F.)
		szi -> (dbrecall ())
		msunlock ()

	endif

	// Atualiza saldo do Associado
	if _lContinua                                          
		if upper(alltrim(getenvserver())) == 'ROBERT' .and. dtos (date ()) == '20190205'
			// hoje to re-re-refazendo distr.sobras....
		else
			::AtuSldAsso ()
		endif
	endif

	//u_logFim (GetClassName (::Self) + '.' + procname ())
return _lContinua



// --------------------------------------------------------------------------
// Alimenta os atributos da classe.
METHOD GeraAtrib (_sOrigem) Class ClsCtaCorr
	local _aAreaAnt := U_ML_SRArea ()
	local _sQuery   := ""
	local _oSQL     := NIL
	local _nRetSQL  := 0

	// Defaults
	::Filial     = xfilial ("SZI")
	::Assoc      = ''
	::Loja       = ''
	::SeqSZI     = ''
	::Fornece    = ''
	::LojaFor    = ''
	::RegSZI     = 0
	::TM         = ''
	::DtMovto    = ctod ('')
	::TMCorrMonD = '15'
	::TMCorrMonC = '14'
	::TMCapital  = ''
	::UltMsg     = ''
	::Valor      = 0
	::SaldoAtu   = 0
	::Histor     = ''
	::MesRef     = ''
	::Doc        = ''
	::SeqOrig    = ''
	::Serie      = ''
	::Obs        = ''
	::Origem     = ''
	::FilDest    = ''
	::FilOrig    = ''
	::Usuario    = cUserName
	::DebCred    = ''
	::FormPag    = ''
	::Banco      = ''
	::Agencia    = ''
	::NumCon     = ''
	::Parcela    = ''
	::VctoSE2    = ctod ('')

	if _sOrigem == 'M'  // Variaveis M->
		::Filial   = xfilial ("SZI")
		::Assoc    = m->zi_assoc
		::Loja     = m->zi_lojasso
		::SeqSZI   = m->zi_seq
		::Fornece  = m->zi_fornece
		::LojaFor  = m->zi_lojafor
		::TM       = m->zi_tm
		::DtMovto  = m->zi_data
		::Valor    = m->zi_valor
		::SaldoAtu = m->zi_saldo
		::Usuario  = m->zi_user
		::Histor   = m->zi_histor
		::MesRef   = m->zi_mesref
		::Doc      = m->zi_doc
		::SeqOrig  = ''  // Campo nao existe na tabela.
		::Serie    = m->zi_serie
		::Obs      = m->zi_obs
		::FilOrig  = m->zi_filorig
		::FormPag  = m->zi_FormPag
		::Banco    = m->zi_banco
		::Agencia  = m->zi_agencia
		::NumCon   = m->zi_numcon
		::Origem   = m->zi_origem
		::Parcela  = m->zi_parcela
	elseif _sOrigem == "SZI"
		::Filial   = szi -> zi_filial
		::RegSZI   = szi -> (recno ())
		::Assoc    = szi -> zi_assoc
		::Loja     = szi -> zi_lojasso
		::SeqSZI   = szi -> zi_seq
		::Fornece  = szi -> zi_fornece
		::LojaFor  = szi -> zi_lojafor
		::TM       = szi -> zi_tm
		::DtMovto  = szi -> zi_data
		::Valor    = szi -> zi_valor
		::SaldoAtu = szi -> zi_saldo
		::Usuario  = szi -> zi_user
		::Histor   = szi -> zi_histor
		::MesRef   = szi -> zi_mesref
		::Doc      = szi -> zi_doc
		::SeqOrig  = ''  // Campo nao existe na tabela.
		::Serie    = szi -> zi_serie
		::FilOrig  = szi -> zi_FilOrig
		::FormPag  = szi -> zi_FormPag
		::Banco    = szi -> zi_banco
		::Agencia  = szi -> zi_agencia
		::NumCon   = szi -> zi_numcon
		::Origem   = szi -> zi_origem
		::Parcela  = szi -> zi_parcela
		if ! empty (szi -> zi_codmemo)
			::Obs = alltrim (msmm (szi -> zi_codmemo,,,,3,,,'SZI'))
		endif
		
		// Busca dados do SE2, caso exista (nem todos os movimentos geram SE2).
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""                                                                                            
		_oSQL:_sQuery += " SELECT TOP 1 E2_VENCTO"  // Soh deveria encontrar uma ocorrencia, mas usei TOP 1 para garantir.
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2 "
		_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " AND SE2.E2_FILIAL   = '" + xfilial ("SE2")   + "'"
		_oSQL:_sQuery +=    " AND SE2.E2_FORNECE  = '" + szi -> zi_assoc   + "'"
		_oSQL:_sQuery +=    " AND SE2.E2_LOJA     = '" + szi -> zi_lojasso + "'"
		_oSQL:_sQuery +=    " AND SE2.E2_NUM      = '" + szi -> zi_doc     + "'"
		_oSQL:_sQuery +=    " AND SE2.E2_PREFIXO  = '" + szi -> zi_serie   + "'"
		_oSQL:_sQuery +=    " AND SE2.E2_PARCELA  = '" + szi -> zi_parcela + "'"
		::VctoSE2 = _oSQL:RetQry ()
	endif

	// Define se o tipo de movimento eh considerado a debito ou a credito.
	::DebCred = ""
	if ! empty (::TM)
		::DebCred = fBuscaCpo ("ZX5", 2, xfilial ("ZX5") + '10' + ::TM, "ZX5_10DC")
	endif

	// Monta lista de tipos de movimentos referentes a controle de capital social.
	_sQuery := ""
	_sQuery += "SELECT ZX5_10COD"
	_sQuery +=  " FROM " + RetSQLName ("ZX5")
	_sQuery += " WHERE D_E_L_E_T_ = ''"
	_sQuery +=   " AND ZX5_FILIAL = (SELECT CASE ZX5_MODO WHEN 'C' THEN '  ' ELSE '" + cFilAnt + "' END"
	_sQuery +=                        " FROM " + RetSQLName ("ZX5")
	_sQuery +=                       " WHERE D_E_L_E_T_ = ''"
	_sQuery +=                         " AND ZX5_FILIAL = '  '"
	_sQuery +=                         " AND ZX5_TABELA = '00'"
	_sQuery +=                         " AND ZX5_CHAVE  = '10')"
	_sQuery +=   " AND ZX5_TABELA = '10'"
	_sQuery +=   " AND ZX5_10CAPI = 'S'"
	_aRetSQL = U_Qry2Array (_sQuery)
	::TMCapital = ""
	for _nRetSQL = 1 to len (_aRetSQL)
		::TMCapital += _aRetSQL [_nRetSQL, 1] + iif (_nRetSQL < len (_aRetSQL), '/', '')
	next

	U_ML_SRArea (_aAreaAnt)
	//u_log2 ('debug', 'Gerei DtMovto com ' + cvaltochar (::DtMovto)) 
return



// --------------------------------------------------------------------------
METHOD GeraSE2 (_sOQueGera, _dEmissao, _lCtOnLine) class ClsCtaCorr
	local _lContinua  := .T.
	local _aAutoSE2   := {}
	local _sParcela   := ""
	local _sSQL       := ""
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	local _aBkpSX1    := {}
	local _oSQL       := NIL
	local _sChvEx     := ::ChaveExt ()
	local _aRetParc   := {}
	local _dDtVenc    := ctod ('')

	//u_logIni (GetClassName (::Self) + '.' + procname ())
	
	// A rotina FINA050 soh funciona dentro destes modulos.
	If _lContinua .and. !(AmIIn(5,6,7,11,12,14,41,97,17))           // Somente Fin,GPE, Vei, Loja , Ofi, Pecas e Esp, EIC
		::UltMsg += "FINA050 funciona apenas nos seguintes modulos: Fin,GPE, Vei, Loja , Ofi, Pecas e Esp, EIC"
		_lContinua = .F.
	endif

	if _lContinua .and. empty (_sOQueGera)
		::UltMsg += "Tipo de titulo nao definido para geracao do arquivo SE2."
		_lContinua = .F.
	endif
	if _lContinua .and. empty (::Serie) .or. empty (::Doc)
		::UltMsg += "Serie ou numero de documento nao definido para geracao do arquivo SE2."
		_lContinua = .F.
	endif
	if _lContinua .and. empty (_dEmissao)
		::UltMsg += "Data de emissao deve ser informada para geracao do arquivo SE2."
		_lContinua = .F.
	endif

	// Se vai gerar um PA, precisa dados do banco.
	if _lContinua .and. _sOQueGera == 'PA'
		if empty (::Banco) .or. empty (::Agencia) .or. empty (::NumCon)
			::UltMsg += "Banco/agencia/conta devem ser informados para geracao do arquivo SE2 quando tipo PA."
			_lContinua = .F.
		else
			// Alimenta variaveis private usadas em inicializadores de campos, gatilhos, etc.
			_SZI_Bco = ::Banco
			_SZI_Age = ::Agencia
			_SZI_Cta = ::NumCon
		endif
	endif

	if _lContinua
		// Se possivel, grava a parcela sugerida. Senao, encontra a maior parcela jah existente e gera a proxima.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""                                                                                            
		_oSQL:_sQuery += " select IsNull (max (E2_PARCELA), '1'),"  // Se nao encontrar nada, retorna 1
		_oSQL:_sQuery +=        " SUM (CASE E2_PARCELA WHEN '" + ::Parcela + "' THEN 1 ELSE 0 END)"  // Contagem de ocorrencias da parcela desejada.
		_oSQL:_sQuery +=   " from " + RetSQLName ("SE2") + " SE2 "
		_oSQL:_sQuery +=  " where SE2.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " and SE2.E2_FILIAL   = '" + xfilial ("SE2")   + "'"
		_oSQL:_sQuery +=    " and SE2.E2_FORNECE  = '" + ::Assoc + "'"
		_oSQL:_sQuery +=    " and SE2.E2_LOJA     = '" + ::Loja  + "'"
		_oSQL:_sQuery +=    " and SE2.E2_NUM      = '" + ::Doc   + "'"
		_oSQL:_sQuery +=    " and SE2.E2_PREFIXO  = '" + ::Serie + "'"
		_aRetParc = aclone (_oSQL:Qry2Array ())
		if _aRetParc [1, 2] == 0  // Nao encontrou nenhuma ocorrencia da parcela desejada
			//u_log ('Mantendo a parcela desejada:', ::Parcela)
			_sParcela = ::Parcela
		else
			_sParcela = soma1 (_aRetParc [1, 1])
			u_log2 ('aviso', '[' + procname () + '] Alterando da parcela desejada (' + ::Parcela + ') para: ' + _sParcela)
		endif

		// Vencimento nao pode ser menor que a data base
		if ! empty (::VctoSE2) .and. ::VctoSE2 < dDataBase
			::VctoSE2 = dDataBase
		endif
		_dDtVenc = iif (! empty (::VctoSE2), ::VctoSE2, ::DtMovto)

		// Gera titulo no contas a pagar.
		_aAutoSE2 := {}
		aadd (_aAutoSE2, {"E2_PREFIXO", ::Serie,   NIL})
		aadd (_aAutoSE2, {"E2_NUM"    , ::Doc,     Nil})
		aadd (_aAutoSE2, {"E2_TIPO"   , _sOQueGera,        Nil})
		aadd (_aAutoSE2, {"E2_FORNECE", ::Assoc,   Nil})
		aadd (_aAutoSE2, {"E2_LOJA"   , ::Loja, Nil})
		aadd (_aAutoSE2, {"E2_EMISSAO", _dEmissao,         Nil})
		aadd (_aAutoSE2, {"E2_VENCTO" , _dDtVenc,    Nil})
		aadd (_aAutoSE2, {"E2_VENCREA", DataValida (_dDtVenc),    Nil})
		aadd (_aAutoSE2, {"E2_VALOR"  , ::Valor,   Nil})
		aadd (_aAutoSE2, {"E2_HIST"   , ::Histor,  Nil})
		aadd (_aAutoSE2, {"E2_PARCELA", _sParcela,         Nil})
		aadd (_aAutoSE2, {"E2_VACHVEX", _sChvEx,           Nil})
		aadd (_aAutoSE2, {"E2_ORIGEM" , "FINA050" ,        Nil})
		_aAutoSE2 := aclone (U_OrdAuto (_aAutoSE2))
//		u_log (_aAutoSE2)

		// Ajusta parametros da rotina.
		cPerg = 'FIN050    '
		_aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
		U_GravaSX1 (cPerg, "04", iif (_lCtOnLine, 1, 2))

		lMsErroAuto	:=	.f.
		lMsHelpAuto	:=	.f.
		dbselectarea ("SE2")
		dbsetorder (1)
		MsExecAuto({ | x,y,z | Fina050(x,y,z) }, _aAutoSE2,, 3)
		if lMsErroAuto

			// Verifica se o titulo foi gravado, pois casos de avisos na contabilizacao sao entendidos como erros, mas a gravacao ocorre normalmente.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT COUNT (*)"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2")
			_oSQL:_sQuery +=  " WHERE E2_FILIAL  = '" + xfilial ("SE5") + "'"
			_oSQL:_sQuery +=    " AND E2_PREFIXO = '" + ::Serie   + "'"
			_oSQL:_sQuery +=    " AND E2_NUM     = '" + ::Doc     + "'"
			_oSQL:_sQuery +=    " AND E2_PARCELA = '" + _sParcela + "'"
			_oSQL:_sQuery +=    " AND E2_FORNECE = '" + ::Assoc   + "'"
			_oSQL:_sQuery +=    " AND E2_LOJA    = '" + ::Loja    + "'"
			_oSQL:_sQuery +=    " AND D_E_L_E_T_ = ''"
			_oSQL:Log ()
			if _oSQL:RetQry () == 0
				::UltMsg += "Erro na rotina automatica de inclusao de contas a pagar:" + U_LeErro (memoread (NomeAutoLog ()))
				_lContinua = .F.
				MostraErro()
			endif
		endif
		
		// Atualiza a conta corrente com a parcela gerada (talvez jah existisse no SE2 e tive que gerar uma nova)
		if _lContinua
			_lContinua = ::AtuParcel (se2 -> e2_parcela)
		endif
		U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina.
	endif
	
	// Verifica se a chave externa foi gravada.
	if _lContinua .and. ! empty (_sChvEx)
		if ! U_TemNick ("SE2", "E2_VACHVEX")
			::UltMsg += "Falta indice 'E2_VACHVEX' para a conta corrente de associados na rotina " + procname () + '.'
			U_AvisaTI (::UltMsg)
			_lContinua = .F.
		else
			se2 -> (dbOrderNickName ("E2_VACHVEX"))  // E2_FILIAL+E2_VACHVEX
			if ! se2 -> (dbseek (xfilial ("SE2") + _sChvEx, .F.))
				::UltMsg += "Erro na gravacao do SE2: Foi gerado titulo no financeiro, mas a amarracao com chave externa nao foi feita."
				_lContinua = .F.
			endif
		endif
	endif

	// Atualiza SE5.
	if _lContinua .and. _sOQueGera == 'PA'
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""                                                                                            
		_oSQL:_sQuery += " UPDATE " + RetSQLName ("SE5")
		_oSQL:_sQuery +=    " SET E5_TIPODOC = 'PA',"  // O campo E5_TIPODOC fica com 'BA' via rotina automatica (seria sem movto. bancario)
		_oSQL:_sQuery +=        " E5_HISTOR  = '" + left (::Histor, tamsx3 ("E5_HISTOR")[1]) + "',"
		_oSQL:_sQuery +=        " E5_VACHVEX = '" + _sChvEx + "'"
		_oSQL:_sQuery +=  " WHERE E5_FILIAL  = '" + xfilial ("SE5") + "'"
		_oSQL:_sQuery +=    " AND E5_DATA    = '" + dtos (se2 -> e2_emissao) + "'"
		_oSQL:_sQuery +=    " AND E5_PREFIXO = '" + se2 -> e2_prefixo + "'"
		_oSQL:_sQuery +=    " AND E5_NUMERO  = '" + se2 -> e2_num     + "'"
		_oSQL:_sQuery +=    " AND E5_PARCELA = '" + se2 -> e2_parcela + "'"
		_oSQL:_sQuery +=    " AND E5_CLIFOR  = '" + se2 -> e2_fornece + "'"
		_oSQL:_sQuery +=    " AND E5_LOJA    = '" + se2 -> e2_loja    + "'"
		_oSQL:_sQuery +=    " AND E5_BANCO   = '" + _SZI_Bco + "'"
		_oSQL:_sQuery +=    " AND E5_AGENCIA = '" + _SZI_Age + "'"
		_oSQL:_sQuery +=    " AND E5_CONTA   = '" + _SZI_Cta + "'"
		_oSQL:_sQuery +=    " AND E5_RECPAG  = 'P'"
		_oSQL:_sQuery +=    " AND E5_TIPO    = 'PA'"
		_oSQL:_sQuery +=    " AND E5_TIPODOC IN ('PA','BA')"  // Mesmo que jah esteja PA, preciso atualizar os demais campos.
		_oSQL:_sQuery +=    " AND D_E_L_E_T_ = ''"
		//_oSQL:Log ()
		if ! _oSQL:Exec ()
			::UltMsg += "Erro na atualizacao do SE5 - rotina " + procname () + " - comando: " + _sSQL
			_lContinua = .F.
		endif
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	//u_logFim (GetClassName (::Self) + '.' + procname ())
return _lContinua



// --------------------------------------------------------------------------
// Gera sequencial para o registro atual do SZI.
METHOD GeraSeq () Class ClsCtaCorr
	local _nLock     := 0
	local _sQuery    := ""
	local _sSeqSZI   := ""
	local _lRet      := .F.
	local _nTentativ := 0

	if ! empty (szi -> zi_seq)
		::UltMsg += "Chamada indevida do metodo " + procname () + ": registro do SZI jah tinha a sequencia '" + szi -> zi_seq + "'. Solicite manutencao do programa."
		u_help (::UltMsg,, .t.)
	else
		do while _nTentativ <= 10
			_nLock := U_Semaforo (procname () + cEmpAnt + xfilial ("SZI") + szi -> zi_assoc + szi -> zi_lojasso, .F.)
	
			// Se nao foi possivel bloquear o semaforo, deleta o registro do SZI, cancelando sua inclusao.
			if _nLock == 0 
				reclock ("SZI", .F.)
				szi -> (dbdelete ())
				msunlock ()
			else
				_sQuery := ""
				_sQuery += "SELECT MAX (ZI_SEQ)"
				_sQuery +=  " FROM " + RetSQLName ("SZI")
				_sQuery += " WHERE ZI_FILIAL  = '" + xfilial ("SZI")   + "'"
				// Quero os deletados, para nao gerar a mesma sequencia de registros jah deletados. -->_sQuery +=   " AND D_E_L_E_T_ = ''"
				_sQuery +=   " AND ZI_ASSOC   = '" + szi -> zi_assoc   + "'"
				_sQUery +=   " AND ZI_LOJASSO = '" + szi -> zi_lojasso + "'"
				_sSeqSZI = U_RetSQL (_sQuery)
				if empty (_sSeqSZI)
					_sSeqSZI = '000000'
				endif
				_sSeqSZI = soma1 (_sSeqSZI)
	
				// Grava a sequencia no SZI e libera o semaforo.
				reclock ("SZI", .F.)
				szi -> zi_seq = _sSeqSZI
				msunlock ()
				::SeqSZI = szi -> zi_seq
				U_Semaforo (_nLock)
				_lRet = .T.
				exit
			endif
		enddo
	endif
return _lRet



// --------------------------------------------------------------------------
// Grava novo registro.
METHOD Grava (_lSZIGrav, _lMemoGrav) Class ClsCtaCorr
	local _lContinua := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _oAssoc    := NIL
	local _dEmiSE2   := ctod ('')

	_lSZIGrav  := iif (_lSZIGrav  == NIL, .F., _lSZIGrav)  // Indica registro jah gravado no SZI. Falta soh complementar dados.
	_lMemoGrav := iif (_lMemoGrav == NIL, .F., _lMemoGrav)  // Indica memo jah gravado.

	// Deve sempre se referir a um associado (ou futuro associado, em caso de movimento 'associar'). Deve pelo menos existir no SA2.
	_oAssoc := ClsAssoc():New (::Assoc, ::Loja)
	if valtype (_oAssoc) != "O"
		_lContinua = .F.
	endif

	// Posiciona ZX5 para leitura de dados adicionais.
	if _lContinua
		zx5 -> (dbsetorder (2))  // ZX5_FILIAL+ZX5_TABELA+ZX5_10COD
		if ! zx5 -> (dbseek ('  ' + '10' + ::TM, .F.))  // Tabela 10 do ZX5 eh compartilhada.
			::UltMsg += "Tipo de movimento '" + ::TM + "' nao cadastrado na tabela 10 do ZX5."
			_lContinua = .F.
		endif
	endif

	if _lContinua
		if ! _lSZIGrav
			_cFilial := szi -> zi_filial
			_dDtAtu := szi -> zi_data
			u_log2 ('info', '[' + GetClassName (::Self) + '.' + procname () + '] Gravando ZI_DOC = ' + ::Doc + '/' + ::Serie + '-' + ::Parcela + ' $ ' + transform (::Valor, "@E 999,999,999.99"))
			reclock ("SZI", .T.)
			szi -> zi_filial  = xfilial ("SZI")
			szi -> zi_assoc   = ::Assoc
			szi -> zi_lojasso = ::Loja
			szi -> zi_nomasso = _oAssoc:Nome
			szi -> zi_data    = ::DtMovto
			szi -> zi_mesref  = ::MesRef
			szi -> zi_doc     = ::Doc
			szi -> zi_serie   = ::Serie
			szi -> zi_histor  = ::Histor
			szi -> zi_valor   = ::Valor
			szi -> zi_saldo   = ::Valor
			szi -> zi_user    = cUserName
			szi -> zi_tm      = ::TM
			szi -> zi_FilOrig = ::FilOrig
			szi -> zi_Origem  = ::Origem
			szi -> zi_Parcela = ::Parcela
			msunlock ()
			_lSZIGrav = .T.
			::RegSZI = szi -> (recno ())
		endif

		// Gera sequencial para este novo registro.
		if ::GeraSeq ()

			// Grava campo memo.
			if ! _lMemoGrav .and. ! empty (::Obs)
				msmm (,,, ::Obs, 1,,, "SZI", "ZI_CODMEMO")
			endif

			// Gera demais dados.
			if ! empty (::OQueGera ())
				do case
				case ::OQueGera () $ "DP/NDF/PA/PR"
					
					// Em alguns casos a data de emissao do SE2 nao pode ser a mesma do vencimento (geracao de
					// resgate de cota capital, por exemplo, onde sao gerados venctos para anos futuros).
					if szi -> zi_data > date ()
						_dEmiSE2 = min (dDataBase, date ())
					else
						_dEmiSE2 = szi -> zi_data
					endif

					_lContinua = ::GeraSE2 (::OQueGera (), _dEmiSE2, iif (type ('_lCtOnLine') == 'L', _lCtOnLine, .F.))
				case ::OQueGera () == "DP+SE5_R"
					_lContinua = ::GeraSE2 ('DP', szi -> zi_data, .F.)
					if _lContinua
						u_log ('vou gerar SE5 a receber')
						if ! U_GeraSE5 ("IR", ::DtMovto, ::Valor, ::Histor, ::Banco, ::Agencia, ::NumCon, ::ChaveExt (), @::UltMsg, iif (type ('_lCtOnLine') == 'L', _lCtOnLine, .F.), '110104', ::FormPag)
							::UltMsg += "Erro na atualizacao do financeiro (SE5). Este registro nao sera' mantido."
							_lContinua = .F.
						endif
					endif
				otherwise
					::UltMsg += "Metodo " + procname () + " sem tratamento para '" + zx5 -> zx5_10GerI + "' no campo ZX5_10GERI. Avise setor de informatica."
					U_AvisaTI (::UltMsg)
					_lContinua = .F.
				endcase
			endif
		endif
		CursorArrow ()
	endif

	// Gera movimentos adicionais.
	if _lContinua .and. ::TM == '08'
		_lContinua = ::Associar ()
	endif
	if _lContinua .and. ::TM == '09'
		_lContinua = ::Desassoc ()
	endif

	// Se o registro jah foi gavado no SZI mas houve problemas nas validacoes
	// ou na geracao de sequencial, por exemplo, o mesmo deve ser excluido.
	if ! _lContinua .and. _lSZIGrav
		::UltMsg += "Erro na gravacao do arquivo SZI. Gravacao cancelada."
		if _lMemoGrav .and. ! empty (szi -> zi_CodMemo)
			u_log ("Deletando memo")
			msmm (szi -> zi_CodMemo,,,, 2,,, "SZI", "ZI_CODMEMO")
		endif
		u_log ("Deletando registro no SZI")
		
		reclock ("SZI", .F.)
		szi -> (dbdelete ())
		msunlock ()

	endif

	// Atualiza saldo do Associado
	if _lContinua
       ::AtuSldAsso ()                                              
	endif                                          

	if ! _lContinua .and. ! empty (::UltMsg)
		u_help (::UltMsg,, .t.)
	endif

	U_ML_SRArea (_aAreaAnt)
return _lContinua



// --------------------------------------------------------------------------
// Retorna array com o historico de baixas do documento atual.
METHOD HistBaixas () Class ClsCtaCorr
	local _aRet     := {}
	local _oSQL     := NIL
	local _aBaixas  := {}
	local _nBaixa   := 0
	local _sFilDest := ""
	
//	u_logIni (GetClassName (::Self) + '.' + procname ())

	// Busca baixas do titulo atual feitas via conta transitoria.
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT SA6.A6_CONTA, SE5.E5_DATA, SE5.E5_VALOR, SE5.E5_DOCUMEN, SE5.R_E_C_N_O_, RTRIM (SE5.E5_HISTOR)"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SE5") + " SE5 "
	_oSQL:_sQuery +=  " LEFT JOIN " + RetSQLName ("SA6") + " SA6 "
	_oSQL:_sQuery +=        " ON (SA6.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=        " AND SA6.A6_FILIAL  = '" + ::Filial + "'"
	_oSQL:_sQUery +=        " AND SA6.A6_COD     = SE5.E5_BANCO"
	_oSQL:_sQuery +=        " AND SA6.A6_AGENCIA = SE5.E5_AGENCIA"
	_oSQL:_sQuery +=        " AND SA6.A6_NUMCON  = SE5.E5_CONTA)"
	_oSQL:_sQuery += " WHERE SE5.E5_FILIAL   = '" + ::Filial + "'"
	_oSQL:_sQuery +=   " AND SE5.E5_VACHVEX  = 'SZI" + ::Assoc + ::Loja + ::SeqSZI + "'"
	_oSQL:_sQuery +=   " AND SE5.E5_SITUACA != 'C'"
	_oSQL:_sQuery +=   " AND SE5.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=   " AND SE5.E5_FILORIG  = '" + ::Filial + "'"
	_oSQL:_sQuery +=   " AND dbo.VA_SE5_ESTORNO (SE5.R_E_C_N_O_) = 0"
//	u_log (_oSQL:_squery)
	_aBaixas := aclone (_oSQL:Qry2Array (.f., .f.))
	for _nBaixa = 1 to len (_aBaixas)

		// Se baixou pela conta transitoria entre filiais na contabilidade, verifica para onde o saldo foi transferido.
		_sFilDest = ''
		if alltrim (_aBaixas [_nBaixa, 1]) == '101010201099'  
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT ZI_FILIAL"
			_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI "
			_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_  = ''"
			_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC    = '" + ::Assoc  + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO  = '" + ::Loja   + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_FILORIG  = '" + ::Filial + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_TM       = '" + ::TM     + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_DATA     = '" + _aBaixas [_nBaixa, 2] + "'"
			//u_log (_oSQL:_squery)
			_sFilDest = _oSQL:RetQry (1, .F.)
		endif
		aadd (_aRet, {_sFilDest, stod (_aBaixas [_nBaixa, 2]), _aBaixas [_nBaixa, 3], _aBaixas [_nBaixa, 4], _aBaixas [_nBaixa, 5], alltrim (_aBaixas [_nBaixa, 6])})
	next
	
//	u_logFim (GetClassName (::Self) + '.' + procname ())
return _aRet


/*
// --------------------------------------------------------------------------
// Retorna array com o historico de transferencias de saldo entre filiais.
METHOD HistTrFil () Class ClsCtaCorr
	local _aRet    := {}
	local _oSQL    := NIL
	local _aBaixas := {}
	local _nBaixa  := 0
	
	u_logIni (GetClassName (::Self) + '.' + procname ())

	// Busca baixas do titulo atual feitas via conta transitoria.
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT E5_DATA, E5_VALOR"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SE5") + " SE5, "
	_oSQL:_sQuery +=             RetSQLName ("SA6") + " SA6 "
	_oSQL:_sQuery += " WHERE SE5.E5_FILIAL   = '" + ::Filial + "'"
	_oSQL:_sQuery +=   " AND SE5.E5_VACHVEX  = 'SZI" + ::Assoc + ::Loja + ::SeqSZI + "'"
	_oSQL:_sQuery +=   " AND SE5.E5_SITUACA != 'C'"
	_oSQL:_sQuery +=   " AND SE5.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=   " AND SE5.E5_FILORIG  = '" + ::Filial + "'"
	_oSQL:_sQUery +=   " AND SE5.E5_BANCO    = A6_COD"
	_oSQL:_sQuery +=   " AND SE5.E5_AGENCIA  = A6_AGENCIA"
	_oSQL:_sQuery +=   " AND SE5.E5_CONTA    = A6_NUMCON"
	_oSQL:_sQuery +=   " AND dbo.VA_SE5_ESTORNO (SE5.R_E_C_N_O_) = 0"
	_oSQL:_sQuery +=   " AND SA6.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=   " AND SA6.A6_FILIAL   = '" + ::Filial + "'"
	_oSQL:_sQuery +=   " AND SA6.A6_CONTA    = '101010201099'"  // Conta transitoria entre filiais na contabilidade.
	u_log (_oSQL:_squery)
	_aBaixas := aclone (_oSQL:Qry2Array (.f., .f.))
	for _nBaixa = 1 to len (_aBaixas)
		// Verifica para onde o saldo foi transferido
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT ZI_FILIAL"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI "
		_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC    = '" + ::Assoc  + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO  = '" + ::Loja   + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_FILORIG  = '" + ::Filial + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_TM       = '" + ::TM     + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_DATA     = '" + _aBaixas [_nBaixa, 1] + "'"
		//u_log (_oSQL:_squery)
		aadd (_aRet, {_oSQL:RetQry (1, .F.), stod (_aBaixas [_nBaixa, 1]), _aBaixas [_nBaixa, 2]})
	next

	u_logFim (GetClassName (::Self) + '.' + procname ())
return _aRet
*/



// --------------------------------------------------------------------------
// Verifica o que este movimento gera.
METHOD OQueGera () Class ClsCtaCorr
	local _sRet := ""
	
	zx5 -> (dbsetorder (2))  // ZX5_FILIAL+ZX5_TABELA+ZX5_10COD
	if ! zx5 -> (dbseek (xfilial ("ZX5") + "10" + ::TM, .F.))
		u_help ("Tipo de movimento '" + ::TM + "' nao cadastrado na tabela de movimentos de conta corrente (tabela 10 do ZX5).",, .t.)
	else
		do case
			case ::TM == '13' .and. ! empty (::FilOrig)  // Transferencia de saldo de NF de compra de safra de outra filial.
				_sRet = "DP"
			case zx5 -> zx5_10GerI == '0' .or. empty (zx5 -> zx5_10GerI)
				_sRet = ""  // Nao gera nada
			case zx5 -> zx5_10GerI == '1'
				_sRet = "NDF"
			case zx5 -> zx5_10GerI == '2'
				_sRet = "PA"
			case zx5 -> zx5_10GerI == '3'
				_sRet = "DP"
			case zx5 -> zx5_10GerI == '4'
				_sRet = "DP+SE5_R"
			case zx5 -> zx5_10GerI == '5' // Registro no SE2 jah gerado por outra rotina (NF compra safra, por exemplo).
				_sRet = ""  // Nao gera nada
			case zx5 -> zx5_10GerI == '6'
				_sRet = "PR"
			otherwise
				::UltMsg += "Metodo " + procname () + " sem definicao do que deve ser gerado para '" + zx5 -> zx5_10GerI + "' no campo ZX5_GERI. Avise setor de informatica."
				U_AvisaTI (::UltMsg)
		endcase
	endif
return _sRet



// --------------------------------------------------------------------------
// Verifica se o movimento pode ser excluido.
METHOD PodeExcl () Class ClsCtaCorr
	local _lContinua := .T.
	local _sQuery    := ""
	local _oAssoc    := NIL
	local _nRegSE2Ex := 0

	//u_logIni (GetClassName (::Self) + '.' + procname ())

	::UltMsg = ""

	_oAssoc = ClsAssoc():New(::Assoc, ::Loja)
	if valtype (_oAssoc) != "O"
		::UltMsg += "Nao foi possivel instanciar classe ClsAssoc." + _sCRLF
		_lContinua = .F.
	endif

	// Posiciona ZX5 para validacoes posteriores.
	if _lContinua
		zx5 -> (dbsetorder (2))  // ZX5_FILIAL+ZX5_TABELA+ZX5_10COD
		if ! zx5 -> (dbseek (xfilial ("ZX5") + "10" + ::TM, .F.))
			::UltMsg += "Tipo de movimento '" + ::TM + "' nao encontrado na tabela de movimentos de conta corrente!"
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. ::TM $ ::TMCapital
		if _lContinua
			_lContinua = ::VerifUser ("Movimentacao de capital social: uso restrito.")
		endif
		if empty (_oAssoc:DtNascim)
			::UltMsg += "Para excluir movimentos que envolvem capital social a data de nascimento do associado deve estar informada no seu cadastro."
			_lContinua = .F.
		endif
	endif

	// Correcao monetaria.
	if _lContinua .and. ::TM $ ::TMCorrMonC + '/' + ::TMCorrMonD
		_lContinua = ::VerifUser ("Exclusao de movimento de correcao monetaria: uso restrito.")
	endif

	if _lContinua .and. ::TM $ '04'
		::UltMsg += "Este tipo de movimentacao so pode ser excluido atraves da exclusao da NF de venda que o gerou."
		_lContinua = .F.
	endif

	// Compra de safra
	if _lContinua .and. ::TM == '13' .and. empty (::FilOrig)
		// Se for uma fatura gerada pelo financeiro, a mesma pode ser cancelada.
		se2 -> (dbsetorder (6))  // E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO
		if ! se2 -> (dbseek (::Filial + ::Assoc + ::Loja + ::Serie + ::Doc + ::Parcela, .F.)) .or. se2 -> e2_tipo != 'FAT'
			::UltMsg += "Movimento de compra de safra: so' pode ser excluido excluindo-se a NF de compra que o gerou."
			_lContinua = .F.
		endif
	endif


	// Verifica periodo fechado (correcao monetaria jah calculada).
	if _lContinua .and. ! ::TM $ ::TMCapital
		_sQuery := ""
		_sQuery += "SELECT COUNT (*)"
		_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI"
		_sQuery += " WHERE D_E_L_E_T_ = ''"
		_sQUery +=   " AND ZI_FILIAL  = '" + xfilial ("SZI") + "'"  // O calculo eh feito separadamente por filial.
		_sQUery +=   " AND ZI_TM      IN " + FormatIn (::TMCorrMonC + "/" + ::TMCorrMonD, '/')
		_sQUery +=   " AND ZI_ASSOC   = '" + ::Assoc + "'"
		_sQUery +=   " AND ZI_LOJASSO = '" + ::Loja + "'"
		_sQUery +=   " AND ZI_DATA    > '" + dtos (::DtMovto) + "'"  // Eh gerada no dia 1 do mes subsequente.
		//u_log (_squery)
		if U_RetSQL (_sQuery) > 0
			::UltMsg += "Ja' existe calculo de correcao monetaria para este associado em meses posteriores. Exclusao nao permitida."
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. ::SaldoAtu != ::Valor .and. ! ::TM $ '10/17/18/19'
		::UltMsg += "Este lancamento sofreu baixas, pois o saldo difere do valor original. Cancele as baixas antes de continuar."
		_lContinua = .F.
	endif
	
	// Usuarios excluiam movto em datas posteriores a sua criacao, e ficava um saldo no extrato da CC durante esse periodo.
//	if _lContinua .and. dDataBase != ::DtMovto
	if _lContinua // .and. dDataBase != ::DtMovto
		_nRegSE2Ex = ::RecnoSE2 ()
		if _nRegSE2Ex > 0
			se2 -> (dbgoto (_nRegSE2Ex))
			if se2 -> e2_emissao != dDataBase
	//	::UltMsg += "Para exclusao deve ser usada data base igual `a data da inclusao (" + dtoc (::DtMovto) + ")"
				::UltMsg += "Este registro gerou titulo no financeiro, com data de emissao " + dtoc (se2 -> e2_emissao) + ". Para exclusao deve ser usada a mesma data base."
				_lContinua = .F.
			endif
		endif
	endif

	if _lContinua .and. ::TM == '08'
		_sQuery := ""
		_sQuery += "SELECT count (*)"
		_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI"
		_sQuery += " WHERE D_E_L_E_T_ = ''"
		_sQuery +=   " AND ZI_ASSOC   = '" + ::Assoc + "'"
		_sQUery +=   " AND ZI_LOJASSO = '" + ::Loja + "'"
		_sQUery +=   " AND ZI_DATA   >= '" + dtos (::DtMovto) + "'"
		_sQUery +=   " AND ZI_TM     != '08'"
		u_log (_squery)
		if U_RetSQL (_sQuery) > 0
			::UltMsg += "Existe movimentacao posterior a esta data na conta corrente deste associado."
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. ::TM == '09'
		_sQuery := ""
		_sQuery += "SELECT count (*)"
		_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI"
		_sQuery += " WHERE D_E_L_E_T_ = ''"
		_sQuery +=   " AND ZI_ASSOC   = '" + ::Assoc + "'"
		_sQUery +=   " AND ZI_LOJASSO = '" + ::Loja + "'"
		_sQUery +=   " AND ZI_SALDO  >  0"
		_sQUery +=   " AND ZI_DATA   >= '" + dtos (::DtMovto) + "'"
		_sQUery +=   " AND ZI_TM      = '11'"
		u_log (_squery)
		if U_RetSQL (_sQuery) > 0
			::UltMsg += "Existem lancamentos de resgate de quota capital posteriores a esta data com saldo em aberto."
			_lContinua = .F.
		endif
	endif

	if ! _lContinua
		u_help (::UltMsg,, .t.)
	endif
	//u_logFim (GetClassName (::Self) + '.' + procname ())
return _lContinua



// --------------------------------------------------------------------------
// Verifica se o movimento pode ser incluido.
METHOD PodeIncl () Class ClsCtaCorr
	local _lContinua := .T.
	local _sQuery    := ""
	local _sRetQry   := ""
	local _oAssoc    := NIL
	local _nBxTrans  := 0
	local _dAniver   := ctod ('')
	local _oDUtil    := NIL
	local _sCRLF     := chr (13) + chr (10)

//	u_logIni (GetClassName (::Self) + '.' + procname ())

	::UltMsg = ""

	// Verifica dados.
	if _lContinua
		if empty (::Assoc)   ; ::UltMsg += "Codigo do associado deve ser informado." ; _lContinua = .F. ; endif
		if empty (::Loja)    ; ::UltMsg += "Loja do associado deve ser informada."   ; _lContinua = .F. ; endif
		if empty (::TM)      ; ::UltMsg += "Tipo de movimento deve ser informado."   ; _lContinua = .F. ; endif
		if empty (::DtMovto) ; ::UltMsg += "Data do movimento deve ser informada."   ; _lContinua = .F. ; endif
		if empty (::Histor)  ; ::UltMsg += "Historico deve ser informado."           ; _lContinua = .F. ; endif
		if empty (::MesRef)  ; ::UltMsg += "Mes de referencia deve ser informado."   ; _lContinua = .F. ; endif
		if empty (::Doc)     ; ::UltMsg += "Documento deve ser informado."           ; _lContinua = .F. ; endif
	endif

	_oAssoc = ClsAssoc():New(::Assoc, ::Loja)
	if valtype (_oAssoc) != "O"
		::UltMsg += "Nao foi possivel instanciar classe ClsAssoc." + _sCRLF
		_lContinua = .F.
	endif
	
	// Se estou associando ele agora, o objeto ainda nao tem nenhum dado.
	if ::TM == '08'
		sa2 -> (dbsetorder (1))
		if sa2 -> (msseek (xfilial ("SA2") + ::Assoc + ::Loja, .F.))
			_oAssoc:CoopOrigem = sa2 -> a2_vacorig
			_oAssoc:DtNascim   = sa2 -> a2_vadtnas
			_oAssoc:CodBase    = sa2 -> a2_vacbase
			_oAssoc:LojaBase   = sa2 -> a2_valbase
		endif
	endif
	
	// PARA EVITAR DE DAR A MENSAGEM NA INCLUSAO DA ROTINA AUTOMATICA NO SE2, TESTA INCLUSIVE NO PROPRIO SZI NAO DEIXANDO QUE INCLUA COM O MESMO DOC/PREFIXO 
	_sQuery := ""
	_sQuery += " SELECT ZI_HISTOR"
	_sQuery += "   FROM SZI010 AS SZI"
	_sQuery += "  WHERE SZI.D_E_L_E_T_ = ''"
	_sQuery += "    AND SZI.ZI_FILIAL  = '" + ::Filial + "'"
	_sQuery += "    AND SZI.ZI_ASSOC   = '" + ::Assoc + "'"
	_sQuery += "    AND SZI.ZI_LOJASSO = '" + ::Loja + "'"
	_sQuery += "    AND SZI.ZI_DOC     = '" + ::Doc + "'"
	_sQuery += "    AND SZI.ZI_SERIE   = '" + ::Serie + "'"
	_sQuery += "    AND SZI.ZI_PARCELA = '" + ::Parcela + "'"
	_aDados := U_Qry2Array(_sQuery)
	if len (_aDados) > 0
		::UltMsg += "Associado ja tem lancamento com esse numero de documento/prefixo/parcela. Verifique! " + _sCRLF
		_lContinua = .F.
	endif
	
	// Posiciona ZX5 para validacoes posteriores.
	zx5 -> (dbsetorder (2))  // ZX5_FILIAL+ZX5_TABELA+ZX5_10COD
	if ! zx5 -> (dbseek (xfilial ("ZX5") + "10" + ::TM, .F.))
		::UltMsg += "Tipo de movimento '" + ::TM + "' nao encontrado na tabela de movimentos de conta corrente!" + _sCRLF
		_lContinua = .F.
	endif

	if _lContinua .and. ! zx5 -> zx5_10geri $ '0123456'
		::UltMsg += "Falta tratamento para campo ZX5_10GERI com conteudo '" + zx5 -> zx5_10geri + "' no metodo " + procname () + _sCRLF
		_lContinua = .F.
	endif

	if _lContinua .and. ::TM $ ::TMCapital
		if _lContinua
			_lContinua = ::VerifUser ("Movimentacao de capital social: uso restrito.")
		endif
		if empty (_oAssoc:DtNascim)
			::UltMsg += "Para incluir movimentos que envolvem capital social a data de nascimento do associado deve estar informada no seu cadastro." + _sCRLF
			_lContinua = .F.
		endif
	endif

	// Inclusao manual de NF de compra de safra: por enquanto, somente em casos de transf. entre filiais.
	if _lContinua .and. ::TM == '13'

		// Ex-associado pode ainda ter a safra para receber.
		if !_oAssoc:EhSocio (::DtMovto) .and. empty (_oAssoc:DtSaida (::DtMovto))
			::UltMsg += "Nao consta como associado nem como ex-associado nesta data." + _sCRLF
			_lContinua = .F.
		endif
//		if _lContinua .and. empty (::FilOrig) .and. ! IsInCallStack ("U_VA_GNF2") .and. ! IsInCallStack ("U_FTSAFRA") .and. ! IsInCallStack ("U_FTSAFRA1") .and. ! IsInCallStack ("U_ROBERT")  // habilitado por causa de um baca em 2018
		if _lContinua .and. empty (::FilOrig) .and. ! IsInCallStack ("U_VA_GNF2") .and. ! IsInCallStack ("U_FTSAFRA") .and. ! IsInCallStack ("U_FTSAFRA1") .and. ! IsInCallStack ("U_VA_RUSN")
			::UltMsg += "Movimento de compra de safra: so' pode ser incluido por rotinas especificas, ou manualmente quando tratar-se de titulo transferido de outra filial. Informe filial de origem." + _sCRLF
			_lContinua = .F.
		endif
		if _lContinua .and. ! empty (::FilOrig)
			if empty (::SeqOrig)
				::UltMsg += "Inclusao de transferencia de outra filial: sequencia original nao informada (o movimento correspondente deve existir na filial origem). Verifique campos Associado, Loja, Data, Tipo movto., Documento, Serie e Mes ref." + _sCRLF
				_lContinua = .F.
			else
				// Para ficar mais correto, a query abaixo deveria abater transferencias jah realizadas, pois
				// como estah permite fazer a transferencia mais de uma vez.
				_sQuery := ""
				_sQuery += " SELECT ISNULL (SUM (E5_VALOR), 0)"
				_sQuery +=   " FROM " + RetSQLName ("SE5") + " SE5,"
				_sQuery +=              RetSQLName ("SA6") + " SA6"
				_sQuery +=  " WHERE SE5.E5_FILIAL   = '" + ::FilOrig + "'"
				_sQuery +=    " AND SE5.E5_VACHVEX  = 'SZI" + ::Assoc + ::Loja + ::SeqOrig + "'"
				_sQuery +=    " AND SE5.E5_SITUACA != 'C'"
				_sQuery +=    " AND SE5.D_E_L_E_T_  = ''"
				_sQuery +=    " AND SE5.E5_FILORIG  = '" + ::FilOrig + "'"
				_sQUery +=    " AND SE5.E5_DATA    <= '" + dtos (::DtMovto) + "'"
				_sQuery +=    " AND SE5.E5_BANCO    = A6_COD"
				_sQuery +=    " AND SE5.E5_AGENCIA  = A6_AGENCIA"
				_sQuery +=    " AND SE5.E5_CONTA    = A6_NUMCON"
				_sQuery +=    " AND SA6.D_E_L_E_T_  = ''"
				_sQuery +=    " AND SA6.A6_FILIAL   = '" + ::FilOrig + "'"
				_sQuery +=    " AND SA6.A6_CONTA    = '101010201099'"  // Conta transitoria entre filiais na contabilidade.
				//u_log (_squery)
				_nBxTrans = U_RetSQL (_sQuery)
				if ::Valor > _nBxTrans
					::UltMsg += "Inclusao de transferencia de compra de safra de outra filial: o valor esta limitado a R$ " + alltrim (transform (_nBxTrans, "@E 999,999,999.99")) + " (total baixado via conta transitoria na filial de origem nesta data)." + _sCRLF
					_lContinua = .F.
				endif
			endif
		endif
	endif


	// Implantacao de saldo de quota capital: somente uma vez na vida, independente de filial.
	if _lContinua .and. ::TM == '10'
		if ! _oAssoc:EhSocio (::DtMovto)
			::UltMsg += "Nao consta como associado nesta data." + _sCRLF
			_lContinua = .F.
		endif
		if _lContinua
			_sQuery := ""
			_sQuery += "SELECT COUNT (*)"
			_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI"
			_sQuery += " WHERE D_E_L_E_T_ = ''"
			_sQuery +=   " AND ZI_ASSOC   = '" + ::Assoc + "'"
			_sQUery +=   " AND ZI_LOJASSO = '" + ::Loja + "'"
			_sQUery +=   " AND ZI_TM      = '" + ::TM + "'"
			_sQUery +=   " AND ZI_DATA   >= '" + dtos (_oAssoc:DtEntrada (::DtMovto)) + "'"
			_sQUery +=   " AND ZI_DATA   <= '" + dtos (iif (empty (_oAssoc:DtSaida (::DtMovto)), dDataBase, _oAssoc:DtSaida (::DtMovto))) + "'"
			//u_log (_squery)
			if U_RetSQL (_sQuery) > 0
				::UltMsg += "Associado ja tem lancamento de implantacao de capital. Posterior a isso, somente serao permitidas geracoes de distribuicoes anuais de sobras." + _sCRLF
				_lContinua = .F.
			endif
		endif
	endif


	// Resgate parcial da quota capital.
	if _lContinua .and. ::TM == '11'
		if _oAssoc:EhSocio (::DtMovto) .and. ! IsInCallStack ("DESASSOC")  // Usuario estah incluindo o movto. manualmente.
			if _lContinua .and. empty (_oAssoc:DtNascim)
				::UltMsg += "Data de nascimento deste associado nao informada no cadastro." + _sCRLF
				_lContinua = .F.
			endif
			if _lContinua
				_oDUtil := ClsDUtil():New()
				_dAniver = _oDUtil:Aniver (_oAssoc:DtNascim, 65)
				if ::DtMovto < _dAniver
					::UltMsg += "Associado somente vai ter direito a resgatar parte da quota capital apos 65 anos de idade, o que serah em " + dtoc (_dAniver) + _sCRLF
					_lContinua = .F.
				endif
			endif
			if _lContinua
				_oDUtil := ClsDUtil():New()
				_dAniver = _oDUtil:Aniver (_oAssoc:DtEntrada (::DtMovto), 10)
				if ::DtMovto < _dAniver
					::UltMsg += "Associado so' tera' direito a resgatar parte da quota capital apos 10 anos de associacao, o que sera' em " + dtoc (_dAniver) + _sCRLF
					_lContinua = .F.
				endif
			endif
			if _lContinua .and. ::Valor > _oAssoc:SldQuotCap (::DtMovto) [1] / 10
				::UltMsg += "Associado so' tem direito a resgatar 10% do saldo de sua quota capital (saldo da quota em " + dtoc (::DtMovto) + ": " + GetMv('MV_SIMB1') + " " + alltrim (transform (_oAssoc:SldQuotCap (::DtMovto) [1], "@E 999,999,999.99")) + ")." + _sCRLF
				_lContinua = .F.
			endif
			if _lContinua
				_sQuery := ""
				_sQuery += "SELECT ZI_MESREF"
				_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI"
				_sQuery += " WHERE D_E_L_E_T_ = ''"
				_sQuery +=   " AND ZI_ASSOC   = '" + ::Assoc + "'"
				_sQUery +=   " AND ZI_LOJASSO = '" + ::Loja + "'"
				_sQUery +=   " AND SUBSTRING (ZI_MESREF, 3, 4) = '" + substr (::MesRef, 3, 4) + "'"
				_sQUery +=   " AND ZI_TM      = '11'"
				_sRetQry = U_RetSQL (_sQuery)
				if ! empty (_sRetQry)
					::UltMsg += "Associado ja tem lancamento de resgate de quota capital para este ano, com mes de referencia " + _sRetQry + _sCRLF
					_lContinua = .F.
				endif
			endif
		endif
		
		// Se, apesar de todos os testes anteriores, for um usuario bonito, simpatico e poderoso, posso abrir uma excecao...
		//if ! _lContinua .and. U_ZZUVL ('051', __cUserID, .F., cEmpAnt, cFilAnt)
		if ! _lContinua .and. U_ZZUVL ('051', __cUserID, .F.)
			_lContinua = U_MsgNoYes (::UltMsg + _sCRLF + "Deseja incluir a movimentacao, apesar dos avisos anteriores?")
		endif
	endif

	// Associar.
	if _lContinua .and. ::TM == '08'
		if _lContinua .and. ::DtMovto < _oAssoc:DtNascim
			::UltMsg += "Trabalhar pelo cooperativismo eh bom, mas associar-se antes de nascer eh demais... Data de nascimento deste fornecedor: " + dtoc (_oAssoc:DtNascim) + _sCRLF
			_lContinua = .F.
		endif
		if _lContinua .and. _oAssoc:EhSocio (::DtMovto)
			::UltMsg += "Jah consta como associado nesta data." + _sCRLF
			_lContinua = .F.
		endif
	endif

	// Desassociar.
	if _lContinua .and. ::TM == '09'
		if ::DtMovto < date ()
			_lContinua = U_MsgNoYes ("Confirma o uso de data retroativa?", .F.)
		endif
		if _lContinua .and. ! _oAssoc:EhSocio (::DtMovto)
			::UltMsg += "Nao consta como associado em " + dtoc (::DtMovto) + _sCRLF
			_lContinua = .F.
		endif
	endif

	// Transferencia de quota capital.
	if _lContinua .and. ::TM == '17'
		if ::Valor == 0 .or. _oAssoc:SldQuotCap (::DtMovto) [1] < ::Valor
			::UltMsg += "Valor nao informado ou saldo cota capital (" + cvaltochar (_oAssoc:SldQuotCap (::DtMovto) [1]) + ") insuficiente para a transferencia." + _sCRLF
			_lContinua = .F.
		endif
		if ::Valor < _oAssoc:SldQuotCap (::DtMovto) [1] * 0.15
			::UltMsg += "Nao pode ser transferido menos que 15% do saldo de cota capital (" + cvaltochar (_oAssoc:SldQuotCap (::DtMovto) [1]) + ")." + _sCRLF
			_lContinua = .F.
		endif
	endif
	if _lContinua .and. ::TM == '18' .and. ! _oAssoc:EhSocio (::DtMovto)
		::UltMsg += _oAssoc:Nome + " nao consta como associado nesta data." + _sCRLF
		_lContinua = .F.
	endif


	// Distribuicao de sobras: somente uma vez por ano.
	if _lContinua .and. ::TM == '19'
		if ! _oAssoc:EhSocio (::DtMovto) .and. empty (_oAssoc:DtSaida (::DtMovto))  // Ex-associado
			::UltMsg += "Nao consta como associado (nem ex associado) nesta data." + _sCRLF
			_lContinua = .F.
		endif
		if _lContinua .and. ! IsInCallStack ("U_SZI_DS")
			::UltMsg += "Este tipo de movimento so deveria ser gerado pela rotina de distribuicao de sobras (SZI_DS)." + _sCRLF
			if U_ZZUVL ('051', __cUserId, .F.)
				_lContinua = U_MsgNoYes (::UltMsg + " Confirma assim mesmo?")
			else
				_lContinua = .F.
			endif
		endif
		if _lContinua
			_sQuery := ""
			_sQuery += "SELECT COUNT (*)"
			_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI"
			_sQuery += " WHERE D_E_L_E_T_ = ''"
			_sQuery +=   " AND ZI_ASSOC   = '" + ::Assoc + "'"
			_sQUery +=   " AND ZI_LOJASSO = '" + ::Loja + "'"
			_sQUery +=   " AND ZI_TM      = '" + ::TM + "'"
			_sQUery +=   " AND ZI_MESREF  = '" + ::MesRef + "%'"
			u_log (_squery)
			if U_RetSQL (_sQuery) > 0
				::UltMsg += "Associado ja tem lancamento de integralizacao de sobras neste ano." + _sCRLF
				_lContinua = .F.
			endif
		endif
	endif


	// Emprestimos.
//	if _lContinua .and. ::TM == '07' .and. empty (::FormPag)
	if _lContinua .and. ::TM $ '07/31' .and. empty (::FormPag)
		::UltMsg += "Para emprestimos/adiantamentos de safra deve ser informada a forma de pagamento." + _sCRLF
		_lContinua = .F.
	endif

	// Esta validacao eh soh por que sou enjoado e quero o cadastro preenchido. A principio nao preciso para nada em especial.
	if _lContinua .and. empty (_oAssoc:CoopOrigem)
		::UltMsg += "Cooperativa de origem nao informada no cadastro do associado." + _sCRLF
		_lContinua = .F.
	endif
	if _lContinua .and. ! _oAssoc:EhSocio (::DtMovto)
//		if ::TM $ '07' .and. !empty (_oAssoc:DtSaida (::DtMovto))  // Ex-associado
		if ::TM $ '07/31' .and. !empty (_oAssoc:DtSaida (::DtMovto))  // Ex-associado
			if ! msgnoyes ("Codigo/loja '" + ::Assoc + '/' + ::Loja + "' consta como EX-ASSOCIADO em " + dtoc (::DtMovto) + ". Confirma a inclusao deste registro?")
				::UltMsg += "Codigo/loja '" + ::Assoc + '/' + ::Loja + "' consta como ex-associado em " + dtoc (::DtMovto)
				_lContinua = .F.
			endif
		else
			if ! ::TM $ '11/08/13/19'
				if ::TM == '16'
					IF ! (DTOS (DATE ()) = '20210224' .AND. ISiNCALLSTACK ('U_ROBERT'))  // REMOVER DEPOIS... NESTA DATA ESTOU GERANDO PREMIO SAFRA 2020 (GLPI 9515)
						if ! u_msgnoyes ("Codigo/loja '" + ::Assoc + '/' + ::Loja + "' nao consta como associado na data informada. Confirma a inclusao deste registro?")
							::UltMsg += "Codigo/loja '" + ::Assoc + '/' + ::Loja + "' nao consta como associado na data informada."
							_lContinua = .F.
						endif
					ENDIF
				else
					if empty (::FilOrig)  // Aceita movto. de ex associados quando tratar-se de transferencia de outra filial.
						if alltrim (::OQueGera ()) $ "NDF/" .and. msgnoyes ("Codigo/loja '" + ::Assoc + '/' + ::Loja + "' nao consta como associado na data de " + dtoc (::DtMovto) + ". Confirma a inclusao deste registro?")
							// Pode passar
						else
							::UltMsg += "Codigo/loja '" + ::Assoc + '/' + ::Loja + "' nao consta como associado na data de " + dtoc (::DtMovto)
							_lContinua = .F.
						endif
					endif
				endif
			endif
		endif
	endif

	if _lContinua .and. (empty (_oAssoc:CodBase) .or. empty (_oAssoc:LojaBase))
		::UltMsg += "Codigo/loja base nao informados no cadastro do associado." + _sCRLF
		_lContinua = .F.
	endif

	// Outros creditos sem entrada de valor.
	if _lContinua .and. ! zx5 -> zx5_10geri $ '2/4'
		if !empty (::Banco) .or. !empty (::Agencia) .or. !empty (::NumCon)
			::UltMsg += "Banco/agencia/conta somente devem ser informados quando houver recebimento ou pagamento de valores." + _sCRLF
			_lContinua = .F.
		endif
	endif

	// Geracao de PA.
	if _lContinua .and. zx5 -> zx5_10geri == '2'
		if empty (::Banco) .or. empty (::Agencia) .or. empty (::NumCon)
			::UltMsg += "Para geracao de PA devem ser informados banco/agencia/conta." + _sCRLF
			_lContinua = .F.
		endif
	endif

	// Outros creditos com entrada de valor.
	if _lContinua .and. zx5 -> zx5_10geri == '4'
		if empty (::Banco) .or. empty (::Agencia) .or. empty (::NumCon)
			::UltMsg += "Para recebimento de valores devem ser informados banco/agencia/conta." + _sCRLF
			_lContinua = .F.
		endif
	endif

	// Cadastro do banco/agencia/conta.
	if _lContinua
		if ! empty (::Banco) .or. ! empty (::Agencia) .or. ! empty (::NumCon)
			sa6 -> (dbsetorder (1))  // A6_FILIAL+A6_COD+A6_AGENCIA+A6_NUMCON
			if ! sa6 -> (dbseek (xfilial ("SA6") + ::Banco + ::Agencia + ::NumCon, .f.))
				::UltMsg += "Banco / agencia / conta nao cadastrada."
				_lContinua = .F.
			else
				if sa6 -> a6_blocked == '1'
					::UltMsg += "Conta bancaria bloqueada."
					_lContinua = .F.
				endif
			endif
		endif
	endif

	if _lContinua .and. ::TM $ '03/05/06'
		if _lContinua .and. empty (::Fornece)
			::UltMsg += "Fornecedor deve ser informado, quando tipo de movimento for 03, 05 ou 06 (Analise de Solo ou Compras de Insumos/Sementes/Mudas). Verifique!"
			_lContinua = .F.
		endif
	endif	

	if _lContinua .and. ! empty (::OQueGera())
		if ::DtMovto < GetMv ("MV_DATAFIN")
			::UltMsg += "Data (minima) limite para movimentacoes financeiras: " + dtoc (GetMv ("MV_DATAFIN"))
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. ::TM == '27'
		if ::Valor > _oAssoc:SldQuotCap (::DtMovto) [.QtCapSaldoNaData]
			::UltMsg += "Valor do movimento nao pode ser maior que o saldo do capital social nesta data ($ " + cvaltochar (_oAssoc:SldQuotCap (::DtMovto) [.QtCapSaldoNaData]) + ")"
			_lContinua = .F.
		endif
	endif	

	// Verifica periodo fechado (correcao monetaria jah calculada) - independente de filial.
	if _lContinua .and. ! ::TM $ '19/'
		_sQuery := ""
		_sQuery += "SELECT COUNT (*)"
		_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI"
		_sQuery += " WHERE D_E_L_E_T_ = ''"
		_sQuery +=   " AND ZI_ASSOC   = '" + ::Assoc + "'"
		_sQuery +=   " AND ZI_LOJASSO = '" + ::Loja + "'"
		_sQuery +=   " AND ZI_TM      IN " + FormatIn (::TMCorrMonC + "/" + ::TMCorrMonD, '/')
		_sQuery +=   " AND ZI_DATA    > '" + dtos (::DtMovto) + "'"  // Eh gerada no dia 1 do mes subsequente.
		//u_log (_squery)
		if U_RetSQL (_sQuery) > 0
			::UltMsg += "Ja' existe calculo de correcao monetaria para este mes (ou posterior)."
			_lContinua = .F.
		endif
	endif

	if ! _lContinua .and. ! empty (::UltMsg)
		u_help (::UltMsg,, .t.)
	endif
	
	//u_log ('Retornando', _lContinua)
//	u_logFim (GetClassName (::Self) + '.' + procname ())
return _lContinua



// --------------------------------------------------------------------------
// Retorna o R_E_C_N_O_ correspondente no arquivo SE2, caso exista.
METHOD RecnoSE2 () Class ClsCtaCorr
	local _nRet     := 0
	local _oSQL     := NIL
	local _aAreaAnt := U_ML_SRArea ()
	local _aRetQry  := {}

	//u_logIni ()

	// Busca dados do SE2, caso exista (nem todos os movimentos geram SE2).
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""                                                                                            
	_oSQL:_sQuery += " SELECT R_E_C_N_O_"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2 "
	_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=    " AND SE2.E2_FILIAL   = '" + ::Filial  + "'"
	_oSQL:_sQuery +=    " AND SE2.E2_FORNECE  = '" + ::Assoc   + "'"
	_oSQL:_sQuery +=    " AND SE2.E2_LOJA     = '" + ::Loja    + "'"
	_oSQL:_sQuery +=    " AND SE2.E2_NUM      = '" + ::Doc     + "'"
	_oSQL:_sQuery +=    " AND SE2.E2_PREFIXO  = '" + ::Serie   + "'"
	_oSQL:_sQuery +=    " AND SE2.E2_PARCELA  = '" + ::Parcela + "'"
	//_oSQL:Log ()
	_aRetQry = aclone (_oSQL:Qry2Array (.F., .F.))
	if len (_aRetQry) == 1
		_nRet = _aRetQry [1, 1]
	else
		if len (_aRetQry) > 1
			U_help (procname () + ": Encontrei mais de um registro correspondente no SE2 para o seguinte lcto do SZI: " + _oSQL:_sQuery,, .t.)
			_nRet = 0
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
	//u_logFim ()
return _nRet



// --------------------------------------------------------------------------
// Calcula o saldo do lancamento em determinada data.
METHOD SaldoEm (_dData) Class ClsCtaCorr
	local _nSaldo    := 0
	local _oSQL      := NIL

	::UltMsg = ""
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := " SELECT dbo.VA_CTACORRSALDOEM (" + cvaltochar (::RegSZI) + ", " + dtos (_dData) + ")"
	//_oSQL:Log ()
	_nSaldo = _oSQL:RetQry (1, .F.)
return _nSaldo



// --------------------------------------------------------------------------
// Transfere saldo deste lancamento para outra filial.
METHOD TransFil () Class ClsCtaCorr
	local _lContinua := .T.
	local _aTit      := afill (array (8), '')
	local _oBatch    := NIL
	local _nSaldo    := 0
	local _oSQL      := NIL
	local _aBanco    := {}
	local _aBkpSX1   := {}
	local cPerg      := "          "
	Private lMsErroAuto := .F.
	
	u_log2 ('info', 'Iniciando ' + GetClassName (::Self) + '.' + procname ())
	
	if alltrim (::OQueGera ()) $ "PA/DP+SE5_R"
		::UltMsg += "Transferencia de saldo que gerou movimento bancario nao permitida, pois nao tenho o mesmo bco/ag/cta na filial destino. Baixe o movimento manualmente na filial origem e digite lcto correspondente na filiai destino."
		_lContinua = .F.
	endif
	if _lContinua .and. ::SaldoAtu <= 0
		::UltMsg += 'Lancamento sem saldo na conta corrente'
		_lContinua = .F.
	else
		_nSaldo = ::SaldoAtu
	endif
	if _lContinua .and. ::FilDest == ::Filial
		::UltMsg += 'Filial destino deve ser diferente da filial de origem.'
		_lContinua = .F.
	endif
	if _lContinua
		if ! sm0 -> (dbseek (cEmpAnt + ::FilDest, .F.))
			::UltMsg += 'Filial destino inexistente nesta empresa.'
			_lContinua = .F.
		endif
		sm0 -> (dbseek (cEmpAnt + cFilAnt, .F.))
	endif

	// Documentacao cfe. TDN -->  http://tdn.totvs.com/pages/releaseview.action?pageId=6070725
	// Deve ser passado um array (aTitulos), com oito posicoes, sendo que cada posicao devera conter a seguinte composicao:
	// aTitulos [1]:= aRecnos   (array contendo os Recnos dos registros a serem baixados)
	// aTitulos [2]:= cBanco     (Banco da baixa)
	// aTitulos [3]:= cAgencia   (Agencia da baixa)
	// aTitulos [4]:= cConta     (Conta da baixa)
	// aTitulos [5]:= cCheque   (Cheque da Baixa)
	// aTitulos [6]:= cLoteFin    (Lote Financeiro da baixa)
	// aTitulos [7]:= cNatureza (Natureza do movimento bancario)
	// aTitulos [8]:= dBaixa     (Data da baixa)
	// Caso a contabilizacao seja online e a tela de contabilizacao possa ser mostrada em caso de erro no lancamento (falta de conta, debito/credito nao batem, etc) a baixa automatica em lote nao podera ser utilizada.
	// Somente sera processada se: 
	// MV_PRELAN = S
	// MV_CT105MS = N
	// MV_ALTLCTO = N


	// Verifica se existe titulo correspondente no financeiro e guarda seu RECNO.
	if _lContinua
		_aTit [1] = {::RecnoSE2 ()}  // Formato de array por que pode baixar mais de um titulo por vez.
		U_Log2 ('info', 'Registro do SE2 a ser baixado via conta transitoria: ' + cvaltochar (_aTit [1, 1]))
		if _aTit [1, 1] == 0
			::UltMsg += "Nao ha titulo correspondente no financeiro.
			_lContinua = .F.
		else
			se2 -> (dbgoto (_aTit [1, 1]))
			if se2 -> e2_saldo <= 0 .or. se2 -> e2_saldo != _nSaldo
				::UltMsg += 'Lancamento sem saldo no financeiro ou saldo diferente do apresentado na conta corrente.'
				_lContinua = .F.
			endif
		endif
	endif

	// Procura a conta transitoria (eh diferente para cada filial).
	if _lContinua
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery +=" SELECT TOP 1 A6_COD, A6_AGENCIA, A6_NUMCON"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SA6") + " SA6 "
		_oSQL:_sQuery += " WHERE SA6.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SA6.A6_FILIAL  = '" + xfilial ("SA6") + "'"
		_oSQL:_sQuery +=   " AND SA6.A6_CONTA   = '101010201099'"
		_aBanco := aclone (_oSQL:Qry2Array (.f., .f.))
		if len (_aBanco) == 0
			::UltMsg += 'Registro ref.bco/conta transitoria entre filiais nao encontrado na tabela SA6 para esta filial.'
			_lContinua = .F.
		else
			_aTit [2] = _aBanco [1, 1]
			_aTit [3] = _aBanco [1, 2]
			_aTit [4] = _aBanco [1, 3]
		endif
	endif
			
	// A transferencia de saldo entre filiais eh feita atraves de conta financeira transitoria. Para isso,
	// o saldo deve ser baixado na filial de origem atraves de conta transitoria e deve ser feita inclusao
	// de novo movimento na filial destino.
	if _lContinua
		_aTit [8] = dDataBase
		u_log2 ('debug', _atit)

		// Ajusta parametros de contabilizacao para NAO, pois a rotina automatica nao aceita.
		cPerg = 'FIN090'
		_aBkpSX1 = U_SalvaSX1 (cPerg)
		U_GravaSX1 (cPerg, "03", 2)  // Contabiliza online = nao
		
		lMsErroAuto = .F.
		MSExecAuto({|x,y| Fina090(x,y)},3,_aTit)
		If lMsErroAuto
			_lContinua = .F.
			::UltMsg += u_LeErro (memoread (NomeAutoLog ()))
			MostraErro()
		endif

		// Ajusta parametros da rotina automatica.
		U_SalvaSX1 (cPerg, _aBkpSX1)
	endif

	// Se fez a baixa, ajusta historico do movimento bancario.
	if _lContinua
		_sHistSE5 = 'TR.SLD.CC.P/FIL.' + ::FilDest + ' REF.' + ::Histor

		// Arquivo SE5 vem, algumas vezes, desposicionado. Robert, 20/12/2016.
		se2 -> (dbgoto (_aTit [1, 1]))
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT MAX (R_E_C_N_O_)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SE5") + " SE5 "
		_oSQL:_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND E5_FILIAL      = '" + se2 -> e2_filial  + "'"
		_oSQL:_sQuery +=   " AND SE5.E5_CLIFOR  = '" + se2 -> e2_fornece + "'"
		_oSQL:_sQuery +=   " AND SE5.E5_LOJA    = '" + se2 -> e2_loja    + "'"
		_oSQL:_sQuery +=   " AND SE5.E5_PREFIXO = '" + se2 -> e2_prefixo + "'"
		_oSQL:_sQuery +=   " AND SE5.E5_NUMERO  = '" + se2 -> e2_num     + "'"
		_oSQL:_sQuery +=   " AND SE5.E5_PARCELA = '" + se2 -> e2_parcela + "'"
		_oSQL:_sQuery +=   " AND SE5.E5_TIPO    = '" + se2 -> e2_tipo    + "'"
		_oSQL:_sQuery +=   " AND SE5.E5_VACHVEX = ''"
		_oSQL:Log ()
		_nRegSE5 = _oSQL:RetQry ()
		u_log2 ('debug', 'recno se5 para atualizar: ' + cvaltochar (_nRegSE5))
		if _nRegSE5 > 0
			se5 -> (dbgoto (_nRegSE5))
			//u_log ('Vou atualizar SE5')
			//u_log ('SE2:', se2 -> e2_num, se2 -> e2_prefixo, se2 -> e2_parcela, SE2 -> E2_VACHVEX)
			//u_log ('SE5:', se5 -> e5_numero, se5 -> e5_prefixo, se5 -> e5_parcela, se5 -> e5_vachvex, se5 -> e5_seq)
			reclock ('SE5', .F.)
			se5 -> e5_vachvex = se2 -> e2_vachvex
			se5 -> e5_histor  = left (_sHistSE5, tamsx3 ("E5_HISTOR")[1])
			msunlock ()
			u_log2 ('info', 'Regravei historico do SE5 para: ' + se5 -> e5_histor)
		else
			u_log2 ('erro', '[' + GetClassName (::Self) + '.' + procname () + '] Nao encontrei SE5 para atualizar historico e chave externa.')
		endif
		
		if fk2 -> fk2_valor == _nSaldo .and. fk2 -> fk2_motbx == 'NOR'  // Para ter mais certeza de que estah posicionado no registro correto.
			//u_log ('Vou atualizar FK2')
			reclock ('FK2', .F.)
			fk2 -> fk2_histor = left (alltrim (fk2 -> fk2_histor) + ' TR.CC.FIL.' + ::FilDest + ' ' + ::Histor, tamsx3 ("FK2_HISTOR")[1])
			msunlock ()
			u_log2 ('info', 'regravei historico do FK2 para: ' + fk2 -> fk2_histor)
		endif
	endif

	// Se fez a baixa na filial de origem, recalcula saldo do lcto.
	if _lContinua
		::AtuSaldo ()
	endif

	// Se fez a baixa na filial de origem, agenda rotina batch para a inclusao na filial de destino.
	if _lContinua
		_oBatch := ClsBatch():new ()
		_oBatch:Dados    = 'Transf.sld.SZI fil.' + ::Filial + ' p/' + ::FilDest + '-Assoc.' + ::Assoc + '/' + ::Loja
		_oBatch:EmpDes   = cEmpAnt
		_oBatch:FilDes   = ::FilDest
		_oBatch:DataBase = dDataBase
		_oBatch:Modulo   = 6  // Campo E2_VACHVEX nao eh gravado em alguns modulos... vai saber...
		_oBatch:Comando  = "U_BatTrSZI('" + ::Assoc + "','" + ::Loja + "','" + ::SeqSZI + "','" + cEmpAnt + "','" + ::Filial + "','" + ::FilDest + "','" + ::TM + "','" + dtos (dDatabase) + "'," + cvaltochar (_nSaldo) + ")"
		_oBatch:Grava ()
	endif

//	u_logFim (GetClassName (::Self) + '.' + procname ())
return _lContinua



// --------------------------------------------------------------------------
// Verifica se o usuario tem os devidos acessos.
METHOD VerifUser (_sMsg) Class ClsCtaCorr
	_lRet = U_ZZUVL ('051', __cUserID, .T., cEmpAnt, cFilAnt)
	if ! _lRet
		::UltMsg += _sMsg
		u_help (::UltMsg,, .t.)
	endif
return _lRet
