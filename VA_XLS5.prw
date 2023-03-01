// Programa...: VA_XLS5
// Autor......: Robert Koch
// Data.......: 16/12/2009
// Descricao..: Exportacao geral de dados de faturamento para planilha.
//
// #TipoDePrograma    #Relatorio
// #Descricao         #Exportacao geral de dados de faturamento para planilha
// #PalavasChave      #exportacao_dados #planilha #faturamento #exporta_dados #dados_gerais_faturamento
// #TabelasPrincipais #SD2 #SF2 #SD1 #SF4 #SF4 #SC5 #SC6
// #Modulos           #FAT
//
// Historico de alteracoes:
// 09/06/2010 - Robert  - Criados parametros de exportar ou nao frete previsto e redespacho.
// 14/07/2010 - Robert  - Criada rotina de selecao de colunas a exportar.
//                      - Acrescentadas diversas colunas.
// 23/07/2010 - Robert  - IPI nao eh mais descontado do valor da margem
//                      - Criada coluna com mes e ano da emissao da nota
// 29/07/2010 - Robert  - Nao considera mais notas bonificadas para calculo de rapel pelo cad. cliente.
//                      - Valor da ST entra na base de calculo do rapel.
//                      - Incluida coluna com o valor da ST.
// 06/08/2010 - Robert  - Leitura do SA3 e SA4 passa a ser feita com left join por ter casos sem informacao.
// 15/09/2010 - Robert  - Passa a usar 'left join' para relacionar tabela T3 do SX5, para casos de cadastro incompleto.
//                      - Criadas novas colunas
//                      - Custo, rapel, margem e frete previsto passam a ser lidos direto da tabela do exporta dados
// 13/10/2010 - Robert  - Incluida coluna com tipo de pessoa.
// 12/12/2010 - Robert  - Nao usa mais arq. de trabalho. Exporta direto do resultado da query.
// 10/02/2011 - Robert  - Busca nome da empresa e filial do Sigamat e usa na query.
//                      - Exporta campos de texto com a funcao RTrim do SQL.
// 29/11/2011 - Robert  - Incluido filtro por vendedor2.
// 26/03/2012 - Robert  - Incluida coluna com valor do frete paletizacao.
// 18/05/2012 - Robert  - Incluida coluna com valor do PVCond.
// 20/06/2012 - Robert  - Criadas colunas de valor total NF e venda liquida.
//                      - Implementado parametro 22 para acomodar maio opcoes de selecao de colunas.
// 18/10/2012 - Elaine  - Inclusao das colunas: Pedido do Cliente, MsgAdicionais, Obs do Pedido  Nro de Serie
// 25/10/2012 - Elaine  - Adcionei novos filtros de tela: Ignorar devol.venda e Apenas fatur.e bonif 
//                        e inclusao da coluna observacao do pedido
// 07/01/2013 - Robert  - Incluida coluna B1_VAMIX.
// 04/03/2013 - Robert  - Incluida coluna com o ano.
// 08/08/2013 - Robert  - Incluida coluna com a origem dos dados (SD2 ou SD1).
// 15/02/2014 - Robert  - Incluida coluna com o canal de vendas.
// 14/08/2014 - Catia   - Incluida opcao de Cupons Fiscais
// 15/08/2014 - Catia   - Identificação notas de devolucao como DEVOLUCAO e gerados valores negativos.
// 04/12/2014 - Robert  - Criado join com SF4
//                      - Criada coluna com descricao do TES
// 17/04/2015 - Catia   - Permissoes - quem NAO pode usar esta rotina
// 27/04/2015 - Catia   - Incluida coluna de DESCONT_NF
// 12/06/2015 - Catia   - Tirado parametro de considerar devolucoes - vai considerar SEMPRE
// 12/06/2015 - Catia   - alterada a forma de identificar o que eh cupom fiscal
// 19/06/2015 - Catia   - fechamento com os relatorios do faturamento - analise comercial e analise de saidas
//                      - passa a considerar sempre os CUPONS FISCAIS,VALBRUT nao estava considerando ST, 
//                        tirada coluna VENDA LIQUIDA
//	                    - VALMERC quando era uma devolução nao estava negativando, tirada coluna DESCONTO_NF
// 09/07/2015 - Robert  - Tratamento para remover ';' dos campos de mensagem e observacoes, pois causa 
//                        confusao ao exportar para CSV.
// 03/08/2015 - Robert  - Incluida coluna VEND1
// 07/06/2016 - Robert  - Campo PRODPAI em desuso. Passa a usar apenas o campo PRODUTO da view VA_VFAT.
// 25/07/2016 - Catia   - incluida a opcao de gerar o motivo de devolução MOTDEV
// 31/08/2016 - Robert  - Controla acesso por semaforo.
// 23/12/2016 - Júlio   - Alterada a leitura da tabela SX5_88 para a tabela ZX5_39.  
// 23/12/2016 - Júlio   - Alterada a leitura da tabela SX5_Z7 para a tabela ZX5_40.  
// 06/02/2017 - Robert  - Ajuste descricao colunas LINHA e MARCA.
// 27/02/2017 - Catia   - Desabilitado da seleção o campo C5_PEDCLI, na maioria dos registros esta em branco, 
//                        normalmente não eh usado 
//						  e estava dando erro pq nem sempre faz o join no SC5 e SC6
// 23/10/2017 - Robert  - Testa se alguns campos serao usados na query, do contrario nem inclui os joins das respectivas tabelas.
// 02/03/2018 - Catia   - Incluida coluna codigo do supervidor - A3_VAGEREN
// 04/06/2018 - Robert  - Adicionadas colunas de codigo e nome do promotor.
// 20/09/2018 - Catia   - Valores de FRETE de devolucoes nao pode ser considerado como negativo, é um custo 
//					      nosso entao tem que aparecer positivo
// 20/09/2018 - Catia   - Colocada a opcao de aparecer a base de rapel do cliente 
// 07/11/2018 - Robert  - Incluida coluna CUSTOMEDIO
// 11/04/2019 - Robert  - Alterada a leitura da tabela SX5_98 para a tabela ZX5_50
// 17/05/2019 - Robert  - Incluida coluna linha de embalagem conforme B1_CLINF (GLPI 5938).
// 28/10/2019 - Cláudia - Incluída colunas AGRUPADOR_UNITARIO e ATO, conforme GLPI 6858
// 12/12/2019 - Robert  - Incluida coluna LINHA_ENVASE com base no B1_VALINEN.
// 25/02/2020 - Claudia - Alterado o uso da view VA_VFAT para a tabela BI_ALIANCA.dbo.VA_FATDADOS
// 25/06/2020 - Robert  - Coluna CUSTO_REPOS renomeada para CUSTO_STD e criada nova coluna VALOR_NET (GLPI 8104).
// 13/07/2020 - Robert  - Coluna VALOR_NET nao estava sendo mudada para negativa quando origem = 'SD1'.
//                      - Coluna FAT_BONIF considerava devolucao apenas quando origem=SD1 e nao considerava todas 
//						  as opcoes do campo F4_MARGEM.
//                      - Inseridas tags para catalogacao de fontes
// 05/10/2020 - Claudia - Incluido grupo para impressão simplificado. GLPI:8588 
// 13/10/2020 - Cláudia - Incluidas colunas na versao resumida, conforme GLPI: 8642
// 09/12/2020 - Cláudia - Alterada busca de promotor. GLPI: 8880
// 21/05/2020 - Claudia - Incluida a gravação e exclusão de parametros na SXK. GLPI: 10071
// 02/07/2021 - Claudia - Incluido campo CNAE. GLPI: 10354
// 02/07/2021 - Claudia - Incluido valor do funrural. GLPI: 10177
// 27/07/2021 - Robert  - Incluida coluna NCM (B1_POSIPI) do produto (GLPI 10591).
//                      - Passa a somar a coluna D2_VALFRE no "Valor bruto" e "Valor total NF" (GLPI 10579).
// 27/08/2021 - Cláudia - Incluida as colunas Id pagar-me e NSU pagarme e link cielo. GLPI 10830
// 01/07/2022 - Claudia - Ajuste na opção mesoregiao. GLPI: 12297
// 14/12/2022 - Claudia - Inclusão de tratamento notas de complemento no valor mercadoria. GLPI: 12852
// 01/03/2023 - Claudia - Ajustado filtro de filial e amarração SC5 X FAT_DADOS. GLPI: 13216
//
// ---------------------------------------------------------------------------------------------------------------
User Function VA_XLS5 (_lAutomat)
	Local cCadastro  := "Exportacao geral de dados de faturamento para planilha"
	Local aSays      := {}
	Local aButtons   := {}
	Local nOpca      := 0
	Local lPerg      := .F.
	local _nLock     := 0
	local _sTipo     := 'T'
	private _lSelCol := .F.  // Para controlar se jah chamou as opcoes.
	private _sOpcoes := ""   // Opcoes (colunas) selecionadas pelo usuario, em formato string para guardar nos parametros do SX1.
	private _aOpcoes := {}   // Opcoes (colunas) selecionadas pelo usuario.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	if u_zzuvl ('120', __cUserId, .F.) .or. u_zzuvl ('038', __cUserId, .F.) 
		if u_zzuvl ('120', __cUserId, .F.) 
			_sTipo := 'P'
		else
			_sTipo := 'T'
		endif
	else
		u_help("Usuario '" + __cUserId + "' sem liberacao (ou nao cadastrado) no grupo.")
		return
	endif

	// Somente uma estacao por vez, pois a rotina eh pesada e certos usuarios derrubam o client na estacao e mandam rodar novamente...
	_nLock := U_Semaforo (procname ())
	if _nLock == 0
		u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.")
		return
	endif

	Private cPerg   := "VAXLS5"
	_ValidPerg()
	Pergunte(cPerg,.F.)
	_sOpcoes = mv_par19 + mv_par22

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo gerar uma")
		AADD(aSays,"exportacao geral de dados de faturamento para planilha")
		AADD(aSays,"")
		
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk(_sTipo) , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 11,.T.,{|| _Opcoes (_sTipo)}})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
	
	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif
return
//
// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk(_sTipo)
	Local _lRet     := .T.
	local _oDUtil   := NIL
	
	if _lRet
		_oDUtil := ClsDUtil ():New ()
		if _oDUtil:DifMeses (mv_par17, mv_par18) > 12
			u_help ("Esta consulta gera grandes volumes de dados e, por este motivo, sao permitidos periodos de no maximo 12 meses.")
			_lRet = .F.
		endif
	endif

	if _lRet .and. ! _lSelCol
		_Opcoes (_sTipo)
	endif
Return _lRet
//
// --------------------------------------------------------------------------
// Seleciona opcoes especificas do relatorio.
Static Function _Opcoes (_sTipo)
	local _aCols     := {}
	local _sSelVlMer := "(V.TOTAL + V.PVCOND)"
	local _sSelComi1 := "(" + _sSelVlMer + ") * V.COMIS1 / 100"
	local _sSelComi2 := "(" + _sSelVlMer + ") * V.COMIS2 / 100"
	local _sSelComi3 := "(" + _sSelVlMer + ") * V.COMIS3 / 100"
	local _sSelComi4 := "(" + _sSelVlMer + ") * V.COMIS4 / 100"
	local _sSelComi5 := "(" + _sSelVlMer + ") * V.COMIS5 / 100"
	local _sSelCusto := "V.CUSTOREPOS*V.QUANTIDADE"
	local _nOpcao    := 0

	// exclui SXK para não duplicar as perguntas
	U_GravaSXK (cPerg, "19", mv_par19, 'D' )
	U_GravaSXK (cPerg, "22", mv_par22, 'D' )

	// Monta array de opcoes de campos, jah com o respectivo trecho para uso na query.
	_aOpcoes = {}
	If _sTipo == 'P'
		aadd (_aOpcoes, {.F., "Fat/bonif",                "CASE WHEN V.F4_MARGEM='1' THEN 'FATURADO' WHEN V.F4_MARGEM='2' THEN 'DEVOLUCAO' WHEN V.F4_MARGEM='3' THEN 'BONIFICADO' WHEN V.F4_MARGEM='4' THEN 'COMODATO' WHEN V.F4_MARGEM='5' THEN 'RET.COMODATO' WHEN V.F4_MARGEM='6' THEN 'FRETE' WHEN V.F4_MARGEM='7' THEN 'SERVICOS' WHEN V.F4_MARGEM='8' THEN 'USO E CONSUMO' WHEN V.F4_MARGEM='9' THEN 'NAO SE APLICA' ELSE V.F4_MARGEM END AS FAT_BONIF"})
		aadd (_aOpcoes, {.F., "Filial",                   "SM0.M0_FILIAL AS FILIAL"})
		aadd (_aOpcoes, {.F., "Emissao",                  "SUBSTRING (V.EMISSAO, 7, 2) + '/' + SUBSTRING (V.EMISSAO, 5, 2) + '/' + SUBSTRING (V.EMISSAO, 1, 4) AS EMISSAO"})
		aadd (_aOpcoes, {.F., "Mes/ano emissao",          "SUBSTRING (V.EMISSAO, 5, 2) + '/' + SUBSTRING (V.EMISSAO, 1, 4) AS MES_EMIS"})
		aadd (_aOpcoes, {.F., "Nome linha produtos",      "RTRIM(ISNULL(ZX5_39.ZX5_39DESC,'')) AS LINHA"})
		aadd (_aOpcoes, {.F., "Codigo produto",           "V.PRODUTO AS CODIGO"})
		aadd (_aOpcoes, {.F., "Descricao produto",        "RTRIM (SB1.B1_DESC) AS DESCRICAO"})
		aadd (_aOpcoes, {.F., "Embalagem",                "RTRIM (ISNULL (ZX5_50.ZX5_50DESC, '')) AS EMBALAGEM"})
		aadd (_aOpcoes, {.F., "Litros",                   "SB1.B1_LITROS AS LITROS"})
		aadd (_aOpcoes, {.F., "Litragem",                 "V.QTLITROS * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END AS LITRAGEM"})
		aadd (_aOpcoes, {.F., "Unid.medida produto",      "V.UMPROD AS UN_MEDIDA"})
		aadd (_aOpcoes, {.F., "Quant. em caixas",         "V.QTCAIXAS * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS QT_CAIXAS"})
		aadd (_aOpcoes, {.F., "Marca comercial",          "RTRIM (ISNULL (ZX5_40.ZX5_40DESC, '')) AS MARCA"})
	else
		aadd (_aOpcoes, {.F., "Empresa",                  "SM0.M0_NOME AS EMPRESA"})
		aadd (_aOpcoes, {.F., "Filial",                   "SM0.M0_FILIAL AS FILIAL"})
		aadd (_aOpcoes, {.F., "NF",                       "V.DOC AS NF"})
		aadd (_aOpcoes, {.F., "Emissao",                  "SUBSTRING (V.EMISSAO, 7, 2) + '/' + SUBSTRING (V.EMISSAO, 5, 2) + '/' + SUBSTRING (V.EMISSAO, 1, 4) AS EMISSAO"})
		aadd (_aOpcoes, {.F., "Mes/ano emissao",          "SUBSTRING (V.EMISSAO, 5, 2) + '/' + SUBSTRING (V.EMISSAO, 1, 4) AS MES_EMIS"})
		aadd (_aOpcoes, {.F., "Serie",                    "V.SERIE"})
		aadd (_aOpcoes, {.F., "Pedido",                   "PEDVENDA"})
		aadd (_aOpcoes, {.F., "Fat/bonif",                "CASE WHEN V.F4_MARGEM='1' THEN 'FATURADO' WHEN V.F4_MARGEM='2' THEN 'DEVOLUCAO' WHEN V.F4_MARGEM='3' THEN 'BONIFICADO' WHEN V.F4_MARGEM='4' THEN 'COMODATO' WHEN V.F4_MARGEM='5' THEN 'RET.COMODATO' WHEN V.F4_MARGEM='6' THEN 'FRETE' WHEN V.F4_MARGEM='7' THEN 'SERVICOS' WHEN V.F4_MARGEM='8' THEN 'USO E CONSUMO' WHEN V.F4_MARGEM='9' THEN 'NAO SE APLICA' ELSE V.F4_MARGEM END AS FAT_BONIF"})
		aadd (_aOpcoes, {.F., "Cod.cliente",              "V.CLIENTE AS CODCLI"})
		aadd (_aOpcoes, {.F., "Nome cliente",             "RTRIM (SA1.A1_NOME) AS CLIENTE"})
		aadd (_aOpcoes, {.F., "Segmento cliente",         "RTRIM(DESCRIATIV) AS SEGMENTO"})
		aadd (_aOpcoes, {.F., "Nome linha produtos",      "RTRIM(ISNULL(ZX5_39.ZX5_39DESC,'')) AS LINHA"})
		aadd (_aOpcoes, {.F., "Codigo produto",           "V.PRODUTO AS CODIGO"})
		aadd (_aOpcoes, {.F., "Descricao produto",        "RTRIM (SB1.B1_DESC) AS DESCRICAO"})
		aadd (_aOpcoes, {.F., "Embalagem",                "RTRIM (ISNULL (ZX5_50.ZX5_50DESC, '')) AS EMBALAGEM"})
		aadd (_aOpcoes, {.F., "Litragem",                 "V.QTLITROS * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END AS LITRAGEM"})
		aadd (_aOpcoes, {.F., "Unid.medida produto",      "V.UMPROD AS UN_MEDIDA"})
		aadd (_aOpcoes, {.F., "Quant. em caixas",         "V.QTCAIXAS * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS QT_CAIXAS"})
		aadd (_aOpcoes, {.F., "Peso bruto",               "V.PESOBRUTO * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END AS PESOBRUTO"})
		aadd (_aOpcoes, {.F., "Estado (UF)",              "SA1.A1_EST AS ESTADO"})
		aadd (_aOpcoes, {.F., "Regiao",                   "RTRIM (SA1.A1_REGIAO) AS REGIAO"})
		aadd (_aOpcoes, {.F., "Mesoregiao",               "RTRIM (ZB_MESO) AS MESOREGIAO"})
		aadd (_aOpcoes, {.F., "Municipio",                "RTRIM (SA1.A1_MUN) MUNICIPIO"})
		aadd (_aOpcoes, {.F., "Nome Representante 1",     "RTRIM (A3_NOME) AS REPRES"})
		aadd (_aOpcoes, {.F., "Valor mercadoria",         "CASE WHEN V.TIPONFSAID = 'C' THEN 0 ELSE "+_sSelVlMer + " * (CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END) END AS VALMERC"})
	//	aadd (_aOpcoes, {.F., "Valor mercadoria",         _sSelVlMer + " * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END AS VALMERC"})
	//	aadd (_aOpcoes, {.F., "Valor bruto",              "(V.TOTAL + V.VALIPI + V.SEGURO + V.DESPESA + V.PVCOND + V.ICMSRET) * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END AS VALBRUT"})
		aadd (_aOpcoes, {.F., "Valor bruto",              "(V.TOTAL + V.VALIPI + V.SEGURO + V.DESPESA + V.PVCOND + V.ICMSRET + V.D2_VALFRE) * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END AS VALBRUT"})
		aadd (_aOpcoes, {.F., "Valor ICMS",               "V.VALICM * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS ICMS"})
		aadd (_aOpcoes, {.F., "Valor IPI",                "V.VALIPI * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS IPI"})
		aadd (_aOpcoes, {.F., "Valor PIS",                "V.VALPIS * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS PIS"})
		aadd (_aOpcoes, {.F., "Valor COFINS",             "V.VALCOFINS * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS COFINS"})
		aadd (_aOpcoes, {.F., "Valor comissao 1",         _sSelComi1 + " * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS COMISSAO1"})
		aadd (_aOpcoes, {.F., "Valor comissao 2",         _sSelComi2 + " * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS COMISSAO2"})
		aadd (_aOpcoes, {.F., "Valor comissao 3",         _sSelComi3 + " * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS COMISSAO3"})
		aadd (_aOpcoes, {.F., "Valor comissao 4",         _sSelComi4 + " * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS COMISSAO4"})
		aadd (_aOpcoes, {.F., "Valor comissao 5",         _sSelComi5 + " * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS COMISSAO5"})
		aadd (_aOpcoes, {.F., "Valor rapel padrao",       "V.RAPELPREV * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS RAPELPADR"})
		aadd (_aOpcoes, {.F., "Base Rapel",               "V.BASERAPEL AS BASERAPEL"})
		aadd (_aOpcoes, {.F., "Valor custo standard",     _sSelCusto + " * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS CUSTO_STD"})
		aadd (_aOpcoes, {.F., "Tipo frete (CIF/FOB)",     "V.TIPOFRETE AS TIPOFRETE"})
		aadd (_aOpcoes, {.F., "Valor previsto frete",     "FRETEPREV AS FRETEPREV"})
		aadd (_aOpcoes, {.F., "Valor real frete",         "V.VALORFRETE AS FRETEREAL"})
		aadd (_aOpcoes, {.F., "Valor frete redespacho",   "V.FRETEREDSP AS REDESP"})
		aadd (_aOpcoes, {.F., "Margem contribuicao",      "V.MARGEMCONT * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS MARGEM"})
		aadd (_aOpcoes, {.F., "Nome transportadora",      "RTRIM (A4_NOME) AS TRANSP"})
		aadd (_aOpcoes, {.F., "Valor ST (subst.trib.)",   "V.ICMSRET * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS VALOR_ST"})
		aadd (_aOpcoes, {.F., "Desc.fin.rapel",           "V.DFRAPEL * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS DF_RAPEL"})
		aadd (_aOpcoes, {.F., "Desc.fin.encartes",        "V.DFENCART * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS DF_ENCART"})
		aadd (_aOpcoes, {.F., "Desc.fin.feiras",          "V.DFFEIRAS * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS DF_FEIRAS"})
		aadd (_aOpcoes, {.F., "Desc.fin.fretes",          "V.DFFRETES * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS DF_FRETES"})
		aadd (_aOpcoes, {.F., "Desc.fin.normais",         "V.DFDESCONT * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS DF_NORMAIS"})
		aadd (_aOpcoes, {.F., "Desc.fin.devolucoes",      "V.DFDEVOL * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS DF_DEVOL"})
		aadd (_aOpcoes, {.F., "Desc.fin.campanhas",       "V.DFCAMPANH * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS DF_CAMPANH"})
		aadd (_aOpcoes, {.F., "Desc.fin.abert.loja",      "V.DFABLOJA * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS DF_ABLOJA"})
		aadd (_aOpcoes, {.F., "Desc.fin.multas contrat",  "V.DFCONTRAT * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS DF_CONTRAT"})
		aadd (_aOpcoes, {.F., "Desc.fin.outros",          "V.DFOUTROS * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS DF_OUTROS"})
		aadd (_aOpcoes, {.F., "Marca comercial",          "RTRIM (ISNULL (ZX5_40.ZX5_40DESC, '')) AS MARCA"})
		aadd (_aOpcoes, {.F., "Prazo medio venda (dias)", "V.PRAZOMEDIO AS PRAZOMEDIO"})
		aadd (_aOpcoes, {.F., "Tipo pessoa (fis/jurid)",  "CASE SA1.A1_PESSOA WHEN 'F' THEN 'FISICA' WHEN 'J' THEN 'JURIDICA' WHEN 'X' THEN 'EXTERIOR' ELSE '?' END AS PESSOA"})
		aadd (_aOpcoes, {.F., "CNPJ cliente",             "dbo.VA_FORMATA_CGC (SA1.A1_CGC) AS CNPJ_CLI"})
		aadd (_aOpcoes, {.F., "Valor frete paletizacao",  "V.FRETEPALET * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END  AS FRTPALETIZ"})
		aadd (_aOpcoes, {.F., "PVCond",                   "V.PVCOND * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END as PVCOND"})
	//	aadd (_aOpcoes, {.F., "Valor total NF",           "(" + _sSelVlMer + " - V.PVCOND + V.VALIPI + V.ICMSRET) * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END AS VL_TOT_NF"})
		aadd (_aOpcoes, {.F., "Valor total NF",           "(" + _sSelVlMer + " - V.PVCOND + V.VALIPI + V.ICMSRET + D2_VALFRE) * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END AS VL_TOT_NF"})
		aadd (_aOpcoes, {.F., "Msg Adicionais",           "RTRIM(C5_MENNOTA) AS MSGADIC"})
		aadd (_aOpcoes, {.F., "Numero de Serie",          "RTRIM(C6_VANSER) AS NUMSER"})
		aadd (_aOpcoes, {.F., "Obs do Pedido",            "REPLACE(ISNULL(REPLACE (REPLACE ( REPLACE ( CAST(RTRIM (CAST (C5_OBS AS VARBINARY (8000))) AS VARCHAR (8000)) , char(13), ''), char(10), ''), char(14), ''),''),char(34),' ') AS OBSPED"})
		aadd (_aOpcoes, {.F., "Mix comercial do produto", "CASE SB1.B1_VAMIX WHEN 'F' THEN 'FOCO' WHEN 'T' THEN 'TRANSICAO' WHEN 'A' THEN 'EM ANALISE' ELSE SB1.B1_VAMIX END AS MIX_COML"})
		aadd (_aOpcoes, {.F., "Ano emissao",              "SUBSTRING (V.EMISSAO, 1, 4) AS ANO_EMIS"})
		aadd (_aOpcoes, {.F., "Origem dos dados",         "CASE V.ORIGEM WHEN 'SD2' THEN 'NF SAIDA' WHEN 'SD1' THEN 'NF ENTRADA' ELSE V.ORIGEM END AS ORIGEM"})
		aadd (_aOpcoes, {.F., "Canal de vendas",          "RTRIM (DESCRICANAL) AS CANAL"})
		aadd (_aOpcoes, {.F., "Codigo matriz cliente",    "SA1.A1_VACBASE AS COD_MAT_CLI"})
		aadd (_aOpcoes, {.F., "Loja matriz cliente",      "SA1.A1_VALBASE AS LOJ_MAT_CLI"})
		aadd (_aOpcoes, {.F., "Nome matriz cliente",      "RTRIM (ISNULL (SA1BASE.A1_NOME, '')) AS MATRIZ_CLIENTE"})
		aadd (_aOpcoes, {.F., "Descricao do TES",         "RTRIM (ISNULL (SF4.F4_TEXTO, '')) AS DESCRICAO_TES"})
		aadd (_aOpcoes, {.F., "Cod.representante 1",      "V.VEND1"})
		aadd (_aOpcoes, {.F., "Motivo de DEVOLUÇÃO",      "V.MOTDEV"})
		aadd (_aOpcoes, {.F., "Cod.Supervisor",           "A3_VAGEREN"})
		aadd (_aOpcoes, {.F., "Cod.promotor",             "SA1.A1_VAPROMO AS PROMOTOR"})
		aadd (_aOpcoes, {.F., "Nome promotor",            "RTRIM (ISNULL ((SELECT A2_NOME FROM " + RetSQLName ("SA2") + " AS SA2FOR WHERE SA2FOR.D_E_L_E_T_ = '' AND SA2FOR.A2_COD = SA1.A1_VAPROMO), '')) AS NOME_PROMOTOR"})
		//aadd (_aOpcoes, {.F., "Nome promotor",            "RTRIM (ISNULL ((SELECT ZX5_46DESC FROM " + RetSQLName ("ZX5") + " WHERE D_E_L_E_T_ = '' AND ZX5_FILIAL = '  ' AND ZX5_TABELA = '46' AND ZX5_46COD = SA1.A1_VAPROMO), '')) AS NOME_PROMOTOR"})
		aadd (_aOpcoes, {.F., "Custo medio do movto",     "CUSTOMEDIO"})
		aadd (_aOpcoes, {.F., "Tipo embalagem",           "RTRIM (ISNULL ((SELECT ZAZ_NLINF FROM " + RetSQLName ("ZAZ") + " WHERE D_E_L_E_T_ = '' AND ZAZ_FILIAL = '" + xfilial ("ZAZ") + "' AND ZAZ_CLINF = SB1.B1_CLINF), '')) AS TIPO_EMBALAGEM"})
		aadd (_aOpcoes, {.F., "Agrupador unitário",       "CASE WHEN (SB1.B1_CODPAI <> '')  THEN  SB1.B1_CODPAI ELSE SB1.B1_COD END AS AGRUPADOR_UNITARIO"})
		aadd (_aOpcoes, {.F., "Ato cooperativo/não coop.","CASE WHEN (B1_VAATO = 'S')  THEN  'Cooperativo' ELSE 'Nao Cooperativo' END AS ATO"})
		aadd (_aOpcoes, {.F., "Linha de envase",          "RTRIM (ISNULL ((SELECT H1_DESCRI FROM " + RetSqlName ("SH1") + " WHERE D_E_L_E_T_ <> '*' AND H1_FILIAL = '" + xfilial ("sh1") + "' AND H1_CODIGO = B1_VALINEN), '')) AS LINHA_ENVASE"})
		aadd (_aOpcoes, {.F., "Valor NET",                "VALOR_NET * CASE V.ORIGEM WHEN 'SD1' THEN -1 ELSE 1 END AS VALOR_NET"})
		aadd (_aOpcoes, {.F., "Cód CNAE ",                "SA1.A1_CNAE AS CNAE"})
		aadd (_aOpcoes, {.F., "Desc. CNAE ",              "CC3.CC3_DESC AS CNAE_DESC"})
		aadd (_aOpcoes, {.F., "Vlr. Funrural ",           "IIF(SAFRA.VLR_FUNRURAL > 0, SAFRA.VLR_FUNRURAL, 0) AS VLR_FUNRURAL"})
		aadd (_aOpcoes, {.F., "NCM",                      "SB1.B1_POSIPI"})
		aadd (_aOpcoes, {.F., "Id Pagar-me",              "C5_VAIDT"})
		aadd (_aOpcoes, {.F., "NSU Pagar-me/Link Cielo",  "C5_VANSU"})
		aadd (_aOpcoes, {.F., "Tipo bonificacao",         "CASE WHEN C5_VABTPO = '1' THEN '1=Negoc.Comercial' WHEN C5_VABTPO = '2' THEN '2=Doacao' WHEN C5_VABTPO = '3' THEN '3=Acao MKT' WHEN C5_VABTPO = '4' THEN '4=Merchandising' WHEN C5_VABTPO = '5' THEN '5=Introd.Produto ' ELSE '' END AS TIPO_BONIF"})
		aadd (_aOpcoes, {.F., "Pedido venda bonificacao", "C5_VABREF AS PEDVEN_BONIF"})
	endif
	// Pre-seleciona opcoes cfe. conteudo anterior.
	for _nOpcao = 1 to len (_aOpcoes)
		_aOpcoes [_nOpcao, 1] = (substr (_sOpcoes, _nOpcao, 1) ==  "S")
	next

	// Browse para usuario selecionar as opcoes
	_aCols = {}
	aadd (_aCols, {2, "Coluna",  80,  ""})
	aadd (_aCols, {3, "Formula", 260, ""})
	U_MBArray (@_aOpcoes, "Selecione as colunas a exportar", _aCols, 1, 700, 450, , ".T.")

	// Atualiza as opcoes selecionadas no arquivo de parametros do usuario.
	_sOpcoes = ""
	for _nOpcao = 1 to len (_aOpcoes)
		_sOpcoes += iif (_aOpcoes [_nOpcao, 1], "S", "N")
	next
	mv_par19 = substr (_sOpcoes, 1, 60)
	mv_par22 = substr (_sOpcoes, 61, 60)
	U_GravaSX1 (cPerg, "19", mv_par19)
	U_GravaSX1 (cPerg, "22", mv_par22)

	// Grava SXK para salvar opções
	U_GravaSXK (cPerg, "19", mv_par19, 'G' )
	U_GravaSXK (cPerg, "22", mv_par22, 'G' )

	// Indica que as opcoes jah foram selecionadas ou, pelo menos, visualizadas.
	_lSelCol = .T.
Return
//
// --------------------------------------------------------------------------
// Gera relatório
Static Function _Gera()
	local _sQuery    := ""
	local _sAliasQ   := ""
	local _nOpcao    := 0

	u_logsx1 (cPerg)

	procregua (10)

	// Monta comando 'Select' com as informacoes das colunas selecionadas pelo usuario.
	_sQuery := ""
	for _nOpcao = 1 to len (_aOpcoes)
		if _aOpcoes [_nOpcao, 1]
			_sQuery += chr (13) + chr (10)  // Apenas para facilitar a leitura da query, caso necessario.
			_sQuery += alltrim (_aOpcoes [_nOpcao, 3]) + ", "
		endif
	next

	_sQuery = substr (_sQuery, 1, len (_sQuery) - 2)  // Remove virgula do final.
	if empty (_sQuery)
		u_help ("Deve ser selecionada pelo menos uma coluna para exportacao")
		return
	endif

	// Busca dados
	incproc ("Buscando dados")
	_sQuery := "select " + _sQuery
	_sQuery +=   " from " + RetSQLName ("SB1") + " SB1"
	_sQuery +=              ","
	_sQuery +=              RetSQLName ("SA1") + " SA1"
	_sQuery +=            " left join " + RetSQLName ("SA1") + " SA1BASE "
	_sQuery +=                 " on (SA1BASE.D_E_L_E_T_ != '*'"
	_sQuery +=                 " and SA1BASE.A1_FILIAL   = SA1.A1_FILIAL"
	_sQuery +=                 " and SA1BASE.A1_COD      = SA1.A1_VACBASE"
	_sQuery +=                 " and SA1BASE.A1_LOJA     = SA1.A1_VALBASE)"
	_sQuery +=            " LEFT JOIN " + RetSQLName ("CC3") + " CC3 "
	_sQuery +=                 " ON(CC3.D_E_L_E_T_=''"
	_sQuery +=                 " AND CC3.CC3_COD = SA1.A1_CNAE)"
    if "ZB_" $ upper (_sQuery)
    	_sQuery +=         "LEFT JOIN "+ RetSQLName ("SZB") + " SZB"
		_sQuery +=    			" ON (SZB.ZB_FILIAL      = '" + xfilial ("SZB") + "'"
		_sQuery +=    			" AND SZB.ZB_COD         = SA1.A1_CMUN)"
	endif
	_sQuery +=            " ,BI_ALIANCA.dbo.VA_FATDADOS as V "
    if "A3_" $ upper (_sQuery)
		_sQuery +=            " left join " + RetSQLName ("SA3") + " SA3 "
		_sQuery +=                 " on (SA3.D_E_L_E_T_ != '*'"
		_sQuery +=                 " and SA3.A3_FILIAL   = '" + xfilial ("SA3") + "'"
		_sQuery +=                 " and SA3.A3_COD      = V.VEND1)"
	endif
    if "A4_" $ upper (_sQuery)
		_sQuery +=            " left join " + RetSQLName ("SA4") + " SA4 "
		_sQuery +=                 " on (SA4.D_E_L_E_T_ != '*'"
		_sQuery +=                 " and SA4.A4_FILIAL   = '" + xfilial ("SA4") + "'"
		_sQuery +=                 " and SA4.A4_COD      = V.TRANSP)"
	endif
    if "M0_" $ upper (_sQuery)
		_sQuery +=            " left join VA_SM0 SM0"
		_sQuery +=                 " on (SM0.D_E_L_E_T_ != '*'"
		_sQuery +=                 " and SM0.M0_CODIGO   = V.EMPRESA"
		_sQuery +=                 " and SM0.M0_CODFIL   = V.FILIAL)"
	endif
    if "ZX5_39" $ upper (_sQuery)
		_sQuery +=            " left join " + RetSQLName ("ZX5") + " ZX5_39 "
		_sQuery +=                 " on (ZX5_39.D_E_L_E_T_ != '*'"
		_sQuery +=                 " and ZX5_39.ZX5_FILIAL   = '" + xfilial ("ZX5") + "'"
		_sQuery +=                 " and ZX5_39.ZX5_TABELA   = '39'"
		_sQuery +=                 " and ZX5_39.ZX5_39COD    = V.CODLINHA)"
	endif
    if "ZX5_50" $ upper (_sQuery)
		_sQuery +=            " left join " + RetSQLName ("ZX5") + " ZX5_50 "
		_sQuery +=                 " on (ZX5_50.D_E_L_E_T_ != '*'"
		_sQuery +=                 " and ZX5_50.ZX5_FILIAL  = '" + xfilial ("ZX5") + "'"
		_sQuery +=                 " and ZX5_50.ZX5_TABELA  = '50'"
		_sQuery +=                 " and ZX5_50.ZX5_50COD   = V.GRPEMB)"
	endif
    if "ZX5_40" $ upper (_sQuery)
		_sQuery +=            " left join " + RetSQLName ("ZX5") + " ZX5_40 "
		_sQuery +=                 " on (ZX5_40.D_E_L_E_T_ != '*'"
		_sQuery +=                 " and ZX5_40.ZX5_FILIAL   = '" + xfilial ("ZX5") + "'"
		_sQuery +=                 " and ZX5_40.ZX5_TABELA   = '40'"
		_sQuery +=                 " and ZX5_40.ZX5_40COD = V.MARCA)"
	endif
	_sQuery +=            " left join " + RetSQLName ("SF4") + " SF4 "
	_sQuery +=                 " on (SF4.D_E_L_E_T_ != '*'"
	_sQuery +=                 " and SF4.F4_FILIAL   = '" + xfilial ("SF4") + "'"
	_sQuery +=                 " and SF4.F4_CODIGO   = V.TES)"     
	_sQuery +=            "	 LEFT JOIN VA_VNOTAS_SAFRA SAFRA "
	_sQuery +=            "		 ON (SAFRA.FILIAL = V.FILIAL"
	_sQuery +=            "		 AND SAFRA.DOC = V.DOC"
	_sQuery +=            "		 AND SAFRA.SERIE = V.SERIE"
	_sQuery +=            "		 AND SAFRA.ASSOCIADO = V.CLIENTE"
	_sQuery +=            "		 AND SAFRA.LOJA_ASSOC = V.LOJA)"                       
    if "C5_" $ upper (_sQuery) //.or. "C6_" $ upper (_sQuery)
		// Fazer teste se estes campos foram selecionados para efetivamente incluir o teste
		_sQuery +=            " left join " + RetSQLName ("SC5") + " SC5 "
		_sQuery +=                 " on (SC5.D_E_L_E_T_ != '*'"
		_sQuery +=                 " and SC5.C5_FILIAL   = V.FILIAL "
		_sQuery +=                 " and SC5.C5_NUM      = V.PEDVENDA)"
		/*_sQuery +=            " left join " + RetSQLName ("SC6") + " SC6 "
		_sQuery +=                 " on (SC6.D_E_L_E_T_ != '*'"
		_sQuery +=                 " and SC6.C6_FILIAL   = '" + xfilial ("SC6") + "'"
		_sQuery +=                 " and SC6.C6_NUM      = V.PEDVENDA "
		_sQuery +=                 " and SC6.C6_ITEM     = V.ITEMPDVEND)"*/
    endif
	_sQuery +=  " where SB1.D_E_L_E_T_    != '*'"
	_sQuery +=    " and SB1.B1_FILIAL      = '" + xfilial ("SB1") + "'"
	_sQuery +=    " and SB1.B1_COD         = V.PRODUTO"
	_sQuery +=    " and SA1.D_E_L_E_T_    != '*'"
	_sQuery +=    " and SA1.A1_FILIAL      = '" + xfilial ("SA1") + "'"
	_sQuery +=    " and SA1.A1_COD         = V.CLIENTE"
	_sQuery +=    " and SA1.A1_LOJA        = V.LOJA"
    _sQuery +=    " and V.TIPONFSAID      != 'B'"  // Beneficiamento
    _sQuery +=    " and V.TIPONFSAID      != 'D'"  // Devolucao de compra
   	if mv_par23 == 1  // Apenas fatur.e bonif 
   	   	_sQuery +=" AND (V.F4_MARGEM = '2' AND V.ORIGEM='SD1' AND V.TIPONFENTR='D' OR (V.ORIGEM='SD2' AND V.F4_MARGEM IN ('1','3') ) )"
  	endif      
 	_sQuery +=    " and V.FILIAL          between '" + mv_par01 + "' and '" + mv_par02 + "'"
	_sQuery +=    " and SA1.A1_REGIAO     between '" + mv_par03 + "' and '" + mv_par04 + "'"
	_sQuery +=    " and V.EST             between '" + mv_par05 + "' and '" + mv_par06 + "'"
	_sQuery +=    " and V.VEND1           between '" + mv_par07 + "' and '" + mv_par08 + "'"
	_sQuery +=    " and V.VEND2           between '" + mv_par20 + "' and '" + mv_par21 + "'"
	_sQuery +=    " and B1_CODLIN         between '" + mv_par09 + "' and '" + mv_par10 + "'"
	_sQuery +=    " and B1_TIPO           between '" + mv_par11 + "' and '" + mv_par12 + "'"
	_sQuery +=    " and V.EMISSAO         between '" + dtos (mv_par17) + "' and '" + dtos (mv_par18) + "'"
	_sQuery +=    " and V.CLIENTE+V.LOJA  between '" + mv_par13 + mv_par14 + "' and '" + mv_par15 + mv_par16 + "'"

	u_log2 ('info', _sQuery)
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)

	u_log2 ('debug', "Gerando arquivo de exportacao")
	incproc ("Gerando arquivo de exportacao")
	processa ({ || U_Trb2XLS (_sAliasQ, .F.)})

	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("SD2")
	u_log2 ('debug', 'Arquivo exportado.')
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes            Help
	aadd (_aRegsPerg, {01, "Filial Inicial               ?", "C", 02, 0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {02, "Filial Final                 ?", "C", 02, 0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {03, "Regiao Inicial               ?", "C", 03, 0,  "",   "82   ", {},             ""})
	aadd (_aRegsPerg, {04, "Regiao Final                 ?", "C", 03, 0,  "",   "82   ", {},             ""})
	aadd (_aRegsPerg, {05, "Estado Inicial               ?", "C", 02, 0,  "",   "12   ", {},             ""})
	aadd (_aRegsPerg, {06, "Estado Final                 ?", "C", 02, 0,  "",   "12   ", {},             ""})
	aadd (_aRegsPerg, {07, "Vendedor 1 Inicial           ?", "C", 06, 0,  "",   "SA3  ", {},             ""})
	aadd (_aRegsPerg, {08, "Vendedor 1 Final             ?", "C", 06, 0,  "",   "SA3  ", {},             ""})
	aadd (_aRegsPerg, {09, "Linha Inicial                ?", "C", 02, 0,  "",   "ZX539", {},             ""})
	aadd (_aRegsPerg, {10, "Linha Final                  ?", "C", 02, 0,  "",   "ZX539", {},             ""})
	aadd (_aRegsPerg, {11, "Tipo Produto Inicial         ?", "C", 02, 0,  "",   "02   ", {},             ""})
	aadd (_aRegsPerg, {12, "Tipo Produto Final           ?", "C", 02, 0,  "",   "02   ", {},             ""})
	aadd (_aRegsPerg, {13, "Cliente Inicial              ?", "C", 06, 0,  "",   "SA1  ", {},             ""})
	aadd (_aRegsPerg, {14, "Loja cliente inicial         ?", "C", 02, 0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {15, "Cliente Final                ?", "C", 06, 0,  "",   "SA1  ", {},             ""})
	aadd (_aRegsPerg, {16, "Loja cliente final           ?", "C", 02, 0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {17, "Data inicial do faturamento  ?", "D", 08, 0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {18, "Data final do faturamento    ?", "D", 08, 0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {19, "Uso interno da rotina         ", "C", 60, 0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {20, "Vendedor 2 Inicial           ?", "C", 06, 0,  "",   "SA3  ", {},             ""})
	aadd (_aRegsPerg, {21, "Vendedor 2 Final             ?", "C", 06, 0,  "",   "SA3  ", {},             ""})
	aadd (_aRegsPerg, {22, "Uso interno da rotina         ", "C", 60, 0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {23, "Apenas fatur.e bonif          ", "N", 01, 0,  "",   "     ", {"Sim", "Nao"}, ""})

	aadd (_aDefaults, {"20", ''})
	aadd (_aDefaults, {"21", 'zzzzzz'})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
