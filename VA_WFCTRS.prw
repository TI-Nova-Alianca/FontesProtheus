#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "ap5mail.ch"

// Programa:  VA_WFCTRS
// Autor:     Robert Koch
// Data:      25/10/2013
// Cliente:   Alianca
// Descricao: Workflow para envio de e-mail para controles como:
//					- recebimento de nota fiscal pela filial 14
//					- aprovação de pedido de compra pela gerência
//					- retorno de e-mail liberando batch
//			  Tipos (0=Nota Fiscal, 1=Pedido Compra, 2=Retorno, 3=Time Out )
//
// Historico de alteracoes:
//

User Function VA_WFCTRS(_cTipo, _cNum, _cSerie ,_cBatch, _cForMail)
	local _aAreaAnt  := U_ML_SRArea ()
	Private _cUser   	:= "000001"
	Private _sNum 		:= _cNum
	Private _sForMail   := _cForMail
	Private _sSerie   	:= _cSerie
	Private _sBatch   	:= _cBatch

	if ! empty (_cForMail)
		U_EXECWFAL(_cTipo)
	endif
	U_ML_SRArea (_aAreaAnt)
Return

// --------------------------------------------------------------------------
// Função para tratar das etapas do workflow
User Function EXECWFAL(nOpcao, oProcess)

If nOpcao == NIL
	nOpcao := 0
Endif

If oProcess == NIL
	oProcess := TWFProcess():New( "000001", "Workflow de controles" )
Endif

Do Case
	Case nOpcao == 0
		WfNfFil(oProcess) 	// Nota Fiscal
	Case nOpcao == 1
		//WfPedC(oProcess) 	// Pedido de Compra
	Case nOpcao == 2
		WfRet(oProcess)		// Retorno
	Case nOpcao == 3
		WfTO(oProcess)		// TimeOut
EndCase
               
oProcess:Free()

return


// ----------------------------------------------------------------------------------------------
// Função para iniciar o processo de workflow preenchendo o html e enviando o e-mail para o destinatário
Static Function WfNfFil(oProcess)

//Local cSubject
Local _nTot := 0
Local _dEmissao           
Local _lPrim := .T.
local _xTit := ""
Local _xCliForn := ""
Local _xCond := ""
U_LOGiNI ()
If oProcess == NIL
	oProcess := TWFProcess():New( "000001", "Workflow de controles" )
Endif

oProcess:NewTask( "Confirmacao de recebimento de Nota Fiscal", "\fontes\VA_WFCTRS.htm" )
oProcess:bReturn := "U_EXECWFAL(2)"
oProcess:bTimeOut := {{"U_EXECWFAL(3)",30, 0 , 0 }} // Timeout em 24 horas
oProcess:cSubject := "Confirmacao de recebimento da Nota Fiscal " + alltrim(_sSerie) + "-" + alltrim(_sNum)
oHTML := oProcess:oHTML

DbSelectArea("SD2")                                            
DbSetOrder(3)
If DbSeek(xfilial("SD2") + _sNum + _sSerie)
	Do While !EoF() .and. xfilial("SD2") + _sNum + _sSerie == SD2->D2_FILIAL+SD2->D2_DOC+SD2->D2_SERIE
		
		_dEmissao 	:= SD2->D2_EMISSAO
		_cCliFor	:= SD2->D2_CLIENTE
		_cLoja 		:= SD2->D2_LOJA
		_cCond 	  	:= Posicione("SF2",1,xFilial("SF2") + _sNum + _sSerie,"F2_COND")
		_nTot 		+= SD2->D2_TOTAL 
		
		if _lPrim
			_lPrim := .F.
			_xTit := "Confirmacao de recebimento da Nota Fiscal " + alltrim(_sSerie) + "-" + alltrim(_sNum)
			_xCliForn := _cCliFor +"-"+_cLoja+" / "+FBuscaCpo("SA1",1,xFilial("SA1")+_cCliFor+_cLoja,"A1_NOME")
			_xCond := _cCond+" - "+FBuscaCPO("SE4",1,xFilial("SE4")+_cCond,"E4_DESCRI")
			_xFrete := ""
			
			_ccaminho := "logo2.bmp"
			oHtml:ValByName( "ende_logo", _ccaminho )
			oHtml:ValByName( "tit", _xtit )
			oHtml:ValByName( "emi", _dEmissao )
			//oHtml:ValByName( "usu", UsrFullName(_cUser) )
			oHtml:ValByName( "forn", alltrim(_xCliForn))
			//oHtml:ValByName( "cond",  _xCond)
			//oHtml:ValByName( "frete",  _xFrete)
			//oHtml:ValByName( "prazo",  STOD("") )
			//oHtml:ValByName( "user",  _cUser)
			//oHtml:ValByName( "supe",  "")//Alterado para poder controlar a liberacao de documentos
			//oHtml:ValByName( "nivel", "01")
		endif
		
		AAdd( (oHtml:ValByName( "t1.1" )),SD2->D2_ITEM )
		AAdd( (oHtml:ValByName( "t1.2" )),SD2->D2_COD )
		AAdd( (oHtml:ValByName( "t1.3" )),Posicione("SB1",1,xFilial("SB1") + SD2->D2_COD,"B1_DESC"))
		AAdd( (oHtml:ValByName( "t1.4" )),SD2->D2_UM )
		AAdd( (oHtml:ValByName( "t1.5" )),TRANSFORM( SD2->D2_QUANT,'@E 999,999,999.9999' ))
		//AAdd( (oHtml:ValByName( "t1.6" )),TRANSFORM( SD2->D2_PRCVEN,'@E 999,999,999.9999' ))
		//AAdd( (oHtml:ValByName( "t1.7" )),TRANSFORM( SD2->D2_TOTAL,'@E 999,999,999.99' ))
		//AAdd( (oHtml:ValByName( "t1.8" )),TRANSFORM( 0,'@E 999,999,999.99' ))
		//AAdd( (oHtml:ValByName( "t1.9" )),TRANSFORM( 0,'@E 999,999,999.99' ))
		//AAdd( (oHtml:ValByName( "t1.10" )),TRANSFORM( 0,'@E 999,999,999.99' ))
		//AAdd( (oHtml:ValByName( "t1.11" )),TRANSFORM( 0,'@E 999,999,999.99' ))
		//AAdd( (oHtml:ValByName( "t1.12" )),"" )
		//AAdd( (oHtml:ValByName( "t1.13" )),"" )
		//AAdd( (oHtml:ValByName( "t1.14" )),"")
		
		DbSelectArea("SD2")
		DbSkip()
	enddo
endif

//AAdd( (oHtml:ValByName( "t2.1" )),TRANSFORM( _nTot,'@E 999,999,999.99' ))
//oHtml:ValByName( "NUM", _sNum )

//oProcess:ClientName( Subs(cUsuario,7,15))
oProcess:ClientName(cUserName)
oProcess:cTo := _sForMail
//oProcess:oWF:cMailBox = "ROBERT.KOCH"
//oProcess:UserSiga := __CUSERID //passa Id do processo para rastreabilidade
oProcess:Start()
oProcess:Free()
u_logFim ()
Return


// ----------------------------------------------------------------------------------------------
// Função para executar o retorno no Workflow
Static Function WfRet(oProcess)

//Local _cNumRet  := 	oProcess:oHtml:RetByName('NUM')
Local _xLibera  := 	oProcess:oHtml:RetByName('LIBERA')
//Local _cMotivob := 	oProcess:oHtml:RetByName('MOTIVOB')

If _xLibera == "Sim"
	// campo de "esperando WF" no agendamento do ZZ6 fica como .F.
	// ZZ6 _cNumRet
else
	// _cMotivob
endif

Return
   

// ----------------------------------------------------------------------------------------------
// Função para timeout
Static Function WfTO( oProcess )
oProcess:Finish()  //Finaliza o Processo                    
Return
