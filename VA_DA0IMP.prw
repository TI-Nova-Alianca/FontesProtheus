// Programa: VA_DA0IMP
// Autor...: Cláudia Lionço
// Data....: 19/09/2023
// Funcao..: Importa .CSV com dados da tabela de preços
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Importa .CSV com dados da tabela de preços
// #PalavasChave      #vendas #tabela_de_preco
// #TabelasPrincipais #DA0 #DA1
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "Rwmake.ch"

User Function VA_DA0IMP()
    Processa({|| _ProcessaTab()}, "Executando ajustes na tabela de preço...")
    u_help("Atualizado!")
Return
//
// ---------------------------------------------------------------------------------------
// Processamento da importação
Static function _ProcessaTab()
    Local _sArqOri := ""
    Local _i       := 0
    Local _sDA0Est := ""
    Local _aMsg    := {}
    
    _sArqOri := tFileDialog( "CSV files (*.csv) ", 'Seleção de Arquivos', , , .F., )

    _aDados = U_LeCSV(_sArqOri, ';')

    for _i := 2 to len(_aDados)
        _sFilial  := PADL(ALLTRIM(_aDados[_i, 1]),2,'0')
        _sTabela  := PADL(ALLTRIM(_aDados[_i, 2]),3,'0')
        _sItem    := PADL(ALLTRIM(_aDados[_i, 3]),4,'0')
		_sProduto := ALLTRIM(_aDados[_i, 4])
		_sEstado  := alltrim(_aDados[_i, 5])
        _nValor   := _ConverteValor(_aDados[_i, 6])
        _sStatus  := alltrim(_aDados[_i, 7])

        DbSelectArea("DA0")
        DbSetOrder(1) // DA0_FILIAL+DA0_CODTAB 
        If DbSeek(_sFilial + _sTabela ,.F.)
            _sDA0Est := DA0->DA0_VAUF
        EndIf             

        Do Case
            Case _sStatus == 'A'
                _AtuRegistro(_sFilial, _sTabela, _sItem, _sProduto, _sEstado, _nValor, _sDA0Est, _aMsg)

            Case _sStatus == 'I'
                _IncRegistro(_sFilial, _sTabela, _sItem, _sProduto, _sEstado, _nValor, _sDA0Est, _aMsg)

            Case _sStatus == 'E'
                _ExcRegistro(_sFilial, _sTabela, _sItem, _sProduto, _sEstado, _nValor, _sDA0Est, _aMsg)
        EndCase

        If _i == len(_aDados)
            DbSelectArea("DA0")
            DbSetOrder(1) // DA0_FILIAL+DA0_CODTAB 
            If DbSeek(_sFilial + _sTabela ,.F.)
                _sDA0Est := DA0->DA0_VAUF

                reclock("DA0", .f.)
                    DA0->DA0_ATIVO := '2'
                msunlock()

                U_AtuMerc ('DA0', da0 -> (recno ()))
            EndIf                                                                                                                                  
        EndIf
	Next
    
     _sMsg := ""
     For _i := 1 to Len(_aMsg)
        _sMsg += _aMsg[_i, 1] + ' -> ' + _aMsg[_i, 2] + CRLF
     Next

    If !empty(_sMsg)
        _MsgLog(_sMsg, _sTabela)
    EndIf
Return
//
// ---------------------------------------------------------------------------------------
// Atualiza registros
Static Function _AtuRegistro(_sFilial, _sTabela, _sItem, _sProduto, _sEstado, _nValor,_sDA0Est, _aMsg)

    DbSelectArea("DA1")
    DbSetOrder(3) // DA1_FILIAL+DA1_CODPRO+DA1_CODTAB+DA1_ITEM

    If DbSeek(_sFilial + _sTabela + _sItem ,.F.)
        _sCliente := DA1->DA1_CLIENT
        _sLoja    := DA1->DA1_LOJA
        _sEstAnt  := DA1->DA1_ESTADO
        _sVlrAnt  := DA1->DA1_PRCVEN
        If _sEstAnt != _sEstado
            _oEvento := ClsEvent():New ()
            _oEvento:Alias     = 'DA1'
            _oEvento:Texto     = "Estado alterado de "+ DA1->DA1_ESTADO +" para "+ _sEstado +". Filial:"+ _sFilial +" Tabela:"+ _sTabela +" Item:"+ _sItem +" Produto:"+ alltrim(_sProduto) + " Estado:" + _sEstado
            _oEvento:CodEven   = "DA0002"
            _oEvento:Grava()
        EndIf

        If _sVlrAnt != _nValor  
            _oEvento := ClsEvent():New ()
            _oEvento:Alias     = 'DA1'
            _oEvento:Texto     = "Valor alterado de "+ alltrim(str(DA1->DA1_PRCVEN)) +" para "+ alltrim(str(_nValor))+ ". Filial:"+ _sFilial +" Tabela:"+ _sTabela +" Item:"+ _sItem +" Produto:"+ alltrim(_sProduto) + " Estado:" + _sEstado
            _oEvento:CodEven   = "DA0002"
            _oEvento:Grava()            
        EndIf

        reclock("DA1", .F.)
            DA1->DA1_ESTADO := _sEstado
            DA1->DA1_PRCVEN := _nValor   
            DA1->DA1_ICMS   := _RegraICMS(_sEstado) 
            DA1->DA1_VAST   := _RegraST(_sEstado,_sDA0Est,_nValor,_sCliente,_sLoja,_sProduto)                                                                      	                                                                 
        MsUnLock()
        _sMsg := "Item " + _sItem + " alterado de Vlr." + alltrim(str(_sVlrAnt))+ " para " + alltrim(str(_nValor))+ " Estado de " + _sEstAnt + " para " + _sEstado + Chr(10) + Chr (13)
        aadd(_aMsg,{ "ALT", _sMsg })
    EndIf        	
Return 
//
// ---------------------------------------------------------------------------------------
// Inclui registros
Static Function _IncRegistro(_sFilial, _sTabela, _sItem, _sProduto, _sEstado, _nValor,_sDA0Est,_aMsg)
    Local _lCont := .T.

    Do Case 
        Case empty(_sFilial)
            _sMsg := " Na inclusão de novos registros, o campo <filial> é obrigatório! Produto:" + _sProduto 
            _lCont := .F.
            u_help(_sMsg)
            aadd(_aMsg,{ "ERRO", _sMsg })

        Case empty(_sTabela)
            _sMsg := " Na inclusão de novos registros, o campo <tabela> é obrigatório! Produto:" + _sProduto 
            _lCont := .F.
            u_help(_sMsg)
            aadd(_aMsg,{ "ERRO", _sMsg })

        Case empty(_sItem)
            _sMsg := " Na inclusão de novos registros, o campo <item> é obrigatório! Produto:" + _sProduto 
            _lCont := .F.
            u_help(_sMsg)
            aadd(_aMsg,{ "ERRO", _sMsg })

        Case empty(_sProduto)
            _sMsg := " Na inclusão de novos registros, o campo <produto> é obrigatório!"
            _lCont := .F.
            u_help(_sMsg)
            aadd(_aMsg,{ "ERRO", _sMsg })

        Case empty(_sEstado)
            _sMsg := " Na inclusão de novos registros, o campo <estado> é obrigatório! Produto:" + _sProduto 
            _lCont := .F.
            u_help(_sMsg)
            aadd(_aMsg,{ "ERRO", _sMsg })

        Case empty(_nValor)
            _sMsg := " Na inclusão de novos registros, o campo <valor> é obrigatório! Produto:" + _sProduto 
            u_help(_sMsg)
            aadd(_aMsg,{ "ERRO", _sMsg })
            _lCont := .F.            

    EndCase

    If _lCont 
        DbSelectArea("DA1")
        DbSetOrder(3) // DA1_FILIAL+DA1_CODTAB+DA1_ITEM                                                                                                                                  

        If !DbSeek(_sFilial + _sTabela + _sItem)
            _sCliente := DA1->DA1_CLIENT
            _sLoja    := DA1->DA1_LOJA

            _oEvento := ClsEvent():New ()
            _oEvento:Alias     = 'DA1'
            _oEvento:Texto     = "Produto incluído "+ _sProduto +". Filial:"+ _sFilial +" Tabela:"+ _sTabela +" Item:"+ _sItem +" Produto:"+ alltrim(_sProduto) + " Estado:" + _sEstado + " Valor:" + alltrim(str(_nValor))
            _oEvento:CodEven   = "DA0002"
            _oEvento:Grava()

            reclock("DA1", .T.)
                DA1->DA1_FILIAL := _sFilial
                DA1->DA1_ITEM   := _sItem
                DA1->DA1_CODTAB := _sTabela
                DA1->DA1_ESTADO := _sEstado
                DA1->DA1_CODPRO := _sProduto
                DA1->DA1_PRCVEN := _nValor   
                DA1->DA1_ICMS   := _RegraICMS(_sEstado) 
                DA1->DA1_VAST   := _RegraST(_sEstado,_sDA0Est,_nValor,_sCliente,_sLoja,_sProduto)     
                DA1->DA1_QTDLOT := 999999.99
                DA1->DA1_INDLOT := '000000000999999,99'  
                DA1->DA1_MOEDA  := 1
                DA1->DA1_ATIVO  := '1'
                DA1->DA1_TPOPER := '4'
                DA1->DA1_DATVIG := ddatabase                                                                   	                                                                 
            MsUnLock()

            _sMsg := "Item " + _sItem + " aVlr." + alltrim(str(_nValor)) + " Estado " + _sEstado + Chr(10) + Chr (13)
            aadd(_aMsg,{ "INC", _sMsg })
        else
            _sMsg := "Item " + _sItem + " com status <I> porém já está na tabela de preço. Item não incluído." + Chr(10) + Chr (13)
            aadd(_aMsg,{ "INFO", _sMsg })
        EndIf  
    EndIf      	
Return 
//
// ---------------------------------------------------------------------------------------
// Exclui registros
Static Function _ExcRegistro(_sFilial, _sTabela, _sItem, _sProduto, _sEstado, _nValor, _sDA0Est, _aMsg)

    DbSelectArea("DA1")
    DbSetOrder(3) // DA1_FILIAL+DA1_CODPRO+DA1_CODTAB+DA1_ITEM

    If DbSeek(_sFilial + _sTabela + _sItem ,.F.)
        reclock("DA1", .F.)
            DA1->(DbDelete())                                                                   	                                                                 
        MsUnLock()

        _oEvento := ClsEvent():New ()
        _oEvento:Alias     = 'DA1'
        _oEvento:Texto     = "Produto Excluído "+ _sProduto +". Filial:"+ _sFilial +" Tabela:"+ _sTabela +" Item:"+ _sItem +" Produto:"+ alltrim(_sProduto) + " Estado:" + _sEstado + " Valor:" + alltrim(str(_nValor))
        _oEvento:CodEven   = "DA0002"
        _oEvento:Grava()

        _sMsg := "Item " + _sItem + " excluído." + Chr(10) + Chr (13)
        aadd(_aMsg,{ "DEL", _sMsg })
    else
        _sMsg := "Item " + _sItem + " não encontrado para excluir." + Chr(10) + Chr (13)
        aadd(_aMsg,{ "INFO", _sMsg })
    EndIf        	
Return
//
// ---------------------------------------------------------------------------------------
// Regra do gatilho de ICMS - DA1_ESTADO para DA1_ICMS
Static Function _RegraICMS(_sEstado)
    _sMVAliqIcm := U_SeparaCpo(alltrim (GetMv("MV_ALIQICM",, "")), "/")
    _sMVNorte   := alltrim(GetMv("MV_NORTE"))
    _sMVEstado  := alltrim(GetMv("MV_ESTADO"))
    _nPiece     := 0

    // verifica se UF da tabela é RS
    if alltrim(_sEstado) == _sMVEstado
        _nPiece :=  4 // usa aliquota 3
    else
        // verifica se estado esta na regiao norte
        _nNorte = at(_sEstado, _sMVNorte)
        if _nNorte > 0
            // usa aliquota 1
            _nPiece := 2
        else
            // usa aliquota 2
            _nPiece := 3
        endif
    endif
    _xRet= val( _sMVAliqIcm [_nPiece] )
Return _xRet
//
// ---------------------------------------------------------------------------------------
// Regra do ST - DA1_PRCVEN para DA1_VAST
Static Function _RegraST(_sEstado,_sDA0Est,_nValor,_sCliente,_sLoja,_sProduto) 
    _xRet    := 0
    _sEstado := _sEstado

    if empty(_sEstado)
        _sEstado := _sDA0Est
    endif

    _xRet = U_CalcST4(_sEstado, _sProduto, _nValor, _sCliente, _sLoja, 1, '801')
Return _xRet
//
// ---------------------------------------------------------------------------------------
// faz tratamentos de valores
Static Function _ConverteValor(_sValor)
    Local _nValor := 0

    _sValor := strtran(_sValor, '"', '')
    _sValor := strtran(_sValor, ",", ".")
    _nValor := val(_sValor) 

Return _nValor
//
// ---------------------------------------------------------------------------------------
// Mostra Log
Static Function _MsgLog(cMsg, _sTabela)
	Local lRetMens := .F.
	Local oButton1
	Local oButton2
	Local oMultiGe1
	Static oDlg

	DEFINE MSDIALOG oDlg TITLE "New Dialog" FROM 000, 000  TO 600, 800 COLORS 0, 16777215 PIXEL

	@ 006, 005 GET oMultiGe1 VAR cMsg OF oDlg MULTILINE SIZE 390, 267 COLORS 0, 16777215 HSCROLL PIXEL
	@ 280, 357 BUTTON oButton1 PROMPT "OK" SIZE 037, 012  ACTION (lRetMens:=.T., oDlg:End()) OF oDlg PIXEL
	@ 280, 311 BUTTON oButton2 PROMPT "Salvar .TXT" SIZE 037, 012 ACTION (_SalvArq(cMsg, _sTabela)) OF oDlg PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED

Return lRetMens
//
// ---------------------------------------------------------------------------------------
//Função para gerar um arquivo texto 
Static Function _SalvArq(cMsg, _sTabela)
    Local cFileNom :='\x_arq_'+dToS(Date())+StrTran(Time(),":")+".txt"
    Local cQuebra  := CRLF + "=======================================================================" + CRLF
    Local lOk      := .T.
    Local cTexto   := ""
     
    //Pegando o caminho do arquivo
    cFileNom := "c:\temp\LOG_tabela_" +alltrim(_sTabela) + ".txt"
 
    //Se o nome não estiver em branco    
    If !Empty(cFileNom)
        //Teste de existência do diretório
        If ! ExistDir(SubStr(cFileNom,1,RAt('\',cFileNom)))
            Alert("Diretório não existe:" + CRLF + SubStr(cFileNom, 1, RAt('\',cFileNom)) + "!")
            Return
        EndIf
         
        //Montando a mensagem
        cTexto := "Função   - "+ FunName()       + CRLF
        cTexto += "Usuário  - "+ cUserName       + CRLF
        cTexto += "Data     - "+ dToC(dDataBase) + CRLF
        cTexto += "Hora     - "+ Time()          + CRLF
        cTexto += "Mensagem - "+ "Importação" + cQuebra  + cMsg + cQuebra
         
        //Testando se o arquivo já existe
        If File(cFileNom)
            lOk := MsgYesNo("Arquivo já existe, deseja substituir?", "Atenção")
        EndIf
         
        If lOk
            MemoWrite(cFileNom, cTexto)
            MsgInfo("Arquivo Gerado com Sucesso:"+CRLF+cFileNom,"Atenção")
        EndIf
    EndIf
Return
