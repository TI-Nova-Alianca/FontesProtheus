// Programa...: ZB5TRANSF
// Autor......: Cláudia Lionço
// Data.......: 25/02/2021
// Descricao..: Cadastro de batchs para a transferencia bancária
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Cadastro
// #Descricao         #Cadastro de batchs para a transferencia bancária
// #PalavasChave      #conta_bancaria #batchs #transferencia_entre_filiais
// #TabelasPrincipais #ZB5 #ZZ6
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
User Function ZB5TRANSF(_sFilial)

    _oBatch := ClsBatch():new ()
    _oBatch:Dados    = 'Transf.vlr. FL '+ _sFilial +' para CT'
    _oBatch:EmpDes   = cEmpAnt
    _oBatch:FilDes   = _sFilial
    _oBatch:DataBase = dDataBase
    _oBatch:Modulo   = 6 
    _oBatch:Comando  = "U_BatTransf('" + _sFilial + "','" + _sFilial + "')"
    _oBatch:Grava ()

    _oEvento := ClsEvent():New ()
    _oEvento:Alias     = 'ZB5'
    _oEvento:Texto     = "CRIOU BATCH FILIAL-> C.T:" + cEmpAnt +'-' + _sFilial +'-' + dtos(dDataBase) +'-'+ "U_BatTransf('" + _sFilial + "','" + _sFilial + "')"
    _oEvento:CodEven   = "ZB5001"
    _oEvento:Grava()

Return
