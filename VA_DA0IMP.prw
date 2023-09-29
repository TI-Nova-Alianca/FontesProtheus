// Programa: VA_DA0IMP
// Autor...: Cláudia Lionço
// Data....: 19/09/2023
// Funcao..: Importa .CSV com dados da tabela de preços
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Importa .CSV com dados da tabela de preços
// #PalavasChave      #vendas #tabela_de_preco
// #TabelasPrincipais #DA0
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------
User function VA_DA0IMP()
    Local _sArqOri := ""
    Local _i       := 0
    Local _sDA0Est := ""

    _sArqOri := tFileDialog( "CSV files (*.csv) ", 'Seleção de Arquivos', , , .F., )

    _aDados = U_LeCSV(_sArqOri, ';')

    for _i := 2 to len(_aDados)

        _sFilial  := PADL(ALLTRIM(_aDados[_i, 1]),2,'0')
        _sTabela  := PADL(ALLTRIM(_aDados[_i, 2]),3,'0')
        _sItem    := PADL(ALLTRIM(_aDados[_i, 3]),4,'0')
		_sProduto := PADL(ALLTRIM(_aDados[_i, 4]),4,'0')
		_sEstado  := alltrim(_aDados[_i, 5])
        _nValor   := val(strtran(_aDados[_i, 6], ",", ".")) 
        _sStatus  := alltrim(_aDados[_i, 7])

        If _i == 2
            DbSelectArea("DA0")
            DbSetOrder(1) // DA0_FILIAL+DA0_CODTAB 
            If DbSeek(_sFilial + _sTabela ,.F.)
                _sDA0Est := DA0->DA0_VAUF

                reclock("DA0", .f.)
                    DA0->DA0_ATIVO := '2'
                msunlock()
            EndIf                                                                                                                                  
        EndIf

        Do Case
            Case _sStatus == 'A'
                _AtuRegistro(_sFilial, _sTabela, _sItem, _sProduto, _sEstado, _nValor)

            Case _sStatus == 'I'
                _IncRegistro(_sFilial, _sTabela, _sItem, _sProduto, _sEstado, _nValor)

            Case _sStatus == 'E'
                _ExcRegistro(_sFilial, _sTabela, _sItem, _sProduto, _sEstado, _nValor)
        EndCase
	Next
	u_help("Atualizado!")
Return
//
// ---------------------------------------------------------------------------------------
// Atualiza registros
Static Function _AtuRegistro(_sFilial, _sTabela, _sItem, _sProduto, _sEstado, _nValor,_sDA0Est)

    DbSelectArea("DA1")
    DbSetOrder(3) // DA1_FILIAL+DA1_CODPRO+DA1_CODTAB+DA1_ITEM

    If DbSeek(_sFilial + _sTabela + _sItem ,.F.)
        _sCliente := DA1->DA1_CLIENT
        _sLoja    := DA1->DA1_LOJA

        reclock("DA1", .F.)
            DA1->DA1_PRCVEN := _nValor   
            DA1->DA1_ICMS   := _RegraICMS(_sEstado) 
            DA1->DA1_VAST   := _RegraST(_sEstado,_sDA0Est,_nValor,_sCliente,_sLoja,_sProduto)                                                                      	                                                                 
        MsUnLock()
    EndIf        	
Return
//
// ---------------------------------------------------------------------------------------
// Inclui registros
Static Function _IncRegistro(_sFilial, _sTabela, _sItem, _sProduto, _sEstado, _nValor,_sDA0Est)
    Local _lCont := .T.

    Do Case 
        Case empty(_sFilial)
            u_help(" Na inclusão de novos registros, o campo <filial> é obrigatório!")
            _lCont := .F.
        Case empty(_sTabela)
            u_help(" Na inclusão de novos registros, o campo <tabela> é obrigatório!")
            _lCont := .F.

        Case empty(_sItem)
            u_help(" Na inclusão de novos registros, o campo <item> é obrigatório!")
            _lCont := .F.

        Case empty(_sProduto)
            u_help(" Na inclusão de novos registros, o campo <produto> é obrigatório!")
            _lCont := .F.

        Case empty(_sEstado)
            u_help(" Na inclusão de novos registros, o campo <estado> é obrigatório!")
            _lCont := .F.

        Case empty(_nValor)
            u_help(" Na inclusão de novos registros, o campo <valor> é obrigatório!")
            _lCont := .F.

    EndCase

    If _lCont 
        DbSelectArea("DA1")
        DbSetOrder(3) // DA1_FILIAL+DA1_CODPRO+DA1_CODTAB+DA1_ITEM

        If !DbSeek(_sFilial + _sTabela + _sItem ,.F.)
            _sCliente := DA1->DA1_CLIENT
            _sLoja    := DA1->DA1_LOJA

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
        EndIf  
    EndIf      	
Return
//
// ---------------------------------------------------------------------------------------
// Exclui registros
Static Function _ExcRegistro(_sFilial, _sTabela, _sItem, _sProduto, _sEstado, _nValor)

    DbSelectArea("DA1")
    DbSetOrder(3) // DA1_FILIAL+DA1_CODPRO+DA1_CODTAB+DA1_ITEM

    If DbSeek(_sFilial + _sTabela + _sItem ,.F.)
        reclock("DA1", .F.)
            DA1->(DbDelete())                                                                   	                                                                 
        MsUnLock()
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
