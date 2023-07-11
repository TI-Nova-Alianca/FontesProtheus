// Programa.:  LimpaEsp
// Autor....:  Cl�udia Lion�o
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
//
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
    cConteudo := StrTran(cConteudo, '"' , '')
    cConteudo := StrTran(cConteudo, '�' , '')
    cConteudo := StrTran(cConteudo, '�' , '')
    cConteudo := StrTran(cConteudo, '--', '')
    cConteudo := StrTran(cConteudo, '�',  '')
     
    RestArea(aArea)
Return cConteudo
