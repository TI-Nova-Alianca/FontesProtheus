// Programa...: FrtSelPV
// Autor......: Robert Koch
// Data.......: 17/04/2008
// Descricao..: Tela para usuario selecionar o frete no pedido de venda.
//
// Historico de alteracoes:
// 08/08/2008 - Robert - Deixava passar transportadora negociada sem informar o valor do frete.
// 11/08/2008 - Robert - Passa a pedir justificativa para escolher transportadora mais cara ou negociada.
// 25/08/2010 - Robert - Justificativa para frete maior ou negociado nao eh mais exigida.
// 28/06/2010 - Robert - Nao somava a ST no valor total da nota para calculo do frete.
// 15/08/2011 - Robert - Volta a pedir justificativa quando nao usar o frete de menor valor/
// 01/10/2013 - Robert - Liberado apenas para usuarios de logistica (filial 01).
// 19/03/2014 - Bruno  - Criado parametro lMrFrete, quando .T. apenas pega o valor do maior frete,
//                       utilizado quando for solicitado calculo de margem (A410CONS) e o frete ainda não estiver preenchido
// 14/09/2015 - Robert - Verifica existencia de pedido com frete FOB e transportadora diferente da selecionada na carga.
// 17/11/2015 - Robert - Exige valor sempre que houver transp. negociada (antes exigia apenas para alguns estados).
// 30/06/2017 - Robert - Criado campo para informar transportadora redespacho; grava na carga e/ou pedido.
// 29/09/2017 - Robert - Criada opcao de consultar webservice da E-Sales (entregou.com).
// 30/10/2017 - Robert - Chama rotina de selecao de frete somente para frete tipo CIF.
// 14/05/2018 - Robert - Nao atualiza mais o campo C5_MVFRE quando executando na tela de cargas para manter historico do que foi usado no calculo de margem do pedido.
// 06/06/2018 - Robert - Verificacao de pedidos com frete FOB desabilitada (quem deve validar isso eh o P.E. OM200ok)
// 21/06/2018 - Robert - nao pretendo mais abrir tela de sel.frete no pedido de venda.
// 05/08/2019 - Robert - Dasabilitada tela de selecao de frete (usa sempre pelo entregou.com)
// 06/08/2019 - Robert - Habilitada novamente tela de selecao de frete, mas apenas com opcao de transp.negociada e redespacho.
// 10/08/2020 - Robert - Desabilitadas partes relacionadas a pedido de venda (esta funcao nao eh mais chamada desse local) - GLPI 8180
//                     - Inseridas tags para catalogacao de fontes.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Tela para selecao de transportadora na montagem de cargas do modulo OMS
// #PalavasChave      #selecao_transportadora #cotacao_frete #montagem_de_carga
// #TabelasPrincipais #DAK #DAI
// #Modulos           #OMS

#include "rwmake.ch"
#include "colors.ch"
#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
User Function FrtSelPV (lMrFrete)
//	local _aLiber     := {.F.,,}
//	local _lContinua  := .T.
	local _aAmbAnt    := U_SalvaAmb ()
	local _aAreaAnt   := U_ML_SRArea ()
	Private _lMrFrete := .F.
	Private nValorFR  := 0
	private _sTransSel := ""

	If !Empty(lMrFrete)
		_lMrFrete := lMrFrete 
	EndIf 
	
	If Funname()=='OMSA200'
		if cFilAnt == '01' .and. u_msgyesno ("Deseja consultar o serviço 'entregou.com' ?")
			processa ({|| U_FrtESal ('C', dak -> dak_cod, .T.)})
		else
			processa ({|| _AndaLogo ()})
		endif
	endif 

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt) 
	
	if _lMrFrete
		Return nValorFR
	EndIf

return 


// --------------------------------------------------------------------------
static function _AndaLogo ()
	local _lContinua   := .T.
	local _bAcao       := NIL
//	local _oCour20     := TFont():New("Courier New",,20,,.T.,,,,,.F.)
//	local _aDadosZZ3   := {}
//	local _aAreaQ      := {}
//	local _sAliasQ     := ""
//	local _sMVEstICM   := ""
//	local _nAliqICM    := 0
	private _sOrigem   := GetMv ("VA_FRTMORI")  // Municipio origem (posso ter filiais em diferentes cidades)
	private _sDestino  := ""
	private _sEstDest  := ""
	private _sTransNeg := space (6)
	private _sNomeTra  := ""
	private _nNegociad := 0
	private _nVlCalc   := 0
	private _sTransRed := space (6)
	private _sNomTrRed := ""

	// Declara variavel publica para poder ser vista em mais de um ponto de entrada.
	public _oClsFrtPV := ClsFrtPV():New ()

	u_logIni ()

	// Se estas variaveis nao existirem, tenho que cria-las.
	if type ("aHeader") != "A"
		private aHeader   := {}
	endif
	if type ("aCols") != "A"
		private aCols     := {}
	endif
	if type ("N") != "N"
		private N         := 1
	endif
	if type ("aRotina") != "A"
		private aRotina   := {}  // Variavel exigida pela GetDados.
	endif
	aRotina = {}
	aadd (aRotina, {"BlaBlaBla", "allwaystrue ()", 0, 1})
	aadd (aRotina, {"BlaBlaBla", "allwaystrue ()", 0, 2})

// Nao usa mais esta rotina a partir da tela de pedidos de venda -->	if FunName()=='OMSA200'
		_sCliente := DAI->DAI_CLIENT 
		_sLojacli := DAI->DAI_LOJA  
		_sTipoPV  := Posicione("SC5",1,xFilial("SC5") + DAI->DAI_PEDIDO, "C5_TIPO")
		_nPesoTot := DAK->DAK_PESO 
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->	else
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		_sCliente := m->c5_client
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		_sLojacli := m->c5_lojaent 
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		_sTipoPV  := m->c5_tipo
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		_nPesoTot := m->c5_pbruto
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->	endif

	if _lContinua
		if empty (_sCliente) .or. empty (_sLojacli)
			u_help ("Cliente / loja de entrega devem ser informados.")
			_lContinua = .F.
		endif
	endif
	if _lContinua
		
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		if FunName()=='OMSA200'
			_nValFat := DAK->DAK_VALOR	
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		else
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->			_nValFat = _ValFat (aRotina[ 2, 4 ])
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		endif
	endif

	if _lContinua
		_bAcao = {|| _Seleciona (), iif (_TudoOK(), _oDlg:End (), NIL)}
		define MSDialog _oDlg from 0, 0 to 400, oMainWnd:nClientWidth - 20 of oMainWnd pixel title "Transportadoras disponiveis"
		@ _oDlg:nClientHeight / 2 - 50, 15  say "Transport.(negociado)"
		@ _oDlg:nClientHeight / 2 - 35, 15  say "Valor negociado"
		@ _oDlg:nClientHeight / 2 - 50, 80  get _sTransNeg size 50,  11 F3 "SA4" valid _ValTrNeg ()
		@ _oDlg:nClientHeight / 2 - 50, 140 get _sNomeTra  size 130, 11 when .F.
		@ _oDlg:nClientHeight / 2 - 50, 290 say "Transport. redespacho"
		@ _oDlg:nClientHeight / 2 - 50, 360 get _sTransRed size 50,  11 F3 "SA4" valid _ValTrRed ()
		@ _oDlg:nClientHeight / 2 - 50, 415 get _sNomTrRed size 130, 11 when .F.
		@ _oDlg:nClientHeight / 2 - 35, 100 get _nNegociad size 50,  11 picture "@E 999,999,999.99" valid _ValNeg ()
		@ _oDlg:nClientHeight / 2 - 35, _oDlg:nClientWidth / 2 - 100 bmpbutton type 1 action eval (_bAcao)
		@ _oDlg:nClientHeight / 2 - 35, _oDlg:nClientWidth / 2 - 45  bmpbutton type 2 action _oDlg:End ()
		activate dialog _oDlg centered // valid _TudoOK ()
	endif
	u_logFim ()
return



// --------------------------------------------------------------------------
// Verifica 'tudo ok'.
static function _TudoOK ()
	local _lRet      := .T.
//	local _oSQL      := NIL
//	local _sFrom     := ""
	
	if _lRet
		if empty (_oClsFrtPV:_C5TRANSP) .and. empty (_sTransNeg)
			u_help ("Selecione uma transportadora entre as disponiveis ou informe negociacao.")
			_lRet = .F.
		endif
	endif
	if _lRet                                
		if ! empty (_sTransNeg) .and. _nNegociad == 0
			u_help ("Frete negociado: valor nao pode ficar zerado.")
			_lRet = .F.
		endif
	endif
	if _lRet .and. _sTransRed == _oClsFrtPV:_C5TRANSP
		u_help ("Transportadora redespacho nao pode ser igual `a transportadora selecionada para o frete.")
		_lRet = .F.
	endif
	
	// Algumas selecoes feitas pelo usuario exigem justificativa.
	if _lRet
		if _oClsFrtPV:_ZZ1VLNEGO > 0
			_oClsFrtPV:_ZZ1Justif = ""
			do while empty (_oClsFrtPV:_ZZ1Justif)
				_oClsFrtPV:_ZZ1Justif := space (255)  // Mais que isso eh pra matar...
				define MSDialog _oDlgJust from 0, 0 to 150, 500 of oMainWnd pixel title "Justificativa"
				@ 10, 10 say "Justifique o uso de uma transportadora com negociacao."
				@ 30, 10 get _oClsFrtPV:_ZZ1Justif size 200, 11
				@ 45, 10 bmpbutton type 1 action (_oDlgJust:End ())
				activate MSDialog _oDlgJust centered
			enddo
		endif
	endif

	if _lRet
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		if FunName()=='OMSA200'
			_sTransp := _oClsFrtPV:_C5TRANSP
			if _oClsFrtPV:_ZZ1VLCALC > 0
				_nValFre := _oClsFrtPV:_ZZ1VLCALC
			elseif _oClsFrtPV:_ZZ1VLNEGO > 0
				_nValFre := _oClsFrtPV:_ZZ1VLNEGO
			endif         
			
			// calcula o valor por KG, utilizando o peso total da carga e o valor total do frete
			_nValPKg := _nValFre / _nPesoTot
						
			// Altera as transportadoras nos pedidos da carga
			dbselectarea("DAI")
			dbsetorder(1)
			if dbseek(xFilial("DAI") + DAK->DAK_COD)
				While !Eof() .and. DAI->DAI_COD == DAK->DAK_COD
					dbselectarea("SC5")
					dbsetorder(1)
					if dbseek(xFilial("SC5") + DAI->DAI_PEDIDO)
						Reclock("SC5",.F.)
						Replace SC5->C5_TRANSP With _sTransp
						// quero manter historico do que foi usado no calculo de margem --> Replace Sc5->C5_MVFRE  With round((_nValPKg * SC5->C5_pbruto),2) // preenche os valores de frete nos pedidos da carga
						Replace Sc5->C5_redesp With _oClsFrtPV:_TrRedesp
						MsUnlock()
					Endif											
					
					dbselectarea("DAI")
					dbskip()	
				Enddo
			endif
			
			// grava código da transportadora no DAK
			reclock("DAK",.F.)
			Replace DAK->DAK_VATRAN With _sTransp
			Replace DAK->DAK_VATRRE With _oClsFrtPV:_TrRedesp
			msunlock()    
			
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		else
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->			// O pedido assume a transportadora selecionada / informada.
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->			m->c5_transp = _oClsFrtPV:_C5TRANSP
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->			m->c5_redesp = _oClsFrtPV:_TrRedesp
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->			if _oClsFrtPV:_ZZ1VLCALC > 0
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->				m->c5_mvfre = _oClsFrtPV:_ZZ1VLCALC
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->			elseif _oClsFrtPV:_ZZ1VLNEGO > 0
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->				m->c5_mvfre = _oClsFrtPV:_ZZ1VLNEGO
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->			endif
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		endif
	endif
	
	if _lRet
		GetDRefresh ()  // Atualiza tela do pedido.
		Sysrefresh ()
	endif
return _lRet



// --------------------------------------------------------------------------
// Valida transportadora negociada.
static function _ValTrNeg ()
	local _lRet := .T.
	if ! empty (_sTransNeg)
		if _sTransRed == _sTransNeg
			u_help ("Transportadora redespacho e negociada nao podem ser iguais.")
			_lRet = .F.
		else 
			sa4 -> (dbsetorder (1))
			if ! sa4 -> (dbseek (xfilial ("SA4") + _sTransNeg, .F.))
				u_help ("Transportadora nao cadastrada.")
				_lRet = .F.
			else
				_sNomeTra = sa4 -> a4_nome
			endif
		endif
	endif
return _lRet



// --------------------------------------------------------------------------
// Valida transportadora redespacho.
static function _ValTrRed ()
	local _lRet := .T.
	if ! empty (_sTransRed)
		if _sTransRed == _sTransNeg
			u_help ("Transportadora redespacho e negociada nao podem ser iguais.")
			_lRet = .F.
		else 
			sa4 -> (dbsetorder (1))
			if ! sa4 -> (dbseek (xfilial ("SA4") + _sTransRed, .F.))
				u_help ("Transportadora nao cadastrada.")
				_lRet = .F.
			else
				_sNomTrRed = sa4 -> a4_nome
			endif
		endif
	endif
return _lRet



// --------------------------------------------------------------------------
// Valida valor negociado.
static function _ValNeg ()
	local _lRet := .T.
	if _nNegociad != 0 .and. empty (_sTransNeg)
		u_help ("Informe antes a transportadora.")
		_lRet = .F.
	endif
return _lRet



// --------------------------------------------------------------------------
// Grava os dados da opcao selecionada ou valor negociado, se for o caso.
static function _Seleciona ()
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->	local _lContinua := .T.
//	local _nLin      := 0

// Nao usa mais esta rotina a partir da tela de pedidos de venda -->	if _lContinua .and. FunName()=='OMSA200'
		dbselectarea("DAI")
		dbsetorder(1)
		if dbseek(xFilial("DAI") + DAK->DAK_COD)
			While !Eof() .and. DAI->DAI_COD == DAK->DAK_COD
				_oClsFrtPV := ClsFrtPV():New ()
				_oClsFrtPV:_C5NUM     = DAI->DAI_PEDIDO
				_oClsFrtPV:_C5CLIENTE = DAI->DAI_CLIENT
				_oClsFrtPV:_C5LOJACLI = DAI->DAI_LOJA
				_oClsFrtPV:_C5CLIENT  = DAI->DAI_CLIENT
				_oClsFrtPV:_C5LOJAENT = DAI->DAI_LOJA
				_oClsFrtPV:_ZZ1ORIGEM = _sOrigem
				_oClsFrtPV:_ZZ1DESTIN = _sDestino
				_oClsFrtPV:_C5TRANSP  = ""
				_oClsFrtPV:_ZZ1VLNEGO = 0
				_oClsFrtPV:_ZZ1VLCALC = 0
				_oClsFrtPV:_TrRedesp  = _sTransRed
			
				// Se o usuario informou um valor negociado, ignora os demais.
				if ! empty (_sTransNeg)
					if _nNegociad > 0
						_oClsFrtPV:_C5TRANSP  = _sTransNeg
						_oClsFrtPV:_ZZ1VLNEGO = _nNegociad
					endif
				endif
				
				U_FrtPV ("I")
				
				dbselectarea("DAI")
				dbskip()	
			Enddo
		endif	
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->	elseif _lContinua 
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->	
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		_oClsFrtPV:_C5NUM     = m->c5_num
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		_oClsFrtPV:_C5CLIENTE = m->c5_cliente
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		_oClsFrtPV:_C5LOJACLI = m->c5_lojacli
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		_oClsFrtPV:_C5CLIENT  = m->c5_client
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		_oClsFrtPV:_C5LOJAENT = m->c5_lojaent
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		_oClsFrtPV:_ZZ1ORIGEM = _sOrigem
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		_oClsFrtPV:_ZZ1DESTIN = _sDestino
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		_oClsFrtPV:_C5TRANSP  = ""
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		_oClsFrtPV:_ZZ1VLNEGO = 0
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		_oClsFrtPV:_ZZ1VLCALC = 0
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		_oClsFrtPV:_TrRedesp  = _sTransRed
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->	
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		// Se o usuario informou um valor negociado, ignora os demais.
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		if ! empty (_sTransNeg)
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->			if _nNegociad > 0
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->				_oClsFrtPV:_C5TRANSP  = _sTransNeg
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->				_oClsFrtPV:_ZZ1VLNEGO = _nNegociad
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->			endif
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		endif 
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->	endif
return


/* Nao usa mais esta rotina a partir da tela de pedidos de venda
// --------------------------------------------------------------------------
// Calcula valor da fatura. Baseia-se no MA410IMPOS de Eduardo Riera.
Static Function _ValFat (nOpc)
	Local aArea		:= GetArea()
	Local aAreaSA1	:= SA1->(GetArea())
	Local aFisGet	:= {}
	Local aFisGetSC5:= {}
	Local aTitles   := {"Nota Fiscal", "Duplicatas", "Rentabilidade"}
	Local aDupl     := {}
	Local aVencto   := {}
	Local aFlHead   := { "Vencimento", "Valor", "?"}
	Local aEntr     := {}
	Local aDuplTmp  := {}
	Local aRFHead   := { RetTitle("C6_PRODUTO"),RetTitle("C6_VALOR"),"C.M.V","Vlr.Presente","Lucro Bruto","Margem de Contribuição(%)"}
	Local aRentab   := {}
	Local nPLocal   := aScan(aHeader,{|x| AllTrim(x[2])=="C6_LOCAL"})
	Local nPTotal   := aScan(aHeader,{|x| AllTrim(x[2])=="C6_VALOR"})
	Local nPValDesc := aScan(aHeader,{|x| AllTrim(x[2])=="C6_VALDESC"})
	Local nPPrUnit  := aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRUNIT"})
	Local nPPrcVen  := aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRCVEN"})
	Local nPQtdVen  := aScan(aHeader,{|x| AllTrim(x[2])=="C6_QTDVEN"})
	Local nPDtEntr  := aScan(aHeader,{|x| AllTrim(x[2])=="C6_ENTREG"})
	Local nPProduto := aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"})
	Local nPTES     := aScan(aHeader,{|x| AllTrim(x[2])=="C6_TES"})
	Local nPNfOri   := aScan(aHeader,{|x| AllTrim(x[2])=="C6_NFORI"})
	Local nPSerOri  := aScan(aHeader,{|x| AllTrim(x[2])=="C6_SERIORI"})
	Local nPItemOri := aScan(aHeader,{|x| AllTrim(x[2])=="C6_ITEMORI"})
	Local nPIdentB6 := aScan(aHeader,{|x| AllTrim(x[2])=="C6_IDENTB6"})
	Local nPSuframa := 0
	Local nUsado    := Len(aHeader)
	Local nX        := 0
	Local nAcerto   := 0
	Local nPrcLista := 0
	Local nValMerc  := 0
	Local nDesconto := 0
	Local nAcresFin := 0
	Local nQtdPeso  := 0
	Local nRecOri   := 0
	Local nPosEntr  := 0
	Local nItem     := 0
	Local nY        := 0
	Local nPosCpo   := 0
	Local lDtEmi    := SuperGetMv("MV_DPDTEMI",.F.,.T.)
	Local dDataCnd  := M->C5_EMISSAO
	Local oDlg
	Local oDupl
	Local oFolder
	Local oRentab
	Local lCondVenda := .F. // Template GEM
	Local aRentabil := {}
	Local cProduto  := ""
	Local nTotDesc  := 0
	local _nRet := 0
	local _nLinha := 0

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Busca referencias no SC6                     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aFisGet	:= {}
	dbSelectArea("SX3")
	dbSetOrder(1)
	MsSeek("SC6")
	While !Eof().And.X3_ARQUIVO=="SC6"
		cValid := UPPER(X3_VALID+X3_VLDUSER)
		If 'MAFISGET("'$cValid
			nPosIni 	:= AT('MAFISGET("',cValid)+10
			nLen		:= AT('")',Substr(cValid,nPosIni,Len(cValid)-nPosIni))-1
			cReferencia := Substr(cValid,nPosIni,nLen)
			aAdd(aFisGet,{cReferencia,X3_CAMPO,MaFisOrdem(cReferencia)})
		EndIf
		If 'MAFISREF("'$cValid
			nPosIni		:= AT('MAFISREF("',cValid) + 10
			cReferencia	:=Substr(cValid,nPosIni,AT('","MT410",',cValid)-nPosIni)
			aAdd(aFisGet,{cReferencia,X3_CAMPO,MaFisOrdem(cReferencia)})
		EndIf
		dbSkip()
	EndDo
	aSort(aFisGet,,,{|x,y| x[3]<y[3]})

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Busca referencias no SC5                     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aFisGetSC5	:= {}
	dbSelectArea("SX3")
	dbSetOrder(1)
	MsSeek("SC5")
	While !Eof().And.X3_ARQUIVO=="SC5"
		cValid := UPPER(X3_VALID+X3_VLDUSER)
		If 'MAFISGET("'$cValid
			nPosIni 	:= AT('MAFISGET("',cValid)+10
			nLen		:= AT('")',Substr(cValid,nPosIni,Len(cValid)-nPosIni))-1
			cReferencia := Substr(cValid,nPosIni,nLen)
			aAdd(aFisGetSC5,{cReferencia,X3_CAMPO,MaFisOrdem(cReferencia)})
		EndIf
		If 'MAFISREF("'$cValid
			nPosIni		:= AT('MAFISREF("',cValid) + 10
			cReferencia	:=Substr(cValid,nPosIni,AT('","MT410",',cValid)-nPosIni)
			aAdd(aFisGetSC5,{cReferencia,X3_CAMPO,MaFisOrdem(cReferencia)})
		EndIf
		dbSkip()
	EndDo
	aSort(aFisGetSC5,,,{|x,y| x[3]<y[3]})

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Inicializa a funcao fiscal                   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	MaFisSave()
	MaFisEnd()
	MaFisIni(Iif(Empty(M->C5_CLIENT),M->C5_CLIENTE,M->C5_CLIENT),;// 1-Codigo Cliente/Fornecedor
	M->C5_LOJAENT,;		// 2-Loja do Cliente/Fornecedor
	IIf(M->C5_TIPO$'DB',"F","C"),;				// 3-C:Cliente , F:Fornecedor
	M->C5_TIPO,;				// 4-Tipo da NF
	M->C5_TIPOCLI,;		// 5-Tipo do Cliente/Fornecedor
	Nil,;
		Nil,;
		Nil,;
		Nil,;
		"MATA461")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Realiza alteracoes de referencias do SC5         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Len(aFisGetSC5) > 0
		dbSelectArea("SC5")
		For nY := 1 to Len(aFisGetSC5)
			If !Empty(&("M->"+Alltrim(aFisGetSC5[ny][2])))
				MaFisAlt(aFisGetSC5[ny][1],&("M->"+Alltrim(aFisGetSC5[ny][2])),,.F.)
			EndIf
		Next nY
	Endif

//Na argentina o calculo de impostos depende da serie.
	If cPaisLoc == 'ARG'
		SA1->(DbSetOrder(1))
		SA1->(MsSeek(xFilial()+IIf(!Empty(M->C5_CLIENT),M->C5_CLIENT,M->C5_CLIENTE)+M->C5_LOJAENT))
		MaFisAlt('NF_SERIENF',LocXTipSer('SA1',MVNOTAFIS))
	Endif
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Agrega os itens para a funcao fiscal         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If nPTotal > 0 .And. nPValDesc > 0 .And. nPPrUnit > 0 .And. nPProduto > 0 .And. nPQtdVen > 0 .And. nPTes > 0
		For nX := 1 To Len(aCols)
			nQtdPeso := 0
			If Len(aCols[nX])==nUsado .Or. !aCols[nX][nUsado+1]
				nItem++
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Posiciona Registros                          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				cProduto := aCols[nX][nPProduto]
				MatGrdPrRf(@cProduto)
				SB1->(dbSetOrder(1))
				If SB1->(MsSeek(xFilial("SB1")+cProduto))
					nQtdPeso := aCols[nX][nPQtdVen]*SB1->B1_PESO
				EndIf

				If nPIdentB6 <> 0 .And. !Empty(aCols[nX][nPIdentB6])
					SD1->(dbSetOrder(4))
					If SD1->(MSSeek(xFilial("SD1")+aCols[nX][nPIdentB6]))
						nRecOri := SD1->(Recno())
					EndIf
				ElseIf nPNfOri > 0 .And. nPSerOri > 0 .And. nPItemOri > 0
					If !Empty(aCols[nX][nPNfOri]) .And. !Empty(aCols[nX][nPItemOri])
						SD1->(dbSetOrder(1))
						If SD1->(MSSeek(xFilial("SD1")+aCols[nX][nPNfOri]+aCols[nX][nPSerOri]+M->C5_CLIENTE+M->C5_LOJACLI+aCols[nX][nPProduto]+aCols[nX][nPItemOri]))
							nRecOri := SD1->(Recno())
						EndIf
					EndIf
				EndIf
				SB2->(dbSetOrder(1))
				SB2->(MsSeek(xFilial("SB2")+SB1->B1_COD+aCols[nX][nPLocal]))
				SF4->(dbSetOrder(1))
				SF4->(MsSeek(xFilial("SF4")+aCols[nX][nPTES]))
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Calcula o preco de lista                     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				nValMerc  := aCols[nX][nPTotal]
				nPrcLista := aCols[nX][nPPrUnit]
				If ( nPrcLista == 0 )
					nPrcLista := NoRound(nValMerc/aCols[nX][nPQtdVen],TamSX3("C6_PRCVEN")[2])
				EndIf
				nAcresFin := A410Arred(aCols[nX][nPPrcVen]*M->C5_ACRSFIN/100,"D2_PRCVEN")
				nValMerc  += A410Arred(aCols[nX][nPQtdVen]*nAcresFin,"D2_TOTAL")
				nDesconto := a410Arred(nPrcLista*aCols[nX][nPQtdVen],"D2_DESCON")-nValMerc
				nDesconto := IIf(nDesconto==0,aCols[nX][nPValDesc],nDesconto)
				nDesconto := Max(0,nDesconto)
				nPrcLista += nAcresFin

//Para os outros paises, este tratamento e feito no programas que calculam os impostos.
				If cPaisLoc=="BRA"
					nValMerc  += nDesconto
				Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica a data de entrega para as duplicatas³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If ( nPDtEntr > 0 )
					If ( dDataCnd > aCols[nX][nPDtEntr] .And. !Empty(aCols[nX][nPDtEntr]) )
						dDataCnd := aCols[nX][nPDtEntr]
					EndIf
				Else
					dDataCnd  := M->C5_EMISSAO
				EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Agrega os itens para a funcao fiscal         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				MaFisAdd(cProduto,;   	// 1-Codigo do Produto ( Obrigatorio )
				aCols[nX][nPTES],;	   	// 2-Codigo do TES ( Opcional )
				aCols[nX][nPQtdVen],;  	// 3-Quantidade ( Obrigatorio )
				nPrcLista,;		  	// 4-Preco Unitario ( Obrigatorio )
				nDesconto,; 	// 5-Valor do Desconto ( Opcional )
				"",;	   			// 6-Numero da NF Original ( Devolucao/Benef )
				"",;				// 7-Serie da NF Original ( Devolucao/Benef )
				nRecOri,;					// 8-RecNo da NF Original no arq SD1/SD2
				0,;					// 9-Valor do Frete do Item ( Opcional )
				0,;					// 10-Valor da Despesa do item ( Opcional )
				0,;					// 11-Valor do Seguro do item ( Opcional )
				0,;					// 12-Valor do Frete Autonomo ( Opcional )
				nValMerc,;			// 13-Valor da Mercadoria ( Obrigatorio )
				0)					// 14-Valor da Embalagem ( Opiconal )
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Calculo do ISS                               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				SF4->(dbSetOrder(1))
				SF4->(MsSeek(xFilial("SF4")+aCols[nX][nPTES]))
				If ( M->C5_INCISS == "N" .And. M->C5_TIPO == "N")
					If ( SF4->F4_ISS=="S" )
						nPrcLista := a410Arred(nPrcLista/(1-(MaAliqISS(nItem)/100)),"D2_PRCVEN")
						nValMerc  := a410Arred(nValMerc/(1-(MaAliqISS(nItem)/100)),"D2_PRCVEN")
						MaFisAlt("IT_PRCUNI",nPrcLista,nItem)
						MaFisAlt("IT_VALMERC",nValMerc,nItem)
					EndIf
				EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Altera peso para calcular frete              ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				MaFisAlt("IT_PESO",nQtdPeso,nItem)
				MaFisAlt("IT_PRCUNI",nPrcLista,nItem)
				MaFisAlt("IT_VALMERC",nValMerc,nItem)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Analise da Rentabilidade                     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If SF4->F4_DUPLIC=="S"
					nTotDesc += MaFisRet(nItem,"IT_DESCONTO")
					nY := aScan(aRentab,{|x| x[1] == aCols[nX][nPProduto]})
					If nY == 0
						aadd(aRenTab,{aCols[nX][nPProduto],0,0,0,0,0})
						nY := Len(aRenTab)
					EndIf
					If cPaisLoc=="BRA"
						aRentab[nY][2] += (nValMerc - nDesconto)
					Else
						aRentab[nY][2] += nValMerc
					Endif
					aRentab[nY][3] += aCols[nX][nPQtdVen]*SB2->B2_CM1
				Else
					If GetNewPar("MV_TPDPIND","1")=="1"
						nTotDesc += MaFisRet(nItem,"IT_DESCONTO")
					EndIf
				EndIf
			EndIf
		Next nX
	EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Indica os valores do cabecalho               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	MaFisAlt("NF_FRETE",M->C5_FRETE)
	If !Empty(SC5->(FieldPos("C5_VLR_FRT")))
		MaFisAlt("NF_VLR_FRT",M->C5_VLR_FRT)
	EndIf
	MaFisAlt("NF_SEGURO",M->C5_SEGURO)
	MaFisAlt("NF_AUTONOMO",M->C5_FRETAUT)
	MaFisAlt("NF_DESPESA",M->C5_DESPESA)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Indenizacao por valor                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If M->C5_DESCONT > 0
		MaFisAlt("NF_DESCONTO",Min(MaFisRet(,"NF_VALMERC")-0.01,nTotDesc+M->C5_DESCONT),,,,GetNewPar("MV_TPDPIND","1")=="2" )
	EndIf

	If M->C5_PDESCAB > 0
		MaFisAlt("NF_DESCONTO",A410Arred(MaFisRet(,"NF_VALMERC")*M->C5_PDESCAB/100,"C6_VALOR")+MaFisRet(,"NF_DESCONTO"))
	EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Realiza alteracoes de referencias do SC6         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("SC6")
	If Len(aFisGet) > 0
		For nX := 1 to Len(aCols)
			If Len(aCols[nX])==nUsado .Or. !aCols[nX][Len(aHeader)+1]
				For nY := 1 to Len(aFisGet)
					nPosCpo := aScan(aHeader,{|x| AllTrim(x[2])==Alltrim(aFisGet[ny][2])})
					If nPosCpo > 0
						If !Empty(aCols[nX][nPosCpo])
							MaFisAlt(aFisGet[ny][1],aCols[nX][nPosCpo],nX,.F.)
						Endif
					EndIf
				Next nX
			Endif
		Next nY
	EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Realiza alteracoes de referencias do SC5 Suframa ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	nPSuframa:=aScan(aFisGetSC5,{|x| x[1] == "NF_SUFRAMA"})
	If !Empty(nPSuframa)
		dbSelectArea("SC5")
		If !Empty(&("M->"+Alltrim(aFisGetSC5[nPSuframa][2])))
			MaFisAlt(aFisGetSC5[nPSuframa][1],Iif(&("M->"+Alltrim(aFisGetSC5[nPSuframa][2])) == "1",.T.,.F.),nItem,.F.)
		EndIf
	Endif
	If ExistBlock("M410PLNF")
		ExecBlock("M410PLNF",.F.,.F.)
	EndIf
	MaFisWrite(1)

	_nRet = MaFisRet(,"NF_TOTAL")

	MaFisEnd()
	MaFisRestore()

	RestArea(aAreaSA1)
	RestArea(aArea)

Return(_nRet)
*/
