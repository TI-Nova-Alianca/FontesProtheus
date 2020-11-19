// Programa:  ATFA012
// Autor:     Andre Alves
// Data:      23/08/2019
// Descricao: Ponto entrada na tela cadastro de Ativos Fixos.
//           
//
// Historico de alteracoes:
// 24/10/2019 - Robert - Nao valida centros de custo quando chamado a partir da NF de entrada - GLPI 6596.
//

#include "protheus.ch"
#include "parmtype.ch"

user Function ATFA012()
    Local aParam := PARAMIXB
    Local _xRet := .T.
    Local oObj := ""
    Local cIdPonto := ""
    Local cIdModel := ""
    Local lIsGrid := .F.
   // Local nLinha := 0
   // Local nQtdLinhas := 0
   // Local cMsg := ""

    If aParam <> NIL
        oObj := aParam[1]
        cIdPonto := aParam[2]
        cIdModel := aParam[3]
        lIsGrid := (Len(aParam) > 3)
        
        If cIdPonto == "MODELPOS"
        	_xRet := _AF010TOK ()
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

// --------------------------------------------------------------------------
Static Function _AF010TOK()
	Local _lRet     := .T.
	Local _aAreaAnt := U_ML_SRArea()
	Local oObj := paramixb [1]
	Local _nLinha := 0
	Private oModelN3 := oObj:GetModel("SN3DETAIL")
	Private N := oModelN3:NLine
	Private aCols := aClone(oModelN3:aCOLS)
	Private aHeader := aClone(oModelN3:aHeader)
	Static lJahPassou := .F.
	
	if ! lJahPassou
		if ! IsInCallStack ("MATA103")  // Este P.E. eh chamado tb na NF de entrada de aquisicao de imobilizado, mas a NF nao preenche todos os CC.
			For _nLinha = 1 TO LEN (aCols)
				if GDFIELDGET('N3_CUSTBEM',_nLinha) != GDFIELDGET ('N3_CCUSTO',_nLinha)
					msgAlert("Campo 'N3_CUSTBEM' deve ser igual ao campo 'N3_CCUSTO'.")
					_lRet := .F.
					exit
				endif
				if GDFIELDGET('N3_CUSTBEM',_nLinha) != GDFIELDGET ('N3_CCDESP',_nLinha)
					msgAlert("Campo 'N3_CUSTBEM' deve ser igual ao campo 'N3_CCDESP'.")
					_lRet := .F.
					exit
				endif
				if GDFIELDGET('N3_CUSTBEM',_nLinha) != GDFIELDGET ('N3_CCCDEP',_nLinha)
					msgAlert("Campo 'N3_CUSTBEM' deve ser igual ao campo 'N3_CCCDEP'.")
					_lRet := .F.
					exit
				endif
				if GDFIELDGET('N3_CUSTBEM',_nLinha) != GDFIELDGET ('N3_CCCDES',_nLinha)
					msgAlert("Campo 'N3_CUSTBEM' deve ser igual ao campo 'N3_CCCDES'.")
					_lRet := .F.
					exit
				endif
				if GDFIELDGET('N3_CUSTBEM',_nLinha) != GDFIELDGET ('N3_CCCORR',_nLinha)
					msgAlert("Campo 'N3_CUSTBEM' deve ser igual ao campo 'N3_CCCORR'.")
					_lRet := .F.
					exit
				endif
			next
		endif
		_lJahPassou := .T.
	endif
	
	if _lRet = .T.
		_lRet = U_RepMaq ()
	endif
	
	U_ML_SRArea(_aAreaAnt)
return _lRet
