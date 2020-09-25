// Programa:  VA_TOTBO
// Autor:     Elaine Ballico
// Data:      04/10/2012
// Cliente:   Alianca
// Descricao: Funcao para buscar o total dos titulos do bordero
//            Criado inicialmente para informar o total geral dos titulos do arquivo .rem do Banrisul
//
// Historico de alteracoes:
//
//

// --------------------------------------------------------------------------
User Function VA_TOTBO (_cNumBor)
	local _xRet      := NIL
    local _cQuery   := " "

                                                                                          
_cQuery := "SELECT  SUM(E1_SALDO) totsaldo,  SUM( E1_ACRESC)  totacres, SUM(E1_DECRESC) totdecres "
_cQuery +=   " FROM  " + RetSQLName ("SE1") + " SE1, " +   RetSQLName ("SEA") + " SEA "
_cQuery +=   " WHERE  EA_NUMBOR = '" + _cNumBor + "'"
_cQuery +=   " AND   EA_FILIAL = E1_FILIAL "
_cQuery +=   " AND   EA_NUM = E1_NUM "
_cQuery +=   " AND   EA_PREFIXO = E1_PREFIXO "
_cQuery +=   " AND   EA_PARCELA = E1_PARCELA "



dbUseArea(.T., "TOPCONN", TCGenQry(,,_cQuery), "TOT", .F., .T.)
dbSelectArea("TOT")           

if  !Eof()                              
   _xRet  := round (TOT -> totsaldo + TOT -> totacres - TOT -> totdecres, 2)
else 
   _xRet  := 0
endif  
                                                                                                                                 
return _xRet
