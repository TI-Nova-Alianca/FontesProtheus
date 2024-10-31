// Programa...: A116TECT
// Autor......: Cláudia Lionço
// Data.......: 25/10/2024
// Descricao..: P.E. Altera TES e Condição de pagamento para CTe
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. Altera TES e Condição de pagamento para CTe
// #PalavasChave      #TOTVS_Transmite #Monitor #Frete #Cte 
// #TabelasPrincipais #CKO #SDT #SDS #SF1 #SD1
// #Modulos   		  #COM 
//
// Historico de alteracoes:
//
// ----------------------------------------------------------------------------------------------
#Include 'Protheus.ch'

User function A116TECT()
    Local oXML   := Paramixb[1]
    Local aRet   := {}
    Local _sCond := ""
    Local _sCNPJ := ""

    // Busca condição de pagamento
    If (XmlChildEx( oXml ,"_CTEPROC")<>Nil)
        _sCNPJ := oXml:_CTEPROC:_CTE:_INFCTE:_EMIT:_CNPJ:Text

        _sCond := Posicione("SA2", 3, xFilial("SA2") + _sCNPJ, "A2_COND") // 3	A2_FILIAL + A2_CGC  
        // Adiciona parametros
        aAdd(aRet, "" ) // Código da TES
        aAdd(aRet, _sCond)    // Código da condição de pagamento

    else
        _sCNPJ := oXml:_INFCTE:_EMIT:_CNPJ:Text

        _sCond := Posicione("SA2", 3, xFilial("SA2") + _sCNPJ, "A2_COND") // 3	A2_FILIAL + A2_CGC  
        // Adiciona parametros
        aAdd(aRet, "066" ) // Código da TES
        aAdd(aRet, _sCond) // Código da condição de pagamento
    Endif
Return aRet


