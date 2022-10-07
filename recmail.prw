// Programa..: RECMAIL
// Autora....: Catia Cardoso
// Data......: 20/11/2018
// Funcao....: Recebe emails da conta fretesimport@novaalianca.coop.br
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch #processamento 
// #Descricao         #Recebe emails da conta fretesimport@novaalianca.coop.br
// #PalavasChave      #email #fretesimport
// #Modulos           #FAT 
//
// Historico de Alteracoes:
// 04/11/2019 - Robert  - Passa a ler tambem extensoes TXT pois vamos redirecionar a conta
//                        'edifretes' para cair junto com a 'fretesimport'
// 14/08/2020 - Cláudia - Ajuste de Api em loop, conforme solicitação da versao 25 protheus. GLPI: 7339
// 10/07/2022 - Robert  - Melhoria nos logs.
// 01/09/2022 - Robert  - Melhorias ClsAviso.
// 03/10/2022 - Robert  - Trocado grpTI por grupo 122 no envio de avisos.
//

// --------------------------------------------------------------------------
User Function RECMAIL(_lAuto)
	Local oMessage   := NIL
	Local oPopServer := NIL
	Local aAttInfo   := {}
	Local cPopServer := "srvmail.novaalianca.coop.br"
	Local cAccount   := "fretesimport@novaalianca.coop.br"
	Local cPwd       := "Alianca14"
	Local nPortPop   := 7110
	Local nMessages  := 0
	Local nMessage   := 0
	Local nAtach     := 0
	Local _cNome1    := ""
	Local _cNome4    := ""
	Local _cNomeArq  := ""
	Local _cExt      := ""
	Local _nPosIni   := 0
	Local _nPosFim   := 0
	Local _cRemet    := ""
	Local _cTam      := 0
	Local _cConta    := 0
	//local _oXml      := NIL
	//local _cError    := ""
	//local _cWarning  := ""
	local _nMaxMsg   := 100
	//local _sAvisos   := ""
	local _lRet      := .T.
	local _oAviso    := NIL

	procregua (10)

	oPopServer := TMailManager():New()
	oPopServer:Init(cPopServer , "srvmail.novaalianca.coop.br", cAccount, cPwd, nPortPop)
	
	if oPopServer:PopConnect() == 0
		//Conta quantas mensagens há no servidor
		oPopServer:GetNumMsgs(@nMessages)
		u_log2 ('info', '[' + procname () + "]Numero de mensagens no servidor: " + cvaltochar (nMessages) + ". Serao baixadas no maximo " + cvaltochar (_nMaxMsg) + " por vez.")

		// Verifica todas mensagens no servidor
		procregua (min (nMessages, _nMaxMsg))
		For nMessage := 1 To min (nMessages, _nMaxMsg)
			oMessage := TMailMessage():New()
			if oMessage:Receive( oPopServer, nMessage) == 0  // Se recebido com sucesso
				incproc (oMessage:cFrom)

				// Verifica todos anexos da mensagem e os salva
				u_log2 ('info', '[' + procname () + ']Msg ' + cvaltochar (nMessage) ;
					+ ' From: ' + alltrim (oMessage:cFrom) ;
					+ ' Subject: ' + oMessage:cSubject)
				
				For nAtach := 1 to oMessage:getAttachCount()
					_cNomeArq:= ""
					_cNome1  := ""
					_cNome4  := ""
					_cExt    := ""
					_cTam    := 0
					if _nPosIni > 0
						_cEnder := substr(_cRemet, (_nPosIni +1), (_nPosFim -(_nPosIni +1)))
					else
						_cEnder := _cRemet
					endif

					aAttInfo:= oMessage:getAttachInfo(nAtach)
					//u_log ('aAttInfo:', aAttInfo)
					_cNome1 := aAttInfo[1]
					_cNome4 := aAttInfo[4]

					if !empty(_cNome1) .or. !empty(_cNome4)
						if !empty(_cNome1)
							_cNomeArq := _cNome1
							_cTam := len(alltrim(_cNome1))
							_cExt := substr(_cNome1, (_cTam - 2), 3)
						else
							_cNomeArq := _cNome4
							_cTam := len(alltrim(_cNome4))
							_cExt := substr(_cNome4, (_cTam - 2), 3)
						endif
					//else
					//	u_log("Nao tem anexos")
					endif

					if upper(_cExt) == "XML"
						_cAnexo := oMessage:getAttach(nAtach)
						if empty (_cAnexo)
						 	_cAnexo := "ARQUIVO SEM CONTEUDO"
						else
							if right(_cAnexo,2) != 'c>'
								_cAnexo := _cAnexo +'c>'
							endif
					 		if right(_cAnexo,1) != '>'
								_cAnexo := _cAnexo +'>'
							endif
						endif
						//u_showmemo(_cAnexo)
						if empty (_cAnexo)
						 	_cAnexo := "ARQUIVO SEM CONTEUDO"
						endif
					  
						// copia o anexo para a pasta de XML a importar
						_nDirArq = fcreate('\XML_NFE\CT-E\' + _cNomeArq , 0)
						
						_cConta := _cConta + 1
					    
					    fwrite (_nDirArq, _cAnexo)
					    fclose (_nDirArq)

					elseif upper(_cExt) == "TXT"
							_cAnexo := oMessage:getAttach(nAtach)
							if empty (_cAnexo)
								_cAnexo := "ARQUIVO SEM CONTEUDO"
							endif
							
							// copia o anexo para o lugar certo
							if '320CONHE' $ _cAnexo
								_nDirArq = fcreate('\EDI_CONH\CONEMB\' + _cNomeArq , 0)
							else
								_nDirArq = fcreate('\EDI_CONH\OUTROS\' + _cNomeArq , 0)
						endif
						
						fwrite (_nDirArq, _cAnexo)
						fclose (_nDirArq)
						_cConta := _cConta + 1
					endif	
				Next
				// exclui o email do servidor
				u_log2 ('info', '[' + procname () + ']Excluindo e-mail do servidor')
				oMessage:SetConfirmRead(.T.)
				nDel  := oPopServer:deleteMsg(nMessage)

				oMessage:Clear()

			else
				_oAviso := ClsAviso ():New ()
				_oAviso:Tipo       = 'E'
				_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
				_oAviso:Texto      = "Mensagem " + cvaltochar (nMessage) + " nao foi recebida com sucesso e nao sera´ processada."
				_oAviso:Grava ()
			EndIf

		Next
		oPopServer:PopDisconnect()

		if _lRet .and. type ("_oBatch") == 'O'
			_oBatch:Mensagens += cvaltochar (_cConta) + ' arq.baixados.'
			_oBatch:Retorno   := 'S'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
		endif

	else
		//u_help ("Nao foi possivel conectar ao servidor de e-mail")
		_lRet = .F.
		_ValType := _RetType("_oBatch")
		if _ValType == 'O'
			U_Log2 ('erro', '[' + procname () + ']Nao foi possivel conectar ao servidor de e-mail')
			_oBatch:Mensagens += 'Nao foi possivel conectar ao servidor de e-mail'
			_oBatch:Retorno   := 'N'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
		endif
		_oAviso := ClsAviso ():New ()
		_oAviso:Tipo       = 'E'
		_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
		_oAviso:Texto      = 'Nao foi possivel conectar ao servidor de e-mail.'
		_oAviso:Grava ()
	EndIf
	
Return _lRet
//
// --------------------------------------------------------------------------
// Retorno do type - type em looling nao é permitido da R25 
Static Function _RetType(_var)
	_type := type(_var)
Return _type
