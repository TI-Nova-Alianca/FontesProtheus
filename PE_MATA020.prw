// Programa:  CUSTOMERVENDOR
// Autor:     Andre Alves
// Data:      06/05/2019
// Descricao: Ponto entrada na tela cadastro de Fornecedores.
//           
//
// Historico de alteracoes:

#include "protheus.ch"
#include "parmtype.ch"

user Function CUSTOMERVENDOR()
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
            nOper := oObj:nOperation
        	if nOper == 4
        		_GeraLog ()
        	endif
            _xRet := MA020TDOK ()
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


//----------------------------------------------------------------------------- 
static function _GeraLog ()
	local _oEvento  := NIL

//	 Grava log de evento em case de alteracao de cadastro.
	if altera
		_oEvento := ClsEvent():new ()
		_oEvento:AltCadast ("SA2", m->a2_cod + m->a2_loja, sa2 -> (recno ()))
	endif
return

//-----------------------------------------------------------------------------
Static Function MA020TDOK ()
	Local _aArea    := GetArea()
	Local _aAreaSA2 := SA2->(GetArea())
	Local _xFim     := chr(13)+chr(10)
	Local _lRet     := .T.
	Local _xCOD     := M->A2_COD
	Local _xLOJA    := M->A2_LOJA
	Local _xNOME    := M->A2_NOME
	Local _xEST     := M->A2_EST
	Local _xTIPO    := M->A2_TIPO
	Local _xCGC     := M->A2_CGC
	//Local _xInscr   := M->A2_INSCR
	Local _nInd     := 0

	// Consiste Estado com Tipo do Fornecedor (Critica Importacao)
	If _lRet
		If ( _xEST == "EX" .And. _xTIPO <> "X" ) .Or. ( _xEST <> "EX" .And. _xTIPO == "X" )
			MsgInfo("Fornecedor: "+Trim(_xCOD)+"/"+Trim(_xLOJA)+" - "+_xNOME+_xFim+;
			"Verifique o campo ESTADO e o Campo TIPO pois existe incoerencia."+_xFim;
			,"Atencao !!!  Incoerencia entre o Campo ESTADO e TIPO.")
			_lRet := .F.
		Endif
	Endif
	
	// Consiste !Importacao X Preenchimento do CNPJ / CPF
	If _lRet
//		If X3Obrigat( "A2_CGC" ) .And. Empty( _xCGC )
			If  ( _xEST <> "EX" .And. _xTIPO <> "X" ) .And. Empty(_xCGC)
				MsgInfo("Fornecedor: "+Trim(_xCOD)+"/"+Trim(_xLOJA)+" - "+_xNOME+_xFim+;
				"Verifique o campo CNPJ / CPF. O mesmo deve estar Preenchido."+_xFim;
				,"Atencao !!!  Obrigatorio CNPJ / CPF.")
				_lRet := .F.
			Endif
			If  ( _xEST <> "EX" .And. _xTIPO <> "X" ) .And. _xCGC == "00000000000000"
				MsgInfo("Fornecedor: "+Trim(_xCOD)+"/"+Trim(_xLOJA)+" - "+_xNOME+_xFim+;
				"Verifique o campo CNPJ / CPF. O mesmo deve estar Preenchido."+_xFim;
				,"Atencao !!!  Nao preencher CNPJ / CPF com zero.")
				_lRet := .F.
			Endif
//		Endif
	Endif

			
	//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
	//� Verifico se todos os caracteres do Codigo sao numeros                    �
	//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
	If _lRet
		For _nInd := 1 To Len(_xCOD)
			_cChar := Substr(_xCOD,_nInd,1)
			If IsAlpha(_cChar)
				MsgInfo("O Codigo so permite Campos Numericos."+_xFim;
				,"Atencao !!!  Codigo Invalido.")
				_lRet := .F.
				Exit
			Endif
		Next
	Endif
	
	// Consistencias para associados.
	if (empty (m->a2_vaCBase) .and. ! empty (m->a2_vaLBase)) .or. (!empty (m->a2_vaCBase) .and. empty (m->a2_vaLBase))
		u_help ("Os campos '" + alltrim (RetTitle ("A2_VACBASE")) + "' e '" + alltrim (RetTitle ("A2_VALBASE")) + "' devem ser ambos informados ou deixados em branco.")
		_lRet = .F.
	endif
	
	RestArea(_aAreaSA2)
	RestArea(_aArea)
	
Return(_lRet)

                              
