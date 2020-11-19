#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"

// ROTINA DE GRAVAÇÃO DA GUIA DE LIVRE TRANSITO
//
// Historico de alteracoes:
// 08/09/2011 - Robert - Valida UF do cliente com tipo de operacao no 'Tudo OK'.
// 14/03/2013 - Elaine - Passa a tratar a operação (Sisdeclara) pela TES das NFs seleciondas e somente deixar incluir se todas as
//                       notas tiverem a mesma operação. Não existe mais interação do usuário neste campo, vai vir da TES e não pode alterar.
// 11/07/2013 - Robert - Passa a aceitar tambem acucar nas guias.
// 21/08/2013 - Leandro DWT - Inclusão de função para pegar o nome do cliente ou fornecedor, e jogar no browse ...  está no inicializador de browse do campo
// 04/09/2013 - Leandro DWT - Permite até 15 notas vinculadas à guia
// 06/09/2013 - Leandro	DWT - Ajusta o tipo de operação conforme o estado do cliente (somente nos casos do tipo ser 01 ou 02)
// 01/08/2014 - Robert - Criada funcao de validacao de linha para verificar preenchimento de campos.
// 02/04/2015 - Robert - Valida quantidade de campos ZQ_NF01, ZQ_NF02, ...
//                     - Deixa de usar os campos ZQ_NF01, ZQ_NF02, ... e toda a amarracao fica apenas no SF2.
// 13/01/2016 - Robert - Impede uso de TES que nao movimente estoque, bem como configurado como 'nao gera Sisdeclara.'
// 17/05/2016 - Robert - Campos do Sisdeclara migrados da tabela SB1 para SB5.
// 09/08/2018 - Robert - Estabelace litragem minima (GLPI 1499).
// 06/09/2019 - Robert - Desabilitada inclusao / alteracao (agora se geram guias via portal)
//

// --------------------------------------------------------------------------
User Function VA_SZQ()
	PRIVATE cCadastro := "Cadastro de Guias de Livre Transito"
	PRIVATE aRotina := { {"Pesquisar", "AxPesqui", 	0 ,	1},;
		{"Visualizar", 	"u_VA_SZQA('SZQ', SZQ->(RECNO()), 2)", 	0 ,	2},;
		{"Incluir",		"u_VA_SZQA('SZQ', SZQ->(RECNO()), 3)", 	0 ,	3},;
		{"Alterar",		"u_VA_SZQA('SZQ', SZQ->(RECNO()), 4)", 	0 ,	4},;
		{"Excluir",		"u_VA_SZQA('SZQ', SZQ->(RECNO()), 5)", 	0 ,	5},;
		{"Imprimir",	"u_VA_SZQR(SZQ->ZQ_NUMERO)",	0 ,	6}}
	private _sArqLog := U_NomeLog ()
	u_logIni ()
	mBrowse( 6, 1,22,75,"SZQ",,,)
Return



// --------------------------------------------------------------------------
//Tela de Manutenção
User Function VA_SZQA(cAlias, nReg, nAcao)
	
	local lRet
	//local cCampo
	local _nLinha, _nF, _cNf
	local _aButtons	 	 := {}
	//local aCpoEnChoice   := {}
	local _nCampo      	 := 0
	local _nX			 := 0
	PRIVATE aCols        := {}
	PRIVATE aHeader      := {}
	PRIVATE aAltEnChoice := {}
	PRIVATE aAltGetDados := {}
	PRIVATE nUsado       := 0
	PRIVATE _nTamItem	 :=	TAMSX3("ZR_ITEM")[1]
	private _nMaxNotas   := 15  // Deve estar de acordo com a quantidade de campos ZQ_NF01, ZQ_NF02, ...

	if nAcao == 3 .or. nAcao == 4
		u_help ("Esta rotina permanece apenas para consultas de guias antigas, pois atualmente as guias sao emitidas via internet.")
		RETURN
	endif

	RegToMemory( "SZQ", IIf(nAcao == 3, .t., .f.) )

	for _nCampo = 1 to _nMaxNotas
		if type ('M->ZQ_NF' + strzero (_nCampo, 2)) != 'C' .or. type ('M->ZQ_SERIE' + strzero (_nCampo, 2)) != 'C'
			u_help ("Nao ha suficientes campos de NF/serie 'em uso'. Incompatibilidade entre o programa e o dicionario de dados.")
			return
		endif
	next

	MontaHead()
	MontaCols(nAcao)

	If (nAcao == 3) .or. (nAcao == 4)
		aadd( _aButtons, { "VERNOTA", { || Processa( {|| _SelNotas()}, "Selecionando as notas..." ) }, "Busca as Notas do Cliente/Fornecedor", "Notas" } )
	Endif

//	lRet	:=	Modelo3(cCadastro, "SZQ", "SZR", {"ZQ_NUMERO"}, "U_VASZQLOK()"/*valida linha*/, "U_VASZQTOK()"/*valida tela*/, nAcao, nAcao, "AllwaysTrue()", .t., 999, nil, nil, _aButtons, nil, 200)
	lRet	:=	Modelo3(cCadastro, "SZQ", "SZR", {"ZQ_NUMERO"}, "U_VASZQLOK()"/*valida linha*/, "U_VASZQTOK()"/*valida tela*/, nAcao, nAcao, "AllwaysTrue()", .t., 999, nil, nil, _aButtons, nil, oMainWnd:nClientHeight / 2)
	If lRet
		If (nAcao == 3) .or. (nAcao == 4)	//inclusão ou alteração
			begin transaction
			DbSelectArea("SZR")
			DbSetOrder(1)
			DbSelectArea("SZQ")
			DbSetOrder(1)
			DbSeek( xFilial("SZQ")+M->ZQ_NUMERO )
			If Found()
				RecLock( "SZQ", .f. )
			Else
				RecLock( "SZQ", .t. )
			Endif
			//registra a gravação da capa da guia
			For _nX := 1 to FCount()
				_cCpo	:=	"M->"+Fieldname(_nX)
				_xVar 	:=	&_cCpo
				FieldPut(_nX, _xVar)
			Next
			SZQ->ZQ_FILIAL	:=	xFilial("SZQ")
			MsUnLock()
			msmm (,,, M->ZQ_OBSERV, 1,,, "SZQ", "ZQ_CODOBS")
			//registra a gravação dos itens da guia
			For _nLinha := 1 To Len(aCols)
				If !aCols[_nLinha, Len(aHeader) + 1]	//linha válida
					DbSelectArea("SZR")
					DbSeek( xFilial("SZR")+M->ZQ_NUMERO+aCols[_nLinha, 1] )
					If Found()
						RecLock( "SZR", .f. )
					Else
						RecLock( "SZR", .t. )
					Endif
					For _nX := 1 to Len(aHeader)
						_nPos	:=	FieldPos( Alltrim(aHeader[_nX, 2]) )
						IF _nPos > 0
							FieldPut(_nPos, aCols[_nLinha, _nX])
						Endif
					Next
					SZR->ZR_FILIAL	:=	xFilial("SZR")
					SZR->ZR_NUMERO	:=	M->ZQ_NUMERO
					MsUnLock()
				Else	//linha apagada
					DbSelectArea("SZR")
					DbSeek( xFilial("SZR")+M->ZQ_NUMERO+aCols[_nLinha, 1] )
					If Found()
						RecLock( "SZR", .f. )
						DbDelete()
						MsUnLock()
					Endif
				Endif
			Next
			ConfirmSx8()
			//registra o número da guia no cabeçalho da nota fiscal (SF2)
			DbSelectArea( "SF2" )
			DbSetOrder(2)
			For _nF := 1 To _nMaxNotas
				_cNf	:=	StrZero(_nF, 2)
				If !Empty( M->&("ZQ_NF"+_cNf) )
					DbSelectArea( "SF2" )
					DbSeek( xFilial("SF2") + M->ZQ_CLIENTE + M->ZQ_LOJA + M->&("ZQ_NF"+_cNf) + M->&("ZQ_SERIE"+_cNf) )
					If Found()
						RecLock( "SF2", .f. )
						F2_VAGUIA	:=	M->ZQ_NUMERO
						MsUnLock()
					Endif
				Else
					Exit
				Endif
			Next _nF
			end transaction
		Elseif nAcao == 5					//exclusão
			begin transaction
			//apaga os dados da capa da guia
			DbSelectArea("SZR")
			DbSetOrder(1)
			DbSelectArea("SZQ")
			DbSetOrder(1)
			DbSeek( xFilial("SZQ")+M->ZQ_NUMERO )
			If Found()
				RecLock( "SZQ", .f. )
				DbDelete()
				MsUnLock()
			Endif

			//apaga os itens da guia
			For _nLinha := 1 To Len(aCols)
				DbSelectArea("SZR")
				DbSeek( xFilial("SZR")+M->ZQ_NUMERO+aCols[_nLinha, 1] )
				If Found()
					RecLock( "SZR", .f. )
					DbDelete()
					MsUnLock()
				Endif
			Next
			//apaga o vínculo da guia no cabeçalho da nota fiscal (SF2)
			DbSelectArea( "SF2" )
			DbSetOrder(2)
			For _nF := 1 To _nMaxNotas
				_cNf	:=	StrZero(_nF, 2)
				If !Empty( M->&("ZQ_NF"+_cNf) )
					DbSelectArea( "SF2" )
					DbSeek( xFilial("SF2") + M->ZQ_CLIENTE + M->ZQ_LOJA + M->&("ZQ_NF"+_cNf) + M->&("ZQ_SERIE"+_cNf) )
					If Found()
						RecLock( "SF2", .f. )
						F2_VAGUIA	:=	""
						MsUnLock()
					Endif
				Else
					Exit
				Endif
			Next _nF
			end transaction
		Endif
	Elseif (nAcao == 3)
		RollBackSX8()
	EndIf
Return



// --------------------------------------------------------------------------
//monta dados dos itens
Static Function MontaCols(nAcao)
	Local _nI := 0

	aCols := {}
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Monta o array aCols com os itens                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("SZR")
	dbSetOrder(1)
	dbSeek( xFilial("SZR") + M->ZQ_NUMERO )
	While nAcao != 3 .and. !Eof() .And. (ZR_FILIAL+ZR_NUMERO == xFilial("SZR")+M->ZQ_NUMERO)
		AADD(aCols, Array(nUsado+1))
		For _ni:=1 to nUsado
			If AllTrim( aHeader[_ni,2] ) == "ZR_DESCRI"
				aCols[Len(aCols), _ni]	:=	FBUSCACPO( "SB1", 1, xFilial("SB1") + GDFIELDGET("ZR_PRODUTO", Len(aCols)), "B1_DESC" )
			ElseIf AllTrim( aHeader[_ni,2] ) $ "ZR_UNALCO/ZR_UNTOTAL/ZR_UNEXSEC"
				aCols[Len(aCols), _ni]	:=	CriaVar(aHeader[_ni, 2])
			Else
				aCols[Len(aCols), _ni]	:=	FieldGet(FieldPos(aHeader[_ni, 2]))
			Endif
		Next
		aCols[Len(aCols), nUsado+1]	:=	.F.
		dbSkip()
	End

	If Len(aCols) <= 0
		AADD(aCols, Array(nUsado+1))
		For _ni:=1 to nUsado
			aCols[1, _ni]	:=	CriaVar(aHeader[_ni, 2])
		Next
		aCols[Len(aCols), 1]		:=	StrZero(1, _nTamItem)
		aCols[Len(aCols), nUsado+1]	:=	.F.
	Endif
Return



// --------------------------------------------------------------------------
//monta os dados do cabeçalho dos itens
Static Function MontaHead()
	dbSelectArea("SX3")
	dbSetOrder(1)
	dbSeek("SZR")

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Monta o array aHeader para a GetDados()                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	While !Eof() .And. (X3_ARQUIVO == "SZR")
		IF X3USO(X3_USADO) .And. (cNivel >= X3_NIVEL)
			nUsado	:=	nUsado+1
			AADD(aHeader, { Trim(X3_TITULO),X3_CAMPO,X3_PICTURE, ;
				X3_TAMANHO, ;
				X3_DECIMAL, ;
				"AllwaysTrue()" , ;
				X3_USADO,;
				X3_TIPO, ;
				X3_ARQUIVO,;
				X3_CONTEXT } )
		Endif
		dbSkip()
	Enddo
Return



// --------------------------------------------------------------------------
//ROTINA DE VALIDAÇÃO DO CÓDIGO DO CLIENTE
User Function VASZQCLI(_cCliente, _cLoja)
	Local	_aArea	:=	GetArea()
	Local	_bOk	:=	.t.
	RestArea(_aArea)
Return _bOk



// --------------------------------------------------------------------------
Static Function _SelNotas()
	Local	_aArea		:=	GetArea()
	Local	_aDados		:=	{}
	Local	_cQuery		:=	""
	Local	_dData		:=	CTOD("01/05/2011")
	Local	_aCols		:=	{}
	Local	_nLinha		:=	0
	Local	_aProd		:=	{}
	Local	_aNF		:=	{}
	Local	_nF			:=	0
	Local	_cNf		:=	""
	Local	_nPos		:=	0
	Local	_bFirst		:=	.t.
	Local	_cPlacas	:=	""
	Local	_nTamPlaca	:=	TAMSX3("ZQ_PLACAS")[1]
	Local	_aTransp	:=	{}
	Local	_aOper		:=	{}
	Local	_nNfInf		:=	0
	Local	_bMens		:=	.f.
	Local	_bMensNf	:=	.f.
	Local   _ni			:=  0
	private	_cPerg		:=	"VA_SZQ0001"
	private	_cPerg1		:=	"VA_SZQ0001"
	private	_cPerg2		:=	"VA_SZQ0002"
	private	_cCliFor	:=	"C"

	_cCliFor := M->ZQ_CLIFOR

	If !M->ZQ_CLIFOR $ 'F|C'
		u_help( "Informe se a busca sera por Fornecedor ou Cliente" )
		Return
	//elseif !Empty(M->ZQ_NF15)
	elseif !Empty(&('M->ZQ_NF' + strzero (_nMaxNotas, 2)))
		u_help( "Não é possível selecionar mais de " + cvaltochar (_nMaxNotas) + " notas" )
		Return
	Else
		if _cCliFor == "F"
			_cPerg := _cPerg2  // Pergunta pelo Fornecedor
		else
			_cPerg := _cPerg1  // Pergunta pelo Cliente
		endif

		_ValidPerg ()

		U_GravaSX1 (_cPerg, "01", dDatabase - 31)
		If Pergunte(_cPerg)
			_dData	:=	mv_par01
		Else
			Return
		Endif
		if _cCliFor == "F" .and. (mv_par02 == " " .or. mv_par03 == " ")
			MsgAlert( "Um Fornecedor/Loja deve ser informado!!!" )
			Return
		elseif _cCliFor == "F" .and. (mv_par02 == " " .or. mv_par03 == " ")
			MsgAlert( "Um Fornecedor/Loja deve ser informado!!!" )
			Return
		elseif _cCliFor == "C" .and. (mv_par02 == " " .or. mv_par03 == " ")
			MsgAlert( "Um Cliente/Loja deve ser informado!!!" )
			Return
		elseif mv_par02 <> " " .and. mv_par03 <> " "
			M->ZQ_CLIENTE    := MV_PAR02
			M->ZQ_LOJA       := MV_PAR03
		endif

		if _cCliFor == "F"
			if ExistCpo("SA2", mv_par02 + mv_par03)
				If Empty(FBUSCACPO("SA2", 1, xFilial("SA2")+mv_par02+mv_par03, "A2_VAREGMA"))
					MsgAlert( "Fornecedor não possui Registro MAA informado no cadastro." )
					return
				else
					M->ZQ_NOMECLI := FBUSCACPO("SA2", 1, xFilial("SA2")+mv_par02+mv_par03, "A2_NOME")
				Endif
			Else
				MsgAlert( "Fornecedor Inexistente!!." )
				return
			endif
		else
			if ExistCpo("SA1", mv_par02 + mv_par03)
				If Empty(FBUSCACPO("SA1", 1, xFilial("SA1")+mv_par02+mv_par03, "A1_VAREGMA"))
					MsgAlert( "Cliente não possui Registro MAA informado no cadastro." )
					return
				else
					M->ZQ_NOMECLI := FBUSCACPO("SA1", 1, xFilial("SA1")+mv_par02+mv_par03, "A1_NOME")
				Endif
			Else
				MsgAlert( "Cliente Inexistente!!." )
				return
			endif
		endif
	Endif

	//verifica quantas notas já estão informadas
	For _nF := 1 To _nMaxNotas
		_cNf	:=	StrZero(_nF, 2)
		If !Empty( M->&("ZQ_NF"+_cNf) )
			_nNfInf++
		Endif
	Next _nF

	_cQuery	:=	" SELECT D2_DOC, D2_SERIE, D2_EMISSAO, D2_COD, D2_QUANT, D2_UM, B1_DESC, F2_TRANSP, F2_VEICUL1, F2_VEICUL2, F2_VEICUL3, F4_VASISDE, D2_TES "
	_cQuery	+=	"   FROM " + RetSqlName( "SB1" ) + " B1, " + RetSqlName( "SF2" ) + " F2, " + RetSqlName( "SF4" ) + " F4, " + RetSqlName( "SD2" ) + " D2, " + RetSqlName( "SB5" ) + " B5 "
	_cQuery	+=	"  WHERE B1.D_E_L_E_T_ <> '*' "
	_cQuery	+=	"    AND (B1_GRPEMB = '18' OR B5_VATPSIS IN ('24', '40'))"  // Borra ou acucar.
	_cQuery	+=	"    AND B1_COD = D2_COD "
	_cQuery	+=	"    AND B1_FILIAL = '" + xFilial("SB1") + "' "
	_cQuery	+=	"    AND B5_COD = B1_COD"
	_cQuery	+=	"    AND B5_FILIAL = '" + xFilial("SB5") + "' "
	_cQuery	+=	"    AND F2.D_E_L_E_T_ <> '*' "
	_cQuery	+=	"    AND F4.D_E_L_E_T_ <> '*' "
	_cQuery	+=	"    AND B5.D_E_L_E_T_ <> '*' "
	If !Empty(M->ZQ_TRANSP)
		_cQuery	+=	"    AND F2_TRANSP = '" + M->ZQ_TRANSP + "' "
	Endif
	If _cCliFor == "F"
		_cQuery	+=	"    AND F2_TIPO IN('B', 'D') "
	else
		_cQuery	+=	"    AND F2_TIPO NOT IN('B', 'D') "
	Endif
	_cQuery	+=	"    AND F2_VAGUIA = ' ' "
	_cQuery	+=	"    AND F2_TIPO = D2_TIPO "
	_cQuery	+=	"    AND F2_LOJA = D2_LOJA "
	_cQuery	+=	"    AND F2_CLIENTE = D2_CLIENTE "
	_cQuery	+=	"    AND F2_SERIE = D2_SERIE "
	_cQuery	+=	"    AND F2_DOC = D2_DOC "
	_cQuery	+=	"    AND F4_CODIGO = D2_TES "

	
	// Robert, 13/01/2016
	_cQuery	+=	"    AND NOT (F4_VASISDE = '99' AND F4_VASISEN = '99')"
	_cQuery	+=	"    AND F4_ESTOQUE = 'S'"

	
	_cQuery	+=	"    AND F2_FILIAL = D2_FILIAL "
	_cQuery	+=	"    AND D2.D_E_L_E_T_ <> '*' "
	_cQuery	+=	"    AND D2_DOC+D2_SERIE NOT IN (" + _Notas() + ") "
	_cQuery	+=	"    AND D2_LOJA = '" + MV_PAR03 + "' "
	_cQuery	+=	"    AND D2_CLIENTE = '" + MV_PAR02 + "' "
	_cQuery	+=	"    AND D2_EMISSAO >= '" + DTOS(_dData) + "' "
	_cQuery	+=	"    AND D2_FILIAL = '" + xFilial("SD2") + "' "
	_cQuery	+=	"    AND (B1_LITROS = 0 OR D2_QUANT * B1_LITROS >= 10)" // Litragem (quando aplicavel) minima (GLPI 1499).
	_cQuery	+=	"  ORDER BY D2_EMISSAO DESC, D2_DOC DESC "
	u_log (_cQuery)
	ProcRegua( 50 )
	TCQuery _cQuery NEW ALIAS "_NF"
	TCSetField( "_NF", "D2_EMISSAO", "D" )
	DbSelectArea("_NF")
	DbGoTop()
	While !Eof()
		IncProc()

		//verifica se há mais de 10 notas selecionadas
		_nPos	:=	ascan (_aNF, {|x| x[1]+X[2] == _NF->D2_DOC + _NF->D2_SERIE})
		If _nPos <= 0
			aadd( _aNF, {_NF->D2_DOC, _NF->D2_SERIE, nil, nil} )
		Endif
		If !_bMensNf .and. ( (Len(_aNf) + _nNfInf) > _nMaxNotas )
			_bMensNf	:=	.t.
			MsgAlert( "A T E N Ç Ã O. Há mais de " + cvaltochar (_nMaxNotas) + " notas diferentes." )
		Endif

		//verifica se há mais de um a transportadora nas notas
		If _bFirst
			_bFirst := .f.
			_cTraPadrao	:=	_NF->F2_TRANSP
		Endif
		If !_bMens .and. (_cTraPadrao <> _NF->F2_TRANSP)
			_bMens	:=	.t.
			u_help( "A T E N Ç Ã O. Há notas com diferentes transportadoras." )
		Endif

		if empty (_NF->F4_VASISDE)
			u_help ("Tipo de operacao (campo '" + alltrim (RetTitle ("F4_VASISDE")) + "' nao informado no cadastro do TES '" + _NF -> d2_tes + "'. Nota '" + _NF -> d2_doc + "' vai ser desconsiderada.")
			DbSelectArea("_NF")
			DbSkip()
			loop
		endif

		aadd( _aDados, {IIF(_cTraPadrao == _NF->F2_TRANSP, IIf( (Len(_aNF) + _nNfInf) <= _nMaxNotas, .t., .f.), .f.),;
			_NF->D2_DOC,;
			_NF->D2_SERIE,;
			_NF->D2_EMISSAO,;
			_NF->D2_COD,;
			_NF->D2_QUANT,;
			_NF->D2_UM,;
			_NF->B1_DESC,;
			_NF->F2_TRANSP,;
			FBUSCACPO("SA4", 1, xFilial("SA4")+_NF->F2_TRANSP, "A4_NOME"),;
			_Placas(_NF->F2_VEICUL1, _NF->F2_VEICUL2, _NF->F2_VEICUL3, _nTamPlaca),;
			_NF->F4_VASISDE,;
			} )
		DbSelectArea("_NF")
		DbSkip()
	End
	_NF -> ( DBCloseArea() )
	RestArea(_aArea)

	If Len(_aDados) > 0
		aadd (_aCols, {02, "Nota",       40, "@!"})
		aadd (_aCols, {03, "Serie",      30, "@!"})
		aadd (_aCols, {04, "Emissao",    50, "@D"})
		aadd (_aCols, {05, "Produto",    40, "@!"})
		aadd (_aCols, {06, "Qtde.",      50, "@E 999,999,999.99"})
		aadd (_aCols, {07, "Un.med",     30, "@!"})
		aadd (_aCols, {08, "Descrição", 150, "@!"})
		aadd (_aCols, {09, "Transp.",    40, "@!"})
		aadd (_aCols, {10, "Nome",      100, "@!"})
		aadd (_aCols, {11, "Placa(s)",  150, "@!"})
		u_MBArray (@_aDados, "Selecione os Produtos", _aCols, 1, 750, 400)

		//verifica o número de notas selecionadas
		_aNF	:=	{}
		For _nLinha := 1 To Len(_aDados)
			If _aDados[_nLinha, 1]

				//aglutina as notas e séries
				_nPos	:=	ascan (_aNF, {|x| x[1]+X[2] == _aDados[_nLinha, 2]+_aDados[_nLinha, 3]})
				If _nPos <= 0
					aadd( _aNF, {_aDados[_nLinha, 2], _aDados[_nLinha, 3], _aDados[_nLinha, 9], _aDados[_nLinha, 10], _aDados[_nLinha, 12]} )
				Endif

				//aglutina as transportadoras
				_nPos	:=	ascan (_aTransp, {|x| x[1] == _aDados[_nLinha, 9]})
				If _nPos <= 0
					aadd( _aTransp, {_aDados[_nLinha, 9]} )
				Endif

				//aglutina as operacoes
				_nPos	:=	ascan (_aOper, {|x| x[1] == _aDados[_nLinha, 12]})
				If _nPos <= 0
					aadd( _aOper, {_aDados[_nLinha, 12]} )
				Endif
			Endif
		Next
		If Len(_aNF) > 0
			If (Len(_aNF) + _nNfInf)  > _nMaxNotas
				u_help( "O sistema permite apenas a seleção de no máximo " + cvaltochar (_nMaxNotas) + " notas." )
				RestArea(_aArea)
				Return
			Elseif Len(_aTransp) > 1
				u_help( "Foram informadas notas com diferentes transportadoras. O sistema permite apenas a seleção de uma transportadora." )
				RestArea(_aArea)
				Return
			Elseif Len(_aOper) > 1
				MsgAlert( "Foram informadas notas com diferentes operações do Sisdeclara. Todas as notas devem ter a mesma operação." )
				RestArea(_aArea)
				Return
			Else
				For _nLinha := 1 To Len(_aNF)

					//preenche o campo da transportadora se não estiver
					If Empty(M->ZQ_TRANSP)
						M->ZQ_TRANSP	:=	_aNF[1, 3]
						M->ZQ_NOMETRA	:=	_aNF[1, 4]
					Endif

					//verifica se há duplicidade das notas informadas
					For _nF := 1 To _nMaxNotas
						_cNf	:=	StrZero(_nF, 2)
						If (M->&("ZQ_NF"+_cNf) == _aNF[_nLinha, 1]) .and. (M->&("ZQ_SERIE"+_cNf) == _aNF[_nLinha, 2])
							Exit
						Elseif Empty( M->&("ZQ_NF"+_cNf) )
							M->&("ZQ_NF"+_cNf)		:=	_aNF[_nLinha, 1]
							M->&("ZQ_SERIE"+_cNf)	:=	_aNF[_nLinha, 2]
							Exit
						Endif
					Next _nF
				Next

				M->ZQ_TPOPER := _aNF[1,5]

				// Verifica UF do cliente X tipo de operacao.
				// Se no TES tiver operacao = 01 e UF do destinatário = MV_ESTADO (RS), trocar para 02
				// Se no TES tiver operacao = 02 e UF do destinatário != MV_ESTADO (RS), trocar para 01
				if M->ZQ_TPOPER == '01'
					if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->zq_cliente + m->zq_loja, "A1_EST") == alltrim(SuperGetMV("MV_ESTADO", .F.,"RS"))
						M->ZQ_TPOPER := '02'
					endif
				elseif M->ZQ_TPOPER == '02'
					if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->zq_cliente + m->zq_loja, "A1_EST") != alltrim(SuperGetMV("MV_ESTADO", .F.,"RS"))
						M->ZQ_TPOPER := '01'
					endif
				endif

			Endif
		Endif

		For _nLinha := 1 To Len(_aDados)
			If _aDados[_nLinha, 1]
				//aglutina os produtos selecionados
				_nPos	:=	ascan (_aProd, {|x| x[1] == _aDados[_nLinha, 5]})
				If _nPos <= 0
					aadd( _aProd, {_aDados[_nLinha, 5], _aDados[_nLinha, 6], _aDados[_nLinha, 8]} )
				Else
					_aProd[_nPos, 2]	+=	_aDados[_nLinha, 6]
				Endif
				//verifica os números de placas e atualiza a tela e tabela
				If !Empty(_aDados[_nLinha, 11]) .and. !( AllTrim(_aDados[_nLinha, 11]) $ AllTrim(M->ZQ_PLACAS) )
					_cPlacas		:=	AllTrim(_aDados[_nLinha, 11]) + IIF( Empty(M->ZQ_PLACAS), "", "," + AllTrim(M->ZQ_PLACAS) )
					M->ZQ_PLACAS	:=	_cPlacas + Space( _nTamPlaca - Len(_cPlacas) )
				Endif
			Endif
		Next

		//atualiza as linhas do acols
		If Len(_aProd) > 0
			For _nLinha := 1 To Len(_aProd)
				//verifica se o produto já consta nas linhas dos itens (getdados), para incrementar a quantidade
				_nPos	:=	ascan (aCols, {|x| x[2] == _aProd[_nLinha, 1]})
				If _nPos > 0
					aCols[_nPos, GDFieldPos("ZR_LITROS")]	+=	_aProd[_nLinha, 2]
				Else
					//verifica se a primeira linha está preenchida
					If !Empty(aCols[1, 2])
						_cItem		:=	Soma1( aCols[Len(aCols), 1], _nTamItem )
						AADD(aCols, Array(nUsado+1))
						aCols[Len(aCols), nUsado+1]	:=	.F.
						For _ni:=1 to nUsado
							aCols[Len(aCols), _ni]	:=	CriaVar(aHeader[_ni, 2])
						Next
						aCols[Len(aCols), 1]		:=	_cItem
					Else
						aCols[Len(aCols), GDFieldPos("ZR_ITEM")]	:=	"01"
					Endif

					//preenche os demais dados da linha
					aCols[Len(aCols), GDFieldPos("ZR_PRODUTO")]	:=	_aProd[_nLinha, 1]
					aCols[Len(aCols), GDFieldPos("ZR_LITROS")]	:=	_aProd[_nLinha, 2]
					aCols[Len(aCols), GDFieldPos("ZR_DESCRI")]	:=	_aProd[_nLinha, 3]
					aCols[Len(aCols), GDFieldPos("ZR_DATA")]	:=	dDataBase
				Endif
			Next
			GETDREFRESH() // ATUALIZA OS CAMPOS DE MEMORIA
		Endif
	Else
		if _cCliFor == "C"
			MsgAlert( "Não foram encontradas notas do cliente informado com data de emissão digitada e em condições de gerar guia." )
		else
			MsgAlert( "Não foram encontradas notas do fornecedor informado com data de emissão digitada e em condições de gerar guia." )
		endif

	Endif
	RestArea(_aArea)
Return



// --------------------------------------------------------------------------
//rotina que monta um texto filtrando a notas já informadas
Static Function _Notas()
	Local	_cTexto	:=	""
	Local	_nX

	For _nX := 1 to _nMaxNotas
		_cNota	:=	M->&("ZQ_NF"+StrZero(_nX, 2)) + M->&("ZQ_SERIE"+StrZero(_nX, 2))
		If !Empty(_cNota)
			_cTexto	+=	"'" + _cNota + "',"
		Endif
	Next
	If !Empty(_cTexto)
		_cTexto	:=	Substr(_cTexto, 1, Len(_cTexto) - 1)
	Else
		_cTexto	:=	"''"
	Endif
Return _cTexto



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}

	//                     PERGUNT                            TIPO  TAM DEC VALID F3      Opcoes                                  Help
	aadd (_aRegsPerg, {01, "Emissao de                   ?",  "D",  08, 0,  "",   "   ",  {},                                     ""})
	aadd (_aRegsPerg, {02, "Fornecedor                   ?",  "C",  06, 0,  "",   "SA2",  {},                                     ""})
	aadd (_aRegsPerg, {03, "Loja                         ?",  "C",  02, 0,  "",   "   ",  {},                                     ""})
	U_ValPerg (_cPerg2, _aRegsPerg)

	_aRegsPerg := {}
	//                     PERGUNT                            TIPO  TAM DEC VALID F3      Opcoes                                  Help
	aadd (_aRegsPerg, {01, "Emissao de                   ?",  "D",  08, 0,  "",   "   ",  {},                                     ""})
	aadd (_aRegsPerg, {02, "Cliente                      ?",  "C",  06, 0,  "",   "SA1",  {},                                     ""})
	aadd (_aRegsPerg, {03, "Loja                         ?",  "C",  02, 0,  "",   "   ",  {},                                     ""})
	U_ValPerg (_cPerg1, _aRegsPerg)

Return



// --------------------------------------------------------------------------
//rotina que valida a seleção das notas sem haver duplicidade de transportadora
User Function VA_SZQN()
	Local	_bOk		:=	.t.
	Local	_nPosTra	:=	9
	Local	_nPosLin	:=	_aMBArrayV[2]
	Local	_cTraSelec	:=	_aMBArrayV[1, _nPosLin][_nPosTra]
	Local	_cTraPadrao	:=	""
	Local	_aDados		:=	_aMBArrayV[1]
	Local	_nLinha
	Local	_bTemTra	:=	.f.
	For _nLinha := 1 to Len(_aDados)
		If _aDados[_nLinha, 1]
			_bTemTra	:=	.t.
			If (_nPosLin <> _nLinha)
				_cTraPadrao	:=	_aDados[_nLinha, _nPosTra]
				Exit
			Endif
		Endif
	Next

	If _bTemTra .and. (_cTraSelec <> _cTraPadrao)
		_bOk	:=	.f.
		MsgAlert( "Esta nota possui uma transportadora diferente das demais." )
	Endif
Return _bOK



// --------------------------------------------------------------------------
//rotina que busca as placas dos veículos
Static Function _Placas( _cVeicul1, _cVeicul2, _cVeicul3, _nTam )
	Local	_aArea	:=	GetArea()
	Local	_cTexto	:=	""

	If !Empty(_cVeicul1)
		dbSelectArea("DA3")
		dbSetOrder(1)
		DbSeek(xFilial("DA3")+_cVeicul1)
		If Found()
			_cTexto	+=	AllTrim(DA3->DA3_PLACA) + ","
		Endif
		If !Empty(_cVeicul2)
			dbSelectArea("DA3")
			DbSeek(xFilial("DA3")+_cVeicul2)
			If Found()
				_cTexto	+=	AllTrim(DA3->DA3_PLACA) + ","
			Endif
			If !Empty(_cVeicul3)
				dbSelectArea("DA3")
				MsSeek(xFilial("DA3")+_cVeicul3)
				If Found()
					_cTexto	+=	AllTrim(DA3->DA3_PLACA) + ","
				Endif
			EndIf
		EndIf
	EndIf
	If !Empty(_cTexto)
		_cTexto	:=	Left(_cTexto, Len(_cTexto) - 1) + Space(_nTam - Len(_cTexto) - 1)
	Endif
	RestArea( _aArea )
Return _cTexto



// --------------------------------------------------------------------------
//rotina de validação da tela para avisar quando há mais de 3 produtos informados
User Function VASZQLOK()
	local _lRet := .T.
	//local _sProd := fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("ZR_PRODUTO"), "B1_PROD")
	local _sProd := fBuscaCpo ("SB5", 1, xfilial ("SB5") + GDFieldGet ("ZR_PRODUTO"), "B5_VATPSIS")
	if _sProd != '24'  // Borra
		if empty (GDFieldGet ("ZR_ACTOTAL")) .or. empty (GDFieldGet ("ZR_DENSID"))
			u_help ("Campos '" + alltrim (RetTitle ("ZR_ACTOTAL")) + "' e '" + alltrim (RetTitle ("ZR_DENSID")) + "' devem ser informados para este tipo de produto.")
			_lRet = .F.
		endif
	endif
return _lRet



// --------------------------------------------------------------------------
//rotina de validação da tela para avisar quando há mais de 3 produtos informados
User Function VASZQTOK()
	Local	_bOk	:=	.t.
	Local	_nLinha
	Local	_nProds	:=	0

	//verifica se há itens excluídos, pois a rotina não permite
	For _nLinha := 1 To Len(aCols)
		If aCols[_nLinha, Len(aHeader) + 1]
			_bOk	:=	.f.
			MsgAlert( "Não é permitida a exclusão de itens neste cadastro, favor refaça a operação!" )
			Exit
		Endif
	Next

	//busca o número de itens informados
	If _bOk
		For _nLinha := 1 To Len(aCols)
			If !aCols[_nLinha, Len(aHeader) + 1]
				_nProds++
			Endif
		Next
		If _nProds > 3
			_bOk	:=	MsgNoYes( "A T E N Ç Ã O! A Impressão da Guia permite apenas 3 itens. Deseja continuar ???" )
		Endif
	Endif

	// Verifica UF do cliente X tipo de operacao.
	if m->zq_tpoper == '01'
		if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->zq_cliente + m->zq_loja, "A1_EST") == 'RS'
			msgalert ("Para venda dentro do estado deve ser usado movimento de 'Venda interna'.")
			_bOk = .F.
		endif
	endif
	if m->zq_tpoper == '02'
		if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->zq_cliente + m->zq_loja, "A1_EST") != 'RS'
			msgalert ("Para venda fora do estado deve ser usado movimento de 'Venda'.")
			_bOk = .F.
		endif
	endif
Return _bOk



// --------------------------------------------------------------------------
User Function VA_NOMSZQ()
	local _nome := ""
	local _cod	:= ""
	local _loja := ""
	local _tpnf := ""

	dbselectarea("SF2")
	dbsetorder(1)
	dbseek(SZQ->ZQ_FILIAL + SZQ->ZQ_NF01 + SZQ->ZQ_SERIE01)
	if found()
		_cod  := alltrim(SF2->F2_CLIENTE)
		_loja := alltrim(SF2->F2_LOJA)
		_tpnf := alltrim(SF2->F2_TIPO)
	endif

	if !empty(_cod) .and. !empty(_loja) .and. !empty(_tpnf)
		if _tpnf == 'N'
			dbselectarea("SA1")
			dbsetorder(1)
			dbseek(xFilial("SA1") + _cod + _loja)
			if found()
				_nome := alltrim(SA1->A1_NOME)
			endif
		else
			dbselectarea("SA2")
			dbsetorder(1)
			dbseek(xFilial("SA2") + _cod + _loja)
			if found()
				_nome := alltrim(SA2->A2_NOME)
			endif
		endif
	endif
return _nome
