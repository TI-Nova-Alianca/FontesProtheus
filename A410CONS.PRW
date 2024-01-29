// Programa...: A410Cons
// Autor......: Adelar Minuzzo
// Data.......: out/2006
// Descricao..: P.E. para criar botoes adicionais na tela do pedido de venda.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada para criar botoes adicionais na tela do pedido de venda.
// #PalavasChave      #pedido_venda #botoes
// #TabelasPrincipais #SC5 #SC6
// #Modulos           #FAT
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
// 23/01/2023 - Robert  - Tratamento para medicao de grau (usado em vendas de mosto durante a safra).
// 12/01/2024 - Claudia - Incluida nova rotina de calculo de margem. GLPI: 14644
// 19/01/2024 - Claudia - Solicitado pelo cesar voltar a rotina antiga para verificação de registros antigos.
//
// ---------------------------------------------------------------------------------------------------------------------------
User Function A410CONS()
	Local _aRet := {}
	aadd( _aRet, {"LANDSCAPE",  {|| _Menu ()}, "Especificos"})
Return(_aRet)
//
// ---------------------------------------------------------------------------------------------------------------------------
// Menu
static function _Menu()
	local _aAmbAnt  := U_SalvaAmb()
	local _aAreaAnt := U_ML_SRArea()
	local _aF3      := {}
	local _nF3      := 0
	local _aCols    := {}
	local _aNotas   := {}
	local _sQuery   := {}
	local _aColsLib := {}
	local _aColsZZA := {}

	// Colunas para menu de opcoes
	aadd(_aCols, {1, "Opcao",     100, ""})

	// Define opcoes a mostrar
	if type("_sCodRep") != "C"  // Representantes externos nao visualizam este botao.
		//aadd(_aF3, {"Margem de contribuicao"		, "MCont"		})
		aadd(_aF3, {"Margem de contribuicao (Novo)"	, "MCont"		})
		if inclui .or. altera
			aadd(_aF3, {"Liberacao pedido"			, "Liberar"		})
		endif
	endif
	aadd(_aF3, {"Eventos"							, "Eventos"		})
	if ! m->c5_tipo $ "DB" .and. ! empty(m->c5_cliente)
		aadd(_aF3, {"Saldo Limite cliente"			, "SaldoCli"	})
	endif
	if type("_sCodRep") != "C"  // Representantes externos nao visualizam este botao.
		aadd(_aF3, {"Imprimir DANFe"				, "DANFe"		})
	endif
	aadd(_aF3, {"Enviar para medicao de grau"		, "MedGrau"		})
	aadd(_aF3, {"Pegar retorno medicao de grau"		, "RetGrau"		})
	aadd(_aF3, {"Cancelar"							, "Cancelar"	})

	_nF3 = U_F3Array(_aF3, "Opcoes", _aCols, oMainWnd:nClientWidth / 3, oMainWnd:nClientHeight / 1.5, "", "", .F.)

	do case
		//case _nF3 != 0 .and. _aF3 [_nF3, 2] == "MCont"
		// 	processa({|| U_VA_McPed(.T., .T.), "Calculando margem de contribuicao"})

		case _nF3 != 0 .and. _aF3 [_nF3, 2] == "MCont"
			processa({|| U_VA_PedMrg('A410CONS'), "Calculando margem de contribuicao"})
			U_VA_PEDMTL(m->c5_filial, m->c5_num, m->c5_cliente, m->c5_lojacli)
			
		case _nF3 != 0 .and. _aF3 [_nF3, 2] == "Liberar"
			U_GrvLibPV(.T.)
			_aColsLib := aclone(aCols)

		case _nF3 != 0 .and. _aF3 [_nF3, 2] == "SaldoCli"
			U__SldLimite(M->C5_CLIENTE, M->C5_LOJACLI, M->C5_TIPO)

		case _nF3 != 0 .and. _aF3 [_nF3, 2] == "Eventos"
			U_VA_SZNC("PedVenda", m->c5_num)

		case _nF3 != 0 .and. _aF3 [_nF3, 2] == "DANFe"
			_aNotas = {}
			if ! inclui
				_sQuery := "SELECT DISTINCT D2_DOC + '/' + D2_SERIE, D2_DOC, D2_SERIE"
				_sQuery +=  " FROM " + RetSQLName ("SD2")
				_sQuery += " WHERE D_E_L_E_T_ = ''"
				_sQuery +=   " AND D2_FILIAL  = '" + xfilial ("SD2") + "'"
				_sQuery +=   " AND D2_PEDIDO  = '" + m->c5_num + "'"
				_aNotas = aclone(U_Qry2Array(_sQuery))
			endif
			if len(_aNotas) == 0
				u_help ("Nao encontrei nota fiscal gerada para este pedido.")
			else
				if len(_aNotas) > 1
					_nNota = U_F3Array(_aNotas, "Notas geradas por este pedido", _aCols, oMainWnd:nClientWidth / 4, oMainWnd:nClientHeight / 3, "Pedido gerou mais de uma nota", "", .F.)
				else
					_nNota = 1
				endif
				if _nNota != 0  // Usuario pode ter cancelado a escolha da nota
					U_ImpDanfe('2', _aNotas [_nNota, 2], _aNotas [_nNota, 2], _aNotas [_nNota, 3])
				endif
			endif

		case _nF3 != 0 .and. _aF3 [_nF3, 2] == "MedGrau"
			if U_MsgYesNo("Esta rotina disponibiliza este pedido para o programa de medicao de grau de uva, visando medir o grau de mosto que vai ser vendido/transferido. Confirma?")
				_EnviaZZA()
			endif

		case _nF3 != 0 .and. _aF3 [_nF3, 2] == "RetGrau"
			if !altera
				u_help("Funcionalidade disponivel somente em nodo de alteracao do pedido.",, .t.)
			else
				_RetZZA()
				// Como o ponto de entrada faz um backup do aCols, preciso pega a posicao atual
				// para restaurar depois do backup original.
				_aColsZZA := aclone(aCols)
			endif
	endcase

	U_ML_SRArea(_aAreaAnt)
	U_SalvaAmb(_aAmbAnt)

	// Se foi alterado o aCols, baixa novamente o seu conteudo, pois a funcao SalvaAmb retornou o original.
	if len(_aColsLib) > 0
		aCols := aclone(_aColsLib)
	endif
	if len (_aColsZZA) > 0
		aCols := aclone(_aColsZZA)
	endif
return
//
// --------------------------------------------------------------------------
// Funcao que Processa o Saldo Limite Cliente
User Function _SldLimite(_xCLIENTE,_xLOJA,_xTIPO)
	Local _aArea     := GetArea()
	Local _aAreaSA1  := SA1->(GetArea())
	Local _aAreaSE1  := SE1->(GetArea())
	Local _xTOTSALDO := 0
	Local _xQUANT    := 0
	Local _xFim      := chr(13)+chr(10)
	Local _aOpc      := { "Sair" }
	
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
	
	nOpc := Aviso(  "Saldo Limite"	,;
					"Cliente           " + SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + SA1->A1_NOME + _xFim +	;
					"Limite de Credito " + Transf(SA1->A1_LC,"@E 999,999,999.99") + _xFim +						;
					"Titulos em Aberto " + Transf(_xTOTSALDO,"@E 999,999,999.99") + _xFim +						;
					"Saldo Limite      " + Transf(SA1->A1_LC-_xTOTSALDO,"@E 999,999,999.99")					;
					,_aOpc,3)
	
	RestArea(_aAreaSE1)
	RestArea(_aAreaSA1)
	RestArea(_aArea)
Return(.T.)
//
// --------------------------------------------------------------------------
// Gera uma carga de safra ficticia, com dados do pedido de venda atual, para
// poder ser enviada ao programa que faz a medicao de grau.
static function _EnviaZZA ()
	local _oCarSaf  := NIL
	local _aAreaAnt := U_ML_SRArea()
	local _nLinha   := 0
	
	_oCarSaf := ClsCarSaf():New()
	
	// Nao usa a mesma filial por que o programa BL01 faz medicao de grau continua, e vai estar
	// rodando em um computador diferente do que receber cargas de uva. Se usarmos a mesma
	// filial, ao sincronizar com o servidor SQL ficariamos com chave repetida.
	if cFilial == '07'
		_oCarSaf:Filial = '72'
	else
		u_help("Filial sem tratamento para gerar cargas",, .t.)
	endif

	if ! empty(_oCarSaf:Filial)
		_oCarSaf:Safra      = U_IniSafra()
		_oCarSaf:Carga      = 'PV'
		_oCarSaf:StatusCar  = '1'
		_oCarSaf:PesoBruto  = M->C5_PBRUTO
		_oCarSaf:PesoTara   = 0 //M->C5_PBRUTO - M->C5_PESOL
		_oCarSaf:NomeFornec = fBuscaCpo ("SA1", 1, xfilial ("SA1") + sc5 -> c5_cliente + sc5 -> c5_lojacli, "A1_NOME")
		for _nLinha = 1 to len(aCols)
			if ! GDDeleted(_nLinha)
				_oCarSaf:AddItem()
				atail (_oCarSaf:ItDescri)  = GDFieldGet ("C6_DESCRI", _nLinha)
				atail (_oCarSaf:ItItem)    = m->c5_num + '/' + GDFieldGet ("C6_ITEM", _nLinha) // Numero pedido nao cabe no ZZA_CARGA
				atail (_oCarSaf:ItProduto) = GDFieldGet ("C6_PRODUTO", _nLinha)
			endif
		next
		_oCarSaf:Log ()
		_oCarSaf:AtuZZA (.T.)
		u_help("Processo finalizado.")
	endif

	U_ML_SRArea(_aAreaAnt)
return
//
// --------------------------------------------------------------------------
// Faz leitura da tabela de integracao com o programa de medicao de grau,
// procurando registros relacionados ao pedido atual.
static function _RetZZA()
	local _aAreaAnt  := U_ML_SRArea()
	local _nLinha    := 0
	local _sChaveZZA := ''
	local _sDescri   := ''
	local _sStrGrau  := ''
	local _sFilCarg  := ''

	// Nao usa a mesma filial por que o programa BL01 faz medicao de grau continua, e vai estar
	// rodando em um computador diferente do que receber cargas de uva. Se usarmos a mesma
	// filial, ao sincronizar com o servidor SQL ficariamos com chave repetida.
	if cFilial == '07'
		_sFilCarg = '72'
	else
		u_help("Filial sem tratamento para gerar cargas",, .t.)
	endif

	if ! empty(_sFilCarg)
		zza -> (dbsetorder(1))  // ZZA_FILIAL, ZZA_SAFRA, ZZA_CARGA, ZZA_PRODUT
		for _nLinha = 1 to len(aCols)
			
			// Usa chave de pesquisa equivalente a que usa no momento do envio.
			_sChaveZZA = _sFIlCarg + U_IniSafra() + 'PV  ' + U_TamFixo(m->c5_num + '/' + GDFieldGet("C6_ITEM", _nLinha), 15)
			U_Log2 ('debug', '[' + procname() + ']Pesqusando ZZA com >>' + _sChaveZZA + '<<')
			if ! zza -> (dbseek(_sChaveZZA, .F.))
				u_log2('info', '[' + procname() + ']Nao encontrei ZZA.')
				u_help("Nao localizado nenhum registro de medicao de grau para o item " + GDFieldGet("C6_ITEM", _nLinha),, .t.)
			else
				if zza -> zza_status != '3'
					u_help("Item " + GDFieldGet("C6_ITEM", _nLinha) + ": somente medicoes de grau com status 3 (finalizado) serao aceitos. Status atual: " + zza -> zza_status)
				else
					// Corta final da descricao, caso necessario, para caber o grau.
					_sStrGrau = ' Gr:' + transform(zza -> zza_grau, "@E 99.9")
					if ! _sStrGrau $ GDFieldGet("C6_DESCRI", _nLinha)  // Para nao concatenar 2 vezes.
						_sDescri = left(GDFieldGet("C6_DESCRI", _nLinha), TamSX3("C6_DESCRI")[1] - len(_sStrGrau))
						_sDescri = alltrim(_sDescri) + _sStrGrau
						U_Log2('debug', '[' + procname() + ']ficou assim:' + _sDescri)
						GDFieldPut("C6_DESCRI", _sDescri, _nLinha)
					else
						U_Log2 ('debug', '[' + procname() + ']STR do grau jah estava na descricao')
					endif
				endif
			endif
		next
		GetDRefresh()  // Atualiza tela do pedido.
		u_help("Processo finalizado.")
	endif

	U_ML_SRArea(_aAreaAnt)
return
