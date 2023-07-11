// Programa...: PE_MATA061
// Autor......: Claudia Lion�o
// Data.......: 09/02/2022
// Descricao..: Ponto entrada produto x fornecedor
//
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto entrada produto x fornecedor
// #PalavasChave      #ponto_de_entrada #produto_X_fornecedor  #produtoXfornecedor_MVC
// #TabelasPrincipais #SB1 
// #Modulos 		  #todos
//
// Historico de alteracoes:
// 23/06/2023 - Claudia - Valida��o p/nao duplicar fornecedor para mesmo produto protheus. GLPI: 13777/13690
// 11/07/2023 - Claudia - Chamada a fun��o de limpeza de caracteres especiais. GLPI: 13865
//
//---------------------------------------------------------------------------------------------------------------
#Include "Protheus.ch" 
#Include "TOTVS.ch"
#Include "FWMVCDEF.ch"

User Function MATA061() 
    Local aParam     := PARAMIXB
    Local xRet       := .T.
    Local oObj       := ""
    Local cIdPonto   := ""
    Local cIdModel   := ""
    Local lIsGrid    := .F.
    Local _oSQL := ClsSQL ():New ()

    If aParam <> NIL
        oObj := aParam[1]
        cIdPonto := aParam[2]
        cIdModel := aParam[3]
        lIsGrid := (Len(aParam) > 3)

        If cIdPonto == "MODELPOS" // Validação 'tudo OK' ao clicar no Botão Confirmar
 
        ElseIf cIdPonto == "FORMPOS" // Pós configurações do Formulário

        ElseIf cIdPonto == "FORMLINEPRE" // Chamada na pré validação da linha do formulário
            If aParam[5] == "DELETE"
                xRet := .T.
            EndIf

        ElseIf cIdPonto == "FORMLINEPOS" // Chamada na validação da linha do formulário.
            If aParam[5] == "DELETE"
                xRet := .T.
            else
                cCod     := oObj:GetValue('A5_CODPRF')
                cProd    := A5_PRODUTO
                cFornece := oObj:GetValue('A5_FORNECE')
                cLoja    := oObj:GetValue('A5_LOJA')

                _oSQL:_sQuery := ""
                _oSQL:_sQuery += " SELECT
                _oSQL:_sQuery += " 	    count(*) "
                _oSQL:_sQuery += " FROM " + RetSQLName ("SA5") 
                _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
                _oSQL:_sQuery += " AND A5_PRODUTO = '"+ cProd +"' "
                _aSA5 := aclone (_oSQL:Qry2Array ())

                _nQtdBanco := _aSA5[1,1]
                _nQtdLinha := oObj:Length()

                If _nQtdBanco <  _nQtdLinha
                    xRet := _MA061TOK(cCod,cProd,cFornece,cLoja)
                EndIf

                If xRet
                    _oEvento := ClsEvent():New ()
                    _oEvento:Alias     = 'SA5'
                    _oEvento:Texto     = " Cod.Prod. fornecedor: " + alltrim(cCod) + chr (13) + chr (10) + ;
                                         " Produto: " + alltrim(cProd) + chr (13) + chr (10) + ;
                                         " Fornecedor: " + alltrim(cFornece)
                    _oEvento:CodEven   = "SA5001"
                    _oEvento:Produto   = alltrim(cProd)
                    _oEvento:Fornece   = alltrim(cFornece)
                    _oEvento:Grava()
                EndIf
            EndIf

        ElseIf cIdPonto == "MODELCOMMITTTS"   // Chamada após a gravação total do modelo e dentro da transação
            
        ElseIf cIdPonto == "MODELCOMMITNTTS"  // Chamada após a gravação total do modelo e fora da transação 

        ElseIf cIdPonto == "FORMCOMMITTTSPRE" // Chamada após a gravação da tabela do formulário

        ElseIf cIdPonto == "FORMCOMMITTTSPOS" // Chamada após a gravação da tabela do formulário

        ElseIf cIdPonto == "MODELCANCEL"

        ElseIf cIdPonto == "BUTTONBAR"

        EndIf
    EndIf
Return xRet
//
//----------------------------------------------------------------------------------
// Tudo OK
Static Function _MA061TOK(cCod,cProd,cFornece,cLoja)
    Local _oSQL := ClsSQL ():New ()
    Local lRet  := .T.

    sCod := U_LimpaEsp(cCod)
    sCod := _AjustaCod(sCod)

    If empty(alltrim(sCod))
        u_help(" O codigo do produto no fornecedor nao pode estar vazio. Verifique!")
        lRet := .F.
    EndIf

    If lRet
        _oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT
        _oSQL:_sQuery += " 	    count(*) "
        _oSQL:_sQuery += " FROM " + RetSQLName ("SA5") 
        _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND A5_PRODUTO = '"+ cProd    +"' "
        _oSQL:_sQuery += " AND A5_FORNECE = '"+ cFornece +"' "
        _oSQL:_sQuery += " AND A5_LOJA    = '"+ cLoja    +"' "
        _aSA5 := aclone (_oSQL:Qry2Array ())

        If Len(_aSA5) > 0
            If _aSA5[1,1] > 0
                u_help("C�digo de fornecedor duplicado para mesmo produto. Verifique!")
                lRet := .F.
            EndIf
        EndIf
    EndIf
Return lRet
//
//----------------------------------------------------------------------------------
// Retira demais caracteres especiais do campo 
Static Function _AjustaCod(cConteudo)
     
    //Retirando virgulas e tra�os
    cConteudo := StrTran(cConteudo, ",", "")
    cConteudo := StrTran(cConteudo, "-", "")
     
    //Adicionando os espa�os a direita
    cConteudo := Alltrim(cConteudo)

Return cConteudo

