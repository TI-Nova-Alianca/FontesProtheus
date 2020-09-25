////////////////////////////////////////////////////////////////////////////////////////
// Rotina para manutenção de previsões de venda
// Autor: Bruno SIlva
// 09/07/2014 
////////////////////////////////////////////////////////////////////////////////////////
//
// 11/04/2019 - Andre  - Feito tratamento para campo virtual C4_DESCRI
   
#include "protheus.ch"
#include "tbiconn.ch"
//------------------------- Rotina principal
User Function VA_PRVVND()
Private cCadastro := "Previsao de Venda"
Private aRotina := {}
	AADD( aRotina, {"Pesquisar"  ,"AxPesqui" ,0,1})
	AADD( aRotina, {"Visualizar" ,'U_PVMnt'  ,0,2})
	AADD( aRotina, {"Incluir"    ,'U_PVInc'  ,0,3})
	AADD( aRotina, {"Alterar"    ,'U_PVMnt'  ,0,4})
	AADD( aRotina, {"Excluir"    ,'U_PVMnt'  ,0,5})
	dbSelectArea("SC4")
	dbSetOrder(3)
	dbGoTop()
	MBrowse(,,,,"SC4")
Return

//------------------------- Rotina de inclusão
User Function PVInc( cAlias, nReg, nOpc )
Local oDlg
Local oGet
Local oTPanel1
Local oTPAnel2
Local cDoc := Space(9)// SC4->C4_DOC
//Local cNome := Space(9)//NOME
//Local dData := dDataBase
Private aHeader := {}
Private aCOLS := {}
Private aREG := {}
	dbSelectArea( cAlias )
	dbSetOrder(3)
	PVaHeader( cAlias )
	PVaCOLS( cAlias, nReg, nOpc )
	DEFINE MSDIALOG oDlg TITLE cCadastro From 8,0 To 40,130 OF oMainWnd
	oTPanel1 := TPanel():New(0,0,"",oDlg,NIL,.T.,.F.,NIL,NIL,0,16,.T.,.F.)
	oTPanel1:Align := CONTROL_ALIGN_TOP
	@ 4, 062 SAY "Docto:" SIZE 70,7 PIXEL OF oTPanel1
	//@ 4, 062 SAY "Nome:" SIZE 70,7 PIXEL OF oTPanel1
	//@ 4, 166 SAY "Emissao:" SIZE 70,7 PIXEL OF oTPanel1
	@ 3, 080 MSGET cDoc PICTURE "@!" SIZE 050,7 PIXEL OF oTPanel1
	//@ 3, 080 MSGET cNome When .F. SIZE 78,7 PIXEL OF oTPanel1
	//@ 3, 192 MSGET dData PICTURE "99/99/99" SIZE 40,7 PIXEL OF oTPanel1
	oTPanel2 := TPanel():New(0,0,"",oDlg,NIL,.T.,.F.,NIL,NIL,0,16,.T.,.F.)
	oTPanel2:Align := CONTROL_ALIGN_BOTTOM
	
	aAlter:={"C4_PRODUTO","C4_LOCAL","C4_OBS","C4_VALOR","C4_QUANT","C4_DATA"}
	oGet := MSGetDados():New(0,0,0,0,nOpc,"U_PVLOk()",".T.","+C4_ITEM",.T.,aAlter)
	
	oGet:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	ACTIVATE MSDIALOG oDlg CENTER ON INIT;
	EnchoiceBar(oDlg,{|| IIF(U_PVTOk(cDoc), IIf(PVGrvI(cDoc),oDlg:End(),),( oDlg:End(), NIL ) )},{|| oDlg:End() })
	
Return

//------------------------- Rotina de Visualização, Alteração e Exclusão
User Function PVMnt( cAlias, nReg, nOpc )
Local oDlg
Local oGet
Local oTPanel1
Local oTPAnel2
Local cDoc := Space(Len(SC4->C4_DOC))
//Local cNome := Space(Len(SC4->C4_DOC))
//Local dData := Ctod(Space(8))
Private aHeader := {}
Private aCOLS := {}
Private aREG := {}
	dbSelectArea( cAlias )
	dbGoTo( nReg )
	cDoc := SC4->C4_DOC
	//cNome := ZA3->ZA3_NOME
	//cData := ZA3->ZA3_DATA
	PVaHeader( cAlias )
	PVaCOLS( cAlias, nReg, nOpc )
	DEFINE MSDIALOG oDlg TITLE cCadastro From 8,0 To 40,130 OF oMainWnd
	oTPanel1 := TPanel():New(0,0,"",oDlg,NIL,.T.,.F.,NIL,NIL,0,16,.T.,.F.)
	oTPanel1:Align := CONTROL_ALIGN_TOP
	@ 4, 062 SAY "Docto:" SIZE 70,7 PIXEL OF oTPanel1
	//@ 4, 062 SAY "Nome:" SIZE 70,7 PIXEL OF oTPanel1
	//@ 4, 166 SAY "Emissao:" SIZE 70,7 PIXEL OF oTPanel1
	@ 3, 080 MSGET cDoc When .F. SIZE 50,7 PIXEL OF oTPanel1
	//@ 3, 080 MSGET cNome When .F. SIZE 78,7 PIXEL OF oTPanel1
	//@ 3, 192 MSGET dData When .F. SIZE 40,7 PIXEL OF oTPanel1
	oTPanel2 := TPanel():New(0,0,"",oDlg,NIL,.T.,.F.,NIL,NIL,0,16,.T.,.F.)
	oTPanel2:Align := CONTROL_ALIGN_BOTTOM
	
	If nOpc == 4
		
		aAlter:={"C4_PRODUTO","C4_LOCAL","C4_OBS","C4_VALOR","C4_QUANT","C4_DATA"}
		oGet := MSGetDados():New(0,0,0,0,nOpc,"U_PVLOk()",".T.","+C4_ITEM",.T.,aAlter,,, )
		//MSGetDados():oBrowse:nFreeze     := 1
	Else
		oGet := MSGetDados():New(0,0,0,0,nOpc)
	Endif
	oGet:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	ACTIVATE MSDIALOG oDlg CENTER ON INIT ;
	EnchoiceBar(oDlg,{|| ( IIF(U_PVTOk(cDoc), IIF( nOpc==4, IIf(PVGrvA(cDoc),oDlg:End(),),IIF( nOpc==5, IIf(PVGrvE(cDoc),oDlg:End(),), oDlg:End() )  ),Nil ), ) },{|| oDlg:End() })
	//IIf(PVGrvA(),oDlg:End(),)
Return

//------------------------- Montagem do array aHeader
Static Function PVaHeader( cAlias )
Local aArea := GetArea()
dbSelectArea("SX3")
dbSetOrder(1)
dbSeek( cAlias )
While !EOF() .And. X3_ARQUIVO == cAlias
	If X3Uso(X3_USADO) .And. cNivel >= X3_NIVEL
		If X3_CAMPO <> 'C4_DOC'
			If X3_CAMPO = 'C4_QUANT' .OR. X3_CAMPO = 'C4_VALOR'
				AADD( aHeader, { Trim( X3Titulo() ),;
				X3_CAMPO,;
				X3_PICTURE,;
				X3_TAMANHO,;
				X3_DECIMAL,;
				"",;
				X3_USADO,;
				X3_TIPO,;
				X3_ARQUIVO,;
				X3_CONTEXT})
			else
				AADD( aHeader, { Trim( X3Titulo() ),;
				X3_CAMPO,;
				X3_PICTURE,;
				X3_TAMANHO,;
				X3_DECIMAL,;
				X3_VALID,;
				X3_USADO,;
				X3_TIPO,;
				X3_ARQUIVO,;
				X3_CONTEXT})
			Endif				
		Endif
	Endif
	
dbSkip()
End
RestArea(aArea)
Return

//------------------------- Montagem do array aCols
Static Function PVaCOLS( cAlias, nReg, nOpc )
Local aArea := GetArea()
Local cChave := SC4->C4_DOC
Local nI := 0
If nOpc <> 3
	dbSelectArea( cAlias )
	dbSetOrder(3)
	dbSeek( xFilial( cAlias ) + cChave )
	While !EOF() .And. SC4->( C4_FILIAL + C4_DOC ) == xFilial( cAlias ) + cChave
		AADD( aREG, SC4->( RecNo() ) )
		AADD( aCOLS, Array( Len( aHeader ) + 1 ) )
		For nI := 1 To Len( aHeader )
			If aHeader[nI,10] == "V"
				aCOLS[Len(aCOLS),nI] := CriaVar(aHeader[nI,2],.T.)
			Else
				aCOLS[Len(aCOLS),nI] := FieldGet(FieldPos(aHeader[nI,2]))
			Endif
		Next nI
		aCOLS[Len(aCOLS),Len(aHeader)+1] := .F.
		dbSkip()
	End
Else
	AADD( aCOLS, Array( Len( aHeader ) + 1 ) )
	For nI := 1 To Len( aHeader )
		aCOLS[1, nI] := CriaVar( aHeader[nI, 2], .T. )
	Next nI
	If Len(aCOLS) > 0 
		aCOLS[1, GdFieldPos("C4_ITEM")] := "01"
		aCOLS[1, Len( aHeader )+1 ] := .F.
	EndIf 
Endif
Restarea( aArea )
Return

//------------------ Efetivação da inclusão
Static Function PVGrvI(_cDoc)
Local aArea := GetArea()
Local nI := 0
Local nX := 0

Local aDados := {}
PRIVATE lMsErroAuto := .F.
PRIVATE lAutoErrNoFile := .T.

// EXECAUTO INCLUSAO
For nI := 1 To Len( aCOLS )
	If ! aCOLS[nI,Len(aHeader)+1]
		aDados := {}
		aadd(aDados,{"C4_ITEM",   aCOLS[nI, 1],Nil})
		aadd(aDados,{"C4_PRODUTO",aCOLS[nI, 2],Nil})
		aadd(aDados,{"C4_LOCAL",  aCOLS[nI, 3],Nil})
		aadd(aDados,{"C4_DOC" ,          _cDoc,Nil})
		aadd(aDados,{"C4_QUANT",  aCOLS[nI, 5],Nil})
		aadd(aDados,{"C4_VALOR",  aCOLS[nI, 6],Nil})
		aadd(aDados,{"C4_DATA",   aCOLS[nI, 7],Nil})
		aadd(aDados,{"C4_OBS" ,   aCOLS[nI, 8],Nil})
		MATA700(aDados,3)
		If !lMsErroAuto
			//MsgInfo("Inclusao com sucesso! ",cCadastro)
		Else
			aErro := GetAutoGRLog()
			cErro := ""
			For nX := 1 To Len(aErro)
				cErro += aErro[nX] + Chr(13)+Chr(10)
			Next nX
			Alert( cErro )
		EndIf
	Endif
Next nI
RestArea(aArea)
Return .t.

//------------------ Efetivação da alteração, exclusao
Static Function PVGrvA(_cDoc)
Local aArea := GetArea()
Local nI := 0
Local nX := 0

Local aDados := {}
PRIVATE lMsErroAuto := .F.
PRIVATE lAutoErrNoFile := .T.

// EXECAUTO ALTERACAO
For nI := 1 To Len( aCOLS ) 
		
	If GDDeleted(nI)
		///Validação para saber se o regitro exite na tabela antes de excluir
		dbSelectArea("SC4")
		dbSetOrder(3)
		dbSeek( xFilial("SC4") + _cDoc + aCOLS[nI, GdFieldPos("C4_ITEM")] ) //+ aCOLS[nI, 2] + Dtos(aCOLS[nI, 6]) )
		If Found()		
			if Reclock("SC4", .F.)
				dbDelete() // deleta	
				//MSGALert(_cDoc + " - "+ aCOLS[nI, GdFieldPos("C4_ITEM")] + " foi deletado.")
				msunlock()
			Endif			  
		Endif 
				 	   	   		
	Else		
		dbSelectArea("SC4")
		dbSetOrder(3)
		dbSeek( xFilial("SC4") + _cDoc + aCOLS[nI, GdFieldPos("C4_ITEM")] )		
		If !Found()
			//Incluir
			dbSelectArea("SC4")
			if Reclock("SC4", .T.)
				SC4->C4_FILIAL  := xFilial('SC4')
				SC4->C4_ITEM    := aCOLS[nI, GdFieldPos("C4_ITEM")]
				SC4->C4_PRODUTO := aCOLS[nI, GdFieldPos("C4_PRODUTO")]
				SC4->C4_LOCAL   := aCOLS[nI, GdFieldPos("C4_LOCAL")]
				SC4->C4_DOC     := _cDoc
				SC4->C4_QUANT     := aCOLS[nI, GdFieldPos("C4_QUANT")]
				SC4->C4_VALOR     := aCOLS[nI, GdFieldPos("C4_VALOR")]
				SC4->C4_DATA     := aCOLS[nI, GdFieldPos("C4_DATA")]
				SC4->C4_OBS     := aCOLS[nI, GdFieldPos("C4_OBS")]
																							
				//MSGALert(_cDoc + " - "+ aCOLS[nI, GdFieldPos("C4_ITEM")] + " foi incuído.")		
				MsUnlock()
			EndIf			 	
		Else
			//Alterar	
			dbSelectArea("SC4")
			If Reclock("SC4", .F.)			
				//Verifica se ouve alteração no produto
				If SC4->C4_PRODUTO <> aCOLS[nI, GdFieldPos("C4_PRODUTO")]
					MSGALert("Não é possível alterar do campo produto no item "+ aCOLS[nI, GdFieldPos("C4_ITEM")]+". Delete a linha e crie outra.",cCadastro)
				EndIf			
				SC4->C4_QUANT     := aCOLS[nI, GdFieldPos("C4_QUANT")]									
				SC4->C4_VALOR     := aCOLS[nI, GdFieldPos("C4_VALOR")]
				SC4->C4_DATA     := aCOLS[nI, GdFieldPos("C4_DATA")]
				SC4->C4_OBS     := aCOLS[nI, GdFieldPos("C4_OBS")]
				//MSGALert(_cDoc + " - "+ aCOLS[nI, GdFieldPos("C4_ITEM")] + " foi alterado.")		
				MsUnlock()
			EndIf		 	
		EndIf	
	EndIf			
Next nI

RestArea(aArea)

Return .t.

//------------------ Efetivação da exclusão
Static Function PVGrvE(_cDoc)
Local aArea := GetArea()
Local nI := 0
Local nX := 0

Local aDados := {}
PRIVATE lMsErroAuto := .F.
PRIVATE lAutoErrNoFile := .T.

If !MsgYesNo("Tem certeza que deseja confirmar a exclusao?", cCadastro)
	Return .t.
Endif

// EXECAUTO EXCLUSAO
For nI := 1 To Len( aCOLS )
	If ! aCOLS[nI,Len(aHeader)+1]
		aDados := {}		
		aadd(aDados,{"C4_ITEM",   aCOLS[nI, 1],Nil})
		aadd(aDados,{"C4_PRODUTO",aCOLS[nI, 2],Nil})
		aadd(aDados,{"C4_LOCAL",  aCOLS[nI, 3],Nil})
		aadd(aDados,{"C4_DOC" ,          _cDoc,Nil})
		aadd(aDados,{"C4_QUANT",  aCOLS[nI, 5],Nil})
		aadd(aDados,{"C4_VALOR",  aCOLS[nI, 6],Nil})
		aadd(aDados,{"C4_DATA",   aCOLS[nI, 7],Nil})
		aadd(aDados,{"C4_OBS" ,   aCOLS[nI, 8],Nil})
		//alert("excluindo: "+_cDoc)
		MATA700(aDados,5)
		If !lMsErroAuto
			//MsgInfo("Alterado com sucesso! ",cCadastro)
		Else
			aErro := GetAutoGRLog()
			cErro := ""
			For nX := 1 To Len(aErro)
				cErro += aErro[nX] + Chr(13)+Chr(10)
			Next nX
			Alert( cErro )
		EndIf	
	Endif
Next nI
RestArea(aArea)

Return .t.


//------------------ Rotina para validar a linha de dados.

User Function PVLOk()
Local lRet := .T.
Local cMensagem := "Preencher campos obrigatórios."
If !aCOLS[n, Len(aHeader)+1]
	If Empty(aCOLS[n,GdFieldPos("C4_PRODUTO")]) .OR. Empty(aCOLS[n,GdFieldPos("C4_LOCAL")]) .OR. Empty(aCOLS[n,GdFieldPos("C4_DATA")]) .OR. ;
		Empty(aCOLS[n,GdFieldPos("C4_QUANT")])
		MsgAlert(cMensagem,cCadastro)
		lRet := .F.
	Endif
	//aCOLS[n,GdFieldPos("C4_DOC")] := _cDoc
Endif
Return( lRet )


//------------------ Rotina para validar TODAS AS linha
User Function PVTOk(_cDoc)
Local lRet 		:= .T.
Local nI 		:= 0
Local cMensagem := "Faltam informações a serem preenchidas, revise as linhas digitadas."
Local cDoc		:= ""
Local cProd 	:= ""
Local nCont 	:= 0
Local _nN		:= 0

If Empty(_cDoc)
	MsgAlert("Preencha o campo Docto.")
	Return .F.
Endif

For nI := 1 To Len( aCOLS )
	If aCOLS[nI, Len(aHeader)+1]
		Loop
	Endif
	If !aCOLS[nI, Len(aHeader)+1]
		If Empty(aCOLS[n,GdFieldPos("C4_PRODUTO")]) .OR. Empty(aCOLS[n,GdFieldPos("C4_LOCAL")]) .OR. Empty(aCOLS[n,GdFieldPos("C4_DATA")]) .OR. ;
			Empty(aCOLS[n,GdFieldPos("C4_QUANT")])  
			MsgAlert(cMensagem,cCadastro)
			lRet := .F.
			Exit
		Endif	
		
		//Rotina para verificar se não existe itens duplicado (mesmo Prod, Doc e Data)		
		cDoc  := _cDoc
		cProd := aCOLS[nI,GdFieldPos("C4_PRODUTO")]
		dData := aCOLS[nI,GdFieldPos("C4_DATA")]
		nCont := 0	
		For _nN := 1 To Len( aCOLS )			
			If !aCOLS[_nN, Len(aHeader)+1]
				If aCOLS[_nN,GdFieldPos("C4_PRODUTO")] = cProd .AND. aCOLS[_nN,GdFieldPos("C4_DATA")] = dData
					nCont ++
					if nCont > 1 .and. lRet
						MsgAlert("Já existe um registro do Documento "+alltrim(cDoc)+" Produto: "+alltrim(cProd)+" para Data de "+DToc(dData)+".",cCadastro)
						lRet := .F.
						Exit
					EndIf
				EndIf	
			EndIf			
		Next _nN
				
	Endif
Next nI
Return( lRet )

