// Programa:  CUSTOMERVENDOR
// Autor:     Andre Alves
// Data:      06/05/2019
// Descricao: Ponto entrada na tela cadastro de Fornecedores.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada generico no cadastro de fornecedores.
// #PalavasChave      #ponto_entrada
// #TabelasPrincipais #SA2
// #Modulos           #COM #EST #COOP

// Historico de alteracoes:
// 15/07/2022 - Robert - Impede exclusao se tiver movimentacao na conta corrente de associados.
//

#include "protheus.ch"
#include "parmtype.ch"

// --------------------------------------------------------------------------
user Function CUSTOMERVENDOR()
	Local aParam := PARAMIXB
	Local _xRet := .T.
	Local oObj := ""
	Local cIdPonto := ""
	Local cIdModel := ""
	Local lIsGrid := .F.

	If aParam <> NIL
		oObj := aParam[1]
		cIdPonto := aParam[2]
		cIdModel := aParam[3]
		lIsGrid := (Len(aParam) > 3)
	//	U_Log2 ('debug', '[' + procname () + ']cIdPonto: ' + cIdPonto)
		
		If cIdPonto == "MODELPOS"
			nOper := oObj:nOperation
	//		U_Log2 ('debug', '[' + procname () + ']nOper: ' + cvaltochar (nOper))
			if _xRet .and. nOper == 5  // Exclusao
				_xRet = _PodeExcl ()
			endif
			if _xRet .and. nOper == 4  // Alteracao
				_GeraLog ()
			endif
			if _xRet
				_xRet := MA020TDOK ()
			endif
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


// --------------------------------------------------------------------------
static function _PodeExcl ()
	local _lRet := .T.

	szi -> (dbsetorder (1))  // ZI_FILIAL, ZI_ASSOC, ZI_LOJASSO, ZI_DATA, ZI_TM, R_E_C_N_O_, D_E_L_E_T_
	if szi -> (dbseek (xfilial ("SZI") + m->a2_cod + m->a2_loja, .T.))
		u_help ("Fornecedor tem movimentacao na conta corrente de associados. Exclusao nao permitida.",, .t.)
		_lRet = .F.
	endif
return _lRet
