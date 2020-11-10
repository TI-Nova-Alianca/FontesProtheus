// Programa:   MetaFin
// Autor:      Robert Koch
// Data:       03/06/2016
// Descricao:  Integracao Metadados com financeiro.
 
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Importa para o financeiro (contas a pagar) as obrigacoes geradas pelo sistema Metadados.
// #PalavasChave      #integracao #contas_a_pagar #folha #recolhimentos
// #TabelasPrincipais #SE2
// #Modulos           #FIN

// Historico de alteracoes:
// 08/06/2016 - Robert - TRatamento de data de emissao para determinados titulos.
//                     - Melhorado retorno de mensagens.
//                     - Controla desmembramento em filiais via tabela RHCONTASPAGARHISTLOG
// 08/07/2016 - Robert - Busca natureza do RHDEPOSITOSANALITICO para deposicos bancarios.
// 11/07/2016 - Robert - Grava tambem o campo E2_EMIS1 para que seja considerada a mesma 'data contabil'.
// 12/07/2016 - Robert - Mantem a a data de emissao quando TpItemCP='99' e Fornece$'001498/001853/001496'.
// 12/09/2016 - Robert - Regrava o campo E2_EMIS1 por que na versao P12 o sistema nao aceita o que eu passo no ExecAuto.
// 05/09/2017 - Robert - Antes de gerar SE2 verifica se a chave externa jah existe, para evitar geracao em duplicidade.
// 11/10/2017 - Robert - Database do Metadados migrado - alterado nome para acesso.
// 25/10/2018 - Robert - Criado tratamento para excluir titulos no financeiro.
// 08/04/2019 - Catia  - include TbiConn.ch 
// 19/12/2019 - Robert - Tratamento pontual abertura filial 16 (GLPI 7264).
//                     - Melhoradas mensagens de log.
//                     - Gravacao E2_VENCREA (estava ficando vazio).
// 05/09/2020 - Robert - Separadas rotinas de inclusao e exclusao.
//                     - Melhorados logs e retornos para o Metadados.
//                     - Incluidas tags para catalogo de fontes.
// 16/09/2020 - Robert - Melhorado controle/logs de desmembramento em mais de uma filial.
//

// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

user function MetaFin (_lAuto)
	private _nQtTitGer   := 0
	private _nQtTitDel   := 0
	private _nQtTitErr   := 0
	private _sErroAuto := ""  // Deixar private para ser usada pela funcao U_Help.

	// A rotina FINA050 soh funciona dentro destes modulos.
	if ! (AmIIn (5,6,7,11,12,14,41,97,17))           // S¢ Fin,GPE, Vei, Loja , Ofi, Pecas e Esp, EIC
		u_help ('Modulo invalido. Este programa precisa ter acesso a gerar titulos no financeiro.',, .t.)
		return
	endif

	if _lAuto == NIL .or. ! _lAuto
		if ! U_MsgYesNo ("Este programa executa a integracao entre Metadados e o modulo financeiro do Protheus. Deseja continuar?")
			return
		endif
	endif

	// Processa solicitacoes de inclusao e exclusao separadamente.
	processa ({|| _Incluir ()})
	processa ({|| _Excluir ()})

	// Caso seja execucao em batch, deixa mensagem pronta para retorno.
	if type ("_oBatch") == "O"
		_oBatch:Mensagens += 'Filial ' + cFilAnt + ': ' + cvaltochar (_nQtTitGer) + " titulos gerados; " + cvaltochar (_nQtTitDel) + " titulos excluidos; " + cvaltochar (_nQtTitErr) + " lctos com problemas. "
	else
		u_help (cvaltochar (_nQtTitGer) + " titulos gerados; " + cvaltochar (_nQtTitDel) + " titulos excluidos; " + cvaltochar (_nQtTitErr) + " lctos com problemas. ")
	endif
return



// --------------------------------------------------------------------------
static function _Incluir ()
	local _lContinua   := .T.
	local _oSQL        := NIL
	local _sAliasQ     := ""
	local _sMsgSE2     := ""
//	local _sDoc        := ""
//	local _aAutoSE2    := {}
//	local _sParcela    := ""
	local _dEmis       := ctod ('')
	local _oDUtil      := NIL
	local _sAnoMes     := ""
	local cPerg        := ""
	local _aBkpSX1     := {}
//	local _aFiliais    := {}
//	local _nFilial     := 0
//	local _lFilOK      := .F.
//	local _sNaturez    := ""
	private _sCTE        := ""  // Deixar private para ser vista em mais de uma function.
	
	procregua (10)

	// Inclusao de titulos
	if _lContinua
		incproc ()
		
		// Ajusta parametros da rotina.
		cPerg = 'FIN050    '
		_aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
		U_GravaSX1 (cPerg, "04", 2)  // Contabiliza online = nao

		// Monta uma string com a query principal para ser usada em mais de um local.
		_sCTE := ""
		_sCTE += "WITH CTE AS ("
		_sCTE += "SELECT CASE C.TIPOITEMCONTAPAGAR"
		_sCTE +=           " WHEN '05' THEN SUBSTRING (DARF.UNIDADE, 3, 2) "  // Tipo 05 = DARF PIS: busca detalhamento em tabela especifica.
		_sCTE +=           " WHEN '22' THEN SUBSTRING (DEP.ESTABELECIMENTO, 3, 2) "  // Tipo 22 = remessa p/ banco: busca detalhamento em tabela especifica.
		_sCTE +=           " ELSE SUBSTRING (C.ESTABELECIMENTO, 3, 2)"
		_sCTE +=       " END AS FILIAL,"
		_sCTE +=       " C.NROSEQUENCIAL,"
		_sCTE +=       " C.NROREMESSA,"
		_sCTE +=       " dbo.VA_DatetimeToVarchar (C.DATAINCLUSAO) AS EMISSAO,"
		_sCTE +=       " dbo.VA_DatetimeToVarchar (C.DATAVENCIMENTO) AS VENCTO, "
		_sCTE +=       " CASE C.TIPOITEMCONTAPAGAR"
		_sCTE +=           " WHEN '05' THEN DARF.VALOR "
		_sCTE +=           " WHEN '22' THEN DEP.VALOR "
		_sCTE +=           " ELSE C.VALOR"
		_sCTE +=       " END AS VALOR,"
		_sCTE +=       " SUBSTRING(C.DESCRICAO20, 1, 6) AS FORNECE,"
		_sCTE +=       " RTRIM(C.DESCRICAO250) + CASE WHEN C.TIPOITEMCONTAPAGAR = '22' THEN ' (Rem.' + CAST (C.NROREMESSA AS VARCHAR) + ')' ELSE '' END AS HIST,"
		_sCTE +=       " CASE C.TIPOITEMCONTAPAGAR"
		_sCTE +=           " WHEN '22' THEN RTRIM (DEP.NUMERODOCUMENTO) "  // Tipo 22 = remessa p/ banco: busca detalhamento em tabela especifica.
		_sCTE +=           " ELSE RTRIM (C.NUMERODOCUMENTO)"
		_sCTE +=       " END AS NATUREZA,"
		_sCTE +=       " C.TIPOITEMCONTAPAGAR AS TPITEMCP,"
		_sCTE +=       " C.STATUSREGISTRO AS STATUSREG"
		_sCTE +=  " FROM LKSRV_SIRH.SIRH.dbo.RHCONTASPAGARHIST C "
		
		// Busca detalhamento de remessa para bancos.
		_sCTE +=     " LEFT JOIN (SELECT EMPRESA, BANCO, NROREMESSA, ESTABELECIMENTO, NUMERODOCUMENTO, SUM (VALOR) AS VALOR"
		_sCTE +=                  " FROM LKSRV_SIRH.SIRH.dbo.RHDEPOSITOSANALITICO"
		_sCTE +=                 " WHERE EMPRESA = '00' + '" + cEmpAnt + "'"
		_sCTE +=                 " GROUP BY EMPRESA, BANCO, NROREMESSA, ESTABELECIMENTO, NUMERODOCUMENTO) AS DEP"
		_sCTE +=          " ON (DEP.EMPRESA = C.EMPRESA"
		_sCTE +=         " AND DEP.BANCO = C.BANCO"
		_sCTE +=         " AND DEP.NROREMESSA = C.NROREMESSA"
		_sCTE +=         " AND C.TIPOITEMCONTAPAGAR = '22')"

		// Busca detalhamento de DARF para pagamento de PIS.
		// Quando o RH gera os titulos de PIS antes do final do mes, a query abaixo nao os encontra (dataemissao > datainclusao). A solucao
		// atual eh incluir manualmente no financeiro. Outra possibilidade seria desvincular os titulos de PIS desta rotina automatica
		// e fazer a geracao atraves de um programa com parametrizacao manual do usuario, assim poderia gerar em qualquer data.
		_sCTE +=     " LEFT JOIN (SELECT EMPRESA, UNIDADE, DATAEMISSAO, SUM (LIQUIDOCOMPETENCIA) AS VALOR"
		_sCTE +=                  " FROM LKSRV_SIRH.SIRH.dbo.RHDARFANALITICO"
		_sCTE +=                 " WHERE ESTABELECIMENTO = '00' + '" + cEmpAnt + "'"
		_sCTE +=                   " AND TIPODARF = '3'" // 3=PIS
		_sCTE +=                   " AND DATAEMISSAO = (SELECT MAX (DATAEMISSAO)"
		_sCTE +=                                        " FROM LKSRV_SIRH.SIRH.dbo.RHDARFANALITICO"
		_sCTE +=                                       " WHERE ESTABELECIMENTO = '0001'"
		_sCTE +=                                         " AND TIPODARF = '3')"
		_sCTE +=                 " GROUP BY EMPRESA, UNIDADE, DATAEMISSAO"
		_sCTE +=               " ) AS DARF"
		_sCTE +=               " ON (DARF.EMPRESA = C.EMPRESA"
		_sCTE +=              " AND DARF.DATAEMISSAO < C.DATAINCLUSAO"
		_sCTE +=              " AND C.TIPOITEMCONTAPAGAR = '05')"

		_sCTE += " WHERE C.EMPRESA             = '00' + '" + cEmpAnt + "'"
		_sCTE +=   " AND C.STATUSREGISTRO     IN ('02', '10')"  // A processar e provisionado (para casos de multifilial).
//		_sCTE +=   " AND C.TIPOITEMCONTAPAGAR != '04'"  // DARF IRF s/ salarios: queremos por filial.
//		_sCTE +=   " AND C.TIPOITEMCONTAPAGAR != '10'"  // DARF IRF s/ autonomos: queremos por filial.
		_sCTE += ")"

		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := _sCTE
		_oSQL:_sQuery += " SELECT CTE.*"
		_oSQL:_sQuery +=   " FROM CTE"
		_oSQL:_sQuery +=  " WHERE FILIAL = '" + cFilAnt + "'"

		// Para os casos de titulos que o Metadados gera aglutinados por empresa, mas a Alianca deseja importar por filial,
		// marco-os como '10' (provisionado) no Metadados, e vou controlando se jah foram gerados para cada filial
		// atraves do arquivo de historicos. Por isso, nao mexer no texto do historico.
		_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                      " FROM LKSRV_SIRH.SIRH.dbo.RHCONTASPAGARHISTLOG"
		_oSQL:_sQuery +=                     " WHERE NROSEQUENCIAL = CTE.NROSEQUENCIAL"
		_oSQL:_sQuery +=                       " AND DESCRICAOMEMO LIKE 'Filial ' + CTE.FILIAL + ': Titulo gerado%')"
		_oSQL:_sQuery +=  " ORDER BY NROSEQUENCIAL, NROREMESSA"
		_oSQL:Log ()
		_sAliasQ = _oSQL:Qry2Trb (.F.)
		procregua ((_sAliasQ) -> (reccount ()))
		(_sAliasQ) -> (dbgotop ())
		do while _lContinua .and. ! (_sAliasQ) -> (eof ())
			u_log2 ('info', 'Iniciando inclusao seq.' + cvaltochar ((_sAliasQ) -> NroSequencial) + ' tipo ' + (_sAliasQ) -> TpItemCP + ' R$ ' + transform ((_sAliasQ) -> valor, "@E 999,999,999.99") + ' ' + (_sAliasQ) -> hist)

			if (_sAliasQ) -> TpItemCP $ '04/10'
				_sMsgSE2 = "Numero sequencial " + cvaltochar ((_sAliasQ) -> NroSequencial) + ": Tipo de item 04 (DARF IRF salarios) e 10 (DARF IRF autonomos): nao vai ser importado, pois queremos separado por filial."
				u_help (_sMsgSE2,, .t.)

				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "UPDATE LKSRV_SIRH.SIRH.dbo.RHCONTASPAGARHIST"
				_oSQL:_sQuery +=   " SET STATUSREGISTRO = '08'"
				_oSQL:_sQuery += " WHERE NROSEQUENCIAL = " + cvaltochar ((_sAliasQ) -> NroSequencial)
				_oSQL:Log ()
				_lContinua = _oSQL:Exec ()

				// Cria registro no log do Metadados com o motivo da rejeicao.
				_lContinua = _LogMeta ((_sAliasQ) -> NroSequencial, AllTrim (EnCodeUtf8 (_sMsgSE2)))

				(_sAliasQ) -> (dbskip ())
				loop
			endif

			// Alguns movimentos devem ser gerados com data de emissao = ultimo dia do mes anterior.
			if (_sAliasQ) -> TpItemCP $ '40/41/44/45' .OR. ;  // Folha avulsa/RPA # Ferias # Rescisao principal # Rescisao complementar
				((_sAliasQ) -> TpItemCP $ '22/99' .and. (_sALiasQ) -> Fornece $ '001498/001853/001496')
				_dEmis = stod ((_sAliasQ) -> emissao)
			else
				//U_LOG ('Alterando data de emissao para o ultimo dia do mes anterior.')
				_oDUtil := CLsDUtil ():New ()
				_sAnoMes = left ((_sAliasQ) -> emissao, 6)
				_dEmis = stod (_oDUtil:SubtrMes (_sAnoMes, 1) + '01')
				_dEmis = lastday (_dEmis)  
			endif
			
//			U_LOG2 ('DEBUG', (_sAliasQ) -> nrosequencial)
//			IF (_sAliasQ) -> nrosequencial == 7070  // SITUACAO ESPECIFICA QUE ESTAVA SEM NATUREZA
//				_GeraSE2 ((_sAliasQ) -> nrosequencial, (_sAliasQ) -> Fornece, '120401', _dEmis, stod ((_sAliasQ) -> vencto), (_sAliasQ) -> valor, (_sAliasQ) -> hist)
//			ELSE
			_GeraSE2 ((_sAliasQ) -> nrosequencial, (_sAliasQ) -> Fornece, (_sAliasQ) -> Natureza, _dEmis, stod ((_sAliasQ) -> vencto), (_sAliasQ) -> valor, (_sAliasQ) -> hist)
//			ENDIF

			(_sAliasQ) -> (dbskip ())
			u_log2 ('info', '')
		enddo

		U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina.
	endif


	// Caso seja execucao em batch, deixa mensagem pronta para retorno.
	if type ("_oBatch") == "O"
		_oBatch:Mensagens += 'Filial ' + cFilAnt + ': ' + cvaltochar (_nQtTitGer) + " titulos gerados; " + cvaltochar (_nQtTitDel) + " titulos excluidos; " + cvaltochar (_nQtTitErr) + " lctos com problemas. "
	else
		u_help (cvaltochar (_nQtTitGer) + " titulos gerados; " + cvaltochar (_nQtTitDel) + " titulos excluidos; " + cvaltochar (_nQtTitErr) + " lctos com problemas. ")
	endif
return



// --------------------------------------------------------------------------
static function _GeraSE2 (_nSeqMeta, _sFornece, _sNaturez, _dEmisSE2, _dVencSE2, _nValorSE2, _sHistSE2)
	local _oSQL     := NIL
	local _sDoc     := ''
	local _sParcela := ''
	local _sPrefixo := 'FOL'
	local _aAutoSE2 := {}
	local _sMsgSE2  := ''
	local _aFiliais    := {}
	local _nFilial     := 0
//	local _lFilOK      := .F.
	local _sChvEx      := ""
	local _sStatReg    := ''
	private lMsErroAuto	:= .f.  // Variavel padrao para rotinas automticas.
	private lMsHelpAuto	:= .f.  // Variavel padrao para rotinas automticas.

	// Gera 'chave externa' para o contas a pagar.
	_sChvEx = 'META' + cvaltochar (_nSeqMeta)

	// Verifica se a chave externa jah existe. Se existir, provavelmente falte apenas marcar a remessa como 'ok'.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " select R_E_C_N_O_"
	_oSQL:_sQuery +=   " from " + RetSQLName ("SE2") + " SE2 "
	_oSQL:_sQuery +=  " where SE2.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=    " and SE2.E2_FILIAL   = '" + xfilial ("SE2")   + "'"
	_oSQL:_sQuery +=    " and SE2.E2_VACHVEX  = '" + _sChvEx + "'"
	_oSQL:Log ()
	if _oSQL:RetQry (1, .F.) > 0
		_sMsgSE2 += "Numero sequencial " + cvaltochar (_nSeqMeta) + ": Titulo ja gerado no financeiro. Chave externa: " + _sChvEx
		u_help (_sMsgSE2)

		// Deixa o SE2 posicionado para poder executar a parte de atualizacao das tabelas do Metadados, pois
		// provavelmente soh estah passando por aqui por que na execucao anterior criou o titulo no SE2, mas
		// nao deve ter conseguido atualizar o retorno para o Matadados.
		se2 -> (dbgoto (_oSQL:RetQry (1, .F.)))
	else
		_sDoc = strzero (_nSeqMeta, tamsx3 ("E2_NUM")[1])

		// Encontra a maior parcela jah existente e gera a proxima.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""                                                                                            
		_oSQL:_sQuery += " select IsNull (max (E2_PARCELA), '1')"
		_oSQL:_sQuery +=   " from " + RetSQLName ("SE2") + " SE2 "
		_oSQL:_sQuery +=  " where SE2.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " and SE2.E2_FILIAL   = '" + xfilial ("SE2")   + "'"
		_oSQL:_sQuery +=    " and SE2.E2_FORNECE  = '" + _sFornece + "'"
		_oSQL:_sQuery +=    " and SE2.E2_LOJA     = '01'"
		_oSQL:_sQuery +=    " and SE2.E2_NUM      = '" + _sDoc     + "'"
		_oSQL:_sQuery +=    " and SE2.E2_PREFIXO  = '" + _sPrefixo + "'"
		//_oSQL:Log ()
		_sParcela = soma1 (_oSQL:RetQry ())

		_aAutoSE2 := {}
		aadd (_aAutoSE2, {"E2_PREFIXO", _sPrefixo,                                         NIL})
		aadd (_aAutoSE2, {"E2_NUM"    , _sDoc,                                             Nil})
		aadd (_aAutoSE2, {"E2_TIPO"   , 'FOL',                                             Nil})
		aadd (_aAutoSE2, {"E2_FORNECE", _sFornece,                             Nil})
		aadd (_aAutoSE2, {"E2_LOJA"   , '01',                                              Nil})
		aadd (_aAutoSE2, {"E2_NATUREZ", _sNaturez,                                         Nil})
		aadd (_aAutoSE2, {"E2_EMISSAO", _dEmisSE2,                                            Nil})
		aadd (_aAutoSE2, {"E2_EMIS1",   _dEmisSE2,                                            Nil})
		aadd (_aAutoSE2, {"E2_VENCTO" , _dVencSE2,                       Nil})
		aadd (_aAutoSE2, {"E2_VENCREA", dataValida (_dVencSE2),          Nil})
		aadd (_aAutoSE2, {"E2_VALOR"  , _nValorSE2,                               Nil})
		aadd (_aAutoSE2, {"E2_HIST"   , alltrim (U_NoAcento (_sHistSE2)),         Nil})
		aadd (_aAutoSE2, {"E2_PARCELA", _sParcela,                                         Nil})
		aadd (_aAutoSE2, {"E2_VACHVEX", _sChvEx, Nil})
		aadd (_aAutoSE2, {"E2_ORIGEM" , "U_METAFI",                                        Nil})
		_aAutoSE2 := aclone (U_OrdAuto (_aAutoSE2))
		u_log2 ('info', _aAutoSE2)
		lMsErroAuto	:= .f.
		lMsHelpAuto	:= .f.
		_sErroAuto  := ""
		dbselectarea ("SE2")
		dbsetorder (1)
		MsExecAuto({ | x,y,z | Fina050(x,y,z) }, _aAutoSE2,, 3)
	endif

	if lMsErroAuto
		u_log2 ('erro', "ExecAuto retornou erro")
		_nQtTitErr ++
		_sMsgSE2 += "Erro FINA050:" + U_LeErro (memoread (NomeAutoLog ())) + _sErroAuto
		u_help (_sMsgSE2,, .t.)

		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "UPDATE LKSRV_SIRH.SIRH.dbo.RHCONTASPAGARHIST"
		_oSQL:_sQuery +=   " SET STATUSREGISTRO = '08'"
		_oSQL:_sQuery += " WHERE NROSEQUENCIAL = " + cvaltochar (_nSeqMeta)
		_oSQL:Log ()
		_lContinua = _oSQL:Exec ()

		// Cria registro no log do Metadados com o motivo da rejeicao.
		_lContinua = _LogMeta (_nSeqMeta, AllTrim (EnCodeUtf8 (_sMsgSE2)))
	else
		_nQtTitGer ++
		u_log2 ('info', "ExecAuto retornou OK")

		// Atualiza a data de emissao original por que na versao P12 o sistema nao aceita o que eu passo no ExecAuto.
		reclock ("SE2", .F.)
		se2 -> e2_emis1 = se2 -> e2_emissao
		if empty (se2 -> E2_VACHVEX)  // Jah tivemos casos de nao gravar a chave externa.
			se2 -> E2_VACHVEX = _sChvEx
		endif
		msunlock ()

		// Cria registro no log do Metadados detalhando a operacao.
		// NAO ALTERAR o texto desta mensagem por que eh usada no desmembramento por filial.
		_lContinua = _LogMeta (_nSeqMeta, "Filial " + cFilAnt + ": Titulo gerado: " + _sPrefixo + "/" + _sDoc + "-" + _sParcela + " R$ " + alltrim (transform (_nValorSE2, "@E 999,999,999,999.99")))

		// Se for um titulo que precisa desmembramento em mais de uma filial (ex.: DARFs e envios
		// de arquivos de pagamento para bancos), usa o arquivo de log dos historicos do Metadados
		// para controle de cada filial e mantem o sequencial do Metadados com status 10 (provisionado),
		// que eu entenderia como 'em andamento'.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := _sCTE
		_oSQL:_sQuery += " SELECT FILIAL,"
		_oSQL:_sQuery +=        " (SELECT COUNT (*)"
		_oSQL:_sQuery +=           " FROM LKSRV_SIRH.SIRH.dbo.RHCONTASPAGARHISTLOG"
		_oSQL:_sQuery +=          " WHERE NROSEQUENCIAL = " + cvaltochar (_nSeqMeta)
		_oSQL:_sQuery +=            " AND DESCRICAOMEMO LIKE 'Filial ' + CTE.FILIAL + ': Titulo gerado%')"
		_oSQL:_sQuery +=   " FROM CTE"
		_oSQL:_sQuery +=  " WHERE NROSEQUENCIAL = " + cvaltochar (_nSeqMeta)
		_oSQL:Log ()
		_aFiliais = _oSQL:Qry2Array ()
		//u_log (_aFiliais)
		
		// Verifica se falta gerar para alguma filial.
		_sStatReg = '03'  // Inicialmente, assume que gerou para todas, 'ateh prova em contrario'.
//		_lFilOK = .T.
		for _nFilial = 1 to len (_aFiliais)
			if _aFiliais [_nFilial, 2] == 0
				_sStatReg = '10'  // Achei uma 'prova em contrario'
				u_log2 ('info', 'Verifiquei que ainda falta gerar para a filial ' + _aFiliais [_nFilial, 1] + '. Manterei o Metadados com status=' + _sStatReg)
//				_lFilOk = .F.
			else
				u_log2 ('info', 'Verifiquei que jah foi gerado para a filial ' + _aFiliais [_nFilial, 1])
			endif
		next

		// Muda status da sequencia no Metadados.
		_oSQL:_sQuery := "UPDATE LKSRV_SIRH.SIRH.dbo.RHCONTASPAGARHIST"
//		_oSQL:_sQuery +=   " SET STATUSREGISTRO          = '" + iif (_lFilOK, "03", "10") + "',"  // Se jah gerou para todas as filiais, marca como 03 (aceito)
		_oSQL:_sQuery +=   " SET STATUSREGISTRO          = '" + _sStatReg + "',"
		_oSQL:_sQuery +=       " DATAACEITACAOLIBERACAO  = cast ('" + dtos (date ()) + " " + time () + "' as datetime),"
	//	_oSQL:_sQuery +=       " CHAVEOUTROSISTEMATITULO = " + _sDoc + ","
		_oSQL:_sQuery +=       " CHAVEOUTROSISTEMATITULO = " + se2 -> e2_num + ","
	//	_oSQL:_sQuery +=       " NUMEROTITULO            = " + _sDoc + ","
		_oSQL:_sQuery +=       " NUMEROTITULO            = " + se2 -> e2_num + ","
	//	_oSQL:_sQuery +=       " SERIEDOC                = '" + _sPrefixo + _sParcela + "'"
		_oSQL:_sQuery +=       " SERIEDOC                = '" + se2 -> e2_prefixo + se2 -> e2_parcela + "'"
		_oSQL:_sQuery += " WHERE NROSEQUENCIAL = " + cvaltochar (_nSeqMeta)
		_oSQL:Log ()
		_lContinua = _oSQL:Exec ()
	endif
return



// --------------------------------------------------------------------------
static function _Excluir ()
	local _lContinua   := .T.
	local _oSQL        := NIL
	local _sAliasQ     := ""
	local _sMsgSE2     := ""
//	local _sDoc        := ""
//	local _sPrefixo    := 'FOL'
	local _aAutoSE2    := {}
//	local _sParcela    := ""
//	local _dEmis       := ctod ('')
//	local _oDUtil      := NIL
//	local _sAnoMes     := ""
//	local _sChvEx      := ""
//	local cPerg        := ""
//	local _aBkpSX1     := {}
//	local _sCTE        := ""
//	local _aFiliais    := {}
//	local _nFilial     := 0
//	local _lFilOK      := .F.
	local _sChaveSE2   := ''
//	local _sNaturez    := ""
//	local _nQtTitGer   := 0
	private lMsErroAuto	:= .f.  // Variavel padrao para rotinas automticas.
	private lMsHelpAuto	:= .f.  // Variavel padrao para rotinas automticas.
	
	procregua (10)

	// Exclusao de titulos
	if _lContinua
		u_log2 ('info', 'Verificando se ha movimentos para excluir')
		incproc ()
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT NROSEQUENCIAL,"
		_oSQL:_sQuery +=       " CHAVEOUTROSISTEMATITULO AS NUM,"
		_oSQL:_sQuery +=       " SERIEDOC"
		_oSQL:_sQuery +=  " FROM LKSRV_SIRH.SIRH.dbo.RHCONTASPAGARHIST"
		_oSQL:_sQuery += " WHERE EMPRESA         = '00' + '" + cEmpAnt + "'"
		_oSQL:_sQuery +=   " AND ESTABELECIMENTO = '00' + '" + cFilAnt + "'"
		//_oSQL:_sQuery +=   " AND STATUSREGISTRO  = '04'"
		_oSQL:_sQuery +=   " AND CHAVEOUTROSISTEMATITULO is not null"
		_oSQL:_sQuery +=   " AND STATUSREGISTRO  IN ('04','07')"
		_oSQL:Log () 
		_sAliasQ = _oSQL:Qry2Trb (.F.)
		procregua ((_sAliasQ) -> (reccount ()))
		(_sAliasQ) -> (dbgotop ())
		do while _lContinua .and. ! (_sAliasQ) -> (eof ())
			u_log2 ('info', 'Iniciando exclusao - Seq ' + cvaltochar ((_sAliasQ) -> NroSequencial))
			_sChaveSE2 = xfilial ("SE2") + substr ((_sAliasQ) -> SerieDoc, 1, 3) + strzero ((_sAliasQ) -> num, 9) + substr ((_sAliasQ) -> SerieDoc, 4, 1)
			U_LOG2 ('debug', 'Pesquisando SE2 com a seguinte chave: >>' + _sChaveSE2 + '<<')
			se2 -> (dbsetorder (1))  // E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
			if se2 -> (dbseek (_sChaveSE2, .F.))
				lMsErroAuto	:= .f.
				lMsHelpAuto	:= .f.
				_sErroAuto  := ""
				_aAutoSE2 = {}
				aadd (_aAutoSE2, {"E2_PREFIXO", SE2->E2_PREFIXO , NIL })
				aadd (_aAutoSE2, {"E2_NUM"    , SE2->E2_NUM     , NIL })
				aadd (_aAutoSE2, {"E2_PARCELA", SE2->E2_PARCELA , NIL })
				aadd (_aAutoSE2, {"E2_FORNECE", SE2->E2_fornece , NIL })
				aadd (_aAutoSE2, {"E2_LOJA"   , SE2->E2_loja    , NIL })
				//u_log (_aAutoSE2)
				dbselectarea ("SE2")
				dbsetorder (1)
				MsExecAuto( { |x,y,z| FINA050(x,y,z)}, _aAutoSE2,, 5)  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
				if lMsErroAuto
					_nQtTitErr ++
					_sMsgSE2 = "Impossivel excluir titulo " + strzero ((_sAliasQ) -> num, 9) + " Erro FINA050:" + U_LeErro (memoread (NomeAutoLog ())) + _sErroAuto
				else
					_nQtTitDel ++
					_sMsgSE2 = "Titulo " + strzero ((_sAliasQ) -> num, 9) + " excluido com sucesso."
				endif
				u_help (_sMsgSE2)
				_LogMeta ((_sAliasQ) -> NroSequencial, AllTrim (EnCodeUtf8 (_sMsgSE2)))

				// Muda status da sequencia no Metadados.
				_oSQL:_sQuery := "UPDATE LKSRV_SIRH.SIRH.dbo.RHCONTASPAGARHIST"
				_oSQL:_sQuery +=   " SET STATUSREGISTRO          = '" + iif (lMsErroAuto, "05", "06") + "'"
				_oSQL:_sQuery += " WHERE NROSEQUENCIAL = " + cvaltochar ((_sAliasQ) -> NroSequencial)
				_oSQL:Log ()
				_oSQL:Exec ()

			else
				u_log2 ('info', "Titulo nao encontrado no SE2 (ja deve estar excluido): " + xfilial ("SE2") + substr ((_sAliasQ) -> SerieDoc, 1, 3) + U_TamFixo (cvaltochar ((_sAliasQ) -> num), 9, ' ') + substr ((_sAliasQ) -> SerieDoc, 4, 1))
			endif
			(_sAliasQ) -> (dbskip ())
		enddo
	endif
	
return



// --------------------------------------------------------------------------
// Atualiza o arquivo de logs no Metadados.
static function _LogMeta (_nSeq, _sMsg)
	local _nNroOrdem := 0
	local _oSQL      := NIL
	local _lContinua := .F.

	// Busca a proxima ordem livre para esta sequencia.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " SELECT ISNULL ((SELECT MAX (NROORDEM)"
	_oSQL:_sQuery +=                   " FROM LKSRV_SIRH.SIRH.dbo.RHCONTASPAGARHISTLOG" 
	_oSQL:_sQuery +=                  " WHERE NROSEQUENCIAL = " + cvaltochar (_nSeq) + "), 0) "
	_oSQL:Log ()
	_nNroOrdem = _oSQL:RetQry ()

	_oSQL:_sQuery := "INSERT INTO LKSRV_SIRH.SIRH.dbo.RHCONTASPAGARHISTLOG"
	_oSQL:_sQuery +=        " (NROSEQUENCIAL, NROORDEM, DATAHORAALTERACAO, DESCRICAOMEMO)"
	_oSQL:_sQuery += " VALUES (" + cvaltochar (_nSeq) + ", "
	_oSQL:_sQuery +=         cvaltochar (_nNroOrdem + 1) + ","
	_oSQL:_sQuery +=         " getdate (), " //cast ('" + dtos (date ()) + " " + time () +  "' as datetime),"
	_oSQL:_sQuery +=         "'" + _sMsg + "'"
	_oSQL:_sQuery +=         ")"
	_oSQL:Log ()
	_lContinua = _oSQL:Exec ()
return _lContinua
