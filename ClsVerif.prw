// Programa:  ClsVerif
// Autor:     Robert Koch
// Data:      12/11/2016
// Descricao: Declaracao de classe de verificacoes diversas, geralmente para execucao em batch.
//            Criada com base nos programas VerCMed e VerIndl.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Classe
// #Descricao         #Classe com tratamento para verificacoes diversas de inconsistencias no sistema.
// #PalavasChave      #verificacoes
// #TabelasPrincipais 
// #Modulos           #todos_modulos

// Historico de alteracoes:
// 24/11/2016 - Robert - Criada possibilidade de parametrizacao das consultas (ValidPerg, SetParam, ...)
//                     - Criada consulta 4 (compara SB9 anterior + kardex com SB9 atual).
// 29/03/2017 - Robert - Importadas do programa VERSAFR.PRW varias verificacoes de safra.
// 12/05/2017 - Robert - Criada verificacao 25.
// 27/05/2017 - Robert - Criada verificacao 26.
// 16/10/2017 - Robert - Criadas verificacoes 27 e 28.
// 13/11/2017 - Robert - Criada verificacao 30.
// 17/11/2017 - Robert - Metodo Conv2THM passa a receber parametro de numero maximo de linhas.
// 04/12/2017 - Robert - Melhorada geracao da query para quando chadada a partir do metodo SetParam.
// 12/12/2017 - Robert - Ajuste chamada ValidPerg.
// 16/01/2018 - Robert - Desconsidera cargas canceladas na consulta 8.
// 13/03/2018 - Robert - Implementada verificacao 36 (Pendencias do tipo Empenho (tabela SDC) relacionado a OP inexistente ou ja encerrada).
// 12/09/2018 - Robert - Criada verificacao 37.
// 26/11/2018 - Andre  - Ajustado nome da tabela SG1
// 18/06/2019 - Robert - Verificacao 29 passa a ser enviada tambem para o setor CML (comercial).
// 30/08/2019 - Claudia - Alterado campo de peso bruto para b1_pesbru.
// 17/09/2019 - Claudia - Adicionada verificação 39. GLPI: 6673
// 19/09/2019 - Claudia - Adicionada verificação 40. GLPI: 6673
// 24/09/2019 - Cláudia - Migração de verificações para novo modelo. GLPI:6722
//						- Validação 41 a 46
// 25/09/2019 - Cláudia - Migração de verificações para novo modelo. Validação 47 a 50. GLPI:6722
// 30/09/2019 - Cláudia - Migração de verificações para novo modelo. Validação 51 a 60. GLPI:6722
// 14/02/2020 - Robert  - Consulta 24 (etiq. nao guardadas): chave entrada_id da tabela tb_wms_entrada mudou de ['SD3' + D3_FILIAL + D3_DOC + D3_OP + D3_COD + D3_NUMSEQ] para ['ZA1' + APONT.D3_FILIAL + APONT.D3_VAETIQ]
// 25/03/2020 - Robert  - Verificacao 20 desabilitada (ver comentario no local)
//                      - Parametros de safra passam a aceitar mais de um TES para entrada e mais de um para saida.
//                      - Verificacao 11 passa a validar sistema de conducao.
// 31/03/2020 - Claudia - Desativada a rotina 59, conforme GLPI: 7736
// 06/04/2020 - Cláudia - Alterada verificação 55 conforme GLPI: 7409
// 14/05/2020 - Robert  - Ajustes consulta totais safras e verificacoes de lctos padrao.
// 06/10/2020 - Robert  - Criadas verificacoes 69 a 72
//                      - Inseridas tags para catalogo de fontes.
// 08/10/2020 - Robert  - Verificacao SD5 x SD3 nao considerava D5_LOTECTL = D3_LOTECTL.
//                      - Passa a enviar a query junto no e-mail, para ajudar em testes posteriores.
// 22/10/2020 - Robert  - Adicionados acessos que deveriam e que nao deveriam existir, nas verif. de acessos do sigacfg.
// 23/11/2020 - Robert  - Criada validacao 76 (Todos os grupos deveriam ter privilegio 000002).
// 07/12/2020 - Robert  - Criada validacao 77 (pessoa do Metadados referenciando mais de um usuario no Protheus).
// 18/12/2020 - Robert  - Verificacao 26 passa a usar a procedure VA_SP_VERIFICA_ESTOQUES e passa a ser de interesse tambem de CUS/CTB. (GLPI 9054).
// 26/01/2021 - Robert  - Verificacao 77 considerava usuarios bloqueados (que mudaram de username, por exemplo).
// 08/02/2021 - Robert  - View VA_VUSR_PROTHEUS_X_METADADOS migrada para o database TI. Passa a usar linked server. (GLPI 9353)
// 25/02/2021 - Robert  - Verificacao 78 passa a usar a view VISAO_GERAL_ACESSOS.
// 04/03/2021 - Robert  - Consulta 69 passa a usar tabelas padrao do sistema (agora usuarios estao no banco de dados).
// 12/03/2021 - Robert  - Ignorar usuario robert_teste na verificacao 78
// 02/07/2021 - Robert  - Consultas 77 e 79 deixam de usar a view VA_VUSR_PROTHEUS_X_METADADOS.
// 09/07/2021 - Robert  - Consulta 68 tinha a data fixa de B9_DATA=31/08/2019 e tambem B2_FILIAL=01 (GLPI 10457).
// 23/08/2021 - Robert  - Criada verificacao 81.
// 30/08/2021 - Robert  - Ajustadas ou desabilitadas verificacoes que usavam as tabelas VA_USR*
// 31/08/2021 - Robert  - Criado atributo UltVerif para ajudar em loops que executam todas as validacoes (GLPI 10876)
// 16/09/2021 - Robert  - Ajustes verif. 73 e 80 (desconsiderar deletados e usr.bloqueados).
// 27/09/2021 - Robert  - Adicionada verificacao de modulos na verificacao 74
// 18/02/2022 - Robert  - Adicionada verificacao de itens de mao de obra x CC (GLPI 11650).
// 23/02/2022 - Robert  - Adicionada verificacao 83 (Empenho SD4 relacionado a OP/OS inexistente ou ja encerrada)
// 05/03/2022 - Robert  - Adicionada verificacao 85 (inconsistencias etiq.producao) - GLPI 11486
// 23/03/2022 - Robert  - Verificacao 82 ajustado item 'MO-' para 'AO-'.
// 05/04/2022 - Robert  - Consulta 82 passa a aceitar todas as filiais (para poder ser chamada de outras rotinas)
// 11/04/2022 - Claudia - Excluido o usuario app.mntng da consulta 78.
// 16/05/2022 - Robert  - Adicionada verificacao 87 - Parametrizacoes TSS (GLPI 12042)
// 17/05/2022 - Robert  - Adicionada verificacao 88 - Gatilhos (GLPI 12063)
//                      - Melhorada definicao do atributo :UltVerif
// 31/05/2022 - Robert  - Adicionada verificacao 89 - ambientes SPED (GLPI 12126)
// 05/06/2022 - Robert  - Adicionada verificacao 90 (GLPI 12133)
// 07/06/2022 - Robert  - Ajustes query verif.06 que concatenava com a anterior.
// 08/08/2022 - Robert  - Melhoria formatacao HTML para envio por e-mail.
// 23/08/2022 - Robert  - Criada sugestao para a verificacao 42 (GLPI 12134)
// 09/09/2022 - Robert  - Criada verificacao 91.
// 12/09/2022 - Robert  - Verif.91: Melhorado relacionamento entre MP_SYSTEM_PROFILE e SYS_USR
// 06/10/2022 - Robert  - Verif.82 passa a ser valida para todas as filiais (GLPI 12324)
// 18/11/2022 - Robert  - Criada verificacao 92.
// 26/11/2022 - Robert  - Criado atributo :ComTela
// 15/12/2022 - Claudia - Incluido parametros na verificação 28. GLPI: 12938
// 23/01/2023 - Robert  - Criada verificacao 93.
// 03/03/2023 - Robert  - Campo VA_VNOTAS_SAFRA.TIPO_FORNEC passa a ter novo conteudo.
// 24/03/2023 - Robert  - Verif.24 passa a desconsiderar OPs para envase 'em terceiros' (seguem fluxo diferente para entrada no FullWMS)
//

#include "protheus.ch"

// --------------------------------------------------------------------------------------------------------------------
// Classe usada para verificacoes de inconsistencias em geral.
CLASS ClsVerif

	// Declaracao das propriedades da Classe
	data aHeader     // Para o caso de exportar no formato aHeader/aCols
	data Ativa       // Se encontra-se ativa (.T. / .F.)
	data ComTela     // Indica se mostra (.T.) mensagens em tela (posso estar usando em batch)
	data Descricao   // Descricao da verificacao
	data Dica        // Dica para o usuario.
	data ExecutouOK  // Indica se executou a verificacao sem problemas
	data Filiais     // String contendo as filiais (*=todas) para as quais a consulta deve ser habilitada. Ex.: 01/03/05
	data GrupoPerg   // Grupo de perguntas no SX1, quando houver.
	data LiberZZU    // Grupos da tabela ZZU que podem acessar esta consulta. Se vazio, estah liberada para todos.
	data MesAntEstq  // Mes ja fechado no estoque.
	data MesAtuEstq  // Mes em aberto no estoque.
	data Numero      // Numero (codigo) da verificacao
	data Param01     // NAO alterar diretamente. Usar o metodo SetParam().
	data Param02     // NAO alterar diretamente. Usar o metodo SetParam().
	data Param03     // NAO alterar diretamente. Usar o metodo SetParam().
	data Param04     // NAO alterar diretamente. Usar o metodo SetParam().
	data Param05     // NAO alterar diretamente. Usar o metodo SetParam().
	data Param06     // NAO alterar diretamente. Usar o metodo SetParam().
	data Param07     // NAO alterar diretamente. Usar o metodo SetParam().
	data Param08     // NAO alterar diretamente. Usar o metodo SetParam().
	data Param09     // NAO alterar diretamente. Usar o metodo SetParam().
	data Param10     // NAO alterar diretamente. Usar o metodo SetParam().
	data QtErros     // Quantidade de erros encontrados
	data QuandoUsar  // Descritivo de situacao/momento em que a verificacao deve ser feita.
	data Query       // Query para execucao
	data Result      // Resultado (array com os problemas encontrados)
	data Setores     // String com os setores da empresa que teriam interesse na verificacao.
	data Sugestao    // Sugestao de correcao a ser mostrada para o usuario.
	data UltMsg      // Ultima mensagem de erro
	data UltVerif    // Numero da ultima verificacao.
	data ViaBatch    // Indica se esta verificacao deve ser executada via batch ou apenas manualmente.

	// Declaracao dos Metodos da Classe
	method New ()
	method ConvHTM ()
	method Executa ()
	method GeraQry ()
	method Pergunte ()
	method SetParam ()
	method ValidPerg ()
	method VerifParam ()
ENDCLASS
//
// --------------------------------------------------------------------------------------------------
METHOD New (_nQual) Class ClsVerif
	::Numero     = 0
	::Ativa      = .T.
	::ComTela    = .T.
	::Filiais    = '*'
	::Query      = ""
	::Descricao  = ""
	::QtErros    = 0
	::Result     = {}
	::UltMsg     = ""
	::ExecutouOK = .F.
	::aHeader    = {}
	::Setores    = ""
	::GrupoPerg  = ""
	::Sugestao   = ""
	::LiberZZU   = {}
	::Dica       = ""
	::ViaBatch   = .T.
	::MesAntEstq = substr (dtos (GetMv ("MV_ULMES")), 1, 6)
	::MesAtuEstq = substr (dtos (GetMv ("MV_ULMES") + 1), 1, 6)
	::QuandoUsar = "A qualquer momento"

	// Se recebi um numero de verificacao definido, nao preciso ficar testando a existencia de todas.
	if valtype (_nQual) == 'N'
//		U_Log2 ('debug', '[' + GetClassName (::Self) + '.' + procname () + ']Recebi um numero de verificacao definido: ' + cvaltochar (_nQual))
		::Numero = _nQual
	else
		// Para determinar qual a ultima verificacao, vou comecar por um numero
		// alto e ir buscando para tras, ateh encontrar uma verificacao definida.
		// Jah tentei diversas formas de fazer isso, mas no final sempre acabo
		// criando somente o CASE que define a query e esqueco de atualizar o
		// atributo :UltVerif.
		for ::Numero = 150 to 1 step -1  // Manter aqui sempre um numero maior que o da ultima verificacao.
			::UltMsg = ''
			::GeraQry (.T.)
			if ! empty (::Query)
				::UltVerif = ::Numero
				::Numero = 0
				exit
			endif
		next
	endif

	::GeraQry (.T.)

Return Self


// --------------------------------------------------------------------------
// Converte o resultado para formato HTML.
METHOD ConvHTM (_nMaxLin) Class ClsVerif
	local _sRet  := ""
	local _oUtil := NIL

	if ::ExecutouOK
		_oUtil := ClsAUtil ():New (::Result)
		_sRet = _oUtil:ConvHtm (::Descricao, NIL, NIL, NIL, _nMaxLin)
	endif

	if ! empty (::Sugestao)
		_sRet += chr (13) + chr (10) + '</br></br>Sugestao: ' + alltrim (::Sugestao) + '</br>'
	endif
	if ! empty (::Query)
		_sRet += chr (13) + chr (10) + '</br></br>Query para verificacao: ' + alltrim (::Query) + '</br>'
	endif

Return _sRet


// --------------------------------------------------------------------------
// Executa a verificacao.
METHOD Executa () Class ClsVerif
	local _aAreaAnt  := U_ML_SRArea ()
	local _lContinua := .T.
	local _oSQL      := NIL

	if _lContinua .and. empty (::Query)
		::UltMsg += "Query nao definida para esta verificacao."
		if ::ComTela
			u_help (::UltMsg,, .t.)
		else
			U_Log2 ('erro', '[' + GetClassName (::Self) + '.' + procname () + ']' + ::UltMsg)
		endif
		_lContinua = .F.
	endif
	if _lContinua .and. ::Filiais != '*' .and. ! cFilAnt $ ::Filiais
		::UltMsg += "Query nao se destina a esta filial."
		if ::ComTela
			u_help (::UltMsg,, .t.)
		else
			U_Log2 ('erro', '[' + GetClassName (::Self) + '.' + procname () + ']' + ::UltMsg)
		endif
		_lContinua = .F.
	endif
	if _lContinua
		_lContinua = ::VerifParam ()
	endif
	if _lContinua
		CursorWait ()
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery = ::Query
		_oSQL:lGeraHead = .T.  // Para gerar array 'aHeader' ao final da execucao da query
		_oSQL:Log ('[' + GetClassName (::Self) + '.' + procname () + ']')
		::Result = aclone (_oSQL:Qry2Array (.F., .T.))
		::QtErros = len (::Result) - 1  // Primeira linha tem os nomes de campos
		::ExecutouOK = .T.

		// Deixa variavel criada para o caso do usuario pedir exportacao para planilha.
		::aHeader := aclone (_oSQL:aHeader)
		CursorArrow ()
	endif

	U_ML_SRArea (_aAreaAnt)
return _lContinua


// --------------------------------------------------------------------------
// Gera a query para a consulta.
METHOD GeraQry (_lDefault) Class ClsVerif
	//u_logIni (GetClassName (::Self) + '.' + procname ())
	do case
		case ::Numero == 1
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores   = 'PCP'
			::Descricao = 'Produto deveria ter revisao padrao no cadastro'
			::Sugestao  = "Revise o campo '" + alltrim (RetTitle ("B1_REVATU")) + "' cadastro do produto"
			::Query := ""
			::Query += "WITH REVISOES AS (SELECT DISTINCT G1_COD, G1_REVINI, G1_REVFIM"
			::Query +=                     " FROM " + RetSQLName ("SG1") + " SG1 "
			::Query +=                    " WHERE SG1.D_E_L_E_T_ = ''
			::Query +=                      " AND SG1.G1_FILIAL = '" + xfilial ("SG1") + "'"
			::Query +=                   ")"
			::Query += " SELECT REVISOES.G1_COD AS PRODUTO,"
			::Query +=        " SB1.B1_DESC     AS DESCRICAO,"
			::Query +=        " REVISOES.G1_REVINI AS REV_INICIAL,"
			::Query +=        " REVISOES.G1_REVFIM AS REV_FINAL"
			::Query +=   " FROM	REVISOES,"
			::Query +=          RetSQLName ("SB1") + " SB1 "
			::Query +=  " WHERE SB1.D_E_L_E_T_ = ''"
			::Query +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			::Query +=    " AND SB1.B1_COD     = REVISOES.G1_COD"
			::Query +=    " AND SB1.B1_REVATU  = ''"
			::Query +=    " AND G1_COD IN (SELECT G1_COD"
			::Query +=                     " FROM REVISOES"
			::Query +=                    " GROUP BY G1_COD"
			::Query +=                   " HAVING COUNT(*) > 1"
			::Query +=                   ")" 
			::Query +=  " ORDER BY G1_COD"

		case ::Numero == 2
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores   = 'ENG'
			::Descricao = 'Produto tem revisao padrao informada no seu cadastro, mas o cadastro da propria revisao nao existe'
			::Sugestao  = "Cadastre a revisao"
			::Query := ""
			::Query += "SELECT B1_COD AS PRODUTO, B1_DESC AS DESCRICAO, B1_REVATU AS REVISAO"
			::Query +=  " FROM " + RetSQLName ("SB1") + " SB1 "
			::Query += " WHERE SB1.D_E_L_E_T_ = ''
			::Query +=   " AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
			::Query +=   " AND SB1.B1_REVATU != ''"
			::Query +=   " AND NOT EXISTS (SELECT *"
			::Query +=                     " FROM " + RetSQLName ("SG5") + " SG5 "
			::Query +=                    " WHERE SG5.D_E_L_E_T_ = ''
			::Query +=                      " AND SG5.G5_FILIAL  = '" + xfilial ("SG5") + "'"
			::Query +=                      " AND SG5.G5_PRODUTO = SB1.B1_COD"
			::Query +=                    ")"
			::Query += " ORDER BY B1_COD"

		case ::Numero == 3
			::Setores   = 'CUS'
			::Descricao = 'Movimentacao com data futura'
			::Sugestao  = 'Revise a movimentacao.' 
			::Query := "SELECT ORIGEM, EMISSAO, DOC, OP "
			::Query +=  " FROM (SELECT 'Mov.internos' AS ORIGEM, D3_EMISSAO AS EMISSAO, D3_DOC AS DOC, D3_OP AS OP, D3_USUARIO AS USUARIO"
			::Query +=          " FROM " + RetSQLName ("SD3")
			::Query +=         " WHERE D_E_L_E_T_ = ''"
			::Query +=           " AND D3_FILIAL = '" + xfilial ("SD3") + "'"
			::Query +=           " AND D3_EMISSAO > '" + dtos (date ()) + "'"
			::Query +=           " AND D3_ESTORNO != 'S'"
			::Query +=         " UNION ALL"
			::Query +=        " SELECT 'NF saida', D2_EMISSAO, D2_DOC, '', ''"
			::Query +=          " FROM " + RetSQLName ("SD2")
			::Query +=         " WHERE D_E_L_E_T_ = ''"
			::Query +=           " AND D2_FILIAL = '" + xfilial ("SD2") + "'"
			::Query +=           " AND D2_EMISSAO > '" + dtos (date ()) + "'"
			::Query +=         " UNION ALL"
			::Query +=        " SELECT 'NF entrada', D1_DTDIGIT, D1_DOC, '', ''"
			::Query +=          " FROM " + RetSQLName ("SD1")
			::Query +=         " WHERE D_E_L_E_T_ = ''"
			::Query +=           " AND D1_FILIAL = '" + xfilial ("SD1") + "'"
			::Query +=           " AND D1_DTDIGIT > '" + dtos (date ()) + "'"
			::Query +=         " ) AS TODOS"

		case ::Numero == 4
			::Setores   = 'CUS/CTB'
			::GrupoPerg = "U_VALID004"
			::ValidPerg (_lDefault)
			::Descricao = 'Fech.estq. diferente fech.ant + kardex'
			::Sugestao  = 'Revise a movimentacao. Se o problema persistir, verifique a necessidade de reabrir o periodo e refazer a virada de saldos.'
			::Dica      = "Esta verificacao deve ser executada para meses ja fechados, informando sempre as datas do ultimo dia de cada mes."
			::QuandoUsar = "Apos a virada de saldos do estoque."
			::Query := ""
			::Query += "WITH C AS ("
			::Query += " SELECT B2_FILIAL AS FILIAL,"
			::Query +=        " B2_LOCAL AS ALMOX,"
			::Query +=        " B1_TIPO AS TIPO,"
			::Query +=        " B2_COD AS PRODUTO,"
			::Query +=        " RTRIM(B1_DESC) AS DESCRICAO,"
			::Query +=        " B1_UM AS UN_MED,"
			::Query +=        " ISNULL((SELECT B9_QINI"
			::Query +=                  " FROM " + RetSQLName ("SB9") + " SB9"
			::Query +=                 " WHERE SB9.D_E_L_E_T_ = ''"
			::Query +=                   " AND SB9.B9_FILIAL  = SB2.B2_FILIAL"
			::Query +=                   " AND SB9.B9_COD     = SB2.B2_COD"
			::Query +=                   " AND SB9.B9_LOCAL   = SB2.B2_LOCAL"
			::Query +=                   " AND SB9.B9_DATA    = '" + dtos (::Param01) + "'), 0) AS QT_ANT_SB9,"
			::Query +=        " ISNULL(SUM(D1.ENT_SD1), 0) AS ENT_SD1,"
			::Query +=        " ISNULL(SUM(D2.SAI_SD2), 0) AS SAI_SD2,"
			::Query +=        " ISNULL(SUM(D3.ENT_SD3), 0) AS ENT_SD3,"
			::Query +=        " ISNULL(SUM(D3.SAI_SD3), 0) AS SAI_SD3,"
			::Query +=        " ISNULL((SELECT B9_QINI"
			::Query +=                  " FROM " + RetSQLName ("SB9") + " SB9"
			::Query +=                 " WHERE SB9.D_E_L_E_T_ = ''"
			::Query +=                   " AND SB9.B9_FILIAL  = SB2.B2_FILIAL"
			::Query +=                   " AND SB9.B9_COD     = SB2.B2_COD"
			::Query +=                   " AND SB9.B9_LOCAL   = SB2.B2_LOCAL"
			::Query +=                   " AND SB9.B9_DATA    = '" + dtos (::Param02) + "'), 0) AS QT_FIM_SB9"
			::Query +=   " FROM " + RetSQLName ("SB1") + " SB1,"
			::Query +=              RetSQLName ("SB2") + " SB2 "
			::Query +=      " LEFT JOIN (SELECT D1_COD, D1_LOCAL, SUM (D1_QUANT) AS ENT_SD1"
			::Query +=                   " FROM " + RetSQLName ("SD1") + " SD1, "
			::Query +=                              RetSQLName ("SF4") + " SF4 "
			::Query +=                  " WHERE SD1.D_E_L_E_T_ != '*'"
			::Query +=                    " AND SD1.D1_FILIAL   = '" + xfilial ("SD1") + "'"
			::Query +=                    " AND SD1.D1_DTDIGIT BETWEEN '" + dtos (::Param01 + 1) + "' AND '" + dtos (::Param02) + "'"
			::Query +=                    " AND SF4.D_E_L_E_T_ != '*'"
			::Query +=                    " AND SF4.F4_FILIAL   = '" + xfilial ("SF4") + "'"
			::Query +=                    " AND SF4.F4_CODIGO   = SD1.D1_TES"
			::Query +=                    " AND SF4.F4_ESTOQUE  = 'S'"
			::Query +=                  " GROUP BY	D1_COD, D1_LOCAL) AS D1"
			::Query +=           " ON (D1.D1_COD   = SB2.B2_COD"
			::Query +=           " AND D1.D1_LOCAL = SB2.B2_LOCAL)"
			::Query +=      " LEFT JOIN (SELECT D3_COD, D3_LOCAL, "
			::Query +=                        " SUM (CASE WHEN SD3.D3_TM <  '5' THEN SD3.D3_QUANT ELSE 0 END) AS ENT_SD3,"
			::Query +=                        " SUM (CASE WHEN SD3.D3_TM >= '5' THEN SD3.D3_QUANT ELSE 0 END) AS SAI_SD3"
			::Query +=                   " FROM " + RetSQLName ("SD3") + " SD3 "
			::Query +=                  " WHERE SD3.D_E_L_E_T_ != '*'"
			::Query +=                    " AND SD3.D3_FILIAL   = '" + xfilial ("SD3") + "'"
			::Query +=                    " AND SD3.D3_ESTORNO != 'S'"
			::Query +=                    " AND SD3.D3_EMISSAO BETWEEN '" + dtos (::Param01 + 1) + "' AND '" + dtos (::Param02) + "'"
			::Query +=                  " GROUP BY D3_COD, D3_LOCAL) AS D3"
			::Query +=           " ON (D3.D3_COD = SB2.B2_COD"
			::Query +=           " AND D3.D3_LOCAL = SB2.B2_LOCAL)"
			::Query +=      " LEFT JOIN (SELECT D2_COD, D2_LOCAL, SUM (D2_QUANT) AS SAI_SD2"
			::Query +=                   " FROM " + RetSQLName ("SD2") + " SD2, "
			::Query +=                              RetSQLName ("SF4") + " SF4 "
			::Query +=                  " WHERE SD2.D_E_L_E_T_ != '*'
			::Query +=                    " AND SD2.D2_FILIAL   = '" + xfilial ("SD2") + "'"
			::Query +=                    " AND SD2.D2_EMISSAO BETWEEN '" + dtos (::Param01 + 1) + "' AND '" + dtos (::Param02) + "'"
			::Query +=                    " AND SF4.D_E_L_E_T_ != '*'"
			::Query +=                    " AND SF4.F4_FILIAL   = '" + xfilial ("SF4") + "'"
			::Query +=                    " AND SF4.F4_CODIGO   = SD2.D2_TES"
			::Query +=                    " AND SF4.F4_ESTOQUE  = 'S'"
			::Query +=                  " GROUP BY	D2_COD, D2_LOCAL) AS D2"
			::Query +=           " ON (D2.D2_COD = SB2.B2_COD
			::Query +=           " AND D2.D2_LOCAL = SB2.B2_LOCAL)"
			::Query += " WHERE SB1.D_E_L_E_T_ = ''"
			::Query +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			::Query +=   " AND SB1.B1_COD     = SB2.B2_COD"
			::Query +=   " AND SB1.B1_TIPO    NOT IN ('MO', 'AP', 'GF')"
			::Query +=   " AND SB2.D_E_L_E_T_ = ''"
			::Query +=   " AND SB2.B2_FILIAL  = '" + xfilial ("SB2") + "'"
			::Query += " GROUP BY B2_FILIAL, B2_COD, B2_LOCAL, B1_TIPO, B1_DESC, B1_UM"
			::Query += " )"
			::Query += " SELECT ALMOX, TIPO, PRODUTO, DESCRICAO,"
			::Query +=        " QT_ANT_SB9 AS QT_SB9_" + dtos (::Param01) + ","
			::Query +=        " ENT_SD1 + ENT_SD3 AS ENTRADAS,"
			::Query +=        " SAI_SD2 + SAI_SD3 AS SAIDAS,"
			::Query +=        " QT_FIM_SB9 AS QT_SB9_" + dtos (::Param02) + ","
			::Query +=        " QT_ANT_SB9 + ENT_SD1 + ENT_SD3 - SAI_SD2 - SAI_SD3 - QT_FIM_SB9 AS DIFERENCA,"
			::Query +=        " UN_MED"
			::Query += " FROM C"
			::Query += " WHERE ABS (QT_ANT_SB9 + ENT_SD1 + ENT_SD3 - SAI_SD2 - SAI_SD3 - QT_FIM_SB9) > 0.01"
			::Query += " ORDER BY FILIAL, PRODUTO, ALMOX"

		case ::Numero == 5
			::Setores   = 'SAF'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'Conferencia totais gerais safra'
			::Sugestao  = 'Revise a movimentacao.'
			::LiberZZU  = {'051','045'} 
			::ViaBatch  = .F.
			::QuandoUsar = "Apos a emissao das contranotas."
			::Query := ""
			::Query += " WITH "
			::Query += " CARGAS     AS (SELECT FILIAL, SUM (PESO_LIQ) AS QUANT"
			::Query +=                  " FROM VA_VCARGAS_SAFRA"
			::Query +=                 " WHERE FILIAL        BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=                   " AND SAFRA         = '" + ::Param01 + "'"
			::Query +=                   " AND PRODUTO      != '9999'"  // Transf. de uva entre filiais
			::Query +=                   " AND NF_DEVOLUCAO  = ''"
			::Query +=                   " AND AGLUTINACAO  != 'O'"
			::Query +=                   " AND STATUS       != 'C'"
//			::Query +=                   " AND TIPO_FORNEC  != 'PROD_PROPRIA'"
			::Query +=                   " AND TIPO_FORNEC  NOT LIKE '4%'"  // 4-PROD_PROPRIA
			::Query +=                 " GROUP BY FILIAL"
			::Query +=                "),"
			::Query += " NF_ENTRADA AS (SELECT FILIAL, SUM (PESO_LIQ) AS QUANT"
			::Query +=                  " FROM VA_VNOTAS_SAFRA"
			::Query +=                 " WHERE FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=                   " AND SAFRA = '" + ::Param01 + "'"
			::Query +=                   " AND TIPO_NF IN ('E', 'P')"
			::Query +=                 " GROUP BY FILIAL"
			::Query +=                "),"
			::Query += " PRE_NF     AS (SELECT ZZ9_FILIAL AS FILIAL, SUM (ZZ9_QUANT) AS QUANT, SUM (CASE ZZ9_QUANT WHEN 0 THEN 1 ELSE ZZ9_QUANT END * ZZ9_VUNIT) AS VALOR"
			::Query +=                  " FROM " + RetSQLName ("ZZ9") + " ZZ9"
			::Query +=                 " WHERE ZZ9.D_E_L_E_T_ = ''"
			::Query +=                   " AND ZZ9.ZZ9_FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=                   " AND ZZ9.ZZ9_SAFRA  = '" + ::Param01 + "'"
			if ::Param01 == '2016'
				::Query +=               " AND ZZ9.ZZ9_PARCEL BETWEEN 'A' and 'H'"  // Foram feitas varias simulacoes neste ano.
			endif
			::Query +=                 " GROUP BY ZZ9_FILIAL"
			::Query +=                "),"
			::Query += " NF_COMPRA  AS (SELECT FILIAL, SUM (V.PESO_LIQ) AS QUANT, SUM (V.VALOR_TOTAL) AS VALOR"
			::Query +=                  " FROM VA_VNOTAS_SAFRA V"
			::Query +=                 " WHERE V.FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=                   " AND V.SAFRA = '" + ::Param01 + "'"
			::Query +=                   " AND V.TIPO_NF IN ('C', 'V')"
			::Query +=                  " GROUP BY FILIAL"
			::Query +=                "),"
			::Query += " CTA_CORR   AS (SELECT ZI_FILIAL AS FILIAL, SUM (ZI_VALOR) AS VALOR"
			::Query +=                  " FROM " + RetSQLName ("SZI") + " SZI"
			::Query +=                 " WHERE SZI.D_E_L_E_T_ = ''"
			::Query +=                   " AND SZI.ZI_FILIAL  BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=                   " AND SZI.ZI_TM      = '13'"
			::Query +=                   " AND SZI.ZI_DATA    BETWEEN '" + ::Param01 + "' + '0101' AND '" + ::Param01 + "' + '1231'"
			::Query +=                   " AND SZI.ZI_SERIE   = '" + ::Param04 + "'"
			::Query +=                   " AND SZI.ZI_FILORIG = ''"  // PARA NAO PEGAR TRANSFERENCIA DE SALDO ENTRE FILIAIS
			::Query +=                 " GROUP BY SZI.ZI_FILIAL"
			::Query +=                 ")"
			::Query += " SELECT 'TOTAIS FILIAL ' + FILIAIS.FILIAL,"
			::Query +=        " (SELECT SUM (QUANT) FROM CARGAS     A WHERE A.FILIAL = FILIAIS.FILIAL) AS QT_CARGAS,"
			::Query +=        " (SELECT SUM (QUANT) FROM NF_ENTRADA A WHERE A.FILIAL = FILIAIS.FILIAL) AS QT_NF_ENTRADA,"
			::Query +=        " (SELECT SUM (QUANT) FROM PRE_NF     A WHERE A.FILIAL = FILIAIS.FILIAL) AS QT_PRE_NF,"
			::Query +=        " (SELECT SUM (QUANT) FROM NF_COMPRA  A WHERE A.FILIAL = FILIAIS.FILIAL) AS QT_NF_COMPRA,"
			::Query +=        " (SELECT SUM (VALOR) FROM PRE_NF     A WHERE A.FILIAL = FILIAIS.FILIAL) AS VL_PRE_NF,"
			::Query +=        " (SELECT SUM (VALOR) FROM NF_COMPRA  A WHERE A.FILIAL = FILIAIS.FILIAL) AS VL_NF_COMPRA,"
			::Query +=        " (SELECT SUM (VALOR) FROM CTA_CORR   A WHERE A.FILIAL = FILIAIS.FILIAL) AS VL_CTA_CORR"
			::Query += " FROM ("
			::Query +=       " SELECT DISTINCT FILIAL FROM CARGAS     UNION" 
			::Query +=       " SELECT DISTINCT FILIAL FROM NF_ENTRADA UNION"
			::Query +=       " SELECT DISTINCT FILIAL FROM PRE_NF     UNION"
			::Query +=       " SELECT DISTINCT FILIAL FROM NF_COMPRA  UNION"
			::Query +=       " SELECT DISTINCT FILIAL FROM CTA_CORR"
			::Query +=       ") AS FILIAIS"
			::Query += " UNION ALL"
			::Query += " SELECT 'TOTAIS GERAIS',"
			::Query +=        " (SELECT SUM (QUANT) FROM CARGAS    ) AS QT_CARGAS,"
			::Query +=        " (SELECT SUM (QUANT) FROM NF_ENTRADA) AS QT_NF_ENTRADA,"
			::Query +=        " (SELECT SUM (QUANT) FROM PRE_NF    ) AS QT_PRE_NF,"
			::Query +=        " (SELECT SUM (QUANT) FROM NF_COMPRA ) AS QT_NF_COMPRA,"
			::Query +=        " (SELECT SUM (VALOR) FROM PRE_NF    ) AS VL_PRE_NF,"
			::Query +=        " (SELECT SUM (VALOR) FROM NF_COMPRA ) AS VL_NF_COMPRA,"
			::Query +=        " (SELECT SUM (VALOR) FROM CTA_CORR  ) AS VL_CTA_CORR"


		case ::Numero == 6
			::Setores   = 'SAF'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'Cadastro de uva incompleto / inconsistente'
			::Sugestao  = 'Revise cadastro produtos (cor, tintorea, fina/comum, espumante, ...' 
			::Query := ""
			::Query += " SELECT SB1.B1_COD, SB1.B1_DESC, SB1.B1_VARUVA, SB1.B1_VACOR, SB1.B1_VAORGAN, SB1.B1_VAFCUVA, SB1.B1_VAUVAES"
			::Query +=   " FROM " + RetSQLName ("SB1") + " SB1"
			::Query +=  " WHERE SB1.B1_GRUPO = '0400'"
			::Query +=    " AND SB1.D_E_L_E_T_ = ''"
			::Query +=    " AND (SB1.B1_VAORGAN NOT IN ('C', 'E', 'B', 'O')"
			::Query +=     " OR SB1.B1_VARUVA NOT IN ('C', 'F')"
			::Query +=     " OR SB1.B1_VACOR NOT IN ('B','R','T')"
			::Query +=     " OR SB1.B1_VAUVAES NOT IN ('S','N')"
			::Query +=     " OR (SB1.B1_VATTR = 'S' AND SB1.B1_VACOR != 'T')"
			::Query +=     " OR (SB1.B1_VARUVA = 'F' AND SB1.B1_VAUVAES NOT IN ('S', 'N'))"
			::Query +=     " OR (SB1.B1_VARUVA = 'F' AND SB1.B1_VAFCUVA NOT IN ('C', 'F'))"
			::Query +=     ")"


		case ::Numero == 7
			::Setores   = 'SAF'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'Peso bruto/tara da carga inconsistente com a soma dos itens'
			::Sugestao  = 'Revise a carga' 
			::Query := ''
			::Query += " WITH C AS (""
			::Query += "SELECT ZE_FILIAL AS FILIAL,"
			::Query += " SZE.ZE_CARGA AS CARGA,"
			::Query += " SZE.ZE_SERIE AS SERIE,"
			::Query += " SZE.ZE_NFPROD AS NF_PRODUTOR,"
			::Query += " ZE_NOMASSO AS NOME_ASSOC,"
			::Query += " ZE_PESOBRU,"
			::Query += " ZE_PESOTAR,"
			::Query += " (ZE_PESOBRU - ZE_PESOTAR) AS LIQ_CALCULADO,"
			::Query += " SUM(ZF_PESO) AS PESO_ITENS"
			::Query +=   " FROM " + RetSQLName ("SZE") + " SZE,"
			::Query +=              RetSQLName ("SZF") + " SZF"
			::Query +=  " WHERE  SZE.D_E_L_E_T_ = ''"
			::Query +=    " AND ZE_FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=    " AND ZE_NFDEVOL = ''"
			::Query +=    " AND ZE_STATUS != 'C'"  // Cancelada
			::Query +=    " AND ZE_SAFRA   = '" + ::Param01 + "'"
			::Query +=    " AND SZF.D_E_L_E_T_ = ''"
			::Query +=    " AND SZF.ZF_FILIAL = ZE_FILIAL"
			::Query +=    " AND SZF.ZF_SAFRA = ZE_SAFRA"
			::Query +=    " AND SZF.ZF_CARGA = ZE_CARGA"
			::Query +=    " AND NOT (ZF_FILIAL = '07' AND ZF_SAFRA = '2013' AND ZF_CARGA = '4507')"  // FOI FEITA CARGA COMPLEMENTAR (4508)
			::Query += " GROUP BY ZE_SAFRA, ZE_FILIAL, ZE_SERIE, ZE_CARGA, ZE_DATA, ZE_NFPROD, ZE_ASSOC, ZE_NOMASSO, ZE_LOJASSO, ZE_PESOBRU, ZE_PESOTAR"
			::Query += " )"
			::Query += " SELECT C.*"
			::Query +=   " FROM C"
			::Query +=  " WHERE LIQ_CALCULADO != PESO_ITENS"
			::Query +=    " AND PESO_ITENS > 0" // Temos casos de cargas incluidas, mas ainda nao pesadas.


		case ::Numero == 8
			::Setores   = 'SAF'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'Cargas com NF de produtor repetidas'
			::Sugestao  = 'Revise a carga'
			::Query := ""
			::Query += "SELECT ZE_FILIAL AS FILIAL,"
			::Query +=       " ZE_SAFRA AS SAFRA,"
			::Query +=       " ZE_ASSOC AS ASSOCIADO,"
			::Query +=       " ZE_LOJASSO AS LOJA,"
			::Query +=       " ZE_NOMASSO AS NOME,"
			::Query +=       " ZE_NFPROD AS NF_PRODUTOR,"
			::Query +=       " ZE_NFGER AS CONTRANOTA,"
			::Query +=       " ZE_DATA AS DATA"
			::Query +=  " FROM " + RetSQLName ("SZE") + ""
			::Query += " WHERE  D_E_L_E_T_ = ''"
			::Query +=   " AND ZE_AGLUTIN != 'O'"
			::Query +=   " AND ZE_NFGER  != ''"
			::Query +=   " AND ZE_STATUS != 'C'"
			::Query +=   " AND ZE_FILIAL + ZE_SAFRA + ZE_NFPROD + ZE_SNFPROD IN (SELECT ZE_FILIAL + ZE_SAFRA + ZE_NFPROD + ZE_SNFPROD"
			::Query +=                                                           " FROM " + RetSQLName ("SZE") + ""
			::Query +=                                                          " WHERE  D_E_L_E_T_ = ''"
			::Query +=                                                            " AND ZE_FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=                                                            " AND ZE_SAFRA = '" + ::Param01 + "'"
			::Query +=                                                            " AND ZE_AGLUTIN != 'O'"
			::Query +=                                                            " AND ZE_NFGER   != ''"
			::Query +=                                                            " AND ZE_STATUS  != 'C'"
			::Query +=                                                          " GROUP BY ZE_FILIAL, ZE_SAFRA, ZE_ASSOC, ZE_LOJASSO, ZE_NFPROD, ZE_SNFPROD"
			::Query +=                                                         " HAVING COUNT(*) > 1"
			::Query +=                                                         ")"
			::Query += " ORDER BY ZE_FILIAL, ZE_SAFRA, ZE_ASSOC, ZE_LOJASSO, ZE_NFPROD, ZE_SNFPROD, ZE_NFGER"


		case ::Numero == 9
			::Setores   = 'SAF'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'Contranota sem carga de origem'
			::Sugestao  = 'Revise a contranota'
			::Query := ""
			::Query +=   " WITH C AS ("
			::Query += " SELECT SUBSTRING(D1_DTDIGIT ,1 ,4) AS SAFRA"
			::Query += " ,D1_FILIAL AS FILIAL"
			::Query += " ,D1_FORNECE AS COD_ASSOC"
			::Query += " ,D1_LOJA AS LOJA_ASSOC"
			::Query += " ,D1_DOC AS CONTRANOTA"
			::Query += " ,D1_SERIE AS SERIE"
			::Query += " ,D1_DTDIGIT AS DATA"
			::Query += " ,F1_VANFPRO AS NF_PRODUTOR"
			::Query += " ,D1_VAVITIC AS CAD_VITICOLA"
			::Query += " ,D1_QUANT AS PESO_LIQ"
			::Query += " ,D1_DESCRI AS DESCRICAO"
			::Query += " ,SD1.D1_PRM02,SD1.D1_PRM03,SD1.D1_PRM04,SD1.D1_PRM05,SD1.D1_PRM99,SD1.D1_VACLABD"
			::Query +=   " FROM " + RetSQLName ("SD1") + " SD1"
			::Query += " ," + RetSQLName ("SF1") + " SF1"
			::Query +=  " WHERE  SF1.D_E_L_E_T_ = ''"
			::Query +=    " AND SD1.D_E_L_E_T_ = ''"
			::Query +=    " AND D1_FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=    " AND D1_DTDIGIT BETWEEN '" + ::Param01 + "'+'0101' AND '" + ::Param01 + "'+'1231'"
			::Query +=    " AND F1_FILIAL = D1_FILIAL"
			::Query +=    " AND F1_FORNECE = D1_FORNECE"
			::Query +=    " AND F1_LOJA = D1_LOJA"
			::Query +=    " AND F1_DOC = D1_DOC"
			::Query +=    " AND F1_SERIE = D1_SERIE"
			::Query +=    " AND D1_TES in " + FormatIn (ALLTRIM (::Param05), '/')
			::Query +=    " AND D1_SERIE = '" + ::Param04 + "'"
			::Query +=    " AND D1_COD NOT IN ('1180' ,'1182')" // SOMENTE UVAS (COMPRAS DE VINHO DOS ASSOCIADOS, POR EXEMPLO, NAO INTERESSAM AQUI)"
			::Query +=    " AND D1_FORNECE != '001369'" // LIVRAMENTO (PRODUCAO PRORIA)"
			::Query +=    " AND NOT EXISTS (""
			::Query += " SELECT *"
			::Query +=   " FROM " + RetSQLName ("SZE") + " SZE"
			::Query += " ," + RetSQLName ("SZF") + " SZF"
			::Query +=  " WHERE  SZE.D_E_L_E_T_ = ''"
			::Query +=    " AND SZF.D_E_L_E_T_ = ''"
			::Query +=    " AND ZF_CARGA = ZE_CARGA"
			::Query +=    " AND ZF_SAFRA = SUBSTRING(D1_DTDIGIT ,1 ,4)"
			::Query +=    " AND ZE_SAFRA = ZF_SAFRA"
			::Query +=    " AND ZE_FILIAL = ZF_FILIAL"
			::Query +=    " AND ZF_FILIAL = SD1.D1_FILIAL"
			::Query +=    " AND SZE.ZE_ASSOC = SD1.D1_FORNECE"
			::Query +=    " AND SZE.ZE_LOJASSO = SD1.D1_LOJA"
			::Query +=    " AND SZE.ZE_NFGER = D1_DOC"
			::Query +=    " AND SZE.ZE_SERIE = D1_SERIE"
			::Query +=    " AND ZF_PRODUTO = SD1.D1_COD"
			::Query +=    " AND SZF.ZF_GRAU = SD1.D1_GRAU"
			::Query +=    " AND SZF.ZF_PESO = SD1.D1_QUANT"
			::Query +=    " AND SZF.ZF_QTEMBAL = SD1.D1_VAVOLQT"
			::Query +=    " AND SZF.ZF_EMBALAG = SD1.D1_VAVOLES"
			::Query +=    " AND SZF.ZF_CADVITI = SD1.D1_VAVITIC"
			::Query +=    " AND SD1.D1_PRM02 = SZF.ZF_PRM02"
			::Query +=    " AND SD1.D1_PRM03 = SZF.ZF_PRM03"
			::Query +=    " AND SD1.D1_PRM04 = SZF.ZF_PRM04"
			::Query +=    " AND SD1.D1_PRM05 = SZF.ZF_PRM05"
			::Query +=    " AND ((SZF.ZF_CLASABD = '' AND SD1.D1_PRM99 = SZF.ZF_PRM99) OR SD1.D1_VACLABD = SZF.ZF_CLASABD)"
			::Query += " )"
			::Query += " )"
			::Query += " SELECT C.*"
			::Query += " FROM   C"
			::Query += " ORDER BY"
			::Query += " SAFRA"
			::Query += " ,FILIAL"
			::Query += " ,COD_ASSOC"


		case ::Numero == 10
			::Setores   = 'SAF'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'Cad.viticola invalido ou nao recebido (fisicamente)'
			::Sugestao  = 'Revise os cadastros viticolas'
			::Query := ""
			::Query += "SELECT V.SAFRA,"
			::Query += " V.FILIAL,"
			::Query += " V.LOCAL,"
			::Query += " V.CARGA,"
			::Query += " V.CONTRANOTA,"
			::Query += " V.DATA,"
			::Query += " V.NF_PRODUTOR,"
			::Query += " V.ASSOCIADO,"
			::Query += " V.LOJA_ASSOC,"
			::Query += " V.NOME_ASSOC,"
			::Query += " V.CAD_VITIC,"
			::Query += " V.PRODUTO"
			::Query +=  " FROM VA_VCARGAS_SAFRA V"
			::Query += " WHERE V.SAFRA = '" + ::Param01 + "'"
			::Query +=   " AND V.FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=   " AND V.CARGA != '0000'"
			::Query +=   " AND V.NF_DEVOLUCAO = ''"
			::Query +=   " AND V.STATUS NOT IN ('C','D')"
			::Query +=   " AND NOT EXISTS (""
			::Query += " SELECT *"
			::Query += " FROM   " + RetSQLName ("SZ2") + " SZ2"
			::Query +=  " WHERE  SZ2.D_E_L_E_T_ = ''"
			::Query +=    " AND SZ2.Z2_FILIAL   = '  '"
			::Query +=    " AND SZ2.Z2_CADVITI  = V.CAD_VITIC"
			::Query +=    " AND SZ2.Z2_SAFRVIT  = V.SAFRA"
			::Query +=    " AND SZ2.Z2_DRECFIS != ''"  // Se data do recebimento fisico (em papel) estiver vazia, eh por que o associado nao trouxe ainda. 
			::Query += " )"

		case ::Numero == 11
			::Setores   = 'SAF'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'NF entrada uva sem classificacao'
			::Sugestao  = 'Revise cargas e contranotas'
			::QuandoUsar = "Antes de gerar as pre-notas de compra."
			::Query := ""
			::Query += "SELECT D1_FILIAL AS FILIAL,"
			::Query += " D1_DOC AS CONTRANOTA,"
			::Query += " dbo.VA_DTOC (D1_EMISSAO) AS EMISSAO,"
			::Query += " SZF.ZF_CARGA,"
			::Query += " D1_FORNECE AS ASSOC,"
			::Query += " D1_LOJA AS LOJA,"
			::Query += " RTRIM(A2_NOME) AS NOME_ASSOCIADO,"
			::Query += " SD1.D1_QUANT AS PESO,"
			::Query += " SD1.D1_COD AS PRODUTO,"
			::Query += " RTRIM(SB1.B1_DESC) AS DESCRICAO,"
			::Query += " SD1.D1_GRAU AS GRAU,"
			::Query += " SD1.D1_PRM99 AS CLASSE"
			::Query +=   " FROM " + RetSQLName ("SB1") + " SB1,"
			::Query += " " + RetSQLName ("SA2") + " SA2,"
			::Query += " " + RetSQLName ("SD1") + " SD1"
			::Query += " LEFT JOIN " + RetSQLName ("SZE") + " SZE"
			::Query += " JOIN " + RetSQLName ("SZF") + " SZF"
			::Query += " ON  (""
			::Query += " SZF.D_E_L_E_T_ = ''"
			::Query +=    " AND SZF.ZF_FILIAL = SZE.ZE_FILIAL"
			::Query +=    " AND SZF.ZF_SAFRA = SZE.ZE_SAFRA"
			::Query +=    " AND SZF.ZF_CARGA = SZE.ZE_CARGA"
			::Query += " )"
			::Query += " ON  (""
			::Query += " SZE.D_E_L_E_T_ = ''"
			::Query +=    " AND SZE.ZE_FILIAL = SD1.D1_FILIAL"
			::Query +=    " AND SZE.ZE_SAFRA = '" + ::Param01 + "'"
			::Query +=    " AND SZE.ZE_ASSOC = SD1.D1_FORNECE"
			::Query +=    " AND SZE.ZE_LOJASSO = SD1.D1_LOJA"
			::Query +=    " AND SZE.ZE_NFGER = SD1.D1_DOC"
			::Query +=    " AND SZE.ZE_SERIE = SD1.D1_SERIE"
			::Query += " )"
			::Query +=  " WHERE  SD1.D_E_L_E_T_ = ''"
			::Query +=    " AND SD1.D1_FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=    " AND D1_TES in " + FormatIn (alltrim (::Param05), '/')
			::Query +=    " AND D1_TP = 'MP'"  // COD NOT IN ('1180', '1182') -- SOMENTE UVAS (COMPRAS DE VINHO DOS ASSOCIADOS, POR EXEMPLO, NAO INTERESSAM AQUI)"
			::Query +=    " AND SUBSTRING(SD1.D1_EMISSAO, 1, 4) = '" + ::Param01 + "'"
			::Query +=    " AND ((D1_VACONDU = 'E' AND D1_PRM99 = '') OR (D1_VACONDU = 'L' AND D1_VACLABD = ''))"
			::Query +=    " AND SB1.D_E_L_E_T_ = ''"
			::Query +=    " AND SB1.B1_FILIAL = '  '"
			::Query +=    " AND SB1.B1_COD = SD1.D1_COD"
			::Query +=    " AND SB1.B1_VARUVA = 'F'"
			::Query +=    " AND SB1.B1_VAFCUVA != 'C'"  // UVA FINA CLASSIFICADA COMO COMUM NAO INTERESSA AQUI"
			::Query +=    " AND SA2.D_E_L_E_T_ = ''"
			::Query +=    " AND SA2.A2_FILIAL = '  '"
			::Query +=    " AND SA2.A2_COD = SD1.D1_FORNECE"
			::Query +=    " AND SA2.A2_LOJA = SD1.D1_LOJA"
			::Query +=    " AND D1_FORNECE != '001369'" // PRODUCAO PROPRIA LIVRAMENTO"
			::Query += " ORDER BY"
			::Query += " D1_FILIAL,"
			::Query += " SD1.D1_EMISSAO,"
			::Query += " D1_DOC"


		case ::Numero == 12
			::Setores   = 'SAF'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'Pre-NF com diferentes precos p/mesmo produto/grau/classe/conducao'
			::Sugestao  = 'Revise pre-notas de compra de safra'
			::LiberZZU  = {'051','045'} 
			::ViaBatch  = .F.
			::QuandoUsar = "Apos gerar as pre-notas e antes de gerar as notas de compra."
			::Query := ""
			::Query += "SELECT ZZ9.ZZ9_FILIAL,ZZ9.ZZ9_SAFRA,ZZ9.ZZ9_TIPONF,ZZ9.ZZ9_FORNEC,ZZ9.ZZ9_LOJA,"
			::Query +=       " SA2.A2_NOME,ZZ9.ZZ9_PRODUT,SB1.B1_DESC,ZZ9.ZZ9_GRAU,ZZ9.ZZ9_CLASSE,ZZ9.ZZ9_CONDUC,ZZ9.ZZ9_VUNIT"
			::Query +=   " FROM " + RetSQLName ("ZZ9") + " ZZ9, " + RetSQLName ("SA2") + " SA2, " + RetSQLName ("SB1") + " SB1,"
			::Query += " ("
			::Query += " SELECT A.ZZ9_SAFRA,"  // NAO PEGO FILIAL DA SUBQUERY POR QUE QUERO O MESMO PRECO EM QUALQUER FILIAL.
			::Query += " A.ZZ9_TIPONF,"
			::Query += " A.ZZ9_PRODUT,"
			::Query += " A.ZZ9_GRAU,"
			::Query += " A.ZZ9_CLASSE,"
			::Query += " A.ZZ9_CONDUC,"
			::Query += " COUNT(DISTINCT ZZ9_VUNIT) AS QUANTAS"
			::Query +=   " FROM " + RetSQLName ("ZZ9") + " A"
			::Query +=  " WHERE  A.D_E_L_E_T_ = ''"
			::Query +=    " AND A.ZZ9_SAFRA = '" + ::Param01 + "'"
			::Query +=    " AND A.ZZ9_TIPONF != 'C'"  // NOTAS DE COMPLEMENTO SEMPRE TEM VALORES DIFERENTES
			::Query += " GROUP BY"
			::Query += " A.ZZ9_SAFRA,"
			::Query += " A.ZZ9_TIPONF,"
			::Query += " A.ZZ9_PRODUT,"
			::Query += " A.ZZ9_GRAU,"
			::Query += " A.ZZ9_CLASSE,"
			::Query += " A.ZZ9_CONDUC"
			::Query += " HAVING COUNT(DISTINCT ZZ9_VUNIT) > 1"
			::Query += " ) AS DUPLIC"
			::Query +=  " WHERE  ZZ9.D_E_L_E_T_ = ''"
			::Query +=    " AND ZZ9.ZZ9_FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=    " AND ZZ9.ZZ9_SAFRA = DUPLIC.ZZ9_SAFRA"
			::Query +=    " AND ZZ9.ZZ9_TIPONF = DUPLIC.ZZ9_TIPONF"
			::Query +=    " AND ZZ9.ZZ9_PRODUT = DUPLIC.ZZ9_PRODUT"
			::Query +=    " AND ZZ9.ZZ9_GRAU = DUPLIC.ZZ9_GRAU"
			::Query +=    " AND ZZ9.ZZ9_CLASSE = DUPLIC.ZZ9_CLASSE"
			::Query +=    " AND ZZ9.ZZ9_CONDUC = DUPLIC.ZZ9_CONDUC"
			::Query +=    " AND SA2.D_E_L_E_T_ = ''"
			::Query +=    " AND SA2.A2_FILIAL = '  '"
			::Query +=    " AND SA2.A2_COD = ZZ9.ZZ9_FORNEC"
			::Query +=    " AND SA2.A2_LOJA = ZZ9.ZZ9_LOJA"
			::Query +=    " AND SB1.D_E_L_E_T_ = ''"
			::Query +=    " AND SB1.B1_FILIAL = '  '"
			::Query +=    " AND SB1.B1_COD = ZZ9.ZZ9_PRODUT"
			::Query += " ORDER BY"
			::Query += " ZZ9.ZZ9_TIPONF,"
			::Query += " ZZ9.ZZ9_PRODUT,"
			::Query += " ZZ9.ZZ9_GRAU,"
			::Query += " ZZ9.ZZ9_CLASSE,"
			::Query += " ZZ9.ZZ9_CONDUC"


		case ::Numero == 13
			::Setores   = 'SAF/PCP'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'Carga sem contranota'
			::Sugestao  = 'Revise cargas e notas de entrada'
			::QuandoUsar = "Antes de gerar as pre-notas de compra."
			::Query := ""
			::Query += "SELECT ZE_FILIAL AS FILIAL,"
			::Query += " ZE_SAFRA AS SAFRA,"
			::Query += " ZE_CARGA AS CARGA,"
			::Query += " ZE_DATA AS DATA,"
			::Query += " ZE_LOCAL AS LOCAL,"
			::Query += " ZE_ASSOC AS ASSOCIADO,"
			::Query += " ZE_NOMASSO AS NOME_ASSOC, SZE.ZE_NFGER, ZE_VAUSER"
			::Query +=   " FROM " + RetSQLName ("SZE") + " SZE"
			::Query +=  " WHERE SZE.D_E_L_E_T_ = ''"
			::Query +=    " AND ZE_FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=    " AND ZE_SAFRA = '" + ::Param01 + "'"
			::Query +=    " AND ZE_NFGER = ''"
//			::Query +=    " AND ZE_COOP IN ('000021', '001369')"
			::Query +=    " AND ZE_AGLUTIN != 'O'"  // Origem de aglutinacao
			::Query +=    " AND ZE_STATUS  != 'C'"  // Cancelada
			::Query +=    " AND ZE_STATUS  != 'D'"  // Direcionada para outra filial
			::Query += " ORDER BY ZE_FILIAL, ZE_SAFRA, ZE_CARGA"
		

		case ::Numero == 14
			::Setores   = 'SAF'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'Contranota citada na carga nao existe ou tem dados diferentes'
			::Sugestao  = 'Revise cargas e notas de entrada'
			::QuandoUsar = "Antes de gerar as pre-notas de compra."
			::Query := ""
			::Query += " WITH C AS (""
			::Query += " SELECT ZE_SAFRA AS SAFRA,ZE_FILIAL AS FILIAL,SZE.ZE_COOP AS COOP,SZE.ZE_LOJCOOP AS LOJA_COOP,SZE.ZE_LOCAL AS LOCAL,SZE.ZE_CARGA AS CARGA"
			::Query +=       " ,ZE_NFGER AS CONTRANOTA,SZE.ZE_DATA AS DATA,SZE.ZE_NFPROD AS NF_PRODUTOR,ZF_CADVITI AS CAD_VITICOLA,ZE_ASSOC AS COD_ASSOC"
			::Query +=       " ,ZE_NOMASSO AS NOME_ASSOC,ZE_LOJASSO AS LOJA_ASSOC,SZF.ZF_PESO AS PESO_LIQ,SZF.ZF_PRODUTO AS PRODUTO"
			::Query +=       " ,B1_DESC AS VARIEDADE,SZF.ZF_GRAU AS GRAU,SZF.ZF_PRM02,SZF.ZF_PRM03,SZF.ZF_PRM04,SZF.ZF_PRM05,SZF.ZF_PRM99"
			::Query +=   " FROM " + RetSQLName ("SZF") + " SZF, "
			::Query +=              RetSQLName ("SZE") + " SZE, "
			::Query +=              RetSQLName ("SB1") + " SB1"
			::Query +=  " WHERE  SZE.D_E_L_E_T_ = ''"
			::Query +=    " AND ZE_FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=    " AND ZE_SAFRA = '" + ::Param01 + "'"
			::Query +=    " AND SZF.D_E_L_E_T_ = ''"
			::Query +=    " AND ZF_FILIAL = ZE_FILIAL"
			::Query +=    " AND ZF_SAFRA = ZE_SAFRA"
			::Query +=    " AND ZF_CARGA = ZE_CARGA"
			::Query +=    " AND SB1.D_E_L_E_T_ = ''"
			::Query +=    " AND B1_FILIAL = '  '"
			::Query +=    " AND B1_COD = ZF_PRODUTO"
			::Query +=    " AND ZE_COOP IN ('000021','001369')"
			::Query +=    " AND ZE_AGLUTIN != 'O'"
			::Query +=    " AND SZE.ZE_NFGER != ''"
			::Query +=    " AND NOT EXISTS (""
			::Query += " SELECT *"
			::Query +=   " FROM " + RetSQLName ("SD1") + " SD1"
			::Query +=  " WHERE  SD1.D_E_L_E_T_ = ''"
			::Query +=    " AND SD1.D1_FILIAL = SZF.ZF_FILIAL"
			::Query +=    " AND SD1.D1_FORNECE = SZE.ZE_ASSOC"
			::Query +=    " AND SD1.D1_LOJA = SZE.ZE_LOJASSO"
			::Query +=    " AND D1_DOC = SZE.ZE_NFGER"
			::Query +=    " AND D1_SERIE = '" + ::Param04 + "'"
			::Query +=    " AND SD1.D1_FORMUL = 'S'"
			::Query +=    " AND D1_COD = SZF.ZF_PRODUTO"
			::Query +=    " AND SD1.D1_GRAU = SZF.ZF_GRAU"
			::Query +=    " AND SD1.D1_QUANT = SZF.ZF_PESO"
			::Query +=    " AND SD1.D1_VAVOLQT = SZF.ZF_QTEMBAL"
			::Query +=    " AND SD1.D1_VAVOLES = SZF.ZF_EMBALAG"
			::Query +=    " AND SD1.D1_VAVITIC = SZF.ZF_CADVITI"
			::Query +=    " AND SD1.D1_PRM02 = SZF.ZF_PRM02"
			::Query +=    " AND SD1.D1_PRM03 = SZF.ZF_PRM03"
			::Query +=    " AND SD1.D1_PRM04 = SZF.ZF_PRM04"
			::Query +=    " AND SD1.D1_PRM05 = SZF.ZF_PRM05"
			::Query +=    " AND ((SZF.ZF_CLASABD = '' AND SD1.D1_PRM99 = SZF.ZF_PRM99) OR SD1.D1_VACLABD = SZF.ZF_CLASABD)"
			::Query += " )"
			::Query += " )"
			::Query += " SELECT C.*"
			::Query += " FROM   C"
			::Query += " ORDER BY SAFRA,FILIAL,COOP,COD_ASSOC,CARGA,CAD_VITICOLA"


		case ::Numero == 15
			::Setores   = 'SAF'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'NF de entrada sem pre-nota de compra'
			::Sugestao  = 'Revise cargas e notas de entrada'
			::ViaBatch  = .F.
			::QuandoUsar = "Antes de gerar as notas de compra."
			::Query := ""
			::Query += "SELECT V.FILIAL,"
			::Query += " V.DOC AS CONTRANOTA,"
			::Query += " V.DATA AS EMISSAO,"
			::Query += " V.ASSOCIADO,"
			::Query += " V.LOJA_ASSOC,"
			::Query += " V.PESO_LIQ,"
			::Query += " V.PRODUTO,"
			::Query += " V.DESCRICAO,"
			::Query += " V.GRAU,"
			::Query += " V.CLAS_FINAL, V.CLAS_ABD"
			::Query += " FROM   VA_VNOTAS_SAFRA V"
			::Query +=  " WHERE  V.FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=    " AND V.SAFRA = '" + ::Param01 + "'"
			::Query +=    " AND V.TIPO_NF = 'E'"
			::Query +=    " AND NOT EXISTS (""
			::Query += " SELECT *"
			::Query +=   " FROM " + RetSQLName ("ZZ9") + " ZZ9"
			::Query +=  " WHERE  ZZ9.D_E_L_E_T_ = ''"
			::Query +=    " AND ZZ9.ZZ9_FILIAL = V.FILIAL"
			::Query +=    " AND ZZ9.ZZ9_SAFRA = V.SAFRA"
			::Query +=    " AND ZZ9.ZZ9_FORNEC = V.ASSOCIADO"
			::Query +=    " AND ZZ9.ZZ9_LOJA = V.LOJA_ASSOC"
			::Query +=    " AND ZZ9.ZZ9_NFENTR = V.DOC"
			::Query +=    " AND ZZ9.ZZ9_PRODUT = V.PRODUTO"
			::Query +=    " AND ZZ9.ZZ9_GRAU = V.GRAU"
			::Query +=    " AND (""
			::Query += " ZZ9.ZZ9_CLASSE = V.CLAS_FINAL"
			::Query += " OR (""
			::Query += " ZZ9_SAFRA = '2012'"  // CLASSIFICACAO FOI DESCONSIDERADA EM 2012 PARA ALGUMAS VARIEDADES NAS FILIAIS DA SERRA.
			::Query +=    " AND ZZ9_FILIAL IN ('01', '07', '09', '10', '11', '12')"
			::Query +=    " AND ZZ9_PRODUT IN ('9932','9911','9912','9913','9910')"
			::Query +=    " AND ZZ9_CLASSE = 'B'"
			::Query +=    " AND ZZ9_OBS != ''"  // SE FOI ALTERADO, QUERO ALGUMA EXPLICACAO"
			::Query += " )"
			::Query += " OR (""
			::Query += " ZZ9_SAFRA = '2012'"  // ALGUMAS UVAS DA 'CERROS VERDES' FORAM RECLASSIFICADAS.
			::Query +=    " AND ZZ9_FILIAL = '03'"
			::Query +=    " AND ZZ9_FORNEC + ZZ9_LOJA IN ('00226601', '00226901', '00325601')"
			::Query +=    " AND ZZ9_PRODUT IN ('9939', '9956', '9908')"
			::Query +=    " AND ZZ9_OBS != ''"
			::Query += " )"
			::Query += " OR (""
			::Query += " ZZ9_SAFRA = '2012'"  // ALGUMAS UVAS DO FLAVIO FORAM RECLASSIFICADAS.
			::Query +=    " AND ZZ9_FILIAL = '03'"
			::Query +=    " AND ZZ9_FORNEC + ZZ9_LOJA IN ('00325601')"
			::Query +=    " AND ZZ9_PRODUT IN ('9950','9970')"
			::Query +=    " AND ZZ9_OBS != ''"
			::Query += " )"
			::Query += " )"
			::Query += " )"
			::Query += " ORDER BY"
			::Query += " V.FILIAL,"
			::Query += " V.DATA, V.DOC"

		case ::Numero == 16
			::Setores   = 'SAF'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'Pre-nota de compra sem NF de entrada'
			::Sugestao  = 'Revise notas de entrada e pre-notas'
			::ViaBatch  = .F.
			::QuandoUsar = "Antes de gerar as notas de compra."
			::Query := ""
			::Query += "SELECT ZZ9_FILIAL AS FILIAL,ZZ9_PRE_NF AS PRE_NF,ZZ9_FORNEC AS ASSOC,ZZ9_LOJA AS LOJA,ZZ9_QUANT AS PESO,"
			::Query +=       " ZZ9_NFENTR AS NF_ENTRADA,ZZ9.ZZ9_NFCOMP AS NF_COMPRA,ZZ9_PRODUT AS PRODUTO,ZZ9_GRAU AS GRAU,"
			::Query +=       " ZZ9_CLASSE AS CLASSE, ZZ9.ZZ9_PREORI,ZZ9_OBS AS OBS_PRE_NF"
			::Query +=   " FROM " + RetSQLName ("ZZ9") + " ZZ9"
			::Query +=  " WHERE  D_E_L_E_T_ = ''"
			::Query +=    " AND ZZ9_FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=    " AND ZZ9_SAFRA = '" + ::Param01 + "'"
			::Query +=    " AND NOT EXISTS (""
			::Query += " SELECT *"
			::Query += " FROM   VA_VNOTAS_SAFRA V"
			::Query +=  " WHERE  V.SAFRA = ZZ9.ZZ9_SAFRA"
			::Query +=    " AND V.TIPO_NF = 'E'"
			::Query +=    " AND V.FILIAL = ZZ9.ZZ9_FILIAL"
			::Query +=    " AND V.DOC = ZZ9.ZZ9_NFENTR"
			::Query +=    " AND V.ASSOCIADO = ZZ9.ZZ9_FORNEC"
			::Query +=    " AND V.LOJA_ASSOC = ZZ9.ZZ9_LOJA"
			::Query +=    " AND V.PRODUTO = ZZ9.ZZ9_PRODUT"
			::Query +=    " AND V.GRAU = ZZ9.ZZ9_GRAU"
			::Query +=    " AND V.CLAS_FINAL = ZZ9.ZZ9_CLASSE"
			::Query += " )"
			::Query += " ORDER BY"
			::Query += " ZZ9_FILIAL,"
			::Query += " ZZ9_PRE_NF"

		case ::Numero == 17
			::Setores   = 'FIS'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'NF-e nao autorizada junto a SEFAZ'
			::Sugestao  = 'Revise notas de safra.'
			::QuandoUsar = "Apos gerar as contranotas de compra ou de complemento de preco."
			::Query := ""
			::Query += "SELECT V.TIPO_NF,V.FILIAL,V.DOC,V.SERIE,V.DATA,V.ASSOCIADO,V.LOJA_ASSOC,V.NOME_ASSOC"
			::Query += " FROM   VA_VNOTAS_SAFRA V"
			::Query +=  " WHERE  V.SAFRA = '" + ::Param01 + "'"
			::Query +=    " AND V.FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=    " AND V.SERIE = '" + ::Param04 + "'"
			::Query +=    " AND V.SAFRA >= '2012'"  // ANTES O CAMPO NAO EXISTIA NA TABELA SF1"
			::Query +=    " AND NOT (V.SAFRA = '2012' AND V.TIPO_NF IN ('E', 'P'))"  // ANTES O CAMPO NAO EXISTIA NA TABELA SF1"
			::Query +=    " AND NOT EXISTS (""
			::Query += " SELECT F1_DAUTNFE"
			::Query +=   " FROM " + RetSQLName ("SF1") + " SF1"
			::Query +=  " WHERE  SF1.F1_FILIAL = V.FILIAL"
			::Query +=    " AND SF1.F1_DOC = V.DOC"
			::Query +=    " AND SF1.F1_SERIE = V.SERIE"
			::Query +=    " AND SF1.F1_FORNECE = V.ASSOCIADO"
			::Query +=    " AND SF1.F1_LOJA = V.LOJA_ASSOC"
			::Query +=    " AND SF1.F1_DAUTNFE != ''"
			::Query += " )"
			::Query += " ORDER BY"
			::Query += " V.FILIAL,"
			::Query += " V.DOC"

		case ::Numero == 18
			::Setores   = 'SAF'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'Diferenca entre NF de entrada e de compra'
			::Sugestao  = 'Revise notas de safra. Pode ter faltado contranota para algum associado.'
			::QuandoUsar = "Apos gerar as contranotas de compra."
			::ViaBatch   = .F.
			::Query := ""
			::Query += " WITH E AS (SELECT FILIAL,ASSOCIADO,LOJA_ASSOC,PRODUTO,GRAU,SUM(PESO_LIQ) AS PESO_LIQ"
			::Query += " FROM   VA_VNOTAS_SAFRA"
			::Query +=  " WHERE SAFRA = '" + ::Param01 + "'"
			::Query +=    " AND FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=    " AND TIPO_NF = 'E'"
			::Query += " GROUP BY FILIAL,ASSOCIADO,LOJA_ASSOC,PRODUTO,GRAU)"
			::Query += " ,"
			::Query += " C AS (SELECT FILIAL,ASSOCIADO,LOJA_ASSOC,PRODUTO,GRAU,SUM(PESO_LIQ) AS PESO_LIQ"
			::Query += " FROM   VA_VNOTAS_SAFRA"
			::Query +=  " WHERE SAFRA = '" + ::Param01 + "'"
			::Query +=    " AND FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=    " AND TIPO_NF = 'C'"
			::Query += " GROUP BY FILIAL,ASSOCIADO,LOJA_ASSOC,PRODUTO,GRAU)"
			::Query += " SELECT *"
			::Query += " FROM E LEFT JOIN C"
			::Query +=    " ON (C.FILIAL = E.FILIAL"
			::Query +=    " AND C.ASSOCIADO = E.ASSOCIADO"
			::Query +=    " AND C.LOJA_ASSOC = E.LOJA_ASSOC"
			::Query +=    " AND C.PRODUTO = E.PRODUTO"
			::Query +=    " AND C.GRAU = E.GRAU)"
			::Query +=  " WHERE ISNULL (C.PESO_LIQ, 0) != E.PESO_LIQ"

		case ::Numero == 19
			::Setores   = 'SAF'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'Dados adicionais inconsistentes na contranota'
			::Sugestao  = 'Revise notas'
			::QuandoUsar = "Apos gerar as contranotas de compra ou de complemento de preco."
			::Query := ""
			::Query += "SELECT ZE_FILIAL,ZE_SAFRA,ZE_CARGA,ZE_ASSOC,ZE_NOMASSO,ZE_NFGER,ZE_NFPROD AS NF_PRODUTOR_CARGA,"
			::Query +=       " F1_VANFPRO AS NF_PRODUTOR_CONTRANOTA,ZF_CADVITI AS CAD_VITIC_CARGA,D1_VAVITIC AS CAD_VITIC_CONTRANOTA,"
			::Query +=       " ZE_PLACA AS PLACA_CARGA, F1_VAPLVEI AS PLACA_CONTRANOTA"
			::Query +=  " FROM " + RetSQLName ("SZE") + " SZE,"
			::Query +=             RetSQLName ("SZF") + " SZF,"
			::Query +=             RetSQLName ("SD1") + " SD1,"
			::Query +=             RetSQLName ("SF1") + " SF1"
			::Query +=  " WHERE  SZE.D_E_L_E_T_ = ''"
			::Query +=    " AND SZF.D_E_L_E_T_ = ''"
			::Query +=    " AND SF1.D_E_L_E_T_ = ''"
			::Query +=    " AND SD1.D_E_L_E_T_ = ''"
			::Query +=    " AND ZE_FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=    " AND ZE_SAFRA = '" + ::Param01 + "'"
			::Query +=    " AND ZE_NFDEVOL = ''"
			::Query +=    " AND F1_FILIAL = ZE_FILIAL"
			::Query +=    " AND F1_FORNECE = ZE_ASSOC"
			::Query +=    " AND F1_LOJA = ZE_LOJASSO"
			::Query +=    " AND F1_DOC = ZE_NFGER"
			::Query +=    " AND F1_SERIE = ZE_SERIE"
			::Query +=    " AND ZF_FILIAL = ZE_FILIAL"
			::Query +=    " AND SZF.ZF_SAFRA = SZE.ZE_SAFRA"
			::Query +=    " AND ZF_CARGA = ZE_CARGA"
			::Query +=    " AND SD1.D1_FILIAL = F1_FILIAL"
			::Query +=    " AND D1_DOC = SF1.F1_DOC"
			::Query +=    " AND SD1.D1_SERIE = SF1.F1_SERIE"
			::Query +=    " AND SD1.D1_FORNECE = SF1.F1_FORNECE"
			::Query +=    " AND SD1.D1_LOJA = SF1.F1_LOJA"
			::Query +=    " AND SD1.D1_VAVITIC = SZF.ZF_CADVITI"
			::Query +=    " AND D1_COD = SZF.ZF_PRODUTO"
			::Query +=    " AND SD1.D1_GRAU = SZF.ZF_GRAU"
			::Query +=    " AND (""
			::Query += " F1_VANFPRO != ZE_NFPROD"
			::Query += " )"

		case ::Numero == 20
			::Ativa     = .F.  // Em 2020, por exemplo, algumas classificacoes (mat.estranho, maturacao, ...) nao foram consideradas.
			::Setores   = 'SAF'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'Cargas com inconsistencia entre classificacoes da uva fina'
			::Sugestao  = 'Revise notas'
			::ViaBatch  = .F.
			::QuandoUsar = "Antes de gerar as pre-notas de compra."
			::Query := ""
			::Query += " WITH C AS ("
			::Query += "SELECT ZE_SAFRA AS SAFRA,ZE_FILIAL AS FILIAL,SZE.ZE_COOP AS COOP,SZE.ZE_LOJCOOP AS LOJA_COOP,SZE.ZE_LOCAL AS LOCAL,"
			::Query +=       " SZE.ZE_CARGA AS CARGA,ZE_NFGER AS CONTRANOTA,SZE.ZE_DATA AS DATA,SZE.ZE_NFPROD AS NF_PRODUTOR,ZE_ASSOC AS COD_ASSOC,"
			::Query +=       " ZE_NOMASSO AS NOME_ASSOC,ZE_LOJASSO AS LOJA_ASSOC,SZF.ZF_PESO AS PESO_LIQ,SZF.ZF_PRODUTO AS VARIEDADE,"
			::Query +=       " B1_DESC AS DESCRICAO,SZF.ZF_GRAU AS GRAU,SZF.ZF_PRM02,SZF.ZF_PRM03,SZF.ZF_PRM04,SZF.ZF_PRM05,SZF.ZF_PRM99"
			::Query +=  " FROM " + RetSQLName ("SZF") + " SZF,"
			::Query +=             RetSQLName ("SZE") + " SZE,"
			::Query +=             RetSQLName ("SB1") + " SB1"
			::Query +=  " WHERE  SZE.D_E_L_E_T_ = ''"
			::Query +=    " AND ZE_FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=    " AND ZE_SAFRA = '" + ::Param01 + "'"
			::Query +=    " AND ZE_NFDEVOL = ''"
			::Query +=    " AND NOT (SZE.ZE_FILIAL = '03' AND SZE.ZE_SAFRA = '2013' AND SZE.ZE_COOP = '999999' AND SZE.ZE_ASSOC = '001369')" // PRODUCAO PROPRIA LIVRAMENTO 2013
			::Query +=    " AND SZF.D_E_L_E_T_ = ''"
			::Query +=    " AND ZF_FILIAL = ZE_FILIAL"
			::Query +=    " AND ZF_SAFRA = ZE_SAFRA"
			::Query +=    " AND ZF_CARGA = ZE_CARGA"
			::Query +=    " AND SB1.D_E_L_E_T_ = ''"
			::Query +=    " AND B1_FILIAL = '  '"
			::Query +=    " AND B1_COD = ZF_PRODUTO"
			::Query +=    " AND (""
			::Query += " dbo.VA_PESO_CLAS_UVA (ZF_PRM99) > dbo.VA_PESO_CLAS_UVA (ZF_PRM02)"
			::Query += " OR dbo.VA_PESO_CLAS_UVA (ZF_PRM99) > dbo.VA_PESO_CLAS_UVA (ZF_PRM03)"
			::Query += " OR dbo.VA_PESO_CLAS_UVA (ZF_PRM99) > dbo.VA_PESO_CLAS_UVA (ZF_PRM04)"
			::Query += " OR dbo.VA_PESO_CLAS_UVA (ZF_PRM99) > dbo.VA_PESO_CLAS_UVA (ZF_PRM05)"
			::Query += " )"
			::Query += " )"
			::Query += " SELECT C.*"
			::Query += " FROM   C"
			::Query += " ORDER BY SAFRA,FILIAL,CARGA"


		case ::Numero == 21
			::Setores    = 'CUS'
			::Descricao  = 'OP produzida sem nenhum consumo'
			::Sugestao   = 'Revise OP'
			::ViaBatch   = .F.
			::Query := ""
			::Query += "SELECT D3_FILIAL AS FILIAL, D3_OP AS OP, D3_COD AS PROD_FINAL, SUM (D3_QUANT) AS QT_PRODUZIDA,"
			::Query +=       " SUM (D3_PERDA) AS QT_PERDA, dbo.VA_DTOC (MAX (D3_EMISSAO)) AS ULTIMO_MOVTO"
			::Query +=  " FROM " + RetSQLName ("SD3") + " SD3 "
			::Query += " WHERE D_E_L_E_T_ = ''"
			::Query +=   " AND D3_FILIAL  = '" + xfilial ("SD3") + "'"
			::Query +=   " AND D3_EMISSAO BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query +=   " AND D3_CF      LIKE 'PR%'"
			::Query +=   " AND D3_OP      != ''"
			::Query +=   " AND NOT EXISTS (SELECT *"
			::Query +=                     " FROM " + RetSQLName ("SD3") + " CONSUMO "
			::Query +=                    " WHERE CONSUMO.D_E_L_E_T_ = ''"
			::Query +=                      " AND CONSUMO.D3_FILIAL  = SD3.D3_FILIAL"
			::Query +=                      " AND CONSUMO.D3_OP      = SD3.D3_OP"
			::Query +=                      " AND CONSUMO.D3_CF      LIKE 'RE%')"
			::Query += " GROUP BY SD3.D3_FILIAL, SD3.D3_OP, SD3.D3_COD"
			::Query += " ORDER BY SD3.D3_FILIAL, SD3.D3_OP"


		case ::Numero == 22
			::Setores    = 'SAF'
			::GrupoPerg  = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao  = 'Variedade/grau sem preco de compra definido'
			::Sugestao   = 'Revise cadastro de precos de uvas para safra'
			::LiberZZU   = {'051','045'} 
			::ViaBatch   = .F.
			::QuandoUsar = "Antes de gerar as pre-notas de compra."
			::Query := ""
			::Query += "SELECT DISTINCT PRODUTO, DESCRICAO, GRAU"
			::Query +=  " FROM   VA_VNOTAS_SAFRA V"
			::Query += " WHERE FILIAL BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query +=   " AND SAFRA   = '" + ::Param01 + "'"
			::Query +=   " AND TIPO_NF = 'E'"
			::Query +=   " AND NOT EXISTS (SELECT *"
			::Query +=                     " FROM " + RetSQLName ("SZ1") + " SZ1 "
			::Query +=                    " WHERE D_E_L_E_T_ = ''"
			::Query +=                      " AND Z1_FILIAL  = '" + xfilial ("SZ1") + "'"
			::Query +=                      " AND Z1_TABELA  = '0000' + SUBSTRING (V.SAFRA, 3, 2)"  // Geralmente usa-se 0000 + digito final da safra
			::Query +=                      " AND Z1_CODPRD  = V.PRODUTO"
			::Query +=                      " AND Z1_PRCCOM  > 0"
			::Query +=                      " AND Z1_GRAU    = V.GRAU)"
			::Query += " ORDER BY"
			::Query += " PRODUTO, GRAU"


		case ::Numero == 23
			::Setores    = 'SAF'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao  = 'Variacao preco convencional/bordadura/conversao/organica fora do padrao'
			::Sugestao   = 'Revise cadastro de precos de uvas para safra'
			::LiberZZU  = {'051'} 
			::ViaBatch  = .F.
			::QuandoUsar = "Antes de gerar as pre-notas de compra."
			::Query := ""
			::Query += "WITH C AS ("
			::Query += " SELECT FAM.*,"
			::Query +=        " BORD.Z1_PRCCOM AS PRECO_BORDADURA,"
			::Query +=        " ROUND ((BORD.Z1_PRCCOM / PRECO_BASE - 1) * 100, 0) AS VAR_BORD,"
			::Query +=        " CONV.Z1_PRCCOM AS PRECO_CONVERSAO,"
			::Query +=        " ROUND ((CONV.Z1_PRCCOM / PRECO_BASE - 1) * 100, 0) AS VAR_CONV,"
			::Query +=        " ORGA.Z1_PRCCOM AS PRECO_ORGANICA,"
			::Query +=        " ROUND ((ORGA.Z1_PRCCOM / PRECO_BASE - 1) * 100, 0) AS VAR_ORGA"
			::Query += " FROM (SELECT Z1_TABELA, DESCR_BASE, BASE.Z1_GRAU AS GRAU, COD_BASE, COD_BORDADURA,"
			::Query +=              " COD_EM_CONVERSAO, COD_ORGANICA, BASE.Z1_PRCCOM AS PRECO_BASE"
			::Query +=         " FROM VA_VFAMILIAS_UVAS, SZ1010 BASE"
			::Query +=        " WHERE BASE.D_E_L_E_T_ = ''"
			::Query +=          " AND BASE.Z1_TABELA = '000017'"
			::Query +=          " AND BASE.Z1_PRCCOM > 0"
			::Query +=          " AND BASE.Z1_CODPRD = COD_BASE) AS FAM"
			::Query +=    " LEFT JOIN SZ1010 BORD"
			::Query +=           " ON (BORD.D_E_L_E_T_ = '' AND BORD.Z1_TABELA = FAM.Z1_TABELA AND BORD.Z1_CODPRD = FAM.COD_BORDADURA AND BORD.Z1_GRAU = FAM.GRAU)"
			::Query +=    " LEFT JOIN SZ1010 CONV"
			::Query +=           " ON (CONV.D_E_L_E_T_ = '' AND CONV.Z1_TABELA = FAM.Z1_TABELA AND CONV.Z1_CODPRD = FAM.COD_EM_CONVERSAO AND CONV.Z1_GRAU = FAM.GRAU)"
			::Query +=    " LEFT JOIN SZ1010 ORGA"
			::Query +=           " ON (ORGA.D_E_L_E_T_ = '' AND ORGA.Z1_TABELA = FAM.Z1_TABELA AND ORGA.Z1_CODPRD = FAM.COD_ORGANICA AND ORGA.Z1_GRAU = FAM.GRAU)"
			::Query += ")"
			::Query += " SELECT Z1_TABELA AS TABELA, DESCR_BASE AS VARIEDADE, GRAU,"
			::Query +=        " COD_BASE, PRECO_BASE, "
			::Query +=        " COD_BORDADURA, PRECO_BORDADURA, VAR_BORD,"
			::Query +=        " COD_EM_CONVERSAO, PRECO_CONVERSAO, VAR_CONV,"
			::Query +=        " COD_ORGANICA, PRECO_ORGANICA, VAR_ORGA"
			::Query +=   " FROM C"
			::Query +=  " WHERE (VAR_BORD IS NOT NULL AND VAR_BORD != 0)"
			::Query +=     " OR (VAR_CONV IS NOT NULL AND VAR_CONV NOT BETWEEN 14 AND 16)"
			::Query +=     " OR (VAR_ORGA IS NOT NULL AND VAR_ORGA NOT BETWEEN 59 AND 61)"
			::Query +=  " ORDER BY COD_BASE, GRAU"

		case ::Numero == 24
			::Setores    = 'PCP'
			::GrupoPerg  = "U_VALID001"
			::ValidPerg (_lDefault)
			::Descricao  = 'OP tem etiquetas nao guardadas'
			::Sugestao   = 'Revise movimentacao das etiquetas e integracao com FullWMS'
			::ViaBatch   = .F.
			::Query := ""
			::Query += "SELECT dbo.VA_DTOC (D3_EMISSAO) AS APONTAMENTO,"
			::Query +=       " D3_OP AS OP,"
			::Query +=       " D3_COD AS PRODUTO,"
			::Query +=       " RTRIM (B1_DESC) AS DESCRICAO,"
			::Query +=       " D3_VAETIQ AS ETIQUETA,"
			::Query +=       " D3_QUANT AS QT_PRODUZIDA,"
			::Query +=       " D3_PERDA AS QT_PERDA,"
			::Query +=       " D3_UM AS UN_MED,"
			::Query +=       " D3_LOCAL AS ALM_APONT,"
			::Query +=       " CASE ISNULL (t.status, '')"
			::Query +=          " WHEN '1' THEN 'Ja visualizado'"
			::Query +=          " WHEN '2' THEN 'Recebto.autorizado'"
			::Query +=          " WHEN '3' THEN 'Recebto.finalizado'"
			::Query +=          " WHEN '9' THEN 'Recebto.excluido'"
			::Query +=          " ELSE ''"
			::Query +=          " END AS STATUS_FULL,"
			::Query +=       " CASE ISNULL (t.status_protheus, '')"
			::Query +=          " WHEN '1' THEN 'Falta estq.p/transf'"
			::Query +=          " WHEN '2' THEN 'Erro ao transferir'"
			::Query +=          " WHEN '3' THEN 'Transferido OK'"
			::Query +=          " WHEN '4' THEN 'Qt.Full # Qt.ERP'"
			::Query +=          " WHEN '9' THEN 'Cancelado autom.'"
			::Query +=          " WHEN 'C' THEN 'Cancelado manual'"
			::Query +=          " ELSE ''"
			::Query +=          " END AS STATUS_PROTHEUS"
			::Query +=  " FROM " + RetSQLName ("SC2") + " SC2, "
			::Query +=             RetSQLName ("SD3") + " APONT "
			::Query +=         " LEFT JOIN tb_wms_entrada t"
			::Query +=                " on (t.entrada_id = 'ZA1' + APONT.D3_FILIAL + APONT.D3_VAETIQ),"
			::Query +=             RetSQLName ("SB1") + " SB1 "
			::Query += " WHERE APONT.D_E_L_E_T_ = ''"
			::Query +=   " AND APONT.D3_FILIAL  = '" + xfilial ("SD3") + "'"
			::Query +=   " AND APONT.D3_OP      between '" + ::Param01 + "' AND '" + ::Param02 + "'"
			::Query +=   " AND APONT.D3_COD     between '" + ::Param03 + "' AND '" + ::Param04 + "'"
			::Query +=   " AND APONT.D3_CF      like 'PR%'"
			::Query +=   " AND APONT.D3_ESTORNO != 'S'"
			::Query +=   " AND SC2.D_E_L_E_T_    = ''"
			::Query +=   " AND SC2.C2_FILIAL     = APONT.D3_FILIAL"
			::Query +=   " AND SC2.C2_NUM        = SUBSTRING (APONT.D3_OP, 1, 6)"
			::Query +=   " AND SC2.C2_ITEM       = SUBSTRING (APONT.D3_OP, 7, 2)"
			::Query +=   " AND SC2.C2_SEQUEN     = SUBSTRING (APONT.D3_OP, 9, 3)"
			::Query +=   " AND SC2.C2_ITEMGRD    = SUBSTRING (APONT.D3_OP, 12, 2)"
			::Query +=   " AND SC2.C2_VAOPESP   != 'E'"  // OPs para envase 'em terceiros' seguem fluxo diferente para entrada no FullWMS.
			::Query +=   " AND NOT EXISTS (SELECT *"
			::Query +=                     " FROM " + RetSQLName ("SD3") + " GUARDA "
			::Query +=                    " WHERE GUARDA.D_E_L_E_T_  = ''"
			::Query +=                      " AND GUARDA.D3_FILIAL   = APONT.D3_FILIAL"
			::Query +=                      " AND GUARDA.D3_ESTORNO != 'S'"
			::Query +=                      " AND GUARDA.D3_CF       = 'RE4'"
			::Query +=                      " AND GUARDA.D3_LOCAL    = APONT.D3_LOCAL"
			::Query +=                      " AND GUARDA.D3_VAETIQ   = APONT.D3_VAETIQ"
			::Query +=                      " AND GUARDA.D3_COD      = APONT.D3_COD)"
			::Query += " AND SB1.D_E_L_E_T_ = ''"
			::Query += " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			::Query += " AND SB1.B1_COD     = APONT.D3_COD"
			::Query += " ORDER BY APONT.D3_EMISSAO, APONT.D3_OP, APONT.D3_VAETIQ"

		case ::Numero == 25
			::Ativa     = .F.
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores   = 'SAF'
			::GrupoPerg = "U_VALID005"
			::ValidPerg (_lDefault)
			::Descricao = 'Associado nao consta como patriarca nesta safra'
			::Sugestao  = 'Revise amarracao entre cadastros viticolas e patriarcas.'
			::Query := ""
			::Query += "SELECT ZZB_CODPAT AS PATRIARCA, ZZB_LOJPAT AS LOJA, SA2.A2_NOME AS NOME, ZZB_CADVIT AS CAD_VITICOLA"
			::Query +=  " FROM " + RetSQLName ("ZZB") + " ZZB, "
			::Query +=             RetSQLName ("SA2") + " SA2 "  
			::Query += " WHERE SA2.D_E_L_E_T_ = ''"
			::Query +=   " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
			::Query +=   " AND SA2.A2_COD     = ZZB.ZZB_CODPAT"
			::Query +=   " AND SA2.A2_LOJA    = ZZB.ZZB_LOJPAT"
			::Query +=   " AND ZZB.D_E_L_E_T_ = ''"
			::Query +=   " AND ZZB.ZZB_FILIAL = '" + xfilial ("ZZB") + "'"
			::Query +=   " AND NOT EXISTS (SELECT *"
			::Query +=                     " FROM " + RetSQLName ("SZ8") + " SZ8 "  
			::Query +=                    " WHERE SZ8.D_E_L_E_T_ = ''"
			::Query +=                      " AND SZ8.Z8_FILIAL  = '" + xfilial ("SZ8") + "'"
			::Query +=                      " AND SZ8.Z8_CODPAT  = ZZB.ZZB_CODPAT"
			::Query +=                      " AND SZ8.Z8_LOJAPAT = ZZB.ZZB_LOJPAT"
			::Query +=                      " AND SZ8.Z8_SAFRA   = '" + ::Param01 + "')"

		case ::Numero == 26
			::Setores   = 'PCP/CUS/CTB'
			::Descricao = 'Diferenca saldo estq do produto X lotes X enderecos'
			::Sugestao  = 'Reprocesse saldo atual; possivelmente nao tenha sido gerado lote inicial (telas MATA805 ou MATA390); verifique fechamento (SB9 x SBJ x SBK); verifique movimentacao.'
			::Query := ""
			::Query += "exec VA_SP_VERIFICA_ESTOQUES '" + cFilAnt + "', null, null"


		case ::Numero == 27
			::Setores    = 'CUS'
			::Descricao  = 'OP teve consumo no mes atual e apontamento em meses posteriores'
			::Sugestao   = 'Revise datas de movimentacoes da OP'
			::QuandoUsar = "Antes de rodar o custo medio e fazer a virada de saldos no estoque."
			::Query := ""
			::Query += "WITH C AS ("
			::Query += "SELECT D3_FILIAL AS FILIAL, D3_OP AS OP, MAX (D3_EMISSAO) AS MAIOR_RE,"
			::Query +=       " (SELECT MIN (D3_EMISSAO)"
			::Query +=          " FROM " + RetSQLName ("SD3") + " APONTAMENTOS "
			::Query +=         " WHERE APONTAMENTOS.D_E_L_E_T_ = ''"
			::Query +=           " AND APONTAMENTOS.D3_FILIAL  = SD3.D3_FILIAL"
			::Query +=           " AND APONTAMENTOS.D3_OP      = SD3.D3_OP"
			::Query +=           " AND APONTAMENTOS.D3_ESTORNO != 'S'"
			::Query +=           " AND APONTAMENTOS.D3_CF LIKE 'PR%') AS MENOR_PR"
			::Query +=  " FROM " + RetSQLName ("SD3") + " SD3 "
			::Query += " WHERE D_E_L_E_T_ = ''"
			::Query +=   " AND D3_FILIAL  = '" + xfilial ("SD3") + "'"
			::Query +=   " AND D3_EMISSAO BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query +=   " AND D3_OP      != ''"
			::Query +=   " AND D3_ESTORNO != 'S'"
			::Query +=   " AND D3_CF      LIKE 'RE%'"
			::Query += " GROUP BY SD3.D3_FILIAL, SD3.D3_OP"
			::Query += ") SELECT *"
			::Query +=    " FROM C"
			::Query +=   " WHERE SUBSTRING(MENOR_PR, 1, 6) > SUBSTRING(MAIOR_RE, 1, 6)"
			::Query += " ORDER BY FILIAL, OP"

		case ::Numero == 28
			::Setores    = 'CUS'
			::Descricao  = 'OP com valores totais de RE x PR inconsistentes'
			::Sugestao   = 'Revise custo dos movimentos da OP na tabela SD3.'
			::ViaBatch   = .F.
			::GrupoPerg = "U_VALID028"
			::ValidPerg (_lDefault)
			::QuandoUsar = "Apos rodar o custo medio."
			::Query := ""
			::Query += "WITH C AS ("
			::Query += "SELECT SD3.D3_FILIAL AS FILIAL, SD3.D3_OP AS OP, SC2.C2_PRODUTO AS PRODUTO, RTRIM (PRODUZIDO.B1_DESC) AS DESCRICAO,"
			::Query +=       " SUM(CASE	WHEN D3_CF LIKE 'RE%' AND D3_TIPO     IN ('AP', 'MO', 'GF') THEN D3_CUSTO1 ELSE 0 END) AS CUSTO_RE_MO,"
			::Query +=       " SUM(CASE WHEN D3_CF LIKE 'RE%' AND D3_TIPO NOT IN ('AP', 'MO', 'GF') AND      D3_CF = 'RE9' AND CONSUMIDO.B1_AGREGCU = '1'  THEN D3_CUSTO1 ELSE 0 END) AS CUSTO_RE9,"
			::Query +=       " SUM(CASE WHEN D3_CF LIKE 'RE%' AND D3_TIPO NOT IN ('AP', 'MO', 'GF') AND NOT (D3_CF = 'RE9' AND CONSUMIDO.B1_AGREGCU = '1') THEN D3_CUSTO1 ELSE 0 END) AS CUSTO_RE_OUTROS,"
			::Query +=       " SUM(CASE WHEN D3_CF LIKE 'PR%' THEN D3_CUSTO1 ELSE 0 END) AS CUSTO_PR"
			::Query +=  " FROM " + RetSQLName ("SD3") + " SD3, "
			::Query +=             RetSQLName ("SC2") + " SC2, "
			::Query +=             RetSQLName ("SB1") + " PRODUZIDO, "
			::Query +=             RetSQLName ("SB1") + " CONSUMIDO "
			::Query += " WHERE SD3.D_E_L_E_T_ = ''"
			::Query +=   " AND SD3.D3_FILIAL  = '" + xfilial ("SD3") + "'"
			//::Query +=   " AND SD3.D3_EMISSAO BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query +=   " AND SD3.D3_EMISSAO BETWEEN '" + dtos (::Param01)  + "' AND '"+ dtos (::Param02) + "'"
			::Query +=   " AND SD3.D3_OP      != ''"
			::Query +=   " AND SD3.D3_ESTORNO != 'S'"
			::Query +=   " AND CONSUMIDO.D_E_L_E_T_ = ''"
			::Query +=   " AND CONSUMIDO.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			::Query +=   " AND CONSUMIDO.B1_COD     = SD3.D3_COD"
			::Query +=   " AND SC2.D_E_L_E_T_ = ''"
			::Query +=   " AND SC2.C2_FILIAL  = SD3.D3_FILIAL"
			::Query +=   " AND SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN + SC2.C2_ITEMGRD = SD3.D3_OP"
			::Query +=   " AND PRODUZIDO.D_E_L_E_T_ = ''"
			::Query +=   " AND PRODUZIDO.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			::Query +=   " AND PRODUZIDO.B1_COD     = SC2.C2_PRODUTO"
			::Query += " GROUP BY SD3.D3_FILIAL, SD3.D3_OP, SC2.C2_PRODUTO, PRODUZIDO.B1_DESC"
			::Query += ") SELECT C.*, (CUSTO_RE_MO + CUSTO_RE_OUTROS - CUSTO_PR) AS DIFERENCA"
			::Query +=    " FROM C"
			::Query +=   " WHERE ROUND (CUSTO_RE_MO + CUSTO_RE_OUTROS, 2) != ROUND (CUSTO_PR, 2)"
			::Query += " ORDER BY FILIAL, OP"
			u_log(::Query)

		case ::Numero == 29
			::Filiais    = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores    = 'ENG/FAT'
			::Descricao  = "Produto tem peso liquido (campo '" + alltrim (RetTitle ("B1_PESO")) + "') maior que peso bruto (campo '" + alltrim (RetTitle ("B1_PESBRU")) + "') no cadastro."
			::Sugestao   = 'Revise cadastro do produto.'
			::Query := ""
			::Query += " SELECT B1_TIPO AS TIPO, B1_COD AS PRODUTO, SB1.B1_DESC AS DESCRICAO, SB1.B1_UM AS UN_MED, SB1.B1_PESO AS PESO_LIQ, SB1.B1_PESBRU AS PESO_BRUTO"
			::Query +=  " FROM " + RetSQLName ("SB1") + " SB1 "  
			::Query += " WHERE SB1.D_E_L_E_T_ = ''"
			::Query +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			::Query +=   " AND SB1.B1_MSBLQL != '1'"
			::Query +=   " AND SB1.B1_PESBRU < SB1.B1_PESO"
			::Query += " ORDER BY B1_TIPO, B1_COD"

		case ::Numero == 30
			::Setores    = 'PCP'
			::Descricao  = "Empenho do endereco (tabela SBF) inconsistente com a composicao do empenho (tabela SDC)."
			::Sugestao   = "Execute rotina de 'Refaz acumulados'; Verifique necessidade de ajustar o campo BF_EMPENHO manualmente."
			::ViaBatch   = .T.
			::Query := ""
			::Query += "WITH C AS ("
			::Query += " SELECT SBF.BF_FILIAL AS FILIAL, SBF.BF_LOCAL AS ALMOX, SBF.BF_LOCALIZ AS ENDERECO,"
			::Query +=        " SBF.BF_PRODUTO AS PRODUTO, RTRIM (SB1.B1_DESC) AS DESCRICAO, SBF.BF_LOTECTL AS LOTE,"
			::Query +=        " ISNULL (SUM (SBF.BF_EMPENHO), 0) AS EMPENHOS_ENDERECO,"
			::Query +=        " ISNULL ((SELECT SUM (SDC.DC_QUANT)"
			::Query +=                  " FROM " + RetSQLName ("SDC") + " SDC "
			::Query +=                 " WHERE SDC.D_E_L_E_T_ = ''"
			::Query +=                   " AND SDC.DC_FILIAL  = SBF.BF_FILIAL"
			::Query +=                   " AND SDC.DC_LOCAL   = SBF.BF_LOCAL"
			::Query +=                   " AND SDC.DC_LOCALIZ = SBF.BF_LOCALIZ"
			::Query +=                   " AND SDC.DC_PRODUTO = SBF.BF_PRODUTO"
			::Query +=                   " AND SDC.DC_LOTECTL = SBF.BF_LOTECTL), 0) AS COMPOSICAO_EMPENHOS"
			::Query +=   " FROM " + RetSQLName ("SB1") + " SB1, "
			::Query +=              RetSQLName ("SBF") + " SBF "
			::Query +=  " WHERE SBF.D_E_L_E_T_ = ''"
			::Query +=    " AND SB1.D_E_L_E_T_ = ''"
			::Query +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			::Query +=    " AND SB1.B1_COD     = SBF.BF_PRODUTO"
			::Query +=    " AND SBF.BF_FILIAL  = '" + xfilial ("SBF") + "'"
			::Query +=  " GROUP BY SBF.BF_FILIAL, SBF.BF_LOCAL, SBF.BF_LOCALIZ, SBF.BF_PRODUTO, SB1.B1_DESC, SBF.BF_LOTECTL"
			::Query +=  " )"
			::Query +=  " SELECT *"
			::Query +=    " FROM C"
			::Query +=   " WHERE EMPENHOS_ENDERECO != COMPOSICAO_EMPENHOS"
			::Query +=   " ORDER BY FILIAL, ALMOX, ENDERECO, PRODUTO, LOTE

		case ::Numero == 31
			::Setores    = 'PCP'
			::Descricao  = "Empenho do lote (tabela SB8) inconsistente com a composicao do empenho (tabela SDC)."
			::Sugestao   = "Execute rotina de 'Refaz acumulados'; Verifique necessidade de ajustar o campo B8_EMPENHO manualmente."
			::ViaBatch   = .T.
			::Query := ""
			::Query += "WITH C AS ("
			::Query += " SELECT SB8.B8_FILIAL AS FILIAL, SB8.B8_LOCAL AS ALMOX, "
			::Query +=        " SB8.B8_PRODUTO AS PRODUTO, RTRIM (SB1.B1_DESC) AS DESCRICAO, SB8.B8_LOTECTL AS LOTE,"
			::Query +=        " ISNULL (SUM (SB8.B8_EMPENHO), 0) AS EMPENHOS_LOTE,"
			::Query +=        " ISNULL ((SELECT SUM (SDC.DC_QUANT)"
			::Query +=                  " FROM " + RetSQLName ("SDC") + " SDC "
			::Query +=                 " WHERE SDC.D_E_L_E_T_ = ''"
			::Query +=                   " AND SDC.DC_FILIAL  = SB8.B8_FILIAL"
			::Query +=                   " AND SDC.DC_LOCAL   = SB8.B8_LOCAL"
			::Query +=                   " AND SDC.DC_PRODUTO = SB8.B8_PRODUTO"
			::Query +=                   " AND SDC.DC_LOTECTL = SB8.B8_LOTECTL), 0) AS COMPOSICAO_EMPENHOS"
			::Query +=   " FROM " + RetSQLName ("SB1") + " SB1, "
			::Query +=              RetSQLName ("SB8") + " SB8 "
			::Query +=  " WHERE SB8.D_E_L_E_T_ = ''"
			::Query +=    " AND SB1.D_E_L_E_T_ = ''"
			::Query +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			::Query +=    " AND SB1.B1_COD     = SB8.B8_PRODUTO"
			::Query +=    " AND SB8.B8_FILIAL  = '" + xfilial ("SB8") + "'"
			::Query +=  " GROUP BY SB8.B8_FILIAL, SB8.B8_LOCAL, SB8.B8_PRODUTO, SB1.B1_DESC, SB8.B8_LOTECTL"
			::Query +=  " )"
			::Query +=  " SELECT *"
			::Query +=    " FROM C"
			::Query +=   " WHERE EMPENHOS_LOTE != COMPOSICAO_EMPENHOS"
			::Query +=   " ORDER BY FILIAL, ALMOX, PRODUTO, LOTE

		case ::Numero == 32
			::Setores    = 'FIS'
			::Descricao  = "Pre-notas fiscais de entrada sem classificacao"
			::Sugestao   = "Classifique (ou exclua, se forem indevidas) as pre-notas no modulo de compras ou estoque."
			::Query := ""	
			::Query += " SELECT DISTINCT D1_FILIAL AS FILIAL, D1_DOC AS DOC, D1_SERIE SERIE, D1_FORNECE AS FORNECEDOR, D1_LOJA AS LOJA, D1_EMISSAO EMISSAO "
			::Query +=   " FROM " + RetSQLName ("SD1") + " SD1  "
			::Query +=  " WHERE SD1.D_E_L_E_T_ = ''"
			::Query +=    " AND SD1.D1_FILIAL  = '" + xfilial ("SD1") + "'"
			::Query +=    " AND SD1.D1_TES     = '' "
			::Query +=    " AND SD1.D1_EMISSAO >= '" + dtos (date () - 365) + "'"  // Nao adianta olhar notas antigas demais...
			::Query +=  " ORDER BY D1_FILIAL, D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_EMISSAO "

		case ::Numero == 33
			::Setores    = 'PCP'
			::Descricao  = "Produtos com saldo a enderecar"
			::Sugestao   = "Execute rotina de enderecamento de produtos ou exclua o documento que gerou o saldo."
			::Query := ""	
			::Query += " SELECT DA_FILIAL AS FILIAL, DA_PRODUTO AS PRODUTO, RTRIM (B1_DESC) AS DESCRICAO,"
			::Query +=        " DA_LOCAL AS ALMOX, DA_DOC AS DOCTO, DA_DATA AS DATA, ROUND (DA_QTDORI, 4) AS QT_ORIG, ROUND (DA_SALDO, 4) AS SALDO"
			::Query += " FROM " + RetSQLName ("SDA") + " SDA, "
			::Query +=            RetSQLName ("SB1") + " SB1 "
			::Query += " WHERE SDA.D_E_L_E_T_ = ''"
			::Query +=   " AND SDA.DA_FILIAL  = '" + xfilial ("SDA") + "'"
			::Query +=   " AND SDA.DA_SALDO  != 0"
			::Query +=   " AND SB1.D_E_L_E_T_ = ''"
			::Query +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			::Query +=   " AND SB1.B1_COD     = SDA.DA_PRODUTO"
			::Query += " ORDER BY DA_FILIAL, DA_PRODUTO, DA_DATA "

		case ::Numero == 34
			::Setores    = 'INF'
			::Descricao  = "Inconsistencia entre tabelas SD3 (mov.internos) e SD5 (mov.lotes)"
			::Sugestao   = "Verifique movimentacao."
			::GrupoPerg  = "U_VALID002"
			::ValidPerg (_lDefault)
			::Query := ""
			::Query += " WITH _SD5 AS"
			::Query += "(SELECT D5_FILIAL, D5_PRODUTO, SD5.D5_DATA, D5_LOTECTL, D5_ORIGLAN, D5_DOC, SD5.D5_NUMSEQ, SUM(D5_QUANT) AS QT_SD5"
			::Query +=   " FROM " + RetSQLName ("SD5") + " SD5 "
			::Query +=  " WHERE D_E_L_E_T_ = ''"
			::Query +=    " AND D5_FILIAL  = '" + xfilial ("SD5") + "'"
			::Query +=    " AND D5_PRODUTO between '" + ::Param03 + "' AND '" + ::Param04 + "'"
			::Query +=    " AND D5_DATA    BETWEEN '" + dtos (::Param01) + "' AND '" + dtos (::Param02) + "'"
			::Query +=  " GROUP BY D5_FILIAL, D5_PRODUTO, SD5.D5_DATA, D5_LOTECTL, D5_ORIGLAN, D5_DOC, SD5.D5_NUMSEQ"
			::Query += "),"
			::Query += " _SD3 AS"
			::Query += "(SELECT D3_FILIAL, D3_COD, SD3.D3_EMISSAO, D3_LOTECTL, D3_TM, D3_DOC, SD3.D3_NUMSEQ, SUM(D3_QUANT) AS QT_SD3"
			::Query +=   " FROM " + RetSQLName ("SD3") + " SD3 "
			::Query +=  " WHERE D_E_L_E_T_ = ''"
			::Query +=    " AND D3_FILIAL  = '" + xfilial ("SD3") + "'"
			::Query +=    " AND D3_COD     between '" + ::Param03 + "' AND '" + ::Param04 + "'"
			::Query +=    " AND D3_EMISSAO BETWEEN '" + dtos (::Param01) + "' AND '" + dtos (::Param02) + "'"
			::Query +=  " GROUP BY D3_FILIAL, D3_COD, SD3.D3_EMISSAO, D3_LOTECTL, D3_TM, D3_DOC, SD3.D3_NUMSEQ"
			::Query += ")"
			::Query += " SELECT *"
			::Query += " FROM _SD5 FULL OUTER JOIN _SD3"
			::Query +=   " ON (D5_FILIAL  = D3_FILIAL"
			::Query +=   " AND D5_PRODUTO = D3_COD"
			::Query +=   " AND D5_DATA    = D3_EMISSAO"
			::Query +=   " AND D5_ORIGLAN = D3_TM"
			::Query +=   " AND D5_LOTECTL = D3_LOTECTL"
			::Query +=   " AND D5_DOC     = D3_DOC"
			::Query +=   " AND D5_NUMSEQ  = D3_NUMSEQ)"
			::Query += " WHERE QT_SD3 != QT_SD5"

		case ::Numero == 35
			::Setores    = 'CUS'
			::Descricao  = "Inconsistencia entre tabelas fechto estoque SB9 x SBJ x SBK"
			::Sugestao   = "Verifique movimentacao e virada de saldos."
			::GrupoPerg  = "U_VALID006"
			::ValidPerg (_lDefault)
			::QuandoUsar = "Apos fazer a virada de saldos do estoque."
			::Query := ""
			::Query += " WITH _SBJ AS ("
			::Query += " SELECT BJ_FILIAL, SBJ.BJ_COD, SBJ.BJ_LOCAL, SBJ.BJ_DATA, SUM (SBJ.BJ_QINI) AS QT_SBJ"
			::Query +=   " FROM " + RetSQLName ("SBJ") + " SBJ"
			::Query +=  " WHERE SBJ.D_E_L_E_T_ = ''"
			::Query +=    " AND SBJ.BJ_FILIAL  = '" + xfilial ("SBJ") + "'"
			::Query +=    " AND SBJ.BJ_COD     between '" + ::Param03 + "' AND '" + ::Param04 + "'"
			::Query +=    " AND SBJ.BJ_DATA    between '" + dtos (::Param01) + "' and '" + dtos (::Param02) + "'"
			::Query += " GROUP BY BJ_FILIAL, SBJ.BJ_COD, SBJ.BJ_LOCAL, SBJ.BJ_DATA"
			::Query += " ),"
			::Query += " _SBK AS ("
			::Query += " SELECT BK_FILIAL, BK_COD, BK_LOCAL, BK_DATA, SUM (BK_QINI) AS QT_SBK"
			::Query +=   " FROM " + RetSQLName ("SBK") + " SBK"
			::Query +=  " WHERE SBK.D_E_L_E_T_ = ''"
			::Query +=    " AND SBK.BK_FILIAL  = '" + xfilial ("SBK") + "'"
			::Query +=    " AND SBK.BK_COD     between '" + ::Param03 + "' AND '" + ::Param04 + "'"
			::Query +=    " AND SBK.BK_DATA    between '" + dtos (::Param01) + "' and '" + dtos (::Param02) + "'"
			::Query += " GROUP BY BK_FILIAL, BK_COD, BK_LOCAL, BK_DATA"
			::Query += " ),"
			::Query += " _SB9 AS ("
			::Query += " SELECT B9_FILIAL, B9_COD, B9_LOCAL, B9_DATA, B9_QINI AS QT_SB9"
			::Query +=   " FROM " + RetSQLName ("SB9") + " SB9"
			::Query +=  " WHERE SB9.D_E_L_E_T_ = ''"
			::Query +=    " AND SB9.B9_FILIAL  = '" + xfilial ("SB9") + "'"
			::Query +=    " AND SB9.B9_COD     between '" + ::Param03 + "' AND '" + ::Param04 + "'"
			::Query +=    " AND SB9.B9_DATA    between '" + dtos (::Param01) + "' and '" + dtos (::Param02) + "'"
			::Query += " )"
			::Query += " SELECT B9_FILIAL, B9_COD, B9_LOCAL, B9_DATA, QT_SB9, QT_SBJ, QT_SBK, QT_SB9 - QT_SBJ AS DIF_SB9_SBJ, QT_SB9 - QT_SBK AS DIF_SB9_SBK"
			::Query += " FROM _SB9"
			::Query += " FULL OUTER JOIN _SBJ ON (BJ_FILIAL = B9_FILIAL AND BJ_COD = B9_COD AND BJ_LOCAL = B9_LOCAL AND BJ_DATA = B9_DATA)"
			::Query += " FULL OUTER JOIN _SBK ON (BK_FILIAL = B9_FILIAL AND BK_COD = B9_COD AND BK_LOCAL = B9_LOCAL AND BK_DATA = B9_DATA)"
			::Query += " WHERE ROUND (QT_SBJ, 4) != ROUND (QT_SB9, 4) OR ROUND (QT_SBK, 4) != ROUND (QT_SB9, 4)"
			::Query += " ORDER BY B9_COD, B9_LOCAL"


		case ::Numero == 36
			::Setores    = 'PCP'
			::Descricao  = "Empenho lote/endereco (tabela SDC) relacionado a OP inexistente ou ja encerrada."
			::Sugestao   = "Execute rotina de 'Refaz acumulados'; Verifique necessidade de ajustar o campo DC_QUANT manualmente."
			::ViaBatch   = .T.
			::Query := ""
			::Query += " SELECT SDC.DC_FILIAL,"
			::Query +=        " SDC.DC_PRODUTO,"
			::Query +=        " SDC.DC_LOCAL,"
			::Query +=        " SDC.DC_LOCALIZ,"
			::Query +=        " SDC.DC_LOTECTL,"
			::Query +=        " SDC.DC_OP,"
			::Query +=        " SDC.DC_QUANT"
			::Query +=   " FROM " + RetSQLName ("SDC") + " SDC "
			::Query +=  " WHERE SDC.D_E_L_E_T_ = ''"
			::Query +=    " AND SDC.DC_FILIAL  = '" + xfilial ("SDC") + "'"
			::Query +=    " AND SDC.DC_QUANT  != 0"
			::Query +=    " AND NOT EXISTS (SELECT *"
			::Query +=                      " FROM " + RetSQLName ("SC2") + " SC2 "
			::Query +=                     " WHERE SC2.D_E_L_E_T_ = ''"
			::Query +=                       " AND SC2.C2_FILIAL = SDC.DC_FILIAL"
			::Query +=                       " AND SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN + SC2.C2_ITEMGRD = SDC.DC_OP"
			::Query +=                       " AND SC2.C2_DATRF = '')"

		case ::Numero == 37
			::Setores    = 'CUS'
			::Descricao  = "Almox inexistente na tabela de saldos"
			::Sugestao   = "Verifique movimentacao e tabela de saldos (SB2)"
			::QuandoUsar = "A qualquer momento"
			::Query := ""
			::Query += " SELECT SB2.B2_FILIAL AS FILIAL, SB2.B2_COD AS PRODUTO, SB2.B2_LOCAL AS ALMOX, SB2.B2_QATU AS SALDO_QT"
			::Query +=   " FROM " + RetSQLName ("SB2") + " SB2 "
			::Query +=  " WHERE SB2.D_E_L_E_T_ = ''"
			::Query +=    " AND SB2.B2_FILIAL  = '" + xfilial ("SB2") + "'"
			::Query +=    " AND NOT EXISTS (SELECT *"
			::Query +=                      " FROM " + RetSQLName ("NNR") + " NNR "
			::Query +=                     " WHERE NNR.D_E_L_E_T_ = ''"
			::Query +=                       " AND NNR.NNR_FILIAL = '" + xfilial ("NNR") + "'"
			::Query +=                       " AND NNR.NNR_CODIGO = SB2.B2_LOCAL)"
			::Query += " ORDER BY B2_COD, B2_LOCAL"
			
		case ::Numero == 38
			::Setores    = 'PCP'
			::Descricao  = "Estrutura sobreposta"
			::Sugestao   = "Verificar estruturas dos itens"
			::Query := ""
			::Query += " SELECT	G1_COD, G1_COMP, G1_REVINI + G1_REVFIM REVISAO"
			::Query +=   " FROM " + RetSQLName ("SG1") + " A "
			::Query += " WHERE G1_INI <= '"+DTOS(DATE())+"'"
			::Query += 		" AND G1_FIM >= '"+DTOS(DATE())+"'"
			::Query +=   	" AND EXISTS (SELECT * "
			::Query += " FROM " + RetSQLName ("SG1") + " B "
			::Query +=		" WHERE B.G1_COD = A.G1_COD"
			::Query +=		  " AND B.G1_COMP = A.G1_COMP"
			::Query +=        " AND B.G1_INI <= '"+DTOS(DATE())+"'"
			::Query +=        " AND B.G1_FIM >= '"+DTOS(DATE())+"'"
			::Query +=		  " AND B.D_E_L_E_T_ = ''"
			::Query +=        " AND B.R_E_C_N_O_ <> A.R_E_C_N_O_"
			::Query +=        " AND ((B.G1_REVINI <= A.G1_REVINI"
			::Query +=        " AND B.G1_REVFIM >= A.G1_REVINI )"
			::Query +=      " OR (B.G1_REVINI <= A.G1_REVFIM"
			::Query +=        " AND B.G1_REVFIM >= A.G1_REVFIM)" 
			::Query +=		" OR ( B.G1_REVINI >= A.G1_REVINI"
			::Query +=        " AND B.G1_REVFIM <= A.G1_REVFIM ))"
			::Query += 		" ) "
			::Query += " AND A.D_E_L_E_T_ = ''"

		case ::Numero == 39
			::Setores    = 'CUS'
			::Descricao  = "Transferência entre filiais com custos diferentes"
			::Sugestao   = ""
			::Query := ""
			::Query += " SELECT D1_DTDIGIT AS DT_DIGIT "
			::Query +=      " , D1_FILIAL AS FILIAL_NFE "
			::Query +=      " , D1_FORNECE AS FORNECEDOR "
			::Query +=      " , D1_LOJA AS LOJA_NFE "
			::Query +=      " , D1_SERIE AS SERIE_NFE "
			::Query +=      " , D1_DOC AS DOC_NFE "
			::Query +=      " , D1_TES AS TES_NFE "
			::Query +=      " , D1_CUSTO AS CUSTO_NFE "
			::Query +=      " , D2_FILIAL AS FILIAL_NFS "
			::Query +=      " , D2_CLIENTE AS CLIENTE "
			::Query +=      " , D2_LOJA AS LOJA_NFS "
			::Query +=      " , D2_SERIE AS SERIE_NFS "
			::Query +=      " , D2_DOC AS DOC_NFS "
			::Query +=      " , D2_TES AS TES_NFS "
			::Query +=      " , D2_CUSTO1 AS CUSTO_NFS "
			::Query += " FROM VA_VTRANSF_ENTRE_FILIAIS "
			::Query += " INNER JOIN " + RetSQLName ("SF4") + " AS SF4E "
			::Query += "	ON (SF4E.D_E_L_E_T_ = '' "
			::Query += "			AND SF4E.F4_CODIGO = D1_TES "
			::Query += "			AND SF4E.F4_ESTOQUE = 'S') "
			::Query += " INNER JOIN " + RetSQLName ("SF4") + " AS SF4S "
			::Query += "	ON (SF4S.D_E_L_E_T_ = '' "
			::Query += "			AND SF4S.F4_CODIGO = D2_TES "
			::Query += "			AND SF4S.F4_ESTOQUE = 'S') "
			::Query += " WHERE D1_DTDIGIT BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " AND D1_CUSTO <> D2_CUSTO1 "
		
		case ::Numero == 40
			::Setores    = 'CUS'
			::Descricao  = "Transferência entre filiais - Uma TES altera estoque e a outra não altera"
			::Sugestao   = ""
			::Query := ""
			::Query += " SELECT"
			::Query += "	DT_DIGIT"
			::Query += "   ,FILIAL_NFE"
			::Query += "   ,FORNECEDOR"
			::Query += "   ,LOJA_NFE"
			::Query += "   ,SERIE_NFE"
			::Query += "   ,DOC_NFE"
			::Query += "   ,CUSTO_NFE"
			::Query += "   ,ATU_EST_NFE"
			::Query += "   ,' '"
			::Query += "   ,FILIAL_NFS"
			::Query += "   ,CLIENTE"
			::Query += "   ,LOJA_NFS"
			::Query += "   ,SERIE_NFS"
			::Query += "   ,DOC_NFS"
			::Query += "   ,CUSTO_NFS"
			::Query += "   ,ATU_EST_NFS"
			::Query += " FROM (SELECT"
			::Query += "		D1_DTDIGIT AS DT_DIGIT"
			::Query += "	   ,D1_FILIAL AS FILIAL_NFE"
			::Query += "	   ,D1_FORNECE AS FORNECEDOR"
			::Query += "	   ,D1_LOJA AS LOJA_NFE"
			::Query += "	   ,D1_SERIE AS SERIE_NFE"
			::Query += "	   ,D1_DOC AS DOC_NFE"
			::Query += "	   ,D1_CUSTO AS CUSTO_NFE"
			::Query += "	   ,D2_FILIAL AS FILIAL_NFS"
			::Query += "	   ,D2_CLIENTE AS CLIENTE"
			::Query += "	   ,D2_LOJA AS LOJA_NFS"
			::Query += "	   ,D2_SERIE AS SERIE_NFS"
			::Query += "	   ,D2_DOC AS DOC_NFS"
			::Query += "	   ,D2_CUSTO1 AS CUSTO_NFS"
			::Query += "	   ,(SELECT"
			::Query += "				F4_ESTOQUE"
			::Query += "			FROM " + RetSQLName ("SF4") 
			::Query += "			WHERE D_E_L_E_T_ = ''"
			::Query += "			AND F4_CODIGO = D1_TES)"
			::Query += "		AS ATU_EST_NFE"
			::Query += "	   ,(SELECT"
			::Query += "				F4_ESTOQUE"
			::Query += "			FROM  "+ RetSQLName ("SF4") 
			::Query += "			WHERE D_E_L_E_T_ = ''"
			::Query += "			AND F4_CODIGO = D2_TES)"
			::Query += "		AS ATU_EST_NFS"
			::Query += "	FROM VA_VTRANSF_ENTRE_FILIAIS"
			::Query += "	WHERE D1_DTDIGIT BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " )RETORNO"
			::Query += " WHERE ATU_EST_NFE <> ATU_EST_NFS"
			
		case ::Numero == 41
			::Ativa = .F.  // Ninguem usa e estava demorando 3 horas para rodar... Robert, 10/11/2022
			::Setores    = 'CUS'
			::Descricao  = "Movimento fora do período de emissão/encerramento OP"
			::Sugestao   = ""
			::Query := ""
			::Query += " WITH C"
			::Query += " AS"
			::Query += " (SELECT"
			::Query += " 		SD3.D3_OP"
			::Query += " 	   ,SD3.D3_EMISSAO"
			::Query += " 	   ,SC2.C2_EMISSAO"
			::Query += " 	   ,SC2.C2_DATRF"
			::Query += " 	   ,SD3.D3_COD"
			::Query += " 	FROM " + RetSQLName ("SD3") + " SD3"
			::Query += " 		," + RetSQLName ("SC2") + " SC2"
			::Query += " 	WHERE SD3.D_E_L_E_T_ = ''"
			::Query += " 	AND SD3.D3_FILIAL = '" + xfilial ("SD3") + "'"
			::Query += " 	AND SD3.D3_EMISSAO BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " 	AND SD3.D3_OP <> ''"
			::Query += " 	AND SD3.D3_ESTORNO <> 'S'"
			::Query += " 	AND SC2.D_E_L_E_T_ = ''"
			::Query += " 	AND SC2.C2_FILIAL = SD3.D3_FILIAL"
			::Query += " 	AND SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN + SC2.C2_ITEMGRD = SD3.D3_OP)"
			::Query += " SELECT"
			::Query += " 	'Movimento fora do período de emissão/encerramento OP' AS PROBLEMA"
			::Query += "    ,D3_OP AS OP"
			::Query += "    ,C2_EMISSAO AS EMISSAO_OP"
			::Query += "    ,D3_EMISSAO AS DT_MOVTO"
			::Query += "    ,C2_DATRF AS ENCERR_OP"
			::Query += "    ,D3_COD AS PRODUTO"
			::Query += "    ,RTRIM(B1_DESC) AS DESCRICAO"
			::Query += " FROM C"
			::Query += " 	," + RetSQLName ("SB1") + " SB1"
			::Query += " WHERE ((C2_DATRF <> ''"
			::Query += " AND D3_EMISSAO > C2_DATRF)"
			::Query += " OR D3_EMISSAO < C2_EMISSAO)"
			::Query += " AND SB1.D_E_L_E_T_ = ''"
			::Query += " AND SB1.B1_COD = D3_COD"
			::Query += " ORDER BY EMISSAO_OP"	
			
		case ::Numero == 42
			::Setores    = 'CUS'
			::Descricao  = "Quantidade ou valor negativo para fechamento"
			::Sugestao   := "Toda vez que é rodado o custo médio, o sistema grava na tabela SB2 os campos B2_QFIM e B2_VFIM1 que são, respectivamente, quantidade e valor (custo na moeda 1) que ele encontrou na data final do cálculo."
			::Sugestao   += "Se foi rodado o médio automaticamente à noite, o cálculo é feito até a data atual, e esses seriam a quantidade e valor que o sistema apurou até o momento."
			::Sugestao   += "Se foi executado o cálculo para fazer o fechamento de estoque, então serão os valores apurados até o dia 31 do mês a ser fechado."
			::Sugestao   += "Essa quantidade e valor devem ser os mesmos a que você chegará se emitir o kardex diário (MATR900)."
			::Sugestao   += "Para saber o motivo de ficarem negativos, você teria que emitir esse relatório para analisar, preferencialmente um almoxarifado por vez. Lembrar de parametrizar o intervalo de datas desde o primeiro dia do mês que está aberto no estoque. Já a data final, depende de qual cálculo de médio foi realizado antes de consultar essa verificação (se foi até a data atual, ou até o último dia do mês a encerrar)."
			::Query := ""
			::Query += " SELECT"
			::Query += "	'Quantidade ou valor negativo para fechamento' AS PROBLEMA"
			::Query += "    ,B2_COD AS PRODUTO"
			::Query += "    ,B1_DESC AS DESCRICAO"
			::Query += "    ,B2_LOCAL AS ALMOX"
			::Query += "    ,B2_QFIM AS QUANT"
			::Query += "    ,B2_VFIM1 AS VALOR"
			::Query += " FROM " + RetSQLName ("SB2") + " SB2"
			::Query += " 	," + RetSQLName ("SB1") + " SB1"
			::Query += " WHERE SB2.D_E_L_E_T_ = ''"
			::Query += " AND SB2.B2_FILIAL = '" + xfilial ("SB2") + "'"
			::Query += " AND (SB2.B2_QFIM < -0.01 OR B2_VFIM1 < -0.01)"
			::Query += " AND SB1.D_E_L_E_T_ = ' '"
			::Query += " AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
			::Query += " AND SB1.B1_COD = SB2.B2_COD"
			::Query += " ORDER BY B2_COD"
			
		case ::Numero == 43
			::Setores    = 'CUS'
			::Descricao  = "Quantidade sem valor para fechamento ou vice-versa"
			::Sugestao   = ""
			::Query := ""
			::Query += " SELECT 'Quantidade sem valor para fechamento ou vice-versa' AS PROBLEMA"
			::Query +=       ", B2_LOCAL AS ALMOX"
			::Query +=       ", B2_CMFIM1 AS MEDIO_UNIT"
			::Query +=       ", B2_QFIM AS QUANT"
			::Query +=       ", B2_VFIM1 AS VALOR"
			::Query +=       ", B2_COD AS PRODUTO"
			::Query +=       ", B1_DESC AS DESCRICAO"
			::Query +=       ", B1_TIPO AS TIPO_PRODUTO"
			::Query += " FROM " + RetSQLName ("SB2") + " SB2"
			::Query +=     ", " + RetSQLName ("SB1") + " SB1"
			::Query += " WHERE SB2.D_E_L_E_T_ = ''"
			::Query += " AND SB2.B2_FILIAL = '" + xfilial ("SB2") + "'"
			::Query += " AND ((SB2.B2_QFIM = 0"
			::Query += " AND ABS(B2_VFIM1) > 0.01)"
			::Query += " OR (SB2.B2_QFIM <> 0"
			::Query += " AND ABS(B2_VFIM1) < 0.01))"
			::Query += " AND SB1.D_E_L_E_T_ = ''"
			::Query += " AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
			::Query += " AND SB1.B1_COD = SB2.B2_COD"
			::Query += " ORDER BY B2_COD"
			
		case ::Numero == 44
			::Setores    = 'CUS'
			::Descricao  = "NF de saída com custo zerado ou negativo"
			::Sugestao   = ""
			::Query := ""
			::Query += " SELECT"	
			::Query += "	'NF de saída com custo zerado ou negativo' AS PROBLEMA"
			::Query += "   ,D2_DOC AS NF"
			::Query += "   ,D2_LOCAL AS ALMOX"
			::Query += "   ,D2_EMISSAO AS EMISSAO"
			::Query += "   ,D2_TES AS TES"
			::Query += "   ,D2_COD AS PRODUTO"
			::Query += "   ,D2_CUSTO1 AS CUSTO"
			::Query += " FROM " + RetSQLName ("SD2") + " SD2"
			::Query += "	," + RetSQLName ("SF4") + " SF4"
			::Query += " WHERE SD2.D_E_L_E_T_ = ''"
			::Query += " AND SD2.D2_FILIAL = '" + xfilial ("SD2") + "'"
			::Query += " AND SD2.D2_CUSTO1 <= 0"
			::Query += " AND SD2.D2_EMISSAO BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " AND SF4.D_E_L_E_T_ = ''"
			::Query += " AND SF4.F4_FILIAL = '" + xfilial ("SF4") + "'"
			::Query += " AND SF4.F4_CODIGO = SD2.D2_TES"
			::Query += " AND SF4.F4_ESTOQUE = 'S'"
			::Query += " ORDER BY D2_COD, D2_DOC"
			
		case ::Numero == 45
			::Setores    = 'CUS'
			::Descricao  = "Inconsistencia entre tabelas e parametros"
			::Sugestao   = ""
			::Query := ""
			::Query += " WITH C"	
			::Query += " AS"
			::Query += " (SELECT"
			::Query += " 		'Inconsistencia entre tabelas e parametros' AS PROBLEMA"
			::Query += " 		,'MV_ULMES:   ' + dbo.VA_DTOC ('" + dtos (GetMv ("MV_ULMES")) + "') AS MV_ULMES"
			::Query += " 	    ,'ULTIMO SB9: ' + (SELECT"
			::Query += " 				dbo.VA_DTOC(ISNULL(MAX(B9_DATA), ''))"
			::Query += " 			FROM " + RetSQLName ("SB9") + " SB9"
			::Query += " 			WHERE SB9.D_E_L_E_T_ = ''"
			::Query += " 			AND SB9.B9_FILIAL = '" + xfilial ("SB9") + "')"
			::Query += " 		AS ULTIMO_SB9"
			If GetMV ("MV_RASTRO") == "S"
				::Query += " 	   ,'ULTIMO SBJ: ' + (SELECT"
				::Query += " 				dbo.VA_DTOC(ISNULL(MAX(BJ_DATA), '')) AS ULTIMO_SBJ"
				::Query += " 			FROM " + RetSQLName ("SBJ") + " SBJ"
				::Query += " 			WHERE SBJ.D_E_L_E_T_ = ''"
				::Query += " 			AND SBJ.BJ_COD <> ''"
				::Query += " 			AND SBJ.BJ_FILIAL = '" + xfilial ("SBJ") + "')"
				::Query += " 		AS ULTIMO_SBJ"
				::Query += " 	   ,'ULTIMO SBK: ' + (SELECT"
				::Query += " 				dbo.VA_DTOC(ISNULL(MAX(BK_DATA), '')) AS ULTIMO_SBK"
				::Query += " 			FROM " + RetSQLName ("SBK") + " SBK"
				::Query += " 			WHERE SBK.D_E_L_E_T_ = ''"
				::Query += " 			AND SBK.BK_COD <> ''"
				::Query += " 			AND SBK.BK_FILIAL = '" + xfilial ("SBK") + "')"
				::Query += " 		AS ULTIMO_SBK"
			EndIf
			::Query += " ) "
			::Query += " SELECT"
			::Query += " 	*"
			::Query += " FROM C"
			::Query += " WHERE SUBSTRING(MV_ULMES, 13, 10) <> SUBSTRING(ULTIMO_SB9, 13, 10)"
			If GetMV ("MV_RASTRO") == "S"
				::Query += " OR (ULTIMO_SBJ != 'ULTIMO SBJ: //'"
				::Query += " AND SUBSTRING(MV_ULMES, 13, 10) <> SUBSTRING(ULTIMO_SBJ, 13, 10))"
				::Query += " OR (ULTIMO_SBK != 'ULTIMO SBK: //'"
				::Query += " AND SUBSTRING(MV_ULMES, 13, 10) <> SUBSTRING(ULTIMO_SBK, 13, 10))"		
			EndIf	
			
		case ::Numero == 46
			::Setores    = 'CUS'
			::Descricao  = "Volume de acucar acima do limite"
			::GrupoPerg  = "U_VALID046"
			::ValidPerg (_lDefault)
			::Sugestao   = ""
			::Query := ""
			::Query += " SELECT
			::Query += " 	'Volume de acucar acima do limite de " + alltrim(::Param03) + " g/l' AS PROBLEMA"
			::Query += "    ,D3_OP AS OP"
			::Query += "    ,C2_PRODUTO AS PRODUTO"
			::Query += "    ,B1_DESC AS DESCRICAO"
			::Query += "    ,SC2.C2_QUJE AS QT_PRODUZIDA"
			::Query += "    ,SC2.C2_UM AS UNID_MEDIDA"
			::Query += "    ,SUM(D3_QUANT) AS GRAMAS_ACUCAR_POR_LITRO"
			::Query += " FROM " + RetSQLName ("SD3") + " SD3"
			::Query += " 	 ," + RetSQLName ("SB1") + " SB1"
			::Query += " 	 ," + RetSQLName ("SC2") + " SC2"
			::Query += " WHERE SD3.D_E_L_E_T_ = ''"
			::Query += " AND SD3.D3_FILIAL    = '" + xfilial ("SD3") + "'"
			::Query += " AND SD3.D3_COD       = '1127'"  // acucar
			::Query += " AND SC2.C2_DATRF     BETWEEN '" + dtos (::Param01) + "' AND '" + dtos (::Param02) +"'"
			::Query += " AND SC2.D_E_L_E_T_   = ''"
			::Query += " AND SC2.C2_FILIAL    = SD3.D3_FILIAL"
			::Query += " AND C2_NUM           = substring (SD3.D3_OP, 1, 6)"
			::Query += " AND C2_ITEM          = substring (SD3.D3_OP, 7, 2)"
			::Query += " AND C2_SEQUEN        = substring (SD3.D3_OP, 9, 3)"
			::Query += " AND C2_ITEMGRD       = substring (SD3.D3_OP, 12, 2)"
			::Query += " AND SC2.C2_UM        = 'LT'"
			::Query += " AND SB1.D_E_L_E_T_   = ''"
			::Query += " AND SB1.B1_FILIAL    = '" + xfilial ("SB1") + "'"
			::Query += " AND SB1.B1_COD       = SC2.C2_PRODUTO"
			::Query += " GROUP BY C2_QUJE, C2_UM ,C2_PRODUTO ,B1_DESC ,D3_OP"
			::Query += " HAVING SUM(D3_QUANT) > SC2.C2_QUJE * " + alltrim(::Param03)
			::Query += " ORDER BY D3_OP"
			
		case ::Numero == 47
			::Setores    = 'CUS'
			::Descricao  = "Uva in natura com saldo (fora de período safra)"
			::Sugestao   = ""
			::Query := ""
			::Query += " SELECT "
			::Query += " 	'Uva in natura com saldo (fora de período safra)' AS PROBLEMA"
			::Query += "    ,B2_COD AS PRODUTO"
			::Query += "    ,B1_DESC AS DESCRICAO"
			::Query += "    ,B2_LOCAL AS ALMOX"
			::Query += "    ,B2_QFIM AS QUANT"
			::Query += "    ,B2_VFIM1 AS VALOR"
			::Query += " FROM " + RetSQLName ("SB2") + " SB2"
			::Query += " 	," + RetSQLName ("SB1") + " SB1"
			::Query += " WHERE SB2.D_E_L_E_T_ = ''"
			::Query += " AND SB2.B2_FILIAL = '" + xfilial ("SB2") + "'"
			::Query += " AND SB2.B2_QFIM > 0"
			::Query += " AND SB1.D_E_L_E_T_ = ''"
			::Query += " AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
			::Query += " AND SB1.B1_COD = SB2.B2_COD"
			::Query += " AND SB1.B1_GRUPO = '0400'"
			If substr (::MesAtuEstq , 5, 2) $ '01/02'  // Nos meses de safra tem-se uvas em estoque.
				::Query += " AND 0 = 1"
			Endif
			::Query += " ORDER BY B2_COD"
			
		case ::Numero == 48
			::Setores    = 'CUS'
			if cNumEmp == '0101'  // Nao se aplica as demais filiais.
				::Descricao  = "NF saida/retorno depósito cujos TES não foram trocados p/TES de fechamento"
				::Sugestao   = ""
				::Query := ""
				::Query += " SELECT "	
				::Query += " 	'NF saida/retorno depósito cujos TES não foram trocados p/TES de fechamento' AS PROBLEMA"
				::Query += "    ,'Saida' AS TIPO"
				::Query += "    ,D2_DOC AS NF"
				::Query += "    ,D2_TES AS TES"
				::Query += " FROM " + RetSQLName ("SD2") + " SD2"
				::Query += " 	 ," + RetSQLName ("SF4") + " SF4"
				::Query += " WHERE SF4.D_E_L_E_T_ = ''"
				::Query += " AND SF4.F4_FILIAL = '" + xfilial ("SF4") + "'"
				::Query += " AND SF4.F4_CODIGO = SD2.D2_TES"
				::Query += " AND SF4.F4_VATESFM <> ''"
				::Query += " AND SF4.F4_ESTOQUE = 'N'"
				::Query += " AND SD2.D_E_L_E_T_ = ''"
				::Query += " AND SD2.D2_FILIAL = '" + xfilial ("SD2") + "'"
				::Query += " AND SD2.D2_EMISSAO BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
				::Query += " UNION ALL"
				::Query += " SELECT"
				::Query += " 	'NF saida/retorno depósito cujos TES não foram trocados p/TES de fechamento' AS PROBLEMA"
				::Query += "    ,'Entrada' AS TIPO"
				::Query += "    ,D1_DOC AS NF"
				::Query += "    ,D1_TES AS TES"
				::Query += " FROM " + RetSQLName ("SD1") + " SD1"
				::Query += " 	 ," + RetSQLName ("SF4") + " SF4"
				::Query += " WHERE SF4.D_E_L_E_T_ = ''"
				::Query += " AND SF4.F4_FILIAL = '" + xfilial ("SF4") + "'"
				::Query += " AND SF4.F4_CODIGO = SD1.D1_TES"
				::Query += " AND SF4.F4_VATESFM <> ''"
				::Query += " AND SF4.F4_ESTOQUE = 'N'"
				::Query += " AND SD1.D_E_L_E_T_ = ''"
				::Query += " AND SD1.D1_FILIAL = '" + xfilial ("SD1") + "'"
				::Query += " AND SD1.D1_DTDIGIT BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			else
				::Descricao  = " NÃO SE APLICA A ESTA FILIAL"
			endif
			
		case ::Numero == 49
			::Setores    = 'CUS'
			::Descricao  = "Produto deveria ter estrutura"
			::Sugestao   = ""
			::Query := ""
			::Query += " SELECT"
			::Query += " 	'Produto deveria ter estrutura' AS PROBLEMA"
			::Query += "    ,B1_COD AS PRODUTO"
			::Query += "    ,B1_DESC AS DESCRICAO"
			::Query += "    ,B1_TIPO AS TIPO
			::Query += "    ,B1_VAFORAL AS FORA_DE_LINHA"
			::Query += " FROM " + RetSQLName ("SB1") + " SB1"
			::Query += " 	 ," + RetSQLName ("SD3") + " SD3"
			::Query += " WHERE SD3.D_E_L_E_T_ = ''"
			::Query += " AND SD3.D3_FILIAL = '" + xfilial ("SD3") + "'"
			::Query += " AND SD3.D3_EMISSAO BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " AND SD3.D3_CF LIKE 'PR%'"
			::Query += " AND SB1.D_E_L_E_T_ = ''"
			::Query += " AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
			::Query += " AND SB1.B1_COD = SD3.D3_COD"
			::Query += " AND SB1.B1_TIPO IN ('PA', 'VD')"
			::Query += " AND SB1.B1_MSBLQL <> '1'"
			::Query += " AND NOT EXISTS (SELECT"
			::Query += " 		*"
			::Query += " 	FROM " + RetSQLName ("SG1") + " SG1"
			::Query += " 	WHERE SG1.D_E_L_E_T_ = ''"
			::Query += " 	AND SG1.G1_FILIAL = '" + xfilial ("SG1") + "'"
			::Query += " 	AND SG1.G1_COD = SB1.B1_COD"
			::Query += " 	AND SG1.G1_INI <= '" + dtos (date ()) + "'"
			::Query += " 	AND SG1.G1_FIM >= '" + dtos (date ()) + "')"
			::Query += " ORDER BY B1_TIPO, B1_COD"
			
		case ::Numero == 50
			::Setores    = 'CUS'
			::Descricao  = "Produto deste tipo deveria ter insumos na estrutura"
			::Sugestao   = ""
			::Query := ""
			::Query += " SELECT"
			::Query += " 	'Produto deste tipo deveria ter insumos na estrutura' AS PROBLEMA"
			::Query += "    ,PRODUTOS.B1_TIPO"
			::Query += "    ,PRODUTOS.B1_COD"
			::Query += "    ,PRODUTOS.B1_DESC"
			::Query += " FROM " + RetSQLName ("SB1") + " PRODUTOS"
			::Query += " WHERE PRODUTOS.D_E_L_E_T_ = ''"
			::Query += " AND PRODUTOS.B1_FILIAL = '" + xfilial ("SB1") + "'"
			::Query += " AND PRODUTOS.B1_TIPO = 'VD'"
			::Query += " AND PRODUTOS.B1_MSBLQL != '1'"
			::Query += " AND EXISTS (SELECT"
			::Query += " 		*"
			::Query += " 	FROM " + RetSQLName ("SG1") + " SG1"
			::Query += " 	WHERE SG1.D_E_L_E_T_ = ''"
			::Query += " 	AND SG1.G1_FILIAL = '" + xfilial ("SG1") + "'"
			::Query += " 	AND SG1.G1_COD = PRODUTOS.B1_COD)"
			::Query += " AND NOT EXISTS (SELECT"
			::Query += " 		*"
			::Query += " 	FROM dbo.VA_ESTRUT(PRODUTOS.B1_FILIAL, PRODUTOS.B1_COD, '" + dtos (dDataBase) + "') V"
			::Query += " 		," + RetSQLName ("SB1") + " COMP"
			::Query += " 	WHERE COMP.D_E_L_E_T_ = ''"
			::Query += " 	AND COMP.B1_FILIAL = '" + xfilial ("SB1") + "'"
			::Query += " 	AND COMP.B1_TIPO = 'PS'"
			::Query += " 	AND COMP.B1_COD = V.G1_COMP)"
			::Query += " ORDER BY B1_TIPO, B1_COD"	
			
		case ::Numero == 51
			::Setores    = 'CUS'
			::Descricao  = "Produto deste tipo deveria ter mao de obra na estrutura"
			::Sugestao   = ""
			::Query := ""
			::Query += " SELECT"
			::Query += " 	'Produto deste tipo deveria ter mao de obra na estrutura' AS PROBLEMA"
			::Query += "    ,PRODUTOS.B1_TIPO"
			::Query += "    ,PRODUTOS.B1_COD"
			::Query += "    ,PRODUTOS.B1_DESC"
			::Query += " FROM " + RetSQLName ("SB1") + " PRODUTOS"
			::Query += " WHERE PRODUTOS.D_E_L_E_T_ = ''"
			::Query += " AND PRODUTOS.B1_FILIAL = '" + xfilial ("SB1") + "'"
			::Query += " AND PRODUTOS.B1_TIPO = 'PA'"
			::Query += " AND PRODUTOS.B1_MSBLQL != '1'"
			::Query += " AND EXISTS (SELECT"
			::Query += " 		*"
			::Query += " 	FROM " + RetSQLName ("SG1") + " SG1"
			::Query += " 	WHERE SG1.D_E_L_E_T_ = ''"
			::Query += " 	AND SG1.G1_FILIAL = '" + xfilial ("SG1") + "'"
			::Query += " 	AND SG1.G1_COD = PRODUTOS.B1_COD)"
			::Query += " AND NOT EXISTS (SELECT"
			::Query += " 		*"
			::Query += " 	FROM dbo.VA_ESTRUT(PRODUTOS.B1_FILIAL, PRODUTOS.B1_COD, ' + dtos (dDataBase) + ') V"
			::Query += " 		," + RetSQLName ("SB1") + " COMP"
			::Query += " 	WHERE COMP.D_E_L_E_T_ = ''"
			::Query += " 	AND COMP.B1_FILIAL = '" + xfilial ("SB1") + "'"
			::Query += " 	AND COMP.B1_TIPO = 'MO'"
			::Query += " 	AND COMP.B1_COD = V.G1_COMP)"
			::Query += " AND EXISTS (SELECT"
			::Query += " 		*"
			::Query += " 	FROM " + RetSQLName ("SD3") + " SD3"
			::Query += " 	WHERE SD3.D_E_L_E_T_ = ''"
			::Query += " 	AND SD3.D3_FILIAL = '" + xfilial ("SD3") + "'"
			::Query += " 	AND SD3.D3_EMISSAO BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " 	AND SD3.D3_CF LIKE 'PR%'"
			::Query += " 	AND SD3.D3_COD = PRODUTOS.B1_COD)"
			::Query += " ORDER BY B1_TIPO, B1_COD"	
			
		case ::Numero == 52
			::Setores    = 'CUS'
			::Descricao  = "Produto tipo BN com saldo para fechamento"
			::Sugestao   = ""
			::Query := ""
			::Query += " SELECT"
			::Query += " 	'Produto tipo BN com saldo para fechamento' AS PROBLEMA"
			::Query += "    ,B2_COD AS PRODUTO"
			::Query += "    ,B1_DESC AS DESCRICAO"
			::Query += "    ,B1_TIPO AS TIPO"
			::Query += "    ,B2_LOCAL AS ALMOX"
			::Query += "    ,B2_QFIM AS QUANT"
			::Query += "    ,B2_VFIM1 AS VALOR"
			::Query += " FROM " + RetSQLName ("SB2") + "  SB2"
			::Query += " 	 ," + RetSQLName ("SB1") + "  SB1"
			::Query += " WHERE SB2.D_E_L_E_T_ = ''"
			::Query += " AND SB2.B2_FILIAL = '" + xfilial ("SB2") + "'"
			::Query += " AND (SB2.B2_QFIM > 0"
			::Query += " OR B2_VFIM1 > 0)"
			::Query += " AND SB1.D_E_L_E_T_ = ''"
			::Query += " AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
			::Query += " AND SB1.B1_COD = SB2.B2_COD"
			::Query += " AND SB1.B1_TIPO = 'BN'"
			::Query += " ORDER BY B2_COD"
			
		case ::Numero == 53
			::Setores    = 'CUS'
			::Descricao  = "NF entrada tem BN sem OP ou OP inconsistente"
			::Sugestao   = ""
			::Query := ""
			::Query += " SELECT"
			::Query += " 	'NF entrada tem BN sem OP ou OP inconsistente' AS PROBLEMA"
			::Query += "    ,D1_COD AS CODIGO"
			::Query += "    ,B1_DESC AS DESCRICAO"
			::Query += "    ,B1_TIPO AS TIPO"
			::Query += "    ,D1_QUANT AS QUANT"
			::Query += "    ,dbo.VA_DTOC(D1_DTDIGIT) AS DATA"
			::Query += "    ,D1_DOC AS NF"
			::Query += "    ,D1_FORNECE AS FORNEC"
			::Query += "    ,D1_OP AS OP"
			::Query += " FROM " + RetSQLName ("SD1") + "  SD1"
			::Query += " 	 ," + RetSQLName ("SF4") + "  SF4"
			::Query += " 	 ," + RetSQLName ("SB1") + "  SB1"
			::Query += " WHERE SD1.D_E_L_E_T_ = ''"
			::Query += " AND SD1.D1_FILIAL = '" + xfilial ("SD1") + "'"
			::Query += " AND SD1.D1_DTDIGIT BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " AND SD1.D1_TP = 'BN'"
			::Query += " AND NOT EXISTS (SELECT"
			::Query += " 		*"
			::Query += " 	FROM " + RetSQLName ("SD3") + "  SD3"
			::Query += " 	WHERE SD3.D_E_L_E_T_ = ''"
			::Query += " 	AND SD3.D3_EMISSAO >= '" + ::MesAtuEstq + "01' "
			::Query += " 	AND SD3.D3_OP = SD1.D1_OP"
			::Query += " 	AND SD3.D3_COD = SD1.D1_COD"
			::Query += " 	AND SD3.D3_QUANT = SD1.D1_QUANT"
			::Query += " 	AND SD3.D3_CF LIKE 'RE%'"
			::Query += " 	AND SD3.D3_ESTORNO != 'S')"
			::Query += " AND SF4.D_E_L_E_T_ = ''"
			::Query += " AND SF4.F4_FILIAL = '" + xfilial ("SF4") + "'"
			::Query += " AND SF4.F4_CODIGO = SD1.D1_TES"
			::Query += " AND SF4.F4_ESTOQUE = 'S'"
			::Query += " AND SB1.D_E_L_E_T_ = ''"
			::Query += " AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
			::Query += " AND SB1.B1_COD = SD1.D1_COD"
			::Query += " ORDER BY D1_COD, D1_DOC"	
			
		case ::Numero == 54
			::Setores    = 'CUS'
			::Descricao  = "OP sem mao de obra"
			::Sugestao   = ""
			::Query := ""
			::Query += " SELECT"
			::Query += " 	'OP sem mao de obra' AS PROBLEMA"
			::Query += "    ,V.FILIAL"
			::Query += "    ,V.OP"
			::Query += "    ,V.TIPO_PRODUTO"
			::Query += "    ,V.PROD_FINAL"
			::Query += "    ,V.DESC_PROD_FINAL"
			::Query += "    ,SUM(LITROS) AS LITROS_PRODUZIDOS"
			::Query += "    ,dbo.VA_DTOC(V.ENCERRAMENTO) AS ENCERRAMENTO"
			::Query += "    ,dbo.VA_DTOC(MAX(V.DATA)) AS ULTIMO_MOVTO"
			::Query += " FROM VA_VDADOS_OP V"
			::Query += " WHERE V.FILIAL = '" + cFilAnt + "'"
			::Query += " AND V.DATA BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " AND V.TIPO_MOVTO = 'P'"
			::Query += " AND NOT EXISTS (SELECT"
			::Query += " 		*"
			::Query += " 	FROM VA_VDADOS_OP V2"
			::Query += " 	WHERE V2.FILIAL = V.FILIAL"
			::Query += " 	AND V2.OP = V.OP"
			::Query += " 	AND V2.TIPO_MOVTO = 'C'"
			::Query += " 	AND V2.TIPO_PRODUTO IN ('MO', 'BN'))"
			::Query += " GROUP BY V.FILIAL"
			::Query += " 		,V.OP"
			::Query += " 		,V.TIPO_PRODUTO"
			::Query += " 		,V.PROD_FINAL"
			::Query += " 		,V.DESC_PROD_FINAL"
			::Query += " 		,V.ENCERRAMENTO"
			::Query += " ORDER BY V.OP"		
			
		case ::Numero == 55
			::Setores    = 'CUS'
			::Descricao  = "Centro de custo nao pertence a esta filial"
			::Query := ""
			::Query += " SELECT"
			::Query += " 	'Centro de custo nao pertence a esta filial' AS PROBLEMA"
			::Query += "    ,D3_FILIAL AS FILIAL"
			::Query += "    ,D3_OP AS OP"
			::Query += "    ,D3_EMISSAO AS DATA"
			::Query += "    ,D3_COD AS CODIGO"
			::Query += "    ,D3_QUANT AS QUANT"
			::Query += " FROM " + RetSQLName ("SD3") + "  SD3"
			::Query += " WHERE D_E_L_E_T_ = ''"
			::Query += " AND D3_FILIAL = '" + cFilAnt + "'"
			::Query += " AND D3_EMISSAO BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " AND D3_TIPO IN ('MO', 'GF', 'AP')"
			if ::MesAtuEstq <= '201511'
				::Query += " 	    AND ((D3_FILIAL  = '03' AND SUBSTRING (D3_COD, 4, 3) != '502')"
				::Query += " 	    OR (D3_FILIAL != '03' AND SUBSTRING (D3_COD, 4, 3)  = '502'))"
			else
				::Query += " AND SUBSTRING(D3_COD, 4, 2) != '" + cFilAnt + "'"
			endif
			::Query += " ORDER BY D3_OP"
			
		case ::Numero == 56
			::Setores    = 'CUS'
			::GrupoPerg  = "U_VALID056"
			::ValidPerg (_lDefault)
			if cNumEmp == '0101'  // Nao se aplica as demais filiais.
				::Descricao  = "Produto negativo no almox. retiro simbolico para matriz"
				::Sugestao   = ""
				::Query := ""
				::Query += " SELECT "
				::Query += " 	'Produto negativo no almox. retiro simbolico para matriz' AS PROBLEMA"
				::Query += "    ,B2_FILIAL AS Filial"
				::Query += "    ,B2_LOCAL AS Almox"
				::Query += "    ,B2_COD AS Produto"
				::Query += "    ,B1_DESC AS Descricao"
				::Query += "    ,B2_QFIM AS Sld_quant"
				::Query += "    ,B2_VFIM1 AS Sld_valor"
				::Query += " FROM " + RetSQLName ("SB2") + " SB2"
				::Query += " 	 ," + RetSQLName ("SB1") + " SB1"
				::Query += " WHERE SB2.D_E_L_E_T_ = ''"
				::Query += " AND SB2.B2_FILIAL IN (SELECT"
				::Query += " 		X5_CHAVE"
				::Query += " 	FROM " + RetSQLName ("SX5") + " SX5"
				::Query += " 	WHERE SX5.D_E_L_E_T_ = ''"
				::Query += " 	AND SX5.X5_FILIAL = '" + xfilial ("SX5") + "'"
				::Query += " 	AND SX5.X5_TABELA = 'ZS')"
				::Query += " AND SB2.B2_LOCAL = '" + ::Param01 + "'"
				::Query += " AND (SB2.B2_QFIM < 0"
				::Query += " OR B2_VFIM1 < 0)"
				::Query += " AND SB1.D_E_L_E_T_ = ' '"
				::Query += " AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
				::Query += " AND SB1.B1_COD = B2_COD"
				::Query += " ORDER BY B2_FILIAL, B2_LOCAL, B2_COD"
			else
				::Descricao  = " NÃO SE APLICA A ESTA FILIAL"
			endif		
			
		case ::Numero == 57
			::Descricao  = "Transferencia entre almox.ref.NF cujo TES ja movimentou estoque"
			::Setores    = 'CUS'
			::Query := ""
			::Query += " SELECT"
			::Query += " 	'Transferencia entre almox.ref.NF cujo TES ja movimentou estoque' AS PROBLEMA"
			::Query += "    ,D3_FILIAL AS Filial"
			::Query += "    ,D3_LOCAL AS Almox"
			::Query += "    ,D3_COD AS Produto"
			::Query += "    ,B1_DESC AS Descricao"
			::Query += "    ,D3_QUANT AS QUANT"
			::Query += "    ,D3_EMISSAO AS DATA"
			::Query += "    ,D3_VACFNRD AS REF_CLIFOR"
			::Query += "    ,D3_VALJNRD AS REF_LOJA"
			::Query += "    ,D3_VANFRD AS REF_NF"
			::Query += "    ,D3_VASERRD AS REF_SERIE_NF"
			::Query += "    ,D3_VAITNRD AS REF_ITEM_NF"
			::Query += " FROM " + RetSQLName ("SD3") + " SD3"
			::Query += " 	 ," + RetSQLName ("SB1") + " SB1"
			::Query += " WHERE SD3.D_E_L_E_T_ = ''"
			::Query += " AND SD3.D3_FILIAL = '" + xfilial ("SD3") + "'"
			::Query += " AND SD3.D3_CF LIKE 'RE%'"
			::Query += " AND SD3.D3_ESTORNO != 'S'"
			::Query += " AND SD3.D3_VANFRD != ''"
			::Query += " AND SB1.D_E_L_E_T_ = ''"
			::Query += " AND SB1.B1_FILIAL = ' '"
			::Query += " AND SB1.B1_COD = D3_COD"
			::Query += " AND SD3.D3_EMISSAO >= '" + ::MesAtuEstq + "01'" 
			::Query += " AND (EXISTS (SELECT"
			::Query += " 		*"
			::Query += " 	FROM " + RetSQLName ("SD2") + " SD2"
			::Query += " 		," + RetSQLName ("SF4") + " SF4"
			::Query += " 	WHERE SD2.D_E_L_E_T_ = ''"
			::Query += " 	AND SD2.D2_FILIAL = D3_FILIAL"
			::Query += " 	AND SD2.D2_DOC = D3_VANFRD"
			::Query += " 	AND SD2.D2_SERIE = D3_VASERRD"
			::Query += " 	AND SD2.D2_ITEM = D3_VAITNRD"
			::Query += " 	AND SF4.D_E_L_E_T_ = ''"
			::Query += " 	AND SF4.F4_FILIAL = '" + xfilial ("SF4") + "'"
			::Query += " 	AND SF4.F4_CODIGO = SD2.D2_TES"
			::Query += " 	AND SF4.F4_ESTOQUE != 'N')"
			::Query += " OR EXISTS (SELECT"
			::Query += " 		*"
			::Query += " 	FROM " + RetSQLName ("SD1") + " SD1"
			::Query += " 		," + RetSQLName ("SF4") + " SF4"
			::Query += " 	WHERE SD1.D_E_L_E_T_ = ''"
			::Query += " 	AND SD1.D1_FILIAL = D3_FILIAL"
			::Query += " 	AND SD1.D1_FORNECE = D3_VACFNRD"
			::Query += " 	AND SD1.D1_LOJA = D3_VALJNRD"
			::Query += " 	AND SD1.D1_DOC = D3_VANFRD"
			::Query += " 	AND SD1.D1_SERIE = D3_VASERRD"
			::Query += " 	AND SD1.D1_ITEM = D3_VAITNRD"
			::Query += " 	AND SF4.D_E_L_E_T_ = ''"
			::Query += " 	AND SF4.F4_FILIAL = '" + xfilial ("SF4") + "'"
			::Query += " 	AND SF4.F4_CODIGO = SD1.D1_TES"
			::Query += " 	AND SF4.F4_ESTOQUE != 'N')"
			::Query += " )"
			::Query += " ORDER BY D3_FILIAL, D3_LOCAL, D3_COD, D3_EMISSAO"	
			
		case ::Numero == 58
			::Setores    = 'CUS'
			::Descricao  = "Inconsistencia transferencia alm.3os X NF saida"
			::Query := ""
			::Query += " WITH D3"
			::Query += " AS"
			::Query += " (SELECT"
			::Query += " 		D3_EMISSAO"
			::Query += " 	   ,D3_COD"
			::Query += " 	   ,D3_LOCAL"
			::Query += " 	   ,SUM(D3_QUANT) AS QUANT_SD3"
			::Query += " 	   ,D3_CF"
			::Query += " 	   ,D3_VACFNRD"
			::Query += " 	   ,D3_VALJNRD"
			::Query += " 	   ,D3_VANFRD"
			::Query += " 	   ,D3_VASERRD"
			::Query += " 	   ,D3_VAITNRD"
			::Query += " 	FROM " + RetSQLName ("SD3") + " SD3"
			::Query += " 	WHERE SD3.D_E_L_E_T_ = ''"
			::Query += " 	AND SD3.D3_FILIAL = '" + xfilial ("SD3") + "'"
			::Query += " 	AND SD3.D3_ESTORNO != 'S'"
			::Query += " 	AND SD3.D3_VANFRD != ''"
			::Query += " 	AND SD3.D3_CF = 'DE4'"
			::Query += " 	AND SD3.D3_EMISSAO BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " 	AND SD3.D3_LOCAL IN (SELECT DISTINCT"
			::Query += " 			ZX5.ZX5_03ARMZ"
			::Query += " 		FROM " + RetSQLName ("ZX5") + " ZX5"
			::Query += " 		WHERE ZX5.D_E_L_E_T_ = ''"
			::Query += " 		AND ZX5.ZX5_FILIAL = (SELECT"
			::Query += " 				CASE ZX5_MODO"
			::Query += " 					WHEN 'C' THEN '  '"
			::Query += " 					ELSE '01'"
			::Query += " 				END"
			::Query += " 			FROM " + RetSQLName ("ZX5") + ""
			::Query += " 			WHERE D_E_L_E_T_ = ''"
			::Query += " 			AND ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
			::Query += " 			AND ZX5_TABELA = '00'"
			::Query += " 			AND ZX5_CHAVE  = '03')"
			::Query += " 		AND ZX5.ZX5_TABELA = '03')"
			::Query += " 	GROUP BY SD3.D3_EMISSAO"
			::Query += " 			,SD3.D3_COD"
			::Query += " 			,SD3.D3_LOCAL"
			::Query += " 			,SD3.D3_CF"
			::Query += " 			,SD3.D3_VACFNRD"
			::Query += " 			,SD3.D3_VALJNRD"
			::Query += " 			,SD3.D3_VANFRD"
			::Query += " 			,SD3.D3_VASERRD"
			::Query += " 			,SD3.D3_VAITNRD),"
			::Query += " D2"
			::Query += " AS"
			::Query += " (SELECT"
			::Query += " 		D2_EMISSAO"
			::Query += " 	   ,D2_COD"
			::Query += " 	   ,ZX5.ZX5_03ARMZ"
			::Query += " 	   ,SUM(D2_QUANT) AS QUANT_SD2"
			::Query += " 	   ,D2_CLIENTE"
			::Query += " 	   ,D2_LOJA"
			::Query += " 	   ,D2_DOC"
			::Query += " 	   ,D2_SERIE"
			::Query += " 	   ,D2_ITEM"
			::Query += " 	FROM " + RetSQLName ("SD2") + " SD2"
			::Query += " 		," + RetSQLName ("ZX5") + " ZX5"
			::Query += " 	WHERE ZX5.D_E_L_E_T_ = ''"
			::Query += " 	AND ZX5.ZX5_FILIAL = (SELECT"
			::Query += " 			CASE ZX5_MODO"
			::Query += " 				WHEN 'C' THEN '  '"
			::Query += " 				ELSE '" + cFilAnt + "'"
			::Query += " 			END"
			::Query += " 		FROM ZX5010"
			::Query += " 		WHERE D_E_L_E_T_ = ''"
			::Query += " 		AND ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
			::Query += " 		AND ZX5_TABELA = '00'"
			::Query += " 		AND ZX5_CHAVE = '03')"
			::Query += " 	AND ZX5.ZX5_TABELA = '03'"
			::Query += " 	AND ((ZX5.ZX5_03TIPO = 'F'"
			::Query += " 	AND SD2.D2_TIPO IN ('B', 'D'))"
			::Query += " 	OR (ZX5.ZX5_03TIPO = 'C'"
			::Query += " 	AND SD2.D2_TIPO NOT IN ('B', 'D')))"
			::Query += " 	AND ZX5.ZX5_03COD = SD2.D2_CLIENTE"
			::Query += " 	AND ZX5.ZX5_03LOJA = SD2.D2_LOJA"
			::Query += " 	AND SD2.D_E_L_E_T_ = ''"
			::Query += " 	AND SD2.D2_FILIAL = '" + xfilial ("SD2") + "'"
			::Query += " 	AND SD2.D2_EMISSAO BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " 	GROUP BY SD2.D2_EMISSAO"
			::Query += " 			,SD2.D2_COD"
			::Query += " 			,ZX5.ZX5_03ARMZ"
			::Query += " 			,SD2.D2_CLIENTE"
			::Query += " 			,SD2.D2_LOJA"
			::Query += " 			,SD2.D2_DOC"
			::Query += " 			,SD2.D2_SERIE"
			::Query += " 			,SD2.D2_ITEM)"
			::Query += " SELECT"
			::Query += " 	'Inconsistencia transferencia alm.3os X NF saida' AS Problema"
			::Query += "    ,D3.*"
			::Query += "    ,D2.*"
			::Query += " FROM D3"
			::Query += " FULL OUTER JOIN D2"
			::Query += " 	ON (D3_VACFNRD = D2_CLIENTE"
			::Query += " 			AND D3_VALJNRD = D2_LOJA"
			::Query += " 			AND D3_VANFRD  = D2_DOC"
			::Query += " 			AND D3_VASERRD = D2_SERIE"
			::Query += " 			AND D3_VAITNRD = D2_ITEM"
			::Query += " 			AND D3_LOCAL = ZX5_03ARMZ)"
			::Query += " WHERE ISNULL(D2.QUANT_SD2, 0) != ISNULL(D3.QUANT_SD3, 0)"
			::Query += " ORDER BY D3_EMISSAO, D2_EMISSAO"	
			
		case ::Numero == 59
			::Setores    = 'CUS'
			::Descricao  = "Inconsistencia transferencia almox.3os X NF entrada"
			::Ativa := .F.
			::Query := ""
			::Query += " WITH D3"
			::Query += " AS"
			::Query += " (SELECT"
			::Query += " 		D3_EMISSAO"
			::Query += " 	   ,D3_COD"
			::Query += " 	   ,D3_LOCAL"
			::Query += " 	   ,SUM(D3_QUANT) AS QUANT_SD3"
			::Query += " 	   ,D3_CF"
			::Query += " 	   ,D3_VACFNRD"
			::Query += " 	   ,D3_VALJNRD"
			::Query += " 	   ,D3_VANFRD"
			::Query += " 	   ,D3_VASERRD"
			::Query += " 	   ,D3_VAITNRD"
			::Query += " 	FROM " + RetSQLName ("SD3") + " SD3"
			::Query += " 	WHERE SD3.D_E_L_E_T_ = ''"
			::Query += " 	AND SD3.D3_FILIAL = '" + xfilial ("SD3") + "'"
			::Query += " 	AND SD3.D3_ESTORNO != 'S'"
			::Query += " 	AND SD3.D3_VANFRD != ''"
			::Query += " 	AND SD3.D3_CF = 'RE4'"
			::Query += " 	AND SD3.D3_EMISSAO BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " 	AND SD3.D3_LOCAL IN (SELECT DISTINCT"
			::Query += " 			ZX5.ZX5_03ARMZ"
			::Query += " 		FROM " + RetSQLName ("ZX5") + "  ZX5"
			::Query += " 		WHERE ZX5.D_E_L_E_T_ = ''"
			::Query += " 		AND ZX5.ZX5_FILIAL = (SELECT"
			::Query += " 				CASE ZX5_MODO"
			::Query += " 					WHEN 'C' THEN '  '"
			::Query += " 					ELSE ' "+ cFilAnt + "'"
			::Query += " 				END"
			::Query += " 			FROM ZX5010"
			::Query += " 			WHERE D_E_L_E_T_ = ''"
			::Query += " 			AND ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
			::Query += " 			AND ZX5_TABELA = '00'"
			::Query += " 			AND ZX5_CHAVE = '03')"
			::Query += " 		AND ZX5.ZX5_TABELA = '03')"
			::Query += " 	GROUP BY SD3.D3_EMISSAO"
			::Query += " 			,SD3.D3_COD"
			::Query += " 			,SD3.D3_LOCAL"
			::Query += " 			,SD3.D3_CF"
			::Query += " 			,SD3.D3_VACFNRD"
			::Query += " 			,SD3.D3_VALJNRD"
			::Query += " 			,SD3.D3_VANFRD"
			::Query += " 			,SD3.D3_VASERRD"
			::Query += " 			,SD3.D3_VAITNRD),"
			::Query += " D1"
			::Query += " AS"
			::Query += " (SELECT"
			::Query += " 		D1_DTDIGIT"
			::Query += " 	   ,D1_COD"
			::Query += " 	   ,ZX5.ZX5_03ARMZ"
			::Query += " 	   ,SUM(D1_QUANT) AS QUANT_SD1"
			::Query += " 	   ,D1_FORNECE"
			::Query += " 	   ,D1_LOJA"
			::Query += " 	   ,D1_DOC"
			::Query += " 	   ,D1_SERIE"
			::Query += " 	   ,D1_ITEM"
			::Query += " 	FROM " + RetSQLName ("SD1") + "  SD1"
			::Query += " 		," + RetSQLName ("ZX5") + "  ZX5"
			::Query += " 	WHERE ZX5.D_E_L_E_T_ = ''"
			::Query += " 	AND ZX5.ZX5_FILIAL = (SELECT"
			::Query += " 			CASE ZX5_MODO"
			::Query += " 				WHEN 'C' THEN '  '"
			::Query += " 				ELSE ' "+ cFilAnt + "'"
			::Query += " 			END"
			::Query += " 		FROM ZX5010"
			::Query += " 		WHERE D_E_L_E_T_ = ''"
			::Query += " 		AND ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
			::Query += " 		AND ZX5_TABELA = '00'"
			::Query += " 		AND ZX5_CHAVE = '03')"
			::Query += " 	AND ZX5.ZX5_TABELA = '03'"
			::Query += " 	AND ((ZX5.ZX5_03TIPO = 'F'"
			::Query += " 	AND SD1.D1_TIPO NOT IN ('B', 'D'))"
			::Query += " 	OR (ZX5.ZX5_03TIPO = 'C'"
			::Query += " 	AND SD1.D1_TIPO IN ('B', 'D')))"
			::Query += " 	AND ZX5.ZX5_03COD = SD1.D1_FORNECE"
			::Query += " 	AND ZX5.ZX5_03LOJA = SD1.D1_LOJA"
			::Query += " 	AND SD1.D_E_L_E_T_ = ''"
			::Query += " 	AND SD1.D1_FILIAL = '" + xfilial ("SD1") + "'"
			::Query += " 	AND SD1.D1_DTDIGIT BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " 	GROUP BY SD1.D1_DTDIGIT"
			::Query += " 			,SD1.D1_COD"
			::Query += " 			,ZX5.ZX5_03ARMZ"
			::Query += " 			,SD1.D1_FORNECE"
			::Query += " 			,SD1.D1_LOJA"
			::Query += " 			,SD1.D1_DOC"
			::Query += " 			,SD1.D1_SERIE"
			::Query += " 			,SD1.D1_ITEM)"
			::Query += " SELECT"
			::Query += " 	'Inconsistencia transferencia almox.3os X NF entrada' AS Problema"
			::Query += "    ,D3.*"
			::Query += "    ,D1.*"
			::Query += " FROM D3"
			::Query += " FULL OUTER JOIN D1"
			::Query += " 	ON (D3_VACFNRD = D1_FORNECE"
			::Query += " 			AND D3_VALJNRD = D1_LOJA"
			::Query += " 			AND D3_VANFRD = D1_DOC"
			::Query += " 			AND D3_VASERRD = D1_SERIE"
			::Query += " 			AND D3_VAITNRD = D1_ITEM"
			::Query += " 			AND D3_LOCAL = ZX5_03ARMZ)"
			::Query += " WHERE ISNULL(D1.QUANT_SD1, 0) != ISNULL(D3.QUANT_SD3, 0)"
			::Query += " ORDER BY D3_EMISSAO, D1_DTDIGIT"	
			
		case ::Numero == 60
			::Setores    = 'CUS'
			::Descricao  = "Transferencia entre almox. amarrada a diferentes itens da NF"
			::Query := ""
			::Query += " SELECT"
			::Query += " 	'Transferencia entre almox. amarrada a diferentes itens da NF' AS PROBLEMA"
			::Query += "    ,D3_FILIAL AS Filial"
			::Query += "    ,D3_LOCAL AS Almox"
			::Query += "    ,D3_COD AS Produto"
			::Query += "    ,B1_DESC AS Descricao"
			::Query += "    ,D3_QUANT AS QUANT"
			::Query += "    ,D3_EMISSAO AS DATA"
			::Query += "    ,D3_VACFNRD AS REF_CLIFOR"
			::Query += "    ,D3_VALJNRD AS REF_LOJA"
			::Query += "    ,D3_VANFRD AS REF_NF"
			::Query += "    ,D3_VASERRD AS REF_SERIE_NF"
			::Query += "    ,D3_VAITNRD AS REF_ITEM_NF"
			::Query += " FROM " + RetSQLName ("SD3") + " SD3"
			::Query += " 	 ," + RetSQLName ("SB1") + " SB1"
			::Query += " WHERE SD3.D_E_L_E_T_ = ''"
			::Query += " AND SD3.D3_FILIAL = '" + xfilial ("SD3") + "'"
			::Query += " AND SD3.D3_NUMSEQ IN (SELECT"
			::Query += " 		D3_NUMSEQ"
			::Query += " 	FROM " + RetSQLName ("SD3") + " SD3"
			::Query += " 	WHERE SD3.D_E_L_E_T_ = ''"
			::Query += " 	AND SD3.D3_FILIAL = '" + xfilial ("SD3") + "'"
			::Query += " 	AND SUBSTRING(SD3.D3_CF, 3, 1) = '4'"
			::Query += " 	AND SD3.D3_ESTORNO != 'S'"
			::Query += " 	AND SD3.D3_EMISSAO >= '" + ::MesAtuEstq + "01'" 
			::Query += " 	GROUP BY SD3.D3_NUMSEQ"
			::Query += " 	HAVING COUNT(DISTINCT D3_VACFNRD + D3_VALJNRD + D3_VANFRD + D3_VASERRD + D3_VAITNRD) > 1)"
			::Query += " AND SB1.D_E_L_E_T_ = ''"
			::Query += " AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
			::Query += " AND SB1.B1_COD = SD3.D3_COD"
			::Query += " ORDER BY D3_FILIAL, D3_LOCAL, D3_COD, D3_NUMSEQ"
			
			
		case ::Numero == 61
			::Setores    = 'CUS'
			::Descricao  = "Campo D3_NUMSEQ não pode ter repetição"
			::Query := ""
			::Query += " SELECT"
			::Query += " 	'Campo D3_NUMSEQ nao pode ter repeticao' AS PROBLEMA"
			::Query += "    ,D3_NUMSEQ"
			::Query += " FROM " + RetSQLName ("SD3")
			::Query += " WHERE D_E_L_E_T_ = ''"
			::Query += " AND D3_FILIAL = '" + xfilial ("SD3") + "'"
			::Query += " AND D3_EMISSAO BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " AND D3_ESTORNO <> 'S'"
			::Query += " AND D3_CF IN ('RE4', 'DE4')"
			::Query += " GROUP BY D3_NUMSEQ"
			::Query += " HAVING COUNT(*) > 2"
			::Query += " ORDER BY D3_NUMSEQ"			
		
		case ::Numero == 62
			::Setores    = 'CUS'
			::Descricao  = "Movimentação com data futura"
			::Query := ""
			::Query += " SELECT"
			::Query += "	'Movimentacao com data futura' AS PROBLEMA"
			::Query += "    ,ORIGEM"
			::Query += "    ,EMISSAO"
			::Query += "    ,DOC"
			::Query += "    ,OP
			::Query += " FROM (SELECT"
			::Query += " 		'SD3' AS ORIGEM"
			::Query += " 	   ,D3_EMISSAO AS EMISSAO"
			::Query += " 	   ,D3_DOC AS DOC"
			::Query += " 	   ,D3_OP AS OP"
			::Query += " 	FROM " + RetSQLName ("SD3")
			::Query += " 	WHERE D_E_L_E_T_ = ''"
			::Query += " 	AND D3_FILIAL = '" + xfilial ("SD3") + "'"
			::Query += " 	AND D3_EMISSAO > '" + dtos (date ()) + "'"
			::Query += " 	AND D3_ESTORNO <> 'S'"
			::Query += " 	UNION ALL"
			::Query += " 	SELECT"
			::Query += " 		'SD2'"
			::Query += " 	   ,D2_EMISSAO"
			::Query += " 	   ,D2_DOC"
			::Query += " 	   ,''"
			::Query += " 	FROM " + RetSQLName ("SD2")
			::Query += " 	WHERE D_E_L_E_T_ = ''"
			::Query += " 	AND D2_FILIAL = '" + xfilial ("SD2") + "'"
			::Query += " 	AND D2_EMISSAO > '" + dtos (date ()) + "'"
			::Query += " 	UNION ALL"
			::Query += " 	SELECT"
			::Query += " 		'SD1'"
			::Query += " 	   ,D1_DTDIGIT"
			::Query += " 	   ,D1_DOC"
			::Query += " 	   ,''"
			::Query += " 	FROM " + RetSQLName ("SD1")
			::Query += " 	WHERE D_E_L_E_T_ = ''"
			::Query += " 	AND D1_FILIAL = '" + xfilial ("SD1") + "'"
			::Query += " 	AND D1_DTDIGIT > '" + dtos (date ()) + "'"
			::Query += " 	) AS TODOS"
			
		case ::Numero == 63
			::Setores    = 'CUS'
			::Descricao  = "OP com multiplos custos de producao"
			::Query := ""
			::Query += " WITH C"
			::Query += " AS"
			::Query += " (SELECT"
			::Query += " 		SD3.D3_OP AS OP"
			::Query += " 	   ,SC2.C2_VAOPESP AS TIPO_OP"
			::Query += " 	   ,SD3.D3_COD AS PRODUTO"
			::Query += " 	   ,RTRIM(SB1.B1_DESC) AS DESCRICAO"
			::Query += " 	   ,SD3.D3_EMISSAO AS DATA_MOVTO"
			::Query += " 	   ,ROUND(SD3.D3_CUSTO1 / (SD3.D3_QUANT + SD3.D3_PERDA), 4) AS CUSTO_UNIT"
			::Query += " 	   ,SD3.D3_NUMSEQ AS SEQUENCIAL"
			::Query += " 	FROM " + RetSQLName ("SD3") + "  SD3"   
			::Query += " 		," + RetSQLName ("SC2") + "  SC2" 
			::Query += " 		," + RetSQLName ("SB1") + "  SB1" 
			::Query += " 	WHERE SB1.D_E_L_E_T_ = ''"
			::Query += " 	AND SB1.B1_FILIAL = ' '"
			::Query += " 	AND SB1.B1_COD = SD3.D3_COD"
			::Query += " 	AND SC2.D_E_L_E_T_ = ''"
			::Query += " 	AND SC2.C2_FILIAL = '" + xfilial ("SC2") + "'"
			::Query += " 	AND SC2.C2_NUM = SUBSTRING(SD3.D3_OP, 1, 6)"
			::Query += " 	AND SC2.C2_ITEM = SUBSTRING(SD3.D3_OP, 7, 2)"
			::Query += " 	AND SC2.C2_SEQUEN = SUBSTRING(SD3.D3_OP, 9, 3)"
			::Query += " 	AND SC2.C2_ITEMGRD = SUBSTRING(SD3.D3_OP, 12, 2)"
			::Query += " 	AND SD3.D_E_L_E_T_ = ''"
			::Query += " 	AND SD3.D3_FILIAL = '" + xfilial ("SD3") + "'"
			::Query += " 	AND SD3.D3_ESTORNO <> 'S'"
			::Query += " 	AND SD3.D3_CF LIKE 'PR%'"
			::Query += " 	AND SD3.D3_EMISSAO BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " 	AND SD3.D3_OP IN (SELECT DISTINCT"
			::Query += " 			M.D3_OP"
			::Query += " 		FROM " + RetSQLName ("SD3") + " M"
			::Query += " 		WHERE M.D_E_L_E_T_ = ''"
			::Query += " 		AND M.D3_FILIAL = '" + xfilial ("SD3") + "'"
			::Query += " 		AND M.D3_ESTORNO <> 'S'"
			::Query += " 		AND M.D3_CF LIKE 'PR%'"
			::Query += " 		AND M.D3_EMISSAO BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " 		GROUP BY M.D3_OP"
			::Query += " 				,SUBSTRING(M.D3_EMISSAO, 1, 6)"
			::Query += " 		HAVING COUNT(DISTINCT M.D3_CUSTO1 / (M.D3_QUANT + M.D3_PERDA)) > 1))"
			::Query += " SELECT"
			::Query += " 	'OP com multiplos custos de producao' AS PROBLEMA"
			::Query += "    ,OP"
			::Query += "    ,MIN(CUSTO_UNIT) AS MENOR_CUSTO"
			::Query += "    ,MAX(CUSTO_UNIT) AS MAIOR_CUSTO"
			::Query += " FROM C"
			::Query += " GROUP BY OP"
			::Query += " HAVING MIN(CUSTO_UNIT) < MAX(CUSTO_UNIT) * 0.9"
			::Query += " ORDER BY OP"		
				
		case ::Numero == 64
			::Setores    = 'CUS'
			::Descricao  = "OP com litragem inconsistente"
			::Query := ""
			::Query += " WITH C"
			::Query += " AS"
			::Query += " (SELECT"
			::Query += " 		'Litragem inconsistente' AS PROBLEMA"
			::Query += " 	   ,V.FILIAL"
			::Query += " 	   ,V.OP"
			::Query += " 	   ,V.PROD_FINAL"
			::Query += " 	   ,V.DESC_PROD_FINAL"
			::Query += " 	   ,SUM(CASE"
			::Query += " 			WHEN V.TIPO_MOVTO = 'P' THEN V.QUANT_REAL"
			::Query += " 			ELSE 0"
			::Query += " 		END) AS LITROS_PRODUZIDOS"
			::Query += " 	   ,SUM(CASE"
			::Query += " 			WHEN V.TIPO_MOVTO = 'C' THEN V.QUANT_REAL"
			::Query += " 			ELSE CASE"
			::Query += " 					WHEN V.TIPO_MOVTO = 'D' THEN V.QUANT_REAL * -1"
			::Query += " 					ELSE 0"
			::Query += " 				END"
			::Query += " 		END) AS LITROS_CONSUMIDOS"
			::Query += " 	FROM VA_VDADOS_OP V"
			::Query += " 	WHERE V.FILIAL = '" + cFilAnt + "'"
			::Query += " 	AND V.DATA BETWEEN '" + ::MesAtuEstq + "01' AND '" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "'"
			::Query += " 	AND V.UN_MEDIDA = 'LT'"
			::Query += " 	GROUP BY V.FILIAL"
			::Query += " 			,V.OP"
			::Query += " 			,V.PROD_FINAL"
			::Query += " 			,V.DESC_PROD_FINAL)"
			::Query += " SELECT"
			::Query += " 	C.*"
			::Query += "    ,(100 - LITROS_CONSUMIDOS * 100 / LITROS_PRODUZIDOS) AS VARIACAO"
			::Query += " FROM C"
			::Query += " WHERE LITROS_PRODUZIDOS <> 0"
			::Query += " AND LITROS_CONSUMIDOS <> 0"
			::Query += " AND LITROS_PRODUZIDOS <> LITROS_CONSUMIDOS"
			::Query += " AND ABS(100 - LITROS_CONSUMIDOS * 100 /"
			::Query += " CASE LITROS_PRODUZIDOS"
			::Query += " 	WHEN 0 THEN 1"
			::Query += " 	ELSE LITROS_PRODUZIDOS"
			::Query += " END) > 5  "
			
		case ::Numero == 65
			::Setores    = 'CUS'
			::Descricao  = 'Confere lançamentos padronizados'
			::Query := ""
			::Query += " WITH C" // CTE inicial para isolar os lpad que contenham chamadas para a funcao 
			::Query += " AS"
			::Query += " (SELECT"
			::Query += " 		CT5.CT5_LANPAD"
			::Query += " 	   ,CT5.CT5_SEQUEN"
			::Query += " 	   ,CT5.CT5_ORIGEM"
			::Query += " 	   ,MAX(CASE"
			::Query += " 			WHEN CT5_DEBITO LIKE '%U_LP%' THEN 'CT5_DEBITO: ' + RTRIM(CT5_DEBITO)"
			::Query += " 			ELSE ''"
			::Query += " 		END) AS CMD1"
			::Query += " 	   ,MAX(CASE"
			::Query += " 			WHEN CT5_CREDIT LIKE '%U_LP%' THEN 'CT5_CREDIT: ' + RTRIM(CT5_CREDIT)"
			::Query += " 			ELSE ''"
			::Query += " 		END) AS CMD2"
			::Query += " 	   ,MAX(CASE"
			::Query += " 			WHEN CT5_CCD LIKE '%U_LP%' THEN 'CT5_CCD: ' + RTRIM(CT5_CCD)"
			::Query += " 			ELSE ''"
			::Query += " 		END) AS CMD3"
			::Query += " 	   ,MAX(CASE"
			::Query += " 			WHEN CT5_CCC LIKE '%U_LP%' THEN 'CT5_CCC: ' + RTRIM(CT5_CCC)"
			::Query += " 			ELSE ''"
			::Query += " 		END) AS CMD4"
			::Query += " 	   ,MAX(CASE"
			::Query += " 			WHEN CT5_VLR01 LIKE '%U_LP%' THEN 'CT5_VLR01: ' + RTRIM(CT5_VLR01)"
			::Query += " 			ELSE ''"
			::Query += " 		END) AS CMD5"
			::Query += " 	   ,MAX(CASE"
			::Query += " 			WHEN CT5_HIST LIKE '%U_LP%' THEN 'CT5_HIST: ' + RTRIM(CT5_HIST)"
			::Query += " 			ELSE ''"
			::Query += " 		END) AS CMD6"
			::Query += " 	   ,MAX(CASE"
			::Query += " 			WHEN CT5_ITEMD LIKE '%U_LP%' THEN 'CT5_ITEMD: ' + RTRIM(CT5_ITEMD)"
			::Query += " 			ELSE ''"
			::Query += " 		END) AS CMD7"
			::Query += " 	   ,MAX(CASE"
			::Query += " 			WHEN CT5_ITEMC LIKE '%U_LP%' THEN 'CT5_ITEMC: ' + RTRIM(CT5_ITEMC)"
			::Query += " 			ELSE ''"
			::Query += " 		END) AS CMD8"
			::Query += " 	FROM " + RetSQLName ("CT5") + " CT5 "
			::Query += " 	WHERE CT5.D_E_L_E_T_ = ''"
			::Query += " 	AND CT5.CT5_STATUS = '1'"
			::Query += " 	GROUP BY CT5.CT5_LANPAD"
			::Query += " 			,CT5.CT5_SEQUEN"
			::Query += " 			,CT5.CT5_ORIGEM),"
			::Query += " C2" // CTE para juntar todos os campos CMD em uma unica coluna (posso ter + de 1 comando no mesmo LPAD)
			::Query += " AS"
			::Query += " (SELECT"
			::Query += " 		CT5_LANPAD"
			::Query += " 	   ,CT5_SEQUEN"
			::Query += " 	   ,CT5_ORIGEM"
			::Query += " 	   ,CMD1 AS COMANDO"
			::Query += " 	FROM C"
			::Query += " 	WHERE CMD1 <> '' UNION ALL"
			::Query += " 	SELECT"
			::Query += " 		CT5_LANPAD"
			::Query += " 	   ,CT5_SEQUEN"
			::Query += " 	   ,CT5_ORIGEM"
			::Query += " 	   ,CMD2 AS COMANDO"
			::Query += " 	FROM C"
			::Query += " 	WHERE CMD2 <> '' UNION ALL"
			::Query += " 	SELECT"
			::Query += " 		CT5_LANPAD"
			::Query += " 	   ,CT5_SEQUEN"
			::Query += " 	   ,CT5_ORIGEM"
			::Query += " 	   ,CMD3 AS COMANDO"
			::Query += " 	FROM C"
			::Query += " 	WHERE CMD3 <> '' UNION ALL"
			::Query += " 	SELECT"
			::Query += " 		CT5_LANPAD"
			::Query += " 	   ,CT5_SEQUEN"
			::Query += " 	   ,CT5_ORIGEM
			::Query += " 	   ,CMD4 AS COMANDO"
			::Query += " 	FROM C"
			::Query += " 	WHERE CMD4 <> '' UNION ALL"
			::Query += " 	SELECT"
			::Query += " 		CT5_LANPAD"
			::Query += " 	   ,CT5_SEQUEN"
			::Query += " 	   ,CT5_ORIGEM"
			::Query += " 	   ,CMD5 AS COMANDO"
			::Query += " 	FROM C"
			::Query += " 	WHERE CMD5 <> '' UNION ALL"
			::Query += " 	SELECT"
			::Query += " 		CT5_LANPAD"
			::Query += " 	   ,CT5_SEQUEN"
			::Query += " 	   ,CT5_ORIGEM"
			::Query += " 	   ,CMD6 AS COMANDO"
			::Query += " 	FROM C"
			::Query += " 	WHERE CMD6 <> '' UNION ALL"
			::Query += " 	SELECT"
			::Query += " 		CT5_LANPAD"
			::Query += " 	   ,CT5_SEQUEN"
			::Query += " 	   ,CT5_ORIGEM"
			::Query += " 	   ,CMD7 AS COMANDO"
			::Query += " 	FROM C"
			::Query += " 	WHERE CMD7 <> '' UNION ALL"
			::Query += " 	SELECT"
			::Query += " 		CT5_LANPAD"
			::Query += " 	   ,CT5_SEQUEN"
			::Query += " 	   ,CT5_ORIGEM"
			::Query += " 	   ,CMD8 AS COMANDO"
			::Query += " 	FROM C"
			::Query += " 	WHERE CMD8 <> '')"
			::Query += " SELECT"
			::Query += " 	'LPAD ' + CT5_LANPAD + '/' + CT5_SEQUEN + ': CAMPO ORIGEM INCONSISTENTE: ' + CT5_ORIGEM AS PROBLEMA"
			::Query += " FROM C2"
			::Query += " WHERE CT5_ORIGEM not like '%LPAD ' + CT5_LANPAD + ' ' + CT5_SEQUEN + '%'"
			::Query += " UNION ALL"
			::Query += " SELECT"
			::Query += " 	'LPAD ' + CT5_LANPAD + '/' + CT5_SEQUEN + ': PARAM/FORMATACAO INCONSISTENTE ' + COMANDO AS PROBLEMA"
			::Query += " FROM C2"
			::Query += " WHERE COMANDO LIKE '%U_LP%'"
			::Query += " AND COMANDO NOT LIKE '%U_LP2%'"
			::Query += " AND COMANDO NOT LIKE '%U_LP(''' + CT5_LANPAD + ''',''' + CT5_SEQUEN + ''',%'"
			::Query += " UNION ALL"
			::Query += " SELECT"
			::Query += " 	'LPAD ' + CT5_LANPAD + '/' + CT5_SEQUEN + ': PARAM/FORMATACAO INCONSISTENTE ' + COMANDO AS PROBLEMA"
			::Query += " FROM C2"
			::Query += " WHERE COMANDO LIKE '%U_LP2%'"
			::Query += " AND COMANDO NOT LIKE '%' + CT5_LANPAD + CT5_SEQUEN + '%'"
			::Query += " ORDER BY PROBLEMA"
		
		case ::Numero == 66
			::Setores    = 'CUS'
			::Descricao  = 'Produtos fantasmas nao deveriam ter estoque'	
			::Query := ""
			::Query += " SELECT
			::Query += " 	'Produtos fantasmas nao deveriam ter estoque' AS PROBLEMA"
			::Query += "    ,B2_COD AS PRODUTO"
			::Query += "    ,RTRIM(B1_DESC) AS DESCRICAO"
			::Query += "    ,B2_LOCAL AS ALMOX"
			::Query += "    ,B2_QFIM AS SALDO_QTD"
			::Query += "    ,B2_VFIM1 AS SALDO_VLR"
			::Query += " FROM " + RetSQLName ("SB2") + " SB2"
			::Query += " 	 ," + RetSQLName ("SB1") + " SB1"
			::Query += " WHERE SB2.D_E_L_E_T_ = ''"
			::Query += " AND SB2.B2_FILIAL = '" + xfilial ("SB2") + "'"
			::Query += " AND (SB2.B2_QFIM <> 0"
			::Query += " OR SB2.B2_VFIM1 <> 0)"
			::Query += " AND SB1.D_E_L_E_T_ = ''"
			::Query += " AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
			::Query += " AND SB1.B1_COD = SB2.B2_COD"
			::Query += " AND SB1.B1_FANTASM = 'S'"
			::Query += " ORDER BY B2_COD, B2_LOCAL"
			
		case ::Numero == 67
			::Setores    = 'CUS'
			::Descricao  = 'Lançamento padrao referenciando mais de uma tabela'	
			::Query := ""
			::Query += " (SELECT"
			::Query += " 		CT5.CT5_LANPAD"
			::Query += " 	   ,CT5.CT5_SEQUEN"
			::Query += " 	   ,CT5.CT5_VLR01
			::Query += " 	   ,RTRIM(CT5.CT5_VLR01) + ' ' + RTRIM(CT5.CT5_DEBITO) + ' ' + RTRIM(CT5.CT5_CREDIT) + ' ' + RTRIM(CT5.CT5_CCD) + ' ' + RTRIM(CT5.CT5_CCC) AS OUTROS"
			::Query += " 	FROM " + RetSQLName ("CT5") + " CT5"
			::Query += " 	WHERE CT5.D_E_L_E_T_ = ''"
			::Query += " 	AND (CT5.CT5_VLR01 LIKE '%D1$_%' ESCAPE '$'"
			::Query += " 	OR CT5.CT5_VLR01 LIKE '%D2$_%' ESCAPE '$'"
			::Query += " 	OR CT5.CT5_VLR01 LIKE '%D3$_%' ESCAPE '$'"
			::Query += " 	OR CT5.CT5_VLR01 LIKE '%E1$_%' ESCAPE '$'"
			::Query += " 	OR CT5.CT5_VLR01 LIKE '%E2$_%' ESCAPE '$'))"
			::Query += " SELECT"
			::Query += " 	'LPAD ' + CT5_LANPAD + '/' + CT5_SEQUEN + ' NAO DEVERIA REFERENCIAR TABELAS SD1/SD2/SD3 AO MESMO TEMPO' AS PROBLEMA"
			::Query += " FROM C"
			::Query += " WHERE (CT5_VLR01 LIKE '%D1$_%' ESCAPE '$'"
			::Query += " AND (OUTROS LIKE '%D2$_%' ESCAPE '$'"
			::Query += " OR OUTROS LIKE '%D3$_%' ESCAPE '$'))"
			::Query += " OR (CT5_VLR01 LIKE '%D2$_%' ESCAPE '$'"
			::Query += " AND (OUTROS LIKE '%D1$_%' ESCAPE '$'"
			::Query += " OR OUTROS LIKE '%D3$_%' ESCAPE '$'))"
			::Query += " OR (CT5_VLR01 LIKE '%D3$_%' ESCAPE '$'"
			::Query += " AND (OUTROS LIKE '%D1$_%' ESCAPE '$'"
			::Query += " OR OUTROS LIKE '%D2$_%' ESCAPE '$'))"
			::Query += " UNION ALL"
			::Query += " SELECT"
			::Query += " 	'LPAD ' + CT5_LANPAD + '/' + CT5_SEQUEN + ' NAO DEVERIA REFERENCIAR TABELAS SE1/SE2 AO MESMO TEMPO' AS PROBLEMA"
			::Query += " FROM C"
			::Query += " WHERE (CT5_VLR01 LIKE '%E1$_%' ESCAPE '$'"
			::Query += " AND OUTROS LIKE '%E2$_%' ESCAPE '$')"
			::Query += " OR (CT5_VLR01 LIKE '%E2$_%' ESCAPE '$'"
			::Query += " AND OUTROS LIKE '%E1$_%' ESCAPE '$')"
			
		case ::Numero == 68
			::Setores    = 'CUS'
			::Descricao  = 'Quantidade para fechamento diferente do final do kardex'
			::Query := ""
			::Query += " WITH C"
			::Query += " AS"
			::Query += " (SELECT"
			::Query += " 		B2_FILIAL AS FILIAL"
			::Query += " 	   ,B2_COD AS PRODUTO"
			::Query += " 	   ,B2_LOCAL AS ALMOX"
			::Query += " 	   ,ISNULL((SELECT"
			::Query += " 				B9_QINI"
			::Query += " 			FROM " + RetSQLName ("SB9") + " ANT"
			::Query += " 			WHERE ANT.D_E_L_E_T_ = ''"
			::Query += " 			AND ANT.B9_FILIAL = SB2.B2_FILIAL"
			::Query += " 			AND ANT.B9_COD = SB2.B2_COD"
			::Query += " 			AND ANT.B9_LOCAL = SB2.B2_LOCAL"
			::Query += " 			AND ANT.B9_DATA = '" + dtos (stod (::MesAtuEstq + '01') - 1) + "')"
			::Query += " 		, 0) AS QT_MES_ANT"
			::Query += " 	   ,ISNULL((SELECT"
			::Query += " 				SUM(QT_ENTRADA)"
			::Query += " 			FROM dbo.VA_FKARDEX(B2_FILIAL,"
			::Query += " 			B2_COD,"
			::Query += " 			B2_LOCAL,"
			::Query += " 			'" + ::MesAtuEstq + "01',"
			::Query += " 			'" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "')"   
			::Query += " 			WHERE LINHA > 1)"
			::Query += " 		, 0) AS ENTR"
			::Query += " 	   ,ISNULL((SELECT"
			::Query += " 				SUM(QT_SAIDA)"
			::Query += " 			FROM dbo.VA_FKARDEX(B2_FILIAL,"
			::Query += " 			B2_COD,"
			::Query += " 			B2_LOCAL,"
			::Query += " 			'" + ::MesAtuEstq + "01',"
			::Query += " 			'" + dtos (lastday (stod (::MesAtuEstq + '01'))) + "')" 
			::Query += " 			WHERE LINHA > 1)"
			::Query += " 		, 0) AS SAID"
			::Query += " 	   ,B2_QFIM AS QT_PREV_FECHTO"
			::Query += " 	FROM " + RetSQLName ("SB2") + " SB2"
			::Query += " 	WHERE SB2.D_E_L_E_T_ = ''"
			::Query += " 	AND SB2.B2_FILIAL = '" + xfilial ("SB2") + "')"
			::Query += " SELECT"
			::Query += " 	'Quantidade para fechamento diferente do final do kardex' AS PROBLEMA"
			::Query += "    ,*"
			::Query += " FROM C"
			::Query += " WHERE ROUND((QT_MES_ANT + ENTR - SAID), 2) <> ROUND(QT_PREV_FECHTO, 2)"
			::Query += " ORDER BY FILIAL, PRODUTO, ALMOX"	
		
		case ::Numero == 69
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores    = 'INF'
			::Descricao  = 'Grupos: Acesso repetido (deveria estar apenas no grupo GERAL)'
			::Query := ""
			::Query += " WITH C AS ("
			::Query += " SELECT GR.GR__ID, GR.GR__CODIGO, GR.GR__NOME, AG.GR__CODACESSO, AG.GR__DESCACESSO"
			::Query +=   " FROM SYS_GRP_GROUP GR"
			::Query +=       " ,SYS_GRP_ACCESS AG"
			::Query +=  " WHERE GR.GR__ID = AG.GR__ID"
			::Query +=    " AND AG.GR__ACESSO = 'T'"
			::Query += ")"
			::Query += " SELECT *"
			::Query +=   " FROM C"
			::Query +=  " WHERE UPPER(GR__CODIGO) LIKE 'FUNCAO%'"
			::Query +=    " AND EXISTS (SELECT *"
			::Query +=                  " FROM C AS C2"
			::Query +=                 " WHERE C2.GR__ID = '000102'"  // grupo 'geral'
			::Query +=                   " AND C2.GR__CODACESSO = C.GR__CODACESSO)"
			::Query +=  " ORDER BY GR__ID, GR__CODACESSO

		case ::Numero == 70
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores    = 'INF'
			::Descricao  = 'Usuarios: Diretorio impressao errado, ambiente != cliente ou destino != arquivo'
			::Query := ""
			::Query += " SELECT P.USR_ID, U.USR_CODIGO, P.USR_DIRIMP"
			::Query +=       ", P.USR_TIPOIMP + '-' + CASE P.USR_TIPOIMP WHEN '1' THEN 'EM DISCO' WHEN '2' THEN 'VIA WINDOWS' WHEN '3' THEN 'DIRETO NA PORTA' ELSE '' END AS TIPO_IMPRESSAO"
			::Query +=       ", P.USR_ENVIMP + '-' + CASE P.USR_ENVIMP WHEN '1' THEN 'SERVIDOR' WHEN '2' THEN 'CLIENTE' ELSE '' END AS AMBIENTE_IMPRESSAO"
			::Query +=   " FROM SYS_USR_PRINTER P, SYS_USR U"
			::Query +=  " WHERE P.D_E_L_E_T_ = ''"
			::Query +=    " AND U.D_E_L_E_T_ = ''"
			::Query +=    " AND U.USR_ID = P.USR_ID"
			::Query +=    " AND U.USR_MSBLQL != '1'"
			::Query +=    " AND U.USR_ID != '000000'"
			::Query +=    " AND (UPPER (P.USR_DIRIMP) != 'C:\TEMP\SPOOL_PROTHEUS\' OR P.USR_ENVIMP != '2' OR P.USR_TIPOIMP != '1')"
			::Query +=  " ORDER BY P.USR_ID"

		case ::Numero == 71
			::Ativa     = .F.  // Grupos agora representam funcoes (das pessoas) e nao mais modulos. Robert, 30/08/2021
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores    = 'INF'
			::Descricao  = 'Grupos: Grupo deve fornecer apenas acesso a modulos e nao a funcionalidades'
			::Query := ""
			::Query += "SELECT TIPO_ACESSO, G.ID_GRUPO, RTRIM (G.DESCRICAO) AS DESCR_GRUPO, ACESSO"
			::Query +=  " FROM VA_USR_ACESSOS_POR_GRUPO AG"
			::Query +=      " JOIN VA_USR_GRUPOS G"
			::Query +=        " ON (G.ID_GRUPO = AG.ID_GRUPO"
			::Query +=        " AND G.TIPO_GRUPO = AG.TIPO_ACESSO)"
			::Query += " WHERE AG.TIPO_ACESSO = 'CFG'"
			::Query +=   " AND G.GRUPO LIKE 'Modulos%'"
			::Query += " ORDER BY G.ID_GRUPO"

		case ::Numero == 72
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores    = 'INF'
			::Descricao  = 'Grupos: Nenhum grupo deveria ter este acesso'
			::Query := ""
			::Query += " SELECT G.GR__NOME, GA.GR__CODACESSO, GA.GR__DESCACESSO"
			::Query +=   " FROM SYS_GRP_ACCESS GA, SYS_GRP_GROUP G"
			::Query +=  " WHERE GA.D_E_L_E_T_ = ''"
			::Query +=    " AND G.D_E_L_E_T_ = ''"
			::Query +=    " AND G.GR__ID = GA.GR__ID"
			::Query +=    " AND G.GR__MSBLQL != '1'"
			::Query +=    " AND GR__CODACESSO IN ('121', '169', '190', '024', '164')"
			::Query +=    " AND GR__ACESSO = 'T'"
			::Query += " ORDER BY GA.GR__ID, GA.GR__CODACESSO"

		case ::Numero == 73
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores    = 'INF'
			::Descricao  = 'Usuarios: Usuario nao deveria ter acesso a configurar data base. Deve ser um acesso dos grupos.'
			::Query := ""
			::Query += "SELECT USR_ID, USR_CODIGO"
			::Query +=  " FROM SYS_USR"
			::Query += " WHERE USR_DTBASE  = '1'"
			::Query +=   " AND D_E_L_E_T_  = ''"
			::Query +=   " AND USR_ID     != '000000'"  // Administrador
			::Query +=   " AND USR_MSBLQL != '1'"
			::Query += " ORDER BY USR_CODIGO"

		case ::Numero == 74
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores    = 'INF'
			::Descricao  = 'Usuarios: Usuario nao deveria ter ACESSOS ligados a ele. Os ACESSOS deveriam ser dados aos grupos.'
			::Query := ""
			::Query += "WITH C AS (
			::Query += "SELECT A.USR_ID, U.USR_CODIGO, CAST (A.USR_CODACESSO AS VARCHAR (20)) AS CODACESSO"
			::Query +=  " FROM SYS_USR_ACCESS A, SYS_USR U"
			::Query += " WHERE A.D_E_L_E_T_ = ''"
			::Query +=   " AND U.D_E_L_E_T_ = ''"
			::Query +=   " AND U.USR_ID = A.USR_ID"
			::Query +=   " AND U.USR_MSBLQL != '1'"
			::Query +=   " AND A.USR_ACESSO = 'T'"
			::Query +=   " AND A.USR_ID NOT IN ('000000')"
			::Query += " UNION ALL"
			::Query += " SELECT SUM.USR_ID, SU.USR_CODIGO, SUM.USR_CODMOD"
			::Query += " FROM SYS_USR_MODULE SUM, SYS_USR SU"
			::Query += " WHERE SU.D_E_L_E_T_ = ''"
			::Query += " AND SU.USR_ID = SUM.USR_ID"
			::Query += " AND SU.USR_MSBLQL != '1'"
			::Query += " AND SUM.D_E_L_E_T_ = ''"
			::Query += " AND USR_ACESSO = 'T'"
			::Query += " AND SUM.USR_ID NOT IN ('000000')"
			::Query += " )"
			::Query += " SELECT *"
			::Query += " FROM C"
			::Query += " ORDER BY USR_ID, CODACESSO"

		case ::Numero == 75
			::Ativa     = .F.  // Temos apenas 1 grupo generico por enquanto. Robert, 30/08/2021
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores    = 'INF'
			::Descricao  = 'Grupos: Todos os grupos genericos deveriam ter estes acessos.'
			::Query := ""
			::Query += "SELECT G.TIPO_GRUPO, G.ID_GRUPO, G.GRUPO, G.DESCRICAO"
			::Query +=  " FROM VA_USR_GRUPOS G"
			::Query += " WHERE G.TIPO_GRUPO = 'CFG'"
			::Query +=   " AND G.ID_GRUPO = '000102'"  // Por enquanto este eh o unico grupo geral, ao qual todos pertencem.
			::Query +=   " AND NOT EXISTS (SELECT *"
			::Query +=                     " FROM VA_USR_ACESSOS_POR_GRUPO AG"
			::Query +=                    " WHERE AG.TIPO_ACESSO = 'CFG'"
			::Query +=                      " AND AG.ID_GRUPO = G.ID_GRUPO"
			::Query +=                      " AND AG.ACESSO in ('108', '150'))"  // Por enquanto estes sao os unicos acessos que entendo que todos precisariam ter.
			::Query += " ORDER BY G.ID_GRUPO"

		case ::Numero == 76
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores    = 'INF'
			::Descricao  = 'Grupos: Todos os grupos deveriam ter privilegio 000002.'
			::Query := ""
			::Query += "SELECT G.GR__ID, G.GR__CODIGO, G.GR__NOME"
			::Query +=  " FROM SYS_GRP_GROUP G"
			::Query += " WHERE G.D_E_L_E_T_ = ''"
			::Query +=   " AND G.GR__MSBLQL != '1'"
			::Query +=   " AND NOT EXISTS (SELECT *"
			::Query +=                     " FROM SYS_RULES_GRP_RULES R"
			::Query +=                    " WHERE R.D_E_L_E_T_ = ''"
			::Query +=                      " AND R.GROUP_ID = G.GR__ID"
			::Query +=                      " AND R.GR__RL_ID IN ('000002'))"  // Privilegio 'base'.
			::Query +=  "ORDER BY G.GR__ID"

		case ::Numero == 77
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores    = 'INF'
			::Descricao  = 'Pessoa do Metadados referenciando mais de um usuario no Protheus'
			::Query := ""
			::Query += "SELECT *"
			::Query +=  " FROM LKSRV_PROTHEUS.protheus.dbo.SYS_USR U"
			::Query += " WHERE U.D_E_L_E_T_ = ''"
			::Query +=   " AND (select count (*) from LKSRV_SIRH.SIRH.dbo.VA_VFUNCIONARIOS M"
			::Query +=         " where U.USR_CARGO LIKE 'Pessoa ' + cast (M.PESSOA as varchar (max)) + '%' COLLATE DATABASE_DEFAULT"
			::Query +=        ") > 1"

		case ::Numero == 78
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores    = 'INF'
			::Descricao  = 'Usuarios Protheus nao relacionados a nenhuma pessoa do Metadados'
			::Query := ""
			::Query += "SELECT PROTHEUS_ID, PROTHEUS_USER, PROTHEUS_NOME, PROTHEUS_CARGO"
			::Query +=  " FROM " + U_LkServer ("TI") + ".VISAO_GERAL_ACESSOS"
			::Query += " WHERE PROTHEUS_USER IS NOT NULL"
			::Query += " AND PROTHEUS_SITUACAO = 'ATIVO'"
			::Query += " AND PESSOA_FOLHA IS NULL"
			::Query +=   " AND upper (PROTHEUS_USER) NOT LIKE 'REP_%'"  	// Representantes estao sendo migrados para o Mercanet
			::Query +=   " AND upper (PROTHEUS_USER) != 'ADMINISTRADOR'"
			::Query +=   " AND upper (PROTHEUS_USER) != 'SUPORTE.TOTVS'"
			::Query +=   " AND upper (PROTHEUS_USER) != 'SARA.CETOLIN'"  	// pessoa juridica
			::Query +=   " AND upper (PROTHEUS_USER) != 'KAREN.NUNES'"  	// Menor aprendiz F03
			::Query +=   " AND upper (PROTHEUS_USER) != 'TOBIAS.BEBBER'"  	// Estagiario agronomia
			::Query +=   " AND upper (PROTHEUS_USER) != 'CONSAD'"
			::Query +=   " AND upper (PROTHEUS_USER) != 'MANUTENCAO'"
			::Query +=   " AND upper (PROTHEUS_USER) != 'SOL.MANUT'"  		// Generico para o pessoal de fabrica abrir solicitacoes de manutencao.
			::Query +=   " AND upper (PROTHEUS_USER) != 'BALANCA.SP'"
			::Query +=   " AND upper (PROTHEUS_USER) != 'SIGALOJA'"
			::Query +=   " AND upper (PROTHEUS_USER) != 'ROBERT_TESTE'"
			::Query +=   " AND upper (PROTHEUS_USER) != 'CAROLINA.ROCHA'"  	// Terceirizada quiosque POA
			::Query +=   " AND upper (PROTHEUS_USER) != 'APP.MNTNG'"  		// Usuario app da manutenção
			::Query +=   " AND upper (PROTHEUS_USER) NOT LIKE 'CUPOM%'"  	// Usuarios 'caixa' para emissao de cupom fiscal nas lojas
			::Query += " ORDER BY PROTHEUS_USER"

		case ::Numero == 79
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores    = 'INF'
			::Descricao  = 'Pessoas demitidas cujo usuario nao foi bloqueado no Protheus'
			::Query := ""
			::Query += "SELECT *"
			::Query +=  " FROM LKSRV_PROTHEUS.protheus.dbo.SYS_USR U"
			::Query += " WHERE U.D_E_L_E_T_ = ''"
			::Query +=   " and USR_MSBLQL != '1'"
			::Query +=   " AND exists (select *"
//			::Query +=                 " FROM LKSRV_SIRH.SIRH.dbo.VA_VFUNCIONARIOS M"
			::Query +=                 " FROM " + U_LkServer ("Metadados") + ".VA_VFUNCIONARIOS M"
			::Query +=                " WHERE U.USR_CARGO LIKE 'Pessoa ' + CAST(M.PESSOA AS VARCHAR(MAX)) + '%' COLLATE DATABASE_DEFAULT"
			::Query +=                  " and M.SITUACAO = 4)"

		case ::Numero == 80
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores    = 'INF'
			::Descricao  = 'Ninguem deveria ter ACESSO A TODAS AS EMP/FILIAIS setado no configurador. Usar para isso os grupos FILIAL_'
			::Query := ""
			::Query += " SELECT 'GRUPO ' + GR__ID AS CODIGO, GR__CODIGO, GR__NOME"
			::Query +=   " FROM SYS_GRP_GROUP"
			::Query +=  " WHERE D_E_L_E_T_ = ''"
			::Query +=    " AND GR__MSBLQL != '1'"
			::Query +=    " AND GR__ALLEMP = '1'"
			::Query +=    " AND GR__ID != '000000'"
			::Query +=  " UNION ALL"
			::Query += " SELECT 'USER ' + USR_ID AS CODIGO, USR_CODIGO, USR_NOME"
			::Query +=   " FROM SYS_USR"
			::Query +=  " WHERE D_E_L_E_T_ = ''"
			::Query +=    " AND USR_MSBLQL != '1'"
			::Query +=    " AND USR_ALLEMP = '1'"
			::Query +=    " AND USR_ID != '000000'"

		case ::Numero == 81
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores    = 'INF'
			::Descricao  = 'Ninguem deveria ter acesso a filiais setado no configurador. Usar para isso os grupos FILIAL_'
			::Query := ""
			::Query += " SELECT 'GRUPO ' + SYS_GRP_FILIAL.GR__ID AS CODIGO, SYS_GRP_GROUP.GR__CODIGO, SYS_GRP_GROUP.GR__NOME, CAST (STRING_AGG (RTRIM (SYS_GRP_FILIAL.GR__FILIAL), ',') AS VARCHAR (50)) AS FILIAIS"
			::Query +=   " FROM SYS_GRP_FILIAL, SYS_GRP_GROUP"
			::Query +=  " WHERE SYS_GRP_FILIAL.D_E_L_E_T_ = ''"
			::Query +=    " AND SYS_GRP_GROUP.D_E_L_E_T_ = ''"
			::Query +=    " AND SYS_GRP_GROUP.GR__ID = SYS_GRP_FILIAL.GR__ID"
			::Query +=    " AND GR__CODIGO NOT LIKE 'Filia%'"  // GRUPOS CUJA FUNCAO EH, JUSTAMENTE, DAR ACESSO A CADA FILIAL
			::Query +=    " AND GR__MSBLQL != '1'"
			::Query +=  " GROUP BY SYS_GRP_FILIAL.GR__ID, SYS_GRP_GROUP.GR__CODIGO, SYS_GRP_GROUP.GR__NOME"
			::Query +=  " UNION ALL"
			::Query += " SELECT 'USUARIO ' + SYS_USR.USR_ID AS CODIGO, SYS_USR.USR_CODIGO, SYS_USR.USR_NOME, CAST (STRING_AGG (RTRIM (USR_FILIAL), ',') AS VARCHAR (50)) AS FILIAIS"
			::Query +=   " FROM SYS_USR_FILIAL, SYS_USR"
			::Query +=  " WHERE SYS_USR_FILIAL.D_E_L_E_T_ = ''"
			::Query +=    " AND SYS_USR.D_E_L_E_T_ = ''"
			::Query +=    " AND SYS_USR.USR_ID = SYS_USR_FILIAL.USR_ID"
			::Query +=    " AND SYS_USR.USR_MSBLQL != '1'"
			::Query +=    " AND SYS_USR.USR_GRPRULE = '3'"  // REGRA DE ACESSO POR GRUPOS = 'SOMAR'
			::Query +=  " GROUP BY SYS_USR.USR_ID, SYS_USR.USR_CODIGO, SYS_USR.USR_NOME"

		case ::Numero == 82
			::Filiais   = '*'
			::Setores   = 'CUS'
			::Descricao = 'Itens de mao de obra devem estar amarrados ao CC correspondente'
			::Query := "" 
			::Query += "SELECT 'Item de mao de obra amarrado a CC errado' as PROBLEMA, B1_COD, B1_CCCUSTO, B1_GCCUSTO, B1_DESC"
			::Query +=  " FROM " + RetSQLName ("SB1")
			::Query += " WHERE D_E_L_E_T_ = ''"
			::Query +=   " AND SUBSTRING (B1_COD, 1, 3) IN ('AP-', 'AO-', 'GF-')"
			::Query +=   " AND B1_CCCUSTO != SUBSTRING (B1_COD, 4, 11)"
			::Query += " ORDER BY B1_COD"


		case ::Numero == 83
			::Setores    = 'PCP/MNT'
			::Descricao  = "Empenho item (tabela SD4) relacionado a OP/OS inexistente ou ja encerrada."
			::Sugestao   = "Execute rotina de 'Refaz acumulados'; Verifique necessidade de ajustar o campo D4_QUANT manualmente."
			::Query := ""
			::Query += " SELECT SD4.D4_FILIAL,"
			::Query +=        " SD4.D4_COD,"
			::Query +=        " SB1.B1_DESC,"
			::Query +=        " SD4.D4_LOCAL,"
			::Query +=        " SD4.D4_OP,"
			::Query +=        " SD4.D4_QUANT"
			::Query +=   " FROM " + RetSQLName ("SD4") + " SD4, "
			::Query +=              RetSQLName ("SB1") + " SB1 "
			::Query +=  " WHERE SB1.D_E_L_E_T_ = ''"
			::Query +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			::Query +=    " AND SB1.B1_COD     = SD4.D4_COD"
			::Query +=    " AND SD4.D_E_L_E_T_ = ''"
			::Query +=    " AND SD4.D4_FILIAL  = '" + xfilial ("SD4") + "'"
			::Query +=    " AND SD4.D4_QUANT  != 0"

			::Query +=    " AND NOT EXISTS (SELECT *"
			::Query +=                      " FROM " + RetSQLName ("SC2") + " SC2 "
			::Query +=                     " WHERE SC2.D_E_L_E_T_ = ''"
			::Query +=                       " AND SC2.C2_FILIAL = SD4.D4_FILIAL"
			::Query +=                       " AND SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN + SC2.C2_ITEMGRD = SD4.D4_OP"
			::Query +=                       " AND SC2.C2_DATRF = '')"


		case ::Numero == 84
			::Setores    = 'CUS/CTB/INF'
			::Descricao  = "Inconsistencia virada saldos estoque"
			::Sugestao   = "Revise se a virada de saldos foi finalizada corretamente."
			::GrupoPerg = "U_VALID007"
			::ValidPerg (_lDefault)
			::Query := ""
			::Query += " WITH C AS ("
			::Query += " SELECT CASE WHEN MV_ULMES != dbo.VA_DTOC(ULT_FECHTO_SB9) THEN 'PARAMETRO MV_ULMES UNCONSISTENTE COM A TABELA SB9'"
			::Query +=             " ELSE CASE WHEN ULT_FECHTO_SBJ != '' AND ULT_FECHTO_SBJ != ULT_FECHTO_SB9 THEN 'ULTIMO BJ_DATA INCONSISTENTE COM ULTIMO B9_DATA'"
			::Query +=                 " ELSE CASE WHEN ULT_FECHTO_SBK != '' AND ULT_FECHTO_SBK != ULT_FECHTO_SB9 THEN 'ULTIMO BK_DATA INCONSISTENTE COM ULTIMO B9_DATA'"
			::Query +=                 " ELSE ''"
			::Query +=                 " END"
			::Query +=             " END"
			::Query +=         " END AS PROBLEMA"
			::Query +=     " ,*"
			::Query +=  " FROM VA_VSTATUS_CUSTO_MEDIO"
			::Query += " WHERE EMPRESA = '" + cEmpAnt + "'"
			::Query +=   " AND FILIAL  BETWEEN '" + ::Param02 + "' AND '" + ::Param03 + "'"
			::Query += " )"
			::Query += " SELECT *"
			::Query += " FROM C"
			if ::Param01 == 1
				::Query += " WHERE PROBLEMA != ''"
			endif
			::Query += " ORDER BY EMPRESA, FILIAL"


		case ::Numero == 85
			::Setores   = 'PCP/PROD/LOG'
			::Descricao = 'Problemas em etiquetas de producao'
			::Sugestao  = 'Verificar movimentacao da etiqueta. Possivelmente falte algum processo.'
			::GrupoPerg = "U_VALID008"
			::ValidPerg (_lDefault)
			::Query := ""
			::Query += "exec VA_SP_VERIFICA_ETIQ_PRODUCAO '" + cFilAnt + "'"  // filial
			::Query +=                                  "," + iif (empty (::Param01), "NULL", "'" + ::Param01        + "'")  // etiq
			::Query +=                                  "," + iif (empty (::Param02), "NULL", "'" + ::Param02        + "'")  // produto
			::Query +=                                  "," + iif (empty (::Param03), "NULL", "'" + dtos (::Param03) + "'")  // data ini
			::Query +=                                  "," + iif (empty (::Param04), "NULL", "'" + dtos (::Param04) + "'")  // data ini
			::Query +=                                  "," + iif (empty (::Param05), "NULL", "'" + ::Param05        + "'")  // OP ini
			::Query +=                                  "," + iif (empty (::Param06), "NULL", "'" + ::Param06        + "'")  // OP fim


		case ::Numero == 86
			::Filiais   = '01'  // Gero todas as filiais juntas.
			::Setores   = 'SAF'
			::Descricao = 'Inconsistencia frete safra'
			::Sugestao  = 'Verificar calculo do frete (tabela SZF) e gravacao das tabelas SD1 e SF1.'
			::GrupoPerg = "U_VALID009"
			::ValidPerg (_lDefault)
			::Query := ""
			::Query += " WITH C AS ("
			::Query += " SELECT SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, NOME_ASSOC, DOC, SERIE, dbo.VA_DTOC (DATA) AS DATA, SUM (VALOR_FRETE) AS ZF_VALFRET"
			::Query +=   ", (SELECT F1_DESPESA
			::Query +=       " FROM " + RetSQLName ("SF1") + " SF1"
			::Query +=      " WHERE SF1.D_E_L_E_T_ = ''"
			::Query +=        " AND SF1.F1_FILIAL  = V.FILIAL"
			::Query +=        " AND SF1.F1_DOC     = V.DOC"
			::Query +=        " AND SF1.F1_SERIE   = V.SERIE"
			::Query +=        " AND SF1.F1_FORNECE = V.ASSOCIADO"
			::Query +=        " AND SF1.F1_LOJA    = V.LOJA_ASSOC) AS F1_DESPESA"
			::Query +=   " FROM VA_VNOTAS_SAFRA V"
			::Query +=  " WHERE SAFRA   = '" + ::Param01 + "'"
			::Query +=    " AND TIPO_NF = 'C'"
//			::Query +=    " AND FILIAL  = '" + cFilAnt + "'"
			::Query += " GROUP BY SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, NOME_ASSOC, DOC, SERIE, DATA"
			::Query += ")"
			::Query += "SELECT 'Soma frete(s) no ZF_VALFRET diferente do campo F1_DESPESA' as problema"
			::Query +=      ", C.*"
			::Query +=  " FROM C"
			::Query += " WHERE round (ZF_VALFRET, 2) != round (F1_DESPESA, 2)"
			::Query += " ORDER BY SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE"


		case ::Numero == 87
			::Filiais   = '01'  // Gero todas as filiais juntas.
			::Setores   = 'FIS/INF'
			::Descricao = 'Parametrizacoes TSS'
			::Sugestao  = 'Rodar wizard de configuracao do TSS'
			::Query := ""
			::Query += "WITH C AS ("
			::Query += "SELECT CASE WHEN SPED000.PARAMETRO = 'MV_NFEDISD' AND CONTEUDO != '1'"
			::Query +=          " THEN 'Nao configurada para enviar DANFe pelo TSS (MV_NFEDISD)'"
			::Query +=          " ELSE ''"
			::Query +=          " END AS PROBLEMA"
			::Query +=      ", SPED001.ID_ENT ENTIDADE"
			::Query +=      ", SYS_COMPANY.M0_CODIGO EMPRESA"
			::Query +=      ", SYS_COMPANY.M0_CODFIL FILIAL"
			::Query +=  " FROM SPED000, SPED001, SYS_COMPANY"
			::Query += " WHERE SPED001.D_E_L_E_T_ = ''"
			::Query +=   " AND SYS_COMPANY.D_E_L_E_T_ = ''"
			::Query +=   " AND SPED001.CNPJ = SYS_COMPANY.M0_CGC"
			::Query +=   " AND SPED001.IE = SYS_COMPANY.M0_INSC"
			::Query +=   " AND SPED000.D_E_L_E_T_ = ''"
			::Query +=   " AND SPED000.ID_ENT = SPED001.ID_ENT"
			::Query +=   " AND SYS_COMPANY.M0_CODIGO = '" + cEmpAnt + "'"
			::Query +=   " AND NOT (SYS_COMPANY.M0_CODIGO = '01' AND SYS_COMPANY.M0_CODFIL = '14')"  // Filial inativa
			::Query += " )"
			::Query += " SELECT *"
			::Query +=   " FROM C"
			::Query +=  " WHERE PROBLEMA != ''"
			::Query +=  " ORDER BY ENTIDADE, PROBLEMA"


		case ::Numero == 88
			::Filiais   = '01'  // Gero todas as filiais juntas.
			::Setores   = 'INF'
			::Descricao = 'Gatilhos'
			::Sugestao  = 'Verificar configuracao do gatilho'
			::Query := ""
			::Query += "SELECT X7_CAMPO, X7_SEQUENC, X7_CDOMIN, X7_REGRA"
			::Query +=  " FROM SX7" + cEmpAnt + "0"  // Pelo que vi, a funcao RetSQLName() nao funciona para o SX7.
			::Query += " WHERE D_E_L_E_T_ = ''"
			::Query +=   " AND UPPER (X7_REGRA) LIKE '%U_VA_GAT%'"
			::Query +=   " AND X7_REGRA NOT LIKE '%' + X7_SEQUENC + '%'"
			::Query += " ORDER BY X7_CAMPO, X7_SEQUENC"


		case ::Numero == 89
			::Filiais   = '01'  // Gero todas as filiais juntas.
			::Setores   = 'FIS/INF'
			::Descricao = 'Parametrizacoes TSS'
			::Sugestao  = 'Verificar parametrizacao para cada tipo de documento'
			::Query := ""
			::Query += "SELECT 'Parametro setado para HOMOLOGACAO' as PROBLEMA"
			::Query +=      ", C.M0_CODFIL AS FILIAL"
			::Query +=      ", S0.ID_ENT AS ENTIDADE_TSS"
			::Query +=      ", PARAMETRO"
			::Query +=      ", CONTEUDO"
			::Query += " FROM protheus.dbo.SPED000 S0"
			::Query += " 	,protheus.dbo.SPED001 S1"
			::Query += " 	,protheus.dbo.SYS_COMPANY C"
			::Query += " WHERE S1.D_E_L_E_T_ = ''"
			::Query += " AND C.D_E_L_E_T_ = ''"
			::Query += " AND C.M0_CGC = S1.CNPJ"
			::Query += " AND C.M0_INSC = S1.IE"
			::Query += " AND S0.D_E_L_E_T_ = ''"
			::Query += " AND S0.ID_ENT = S1.ID_ENT"
			::Query += " AND S0.PARAMETRO IN ('MV_AMBCCE', 'MV_AMBMDFE', 'MV_AMBIENT', 'MV_AMBNCFE')"  // Nao usados (por enquanto): MV_AMBCTEC, MV_AMBEPP, MV_AMBNFEC
			::Query += " AND S0.CONTEUDO != '1'"
			::Query += " AND NOT (C.M0_CODIGO = '01' AND C.M0_CODFIL = '14')"  // Filial inativa
			::Query += " ORDER BY FILIAL, PARAMETRO"


		case ::Numero == 90
			::Filiais   = '01'  // Usamos o modulo de manutencao somente ma filial 01.
			::Setores   = 'INF/MNT'
			::Descricao = 'Inconsistencia movimentos OS x Estoque'
			::Sugestao  = 'Verificar movimentacao tabelas STL x SD3'
			::GrupoPerg = "U_VALID002"
			::ValidPerg (_lDefault)
			::Query := ""
			::Query += "WITH D3 AS ("
			::Query +=    "SELECT D3_NUMSEQ, D3_COD, D3_EMISSAO, D3_OP, D3_LOCAL, D3_LOTECTL, D3_LOCALIZ, SUM (D3_QUANT) AS QT_SD3"
			::Query +=     " FROM " + RetSQLName ("SD3")
			::Query +=    " WHERE D_E_L_E_T_  = ''"
			::Query +=      " AND D3_FILIAL   = '" + cFilAnt + "'"
			::Query +=      " AND D3_ESTORNO != 'S'"
			::Query +=      " AND SUBSTRING (D3_OP, 7, 2) = 'OS'"
			::Query +=      " AND D3_TIPO    NOT IN ('MO', 'GG')"
			::Query +=      " AND D3_EMISSAO BETWEEN '" + dtos (::Param01) + "' AND '" + dtos (::Param02) + "'"
			::Query +=      " AND D3_COD     BETWEEN '" + ::Param03 + "' AND '" + ::Param04 + "'"
			::Query +=    " GROUP BY D3_FILIAL, D3_COD, D3_NUMSEQ, D3_EMISSAO, D3_OP, D3_LOCAL, D3_LOTECTL, D3_LOCALIZ"
			::Query += "),"
			::Query += "TL AS ("
			::Query +=    "SELECT TL_NUMSEQ, STL.TL_CODIGO, TL_DTFIM, TL_ORDEM, TL_LOCAL, TL_LOTECTL, TL_LOCALIZ, SUM (TL_QUANTID) AS QT_SDB"
			::Query +=     " FROM " + RetSQLName ("STL") + " STL"
			::Query +=    " WHERE D_E_L_E_T_  = ''"
			::Query +=      " AND TL_FILIAL   = '01'"
			::Query +=      " AND TL_TIPOREG  = 'P'"  // [P]roduto
			::Query +=      " AND TL_SEQRELA != '0'"  // INDICA QUE FOI MOVIMENTADO NO ESTOQUE (LADO DIREITO DA TELA RETORNO MOD.II)
			::Query +=      " AND TL_DTFIM   BETWEEN '" + dtos (::Param01) + "' AND '" + dtos (::Param02) + "'"
			::Query +=      " AND TL_CODIGO  BETWEEN '" + ::Param03 + "' AND '" + ::Param04 + "'"
			::Query +=    " GROUP BY TL_FILIAL, TL_ORDEM, TL_CODIGO, TL_NUMSEQ, TL_DTFIM, TL_LOCAL, TL_LOTECTL, TL_LOCALIZ"
			::Query += ")"
			::Query += ",UNIAO AS ("
			::Query += "SELECT * FROM D3"
			::Query +=    " FULL OUTER JOIN TL"
			::Query +=       " ON (TL_NUMSEQ = D3_NUMSEQ"
			::Query +=       " AND TL_LOCAL = D3_LOCAL"
			::Query +=       " AND TL_LOTECTL = D3_LOTECTL"
			::Query +=       " AND TL_LOCALIZ = D3_LOCALIZ"
			::Query +=       " AND RTRIM (TL_ORDEM) + 'OS001' = D3_OP"
			::Query +=     ")"
			::Query += ")"
			::Query += "SELECT 'Inconsist.mov.STL(O.S.)xSD3(estoque)' as PROBLEMA, *""
			::Query +=  " FROM UNIAO"
			::Query += " WHERE (QT_SD3 IS NULL OR QT_SDB IS NULL OR QT_SD3 != QT_SDB)"
			::Query += " ORDER BY D3_NUMSEQ, TL_NUMSEQ"


		case ::Numero == 91
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores    = 'INF'
			::Descricao  = 'Profile poderia ser excluido para usuarios demitidos.'
			::Query := " SELECT U.USR_ID, U.USR_CODIGO"
			::Query +=       ", CASE WHEN U.D_E_L_E_T_ = '*' THEN 'DELETADO' ELSE '' END AS USR_DELETADO"
			::Query +=       ", P.P_NAME, P.P_PROG, P.P_TYPE"
			::Query +=   " FROM MP_SYSTEM_PROFILE P, SYS_USR U"
			::Query +=  " WHERE P.D_E_L_E_T_ = ''"
			::Query +=    " AND U.USR_ID != '000260'"  // BRUNA.MARTINS - POSSIVEL RETORNO COMO SAFRISTA
			::Query +=    " AND U.USR_ID != '000261'"  // CLAUDIA.BIONDO - POSSIVEL RETORNO COMO SAFRISTA
			::Query +=    " AND U.USR_ID != '000378'"  // PEDRO TONIOLO - NAO RETORNA, MAS ERA USR CHAVE. VOU GUARDAR MAIS UM POUCO
			::Query +=    " AND U.USR_ID != '000523'"  // PABLO.SANTOS - NAO RETORNA, MAS ERA USR CHAVE. VOU GUARDAR MAIS UM POUCO
			::Query +=    " AND U.USR_ID != '000503'"  // CALIANDRA.TUMELERO - POSSIVEL RETORNO COMO SAFRISTA
			::Query +=    " AND U.USR_ID != '000612'"  // KAREN.NUNES - POSSIVEL RETORNO COMO SAFRISTA
			::Query +=    " AND U.USR_ID != '000698'"  // LARISSA.LAZZARI - POSSIVEL RETORNO COMO SAFRISTA
			::Query +=    " AND U.USR_ID != '000703'"  // GUILHERME.STUMPF - POSSIVEL RETORNO COMO SAFRISTA
			::Query +=    " AND U.USR_ID != '000719'"  // RUAN.PIVOTTO - POSSIVEL RETORNO COMO SAFRISTA
			::Query +=    " AND U.USR_ID != '000753'"  // MARCIA.UEZ - POSSIVEL RETORNO COMO SAFRISTA
			::Query +=    " AND U.USR_ID != '000754'"  // CHIARA.MAGALHAES - POSSIVEL RETORNO COMO SAFRISTA
			::Query +=    " AND U.USR_ID != '000757'"  // CAROLINA.MAZZOTTI - POSSIVEL RETORNO COMO SAFRISTA
			::Query +=    " AND U.USR_ID != '000758'"  // JESSICA.CAVALHEIRO - POSSIVEL RETORNO COMO SAFRISTA
			::Query +=    " AND (U.USR_CODIGO LIKE '%' + P.P_NAME + '%'"
			::Query +=        " OR P.P_NAME = U.USR_ID"
			::Query +=        " OR P.P_NAME like U.USR_ID + '01%'"  // se gravar empresa + filial no profile
			::Query +=        " OR substring (P.P_NAME, 3, 13) like substring (U.USR_CODIGO, 1, 13)"  // Antigamente gravava empresa + username
			::Query +=        ")"
			::Query +=    " AND exists (select *"
			::Query +=                  " FROM LKSRV_SIRH.SIRH.dbo.VA_VFUNCIONARIOS META"
			::Query +=                 " WHERE U.USR_CARGO LIKE 'Pessoa ' + CAST(META.PESSOA AS VARCHAR(MAX)) + '%' COLLATE DATABASE_DEFAULT"
			::Query +=                   " and META.SITUACAO = 4)"
			::Query +=    " order by P_NAME, U.USR_ID"

		case ::Numero == 92
			::Filiais   = '01'  // O cadastro eh compartilhado, nao tem por que rodar em todas as filiais. 
			::Setores    = 'INF'
			::Descricao  = 'Usuarios: Timeout nao deveria estar configurado no usuario nem no grupo'
			::Query := ""
			::Query += " SELECT 'Usuario ' as origem, U.USR_ID, U.USR_CODIGO, U.USR_TIMEOUT"
			::Query +=   " FROM SYS_USR U"
			::Query +=  " WHERE U.D_E_L_E_T_ = ''"
			::Query +=    " AND U.USR_MSBLQL != '1'"
			::Query +=    " AND U.USR_TIMEOUT > 0"
			::Query +=  " UNION ALL "
			::Query += " SELECT 'Grupo ' as origem, G.GR__ID, G.GR__CODIGO + ' - ' + G.GR__NOME, G.GR__TIMEOUT"
			::Query +=   " FROM SYS_GRP_GROUP G"
			::Query +=  " WHERE G.D_E_L_E_T_ = ''"
			::Query +=    " AND G.GR__MSBLQL != '1'"
			::Query +=    " AND G.GR__TIMEOUT > 0"

		case ::Numero == 93
			::Setores   = 'CUS/CTB/INF'
			::Descricao = "Nao levou custo correto da NF para a OP"
			::Sugestao  = "Custo dos movimentos RE5 na tabela SD3 deve ser igual ao custo da NF que os gerou. Tente refazer custo das entradas."
			::GrupoPerg = "U_VALID028"
			::ValidPerg (_lDefault)
			::QuandoUsar = "Apos rodar o custo medio."
			::Query := ""
			::Query += " WITH C AS ("
			::Query += " SELECT D3_FILIAL, D3_EMISSAO, D3_DOC, D3_FORNDOC"
			::Query +=       ", D3_LOJADOC, D3_NUMSEQ, D3_COD, D3_QUANT, D3_CUSTO1, SD1.D1_CUSTO"
			::Query +=   " FROM " + RetSQLName ("SD3") + " SD3 "
			::Query +=      " LEFT JOIN " + RetSQLName ("SD1") + " SD1 "
			::Query +=        " ON (SD1.D_E_L_E_T_ = ''"
			::Query +=        " AND SD1.D1_FILIAL  = SD3.D3_FILIAL"
			::Query +=        " AND SD1.D1_DOC     = SD3.D3_DOC"
			::Query +=        " AND SD1.D1_NUMSEQ  = SD3.D3_NUMSEQ"
			::Query +=        " AND SD1.D1_FORNECE = SD3.D3_FORNDOC"
			::Query +=        " AND SD1.D1_LOJA    = SD3.D3_LOJADOC)"
			::Query +=  " WHERE SD3.D_E_L_E_T_ = ''"
			::Query +=    " AND SD3.D3_ESTORNO != 'S'"
			::Query +=    " AND D3_EMISSAO BETWEEN '" + dtos (::Param01) + "' AND '" + dtos (::Param02) + "'"
			::Query +=    " AND D3_CF = 'RE5'"
			::Query += ")"
			::Query += " SELECT *"
			::Query +=   " FROM C"
			::Query +=  " WHERE D3_CUSTO1 != D1_CUSTO OR D1_CUSTO IS NULL"
			::Query +=  " ORDER BY D3_FILIAL, D3_EMISSAO, D3_DOC, D3_COD"

		otherwise
			::UltMsg = "Verificacao numero " + cvaltochar (::Numero) + " nao definida."
	endcase
	//u_logFim (GetClassName (::Self) + '.' + procname ())
return



// --------------------------------------------------------------------------
// Faz a leitura dos parametros (caso existam)
METHOD Pergunte () Class ClsVerif
	local _lRet := .T.
	
	if _lRet .and. ! empty (::GrupoPerg)
		_lRet = Pergunte (::GrupoPerg, ::ComTela)
	endif
	if _lRet
		::Param01 = mv_par01
		::Param02 = mv_par02
		::Param03 = mv_par03
		::Param04 = mv_par04
		::Param05 = mv_par05
		::Param06 = mv_par06
		::Param07 = mv_par07
		::Param08 = mv_par08
		::Param09 = mv_par09
		::Param10 = mv_par10
		::GeraQry ()
	endif
return _lRet


// --------------------------------------------------------------------------
// Altera o conteudo de um parametro.
METHOD SetParam (_sParam, _xConteudo) Class ClsVerif

	// Ainda nao encontrei forma de acessar os atributos da classe com operador de macro, entao vai com CASE mesmo...
	do case
		case _sParam == '01' ; ::Param01 = _xConteudo
		case _sParam == '02' ; ::Param02 = _xConteudo
		case _sParam == '03' ; ::Param03 = _xConteudo
		case _sParam == '04' ; ::Param04 = _xConteudo
		case _sParam == '05' ; ::Param05 = _xConteudo
		case _sParam == '06' ; ::Param06 = _xConteudo
		case _sParam == '07' ; ::Param07 = _xConteudo
		case _sParam == '08' ; ::Param08 = _xConteudo
		case _sParam == '09' ; ::Param09 = _xConteudo
		case _sParam == '10' ; ::Param10 = _xConteudo
		otherwise
			::UltMsg = "Parametro '" + _sParam + "' sem tratamento no metodo " + procname () + " da classe " + GetClassName (::Self) + '.'
			if ::ComTela
				u_help (::UltMsg,, .t.)
			else
				U_Log2 ('erro', '[' + GetClassName (::Self) + '.' + procname () + ']' + ::UltMsg)
			endif
	endcase
	
	// Gera novamente a definicao da query para pegar os novos parametros.
	::GeraQry (.F.)

return


// --------------------------------------------------------------------------
// Cria perguntas no SX1.
METHOD ValidPerg (_lDefault) Class ClsVerif
	local _aRegsPerg := {}
	local _aDefaults := {}
	private cPerg    := ::GrupoPerg

	do case

		case ::GrupoPerg == "U_VALID001"
			//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                               Help
			aadd (_aRegsPerg, {01, "OP inicial                    ", "C", 13, 0,  "",   "SC2   ", {},                                  ""})
			aadd (_aRegsPerg, {02, "OP final                      ", "C", 13, 0,  "",   "SC2   ", {},                                  ""})
			aadd (_aRegsPerg, {03, "Produto inicial               ", "C", 15, 0,  "",   "SB1   ", {},                                  ""})
			aadd (_aRegsPerg, {04, "Produto final                 ", "C", 15, 0,  "",   "SB1   ", {},                                  ""})
			if _lDefault
				::Param01 = ''  // Deixa um valor default para poder gerar a query inicial.
				::Param02 = 'z'  // Deixa um valor default para poder gerar a query inicial.
				::Param03 = ''  // Deixa um valor default para poder gerar a query inicial.
				::Param04 = 'z'  // Deixa um valor default para poder gerar a query inicial.
			endif

		case ::GrupoPerg == "U_VALID002"
			aadd (_aRegsPerg, {01, "Data inicial                  ", "D", 8,  0,  "",   "      ", {},                                  ""})
			aadd (_aRegsPerg, {02, "Data final                    ", "D", 8,  0,  "",   "      ", {},                                  ""})
			aadd (_aRegsPerg, {03, "Produto inicial               ", "C", 15, 0,  "",   "SB1   ", {},                                  ""})
			aadd (_aRegsPerg, {04, "Produto final                 ", "C", 15, 0,  "",   "SB1   ", {},                                  ""})
			if _lDefault
				::Param01 = date ()  // Deixa um valor default para poder gerar a query inicial.
				::Param02 = date ()  // Deixa um valor default para poder gerar a query inicial.
				::Param03 = ''       // Deixa um valor default para poder gerar a query inicial.
				::Param04 = 'z'      // Deixa um valor default para poder gerar a query inicial.
			endif

		case ::GrupoPerg == "U_VALID004"
			//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                               Help
			aadd (_aRegsPerg, {01, "Data fechamento inicial estq  ", "D", 8,  0,  "",   "      ", {},                                  ""})
			aadd (_aRegsPerg, {02, "Data fechamento final estoque ", "D", 8,  0,  "",   "      ", {},                                  ""})
			if _lDefault
				::Param01 = stod (::MesAntEstq + '01') - 1  // Deixa um valor default para poder gerar a query inicial.
				::Param02 = lastday (stod (::MesAntEstq + '01'))  // Deixa um valor default para poder gerar a query inicial.
			endif

		case ::GrupoPerg == "U_VALID005"
			//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                               Help
			aadd (_aRegsPerg, {01, "Safra                         ", "C", 4,  0,  "",   "      ", {},                                  ""})
			aadd (_aRegsPerg, {02, "Filial inicial                ", "C", 2,  0,  "",   "SM0   ", {},                                  ""})
			aadd (_aRegsPerg, {03, "Filial final                  ", "C", 2,  0,  "",   "SM0   ", {},                                  ""})
			aadd (_aRegsPerg, {04, "Serie contranotas             ", "C", 3,  0,  "",   "      ", {},                                  ""})
			aadd (_aRegsPerg, {05, "TES entr.uva(separ.por barras)", "C", 30, 0,  "",   "      ", {},                                  ""})
			aadd (_aRegsPerg, {06, "TES compra(separ.por barras)  ", "C", 30, 0,  "",   "      ", {},                                  ""})
			aadd (_aRegsPerg, {07, "Lista preco base safra        ", "C", 6,  0,  "",   "SZA   ", {},                                  ""})
			if _lDefault
				::Param01 = U_IniSafra ()  // Retorna o Ano da Safra atual. Deixa um valor default para poder gerar a query inicial.
				::Param02 = cFilAnt  // Deixa um valor default para poder gerar a query inicial.
				::Param03 = cFilAnt  // Deixa um valor default para poder gerar a query inicial.
				::Param04 = '30 '  // Deixa um valor default para poder gerar a query inicial.
				::Param05 = '028/057/128'  // Deixa um valor default para poder gerar a query inicial.
				::Param06 = '077/188/107/192'  // Deixa um valor default para poder gerar a query inicial.
			endif

		case ::GrupoPerg == "U_VALID006"
			//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                               Help
			aadd (_aRegsPerg, {01, "Data fechamento estq inicial  ", "D", 8,  0,  "",   "      ", {},                                  ""})
			aadd (_aRegsPerg, {02, "Data fechamento estq final    ", "D", 8,  0,  "",   "      ", {},                                  ""})
			aadd (_aRegsPerg, {03, "Produto inicial               ", "C", 15, 0,  "",   "SB1   ", {},                                  ""})
			aadd (_aRegsPerg, {04, "Produto final                 ", "C", 15, 0,  "",   "SB1   ", {},                                  ""})
			if _lDefault
				::Param01 = lastday (stod (::MesAntEstq + '01'))  // Deixa um valor default para poder gerar a query inicial.
				::Param02 = lastday (stod (::MesAntEstq + '01'))  // Deixa um valor default para poder gerar a query inicial.
				::Param03 = ''  // Deixa um valor default para poder gerar a query inicial.
				::Param04 = 'z'  // Deixa um valor default para poder gerar a query inicial.
			endif	
				
		case ::GrupoPerg == "U_VALID007"
			//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                               Help
			aadd (_aRegsPerg, {01, "Mostrar apenas os problemas?  ", "C", 1,  0,  "",   "      ", {'Apenas problemas', 'Tudo'},        ""})
			aadd (_aRegsPerg, {02, "Filial inicial                ", "C", 2,  0,  "",   "SM0   ", {},                                  ""})
			aadd (_aRegsPerg, {03, "Filial final                  ", "C", 2,  0,  "",   "SM0   ", {},                                  ""})
			if _lDefault
				::Param01 = 1  // Deixa um valor default para poder gerar a query inicial.
				::Param02 = cFilAnt  // Deixa um valor default para poder gerar a query inicial.
				::Param03 = cFilAnt  // Deixa um valor default para poder gerar a query inicial.
			endif

		case ::GrupoPerg == "U_VALID008"
			//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                               Help
			aadd (_aRegsPerg, {01, "Etiqueta (vazio=todas)        ", "C", 10, 0,  "",   "ZA1   ", {},                                  ""})
			aadd (_aRegsPerg, {02, "Produto (vazio=todos)         ", "C", 15, 0,  "",   "SB1   ", {},                                  ""})
			aadd (_aRegsPerg, {03, "Data inicial                  ", "D", 8,  0,  "",   "      ", {},                                  ""})
			aadd (_aRegsPerg, {04, "Data final                    ", "D", 8,  0,  "",   "      ", {},                                  ""})
			aadd (_aRegsPerg, {05, "OP inicial                    ", "C", 14, 0,  "",   "SC2   ", {},                                  ""})
			aadd (_aRegsPerg, {06, "OP final                      ", "C", 14, 0,  "",   "SC2   ", {},                                  ""})
			if _lDefault
				::Param01 = ''  // Deixa um valor default para poder gerar a query inicial.
				::Param02 = ''  // Deixa um valor default para poder gerar a query inicial.
				::Param03 = dDataBase  // Deixa um valor default para poder gerar a query inicial.
				::Param04 = dDataBase  // Deixa um valor default para poder gerar a query inicial.
				::Param05 = ''  // Deixa um valor default para poder gerar a query inicial.
				::Param06 = 'z'  // Deixa um valor default para poder gerar a query inicial.
			endif

		case ::GrupoPerg == "U_VALID009"
			//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                               Help
			aadd (_aRegsPerg, {01, "Safra                         ", "C", 4,  0,  "",   "      ", {},                                  ""})
			if _lDefault
				::Param01 = U_IniSafra ()  // Retorna o Ano da Safra atual. Deixa um valor default para poder gerar a query inicial.
			endif

		case ::GrupoPerg == "U_VALID028"
			//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                               Help
			aadd (_aRegsPerg, {01, "Data de  ", "D", 8,  0,  "",   "      ", {},                                  	""})
			aadd (_aRegsPerg, {02, "Data até ", "D", 8,  0,  "",   "      ", {},  									""})
			
			if _lDefault
				::Param01 = dDataBase   // Deixa um valor default para poder gerar a query inicial.
				::Param02 = dDataBase   // Deixa um valor default para poder gerar a query inicial.
			EndIf

		case ::GrupoPerg == "U_VALID046"
			//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                               Help
			aadd (_aRegsPerg, {01, "Data de  ", "D", 8,  0,  "",   "      ", {},                                  	""})
			aadd (_aRegsPerg, {02, "Data até ", "D", 8,  0,  "",   "      ", {},  									""})
			aadd (_aRegsPerg, {03, "Limite   ", "C", 8,  0,  "",   "      ", {},                                  	""})
			
			::Param01 = stod (::MesAntEstq + '01') - 1  		// Deixa um valor default para poder gerar a query inicial.
			::Param02 = lastday (stod (::MesAntEstq + '01'))    // Deixa um valor default para poder gerar a query inicial.
			::Param03 = '51'

		case ::GrupoPerg == "U_VALID056"
			//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                               Help
			aadd (_aRegsPerg, {01, "Almoxarifado simbólico ", "C", 2,  0,  "",   "      ", {},                                  	""})
			if _lDefault
				::Param01 = '99'
			endif
		otherwise
			::UltMsg = "Perguntas nao definidas para a verificacao " + cvaltochar (::Numero) + " no metodo " + procname () + " da classe " + GetClassName (::Self) + '.'

	endcase

	if len (_aRegsPerg) > 0
		U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
	endif
return


// --------------------------------------------------------------------------------------------------
// Verifica a consistencia dos parametros.
METHOD VerifParam () Class ClsVerif
	local _lRet := .T.
	do case
		case ::Numero == 4
			if ::Param01 >= ::Param02
				::UltMsg = "Data inicial deve ser menor que data final."
				_lRet = .F.
			endif
			if ::Param01 != lastday (::Param01) .or. ::Param02 != lastday (::Param02)
				::UltMsg = "Datas devem ser os ultimos dias de cada mes (corresponde as datas de gravacao do arquivo SB9)."
				_lRet = .F.
			endif

		case ::Numero == 85
			if empty (::Param03) .or. empty (::Param04)
				::UltMsg = "Verif. de etiq.producao eh muito pesada para rodar sem especificar um intervalo de datas."
				_lRet = .F.
			endif
			if empty (::Param06)
				::UltMsg = "OP final nao pode ficar em branco."
				_lRet = .F.
			endif
			if empty (::Param01) .and. empty (::Param02)
				if (::Param04 - ::Param03) > 31
					::UltMsg = "Verif. de etiq.producao eh muito pesada para rodar mais de 30 dias sem especificar etiqueta ou produto."
					_lRet = .F.
				endif
			endif
	endcase
return _lRet
