// Programa.: VA_IMPINV
// Autor....: Cl�udia Lion�o
// Data.....: 21/01/2023
// Descricao: Relat�rio de invent�rio
//
// Historico de alteracoes:
// 03/02/2023 - Claudia - Ajustada importa��o devido a culna "LINHA" GLPI: 13141
// 23/03/2023 - Claudia - Incluida coluna de unidade de medida. GLPI: 13334
//
// -------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_IMPINV()
	Local cCadastro := "Importa��o de invent�rio"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0    

    AADD(aSays,cCadastro)
    AADD(aSays,"")
    AADD(aSays,"")
    AADD(aButtons, { 1, .T.,{|| nOpca := If(_TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
    AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
    FormBatch( cCadastro, aSays, aButtons )

    If nOpca == 1
        Processa( { |lEnd| _Importa() } )
    Endif
return
//
// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
//
// --------------------------------------------------------------------------
// Importa arquivo
Static Function _Importa()
    Local cArq        := ""
	Local cMascara    := ".CSV|*.CSV"
	Local cTitulo     := "Importar arquivo"
	Local nMascpad    := 0
	Local cDirIni     := "C:\Temp\" //"\"
	Local lSalvar     := .T.
	Local nOpcoes     := GETF_LOCALHARD
	Local lArvore     := .F. /*.T. = apresenta o �rvore do servidor || .F. = n�o apresenta*/
    Local aDados      := {}
	Local _x          := 0

    cArq := cGetFile( cMascara, cTitulo, nMascpad, cDirIni, lSalvar, nOpcoes, lArvore)

	If !File(cArq)
		MsgStop("O arquivo '" + cArq + "' n�o foi encontrado. Importa��o n�o realizada!","ATENCAO")
		Return
	EndIf

	FT_FUSE(cArq)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()

	While !FT_FEOF()
		cLinha := alltrim(FT_FREADLN())
		AADD(aDados,Separa(cLinha,";",.T.))
		FT_FSKIP()		
	EndDo  
    
	// Atualiza tabela
	For _x:=2 to Len(aDados)	
		IncProc("Importando dados...")
	
		dbSelectArea("SB7")
		dbSetOrder(5) // B7_FILIAL+B7_DOC+B7_COD+B7_LOCAL+B7_LOCALIZ+B7_LOTECTL                                                                                                                                                                                                                                       
		dbGoTop()
		
		_sFilial := PADL(alltrim(aDados[_x,4]), 2, '0')
		_sProd   := PADR(alltrim(aDados[_x,6]),15, ' ')
		_sLocal  := PADL(alltrim(aDados[_x,5]), 2, '0')
		_sDoc    := PADR(alltrim(aDados[_x,2]), 9, ' ')
		_sEnder  := PADR(alltrim(aDados[_x,10]),15, ' ')
		_sLote   := PADR(alltrim(aDados[_x,11]),10, ' ')
		
		If dbSeek(_sFilial + _sDoc + _sProd + _sLocal + _sEnder + _sLote)
			Reclock("SB7",.F.)
				SB7->B7_VAQTD := Val(StrTran(aDados[_x,14],",","."))   
				SB7->B7_VAOBS := aDados[_x,15]
			SB7->(MsUnlock())
		Else
			u_help(" O produto: " + alltrim(_sProd) + " no local " + _sLocal + " no documento " + alltrim(_sDoc) + " n�o encontrado!" )
		EndIf
	Next
	u_help("Importa��o finalizada!")
return

