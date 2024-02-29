// Autor......: Robert Koch
// Data.......: 09/08/2012
// Descricao..: Libera bloqueio gerencial em pedidos de venda.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processo
// #Descricao         #Libera bloqueio gerencial em pedidos de venda
// #PalavasChave      #bloqueio_gerencial #pedidos_de_venda
// #TabelasPrincipais #SC5 
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
// 17/04/2015 - ?       - pre-alteracao da liberacao por margem.
// 26/06/2017 - Robert  - Implementada legenda por tipo de bloqueio.
// 13/10/2017 - Robert  - Valida liberacao por margem com 2 niveis de alcada (grupo 004 e 024).
// 16/10/2017 - Robert  - Leitura previa de parametros para melhora de performance.
// 23/10/2017 - Robert  - Valida campo c5_vaPrPed.
// 31/10/2017 - Robert  - Implementado filtro do SC5 via TopConnect e nao mais por AdvPl (melhoria performance).
// 06/11/2017 - Robert  - Ignora tambem pedidos com residuo eliminado.
// 07/11/2017 - Robert  - Filtra pedidos com residuo eliminado
//                      - Criada opcao de negar liberacao
//                      - Inseridos campos de valor faturado e margem no browse.
// 08/11/2017 - Robert  - Verifica campo C5_LIBEROK (se alterar o pedido e deixar ele 'verde', 
//                        o campo C5_VABLOQ permanece preenchido).
// 19/06/2018 - Catia   - criados legendas N e A para pedidos bloqueados por % reajuste
// 10/10/2018 - Robert  - Tratamento para C5_NOTA = 'XXXXXXXXX' e 'XXXXXX'
//                      - Criado botao para visualizar eventos do pedido.
// 24/11/2019 - Robert  - Campo C5_VABLOQ passa a ter mais de uma posicao (GLPI 7000).
// 09/03/2021 - Claudia - Criada legenda para bloq. de bonificação. GLPI: 9070
// 22/04/2021 - Claudia - GLPI: 9886 - Bloqueio de pedidos de bonificação
// 11/10/2021 - Claudia - Criado parametro para bloqueio/liberação da rotina no Protheus. GLPI: 11051
// 29/02/2024 - Robert  - Liberar bloqueio gerencial tipo S especifico de sucos - GLPI 14980
//

// ----------------------------------------------------------------------------------------------------------------
User Function SC5LBG ()
	local _aCores     := U_SC5LBGLG (.T.)
	local _sFiltrTop  := ""
	local _aCpoBrw    := {}
	private aRotina   := {}

	If alltrim(GetMv("VA_SC5LBG")) == 'N'
		u_help("Rotina descontinuada no Protheus e disponibilizada no NaWeb! Disponivel em: Menu faturamento >> consultas >> liberação gerencial de pedidos")

	Else
		AAdd (_aCpoBrw, {"Bloqueio",   {|| iif('X'$sc5->c5_vabloq,'Lib.negada',iif('P'$sc5->c5_vabloq,'Preco ','')+iif('M'$sc5->c5_vabloq,'Margem ','')+iif('A'$sc5->c5_vabloq,'Reajuste ','')+iif('F'$sc5->c5_vabloq,'Bonif.s/fat. ',''))}, "C", 15, 0, "" } )
		AAdd (_aCpoBrw, {"Vlr.produtos", {|| sc5 -> c5_vavlfat}, "N", 12, 2, "@E 9,999,999.99" } )
		AAdd (_aCpoBrw, {"Marg.contr", {|| sc5 -> c5_vaMCont}, "N", 12, 2, "@E 9,999,999.99" } )

		aRotina = {}
		aadd (aRotina, {"&Pesquisar"      , "AxPesqui"								, 0, 1})
		aadd (aRotina, {"&Visualizar"     , "A410Visual"							, 0, 2})
		aadd (aRotina, {"Li&berar"        , "processa ({||U_SC5LBGL ()})"			, 0, 4})
		aadd (aRotina, {"&Negar liberacao", "processa ({||U_SC5LBGN ()})"			, 0, 4})
		aadd (aRotina, {"&Legenda"        , "U_SC5LBGLG (.F.)"						, 0, 5})
		aadd (aRotina, {"Even&tos"        , "U_VA_SZNC ('PedVenda', sc5->c5_num)"	, 0, 5})

		private cCadastro := "Liberacao bloqueio gerencial pedidos de venda"

		_sFiltrTop := "C5_VABLOQ != ''"  				// Pedido com bloqueio
		_sFiltrTop += " AND C5_LIBEROK != ''"  			// Pedido com 'liberacao comercial (SC9 gerado)
		_sFiltrTop += " AND C5_NOTA != 'XXXXXXXXX'" 	// Residuo eliminado (nao sei por que as vezes grava com 9 posicoes)
		_sFiltrTop += " AND C5_NOTA != 'XXXXXX'"  		// Residuo eliminado (nao sei por que as vezes grava com 6 posicoes)
		mBrowse(,,,,"SC5", _aCpoBrw,,,,2,_aCores,,,,,,,,_sFiltrTop)
	EndIf
return
//
// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function SC5LBGLG (_lRetCores)
	local _aCores  := {}
	local _aCores2 := {}
	local _i       := 0

	aadd (_aCores, {"'X'$sc5->c5_vabloq", 'BR_PRETO',    'Liberacao negada'})
	aadd (_aCores, {"!'X'$sc5->c5_vabloq.and.'M'$sc5->c5_vabloq.and.'P'$sc5->c5_vabloq"	, 'BR_LARANJA'	, 'Bloq.por margem e preco'	})
	aadd (_aCores, {"!'X'$sc5->c5_vabloq.and.'F'$sc5->c5_vabloq"						, 'BR_MARRON'	, 'Bonif.sem faturamento'	})
	aadd (_aCores, {"!'X'$sc5->c5_vabloq.and.'P'$sc5->c5_vabloq"						, 'BR_VERMELHO'	, 'Bloq.por preco'			})
	aadd (_aCores, {"!'X'$sc5->c5_vabloq.and.'M'$sc5->c5_vabloq"						, 'BR_AMARELO'	, 'Bloq.por margem'			})
	aadd (_aCores, {"!'X'$sc5->c5_vabloq.and.'A'$sc5->c5_vabloq"						, 'BR_AZUL'		, 'Bloq.%reajuste'			})
	aadd (_aCores, {"!'X'$sc5->c5_vabloq.and.'B'$sc5->c5_vabloq"						, 'BR_BRANCO'	, 'Bloq.bonificação'		})
	
	if ! _lRetCores
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 2], _aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", _aCores2)
	else
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 1], _aCores [_i, 2]})
		next
		return _aCores
	endif
return
//
// --------------------------------------------------------------------------
// Realiza validações para liberar ou não o pedido
User Function SC5LBGL ()
	local _aAmbAnt   := U_SalvaAmb()
	local _aAreaAnt  := U_ML_SRArea()
	local _oEvento   := NIL
	local _lContinua := .T.
	local _nMCPed1   := GetMv("VA_MCPED1")
	local _nMCPed2   := GetMv("VA_MCPED2")
	local _lGrp004   := U_ZZUVL('004',,.F.)
	local _lGrp081   := U_ZZUVL('081',,.F.)
	local _lGrp082   := U_ZZUVL('082',,.F.)
	local _lGrp158   := U_ZZUVL('158',,.F.)

	procregua (10)

	if _lContinua .and. ('M' $ sc5 -> C5_VABLOQ .or. 'N' $ sc5 -> C5_VABLOQ)
		if (sc5 -> c5_vaMCont < _nMCPed1 .and. ! _lGrp081) .or. (sc5 -> c5_vaMCont < _nMCPed2 .and. ! _lGrp082)
			u_help ("Bloqueio por margem de contribuicao (" + cvaltochar (sc5 -> c5_vaMCont) + "%). Usuario sem alcada.",,.T.)
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. ('P' $ sc5 -> C5_VABLOQ .or. 'A' $ sc5 -> C5_VABLOQ)
		if sc5 -> c5_vaPrPed > 0 .and. sc5 -> c5_vaPrPed <= 5 //1
			if ! _lGrp004
				u_help ("Bloqueio por reducao de precos ate 5% em relacao ao pedido anterior. Usuario sem alcada.",,.T.)
				_lContinua = .F.
			endif
		else
			if sc5 -> c5_vaPrPed > 1 .and. sc5 -> c5_vaPrPed <= 5
				if ! _lGrp081
					u_help ("Bloqueio por reducao de precos acima de " + cvaltochar (sc5 -> c5_vaPrPed) + "% em relacao ao pedido anterior. Usuario sem alcada.",,.T.)
					_lContinua = .F.
				endif
			else
				if sc5 -> c5_vaPrPed > 5
					if ! _lGrp082
						u_help ("Bloqueio por reducao de precos acima de " + cvaltochar (sc5 -> c5_vaPrPed) + "% em relacao ao pedido anterior. Usuario sem alcada.",,.T.)
						_lContinua = .F.
					endif
				endif
			endif
		endif
	endif	

	if _lContinua .and. ('B' $ sc5 -> C5_VABLOQ)
		if _lGrp082 .or. _lGrp004 .or. _lGrp081
			_lContinua = .T.
		else
			u_help ("Bloqueio por bonificação. Usuario sem alcada para liberação.",,.T.)
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. ('S' $ sc5 -> C5_VABLOQ)
		if _lGrp158
			_lContinua = .T.
		else
			u_help ("Bloqueio especifico sucos. Usuario sem alcada para liberação.",,.T.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		CursorWait ()
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven   = "SC5003"
		_oEvento:Texto     = "Liberado bloqueio gerencial tipo '" + sc5 -> c5_vabloq + "'" + iif (('M' $ sc5 -> C5_VABLOQ .or. 'N' $ sc5 -> C5_VABLOQ), " c/margem " + alltrim (transform (sc5 -> c5_vaMCont, "@E 999,999,999.99")), "")
		_oEvento:Cliente   = sc5 -> c5_cliente
		_oEvento:LojaCli   = sc5 -> c5_lojacli
		_oEvento:PedVenda  = sc5 -> c5_num
		_oEvento:Grava ()

		reclock ("SC5", .F.)
			sc5 -> c5_vabloq = ''
		msunlock ()

		CursorArrow ()

		u_help ("Liberacao efetuada com sucesso.",,.F.)
	endif

	U_ML_SRArea(_aAreaAnt)
	U_SalvaAmb(_aAmbAnt)
return
//
// --------------------------------------------------------------------------
// Negar liberacao (para tirar deste browse e 'devolver' ao comercial).
User Function SC5LBGN ()
	local _aAmbAnt   := U_SalvaAmb()
	local _aAreaAnt  := U_ML_SRArea()

	CursorWait ()
	reclock ("SC5", .F.)
		sc5->c5_vaBloq = iif ('X' $ sc5->c5_vaBloq, sc5->c5_vaBloq, alltrim (sc5->c5_vaBloq) + 'X')
	msunlock ()
	CursorArrow ()

	U_ML_SRArea(_aAreaAnt)
	U_SalvaAmb(_aAmbAnt)
return
