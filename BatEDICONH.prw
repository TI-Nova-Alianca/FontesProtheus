// Programa:   BatEDICONH
// Autor:      Catia Cardoso
// Data:       24/10/2014
// Cliente:    Alianca
// Descricao:  Grava ZAA - EDI Conhecimentos Frete
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
// 11/11/2014 - estava dando erro quando ia verificar se ja existia o arquivo na ZAA
// 15/01/2015 - estava dando erro quando na gravacao quando arquivo vinha vazio, sem linhas referentes a conhecimentos
// 15/12/2015 - Robert - Tratamento para cancelar quando arquivo grande demais.
// 11/08/2017 - Catia  - do nada começou a dar erro na linha +194 variavel _wcont - acertado
// 18/09/2017 - Catia  - bloqueado o trecho que baixa os emails, esta dando erro na nova release, temos chamado aberto, aguardando retorno
// 11/10/2017 - Robert - Habilitada novamente baixa de e-mails (dava erro na build anterior)
// 04/11/2019 - Robert - Nao chama mais a rotina de recepcao de e-mail (migrada para 'batch' separado).
// 02/12/2019 - Robert - Declaradas variaveis locais para for...next - tratamento para mensagem [For variable is not Local]
// 03/03/2020 - Claudia - Ajustada criação de arquivo de trabalho conforme solicitação da release 12.1.25
//
// --------------------------------------------------------------------------
#include "totvs.ch"                                                            	
#include "protheus.ch"
//
// --------------------------------------------------------------------------
user function BatEDICONH () //(_sQueFazer)
	local _lRet      := .T.
	local _aAreaAnt  := {}
	local _aAmbAnt   := {}
	local _nDir      := 0
	local _aDir      := {}
	local _sQuery    := ""
	local _aClientes := {}
	local _nCliente  := 0
	local _nLock     := 0
	local _lContinua := .T.
	Local cLinha     := ''
	local _Xreg      := 0
	
	U_logIni ()
	u_logDH()
	
	_aAreaAnt  := U_ML_SRArea ()
	_aAmbAnt   := U_SalvaAmb ()
	
	// Controla acesso via semaforo para evitar chamadas concorrentes, pois a importacao e a exportacao sao
	// agendadas separadamente nas rotinas de batch. A principio, o problema seria apenas a geracao de logs misturados.
	if _lContinua
		_nLock := U_Semaforo (procname () + cEmpAnt + cFilAnt, .F.)
		if _nLock == 0
			u_log ("Bloqueio de semaforo.")
			_lContinua = .F.
		endif
	endif
  
	if _lContinua 
       _alista = Directory ("\EDI_CONH\CONEMB\*.TXT")
       u_log (_aLista)
       
       	if len (_alista) > 0
    		for _Xreg = 1 to len (_alista)

			   _Xarq := _alista [_Xreg, 1]
			   u_log (_xArq)
			   
			   _sSQL := ""
               _sSQL += " SELECT 1" 
               _sSQL += "   FROM " + RetSQLName ("ZAA") + " AS ZAA"
               _sSQL += "  WHERE D_E_L_E_T_ = ' '" 
               _sSQL += "    AND ZAA_NOMARQ = '" + _xArq + "' "
             
               _existe := U_Qry2Array(_sSQL)
     
     		   cArq := "\EDI_CONH\CONEMB\" + _Xarq
						
               if len (_existe) = 0 
					cLinha = ""
					
					FT_FUSE(cArq)
					ProcRegua(FT_FLASTREC())
					FT_FGOTOP()
					While !FT_FEOF()
						IncProc("Lendo arquivo texto EDI...")
						cLinha += FT_FREADLN() + chr(13) + chr(10)
						FT_FSKIP()
						if len (cLinha) > 900000
							u_help ("Arquivo '" + cArq + "' grande demais. O mesmo vai ser ignorado.")
							_lContinua = .F.
							exit
						endif
					EndDo
					u_log (cLinha)
				   
				   if _lContinua
				   		Processa( { |lEnd| Continua(_Xarq , cArq) } )
				   endif
				   
				   // fecha o arquivo
				   FT_FUSE()
				   
				   // copia para os lidos
				   if _lContinua
				   		copy file (cArq) to ('\EDI_CONH\CONEMB\LIDOS\' + _Xarq)
				   
				   		// deleta do diretorio principal
				   		delete file (cArq)
				   endif
			  else
			  	  delete file (cArq)			  		   
              endif
			next
		endif
	endif
	
	// Libera semaforo.
	if _lContinua .and. _nLock > 0
		U_Semaforo (_nLock)
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return _lRet
//
// --------------------------------------------------------------------------
Static Function Continua(_Xarq1, Carq1)
//    _aEstru := {}
//    aadd(_aEstru,{'CAMPO','C',740,0})
//    _cArq   := CriaTrab(_aEstru,.T.)
//    DbUseArea(.T.,,_cArq,'TRB',.T.,.F.)

    _aArqTrb := {}
	_aEstru  := {}
	aadd(_aEstru,{'CAMPO','C',740,0})	
	U_ArqTrb ("Cria", "TRB", _aEstru, {}, @_aArqTrb)	
	
    Append From &Carq1 SDF 
    
    Processa( { |lEnd| _Grava (_Xarq1, Carq1) } )
    
    TRB->(DbCloseArea())
    
   // fErase(_cArq + '.dbf')
   u_arqtrb ("FechaTodos",,,, @_aArqTrb)
Return
//
// ------------------------------------------------------------------------------------
Static Function _Grava(_Xarq2, Carq2)
    local _aArqTrb   := {}
    local _aCampos   := {}
    local _xCONT     := 0
    local _lContinua := .T.
    local _xFORNECE  := ' '
    local _xseries   := array(40)
    local _xnotas    := array(40)
    local _werro     := 0
    local _werro1    := 0
    local _wcont     := 0
    local _versao    := 681
    private _xNFCFORI := ""  // Deixar 'private' para ser vista por pontos de entrada.
    
    // le arquivo de trabalho e verifica se existem os XMLs referentes ao conhecimentos
    DbSelectArea("TRB")
    DbGoTop()
    Do While !TRB->(Eof())
        if SubStr(TRB->CAMPO,1,3) = '000'
            _wdata := SubStr(TRB->CAMPO,74,6)
            _wdata := stod( "20" + SubStr(_wdata,5,2) + SubStr(_wdata,3,2) + SubStr(_wdata,1,2) )
            _wcont := 0
        endif
        if SubStr(TRB->CAMPO,1,3) = '321'
            // identifica pelo transportador a versao do layout p/saber de onde buscar a chave
            _wtransp := SubStr(TRB->CAMPO,18,40)
            if 'STILLO' $ _wtransp
                _versao := 679
            endif
        endif
        if SubStr(TRB->CAMPO,1,3) = '322'
            // Verifica se existe XML referente ao conhecimento
            _xCHAVE  := SubStr(TRB->CAMPO,_versao,44)
            _xCNPJ   := SubStr(TRB->CAMPO,205,14)
            _wcont++
            if _xCHAVE != ' '
                // verifica se ja existe o conhecimento no ZZX
                _sSQL := ""
                _sSQL += " SELECT *" 
                _sSQL += "   FROM ZZX010"
                _sSQL += "  WHERE D_E_L_E_T_ = ''"  
                _sSQL += "    AND ZZX_CHAVE  = '" + _xCHAVE + "'"
                _TemXML := U_Qry2Array(_sSQL)
                If len(_TemXML) =  0
                    // grava erro SEM XML
                    _werro := 1
                Endif
            Else   
                // grava erro SEM CHAVE
                _werro1 :=1 
            endif
        endif
        DbSelectArea("TRB")
        DbSkip()   
    enddo
    
    // grava ZAA
    if _wcont > 0
    	zaa -> (dbsetorder (1))
    	if ! zaa -> (dbseek (xfilial ("ZAA") + _Xarq2, .F.))
        	reclock("ZAA", .T.)
        	Replace ZAA->ZAA_FILIAL  With xFilial("ZAA")
        	Replace ZAA->ZAA_NOMARQ  With _Xarq
        	Replace ZAA->ZAA_STATUS  With "NI"
        	Replace ZAA->ZAA_DTARQ   With _wdata         
        	Replace ZAA->ZAA_LAYOUT  With iif(_werro1 > 0,'NA','OK')
        	Replace ZAA->ZAA_XML     With iif(_werro  > 0,'BX','OK') 
        	Replace ZAA->ZAA_TRANSP  With fbuscacpo ("SA2", 3, xfilial ("SA2") + _xCNPJ,  "A2_NOME")
        	Replace ZAA->ZAA_CTRANS  With fbuscacpo ("SA2", 3, xfilial ("SA2") + _xCNPJ,  "A2_COD")
        	Replace ZAA->ZAA_QTDDOC  With _wcont
        	msunlock()
    	endif
	endif    	
return
