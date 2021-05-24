User Function LJ7009()

    Local aParams       := iIf( PARAMIXB<>nil, aClone(PARAMIXB), {} )
   // Local aParcResul    := iIf( Len(aParams) > 0, aParams[1], {} )
    Local aParcAlter    := iIf( Len(aParams) > 1, aParams[2], {} ) // novos dados para o pagamento
    Local xRet          := .T.
    Local nQtdParcs     := Len(aParcAlter)
   // Local nI            := 0
   // Local aAuxRet       := {} // verifica se possui informação
   // Local x             := 0

    //u_help(str(aParcAlter[1]))
    u_help(str(aParams[2]))
    U_help(Alltrim(aParams[3]))
    u_help(cValToChar(aParams[4]))
    u_help(cValToChar(aParams[5]))
    u_help(cValToChar(aParams[6]))

    If ( nQtdParcs > 1 )
        If (Alltrim(aParcAlter[3])== 'Cartao Debito' ) // cartão de débito apenas 1 parcela
            xRet := .F.
        Else
            xRet := aParcAlter
        EndIf
    EndIf

    //If( xRet ) // quando o processo pode continuar, é preciso retornar um vetor com os novos dados
    //    xRet := aParcAlter
    //EndIf

    //xRet := aParcAlter

    //For x:= 1 to Len(xRet)
    //    u_help(xRet[x])
    // Next

Return xRet


