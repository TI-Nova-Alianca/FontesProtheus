// Programa..: VA_DA0MAIL
// Autor.....: Cl�udia Lion�o
// Data......: 15/12/2023
// Descricao.: E-mail de altera��o de tabelas de pre�o
//
// #TipoDePrograma    #relatorio
// #PalavasChave      #E-mail de altera��o de tabelas de pre�o
// #TabelasPrincipais #DA0 #DA1
// #Modulos 		  #FAT
//
// Historico de alteracoes:
// 20/12/2023 - Claudia - Programa passa enviar e-mail por batch. GLPI: 14643
// 06/02/2024 - Claudia - Incluida coluna de descricao. GLPI: 14848
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_DA0MAIL()
	Local _aAreaAnt := U_ML_SRArea ()
	Local _oSQL     := NIL
	Local _sMsg     := ""
	Local _dData    := Date()
	

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT"
    _oSQL:_sQuery += " 	     CODIGO_ALIAS "
	_oSQL:_sQuery += "      ,DA0.DA0_DESCRI "
    _oSQL:_sQuery += " 	    ,USUARIO "
    _oSQL:_sQuery += " 	    ,TRIM(PRODUTO) "
    _oSQL:_sQuery += " 	    ,TRIM(DESCRITIVO) "
    _oSQL:_sQuery += " FROM VA_VEVENTOS "
	_oSQL:_sQuery += " INNER JOIN DA0010 DA0 "
	_oSQL:_sQuery += " 	ON DA0.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND DA0.DA0_FILIAL = FILIAL "
	_oSQL:_sQuery += " 		AND DA0.DA0_CODTAB = CODIGO_ALIAS "
    _oSQL:_sQuery += " WHERE (CODEVENTO LIKE ('%DA0%') "
    _oSQL:_sQuery += " OR CODEVENTO LIKE ('%DA1%')) "
    _oSQL:_sQuery += " AND DATA = '"+dtos(_dData)+"' "
    _oSQL:_sQuery += " ORDER BY DATA, HORA, CODIGO_ALIAS "
	
	u_log (_oSQL:_sQuery)
	
	If Len (_oSQL:Qry2Array (.F., .F.)) > 0
		_aCols := {}
		
	   AADD (_aCols, {'TABELA' 		, 'left',  ''})
	   AADD (_aCols, {'DESCRICAO' 	, 'left',  ''})
	   AADD (_aCols, {'USUARIO'		, 'left',  ''})
	   AADD (_aCols, {'PRODUTO'		, 'left',  ''})
       AADD (_aCols, {'OBS'    		, 'left',  ''})

		_sMsg = _oSQL:Qry2HTM ("Altera��o de tabela de pre�o  - Data " + DTOC(_dData), _aCols, "", .F.,.T.)
		U_ZZUNU ({'156'}, "Altera��o de tabela de pre�o  - Data " + DTOC(_dData) , _sMsg, .F.)
	EndIf

	U_ML_SRArea (_aAreaAnt)
Return .T.
