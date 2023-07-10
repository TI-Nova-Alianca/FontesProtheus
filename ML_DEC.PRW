// Programa.: ML_DEC
// Autor....: Jeferson Rech
// Data.....: dez/2001
// Descricao: Gera Arq. TXT p/ Declaracao de Vinicolas (SisDeclara)
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #consulta
// #Descricao         #Gera Arq. TXT p/ Declaracao de Vinicolas (SisDeclara)
// #PalavasChave      #sisdevin
// #TabelasPrincipais #SF1 #SF2 #SB1 #SF4
// #Modulos           
//
// Historico de alteracoes:
// 04/07/2008 - Robert  - Ajustes na formatacao da serie e numero da NF (registro tipo 20)
// 04/08/2008 - Robert  - Aumentado tamanho do campo M0_INSC, que removia a posicao 4.
//                      - Alterado e-mail de contato (de alianca@alianca... para geyce@alianca...)
// 02/12/2008 - Robert  - Criado tratamento para serie '10 ' (NF-e)
//                      - E-mail de contato passa a ficar em letras minusculas.
// 25/02/2009 - Robert  - Inclusao de serie no tipo 20.
//                      - Passa a usar o parametro VA_INSCMA.
// 01/12/2009 - Robert  - Alterado e-mail de contato
// 09/04/2010 - Robert  - Ajustes na soma de litragem total (registro tipo 90)
// 03/05/2010 - Robert  - Mostra aviso em caso de litragem zerada.
// 05/06/2010 - Robert  - Ajustes nas perguntas para versao 10
// 30/09/2010 - Robert  - Campo B1_SAFRA vai ser excluido.
// 09/11/2010 - Robert  - Passa a desconsiderar notas de remessa e retorno de deposito fechado.
// 03/01/2011 - Robert  - Ajustes para aumento do tamanho do campo B1_MARPR.
// 27/01/2011 - Robert  - Desabilitada exportacao de dados para filiais.
// 11/05/2011 - Robert  - Busca marcas comerciais no ZX5.
// 13/06/2011 - Robert  - Unificada exportacao de notas de entrada de uva
//                      - Melhoria nos parametros.
//                      - Criada exportacao de transferencias entre filiais.
// 08/07/2011 - Robert  - Campo B1_MARPR separado por filial (B1_VARMAAL, B1_VARMASP, ...)
//                      - Criada exportacao de guias de livre transito
// 13/07/2011 - Robert  - Buscava descricao dos produtos sempre da tabela 90 do SX5. Agora busca cfe. a filial.
// 08/09/2011 - Robert  - Considerava todo o CGC em vez da raiz, entao nao identificava transf. entre filiais.
// 30/10/2011 - Robert  - Passa a usar metodos da classe ClsSisd.
// 30/03/2012 - Robert  - Leitura de notas da uva passa a usar a view VA_VNOTAS_SAFRA.
// 15/05/2012 - Robert  - Unificacao dos campos B1_MARPR, B1_VARMAAL e B1_VARMASP.
// 06/06/2012 - Robert  - Passa a buscar codigo do Sisdeclara na tabela 12 do ZX5.
// 10/09/2012 - Elaine  - Tratamento NF com 9 posicoes
// 08/11/2012 - Robert  - Mais tratamentos para NF com 9 posicoes.
// 13/02/2013 - Robert  - Campo B1_TPPROD passa a ser padrao no Protheus 11. Criado B1_VACOR em seu lugar.
//                      - Melhoradas mensagens de erros e avisos.
// 19/02/2013 - Elaine  - Passar a tratar o campo F4_VASISDE para separar a operacao dos engarrafados 
//                        e dos produtos a granel,faz selecao
//                        dos parâmetros por query e nao mais por dbselectarea (tipos 20N e 20D)
// 26/02/2013 - Elaine  - Passar a exportar/tratar notas de entrada a granel (registro 30 e 31) 
//                        pois o campo F1_VAGUIA foi criado para este tratamento
// 07/03/2013 - Elaine  - No registro 60, nao estava declarado na query o B1_COD 
//                        e estava considerando número da nota com 9 digitos, sendo que
//                        no layout do sisdeclara aceita somente 6, deslocando todos campos que vinham posterior.
// 07/03/2013 - Elaine  - Considerar notas de saidas/entradas cujo tipo seja diferente de C, I, P.
// 12/03/2013 - Elaine  - Tratamento campo F4_VASISEN - Operacao Sisdeclara produtos engarrafados e avisar as TES 
//                        que estão com este e o F4_VASISDE em branco ***
// 10/04/2013 - Robert  - Ajustes para filial 10
// 13/05/2013 - Robert  - Passa a ler campo A2_VAREGMA para notas de entrada de uva, quando pessoa juridica.
// 15/05/2013 - Robert  - Acrescentadas validacoes diversas no cadastro de produtos.
//                      - Nao buscava dados de fornecedor X cliente cfe. tipo da nota nas guias de granel.
// 11/07/2013 - Robert  - Tratamento para buscar cod.pais de fornecedores.
//                      - Tratamento para buscar cod.pais de notas tipo B/D.
// 20/03/2015 - Robert  - Avisa quando campo B1_LITROS estiver vazio nas guias a granel.
// 23/03/2015 - Robert  - Troca codigo de Pinto Bandeira por Bento Goncalves.
// 06/04/2015 - Robert  - Deixa de usar os campos ZQ_NF01, ZQ_NF02, ... e faz toda a leitura do SF2.
// 18/06/2015 - Robert  - View VA_NOTAS_SAFRA renomeada para VA_VNOTAS_SAFRA
// 15/12/2015 - Robert  - Melhorada geracao de logs e validacao entre tipo e classe de produto no cadastro.
// 13/01/2016 - Robert  - Verifica tipo de operacao das guias de saida.
// 18/02/2016 - Robert  - Validacoes de produtos comecam a ser passadas para o metodo ValProd da classe ClsSisd.
// 07/03/2016 - Robert  - Parece que o Sisdeclara finalmente reconheceu a emancipacao de Pinto Bandeira...
// 14/03/2016 - Robert  - Tipo 60 (notas de uva) passa a considerar transf. entre filiais.
// 29/03/2016 - Robert  - Campos do Sisdeclara migrados do SB1 para SB5.
//                      - Melhorias classe ClsSisd.
// 06/04/2016 - Robert  - Verifica se a descricao estah vazia (provavelmente cod.produto inexistente no cadastro).
// 17/05/2016 - Robert  - Campos do Sisdeclara migrados da tabela SB1 para SB5.
// 01/09/2016 - Robert  - Verifica campo ZX5_08ATIV (registro inativo no M.A.).
// 10/10/2016 - Robert  - Tratamento para nova estrutura de codificacao de registros no M.A.
// 29/03/2017 - Robert  - Ignota NF entrada uva antigo condominio (esta ano virou CNPJ) 
//                        pois ainda nao tem inscr. no Minist.Agric.
//                      - Valida e busca dados do responsavel pela tabela 20 do ZX5.
// 18/04/2017 - Robert  - Avisa caso nao consiga definir o 'destino' de uma NF.
// 15/09/2017 - Robert  - Melhorada mensagem quando falta destino/UF nas notas.
// 06/11/2017 - Robert  - Desconsidera notas de transferencia simbolicas feitas em out/2017 
//                        para equalizacao de custos entre filiais.
// 23/11/2017 - Robert  - Passa a trabalhar pelos campos D1_DTDIGIT e F1_DTDIGIT e nao mais pelos 
//                        campos F1_EMISSAO e F1_EMISSAO.
// 11/01/2018 - Robert  -
// 08/06/2018 - Robert  - Ignora quantidades muito pequenas no tipo 20N
// 14/09/2018 - Robert  - Validacoes do produto passadas do A010TOK para ca.
// 11/12/2018 - Robert  - Opcao de gerar planilha de conferencia
//                      - Opcao de exportar ou nao as guias de livre transito (tipo 30)
// 22/03/2019 - Andre   - Trocado erro por aviso na validação A2_VAREGMA.
// 10/01/2020 - Robert  - Ignora algunas NF de saida de suco em dez/2019 que jah foram digitadas 
//                        manualmente no site do Sisdevin.
// 19/03/2021 - Robert  - Tratamento para exportar NF de safra tipo C na safra 2021 (GLPI 9660).
// 05/04/2021 - Robert  - Melhorada msg de aviso quando fornecedor nao tem registro no MA informado.
// 06/05/2021 - Robert  - Inserida mensagem de aviso quando codigo CR zerado no reg. tipo 21 (GLPI 9987)
// 07/07/2021 - Robert  - Desconsidera entradas de produtos oriundos de outros paises (GLPI 10436).
// 26/07/2021 - Robert  - Criado parametro para informar lotes (PA) a desconsiderar (GLPI 10436).
// 05/08/2021 - Robert  - Campo LT_IGNORAR (GLPI 10436) nao havia sido criado para as filiais (GLPI 10653).
// 05/07/2022 - Robert  - Ajustes novo layout 1.3 (GLPI 12307)
//                      - Criada opcao de exportar apenas um movimento de cada tipo (para testes de layout)
// 29/06/2023 - Claudia - Ajustado para novo campo de tipo de operaçao sisdevin F4_VASITO. GLPI: 13815
//
//
// ------------------------------------------------------------------------------------------------------------
User Function ml_dec (_lAutomat)
	Local cCadastro   := "Arquivo p/ Declaracao Vinicola"
	Local aSays       := {}
	Local aButtons    := {}
	Local nOpca       := 0
	Local lPerg       := .F.
	private _lAuto    := iif (_lAutomat == NIL, .F., _lAutomat)
	private _sGranel  := ""
	private _sSOper   := ""

	Private cPerg   := "ML_DEC"
	_ValidPerg ()
	Pergunte (cPerg, .F.)

	AADD (aSays, "Este Programa Tem Como Objetivo Gerar o Arquivo Texto para o")
	AADD (aSays, "Sisdeclara cfe parametros especificados.")

	AADD (aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
	AADD (aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
	AADD (aButtons, { 2,.T.,{|| FechaBatch() }} )

	if _lAuto
		Processa( { |lEnd| GeraTxt() } )
	else
		FormBatch( cCadastro, aSays, aButtons )
		If nOpca == 1
			Processa( { |lEnd| GeraTxt() } )
		Endif
	endif
return
//
// --------------------------------------------------------------------------
// Gera TXT
Static Function GeraTxt()
	local _aArqTrb  := {}
	local _aTipos   := {}
	local _nTipo    := 0
	local _oSisDec  := NIL
	local _nErro    := 0
	local _nAviso   := 0
	local _aCampos  := {}
	local _nProduto	:= 0
	private _aProdutos := {}
	private _aMarcas   := {}
	private _sErros    := ""
	private _sAvisos   := ""
	private _aTotOper  := {}
	private _nHdl      := 0
	private _lSoh1Reg  := .F.

	// Tenho muita manutencao neste programa, entao uso esta opcao para gerar menos registros para teste.
	//	if cUserName == 'robert.koch' .and. dtos (date()) == '20220705'  // Estou em testes
	//		_lSoh1Reg = .T.
	//	endif

	delete file (alltrim (mv_par06))
	_nHdl = fCreate (alltrim (mv_par06))
	If _nHdl==-1
		u_help("O arquivo de nome '" + alltrim (mv_par06) + "' nao pode ser criado! Verifique os parametros.")
		Return
	Endif

	U_LogSX1 (cPerg)
	
	// Cria arquivo de trabalho para preparacao dos dados a exportar.
	_aCampos := {}
	aadd (_aCampos, {"Dados",     "C", 160, 0})
	aadd (_aCampos, {"Grupo",     "C", 2,  0})
	aadd (_aCampos, {"tipo",      "C", 40, 0})
	aadd (_aCampos, {"origem",    "C", 12, 0})
	aadd (_aCampos, {"dtmovto",   "D", 8,  0})
	aadd (_aCampos, {"nf",        "C", 9,  0})
	aadd (_aCampos, {"serie",     "C", 3,  0})
	aadd (_aCampos, {"TES",       "C", 3,  0})
	aadd (_aCampos, {"guia",      "C", 10, 0})
	aadd (_aCampos, {"cli_for",   "C", 6,  0})
	aadd (_aCampos, {"loja",      "C", 2,  0})
	aadd (_aCampos, {"nome",      "C", 30, 0})
	aadd (_aCampos, {"produto",   "C", 15, 0})
	aadd (_aCampos, {"descricao", "C", 40, 0})
	aadd (_aCampos, {"CR",        "C", 15, 0})
	aadd (_aCampos, {"LITROS",    "N", 18, 3})
	U_ArqTrb ("Cria", "_trb", _aCampos, {}, @_aArqTrb)

	// Cria array para acumular litros para mostrar um totalizador de resumo no final da geracao do arquivo
	aadd (_aTotOper, {"Tipo", "Operacao", "Descricao", "Totais"})
	aadd (_aTotOper, {"20", "01", "ENVASADOS - VENDA (litros)", 0})
	aadd (_aTotOper, {"20", "05", "ENVASADOS - COMPRA (litros)", 0})
	aadd (_aTotOper, {"20", "11", "ENVASADOS - ENTRADA DEVOLUCAO (litros)", 0})
	aadd (_aTotOper, {"20", "13", "ENVASADOS - SAIDA TRANSFERENCIA ENTRE FILIAIS (litros)", 0})
	aadd (_aTotOper, {"20", "14", "ENVASADOS - ENTRADA TRANSFERENCIA ENTRE FILIAIS (litros)", 0})
	aadd (_aTotOper, {"20", "22", "ENVASADOS - SAIDA DEV. DE INDUSTRIALIZACAO (litros)", 0})
	aadd (_aTotOper, {"20", "23", "ENVASADOS - ENTRADA DEV. DE INDUSTRIALIZACAO (litros)", 0})
	aadd (_aTotOper, {"30", "01", "GRANEL - VENDA (litros)", 0})
	aadd (_aTotOper, {"30", "02", "GRANEL - VENDA INTERNA (litros)", 0})
	aadd (_aTotOper, {"30", "04", "GRANEL - SAIDA DEPOSITO (litros)", 0})
	aadd (_aTotOper, {"30", "05", "GRANEL - COMPRA (litros)", 0})
	aadd (_aTotOper, {"30", "10", "GRANEL - ENTRADA DEPOSITO (litros)", 0})
	aadd (_aTotOper, {"30", "11", "GRANEL - ENTRADA DEVOLUCAO (litros)", 0})
	aadd (_aTotOper, {"30", "13", "GRANEL - SAIDA TRANSFERENCIA ENTRE FILIAIS (litros)", 0})
	aadd (_aTotOper, {"30", "14", "GRANEL - ENTRADA TRANSFERENCIA ENTRE FILIAIS (litros)", 0})
	aadd (_aTotOper, {"30", "17", "GRANEL - SAIDA P/ INDUSTRIALIZACAO (litros)", 0})
	aadd (_aTotOper, {"30", "18", "GRANEL - ENTRADA P/ INDUSTRIALIZACAO (litros)", 0})
	aadd (_aTotOper, {"30", "22", "GRANEL - SAIDA DEV. DE INDUSTRIALIZACAO (litros)", 0})
	aadd (_aTotOper, {"30", "23", "GRANEL - ENTRADA DEV. DE INDUSTRIALIZACAO (litros)", 0})
	aadd (_aTotOper, {"60", "01", "NOTAS DE UVA - VENDA (Kg)", 0})
	aadd (_aTotOper, {"60", "05", "NOTAS DE UVA - COMPRA (Kg)", 0})
	aadd (_aTotOper, {"60", "17", "NOTAS DE UVA - SAIDA PARA INDUSTRIALIZACAO (Kg)", 0})
	aadd (_aTotOper, {"60", "18", "NOTAS DE UVA - ENTRADA PARA INDUSTRIALIZACAO (Kg)", 0})
	aadd (_aTotOper, {"60", "27", "NOTAS DE UVA - COMPRA DE OUTRAS EMPRESAS (Kg)", 0})

	ProcRegua(10)
	_xTotLit := 0
	_xTotKil := 0
	_xTotVlr := 0
	_xTotLin := 0
	_nTotLit61:= 0
	_nTotNF61 := 0

	// Uma funcao para gerar cada tipo de registro.
	_Tipo10 ()  			// Identificacao da empresa remetente
	_Tipo11 ()  			// Dados complementares da empresa
	if mv_par03 == 1  		// Movto. mensal
		_Tipo20N ()  		// Notas de venda de engarrafados
		_Tipo20D ()  		// Notas de devolucao de engarrafados
		if mv_par09 == 1
			_Tipo30S  ()  	// Movimentacao a granel Saidas.
			_Tipo30E  ()  	// Movimentacao a granel Entradas.
		endif
	elseif mv_par03 == 2  	// Entradas de uvas
		_Tipo60 ()  		// Identificacao de notas de uvas
	endif
	_Tipo90 ()  			// Totalizadores

	// Validacoes cadastro produtos. Era feito no _tipo15(), mas esse tipo de registro nao eh mais gerado.
	for _nProduto = 1 to len (_aProdutos)
		if ! sb1 -> (dbseek (xfilial ("SB1") + _aProdutos [_nProduto], .F.))
			_Erro ("Erro de programa. Produto '" + _aProdutos [_nProduto] + "' nao cadastrado. Contate setor de informatica.")
			loop
		endif

		_oSisDec := ClsSisd ():New (sb1 -> b1_cod, 'SB5', cFilAnt)
		_oSisDec:ValProd ()
		for _nErro = 1 to len (_oSisDec:Erros)
			_Erro ("Produto '" + alltrim (sb1 -> b1_cod) + '-' + alltrim (sb1 -> b1_desc) + "': " + _oSisDec:Erros [_nErro])
		next
		for _nAviso = 1 to len (_oSisDec:Avisos)
			_Aviso ("Produto '" + alltrim (sb1 -> b1_cod) + '-' + alltrim (sb1 -> b1_desc) + "': " + _oSisDec:Avisos [_nAviso])
		next
	next

	if ! empty (_sErros) .or. ! empty (_sSOper)
		if ! empty (_sErros)
			U_Help ("#################" + chr (13) + char (10) + ;
			        "ERROS ENCONTRADOS" + chr (13) + char (10) + ;
			        "#################" + chr (13) + char (10) + ;
			        "Foram encontrados erros que impedem a execucao do processo.", _sErros)
		endif
		if  ! empty (_sSOper)
			U_Help ("TES sem Código da Operacao Sisdeclara informado, verifique antes de continuar.", _sSOper)
		endif
	else
		if ! empty (_sGranel)
			U_Help ("Notas com itens a granel que nao foram informadas Guias. NAO SERAO EXPORTADAS.", _sGranel)
		endif

		// Exporta para TXT ordenadamente por grupo de tipo de registro.
		_aTipos = {'10','11','20','30','60','90'}
		for _nTipo = 1 to len (_aTipos)
			_trb -> (dbgotop ())
			do while ! _trb -> (eof ())
				if _trb -> grupo == _aTipos [_nTipo]
					fwrite (_nHdl, _trb -> dados + chr (13) + chr (10))
				endif
				_trb -> (dbskip ())
			enddo
		next
	endif

	// Gera planilha para conferencia do usuario.
	if mv_par08 == 1
		U_Trb2XLS ('_trb')
	endif

	fClose(_nHdl)
	u_ArqTrb ("FechaTodos",,,, @_aArqTrb)
	if empty (_sErros)
		if !empty (_aTotOper)
			u_log2 ('info', "Resumo com Totais por Operacao:")
			u_log2 ('info', _aTotOper)
			if ! _lAuto
				u_showarray (_aTotOper, "Resumo com Totais por Operacao ")
			endif
		endif

		if ! empty (_sAvisos)
			u_help ("Arquivo '" + alltrim (mv_par06) + "' gerado, mas com os seguintes avisos:", _sAvisos)
		else
			u_help ("Arquivo '" + alltrim (mv_par06) + "' gerado com sucesso.")
		endif
	endif
return
//
// --------------------------------------------------------------------------
// Identificacao da empresa remetente
Static Function _Tipo10()
	local _sInscMA := U_TamFixo (GetMv("VA_INSCMA", .F., ""), 8, ' ')

	incproc ('Registro(s) ' + procname ())
	if empty (_sInscMA)
		_Erro ("Parametro VA_INSCMA (Nossa inscricao no Ministerio da Agricultura) vazio ou inexistente.")
	endif
	cLin:=""
	cLin := cLin+"10"+left(SM0->M0_CGC,14)+_sInscMA+left(SM0->M0_NOMECOM+space(40),40)+left(SM0->M0_ENDCOB+space(40),40)+"04305108"+SM0->M0_CEPCOB+'SDA1.3    '
	_GravaLin ('10', cLin)
Return
//
// --------------------------------------------------------------------------
// Dados complementares da empresa
Static Function _Tipo11()
	local cLin := ""
	incproc ('Registro(s) ' + procname ())
	cLin:=""
	cLin := cLin + "11"+SM0->M0_TEL+SPACE(01)+SM0->M0_FAX+SPACE(01)+"07"+SubStr(SM0->M0_INSC,1,3)+SubStr(SM0->M0_INSC,4,13)+""+SPACE(01)
	cLin += U_TamFixo (mv_par04, 30)  // Diretor
	cLin += U_TamFixo (U_RetZX5 ('20', mv_par05, 'ZX5_20NOME'), 30)  // Nome responsavel
	cLin += padl (alltrim (mv_par05), 10, ' ')  // CRQ responsavel
	cLin += U_TamFixo (mv_par07, 40)  // e-mail respons (nao o mesmo do CRQ por que nao sao os enologos que geram o arquivo)
	cLin += ' '
	_GravaLin ('11', cLin)
Return
//
// --------------------------------------------------------------------------
// Notas de venda de engarrafados
Static Function _Tipo20N ()
	local _sTipoDocF := ''
	local _sPos      := ''
	local _vTotLit   := 0
	local _lContinua := .T.
	local _sDestino  := ""
	local _nQtTotNF  := 0
	local _nReg20S   := 0
	local _oSQL      := NIL

	incproc ('Registro(s) ' + procname ())

	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		if _lSoh1Reg
			_oSQL:_sQuery += " TOP 1 "
		endif
		_oSQL:_sQuery +=        " D2_DOC, D2_SERIE, D2_EMISSAO, F4_VASITO, F2_EST, B1_COD, D2_UM, D2_QUANT, B1_LITROS, F2_DOC, D2_TIPO, "
		_oSQL:_sQuery +=        " D2_COD, D2_TES, F2_CLIENTE, F2_LOJA, B1_DESC, ISNULL(B8_VACRSIS, '') AS CODCRSIS, D2_LOTECTL "

		// Alguns lotes de produtos envasados devem ser desconsiderados, por exemplo produtos com origem internacional (GLPI 10436)
		// Para isso, busco no FullWMS se foi feita separacao de algum desses lotes e ignoro essa nota.
		if cFilAnt == '01' .and. ! empty (mv_par10)  // Soh temos FullWMS na filial 01.
			_oSQL:_sQuery += " ,ISNULL ((SELECT SUM (qtde)"
			_oSQL:_sQuery +=     " FROM tb_wms_lotes "
			_oSQL:_sQuery +=    " WHERE tb_wms_lotes.lote in " + FormatIn (alltrim (mv_par10), '/')
			_oSQL:_sQuery +=      " AND SF2.F2_CARGA = SUBSTRING (tb_wms_lotes.documento_id, 6, 6)"  // coluna saida_id segue definicao da view v_wms_pedido.
			_oSQL:_sQuery +=      " AND tb_wms_lotes.cod_item = SD2.D2_COD"
			_oSQL:_sQuery +=   "), 0) AS LT_IGNORAR"
		else
			_oSQL:_sQuery +=   ",0 AS LT_IGNORAR"
		endif

		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD2") + " SD2 "
		_oSQL:_sQuery +=   "	LEFT JOIN " + RetSQLName ("SB8") + " SB8 "
		_oSQL:_sQuery +=   "		ON (SB8.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   "			AND SB8.B8_FILIAL  = SD2.D2_FILIAL"
		_oSQL:_sQuery +=   "			AND SB8.B8_PRODUTO = SD2.D2_COD"
		_oSQL:_sQuery +=   "			AND SB8.B8_LOCAL   = SD2.D2_LOCAL"
		_oSQL:_sQuery +=   "			AND SB8.B8_LOTECTL = SD2.D2_LOTECTL),"
		_oSQL:_sQuery +=              RetSQLName ("SB1") + " SB1, "
		_oSQL:_sQuery +=              RetSQLName ("SB5") + " SB5, "
		_oSQL:_sQuery +=              RetSQLName ("SF4") + " SF4, "
		_oSQL:_sQuery +=              RetSQLName ("SF2") + " SF2 "
		_oSQL:_sQuery +=  " WHERE SF4.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=    " AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "' "
		_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=    " AND SB5.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=    " AND SF2.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=    " AND SD2.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=    " AND SB5.B5_COD     = SB1.B1_COD "
		_oSQL:_sQuery +=    " AND SB5.B5_VASISDE = 'S' "
		_oSQL:_sQuery +=    " AND SB1.B1_GRPEMB  <> '18' "  // DIFERENTE DE GRANEL, POIS O GRANEL VAI PELAS GUIAS DE LIVRE TRANSITO.
		_oSQL:_sQuery +=    " AND SF2.F2_FILIAL  = '" + xfilial ("SF2") + "' "
		_oSQL:_sQuery +=    " AND SD2.D2_FILIAL  = '" + xfilial ("SD2") + "' "
		_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "' "
		_oSQL:_sQuery +=    " AND SB5.B5_FILIAL  = '" + xfilial ("SB5") + "' "
		_oSQL:_sQuery +=    " AND SF2.F2_TIPO NOT IN ('C', 'I', 'P') "
		_oSQL:_sQuery +=    " AND SD2.D2_COD     = SB1.B1_COD "
		_oSQL:_sQuery +=    " AND SD2.D2_DOC     = SF2.F2_DOC "
		_oSQL:_sQuery +=    " AND SD2.D2_SERIE   = SF2.F2_SERIE "
		_oSQL:_sQuery +=    " AND SD2.D2_TES     = SF4.F4_CODIGO "
		_oSQL:_sQuery +=    " AND SF4.F4_VASITO <> '99' "

		// Notas de dez/2019 que continham apenas suco e cujas guias foram digitadas diretamente no site do Sisdevin
		if cFilAnt == '01' .and. month (mv_par01) == 12 .and. year (mv_par01) == 2019 .and. month (mv_par02) == 12 .and. year (mv_par02) == 2019
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000168332','000168347','000168351','000168352','000168353','000168355','000168356','000168357','000168367','000168378','000168397','000168420','000168425','000168429','000168430','000168439')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000168450','000168459','000168460','000168492','000168505','000168508','000168529','000168530','000168541','000168545','000168546','000168554','000168555','000168556','000168564','000168565')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000168575','000168584','000168588','000168591','000168597','000168601','000168606','000168608','000168609','000168624','000168625','000168640','000168645','000168646','000168649','000168651')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000168653','000168657','000168670','000168685','000168688','000168705','000168708','000168716','000168723','000168727','000168732','000168741','000168749','000168750','000168761','000168763')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000168771','000168772','000168778','000168779','000168780','000168782','000168786','000168789','000168793','000168794','000168812','000168813','000168819','000168820','000168823','000168824')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000168828','000168830','000168832','000168837','000168842','000168845','000168848','000168849','000168852','000168864','000168865','000168870','000168877','000168878','000168879','000168885')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000168886','000168887','000168888','000168889','000168890','000168891','000168892','000168893','000168900','000168901','000168902','000168903','000168904','000168906','000168908','000168924')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000168925','000168927','000168928','000168930','000168931','000168936','000168937','000168938','000168939','000168941','000168953','000168954','000168955','000168956','000168957','000168958')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000168959','000168961','000168976','000168977','000168982','000168983','000168984','000168985','000168986','000168987','000168988','000169001','000169002','000169007','000169013','000169015')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000169016','000169018','000169019','000169020','000169021','000169022','000169023','000169024','000169026','000169027','000169036','000169037','000169038','000169043','000169051','000169054')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000169091','000169092','000169093','000169094','000169095','000169100','000169103','000169105','000169109','000169110','000169111','000169113','000169115','000169123','000169132','000169134')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000169139','000169145','000169146','000169148','000169150','000169152','000169184','000169193','000169194','000169196','000169197','000169204','000169205','000169207','000169208','000169210')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000169212','000169213','000169216','000169217','000169218','000169219','000169220','000169221','000169222','000169223','000169227','000169228','000169233','000169234','000169235','000169238')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000169239','000169240','000169242','000169244','000169246','000169247','000169254','000169255','000169256','000169258','000169261','000169262','000169266','000169274','000169293','000169296')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000169306','000169307','000169310','000169334','000169346','000169351','000169359','000169365','000169367','000169369','000169375','000169386','000169390','000169399','000169401','000169402')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000169406','000169408','000169409','000169410','000169411','000169412','000169414','000169419','000169420','000169421','000169422','000169423','000169424','000169425','000169426','000169427')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000169434','000169435','000169436','000169437','000169438','000169439','000169440','000169441','000169442','000169443','000169444','000169450','000169456','000169459','000169475','000169476')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000169477','000169478','000169479','000169480','000169481','000169482','000169483','000169484','000169485','000169487','000169490','000169491','000169492','000169502','000169503','000169507')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000169508','000169512','000169519','000169520','000169523','000169527','000169529','000169530','000169531','000169532','000169533','000169534','000169535','000169536','000169537','000169538')"
			_oSQL:_sQuery +=    " AND D2_DOC NOT IN ('000169539','000169540','000169542','000169544','000169549','000169552','000169560','000169561','000169562','000169563','000169564','000169565','00016956')"
		endif

		_oSQL:_sQuery += " ORDER BY SF2.F2_DOC, SF2.F2_SERIE, SD2.D2_COD"
		_oSQL:Log ()
		_oSQL:Copy2Trb (.F., NIL, '_trb20S')

		dbSelectArea ('_trb20S')
		_trb20S -> (dbgotop ())
		do while ! _trb20S -> (eof ())

			_sNF    := _trb20S -> D2_DOC
			_sSerie := _trb20S -> D2_SERIE

			// Varre todos os itens desta nota abatendo possiveis lotes a desconsiderar, e verifica se ainda sobrou alguma quantidade a exportar.
			_nQtTotNF = 0
			_nReg20S = _trb20S -> (recno ())
			do while (! _trb20S -> (eof ()) .AND. _sNF  == _sNF .AND. _sSerie == _sSerie)
				_nQtTotNF += _trb20S->D2_QUANT - _trb20S->LT_IGNORAR
				_trb20S -> (dbskip ())
			enddo
			//
			// Se a quantidade total da nota ficou zerada ou negativa, eh pr que toda a nota foi formada por lotes que devem ser ignorados.
			// Nesse caso, jah terminei de passar por ela e basta deixar seguir para a proxima.
			// Caso contrario, reposiciono no primeiro item da nota, para que seja exportada.
			if _nQtTotNF <= 0
				U_Log2 ('aviso', 'A quantidade total da NF ' + _sNF + ' ficou ' + cvaltochar (_nQtTotNF) + ' e, portanto, essa nota vai ser desconsiderada.')
			else
				_trb20S -> (dbgoto (_nReg20S))
			endif

			dbSelectArea ('_trb20S')

			_sNF    := _trb20S -> D2_DOC
			_sSerie := _trb20S -> D2_SERIE
			_sOper  := _trb20S -> F4_VASITO
			_sTipoDocF  = _TipoDocF (_trb20S -> D2_SERIE)
			_sDestino := _trb20S -> F2_EST

			// Outro pais
			if _sDestino == "EX" .or. empty (_sDestino)
				u_log2 ('info', 'vou buscar pais para nf ' + _trb20S -> D2_DOC)
				if _trb20S -> D2_TIPO $ "B/D"
					_sDestino = _DestOri ("F", _trb20S -> F2_CLIENTE, _trb20S -> F2_LOJA, _trb20S -> D2_DOC, _trb20S -> D2_TIPO)
					if empty (_sDestino)
						_Erro ("Nao foi possivel definir o 'destino'. Verifique o pais no cadastro do cliente " + _trb20S -> F2_CLIENTE + '/' + _trb20S -> F2_LOJA)
					endif
				else
					_sDestino = _DestOri ("C", _trb20S -> F2_CLIENTE, _trb20S -> F2_LOJA, _trb20S -> D2_DOC, _trb20S -> D2_TIPO)
					if empty (_sDestino)
						_Erro ("Nao foi possivel definir o 'destino'. Verifique o pais no cadastro do fornecedor " + _trb20S -> F2_CLIENTE + '/' + _trb20S -> F2_LOJA)
					endif
				endif
				u_log2 ('info', 'destino retornado: ' + _sDestino)
			endif
			if empty (_sDestino)
				_Erro ("Nao foi possivel definir o 'destino' (UF) na NF de saida " + _trb20S -> D2_DOC)
			endif

			// Imprime tipo 20 da nota fiscal
			cLin:=""

			cLin := cLin + "20" + left(SM0->M0_CGC,14)

			_sMes :=  substr(_trb20S-> D2_EMISSAO, 5,2)
			_sAno :=  substr(_trb20S-> D2_EMISSAO, 1,4)

			cLin += _sMes
			cLin += _sAno
			cLin +=  _trb20S -> F4_VASITO
			cLin +=  strzero(val(_trb20S -> D2_DOC),10)
			cLin +=  _sDestino
			cLin +=  _sTipoDocF
			cLin +=  _trb20S -> D2_SERIE
			cLin +=  SPACE(120)

			_GravaLin ('20', cLin)
			
			_sNFI    := _trb20S -> D2_DOC
			_sSerieI := _trb20S -> D2_SERIE
			_sOperI  := _trb20S -> F4_VASITO
			_sCodCR	 :=	_trb20S -> CODCRSIS
			
			do while (! _trb20S -> (eof ()) .AND. _sNF  == _sNFI .AND. _sSerie == _sSerieI .AND. _sOper == _sOperI)

				// Se nao sobrou litragem deste item (pode ter sido vendido um lote que deve ser ignorado), entao nem continuarei processando-o.
				if _trb20S->LT_IGNORAR >= _trb20S->D2_QUANT
					_Aviso ('O item ' + alltrim (_trb20S -> d2_cod) + ' vai ser desconsiderado na NF ' + _trb20S -> d2_doc + ' por que foi vendido um lote que deve ser ignorado.')
					_trb20S -> (dbskip ())
					loop
				endif

				if empty (_sCodCR)
					_oSisDec := ClsSisd ():New (_trb20S -> d2_cod, 'SB5', cFilAnt)
					x_CODPRD := _oSisDec:CodSisd
				else
					x_CODPRD := _sCodCR
				endif
				if empty (x_CODPRD)
					_Erro ("Produto '" + alltrim (_trb20S -> d2_cod) + "'(" + alltrim (_trb20S -> b1_desc) + ") sem codigo no Sisdeclara.")
				endif
				if left (x_CODPRD, 10) = '0000000000'
					_Aviso ("Produto '" + alltrim (_trb20S -> d2_cod) + "'(" + alltrim (_trb20S -> b1_desc) + ") parece ter codigo CR invalido (zerado).")
				endif
				if _trb20S->B1_LITROS == 0
					_Erro ("Produto '" + alltrim (_trb20S -> D2_COD) + "' (cod. sisdeclara '" + x_CODPRD + "') nao tem litragem informada no cadastro.")
				endif
				x_LITROS := STRZERO(((_trb20S->D2_QUANT - _trb20S->LT_IGNORAR) * _trb20S->B1_LITROS)*100,10)
				
				x_UNID   := _trb20S -> D2_UM
				if empty (_trb20S -> F4_VASITO)
					_Erro ("Campo '" + alltrim (RetTitle ("F4_VASITO")) + "' nao informado no TES " + _trb20S -> D2_TES + ". Entre em contato com o setor fiscal.")
				endif
				
				_xTotLit += val (x_LITROS)

				// Somatorio para mostrar no final total por operação
				_sPos := ascan (_aTotOper, {|_aVal| _aVal [1] == "20" .AND. _aVal [2] == _sOperI })
				if _sPos > 0
					_vTotLit := (val(x_Litros)/100)
					_aTotOper [_sPos, 4] += _vTotLit
				endif

				// Imprime tipo 21 da nota fiscal
				cLin:=""
				cLin:= cLin + "21" + SM0->M0_CGC + x_CODPRD + _oSisDec:Embalagem + x_LITROS +SPACE(117)
				reclock ("_trb", .T.)
				_trb -> grupo = '20'
				_trb -> dados = cLin
				if mv_par08 == 1
					_trb -> origem    = 'NF_SAIDA'
					_trb -> dtmovto   = stod (_trb20S-> D2_EMISSAO)
					_trb -> nf        = _trb20S-> D2_doc
					_trb -> serie     = _trb20S-> D2_serie
					_trb -> TES       = _trb20S-> D2_tes
					_trb -> guia      = ''
					_trb -> cli_for   = _trb20S-> f2_cliente
					_trb -> loja      = _trb20S-> f2_loja
					_trb -> nome      = iif (_trb20S-> D2_tipo $ 'B/D', fBuscaCpo ("SA2", 1, xfilial ("SA2") + _trb20S-> f2_cliente + _trb20S-> f2_loja, "A2_NOME"), fBuscaCpo ("SA1", 1, xfilial ("SA1") + _trb20S-> f2_cliente + _trb20S-> f2_loja, "A1_NOME"))
					_trb -> produto   = _trb20S-> D2_cod
					_trb -> descricao = _trb20S-> b1_desc
					_trb -> CR        = x_CODPRD
					_trb -> litros    = val (x_LITROS)
				endif
				msunlock ()
				_xTotLin ++

				// Alimenta lista de produtos para posterior exportacao
				if ascan (_aProdutos, _trb20S->D2_COD) == 0
					aadd (_aProdutos, _trb20S->D2_COD)
				endif

				_trb20S -> (dbskip ())
				_sNFi    := _trb20S -> D2_DOC
				_sSeriei := _trb20S -> D2_SERIE
				_sOperI  := _trb20S -> F4_VASITO

			Enddo
		Enddo
		_trb20S -> (dbclosearea ())
		dbselectarea ('SB1')

	endif
Return
//
// --------------------------------------------------------------------------
// Notas de devolucao de engarrafados
Static Function _Tipo20D ()
	local _sTipoDocF := ''
	local _sQry20    := ''
	local _sPos      := ''
	local _vTotLit   := 0
	local _lContinua := .T.
	local _sDestino  := ""

	incproc ('Registro(s) ' + procname ())

	if _lContinua
		_sQry20 := ""
		_sQry20 += " SELECT "
		if _lSoh1Reg
			_sQry20 += " TOP 1 "
		endif
		_sQry20 +=        " D1_DOC, D1_SERIE, D1_DTDIGIT, F4_VASITO, F1_EST, B1_COD, D1_UM, D1_QUANT, B1_LITROS, "
		_sQry20 +=        " D1_COD, D1_TES, F1_FORNECE, F1_LOJA, B1_DESC, D1_TIPO, ISNULL(B8_VACRSIS, '') AS CODCRSIS, D1_LOTECTL "
		_sQry20 +=   " FROM " + RetSQLName ("SD1") + " SD1 "
		_sQry20 +=   "	LEFT JOIN " + RetSQLName ("SB8") + " SB8 "
		_sQry20 +=   "		ON (SB8.D_E_L_E_T_ = ''"
		_sQry20 +=   "			AND SB8.B8_FILIAL  = SD1.D1_FILIAL"
		_sQry20 +=   "			AND SB8.B8_PRODUTO = SD1.D1_COD"
		_sQry20 +=   "			AND SB8.B8_LOCAL   = SD1.D1_LOCAL"
		_sQry20 +=   "			AND SB8.B8_LOTECTL = SD1.D1_LOTECTL),"
		_sQry20 +=              RetSQLName ("SB1") + " SB1, "
		_sQry20 +=              RetSQLName ("SB5") + " SB5, "
		_sQry20 +=              RetSQLName ("SF4") + " SF4, "
		_sQry20 +=              RetSQLName ("SF1") + " SF1 "
		_sQry20 +=  " WHERE SF4.D_E_L_E_T_ = '' "
		_sQry20 +=    " AND SD1.D1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "' "
		_sQry20 +=    " AND SB1.D_E_L_E_T_ = '' "
		_sQry20 +=    " AND SB5.D_E_L_E_T_ = '' "
		_sQry20 +=    " AND SF1.D_E_L_E_T_ = '' "
		_sQry20 +=    " AND SD1.D_E_L_E_T_ = '' "
		_sQry20 +=    " AND SB1.B1_GRPEMB  <> '18' "// DIFERENTE DE GRANEL
		_sQry20 +=    " AND SB5.B5_COD     = SB1.B1_COD"
		_sQry20 +=    " AND SB5.B5_VASISDE = 'S' "
		_sQry20 +=    " AND SF1.F1_FILIAL  = '" + xfilial ("SF1") + "' "
		_sQry20 +=    " AND SD1.D1_FILIAL  = '" + xfilial ("SD1") + "' "
		_sQry20 +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "' "
		_sQry20 +=    " AND SB5.B5_FILIAL  = '" + xfilial ("SB5") + "' "
		_sQry20 +=    " AND SF1.F1_TIPO NOT IN('C', 'I', 'P') "
		_sQry20 +=    " AND SD1.D1_COD     = SB1.B1_COD "
		_sQry20 +=    " AND SD1.D1_DOC     = SF1.F1_DOC "
		_sQry20 +=    " AND SD1.D1_SERIE   = SF1.F1_SERIE "
		_sQry20 +=    " AND SD1.D1_FORNECE = SF1.F1_FORNECE "
		_sQry20 +=    " AND SD1.D1_LOJA    = SF1.F1_LOJA "
		_sQry20 +=    " AND SD1.D1_TES     = SF4.F4_CODIGO "
		_sQry20 +=    " AND SF4.F4_VASITO <> '99'"
		_sQry20 += " ORDER BY SF1.F1_DOC, SF1.F1_SERIE, SD1.D1_COD"
		u_log2 ('debug', _sQry20)
		_sNF20E = GetNextAlias ()

		DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQry20), _sNF20E,.F.,.F.)

		dbSelectArea(_sNF20E)
		(_sNF20E) -> (dbgotop ())


		do while ! (_sNF20E) -> (eof ())

			dbSelectArea(_sNF20E)

			_sNF    := (_sNF20E) -> D1_DOC
			_sSerie := (_sNF20E) -> D1_SERIE
			_sOper  := (_sNF20E) -> F4_VASITO
			_sTipoDocF  = _TipoDocF ((_sNF20E) -> D1_SERIE)
			_sDestino = (_sNF20E) -> f1_est

			// Outro pais.
			if _sDestino == "EX" .or. empty (_sDestino)

				// Movimentacoes de produtos oriundos de outros paises nao sao consideradas pelo SISDEVIN (GLPI 10436)
				do while ! (_sNF20E) -> (eof ()) .AND. (_sNF20E) -> D1_DOC == _sNF .AND. (_sNF20E) -> D1_SERIE == _sSerie .and. (_sNF20E) -> f1_est == 'EX'
					_Aviso ('Desconsiderando NF ' + (_sNF20E) -> D1_DOC + ' (entrada de outro pais).')
					(_sNF20E) -> (dbskip ())
				enddo
				loop


				u_log2 ('info', 'vou buscar pais para nf ' + (_sNF20E) -> D1_DOC)
				if (_sNF20E) -> D1_TIPO $ "D/B"
					_sDestino = _DestOri ("C", (_sNF20E) -> F1_FORNECE, (_sNF20E) -> F1_LOJA, (_sNF20E) -> D1_DOC, (_sNF20E) -> D1_TIPO)
					if empty (_sDestino)
						_Erro ("Nao foi possivel definir o 'destino'. Verifique o pais no cadastro do cliente " + (_sNF20E) -> F1_FORNECE + '/' + (_sNF20E) -> F1_LOJA)
					endif
				else
					_sDestino = _DestOri ("F", (_sNF20E) -> F1_FORNECE, (_sNF20E) -> F1_LOJA, (_sNF20E) -> D1_DOC, (_sNF20E) -> D1_TIPO)
					if empty (_sDestino)
						_Erro ("Nao foi possivel definir o 'destino'. Verifique o pais no cadastro do fornecedor " + (_sNF20E) -> F1_FORNECE + '/' + (_sNF20E) -> F1_LOJA)
					endif
				endif
				u_log2 ('info', 'destino retornado: ' + _sDestino)
			endif
			if empty (_sDestino)
				_Erro ("Nao foi possivel definir o 'destino' (UF) na NF de entrada " + (_sNF20E) -> D1_DOC)
			endif

			// Imprime tipo 20 da nota fiscal
			cLin:=""

			cLin := cLin + "20" + left(SM0->M0_CGC,14)

			_sMes :=  substr((_sNF20E)-> D1_DTDIGIT, 5,2)
			_sAno :=  substr((_sNF20E)-> D1_DTDIGIT, 1,4)

			cLin += _sMes
			cLin += _sAno
			cLin += (_sNF20E) -> F4_VASITO
			cLin += strzero(val((_sNF20E) -> D1_DOC),10)
			cLin += _sDestino
			cLin += _sTipoDocF
			cLin += (_sNF20E) -> D1_SERIE
			cLin += SPACE(120)

			_GravaLin ('20', cLin)

			_sNFI    := (_sNF20E) -> D1_DOC
			_sSerieI := (_sNF20E) -> D1_SERIE
			_sOperI  := (_sNF20E) -> F4_VASITO
			_sCodCR  := (_sNF20E) -> CODCRSIS
			
			do while (! (_sNF20E) -> (eof ()) .AND. _sNF  == _sNFI .AND. _sSerie == _sSerieI .AND. _sOper == _sOperI)
				if empty (_sCodCR)
					_oSisDec := ClsSisd ():New ((_sNF20E) -> d1_cod, 'SB5', cFilAnt)
					x_CODPRD := _oSisDec:CodSisd  // (_sNF20S) -> &(_oSisd:CpoCod ())
				else
					x_CODPRD := _sCodCR
				endif
				if empty (x_CODPRD)
					_Erro ("Produto '" + alltrim ((_sNF20E) -> b1_cod) + "' (" + alltrim ((_sNF20E) -> b1_desc) + ") sem codigo no Sisdeclara")
				endif
				x_UNID   := (_sNF20E) -> D1_UM
				x_LITROS := STRZERO(((_sNF20E)->D1_QUANT * (_sNF20E)->B1_LITROS)*100,10)

				if val (x_Litros) == 0
					_Erro ("Produto '" + alltrim ((_sNF20E) -> D1_COD) + "' (cod. sisdeclara '" + alltrim (x_CODPRD) + "') nao tem litragem informada no cadastro, ou a NF de Compra '" + (_sNF20E) -> D1_DOC + "' esta' com quantidade zerada.")
				endif
				if empty ((_sNF20E) -> F4_VASITO)
					_Erro ("Campo '" + alltrim (RetTitle ("F4_VASITO")) + "' nao informado no TES " + (_sNF20E) -> D1_TES + ". Contate setor fiscal.")
				endif

				// Somatorio para mostrar no final total por operação
				_sPos = ascan (_aTotOper, {|_aVal| _aVal [1] == "20" .AND. _aVal [2] == _sOperI })
				if _sPos > 0
					_vTotLit := (val(x_Litros)/100)
					_aTotOper [_sPos, 4] += _vTotLit
				endif

				_xTotLit += val (x_LITROS)

				// Imprime tipo 21 da nota fiscal
				cLin:=""
				cLin:= cLin + "21" + SM0->M0_CGC + x_CODPRD + _oSisdec:Embalagem + x_LITROS +SPACE(117)
				reclock ("_trb", .T.)
				_trb -> grupo = '20'
				_trb -> dados = cLin
				if mv_par08 == 1
					_trb -> origem    = 'NF_ENTRADA'
					_trb -> dtmovto   = stod ((_sNF20E)-> D1_DTDIGIT)
					_trb -> nf        = (_sNF20E)-> D1_doc
					_trb -> serie     = (_sNF20E)-> D1_serie
					_trb -> TES       = (_sNF20E)-> d1_tes
					_trb -> guia      = ''
					_trb -> cli_for   = (_sNF20E)-> f1_fornece
					_trb -> loja      = (_sNF20E)-> f1_loja
					_trb -> nome      = iif ((_sNF20E)-> D1_tipo $ 'B/D', fBuscaCpo ("SA1", 1, xfilial ("SA1") + (_sNF20E)-> f1_fornece + (_sNF20E)-> f1_loja, "A1_NOME"), fBuscaCpo ("SA2", 1, xfilial ("SA2") + (_sNF20E)-> f1_fornece + (_sNF20E)-> f1_loja, "A2_NOME"))
					_trb -> produto   = (_sNF20E)-> D1_cod
					_trb -> descricao = (_sNF20E)-> b1_desc
					_trb -> CR        = x_CODPRD
					_trb -> litros    = val (x_LITROS)
				endif
				msunlock ()
				_xTotLin ++

				// Alimenta lista de produtos para posterior exportacao
				if ascan (_aProdutos, (_sNF20E)->D1_COD) == 0
					aadd (_aProdutos, (_sNF20E)->D1_COD)
				endif

				(_sNF20E) -> (dbskip ())
				_sNFI    := (_sNF20E) -> D1_DOC
				_sSerieI := (_sNF20E) -> D1_SERIE
				_sOperI  := (_sNF20E) -> F4_VASITO

			Enddo
		Enddo
	endif
Return
//
// --------------------------------------------------------------------------
// Movimentacao a granel Saidas
Static Function _Tipo30S ()
	local _sTipoDocF := ''
	local _sQuery    := ""
	local _sAliasQ   := ""
	local _sPos      := ''
	local _sDestino  := ""
	local _oSisdec   := ""
	local _sCliente  := ""
	local _sLoja     := ""
	local _sTipoNF   := ""
	local x_CODPRD   := ""
	local x_LITROS   := 0
	local _sGuia     := ""

	incproc ('Registro(s) ' + procname ())

	_sQuery := ""
	_sQuery += " SELECT "
	if _lSoh1Reg
		_sQuery += " TOP 1 "
	endif
	_sQuery +=        " ZR_NUMERO, ZQ_NUMLAB, ZQ_TPOPER, F2_DOC, F2_EST, D2_COD, F2_SERIE, ZQ_NUMERO, F2_EMISSAO, ZR_EMBALAG, D2_DOC, D2_TIPO, "
	_sQuery +=        " CASE WHEN SD2.D2_TIPO IN ('B', 'D') THEN A2_VAREGMA ELSE A1_VAREGMA END AS REG_MA, "
	_sQuery +=        " CASE WHEN SD2.D2_TIPO IN ('B', 'D') THEN A2_CGC     ELSE A1_CGC     END AS CNPJ, "
	_sQuery +=        " CASE WHEN SD2.D2_TIPO IN ('B', 'D') THEN A2_NOME    ELSE A1_NOME    END AS NOME, "
	_sQuery +=        " D2_QUANT * B1_LITROS AS LITROS, F2_CLIENTE, F2_LOJA, D2_TIPO, D2_TES, D2_FILIAL, B1_DESC "
	_sQuery +=   " FROM " + RetSQLName ("SZR") + " SZR, "
	_sQuery +=              RetSQLName ("SZQ") + " SZQ, "
	_sQuery +=              RetSQLName ("SB1") + " SB1, "
	_sQuery +=              RetSQLName ("SB5") + " SB5, "
	_sQuery +=              RetSQLName ("SF2") + " SF2, "
	_sQuery +=              RetSQLName ("SD2") + " SD2 "
	_sQuery +=  " LEFT JOIN " + RetSQLName ("SA1") + " SA1 "  // Busca com left join para casos de usar cliente ou fornecedor
	_sQuery +=    " ON (SA1.D_E_L_E_T_ = ''"
	_sQuery +=    " AND SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
	_sQuery +=    " AND SA1.A1_COD     = SD2.D2_CLIENTE"
	_sQuery +=    " AND SA1.A1_LOJA    = SD2.D2_LOJA)"
	_sQuery +=  " LEFT JOIN " + RetSQLName ("SA2") + " SA2 "  // Busca com left join para casos de usar cliente ou fornecedor
	_sQuery +=    " ON (SA2.D_E_L_E_T_ = ''"
	_sQuery +=    " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
	_sQuery +=    " AND SA2.A2_COD     = SD2.D2_CLIENTE"
	_sQuery +=    " AND SA2.A2_LOJA    = SD2.D2_LOJA)"
	_sQuery +=  " WHERE SZR.D_E_L_E_T_ = ''"
	_sQuery +=    " AND SZQ.D_E_L_E_T_ = ''"
	_sQuery +=    " AND SF2.D_E_L_E_T_ = ''"
	_sQuery +=    " AND SD2.D_E_L_E_T_ = ''"
	_sQuery +=    " AND SB1.D_E_L_E_T_ = ''"
	_sQuery +=    " AND SB5.D_E_L_E_T_ = ''"
	_sQuery +=    " AND SZR.ZR_FILIAL  = '" + xfilial ("SZR") + "'"
	_sQuery +=    " AND SZQ.ZQ_FILIAL  = '" + xfilial ("SZQ") + "'"
	_sQuery +=    " AND SF2.F2_FILIAL  = '" + xfilial ("SF2") + "'"
	_sQuery +=    " AND SD2.D2_FILIAL  = '" + xfilial ("SD2") + "'"
	_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_sQuery +=    " AND SB5.B5_FILIAL  = '" + xfilial ("SB5") + "'"
	_sQuery +=    " AND SB5.B5_VASISDE = 'S' "
	_sQuery +=    " AND SF2.F2_TIPO NOT IN('C', 'I', 'P') "
	_sQuery +=    " AND SZQ.ZQ_NUMERO  = SZR.ZR_NUMERO"
	_sQuery +=    " AND SD2.D2_DOC     = SF2.F2_DOC"
	_sQuery +=    " AND SD2.D2_SERIE   = SF2.F2_SERIE"
	_sQuery +=    " AND SD2.D2_COD     = SZR.ZR_PRODUTO"
	_sQuery +=    " AND (D2_QUANT * B1_LITROS) >= 1"  // Para evitar quantidades muito pequenas (remessas simbolicas, etc)
	_sQuery +=    " AND SB5.B5_COD     = SB1.B1_COD"
	_sQuery +=    " AND SB1.B1_COD     = SD2.D2_COD"
	_sQuery +=    " AND SF2.F2_VAGUIA  = SZR.ZR_NUMERO"
	_sQuery +=    " AND SF2.F2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	
	// Desconsidera notas de transferencia simbolicas feitas em out/2017 para equalizacao de custos entre filiais.
	_sQuery +=    " AND NOT (SD2.D2_EMISSAO between '20171020' and '20171031'"
	_sQuery +=             " AND ((D2_FILIAL = '01' AND D2_DOC BETWEEN '000129625' AND '000129630')"
	_sQuery +=               " OR (D2_FILIAL = '01' AND D2_DOC BETWEEN '000130225' AND '000130225')"
	_sQuery +=               " or (D2_FILIAL = '01' AND D2_DOC BETWEEN '000130243' AND '000130243')"
	_sQuery +=               " or (D2_FILIAL = '07' AND D2_DOC BETWEEN '000015721' AND '000015722')"
	_sQuery +=               " or (D2_FILIAL = '07' AND D2_DOC BETWEEN '000015724' AND '000016734')"
	_sQuery +=               " or (D2_FILIAL = '09' AND D2_DOC BETWEEN '000013136' AND '000013137')"
	_sQuery +=               " or (D2_FILIAL = '09' AND D2_DOC BETWEEN '000013140' AND '000013142')"
	_sQuery +=               " or (D2_FILIAL = '10' AND D2_DOC BETWEEN '000010709' AND '000010739')"
	_sQuery +=               " or (D2_FILIAL = '10' AND D2_DOC BETWEEN '000010747' AND '000010757')"
	_sQuery +=               " or (D2_FILIAL = '11' AND D2_DOC BETWEEN '000004459' AND '000004477')"
	_sQuery +=               " or (D2_FILIAL = '11' AND D2_DOC BETWEEN '000004479' AND '000004480')"
	_sQuery +=               " or (D2_FILIAL = '13' AND D2_DOC BETWEEN '000007444' AND '000007450')"
	_sQuery +=             "))"

	_sQuery += " ORDER BY SF2.F2_VAGUIA, SF2.F2_DOC, SF2.F2_SERIE, SD2.D2_COD"
	u_log2 ('debug', _squery)
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())

		// Controla quebra por nota fiscal
		_sDoc      = (_sAliasQ) -> f2_doc
		_sSerie    = (_sAliasQ) -> f2_serie
		_sTipoDocF = _TipoDocF ((_sAliasQ) -> f2_serie)
		_sDestino  = (_sAliasQ) -> F2_EST
		_sCliente  = (_sAliasQ) -> F2_CLIENTE
		_sLoja     = (_sAliasQ) -> F2_LOJA
		_sTipoNF   = (_sAliasQ) -> d2_tipo

		// Outro pais.
		if _sDestino == "EX"
			u_log2 ('info', 'vou buscar pais para nf ' + (_sNF20S) -> f2_DOC) 
			if (_sNF20S) -> D2_TIPO $ "B/D"
				_sDestino = _DestOri ("F", (_sNF20S) -> F2_CLIENTE, (_sNF20S) -> F2_LOJA, (_sNF20S) -> D2_DOC, (_sNF20S) -> D2_TIPO)
			else
				_sDestino = _DestOri ("C", (_sNF20S) -> F2_CLIENTE, (_sNF20S) -> F2_LOJA, (_sNF20S) -> D2_DOC, (_sNF20S) -> D2_TIPO)
			endif
			u_log2 ('info', 'destino retornado: ' + _sDestino)
		endif

		if empty ((_sAliasQ) -> REG_MA)
			_Erro ("Saidas a granel: Registro no M.A. nao informado no cadastro do cliente/fornecedor '" + alltrim ((_sAliasQ) -> nome) + "' (CNPJ " + (_sAliasQ) -> CNPJ + "). Contate setor comercial.")
		endif
		if empty ((_sAliasQ) -> ZQ_TPOPER) .or. (_sAliasQ) -> ZQ_TPOPER == '99'
			_Erro ("NF " + (_sAliasQ) -> f2_doc + ": Tipo de operacao (" + (_sAliasQ) -> zq_tpoper + ") nao informada ou invalida. Verifique guia '" + (_sAliasQ) -> zq_numero + "' e, possivelmente, o TES '" + (_sAliasQ) -> D2_TES + "' (Campo '" + alltrim (RetTitle ("F4_VASITO")) + "')")
		endif
  
		if empty ((_sAliasQ) -> ZQ_NUMLAB)
			_sGuia = '0000' + (_sAliasQ) -> ZQ_NUMERO
		else
			_sGuia = strzero (val ((_sAliasQ) -> ZQ_NUMLAB), 10)
		endif

		// Gera linha com o cabecalho da nota
		cLin := ""
		cLin += "30" + U_TamFixo (SM0->M0_CGC, 14)
		cLin += _sGuia
		cLin += strzero (val ((_sAliasQ) -> F2_DOC), 10)
		cLin += _sDestino
		cLin += substr ((_sAliasQ) -> F2_EMISSAO, 5, 2) + substr ((_sAliasQ) -> F2_EMISSAO, 1, 4)
		cLin += (_sAliasQ) -> ZQ_TPOPER
		cLin += U_TamFixo ((_sAliasQ) -> NOME, 40)
		cLin += U_TamFixo ((_sAliasQ) -> REG_MA, 8)
		cLin += U_TamFixo ((_sAliasQ) -> CNPJ, 14)
		cLin += _sTipoDocF
		cLin += (_sAliasQ) -> F2_SERIE
		cLin += space (48)
		_GravaLin ('30', cLin)
		u_log2 ('debug', 'NF/serie = ' + _sDoc + '/' + _sSerie + ' Linha gerada = ' + cLin)

		// Processa os itens da nota
		do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> f2_doc == _sDoc .and. (_sAliasQ) -> f2_serie == _sSerie
			incproc ()

			if (_sAliasQ) -> Litros == 0
				_Erro ("Litragem zerada para o produto '" + alltrim ((_sAliasQ) -> d2_cod) + "'. Verifique se o campo '" + alltrim (RetTitle ("B1_LITROS")) + "' esta informado em seu cadastro.")
			endif

			_oSisdec := ClsSisd ():New ((_sAliasQ) -> d2_cod, 'SB5', (_sAliasQ) -> d2_filial)
			if empty (_oSisdec:CodSisd)
				_Erro ("Codigo do produto '" + alltrim ((_sAliasQ) -> d2_cod) + "' no Sisdeclara nao informado para esta filial no cadastro do produto.")
			endif

			x_CODPRD = _oSisdec:CodSisd
			x_LITROS = (_sAliasQ) -> Litros
			cLin := ""
			cLin += "31" + U_TamFixo (SM0->M0_CGC, 14)
			cLin += U_TamFixo (x_CODPRD, 15)
			cLin += iif ((_sAliasQ) -> ZR_EMBALAG == "T", "04", iif ((_sAliasQ) -> ZR_EMBALAG == "B", "03", "??"))
			cLin += strzero (round (x_LITROS * 100, 0), 10)
			cLin += space (117)
			reclock ("_trb", .T.)
			_trb -> grupo = '30'
			_trb -> dados = cLin

			if mv_par08 == 1
				_trb -> origem    = 'GUIA_SAIDA'
				_trb -> dtmovto   = stod ((_sAliasQ)-> F2_EMISSAO)
				_trb -> nf        = _sDoc
				_trb -> serie     = _sSerie
				_trb -> TES       = (_sAliasQ)-> D2_tes
				_trb -> guia      = _sGuia
				_trb -> cli_for   = _sCliente
				_trb -> loja      = _sLoja
				_trb -> nome      = iif (_sTipoNF $ 'B/D', fBuscaCpo ("SA2", 1, xfilial ("SA2") + _sCliente + _sLoja, "A2_NOME"), fBuscaCpo ("SA1", 1, xfilial ("SA1") + _sCliente + _sLoja, "A1_NOME"))
				_trb -> produto   = (_sAliasQ)-> D2_cod
				_trb -> descricao = (_sAliasQ)-> b1_desc
				_trb -> CR        = x_CODPRD
				_trb -> litros    = x_LITROS
			endif

			msunlock ()
			_xTotLin ++

			_xTotLit += round ((_sAliasQ) -> Litros * 100, 0)

			// Somatorio para mostrar no final total por operação
			_sPos = ascan (_aTotOper, {|_aVal| _aVal [1] == "30" .AND. _aVal [2] == (_sAliasQ) -> ZQ_TPOPER })
			if _sPos > 0
				_aTotOper [_sPos, 4] += round ((_sAliasQ) -> Litros, 0)
			endif

			// Alimenta lista de produtos para posterior exportacao
			if ascan (_aProdutos, (_sAliasQ) -> D2_COD) == 0
				aadd (_aProdutos, (_sAliasQ) -> D2_COD)
			endif

			(_sAliasQ) -> (dbskip ())
		enddo
	enddo
return
//
// --------------------------------------------------------------------------
// Movimentacao a granel Entradas
Static Function _Tipo30E ()
	local _sTipoDocF := ''
	local _sQuery    := ""
	local _sAliasQ   := ""
	local _sPos      := ''
	local _sDestino  := ""
	local _oSisdec   := NIL
	local _sTipoNF   := ""
	local x_CODPRD   := ""
	local x_LITROS   := 0
	local _sGuia     := ""

	incproc ('Registro(s) ' + procname ())

	_sQuery := ""
	_sQuery += " SELECT "
	if _lSoh1Reg
		_sQuery += " TOP 1 "
	endif
	_sQuery +=        " F1_DOC, F1_EST, D1_COD, F1_SERIE, F1_VAGUIA, F4_VASITO, F1_FORNECE, F1_LOJA, F1_DTDIGIT, D1_DOC, D1_TIPO, "
	_sQuery +=        " CASE WHEN SD1.D1_TIPO IN ('B', 'D') THEN A1_VAREGMA ELSE A2_VAREGMA END AS REG_MA,"
	_sQuery +=        " CASE WHEN SD1.D1_TIPO IN ('B', 'D') THEN A1_CGC     ELSE A2_CGC     END AS CNPJ, "
	_sQuery +=        " CASE WHEN SD1.D1_TIPO IN ('B', 'D') THEN A1_NOME    ELSE A2_NOME    END AS NOME, "
	_sQuery +=        " D1_QUANT * B1_LITROS AS LITROS, D1_TES, B1_LITROS, D1_FILIAL, B1_DESC "
	_sQuery +=   " FROM " + RetSQLName ("SF1") + " SF1, "
	_sQuery +=              RetSQLName ("SF4") + " SF4, "
	_sQuery +=              RetSQLName ("SB1") + " SB1, "
	_sQuery +=              RetSQLName ("SB5") + " SB5, "
	_sQuery +=              RetSQLName ("SD1") + " SD1 "
	_sQuery +=  " LEFT JOIN " + RetSQLName ("SA1") + " SA1 "  // Busca com left join para casos de usar cliente ou fornecedor
	_sQuery +=    " ON (SA1.D_E_L_E_T_ = ''"
	_sQuery +=    " AND SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
	_sQuery +=    " AND SA1.A1_COD     = SD1.D1_FORNECE"
	_sQuery +=    " AND SA1.A1_LOJA    = SD1.D1_LOJA)"
	_sQuery +=  " LEFT JOIN " + RetSQLName ("SA2") + " SA2 "  // Busca com left join para casos de usar cliente ou fornecedor
	_sQuery +=    " ON (SA2.D_E_L_E_T_ = ''"
	_sQuery +=    " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
	_sQuery +=    " AND SA2.A2_COD     = SD1.D1_FORNECE"
	_sQuery +=    " AND SA2.A2_LOJA    = SD1.D1_LOJA)"
	_sQuery +=  " WHERE SF1.D_E_L_E_T_ = ''"
	_sQuery +=    " AND SF4.D_E_L_E_T_ = '' "
	_sQuery +=    " AND SD1.D1_TES     = SF4.F4_CODIGO "
	_sQuery +=    " AND SF4.F4_VASITO <> '99' "
	_sQuery +=    " AND SD1.D_E_L_E_T_ = ''"
	_sQuery +=    " AND SB1.D_E_L_E_T_ = '' "
	_sQuery +=    " AND SB5.D_E_L_E_T_ = '' "
	_sQuery +=    " AND SB5.B5_VASISDE = 'S' "
	_sQuery +=    " AND SB1.B1_GRPEMB  = '18'"   // SOMENTE EMBALAGEM DE GRANEL e para PA
	_sQuery +=    " AND SF1.F1_FILIAL  = '" + xfilial ("SF1") + "'"
	_sQuery +=    " AND SD1.D1_FILIAL  = '" + xfilial ("SD1") + "'"
	_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_sQuery +=    " AND SB5.B5_FILIAL  = '" + xfilial ("SB5") + "'"
	_sQuery +=    " AND SF1.F1_TIPO NOT IN('C', 'I', 'P') "
	_sQuery +=    " AND SF1.F1_VAGUIA  <> '' "
	_sQuery +=    " AND SD1.D1_DOC     = SF1.F1_DOC "
	_sQuery +=    " AND SD1.D1_SERIE   = SF1.F1_SERIE "
	_sQuery +=    " AND SD1.D1_FORNECE = SF1.F1_FORNECE "
	_sQuery +=    " AND SD1.D1_LOJA    = SF1.F1_LOJA "
	_sQuery +=    " AND (D1_QUANT * B1_LITROS) >= 1"  // Para evitar quantidades muito pequenas (remessas simbolicas, etc)
	_sQuery +=    " AND SB1.B1_COD     = SD1.D1_COD"
	_sQuery +=    " AND SB5.B5_COD     = SB1.B1_COD"
	_sQuery +=    " AND SF1.F1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"

	// Desconsidera notas de transferencia simbolicas feitas em out/2017 para equalizacao de custos entre filiais.
	_sQuery +=    " AND NOT (SD1.D1_DTDIGIT between '20171020' and '20171031'"
	_sQuery +=             " AND ((D1_FORNECE = '000021' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000129625' AND '000129630')"
	_sQuery +=               " OR (D1_FORNECE = '000021' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000130225' AND '000130225')"
	_sQuery +=               " or (D1_FORNECE = '000021' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000130243' AND '000130243')"
	_sQuery +=               " or (D1_FORNECE = '003114' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000015721' AND '000015722')"
	_sQuery +=               " or (D1_FORNECE = '003114' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000015724' AND '000016734')"
	_sQuery +=               " or (D1_FORNECE = '003111' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000013136' AND '000013137')"
	_sQuery +=               " or (D1_FORNECE = '003111' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000013140' AND '000013142')"
	_sQuery +=               " or (D1_FORNECE = '003108' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000010709' AND '000010739')"
	_sQuery +=               " or (D1_FORNECE = '003108' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000010747' AND '000010757')"
	_sQuery +=               " or (D1_FORNECE = '003266' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000004459' AND '000004477')"
	_sQuery +=               " or (D1_FORNECE = '003266' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000004479' AND '000004480')"
	_sQuery +=               " or (D1_FORNECE = '004565' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000007444' AND '000007450')"
	_sQuery +=             "))"

	_sQuery += " ORDER BY SF1.F1_DOC, SF1.F1_SERIE, SD1.D1_COD, SF1.F1_FORNECE, SF1.F1_LOJA "

	u_log2 ('debug', _squery)
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())

		// Controla quebra por nota fiscal
		_sDoc      = (_sAliasQ) -> F1_DOC
		_sSerie    = (_sAliasQ) -> F1_SERIE
		_sFornec   = (_sAliasQ) -> F1_FORNECE
		_sLoja     = (_sAliasQ) -> F1_LOJA
		_sTipoDocF = _TipoDocF ((_sAliasQ) -> F1_SERIE)
		_sDestino  = (_sAliasQ) -> F1_EST
		_sTipoNF   = (_sAliasQ) -> d1_tipo

		// Outro pais.
		if _sDestino == "EX"


			// Movimentacoes de produtos oriundos de outros paises nao sao consideradas pelo SISDEVIN (GLPI 10436)
			do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> f1_doc == _sDoc ;
					.and. (_sAliasQ) -> f1_serie == _sSerie ;
					.and. (_sAliasQ) -> f1_fornece == _sFornec ;
					.and. (_sAliasQ) -> f1_loja == _sLoja
				_Aviso ('Desconsiderando NF ' + (_sAliasQ) -> f1_DOC + ' (entrada de outro pais).')
				(_sAliasQ) -> (dbskip ())
			enddo
			loop


			u_log2 ('info', 'vou buscar pais para nf ' + (_sAliasQ) -> f1_doc) 
			if (_sNF20E) -> D1_TIPO $ "D/B"
				_sDestino = _DestOri ("C", (_sNF20E) -> F1_FORNECE, (_sNF20E) -> F1_LOJA, (_sNF20E) -> D1_DOC, (_sNF20E) -> D1_TIPO)
			else
				_sDestino = _DestOri ("F", (_sNF20E) -> F1_FORNECE, (_sNF20E) -> F1_LOJA, (_sNF20E) -> D1_DOC, (_sNF20E) -> D1_TIPO)
			endif
			u_log2 ('info', 'destino retornado: ' + _sDestino)
		endif

		if empty ((_sAliasQ) -> REG_MA)
			_Erro ("Entradas a granel: Registro no M.A. nao informado no cadastro do cliente/fornecedor '" + alltrim ((_sAliasQ) -> nome) + "' (CNPJ " + (_sAliasQ) -> CNPJ + "). Contate setor comercial.")
		endif

		_sGuia = '0000' + (_sAliasQ) -> F1_VAGUIA
		
		// Gera linha com o cabecalho da nota
		cLin := ""
		cLin += "30" + U_TamFixo (SM0->M0_CGC, 14)
		cLin += _sGuia
		cLin += strzero (val ((_sAliasQ) -> F1_DOC), 10)
		cLin += _sDestino
		cLin += substr ((_sAliasQ) -> F1_DTDIGIT, 5, 2) + substr ((_sAliasQ) -> F1_DTDIGIT, 1, 4)
		cLin += (_sAliasQ) -> F4_VASITO
		cLin += U_TamFixo ((_sAliasQ) -> NOME, 40)
		cLin += U_TamFixo ((_sAliasQ) -> REG_MA, 8)
		cLin += U_TamFixo ((_sAliasQ) -> CNPJ, 14)
		cLin += _sTipoDocF
		cLin += (_sAliasQ) -> F1_SERIE
		cLin += space (48)
		_GravaLin ('30', cLin)
		u_log2 ('info', 'NF/serie = ' + _sDoc + '/' + _sSerie +  ' forn: ' + _sFornec + 'Linha gerada = ' + cLin)

		// Processa os itens da nota
		do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> f1_doc == _sDoc ;
				.and. (_sAliasQ) -> f1_serie == _sSerie ;
				.and. (_sAliasQ) -> f1_fornece == _sFornec ;
				.and. (_sAliasQ) -> f1_loja == _sLoja
			incproc ()

			if (_sAliasQ) -> Litros < 0.01
				_Erro ("Litragem zerada para o produto '" + alltrim ((_sAliasQ) -> d1_cod) + "'. Verifique se o campo '" + alltrim (RetTitle ("B1_LITROS")) + "' esta informado em seu cadastro.")
			endif

			if empty ((_sAliasQ) -> F4_VASITO)
				_Erro ("Campo '" + alltrim (RetTitle ("F4_VASITO")) + "' nao informado no TES " + (_sAliasQ) -> D1_TES + ". Contate setor fiscal.")
			endif

			_oSisdec := ClsSisd ():New ((_sAliasQ) -> d1_cod, 'SB5', (_sAliasQ) -> d1_filial)
			if empty (_oSisdec:CodSisd)
				_Erro ("Codigo do produto '" + alltrim ((_sAliasQ) -> d1_cod) + "' no Sisdeclara nao informado para esta filial no cadastro do produto.")
			endif

			x_CODPRD = _oSisdec:CodSisd
			x_LITROS = (_sAliasQ) -> Litros
			cLin := ""
			cLin += "31" + U_TamFixo (SM0->M0_CGC, 14)
			cLin += U_TamFixo (x_CODPRD, 15)
			cLin += "04"
			cLin += strzero (round (x_LITROS * 100, 0), 10)
			cLin += space (117)
			reclock ("_trb", .T.)
			_trb -> grupo = '30'
			_trb -> dados = cLin

			if mv_par08 == 1
				_trb -> origem    = 'GUIA_ENTRADA'
				_trb -> dtmovto   = stod ((_sAliasQ)-> f1_dtdigit)
				_trb -> nf        = _sDoc
				_trb -> serie     = _sSerie
				_trb -> TES       = (_sAliasQ)-> D1_tes
				_trb -> guia      = _sGuia
				_trb -> cli_for   = _sFornec
				_trb -> loja      = _sLoja
				_trb -> nome      = iif (_sTipoNF $ 'B/D', fBuscaCpo ("SA1", 1, xfilial ("SA1") + _sFornec + _sLoja, "A1_NOME"), fBuscaCpo ("SA2", 1, xfilial ("SA2") + _sFornec + _sLoja, "A2_NOME"))
				_trb -> produto   = (_sAliasQ)-> D1_cod
				_trb -> descricao = (_sAliasQ)-> b1_desc
				_trb -> CR        = x_CODPRD
				_trb -> litros    = x_LITROS
			endif

			msunlock ()
			_xTotLin ++

			_xTotLit += round ((_sAliasQ) -> Litros * 100, 0)

			// Somatorio para mostrar no final total por operação
			_sPos = ascan (_aTotOper, {|_aVal| _aVal [1] == "30" .AND. _aVal [2] == (_sAliasQ) -> F4_VASITO })
			if _sPos > 0
				_aTotOper [_sPos, 4] += round ((_sAliasQ) -> Litros, 0)
			endif

			// Alimenta lista de produtos para posterior exportacao
			if ascan (_aProdutos, (_sAliasQ) -> D1_COD) == 0
				aadd (_aProdutos, (_sAliasQ) -> D1_COD)
			endif
			(_sAliasQ) -> (dbskip ())
		enddo
	enddo
return
//
// --------------------------------------------------------------------------
// Notas de movimentacao de uva
Static Function _Tipo60 ()
	local _sCNPJ     := ""
	local _sEmpresa  := ""
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _NumNF     := ""
	local _sInscMA   := ""
	local _sCposV    := ""
	local _sCposSD1  := ""
	local _sCposSD2  := ""
	local _sOrigem   := ""
	local _dData     := ctod ('')
	local _sAssoc    := ""
	local _sLoja     := ""
	local _sDoc      := ""
	local _sSerie    := ""

	incproc ('Registro(s) ' + procname ())
	cLin:=""

	_sCposV   = " 'VIEW' AS ORIGEM,                               V.SAFRA,                 V.DATA,                 V.ASSOCIADO,              V.LOJA_ASSOC,             V.DOC,               V.SERIE,     V.CAD_VITIC,               V.PESO_LIQ,              V.GRAU,                V.VALOR_UNIT,             V.PRODUTO, SA2.A2_TIPO AS TIPO_CF, SA2.A2_CGC AS CGC, SA2.A2_INSCR AS INSCR, SA2.A2_COD_MUN AS COD_MUN, SA2.A2_NOME AS NOME_CF, SA2.A2_COD AS CLIFOR, SA2.A2_LOJA AS LOJA, SA2.A2_VAREGMA AS REGMA, B5_VATPSIS, SB1.B1_VACOR, B5_VAVPSIS, SB1.B1_COD, SB1.B1_DESC, '' AS F4_VASITO "
	_sCposSD1 = " 'SD1'  AS ORIGEM, SUBSTRING (D1_DTDIGIT, 1, 4) AS SAFRA, SD1.D1_DTDIGIT AS DATA, SD1.D1_FORNECE AS ASSOCIADO, SD1.D1_LOJA AS LOJA_ASSOC, SD1.D1_DOC AS DOC, SD1.D1_SERIE AS SERIE, '' AS CAD_VITIC, SD1.D1_QUANT AS PESO_LIQ, SD1.D1_GRAU AS GRAU, SD1.D1_VUNIT  AS VALOR_UNIT, SD1.D1_COD AS PRODUTO, SA2.A2_TIPO AS TIPO_CF, SD1.D1_DOC AS DOC, SA2.A2_INSCR AS INSCR, SA2.A2_COD_MUN AS COD_MUN, SA2.A2_NOME AS NOME_CF, SA2.A2_COD AS CLIFOR, SA2.A2_LOJA AS LOJA, SA2.A2_VAREGMA AS REGMA, B5_VATPSIS, SB1.B1_VACOR, B5_VAVPSIS, SB1.B1_COD, SB1.B1_DESC, F4_VASITO "
	_sCposSD2 = " 'SD2'  AS ORIGEM, SUBSTRING (D2_EMISSAO, 1, 4) AS SAFRA, SD2.D2_EMISSAO AS DATA, SD2.D2_CLIENTE AS ASSOCIADO, SD2.D2_LOJA AS LOJA_ASSOC, SD2.D2_DOC AS DOC, SD2.D2_SERIE AS SERIE, '' AS CAD_VITIC, SD2.D2_QUANT AS PESO_LIQ, '14.0'      AS GRAU, SD2.D2_PRCVEN AS VALOR_UNIT, SD2.D2_COD AS PRODUTO, SA1.A1_TIPO AS TIPO_CF, SD2.D2_DOC AS DOC, SA1.A1_INSCR AS INSCR, SA1.A1_COD_MUN AS COD_MUN, SA1.A1_NOME AS NOME_CF, SA1.A1_COD AS CLIFOR, SA1.A1_LOJA AS LOJA, SA1.A1_VAREGMA AS REGMA, B5_VATPSIS, SB1.B1_VACOR, B5_VAVPSIS, SB1.B1_COD, SB1.B1_DESC, F4_VASITO "

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C AS ("
	_oSQL:_sQuery += " SELECT "
	if _lSoh1Reg
		_oSQL:_sQuery += " TOP 1 "
	endif
	_oSQL:_sQuery += _sCposV
	_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V,"
	_oSQL:_sQuery +=          RetSQLName ("SA2") + " SA2, "
	_oSQL:_sQuery +=          RetSQLName ("SB1") + " SB1, "
	_oSQL:_sQuery +=          RetSQLName ("SB5") + " SB5 "
	_oSQL:_sQuery +=  " WHERE V.DATA         BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_oSQL:_sQuery +=    " AND V.FILIAL       = '" + cFilAnt + "'"

	if mv_par01 >= stod ('20210101')  // A partir desta safra geramos as notas como 'compra'.
		_oSQL:_sQuery +=    " AND V.TIPO_NF      IN ('C', 'P')"
	else
		_oSQL:_sQuery +=    " AND V.TIPO_NF      IN ('E', 'P')"
	endif

	_oSQL:_sQuery +=    " AND SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
	_oSQL:_sQuery +=    " AND SA2.A2_COD     = V.ASSOCIADO"
	_oSQL:_sQuery +=    " AND SA2.A2_LOJA    = V.LOJA_ASSOC"
	_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=    " AND SB1.B1_COD     = V.PRODUTO"
	_oSQL:_sQuery +=    " AND SB5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB5.B5_FILIAL  = '" + xfilial ("SB5") + "'"
	_oSQL:_sQuery +=    " AND SB5.B5_COD     = V.PRODUTO"

	// Notas do antigo condominio (este ano virou CNPJ) serao desconsideradas por que eles ainda nao tem inscr. no Minist.Agric.
	_oSQL:_sQuery +=    " AND NOT (V.SAFRA = '2017' AND V.ASSOCIADO = '005567')"

	_oSQL:_sQuery += " UNION ALL"  // transf uva recebida de filiais
	_oSQL:_sQuery += " SELECT "
	if _lSoh1Reg
		_oSQL:_sQuery += " TOP 1 "
	endif
	_oSQL:_sQuery += _sCposSD1
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD1") + " SD1, "
	_oSQL:_sQuery +=              RetSQLName ("SA2") + " SA2, "
	_oSQL:_sQuery +=              RetSQLName ("SB1") + " SB1, "
	_oSQL:_sQuery +=              RetSQLName ("SB5") + " SB5, "
	_oSQL:_sQuery +=              RetSQLName ("SF4") + " SF4 "
	_oSQL:_sQuery +=  " WHERE SD1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SD1.D1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_oSQL:_sQuery +=    " AND SD1.D1_FILIAL  = '" + xfilial ("SD1") + "'"
	_oSQL:_sQuery +=    " AND SD1.D1_DTDIGIT >= '20160101'"  // Antes nao tinhamos esse tipo de movimentacao
	_oSQL:_sQuery +=    " AND SD1.D1_TES IN ('219', '057')"
	_oSQL:_sQuery +=    " AND SD1.D1_GRUPO = '0400'"
	_oSQL:_sQuery +=    " AND SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
	_oSQL:_sQuery +=    " AND SA2.A2_COD     = SD1.D1_FORNECE"
	_oSQL:_sQuery +=    " AND SA2.A2_LOJA    = SD1.D1_LOJA"
	_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=    " AND SB1.B1_COD     = SD1.D1_COD"
	_oSQL:_sQuery +=    " AND SB5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB5.B5_FILIAL  = '" + xfilial ("SB5") + "'"
	_oSQL:_sQuery +=    " AND SB5.B5_COD     = SD1.D1_COD"
	_oSQL:_sQuery +=    " AND SF4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SF4.F4_FILIAL  = '" + xfilial ("SF4") + "'"
	_oSQL:_sQuery +=    " AND SF4.F4_CODIGO  = SD1.D1_TES"
	_oSQL:_sQuery += " UNION ALL"  // transf de uva para filiais
	_oSQL:_sQuery += " SELECT "
	if _lSoh1Reg
		_oSQL:_sQuery += " TOP 1 "
	endif
	_oSQL:_sQuery += _sCposSD2
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD2") + " SD2, "
	_oSQL:_sQuery +=              RetSQLName ("SA1") + " SA1, "
	_oSQL:_sQuery +=              RetSQLName ("SB1") + " SB1, "
	_oSQL:_sQuery +=              RetSQLName ("SB5") + " SB5, "
	_oSQL:_sQuery +=              RetSQLName ("SF4") + " SF4 "
	_oSQL:_sQuery +=  " WHERE SD2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_oSQL:_sQuery +=    " AND SD2.D2_FILIAL  = '" + xfilial ("SD2") + "'"
	_oSQL:_sQuery +=    " AND SD2.D2_TES     IN ('665', '534')"
	_oSQL:_sQuery +=    " AND SD2.D2_GRUPO   = '0400'"
	_oSQL:_sQuery +=    " AND SA1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
	_oSQL:_sQuery +=    " AND SA1.A1_COD     = SD2.D2_CLIENTE"
	_oSQL:_sQuery +=    " AND SA1.A1_LOJA    = SD2.D2_LOJA"
	_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=    " AND SB1.B1_COD     = SD2.D2_COD"
	_oSQL:_sQuery +=    " AND SB5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB5.B5_FILIAL  = '" + xfilial ("SB5") + "'"
	_oSQL:_sQuery +=    " AND SB5.B5_COD     = SD2.D2_COD"
	_oSQL:_sQuery +=    " AND SF4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SF4.F4_FILIAL  = '" + xfilial ("SF4") + "'"
	_oSQL:_sQuery +=    " AND SF4.F4_CODIGO  = SD2.D2_TES"
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += " SELECT * FROM C"
	_oSQL:_sQuery +=  " ORDER BY ORIGEM, DATA, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, PRODUTO"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	procregua ((_sAliasQ) -> (reccount ()))
	(_sAliasQ) -> (dbgotop ())

	do while ! (_sAliasQ) -> (eof ())

		// Controla quebra por NF
		_sOrigem  = (_sAliasQ) -> origem
		_dData    = (_sAliasQ) -> data
		_sAssoc   = (_sAliasQ) -> associado
		_sLoja    = (_sAliasQ) -> loja_assoc
		_sDoc     = (_sAliasQ) -> doc
		_sSerie   = (_sAliasQ) -> serie

		IF alltrim ((_sAliasQ) -> origem) == 'VIEW' .and. (_sAliasQ) -> tipo_cf == "J"
			_xOPER    := "27"
			_xINSCR   := Space(15)
			_xVITICOL := Space(08)
			_sCNPJ    := left((_sAliasQ) -> CGC,14)
			_sEmpresa := U_TamFixo ((_sAliasQ) -> nome_cf, 40, " ")
			_sInscMA  := U_TamFixo ((_sAliasQ) -> regma, 8, " ")
			if empty (_sInscMA)
				_Aviso ("Fornecedor/Fornecedor " + alltrim ((_sAliasQ) -> clifor) + " e' do tipo Juridico. O campo '" + alltrim (RetTitle ("A2_VAREGMA")) + "' deve ser informado. Contate setor responsavel.")
			endif
		elseif alltrim ((_sAliasQ) -> origem) == 'VIEW' .and. (_sAliasQ) -> tipo_cf == "F"
			_xOPER    := "05"
			_xVITICOL := U_TamFixo ((_sAliasQ) -> cad_vitic, 8, " ")
			_xINSCR   := Left((_sAliasQ) -> INSCR+Space(15),15)
			_sCNPJ    := left(SM0->M0_CGC,14)
			_sEmpresa := U_TamFixo (sm0 -> m0_nomecom, 40, " ")
			_sInscMA  := space (8)
		elseif alltrim ((_sAliasQ) -> origem) == 'SD1'
			_xOPER    := "18"  // ENTRADA P/ INDUSTRIALIZAÇÃO
			_xINSCR   := Space(15)
			_xVITICOL := Space(08)
			_sCNPJ    := left((_sAliasQ) -> CGC,14)
			_sEmpresa := U_TamFixo ((_sAliasQ) -> nome_cf, 40, " ")
			_sInscMA  := U_TamFixo ((_sAliasQ) -> regma, 8, " ")
			if empty (_sInscMA)
				_Aviso ("Fornecedor/Fornecedor " + alltrim ((_sAliasQ) -> clifor) + " e' do tipo Juridico. O campo '" + alltrim (RetTitle ("A2_VAREGMA")) + "' deve ser informado. Contate setor responsavel.")
			endif
		elseif alltrim ((_sAliasQ) -> origem) == 'SD2'
			_xOPER    := "17"  // SAÍDA P/ INDUSTRIALIZAÇÃO
			_xINSCR   := Space(15)
			_xVITICOL := Space(08)
			_sCNPJ    := left((_sAliasQ) -> CGC,14)
			_sEmpresa := U_TamFixo ((_sAliasQ) -> nome_cf, 40, " ")
			_sInscMA  := U_TamFixo ((_sAliasQ) -> regma, 8, " ")
			if empty (_sInscMA)
				_Aviso ("Fornecedor/Fornecedor " + alltrim ((_sAliasQ) -> clifor) + " e' do tipo Juridico. O campo '" + alltrim (RetTitle ("A2_VAREGMA")) + "' deve ser informado. Contate setor responsavel.")
			endif
		endif

		if (_sAliasQ) -> tipo_cf == "J" .and. Empty(_sInscMA)
			_Aviso ("Fornecedor/Lj "+(_sAliasQ) -> clifor+"/"+(_sAliasQ) -> loja+" Nao possui inscricao no MA (campo '" + alltrim (RetTitle ("A2_VAREGMA")) + "'). Atualize cadastro e repita a rotina.")
			lValida:=.F.
		endif

		_xMUNPRO  := "043" + (_sAliasQ) -> cod_mun
		If Empty(_xMUNPRO)
			_Aviso ("Fornecedor/Lj "+(_sAliasQ) -> clifor+"/"+(_sAliasQ) -> loja+" Nao possui o Codigo do Municipio. Atualize cadastro e repita a rotina.")
			lValida:=.F.
		Endif

		x_BRANCO  := Space(93)
		_wVITICOL := _xVITICOL
		x_Ano := (_sAliasQ) -> safra
		_xData := substr ((_sAliasQ) -> data, 7, 2) + substr ((_sAliasQ) -> data, 5, 2) + substr ((_sAliasQ) -> data, 1, 4)

		// Grava linha de cabecalho da nota
		// Como o layout do Sisdeclara especifica 6 posicoes, enviarei as 6 ultimas.
		if len((_sAliasQ) -> DOC) == 6
			_NumNF := (_sAliasQ) -> DOC
		else
			_NumNF := substr ((_sAliasQ) -> DOC, 4, 6)
		endif

		cLin := "60"+SM0->M0_CGC+ _NumNF +_xDATA+x_ANO+_xVITICOL+_xMUNPRO+_xINSCR+_xOPER+ _sEmpresa + _sCNPJ + _sInscMA + (_sAliasQ) -> serie + space (28)
		_GravaLin ('60', cLin)

		// Itens da nota
		do while ! (_sAliasQ) -> (eof ()) ;
			.and. (_sAliasQ) -> origem == _sOrigem ;
			.and. (_sAliasQ) -> data == _dData ;
			.and. (_sAliasQ) -> associado == _sAssoc ;
			.and. (_sAliasQ) -> loja_assoc == _sLoja ;
			.and. (_sAliasQ) -> doc == _sDoc ;
			.and. (_sAliasQ) -> serie == _sSerie
			IncProc ()

			xQTDE  := (_sAliasQ) -> peso_liq
			x_GRAU := left ((_sAliasQ) -> GRAU, 2)+"00"
			x_VUNIT:= round ((_sAliasQ) -> valor_unit, 4)
			xLITROS:= xQTDE
			xPLIQUI:= xQTDE
			x_PROD   := StrZero(Val((_sAliasQ) -> B5_VATPSIS),3)
			do case
			case sb1 -> b1_vacor == 'T'
				x_TIPO   := '01'
			case sb1 -> b1_vacor == 'B'
				x_TIPO   := '02'
			case sb1 -> b1_vacor == 'R'
				x_TIPO   := '03'
			otherwise
				x_TIPO = '  '
			endcase
			x_ESPEC  := (_sAliasQ) -> B5_VAVPSIS

			If Empty(x_ESPEC) .or. val (x_ESPEC) == 0
				_Erro ("Produto " + Alltrim((_sAliasQ) -> B1_COD)+" - '"+TRIM((_sAliasQ) -> B1_DESC) + "' nao possui o Codigo Variedade cadastrado no campo '" + alltrim (RetTitle ("B5_VAVPSIS")) + "'.")
				lValida:=.F.
			Endif

			x_BRANCO := Space(116)
			cLin := "61"+SM0->M0_CGC+x_ESPEC+StrZero(xLITROS*100,10)+x_GRAU+StrZero(x_VUNIT*10000,10)+x_BRANCO
			_GravaLin ('60', cLin)

			_xVALITEM := Round((xQTDE * x_VUNIT), 4)
			_nTotNF61 := _nTotNF61 + _xVALITEM

			// Acumula totais de litros tipo 61
			_nTotLit61 := _nTotLit61 + xLITROS

			//Somatorio para mostrar no final total por operação
			_sPos = ascan (_aTotOper, {|_aVal| _aVal [1] == "60" .and. _aVal [2] == _xOPER})
			if _sPos > 0
				_aTotOper [_sPos, 4] += round (xLITROS, 0)
			endif

			(_sAliasQ) -> (dbskip ())
		Enddo
	Enddo
	(_sAliasQ) -> (dbclosearea ())
Return
//
// --------------------------------------------------------------------------
// Totalizadores
Static Function _Tipo90()
	incproc ('Registro(s) ' + procname ())
	cLin := "90" + StrZero(_xTotLit,20) + StrZero((_nTotLit61)*100, 20)+ StrZero((_nTotNF61*10000), 20) + StrZero(_xTotLin + 1, 10) + Space(88)
	_GravaLin ('90', cLin)
Return
//
// --------------------------------------------------------------------------
// Valida o TudoOk do Processamento
Static Function _TudoOk()
	Local _aArea    := GetArea()
	Local _lRet     := .T.
	RestArea(_aArea)
Return (_lRet)
//
// --------------------------------------------------------------------------
// Verifica se eh cupom fiscal
Static Function _TipoDocF (_sSerie)
	local _sRet := space (1)

	if _sSerie $ GetMV ("VA_SERIECF")
		_sRet = "3"  // Cupom fiscal
	else
		_sRet = "1"  // NF
	endif

return _sRet
//
// --------------------------------------------------------------------------
// Msg de aviso
static function _Aviso (_sMsg)
	if ! _sMsg $ _sAvisos
		u_log2 ('aviso', _sMsg)
		_sAvisos += _sMsg + chr (13) + chr (10)
	endif
return
//
// --------------------------------------------------------------------------
// Msg de erro
static function _Erro (_sMsg)
	if ! _sMsg $ _sErros
		u_log2 ('erro', _sMsg)
		_sErros += _sMsg + chr (13) + chr (10)
	endif
return
//
// --------------------------------------------------------------------------
// Busca codigo do pais de destino/origem
static function _DestOri (_sOnde, _sCod, _sLoja, _sNF, _sTipoNF)
	local _sRet  := "  "
	local _sPais := ""

	if _sOnde == "C"
		_sPais = fBuscaCpo ("SA1", 1, xfilial ("SA1") + _sCod + _sLoja, "A1_CODPAIS")
		if empty (_sPais)
			_Erro ("Cliente '" + _sCod + '/' + _sLoja + "' (exterior) nao tem codigo de pais informado no campo '" + alltrim (RetTitle ("A1_CODPAIS")) + "' - NF '" + _sNF + "' (tipo '" + _sTipoNF + "')")
		endif
	else
		_sPais = fBuscaCpo ("SA2", 1, xfilial ("SA2") + _sCod + _sLoja, "A2_CODPAIS")
		if empty (_sPais)
			_Erro ("Fornecedor '" + _sCod + '/' + _sLoja + "' (exterior) nao tem codigo de pais informado no campo '" + alltrim (RetTitle ("A2_CODPAIS")) + "' - NF '" + _sNF + "' (tipo '" + _sTipoNF + "')")
		endif
	endif

	if ! empty (_sPais)
		cch -> (dbsetorder (1))  // CCH_FILIAL+CCH_CODIGO
		if ! cch -> (dbseek (xfilial ("CCH") + _sPais, .F.))
			_Erro ("Pais nao encontrado pelo codigo '" + _sPais + "' (cliente '" + _sCod + '/' + _sLoja + "') - NF '" + _sNF + "' (tipo '" + _sTipoNF + "')")
		else
			if empty (cch -> cch_vaSisd)
				_Erro ("Tabela CCH: Pais '" + cch -> cch_codigo + "' (" + alltrim (cch -> cch_pais) + ") nao tem cod.Sisdeclara (campo '" + alltrim (RetTitle ("CCH_VASISD")) + "') - NF '" + _sNF + "' (tipo '" + _sTipoNF + "')")
			else
				_sRet = cch -> cch_vaSisd
			endif
		endif
	endif
return _sRet
//
// --------------------------------------------------------------------------
// Grava linha
Static Function _GravaLin (_sGrupo, _sLinha, x_CODPRD)
	reclock ("_trb", .T.)
	_trb -> grupo = _sGrupo
	_trb -> dados = _sLinha
	_xTotLin ++
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}

    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                                  Help
	aadd (_aRegsPerg, {01, "Emissao NF de                 ", "D", 8,  0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {02, "Emissao NF ate                ", "D", 8,  0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {03, "O que exportar                ", "N", 1,  0,  "",   "     ", {"Movto.mensal", "Entradas de uva"},    ""})
	aadd (_aRegsPerg, {04, "Nome diretor da empresa       ", "C", 30, 0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {05, "CRQ/CREA responsavel tecnico  ", "C", 10, 0,  "U_ExistZX5 ('20', mv_par05)", "ZX520", {},    ""})
	aadd (_aRegsPerg, {06, "Arquivo destino               ", "C", 60, 0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {07, "E-mail para contato           ", "C", 40, 0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {08, "Gerar arq.para conferencia    ", "N", 1,  0,  "",   "     ", {"Sim", "Nao"}, ""})
	aadd (_aRegsPerg, {09, "Exportar guias livre transito?", "N", 1,  0,  "",   "     ", {"Sim", "Nao"}, ""})
	aadd (_aRegsPerg, {10, "Lotes(PA) a desconsid.(sep. /)", "C", 60, 0,  "",   "     ", {},             ""})
	U_ValPerg (cPerg, _aRegsPerg)
Return
