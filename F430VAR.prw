// Programa.:  F430VAR
// Autor....:  Claudia Lionço
// Data.....:  04/10/2024
// Descricao:  P.E. permite manipulação das Variáveis Private durante a baixa CNAB (Pagar)
//             https://tdn.totvs.com/pages/releaseview.action?pageId=641447402
//             Criado inicialmente para controle de baixa de títulos no conta corrente
// 
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. permite manipulação das Variáveis Private durante a baixa CNAB (Pagar)
// #PalavasChave      #baixa #contas_a_receber
// #TabelasPrincipais #SE2 
// #Modulos           #FIN
//
// Historico de alteracoes:
// 04/10/2024 - Claudia = Criação do P.E. GLPI: 16125
//
// ----------------------------------------------------------------------------------------------------
User Function F430VAR()
    local _dUltDiaMes := lastday(Date())

    if MV_PAR10 = 2 // modelo 2
        _oAssoc := ClsAssoc():New(cForne,'01')
        if _oAssoc:EhSocio(_dUltDiaMes)
            _nIdCnab := PARAMIXB[1][1]

            DbSelectArea('SE2')        
            DbSetOrder(11) //SE2	B E2_FILIAL+E2_IDCNAB    
            if DbSeek(xFilial() + _nIdCnab)  
                RecLock("SE2", .F.)
                    se2 -> e2_vaassoc := 'I'
                MsUnlock()   
            endif   
        endif                                                                                                                            
    endif
Return
