// Programa...: PE_OMSA010
// Autor......: Cláudia Lionço
// Data.......: 25/06/2022
// Descricao..: Ponto entrada tabelas de preço
//              https://terminaldeinformacao.com/knowledgebase/omsa010-em-mvc/
//
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto entrada tabelas de preço
// #PalavasChave      #ponto_de_entrada #tabelas_de_preco  #tabela_de_preco_MVC
// #TabelasPrincipais #DA0 #DA1 
// #Modulos 		  #FAT
//
// Historico de alteracoes:
//
// ----------------------------------------------------------------------------------------
#Include "Protheus.ch" 
#Include "TopConn.ch"
 
User Function OMSA010() 
    Local aParam     := PARAMIXB 
    Local xRet       := .T. 
    Local oObj       := Nil 
    Local cIdPonto   := ""
    Local cIdModel   := ""
    Local oModelPad  := Nil
    Local oModelGrid := Nil
    Local _sProduto  := ""
    Local _sCodTab   := ""
    Local _nValor    := 0
    Local _lExcluido := .F.
 
    //Se tiver parâmetros
    If aParam != Nil 
 
        //Pega informações dos parâmetros
        oObj := aParam[1] 
        cIdPonto := aParam[2] 
        cIdModel := aParam[3] 
 
        //Valida a abertura da tela
        If cIdPonto == "MODELVLDACTIVE"
            xRet := .T. 
 
        //Pré configurações do Modelo de Dados
        ElseIf cIdPonto == "MODELPRE"
            xRet := .T. 
 
        //Pré configurações do Formulário de Dados
        ElseIf cIdPonto == "FORMPRE"
            xRet := .T. 
 
        //Adição de opções no Ações Relacionadas dentro da tela
        ElseIf cIdPonto == "BUTTONBAR"
            xRet := {}
 
        //Pós configurações do Formulário
        ElseIf cIdPonto == "FORMPOS"
            xRet := .T. 
 
        //Validação ao clicar no Botão Confirmar
        ElseIf cIdPonto == "MODELPOS"
            xRet := .T. 
 
        //Pré validações do Commit
        ElseIf cIdPonto == "FORMCOMMITTTSPRE"
            If cIdModel == "DA0MASTER"
                //Pegando os modelos de dados
                oModelPad  := FWModelActive()
                oModelCab := oModelPad:GetModel('DA0MASTER')

                U_DA0Verif(oModelCab)
                
            EndIf
            //Se vier da Grid
            If cIdModel == "DA1DETAIL"
                //Pegando os modelos de dados
                oModelPad  := FWModelActive()
                oModelGrid := oModelPad:GetModel('DA1DETAIL')
                 
                //Pegando as informações do item atual
                _sProduto  := oModelGrid:GetValue("DA1_CODPRO")
                _sCodTab   := oModelPad:GetValue("DA0MASTER", "DA0_CODTAB")
                _nValor    := oModelGrid:GetValue("DA1_PRCVEN")
                _lExcluido := oModelGrid:IsDeleted()

                //Chama a rotina do log (para gravar alterações de preço)
                If _lExcluido 
                    _sMsg := "Tabela " + _sCodTab + " alterada. Produto:" +  _sProduto + " Valor:" + cValtoChar(_nValor) + " Registro excluído." 
                Else
                    _sMsg := "Tabela " + _sCodTab + " alterada. Produto:" +  _sProduto + " Valor:" + cValtoChar(_nValor) 
                EndIf
                
                U_LogDA1(_sCodTab, _sMsg, _sProduto )
            EndIf
 
        //Pós validações do Commit
        ElseIf cIdPonto == "FORMCOMMITTTSPOS"
 
        //Commit das operações (antes da gravação)
        ElseIf cIdPonto == "MODELCOMMITTTS"
 
        //Commit das operações (após a gravação)
        ElseIf cIdPonto == "MODELCOMMITNTTS"
            u_TabEmail(da0->da0_filial, da0->da0_codtab)
        EndIf 
    EndIf 
Return xRet
//
// -----------------------------------------------------------------------------------
// Realiza verificações de alteração para gravar logs
User Function DA0Verif(oModelCab)
    _sCodTab    := oModelCab:GetValue("DA0_CODTAB")

    cAtivoAnt   := posicione("DA0", 1, xFilial("DA0") + _sCodTab, "DA0_ATIVO")
    cDescAnt    := posicione("DA0", 1, xFilial("DA0") + _sCodTab, "DA0_DESCRI")
    cPVAnt      := posicione("DA0", 1, xFilial("DA0") + _sCodTab, "DA0_PVCOND")
    nDescAnt    := posicione("DA0", 1, xFilial("DA0") + _sCodTab, "DA0_DESC")
    nFatorAnt   := posicione("DA0", 1, xFilial("DA0") + _sCodTab, "DA0_FATOR")
    nICMSAnt    := posicione("DA0", 1, xFilial("DA0") + _sCodTab, "DA0_ICMS")
    cUFAnt      := posicione("DA0", 1, xFilial("DA0") + _sCodTab, "DA0_VAUF")
    cTFreAnt    := posicione("DA0", 1, xFilial("DA0") + _sCodTab, "DA0_VATPFR")
    cEstDinAnt  := posicione("DA0", 1, xFilial("DA0") + _sCodTab, "DA0_VAESDI")
    nDMaxAnt    := posicione("DA0", 1, xFilial("DA0") + _sCodTab, "DA0_PERMAX")
    nDMinAnt    := posicione("DA0", 1, xFilial("DA0") + _sCodTab, "DA0_PERMAX")

    cAtivo      := oModelCab:GetValue("DA0_ATIVO")
    cDescri     := oModelCab:GetValue("DA0_DESCRI")
    cPVCond     := oModelCab:GetValue("DA0_PVCOND")
    nDesconto   := oModelCab:GetValue("DA0_DESC")
    nFator      := oModelCab:GetValue("DA0_FATOR")
    nICMS       := oModelCab:GetValue("DA0_ICMS")
    cUF         := oModelCab:GetValue("DA0_VAUF")
    cTipoFre    := oModelCab:GetValue("DA0_VATPFR")
    cEstDin     := oModelCab:GetValue("DA0_VAESDI")
    nDescMax    := oModelCab:GetValue("DA0_PERMAX")
    nDescMin    := oModelCab:GetValue("DA0_PERMAX")

    If cAtivoAnt <> cAtivo
        _sMsg := "Campo <Tab.Ativa> alterado de " + cAtivoAnt + " para " + cAtivo 
        U_LogDA0(_sCodTab, _sMsg )
    EndIf

    If cDescAnt <> cDescri
        _sMsg := "Campo <Descricao> alterado de " + alltrim(cDescAnt) + " para " + alltrim(cDescri)
        U_LogDA0(_sCodTab, _sMsg )
    EndIf

    If cPVAnt <> cPVCond
        _sMsg := "Campo <PV Condicao> alterado de " + alltrim(cDescAnt) + " para " + alltrim(cDescri)
        U_LogDA0(_sCodTab, _sMsg )
    EndIf

    If nDescAnt <> nDesconto
        _sMsg := "Campo <Desconto Maximo> alterado de " + cValtoChar(nDescAnt) + " para " + cValtoChar(nDesconto)
        U_LogDA0(_sCodTab, _sMsg )
    EndIf

    If nFatorAnt <> nFator
        _sMsg := "Campo <Fator Desc.> alterado de " + cValtoChar(nFatorAnt) + " para " + cValtoChar(nFator)
        U_LogDA0(_sCodTab, _sMsg )
    EndIf

    If nICMSAnt <> nICMS
        _sMsg := "Campo <%ICMS> alterado de " + cValtoChar(nICMSAnt) + " para " + cValtoChar(nICMS)
        U_LogDA0(_sCodTab, _sMsg )
    EndIf

    If cUFAnt <> cUF
        _sMsg := "Campo <UF> alterado de " + alltrim(cUFAnt) + " para " + alltrim(cUF)
        U_LogDA0(_sCodTab, _sMsg )
    EndIf 

    If cTFreAnt <> cTipoFre
        If alltrim(cTFreAnt) == 'C'
            cTFreAnt := 'CIF'
        else
            cTFreAnt := 'FOB'
        EndIf

        If alltrim(cTipoFre) == 'C'
            cTipoFre := 'CIF'
        else
            cTipoFre := 'FOB'
        EndIf
            
        _sMsg := "Campo <Tpo de frente> alterado de " + alltrim(cTFreAnt) + " para " + alltrim(cTipoFre)
        U_LogDA0(_sCodTab, _sMsg )
    EndIf

    If cEstDinAnt <> cEstDin
        _sMsg := "Campo <Tipo de frente> alterado de " + alltrim(cEstDinAnt) + " para " + alltrim(cEstDin)
        U_LogDA0(_sCodTab, _sMsg )
    EndIf

    If nDMaxAnt <> nDescMax
        _sMsg := "Campo <% Max.Desconto> alterado de " + alltrim(nDMaxAnt) + " para " + alltrim(nDescMax)
        U_LogDA0(_sCodTab, _sMsg )
    EndIf

    If nDMinAnt <> nDescMin
        _sMsg := "Campo <% Max.Acrescimo> alterado de " + alltrim(nDMinAnt) + " para " + alltrim(nDescMin)
        U_LogDA0(_sCodTab, _sMsg )
    EndIf
Return 
//
// -----------------------------------------------------------------------------------
// Grava log na VA_VEVENTOS DA0
User Function LogDA0(_sCodTab, _sMsg )

    _oEvento := ClsEvent():New ()
    _oEvento:Alias    = 'DA0'
    _oEvento:CodAlias = _sCodTab
    _oEvento:Texto    = _sMsg
    _oEvento:CodEven  = 'DA0001'
    _oEvento:Grava()
Return
//
// -----------------------------------------------------------------------------------
// Grava log na VA_VEVENTOS DA1
User Function LogDA1(_sCodTab, _sMsg, _sProduto)

    _oEvento := ClsEvent():New ()
    _oEvento:Alias    = 'DA1'
    _oEvento:CodAlias = _sCodTab
    _oEvento:Texto    = _sMsg
    _oEvento:CodEven  = 'DA1001'
    _oEvento:Produto  = _sProduto
    _oEvento:Grava()
Return

User Function TabEmail(_sFilial, _sTabela)
    Local _x := 0

    _oSQL := ClsSQL():New ()  
    _oSQL:_sQuery := "" 		
    _oSQL:_sQuery += " SELECT
    _oSQL:_sQuery += "     DATA "
    _oSQL:_sQuery += "    ,HORA "
    _oSQL:_sQuery += "    ,DESCRITIVO "
    _oSQL:_sQuery += "    ,CODIGO_ALIAS "
    _oSQL:_sQuery += "    ,PRODUTO "
    _oSQL:_sQuery += "    ,USUARIO "
    _oSQL:_sQuery += " FROM VA_VEVENTOS "
    _oSQL:_sQuery += " WHERE FILIAL      = '" + _sFilial     + "'"
    _oSQL:_sQuery += " AND DATA          = '" + dtos(date()) + "'"
    _oSQL:_sQuery += " AND HORA         <= '" + Time()       + "'"
    _oSQL:_sQuery += " AND CODIGO_ALIAS  = '" + _sTabela     + "'"
    _oSQL:_sQuery += " AND (ALIAS_TABELA = 'DA0' "
    _oSQL:_sQuery += " OR ALIAS_TABELA   = 'DA1') "
    _aDados := _oSQL:Qry2Array ()

    _aRetorno := {}
    If len(_aDados) > 0
        For _x:=1 to Len(_aDados)
        _sDt := DTOC(STOD( _aDados[_x, 1]))

        aadd(_aRetorno, {   _sDt ,;    
                            _aDados[_x, 2] ,; 
                            _aDados[_x, 3] ,; 
                            _aDados[_x, 4] ,; 
                            _aDados[_x, 5] ,; 
                            _aDados[_x, 6] }) 
        aadd(_aRetorno, {   " ",;    
                            " ",; 
                            " ",; 
                            " ",; 
                            " ",; 
                            " "}) 

        Next

        _aCols = {}
        aadd(_aCols, {'DATA'        , "left"    ,  "@!"})
        aadd(_aCols, {'HORA'        , "left"    ,  "@!"})
        aadd(_aCols, {'DESCRITIVO'  , "left"    ,  "@!"})
        aadd(_aCols, {'TABELA'      , "left"    ,  "@!"})
        aadd(_aCols, {'PRODUTO'     , "left"    ,  "@!"})
        aadd(_aCols, {'USUARIO'     , "left"    ,  "@!"})

        _sMsg := '<H1 align="center"></H1>'
		_sMsg += '<H3 align="center">ALTERAÇÃO DE TABELA DE PREÇO '+ _sTabela +'</H2>' + chr (13) + chr (10)

        _oAUtil := ClsAUtil():New (_aRetorno)
		_sMsg += _oAUtil:ConvHTM ("", _aCols, 'width="80%" border="1" cellspacing="0" cellpadding="0" align="center"', .T.)

        _sTitulo  := "ALTERAÇÃO: TABELA DE PREÇO " + _sTabela
		//U_SendMail (_sDestin, _sTitulo, _sMsg, {})
        U_ZZUNU ({'141'}, _sTitulo , _sMsg, .F.)
    EndIf

Return
