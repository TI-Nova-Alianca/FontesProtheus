// Programa.: F240CAN
// Autor....: Cláudia Lionço
// Data.....: 11/10/2024
// Descricao: P.E. Tratamento de cancelamento de borderô
// 
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. Tratamento de cancelamento de borderô
// #PalavasChave      #bordero #associados
// #TabelasPrincipais #SE2
// #Modulos           #FIN

// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------------
User Function F240CAN()

    _oSQL := ClsSQL():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " UPDATE SZI010 SET ZI_BORDERO = '' "
    _oSQL:_sQuery += " WHERE ZI_FILIAL = '" + xfilial("SE2") + "' "
    _oSQL:_sQuery += " AND ZI_BORDERO  = '" + xfilial("SE2") + mv_par01	 + "' "
    _oSQL:Exec ()

Return
