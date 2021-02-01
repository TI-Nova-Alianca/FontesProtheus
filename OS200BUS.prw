// Programa...: OS200BUT
// Autor......: Cláudia Lionço
// Data.......: 01/02/2021
// Descricao..: Ponto de Entrada permite incluir botões na tela exibida, 
//              ao clicar no botão Montagem de Carga, na rotina de Montagem de Carga (OMSA200)

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de Entrada permite incluir botões na tela de Montagem de Carga - Outras Ações
// #PalavasChave      #montagem_de_carga #botoes
// #TabelasPrincipais #SC5
// #Modulos           #OMS

// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------------------

#INCLUDE "PROTHEUS.CH"

User Function OS200BUT()
    Local aButtons := {}
 
    Aadd( aButtons, {"TPFRETE", {|| _OSTpFrete(PED_PEDIDO)}, "TPFRETE", "Tipo de frete" , {|| .T.}} )     
 
Return(aButtons)
//
// ---------------------------------------------------------------------------------------------------
// Exibe em mensagem o tipo de frete
Static Function _OSTpFrete (_sPedido)
    Local _sTpFrete := fbuscacpo("SC5",1,xfilial("SC5")+ _sPedido,"C5_TPFRETE")

    Do Case
        Case alltrim(_sTpFrete) == 'C'
            _sTpDesc := "CIF"

        Case alltrim(_sTpFrete) == 'F'
            _sTpDesc := "FOB"

        Case alltrim(_sTpFrete) == 'T'
            _sTpDesc := "Por conta de terceiros"

        Case alltrim(_sTpFrete) == 'R'
            _sTpDesc := "Por conta remetente"

        Case alltrim(_sTpFrete) == 'D'
            _sTpDesc := "Por conta destinatario"

        Case alltrim(_sTpFrete) == 'S'
            _sTpDesc := "Sem frete"

    EndCase

    u_help("Pedido:" + alltrim(_sPedido) + " com tipo de frete:" + alltrim(_sTpDesc))
Return
