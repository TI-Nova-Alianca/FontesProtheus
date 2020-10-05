//  Programa...: VA_COMDEV
//  Autor......: Cláudia Lionço
//  Cliente....: Alianca
//  Data.......: 02/10/2020
//  Descricao..: Consulta com retorno de dados de devoluções para comissões
//
// #TipoDePrograma    #consulta
// #Descricao         #Consulta com retorno de dados de devoluções para comissões 
// #PalavasChave      #comissoes #devolucoes #representante
// #TabelasPrincipais #SE5 #SA1 
// #Modulos 		  #FIN 
//
//  Historico de alteracoes:
//
// ------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_COMDEV(_dtaIni, _dtaFin, _sVend)
    Local _oSQL    := ClsSQL ():New ()
	Local _aRet    := {}

    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT
    _oSQL:_sQuery += " 	   E5_DATA"
    _oSQL:_sQuery += "    ,E5_NUMERO"
    _oSQL:_sQuery += "    ,E5_PREFIXO"
    _oSQL:_sQuery += "    ,E5_PARCELA"
    _oSQL:_sQuery += "    ,E5_CLIFOR"
    _oSQL:_sQuery += "    ,E5_LOJA"
    //_oSQL:_sQuery += "    ,E5_BENEF"
    _oSQL:_sQuery += "    ,A1_NOME"
    _oSQL:_sQuery += "    ,E5_VALOR"
    _oSQL:_sQuery += "    ,A1_VEND"
    _oSQL:_sQuery += " FROM " + RetSQLName ("SE5") + " SE5 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
    _oSQL:_sQuery += " 	ON (SA1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " 			AND SA1.A1_COD = SE5.E5_CLIFOR"
    _oSQL:_sQuery += " 			AND SA1.A1_LOJA = SE5.E5_LOJA"
    _oSQL:_sQuery += " 			AND SA1.A1_VEND = '" + _sVend + "')"
    _oSQL:_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " AND E5_FILIAL = '" + xFilial('SE5') + "' " 
    _oSQL:_sQuery += " AND E5_DATA  BETWEEN '" + dtos(_dtaIni) + "' AND '" + dtos(_dtaFin) + "'"
    _oSQL:_sQuery += " AND E5_TIPO   = 'NCC'"
    _oSQL:_sQuery += " AND E5_MOTBX  = 'DEB'"
    _oSQL:_sQuery += " AND E5_NATUREZ <> 'VERBAS'"
    _oSQL:_sQuery += " ORDER BY E5_DATA"
    _oSQL:Log ()
	
	_aRet = aclone (_oSQL:Qry2Array ())

Return _aRet
