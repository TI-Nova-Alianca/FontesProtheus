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
// 08/09/2022 - Claudia - Incluida a data de cancelamento da baixa de verbas. GLPI: 12575
// 29/08/2023 - Claudia - Ajustes de devoluções/compensação. GLPI: 13795
//
// -----------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_COMDEV(_dtaIni, _dtaFin, _sVend)
    Local _oSQL    := ClsSQL ():New ()
	Local _aRet    := {}

    _dtaAnt := DaySub(_dtaFin,180) // diminui 6 meses

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
    _oSQL:_sQuery += "    ,(SELECT"
	_oSQL:_sQuery += " 			SUM(E1_COMIS1) / COUNT(*)"
	_oSQL:_sQuery += " 		FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " 		WHERE SE1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND SE1.E1_CLIENTE = SE5.E5_CLIFOR"
	_oSQL:_sQuery += " 		AND SE1.E1_LOJA = SE5.E5_LOJA"
	_oSQL:_sQuery += " 		AND SE1.E1_COMIS1 <> 0"
	_oSQL:_sQuery += " 		AND SE1.E1_VEND1 = '"+alltrim(_sVend)+"'"
	_oSQL:_sQuery += " 		AND SE1.E1_EMISSAO BETWEEN '" + dtos(_dtaAnt) + "' AND '" + dtos(_dtaFin) + "'"
	_oSQL:_sQuery += " 	)"
	_oSQL:_sQuery += " 	AS PERCENTUAL"
    _oSQL:_sQuery += "    ,E5_VALOR * (SELECT"
	_oSQL:_sQuery += " 			SUM(E1_COMIS1) / COUNT(*)"
	_oSQL:_sQuery += " 		FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " 		WHERE SE1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND SE1.E1_CLIENTE IN (SELECT"
	_oSQL:_sQuery += " 				SA1.A1_COD"
	_oSQL:_sQuery += " 			FROM " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 			WHERE SA1. D_E_L_E_T_ = '' AND SA1.A1_VACBASE = (SELECT "
	_oSQL:_sQuery += " 					SA11.A1_VACBASE "
	_oSQL:_sQuery += " 				FROM " + RetSQLName ("SA1") + " SA11 "
	_oSQL:_sQuery += " 				WHERE SA11. D_E_L_E_T_ = '' AND SA11.A1_COD = SE5.E5_CLIFOR "
	_oSQL:_sQuery += " 				AND SA11.A1_LOJA = SE5.E5_LOJA))"
	_oSQL:_sQuery += " 		AND SE1.E1_LOJA = SE5.E5_LOJA"
	_oSQL:_sQuery += " 		AND SE1.E1_COMIS1 <> 0 "
	_oSQL:_sQuery += " 		AND SE1.E1_VEND1 = '" + alltrim(_sVend) + "'"
	_oSQL:_sQuery += " 		AND SE1.E1_EMISSAO BETWEEN '" + dtos(_dtaAnt) + "' AND '" + dtos(_dtaFin) + "')"
	_oSQL:_sQuery += " 	/ 100 * -1 AS COMISSAO"
    _oSQL:_sQuery += "    ,E5_RECPAG RECPAG "
    _oSQL:_sQuery += "    ,E5_MOTBX MOTBX "
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
    _oSQL:_sQuery += " AND E5_MOTBX IN ('DEB','CMP') " // = 'DEB'
    _oSQL:_sQuery += " AND E5_NATUREZ <> 'VERBAS'"
    _oSQL:_sQuery += " AND E5_DTCANBX = '' "
    _oSQL:_sQuery += " ORDER BY E5_DATA"
    _oSQL:Log ()
	
	_aRet = aclone (_oSQL:Qry2Array ())

Return _aRet
