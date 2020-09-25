// Programa...: ML_SZM
// Autor......: Fábio André Michelon
// Data.......: 09/10/2006
// Descricao..: Cadastro de lançamentos de fluxo de caixa de fornecedor
//
// Historico de alteracoes:
// 07/11/2008 - Robert  - Incluida campo ZM_HIST
//                      - Passa a gerer para mais de um fornecedor por vez.
//                      - Exclusao de titulos anteriores via SQL.
// 01/12/2008 - Robert  - Revisao geral processo de geracao dos titulos PR.
//                      - Criado tratamento para o campo E2_VAFLUXO.
// 22/02/2010 - Robert  - Incluido dbselectarea antes de chamar rot. automatica.
// 05/06/2010 - Robert  - Perguntas ajustadas para versao 10
// 24/02/2011 - Robert  - Incrementa prefixo em vez de parcela ao gerar SE2.
// 18/09/2012 - Elaine  - Trata E2_NUM para 9 posicoes
// 04/09/2017 - Catia   - alterar o nro maximo de linhas de 99 para 999
// 08/04/2019 - Catia   - include TbiConn.ch 
// 06/03/2020 - Claudia - Ajustada a leitura do SX3 conforme solicitação da R25
// 07/07/2020 - Robert  - Dava DBSKIP no SZM em vez do SX3 e causada estouro de memoria.
//

// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

User Function ML_SZM()
	Private cCadastro := " Fluxo de caixa de fornecedor"
	Private cDelFunc  := ".T."
	Private cString   := "SZM"
	Private aRotina   := { 	{"Pesquisar","AxPesqui"		,0,1} ,;
							{"Visualizar","u_ML_SZMV()"	,0,2} ,;
							{"Incluir","u_ML_SZMX()"	,0,3} ,;
							{"Alterar","u_ML_SZMX()"	,0,4} ,;
							{"Excluir","u_ML_SZMX()"	,0,5} ,;
							{"Gerar Fluxo","u_ML_SZMG()",0,6} }
	
	
	dbSelectArea("SZM")
	dbSetOrder(1)
	dbSelectArea(cString)
	
	mBrowse( 6,1,22,75,cString)
Return
// --------------------------------------------------------------------------
// Incluir/Alterar/Excluir
User Function ML_SZMX()
	local _nCampo 	:= 0
	local _ni		:= 0
	local x			:= 1
	local l			:= 1
	local i         := 0
	
	If Inclui
		nOpcx := 3    // Inclusao
	Elseif Altera
		nOpcx := 4    // Alteracao
	Else
		nOpcx := 5    // Exclusao
	EndIf
	
	// Montando aHeader                                             
//	DbSelectArea("SX3")
//	DbSetOrder(1)
//	DbSeek("SZM")
//	nUsado  := 0
//	aHeader := {}
//	Do While !Eof() .And. (X3_ARQUIVO == "SZM")
//		If X3USO(X3_USADO) .And. cNivel >= X3_NIVEL
//			If (Alltrim(X3_CAMPO)=="ZM_FILIAL") .or. (Alltrim(X3_CAMPO)=="ZM_FORNECE") .or. ;
//				(Alltrim(X3_CAMPO)=="ZM_LOJA") .or. (Alltrim(X3_CAMPO)=="ZM_NOME")
//				DbSkip()
//				Loop
//			Endif
//			nUsado:=nUsado+1
//			AADD(aHeader,{TRIM(X3_TITULO),X3_CAMPO,X3_PICTURE,X3_TAMANHO,X3_DECIMAL,"",X3_USADO,X3_TIPO,X3_ARQUIVO,X3_CONTEXT})
//		Endif
//		DbSkip()
//	Enddo
	
	// Montando aHeader   
//	u_log2 ('debug', 'SZM posicionado em: ' + szm->zm_filial+SZM->ZM_FORNECE+SZM->ZM_LOJA)
//	u_log2 ('debug', alias())
	nUsado   := 0
	aHeader  := {}
	_aCpoSX3 := FwSX3Util():GetAllFields('SZM')
	
	For i:=1 To Len(_aCpoSX3)
	    If(X3Uso(GetSx3Cache(_aCpoSX3[i], 'X3_USADO')) .And. cNivel >= GetSx3Cache(_aCpoSX3[i], 'X3_NIVEL'))
	    	If (alltrim(GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO')) == 'ZM_FILIAL') .or.  (alltrim(GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO')) == 'ZM_FORNECE') .or. ;
	    		(alltrim(GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO')) == 'ZM_LOJA') .or. (alltrim(GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO')) == 'ZM_NOME')
	    		
	    		sx3 -> (DbSkip())
	    		Loop
	    	EndIf
	    	nUsado:=nUsado+1
	    	
	    	aadd(aHeader,{  GetSx3Cache(_aCpoSX3[i], 'X3_TITULO' ),;
	    					GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO'  ),;
	    					GetSx3Cache(_aCpoSX3[i], 'X3_PICTURE'),;
	    					GetSx3Cache(_aCpoSX3[i], 'X3_TAMANHO'),;
	    					GetSx3Cache(_aCpoSX3[i], 'X3_DECIMAL'),;
	    					""									  ,;
	    					GetSx3Cache(_aCpoSX3[i], 'X3_USADO'  ),;
	    					GetSx3Cache(_aCpoSX3[i], 'X3_TIPO'   ),;
	    					GetSx3Cache(_aCpoSX3[i], 'X3_ARQUIVO'),;
	    					GetSx3Cache(_aCpoSX3[i], 'X3_CONTEXT')})
	    Endif
	Next i

	// Montando aCols                                               
//	u_log2 ('debug', 'SZM posicionado em: ' + szm->zm_filial+SZM->ZM_FORNECE+SZM->ZM_LOJA)
//	u_log2 ('debug', alias())
	If nOpcx == 3     // Inclusao
		aCols := {array (len (aHeader) + 1)}
		For _nCampo = 1 to len (aHeader)
			If AllTrim(aHeader [_nCampo, 2]) == "ZM_ITEM"
				aCols [1, _nCampo] := "0000"
			Elseif AllTrim(aHeader [_nCampo, 2]) == "ZM_EMISSAO"
				aCols [1, _nCampo] := DDATABASE
			Elseif AllTrim(aHeader [_nCampo, 2]) == "ZM_VENCTO"
				aCols [1, _nCampo] := CTOD(" / / ")
			Elseif AllTrim(aHeader [_nCampo, 2]) == "ZM_VALOR"
				aCols [1, _nCampo] := 0.00
			Elseif AllTrim(aHeader [_nCampo, 2]) == "ZM_HIST"
				aCols [1, _nCampo] := CriaVar ("ZM_HIST")
			Else
				aCols [1, _nCampo] := CriaVar (aHeader [_nCampo, 2])
			Endif
		Next
		aCols [1, len (aCols [1])] := .F.  // Linha nao deletada
		y:=Len(acols)
	Else         // Alteracao
		aCols:={}
		DbSelectArea("SZM")
//		u_log2 ('debug', 'SZM posicionado em: ' + szm->zm_filial+SZM->ZM_FORNECE+SZM->ZM_LOJA)
//		u_log2 ('debug', alias())
		xChv := (xFilial("SZM")+SZM->ZM_FORNECE+SZM->ZM_LOJA)
//		u_log2 ('debug', 'chave: >>' + xChv + '<<')
		DbSetOrder(1)
		DbSeek(xChv)
		
		Do While (xChv == xFilial("SZM")+SZM->ZM_FORNECE+SZM->ZM_LOJA)
			AADD(aCols,Array(nUsado+1))
			For _ni:=1 to nUsado
				aCols[Len(aCols),_ni]:=FieldGet(FieldPos(aHeader[_ni,2]))
			Next
			aCols[Len(aCols),nUsado+1]:=.F.
//			u_log ('debug', 'qt.linhas no aCols: ' + cvaltochar (len (aCols)))
			DbSkip()
		Enddo
		
		y:=Len(aCols)
		DbSeek(xChv)
	Endif
	
	_nPosItem   := Ascan(aHeader,{|xCpo| Alltrim(xCpo[2]) == "ZM_ITEM"})
	_nPosEmis   := Ascan(aHeader,{|xCpo| Alltrim(xCpo[2]) == "ZM_EMISSAO"})
	_nPosVenc   := Ascan(aHeader,{|xCpo| Alltrim(xCpo[2]) == "ZM_VENCTO"})
	_nPosValor	:= Ascan(aHeader,{|xCpo| Alltrim(xCpo[2]) == "ZM_VALOR"})
	_nPosHist	:= Ascan(aHeader,{|xCpo| Alltrim(xCpo[2]) == "ZM_HIST"})
	
	// Variaveis do Cabecalho do Modelo 2                           
	If nOpcx == 3     // Inclusao
		_cFornece	:= Space(6)
		_cLoja 		:= Space(2)
		_cNome		:= Space(40)
	Else              // Alteracao
		DbSelectArea("SZM")
		dbSetOrder(1)
		_cFornece	:= SZM->ZM_FORNECE
		_cLoja 		:= SZM->ZM_LOJA
		_cNome		:= FBUSCACPO("SA2",1,XFILIAL("SA2")+SZM->ZM_FORNECE+SZM->ZM_LOJA,"A2_NOME")
	Endif

	// Titulo da Janela                                             
	cTitulo :="Lancamentos de Fluxo de Caixa de Fornecedor"
	
	// Array com descricao dos campos do Cabecalho do Modelo 2      
	aC:={}
	AADD(aC,{"_cFornece",	{018,001},	"Fornecedor",	"@!",	'ExistCpo("SA2")',	"SA2",	IIF(nOpcx==3,.T.,.F.)})
	AADD(aC,{"_cLoja",		{018,070},	"",				"@!",	'ExistCpo("SA2",_cFornece+_cLoja,1) .and. EXISTCHAV("SZM",_cFornece+_cLoja,1)',	,	IIF(nOpcx==3,.T.,.F.)})
	AADD(aC,{"_cNome"  ,	{018,120},	"Nome",			"@S40",	,	,	.F.})
	aR:={}
	
	// Array com coordenadas da GetDados no modelo2                 
	aCGD   := {055,2,175,393}
	aCordw := {115,2,516,800}
	
	// Validacoes na GetDados da Modelo 2                           
	cTudoOk  := "AllwaysTrue()"
	cLinhaOk := "AllwaysTrue()"
	
	// Chamada da Modelo2                                           
//	u_log2 ('debug', 'chamando Modelo2')
	lRetMod2 := Modelo2(cTitulo,aC,aR,aCGD,nOpcx,cLinhaOk,cTudoOk,,,,999,aCordw)
	
	If lRetMod2 .And. (nOpcx == 3 .Or. nOpcx == 4)  // Incluiu,Alterou e Confirmou
		DbSelectArea("SZM")
		dbSetOrder(1)
		For x:=1 to Len(aCols)
			RecLock("SZM",IIF(nOpcx==3 .Or. x>y,.T.,.F.))
			SZM->ZM_FILIAL  := 	xFilial("SZM")
			SZM->ZM_FORNECE	:= 	_cFornece
			SZM->ZM_LOJA 	:= 	_cLoja
			SZM->ZM_ITEM	:= 	aCols[x][_nPosItem]
			SZM->ZM_EMISSAO	:=	aCols[x][_nPosEmis]
			SZM->ZM_VENCTO	:=	aCols[x][_nPosVenc]
			SZM->ZM_VALOR	:=	aCols[x][_nPosValor]
			SZM->ZM_HIST	:=	aCols[x][_nPosHist]
			If aCols[x][Len(aHeader)+1]
				DbDelete()
			Endif
			MsUnlock()
			DbSkip()
		Next
	Elseif lRetMod2 .And. nOpcx == 5      // Excluiu e Confirmou
		DbSelectArea("SZM")
		DbSetOrder(1)
		For l:=1 To Len(aCols)
			If DbSeek(xFilial("SZM")+_cFornece+_cLoja)
				RecLock("SZM",.F.)
				DbDelete()
				MsUnLock()
			Endif
		Next
	Endif
	
	SysRefresh()
Return(.T.)
// --------------------------------------------------------------------------
// Visualizar
User Function ML_SZMV()
	local _ni	:= 1
	local i     := 1
	
	// Montando aHeader                                             
//	DbSelectArea("SX3")
//	DbSetOrder(1)
//	DbSeek("SZM")
//	nUsado  := 0
//	aHeader := {}
//	
//	Do While !Eof() .And. (X3_ARQUIVO == "SZM")
//		If X3USO(X3_USADO) .And. cNivel >= X3_NIVEL
//			If (Alltrim(X3_CAMPO)<>"ZM_FILIAL") .and. (Alltrim(X3_CAMPO)<>"ZM_FORNECE") .and. ;
//				(Alltrim(X3_CAMPO)<>"ZM_LOJA") .and. (Alltrim(X3_CAMPO)<>"ZM_NOME")
//				nUsado:=nUsado+1
//				AADD(aHeader,{TRIM(X3_TITULO),X3_CAMPO,X3_PICTURE,X3_TAMANHO,X3_DECIMAL,"",X3_USADO,X3_TIPO,X3_ARQUIVO,X3_CONTEXT})
//			Endif
//		Endif
//		DbSkip()
//	Enddo

	// Montando aHeader  
	nUsado   := 0
	aHeader  := {}
	_aCpoSX3 := FwSX3Util():GetAllFields('SZM')
	
	For i:=1 To Len(_aCpoSX3)
	    If(X3Uso(GetSx3Cache(_aCpoSX3[i], 'X3_USADO')) .And. cNivel >= GetSx3Cache(_aCpoSX3[i], 'X3_NIVEL'))
	    	If (alltrim(GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO')) == 'ZM_FILIAL') .or.  (alltrim(GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO')) == 'ZM_FORNECE') .or. ;
	    		(alltrim(GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO')) == 'ZM_LOJA') .or. (alltrim(GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO')) == 'ZM_NOME')
	    		
	    		DbSkip()
	    		Loop
	    	EndIf
	    	nUsado:=nUsado+1
	    	
	    	aadd(aHeader,{  GetSx3Cache(_aCpoSX3[i], 'X3_TITULO' ),;
	    					GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO'  ),;
	    					GetSx3Cache(_aCpoSX3[i], 'X3_PICTURE'),;
	    					GetSx3Cache(_aCpoSX3[i], 'X3_TAMANHO'),;
	    					GetSx3Cache(_aCpoSX3[i], 'X3_DECIMAL'),;
	    					""									  ,;
	    					GetSx3Cache(_aCpoSX3[i], 'X3_USADO'  ),;
	    					GetSx3Cache(_aCpoSX3[i], 'X3_TIPO'   ),;
	    					GetSx3Cache(_aCpoSX3[i], 'X3_ARQUIVO'),;
	    					GetSx3Cache(_aCpoSX3[i], 'X3_CONTEXT')})
	    Endif
	Next i
	
	// Montando aCols                                               
	aCols:={}
	DbSelectArea("SZM")
	xChv := (xFilial("SZM")+SZM->ZM_FORNECE+SZM->ZM_LOJA)
	DbSetOrder(1)
	DbSeek(xChv)
	
	Do While (xChv == xFilial("SZM")+SZM->ZM_FORNECE+SZM->ZM_LOJA)
		AADD(aCols,Array(nUsado+1))
		For _ni:=1 to nUsado
			aCols[Len(aCols),_ni]:=FieldGet(FieldPos(aHeader[_ni,2]))
		Next
		aCols[Len(aCols),nUsado+1]:=.F.
		DbSkip()
	Enddo
	
	y:=Len(aCols)
	DbSeek(xChv)
	
	// Variaveis do Cabecalho do Modelo 2                           
	DbSelectArea("SZM")
	dbSetOrder(1)
	_cFornece	:= SZM->ZM_FORNECE
	_cLoja 			:= SZM->ZM_LOJA
	_cNome			:= FBUSCACPO("SA2",1,XFILIAL("SA2")+SZM->ZM_FORNECE+SZM->ZM_LOJA,"A2_NOME")
	
	// Titulo da Janela                                             
	cTitulo :="Lancamentos de Fluxo de Caixa de Fornecedor"
	
	// Array com descricao dos campos do Cabecalho do Modelo 2      
	aC:={}
	// aC[n,1] = Nome da Variavel Ex.:"cCliente"
	// aC[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
	// aC[n,3] = Titulo do Campo
	// aC[n,4] = Picture
	// aC[n,5] = Validacao
	// aC[n,6] = F3
	// aC[n,7] = Se campo e' editavel .t. se nao .f.
	
	AADD(aC,{"_cFornece",	{018,001},	"Fornecedor",	"@!",	,	,	.F.})
	AADD(aC,{"_cLoja",		{018,070},	"Loja",			"@!",	,	,	.F.})
	AADD(aC,{"_cNome"  ,	{018,120},	"Nome",			"@S37",	,	,	.F.})
	
	// Array com descricao dos campos do Rodape do Modelo 2         
	aR:={}
	// aR[n,1] = Nome da Variavel Ex.:"cCliente"
	// aR[n,2] = Array com coordenadas do Get [x,y], em Windows estao em PIXEL
	// aR[n,3] = Titulo do Campo
	// aR[n,4] = Picture
	// aR[n,5] = Validacao
	// aR[n,6] = F3
	// aR[n,7] = Se campo e' editavel .t. se nao .f.
	//AADD(aR,{"cNome" ,{185,005} ,"Modelo"     ,"@!"           ,,.F.,.F.})
	
	// Array com coordenadas da GetDados no modelo2                 
	aCGD   := {055,2,175,393}
	aCordw := {115,2,516,800}
	
	// Validacoes na GetDados da Modelo 2                           
	cTudoOk  := "AllwaysTrue()"
	cLinhaOk := "AllwaysTrue()"
	
	// Chamada da Modelo2                                           
	lRetMod2 := Modelo2(cTitulo,aC,aR,aCGD,2,cLinhaOk,cTudoOk,,,,99,aCordw)
	
	SysRefresh()
Return(.T.)
// --------------------------------------------------------------------------
// Gerar Fluxo
User Function ML_SZMG()
	Local	_cPerg	:=	"ML_SZM"
	_ValidPerg( _cPerg )
	U_GravaSX1 (_cPerg, "03", SZM->ZM_FORNECE)
	U_GravaSX1 (_cPerg, "04", SZM->ZM_LOJA)
	U_GravaSX1 (_cPerg, "05", SZM->ZM_FORNECE)
	U_GravaSX1 (_cPerg, "06", SZM->ZM_LOJA)
	
	If Pergunte( _cPerg, .t. )
		Processa({|| _GerarFlx(mv_par01, mv_par02, mv_par03, mv_par04, mv_par05, mv_par06)}, "Processando ...")
	Endif
Return
// --------------------------------------------------------------------------
// Gerar Fluxo
Static Function _GerarFlx( _dDtIni, _dDtFin, _cFornece, _cLoja,_cFornecef, _cLojaf )
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _aGrvSe2	:=	{}
	local _sPrefixo := ""
	local _aInclu   := {}
	local _nTotincl := 0
	local _sSQL     := ""
	local _lContinua:= .t.
	local _aFornece := {}
	local _nFornece := 0

//	u_log2 ('info', 'Iniciando geracao de fluxo')
//	u_logSX1 ("ML_SZM")

	// Monta lista dos fornecedores a gerar
	if _lContinua
		_sQuery := ""                                                                                            
		_sQuery += " select distinct ZM_FORNECE, ZM_LOJA"
		_sQuery += " from " + RetSQLName ("SZM") + " SZM "
		_sQuery += " where SZM.D_E_L_E_T_ != '*'"
		_sQuery += "   and SZM.ZM_FILIAL   = '" + xfilial ("SZM") + "'"
		_sQuery += "   and SZM.ZM_FORNECE + SZM.ZM_LOJA between '" + _cFornece + _cLoja + "' and '" + _cFornecef + _cLojaf + "'"
		_sQuery += "   and SZM.ZM_VENCTO between '" + dtos (_dDtIni) + "' and '" + dtos (_dDtFin) + "'"
//		u_log2 ('debug', _sQuery)
		_aFornece = aclone (U_Qry2Array (_sQuery))
	
		if len (_aFornece) == 0
			u_help ("Nao foram encontrados dados para geracao de previsoes.",, .t.)
			_lContinua = .F.
		endif
	endif

	// Geracao fornecedor a fornecedor.
	if _lContinua
		procregua (len (_aFornece))
		for _nFornece = 1 to len (_aFornece)
			IncProc("Gerando forn. " + _aFornece [_nFornece, 1])
	
			// Deleta provisorios anteriores deste fornecedor.
			if _lContinua
				_sSQL := ""
				_sSQL += " update " + RetSQLName ("SE2")
				_sSQL +=    " set D_E_L_E_T_  = '*', R_E_C_D_E_L_ = R_E_C_N_O_"
				_sSQL +=  " where D_E_L_E_T_ != '*'"
				_sSQL +=    " and E2_FILIAL   = '" + xfilial ("SE2") + "'"
				_sSQL +=    " and E2_TIPO     = 'PR'"
				_sSQL +=    " and E2_VAFLUXO  = 'S'"
				_sSQL +=    " and E2_ORIGEM   = 'FINA050'"
				_sSQL +=    " and E2_FORNECE  = '" + _aFornece [_nFornece, 1] + "'"
				_sSQL +=    " and E2_LOJA     = '" + _aFornece [_nFornece, 2] + "'"
				_sSQL +=    " and E2_VENCTO between '" + dtos (_dDtIni) + "' and '" + dtos (_dDtFin) + "'"
//				u_log2 ('debug', _sSQL)

				if TCSQLExec (_sSQL) < 0
					u_help ("Erro na exclusao dos titulos provisorios anteriores. Processo cancelado.",, .t.)
					_lContinua = .F.
				endif
			endif

			if _lContinua
				// Gera os provisorios com mesmo numero, apenas alterando o prefixo.
				_sParcela = "1"
				szm -> (DbSetOrder(3))  // ZM_FILIAL+ZM_FORNECE+ZM_LOJA+DTOS(ZM_VENCTO)
				szm -> (DbSeek( xFilial( "SZM" ) + _aFornece [_nFornece, 1] + _aFornece [_nFornece, 2] + dtos(_dDtIni), .t. ))
				do While _lContinua ;
					.and. !szm -> (Eof()) ;
					.and. SZM->ZM_FILIAL  == xFilial( "SZM" ) ;
					.and. SZM->ZM_FORNECE == _aFornece [_nFornece, 1] ;
					.and. SZM->ZM_LOJA    == _aFornece [_nFornece, 2] ;
					.and. SZM->ZM_VENCTO  <= _dDtFin

					// Monta query para encontrar o maior prefixo jah existente para este fornecedor.
					_sQryPref := ""                                                                                            
					_sQryPref += " select IsNull (max (E2_PREFIXO), '001')"
					_sQryPref += " from " + RetSQLName ("SE2") + " SE2 "
					_sQryPref += " where SE2.D_E_L_E_T_ != '*'"
					_sQryPref +=    " and SE2.E2_FILIAL   = '" + xfilial ("SE2") + "'"
					_sQryPref +=    " and SE2.E2_FORNECE  = '" + _aFornece [_nFornece, 1] + "'"
					_sQryPref +=    " and SE2.E2_LOJA     = '" + _aFornece [_nFornece, 2] + "'"
					_sQryPref +=    " and SE2.E2_TIPO     = 'PR'"
					_sQryPref +=    " and SE2.E2_NUM      = '" + replicate ("9", tamsx3 ("E2_NUM")[1]) + "'"
//					u_log2 ('debug', _sQryPref)

					_sPrefixo = soma1 (U_RetSQL (_sQryPref))

					_aGrvSe2 := {;
					{ "E2_PREFIXO"  , _sPrefixo				, NIL},;
					{ "E2_NUM"		, "999999999"			, Nil },;
					{ "E2_TIPO"		, "PR"					, Nil },;
					{ "E2_FORNECE"	, szm -> zm_fornece		, Nil },;
					{ "E2_LOJA"   	, szm -> zm_loja		, Nil },;
					{ "E2_EMISSAO"	, szm -> zm_emissao		, Nil },;
					{ "E2_VENCTO"	, szm -> zm_vencto		, Nil },;
					{ "E2_VALOR"  	, szm -> zm_valor		, Nil },;
					{ "E2_HIST"		, szm -> zm_hist		, Nil },;
					{ "E2_PARCELA"	, _sParcela 			, Nil },;
					{ "E2_VAFLUXO"	, "S"					, Nil },;
					{ "E2_ORIGEM" 	, "FINA050"   			, Nil };
					}
					_aGrvSe2 := aclone (U_OrdAuto (_aGrvSe2))

//					u_log2 ('info', 'Gerando prefixo ' + _sPrefixo)
					lMsErroAuto	:=	.f.
					dbselectarea ("SE2")
					dbsetorder (1)
					
					MsExecAuto({ | x,y,z | Fina050(x,y,z) }, _aGrvSe2,, 3)
					
					If lMsErroAuto
						if ! empty (NomeAutoLog ())
							u_help (U_LeErro (memoread (NomeAutoLog ())),, .t.)
						else
							MostraErro()
						endif
						_lContinua = .F.
					else
						aadd (_aInclu, {se2 -> e2_prefixo + " / " + se2 -> e2_num + " - " + se2 -> e2_parcela, se2 -> e2_fornece + " - " +  se2 -> e2_nomfor, se2 -> e2_vencrea, transform (se2 -> e2_valor, "@E 999,999,999.99"), se2 -> e2_hist})
						_nTotIncl += se2 -> e2_valor
					Endif
					_sParcela = soma1 (_sParcela)
					szm -> (DbSkip())
				enddo
			endif
		next
	endif

	if len (_aInclu) == 0
		u_help ("Nenhum novo titulo gerado.")
	else
		u_F3Array (_aInclu, "Titulos gerados", NIL, NIL, NIL, "Titulos gerados:", "Valor total: " + transform (_nTotIncl, "@E 999,999,999.99"))
	endif
		
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
Return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg (cPerg)
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Vencimento de                 ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Vencimento ate                ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {03, "Fornecedor de                 ", "C", 6,  0,  "",   "SA2", {},    ""})
	aadd (_aRegsPerg, {04, "Loja fornecedor de            ", "C", 2,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {05, "Fornecedor ate                ", "C", 6,  0,  "",   "SA2", {},    ""})
	aadd (_aRegsPerg, {06, "Loja fornecedor ate           ", "C", 2,  0,  "",   "   ", {},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
