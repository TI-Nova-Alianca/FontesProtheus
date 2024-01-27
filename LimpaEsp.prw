// Programa.:  LimpaEsp
// Autor....:  Cláudia Lionço
// Data.....:  11/07/2023
// Descricao:  Limpa caracteres especiais de campo
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Limpa caracteres especiais de campo
// #PalavasChave      #limpa #caracteres_especiais #caracteres #especiais
// #TabelasPrincipais 
// #Modulos           #TODOS
//
// Historico de alteracoes:
// 25/01/2024 - Alteração validação dos caracteres º,ª,__,Â, conforme GLPI (14808)
// ---------------------------------------------------------------------------------------------------------
User Function LimpaEsp(cConteudo)
    Local aArea       := GetArea()

    //Retirando caracteres
    cConteudo := StrTran(cConteudo, "'" , "")
    cConteudo := StrTran(cConteudo, "#" , "")
    cConteudo := StrTran(cConteudo, "%" , "")
    cConteudo := StrTran(cConteudo, "*" , "")
    cConteudo := StrTran(cConteudo, "&" , "E")
    cConteudo := StrTran(cConteudo, ">" , "")
    cConteudo := StrTran(cConteudo, "<" , "")
    cConteudo := StrTran(cConteudo, "!" , "")
    cConteudo := StrTran(cConteudo, "@" , "")
    cConteudo := StrTran(cConteudo, "$" , "")
    cConteudo := StrTran(cConteudo, "(" , "")
    cConteudo := StrTran(cConteudo, ")" , "")
    cConteudo := StrTran(cConteudo, "_" , "")
    cConteudo := StrTran(cConteudo, "=" , "")
    cConteudo := StrTran(cConteudo, "+" , "")
    cConteudo := StrTran(cConteudo, "{" , "")
    cConteudo := StrTran(cConteudo, "}" , "")
    cConteudo := StrTran(cConteudo, "[" , "")
    cConteudo := StrTran(cConteudo, "]" , "")
    cConteudo := StrTran(cConteudo, "/" , "")
    cConteudo := StrTran(cConteudo, "?" , "")
    cConteudo := StrTran(cConteudo, "." , "")
    cConteudo := StrTran(cConteudo, "\" , "")
    cConteudo := StrTran(cConteudo, "|" , "")
    cConteudo := StrTran(cConteudo, ":" , "")
    cConteudo := StrTran(cConteudo, ";" , "")
    cConteudo := StrTran(cConteudo, '"' , "")
    cConteudo := StrTran(cConteudo, "°" , "")
    cConteudo := StrTran(cConteudo, "ª" , "")
    cConteudo := StrTran(cConteudo, "--", "")
    cConteudo := StrTran(cConteudo, "Â" , "")
     
    RestArea(aArea)
Return cConteudo
