// Programa..: VA_CUSXCON	
// Autor.....: Claudia Lionco
// Data......: 12/04/2021 
// Funcao....: PE 'tudo OK' na manutencao de solicitacoes de compra.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #PE 'tudo OK' na manutencao de solicitacoes de compra.
// #PalavasChave      #ponto_de_entrada #colicitacao_de_compra
// #TabelasPrincipais #SC1 
// #Modulos           #COM 
//
// Historico de alteracoes:
//
// -------------------------------------------------------------------------------------------
User Function VA_CUSXCON(_sNum, _sTipo)
    Local _sGrupo := ""

    If _sTipo == '1' // Plano de custo
        _sGrupo := Posicione("CT1", 1, xFilial("CT1") + _sNum,"CT1_RGNV1")
    Else
        If _sTipo == '2' // Centro de custo
            _sGrupo := Posicione("CTT", 1, xFilial("CTT") + _sNum,"CTT_CRGNV1")
        EndIf
    EndIf

Return _sGrupo
