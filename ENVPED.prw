// Programa...: ENVPED
// Autor......: DWT
// Data.......: 17/06/2011 
// Descricao..: Envia pedido de compras por e-mail na procura
//
// Historico de alteracoes:
// 18/06/2016 - Robert  - Envia mensagem de nova razao social durante algum tempo.
// 13/04/2018 - Julio   - Incluido o processamento da lista de anexos cadastrados no NAWeb.
// 05/09/2018 - Andre   - Atualiza flag de 'e-mail enviado' no pedido de compra.
// 25/03/2019 - Andre   - Alterada rotina de envio de e-mail.
// 17/09/2021 - Sandra  - Alteração função  pswret e sEmailR fixado no programa e-mail compras@novaalianca.coop.br
//

#INCLUDE "dialog.ch"
#include 'fivewin.ch'
#include 'topconn.ch'
#INCLUDE "rwmake.ch"
#include "set.ch"
#include "ap5mail.ch"
#Include "protheus.ch"
#include "rwmake.ch"        

// --------------------------------------------------------------------------
User Function ENVPED(caminho) 
	local _lContinua  := .T.
	private _lCancel  := .F.

	_oDlg       := NIL

	_sEMailD   	:= Posicione("SA2",1,xfilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA,"A2_EMAIL") + Space(100)
	//_sEMailR	:= pswret()[1,14] + Space(100)
	_sEMailR	:= 'compras@novaalianca.coop.br'
	_sEMailD2	:= Posicione("SA2",1,xfilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA,"A2_VAMAIL2") + Space(100)
	_lEnviaR	:= .F.
	_lSalva		:= .F.
	caminho    	:= caminho

	do while .T.
		define msdialog _oDlg from 0, 0 to 180, 500 Title "Confirmação de e-mails !" pixel
		@ 10,  5 Say "Remetente:"
		@ 25,  5 Say "Destinatario:"
		@ 40,  5 Say "Com copia:"
		@ 60,  5 Say "Receber copia ?"
		@ 70,  5 Say "Salvar e-mail fornecedor ?"
		@ 10, 60 Get _sEMailR  SIZE 180,11 object _oGet1
		@ 25, 60 Get _sEMailD  SIZE 180,11 object _oGet2
		@ 40, 60 Get _sEMailD2 SIZE 180,11 object _oGet3
		@ 60, 80 CHECKBOX oCheckBox1 VAR _lEnviaR PROMPT "" SIZE 021, 010 OF _oDlg COLORS 0, 16777215 PIXEL
		@ 70, 80 CHECKBOX oCheckBox2 VAR _lSalva  PROMPT "" SIZE 021, 010 OF _oDlg COLORS 0, 16777215 PIXEL
		@ _oDlg:nClientHeight / 2 - 30, _oDlg:nClientWidth / 2 - 100 BMPBUTTON TYPE 1 ACTION (U_envmail(caminho))
		@ _oDlg:nClientHeight / 2 - 30, _oDlg:nClientWidth / 2 - 50  BMPBUTTON TYPE 2 ACTION (_lCancel := .T., Close(_odlg))
		activate dialog _oDlg centered on init (_oGet2:SetFocus ())  // Para que o foco caia no segundo get.
		
		if _lCancel
			//ConOut ("Usuario cancelou tela de confirmacao de enderecos de e-mail.")
			_lContinua = .F.
			exit
		endif
		
		if alltrim (_sEMailD) == alltrim (_sEMailD2)
			msgalert ("Destinatarios nao devem ser iguais.")
			loop
		endif
		
		if empty (_sEMailD) .or. empty (_sEMailR)
			msgalert ("Remetente e destinatario devem ser informados.")
			loop
		endif
		
		exit
	enddo
return
// --------------------------------------------------------------------------
// Envia e-mail
user Function envmail(caminho)
	local _oSQL   	:= NIL
	local _aProds 	:= {}
	local _nProds 	:= 0
	local _aProd  	:= {}
	local _aRet 	:= {}
	local _sSQL 	:= ""
	local _nRet 	:= 0
	
	caminho := alltrim(caminho)
	Close(_oDlg)
	
	if _lSalva
 		dbselectarea("SA2")
 		dbsetorder(1)
 		dbseek(xFilial("SA2")+SC7->C7_FORNECE + SC7->C7_LOJA)
 		if found()
 			reclock("SA2", .F.)
 			Replace SA2->A2_EMAIL With alltrim(_sEMailD)
 			Replace SA2->A2_VAMAIL2 With alltrim(_sEMailD2)
 			msunlock()
 		endif
 		dbselectarea("SA2")
 		dbclosearea()
 	endif
 	
	_sSQL := ""
	_sSQL += " SELECT DISTINCT C7_PRODUTO"
	_sSQL += " FROM " + RetSQLName("SC7")
	_sSQL += " WHERE D_E_L_E_T_ = '' AND "
	_sSQL += " C7_FILIAL = '" + xFilial('SC7') + "' AND "
	_sSQL += " C7_NUM = '" + AllTrim(SC7->C7_NUM) + "'"

	_oSQL := ClsSQl():New ()
	_oSQL:_sQuery := _sSQL
	
	// se nao existir a pasta cria e add ao _cPathPDF
	cDestino := "\pedidos\"
	makedir (cDestino)
	_cPathPDF := "C:\temp\pedidos\"
	
	_cFile := "ped_com_" + AllTrim(SC7->C7_NUM) //nome do arquivo padrão, deve ser alterado para não sobrescrever
    
	_aProds = _oSQL:Qry2Array()
	
	for _nProds = 1 to len (_aProds)
		aadd(_aProd, AllTrim(_aProds[_nProds,1]))
	next

	_aRet := U_GAnexos(_aProd)
	
	cDocument := ""
	For _nRet = 1 to len (_aRet)
		cDocument := cDocument + _aRet[_nRet]
		if _nRet < len (_aRet)
			cDocument := cDocument + ", "
		endif
	Next
	
 	_cNomFor	:= Posicione("SA2",1,xFilial("SA2")+SC7->C7_FORNECE + SC7->C7_LOJA,"A2_NOME")
 	cBody		:= alltrim(_cNomFor) + " !" + chr(13) + chr(10)
 	cBody		+= chr(13) + chr(10)
	cBody 		+= 'Segue em anexo o arquivo PDF do pedido de compra ' + alltrim(SC7->C7_NUM) + " !" + chr(13) + chr(10)  //+ CHR(13)+CHR(10)

	// Envia mensagem de nova razao social durante algum tempo.
	if date () <= stod ('20160730')
		cBody += chr(13) + chr(10) + chr(13) + chr(10)
		cBody += "***  A T E N C A O  ***" + chr(13) + chr(10) + chr(13) + chr(10)
		cBody += "Nova razao social: " + sm0 -> m0_nomecom + chr(13) + chr(10)
	endif

	//cFrom       := alltrim(_sEMailR)
	cFrom       := alltrim("compras@novaalianca.coop.br")
	cServer     := AllTrim(GetNewPar("MV_RELSERV"," ")) 	                                                                                                                                                                                                                                        
	cAccount    := AllTrim(GetNewPar("MV_RELACNT"," ")) 	//Space(50)   //wf     /
	cPassword   := AllTrim(GetNewPar("MV_RELPSW" ," "))  	//Space(50)   //workflow   //654321
	nTimeOut    := GetMv("MV_RELTIME",,120)				 	//Tempo de Espera antes de abortar a Conexão
	lAutentica  := GetMv("MV_RELAUTH",,.F.) 				//Determina se o Servidor de Email necessita de Autenticação
	cUserAut    := Alltrim(GetMv("MV_RELAUSR",,cAccount)) 	//Usuário para Autenticação no Servidor de Email                                                                                                                                                                                                                                                  
	cPassAut    := Alltrim(GetMv("MV_RELAPSW",,cPassword)) 	//Senha para Autenticação no Servidor de Email   //workflow      //654321
	cTo         := alltrim(_sEMailD) //alltrim(_cEmailDe)//endereço de e-mail a ser enviado
	cCC         := alltrim(_sEMailD2)
	
	u_logdh (SC7 -> C7_NUM + "Iniciando envio")
	if _lEnviaR
		//cCO		:= alltrim(_sEMailR)
		  cCO		:= alltrim("compras@novaalianca.coop.br")
	else
		cCO		:= ''
	endif
	
	_cDest = (_sEMailD)
	if ! empty (_sEMailD2)
		_cDest += (_sEMailD) + ";"
		_cDest += (_sEMailD2)
	endif
	
	cSubject    := 'Nova Aliança - pedido de compra ' + alltrim(SC7->C7_NUM)
	cDocument   := cDocument + ", " + caminho
	x			:=1           
	
	PswOrder(1)
	PswSeek(__CUSERID,.T.)
	
	cTo := AvLeGrupoEMail(cTo)
	cCC := AvLeGrupoEMail(cCC)
	cCO := AvLeGrupoEMail(cCO)
	
	// gera o arquivo em PDF
	CpyT2S(_cPathPDF +_cFile+ ".PDF", cDestino)
		
	// envio
	U_SendMail (_cDest, cSubject, "", {cDestino + _cFile + ".PDF"})
		
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " UPDATE " + RetSQLName ("SC7") 
	_oSQL:_sQuery += "   SET C7_EMAIL = 'S' "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND C7_FILIAL = '" + xFilial('SC7') + "'"
	_oSQL:_sQuery += " AND C7_NUM = '" + AllTrim(SC7->C7_NUM) + "'"
	_oSQL:Log()
	_oSQL:Exec ()
Return
