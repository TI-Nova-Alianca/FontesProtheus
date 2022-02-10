// Programa...: PE_MATA061
// Autor......: Cláudia Lionço
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
                xRet := _MA061TOK(cCod)
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
Static Function _MA061TOK(cCod)
    Local lRet  := .T.

    sCod := LimpaEsp(cCod)
    If empty(alltrim(sCod))
        u_help(" O codigo do produto no fornecedor nao pode estar vazio. Verifique!")
        lRet := .F.
    EndIf
Return lRet
//
//----------------------------------------------------------------------------------
// Retira caracteres especiais do campo 
Static Function LimpaEsp(cConteudo)
     
    //Retirando caracteres
    cConteudo := StrTran(cConteudo, "'", "")
    cConteudo := StrTran(cConteudo, "#", "")
    cConteudo := StrTran(cConteudo, "%", "")
    cConteudo := StrTran(cConteudo, "*", "")
    cConteudo := StrTran(cConteudo, "&", "E")
    cConteudo := StrTran(cConteudo, ">", "")
    cConteudo := StrTran(cConteudo, "<", "")
    cConteudo := StrTran(cConteudo, "!", "")
    cConteudo := StrTran(cConteudo, "@", "")
    cConteudo := StrTran(cConteudo, "$", "")
    cConteudo := StrTran(cConteudo, "(", "")
    cConteudo := StrTran(cConteudo, ")", "")
    cConteudo := StrTran(cConteudo, "_", "")
    cConteudo := StrTran(cConteudo, "=", "")
    cConteudo := StrTran(cConteudo, "+", "")
    cConteudo := StrTran(cConteudo, "{", "")
    cConteudo := StrTran(cConteudo, "}", "")
    cConteudo := StrTran(cConteudo, "[", "")
    cConteudo := StrTran(cConteudo, "]", "")
    cConteudo := StrTran(cConteudo, "/", "")
    cConteudo := StrTran(cConteudo, "?", "")
    cConteudo := StrTran(cConteudo, ".", "")
    cConteudo := StrTran(cConteudo, "\", "")
    cConteudo := StrTran(cConteudo, "|", "")
    cConteudo := StrTran(cConteudo, ":", "")
    cConteudo := StrTran(cConteudo, ";", "")
    cConteudo := StrTran(cConteudo, '"', '')
    cConteudo := StrTran(cConteudo, '°', '')
    cConteudo := StrTran(cConteudo, 'ª', '')
    cConteudo := StrTran(cConteudo, ",", "")
    cConteudo := StrTran(cConteudo, "-", "")
     
    //Adicionando os espaços a direita
    cConteudo := Alltrim(cConteudo)

Return cConteudo

