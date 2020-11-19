// Programa:   AF060TOK
// Autor:      Andre Alves
// Data:       22/08/2019
// Descricao:  Criado ponto de entrada AF060TOK que valida os dados inseridos antes 
//             da gravação na rotina Transferência de Ativos (ATFA060).
// 
// Historico de alteracoes:
// 
// --------------------------------------------------------------------------

#include "rwmake.ch" 
#Include "PROTHEUS.CH" 
#include "parmtype.ch"

user Function ATFA060()
    Local aParam := PARAMIXB
    Local _xRet := .T.
    Local oObj := ""
    Local cIdPonto := ""
    Local cIdModel := ""
    Local lIsGrid := .F.
    //Local nLinha := 0
    //Local nQtdLinhas := 0
    //Local cMsg := ""

    If aParam <> NIL
        oObj := aParam[1]
        cIdPonto := aParam[2]
        cIdModel := aParam[3]
        lIsGrid := (Len(aParam) > 3)
        
        If cIdPonto == "MODELPOS"
        	_xRet := _AF060TOK ()
        ElseIf cIdPonto == "FORMPOS"
        	_xRet := NIL
        ElseIf cIdPonto == "FORMLINEPRE"
        	_xRet := .T.
        ElseIf cIdPonto == "FORMLINEPOS"
        	_xRet := .T.
        ElseIf cIdPonto == "MODELCOMMITTTS"
        	_xRet = NIL
        ElseIf cIdPonto == "MODELCOMMITNTTS"
        	_xRet = NIL
        ElseIf cIdPonto == "FORMCOMMITTTSPRE"
        	_xRet = NIL
        ElseIf cIdPonto == "FORMCOMMITTTSPOS"
            _xRet = NIL
        ElseIf cIdPonto == "MODELCANCEL"
        	_xRet := .T.
        ElseIf cIdPonto == "BUTTONBAR"
            _xRet := {}
        EndIf
    EndIf
    
Return _xRet

//---------------------------------------------------------------------------
Static function _AF060TOK() 
Local aArea := GetArea() 
Local lRet := .T. 
//Local nZ := 0 

//Informações passadas por parametro 
//Private cFilDest := ParamIXB[1] 
//Private cFilOrig := ParamIXB[2] 
//Private aTitFolder := ParamIXB[3] 
//Private aVar := ParamIXB[4] 
//Private aCpDigit := ParamIXB[5] 
//Private dDataTrans := ParamIXB[6] 

	if ! substr (M->FN9_FILDES,1,2) = substr (M->FN9_CCDESD,1,2)
	 	msgAlert ("O CAMPO DE FILIAL DE DESTINO DEVE SER O MESMO DO CENTRO DE CUSTO.")
	 	lRet := .F.
	endif
	
	if ! (M->FN9_CCDESD) = (M->FN9_CCBEMD);
		.or. ! (M->FN9_CCDESD) = (M->FN9_CCCORD);
		.or. ! (M->FN9_CCDESD) = (M->FN9_CCDDD);
		.or. ! (M->FN9_CCDESD) = (M->FN9_CCDAD);
		.or. ! (M->FN9_CCDESD) = (M->FN9_CCCDD)
		msgAlert ("OS CAMPOS DA ABA 'CENTRO DE CUSTO' DEVEM SER IGUAIS AO CENTRO DE CUSTO DE DESTINO.")
		lRet := .F.	
	endif

RestArea(aArea) 

Return lRet
