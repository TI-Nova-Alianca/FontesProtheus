// Programa...: PEBOT006
// Autor......: Cláudia Lionço
// Data.......: 04/01/2023
// Descricao..: Ponto de entrada para botões no Painel XML Totvs RS
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada para botões no Painel XML Totvs RS
// #PalavasChave      #ponto_entrada #importador_XML
// #TabelasPrincipais
// #Modulos   		  #COM #EST
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------------------
User Function PEBOT006()

    aRet := PARAMIXB[1]

    aADD(aRet,{"Controle Portaria", "U_VA_CPORT", 0, 4,0,.F.})

Return aRet

