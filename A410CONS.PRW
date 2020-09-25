// Programa...: A410Cons
// Autor......: Adelar Minuzzo
// Data.......: out/2006
// Descricao..: P.E. para criar botoes adicionais na tela do pedido de venda.
//
// Historico de alteracoes:
// 17/04/2008 - Robert  - Inclusao botao para selecao de frete.
// 23/07/2008 - Robert  - Leitura em loop no botao de margem de contribuicao.
// 13/08/2008 - Robert  - Incluido botao para visualizacao de eventos.
// 27/08/2008 - Robert  - Nao considerava campo c5_pvcond.
// 01/09/2008 - Robert  - Criado botao para visualizacao de eventos.
// 10/06/2010 - Robert  - Desabilita alguns botoes para representante externo.
// 21/06/2010 - Robert  - Criado botao para chamada de liberacao dos itens.
// 03/12/2010 - Robert  - Permanece apenas um botao, que chama um menu de opcoes.
// 20/11/2011 - Robert  - Incluida opcao de impressao do(s) DANFe de(s) nota(s) gerada(s) pelo pedido.
// 09/10/2013 - Leandro - Chama calculo de margem apos selecao do frete, mostra se ficar abaixo de determinado percentual.
// 19/03/2014 - Bruno   - Quando for calcular a margem e o campo C5_MVFRE = 0, carrega o maior frete para realizar o cálculo.
// 27/03/2014 - Robert  - Nao somava PIS e COFINS na consuta de mrgem de comtribuicao.
// 09/07/2016 - Robert  - Consulta de margem de contribuicao migrada para 'user function'.
// 09/07/2016 - Robert  - Nao chama mais a consulta de margem apos selecionar o frete. Agora faz no GrvLibPV().
// 08/06/2017 - Catia   - apagado o bloco que montava a tela de margens - que passou para o programa VA_McPed
// 26/10/2017 - Robert  - Chama funcoes de calculo de frete e liberacao somente quando inclusao ou alteracao.
//                      - Eliminadas visualizacoes de peso e comissao (ja tem campos para isso na tela).
// 21/06/2018 - Robert  - Nao pretendo mais abrir tela de sel.frete no pedido de venda (nao chama mais FrtSelPV).
//                      - Funcao Va_McPed() tem novos parametros
// 10/08/2020 - Robert  - Eliminadas linhas comentariadas, melhoria historico alteracoes.
//                      - Inseridas tags para catalogacao de fontes.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada para criar botoes adicionais na tela do pedido de venda.
// #PalavasChave      #pedido_venda #botoes
// #TabelasPrincipais #SC5 #SC6
// #Modulos           #FAT

// --------------------------------------------------------------------------
User Function A410CONS()
	Local _aRet := {}
	aadd( _aRet, {"LANDSCAPE",  {|| _Menu ()}, "Especificos"})
Return(_aRet)



// --------------------------------------------------------------------------
static function _Menu ()
	local _aF3      := {}
	local _nF3      := 0
	local _aCols    := {}
	local _aColsLib := {}
	local _aAmbAnt  := U_SalvaAmb ()
	local _aAreaAnt := U_ML_SRArea ()
	local _aNotas   := {}
	local _sQuery   := {}

	// Colunas para menu de opcoes
	aadd (_aCols, {1, "Opcao",     100, ""})

	// Define opcoes a mostrar
	if type ("_sCodRep") != "C"  // Representantes externos nao visualizam este botao.
		aadd (_aF3, {"Margem de contribuicao", "MCont"})
		if inclui .or. altera
			aadd (_aF3, {"Liberacao pedido",       "Liberar"})
		endif
	endif
	aadd (_aF3, {"Eventos",                    "Eventos"})
	if ! m->c5_tipo $ "DB" .and. ! empty (m->c5_cliente)
		aadd (_aF3, {"Saldo Limite cliente",   "SaldoCli"})
	endif
	if type ("_sCodRep") != "C"  // Representantes externos nao visualizam este botao.
		aadd (_aF3, {"Imprimir DANFe",             "DANFe"})
	endif
	aadd (_aF3, {"Cancelar",                   "Cancelar"})

	_nF3 = U_F3Array (_aF3, "Opcoes", _aCols, oMainWnd:nClientWidth / 3, oMainWnd:nClientHeight / 1.5, "", "", .F.)

	do case
	case _nF3 != 0 .and. _aF3 [_nF3, 2] == "MCont"
	//	U_VA_McPed (.T., inclui .or. altera)
		processa ({|| U_VA_McPed (.T., .T.), "Calculando margem de contribuicao"})
		

	case _nF3 != 0 .and. _aF3 [_nF3, 2] == "Liberar"
		U_GrvLibPV (.T.)
		_aColsLib := aclone (aCols)

	case _nF3 != 0 .and. _aF3 [_nF3, 2] == "SaldoCli"
		U__SldLimite(M->C5_CLIENTE,M->C5_LOJACLI,M->C5_TIPO)

	case _nF3 != 0 .and. _aF3 [_nF3, 2] == "Eventos"
		U_VA_SZNC ("PedVenda", m->c5_num)

	case _nF3 != 0 .and. _aF3 [_nF3, 2] == "DANFe"
		_aNotas = {}
		if ! inclui
			_sQuery := "SELECT DISTINCT D2_DOC + '/' + D2_SERIE, D2_DOC, D2_SERIE"
			_sQuery +=  " FROM " + RetSQLName ("SD2")
			_sQuery += " WHERE D_E_L_E_T_ = ''"
			_sQuery +=   " AND D2_FILIAL  = '" + xfilial ("SD2") + "'"
			_sQuery +=   " AND D2_PEDIDO  = '" + m->c5_num + "'"
			_aNotas = aclone (U_Qry2Array (_sQuery))
		endif
		if len (_aNotas) == 0
			u_help ("Nao encontrei nota fiscal gerada para este pedido.")
		else
			if len (_aNotas) > 1
				_nNota = U_F3Array (_aNotas, "Notas geradas por este pedido", _aCols, oMainWnd:nClientWidth / 4, oMainWnd:nClientHeight / 3, "Pedido gerou mais de uma nota", "", .F.)
			else
				_nNota = 1
			endif
			if _nNota != 0  // Usuario pode ter cancelado a escolha da nota
				U_ImpDanfe ('2', _aNotas [_nNota, 2], _aNotas [_nNota, 2], _aNotas [_nNota, 3])
			endif
		endif
	endcase

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)

	// Se foi alterado o aCols, baixa novamente o seu conteudo, pois a funcao SalvaAmb retornou o original.
	if len (_aColsLib) > 0
		aCols := aclone (_aColsLib)
	endif
return
	



//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Funcao que Processa o Saldo Limite Cliente                   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
User Function _SldLimite(_xCLIENTE,_xLOJA,_xTIPO)
	Local _aArea    := GetArea()
	Local _aAreaSA1 := SA1->(GetArea())
	Local _aAreaSE1 := SE1->(GetArea())
	Local _xTOTSALDO:= 0
	Local _xQUANT   := 0
	Local _xFim     := chr(13)+chr(10)
	Local _aOpc     := { "Sair" }
	
	If Empty(_xCLIENTE+_xLOJA)
		Return
	Endif
	
	If _xTIPO $ "B/D"
		Return
	Endif
	
	DbSelectArea("SA1")        // Cadastro de Clientes
	DbSetOrder(1)
	DbSeek(xFilial()+_xCLIENTE+_xLOJA)
	If !Found()
		Return
	Endif
	
	DbSelectArea("SE1")
	DbSetOrder(2)
	DbSeek(xFilial("SE1")+_xCLIENTE+_xLOJA)
	bWhile := {|| !Eof() .And. xFilial("SE1") == SE1->E1_FILIAL .And.;
	_xCLIENTE  == SE1->E1_CLIENTE .And.;
	_xLOJA     == SE1->E1_LOJA }
	
	Do While ( Eval(bWhile) )
		If SubStr(SE1->E1_TIPO,3,1)!="-"
			If SE1->E1_SALDO > 0
				_xTOTSALDO := _xTOTSALDO + SE1->E1_SALDO
				_xQUANT    := _xQUANT + 1
			Endif
		EndIf
		dbSelectArea("SE1")
		dbSkip()
	EndDo
	
	nOpc := Aviso("Saldo Limite",;
	"Cliente           "+SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+SA1->A1_NOME+_xFim+;
	"Limite de Credito "+Transf(SA1->A1_LC,"@E 999,999,999.99")+_xFim+;
	"Titulos em Aberto "+Transf(_xTOTSALDO,"@E 999,999,999.99")+_xFim+;
	"Saldo Limite      "+Transf(SA1->A1_LC-_xTOTSALDO,"@E 999,999,999.99");
	,_aOpc,3)
	
	RestArea(_aAreaSE1)
	RestArea(_aAreaSA1)
	RestArea(_aArea)
Return(.T.)
