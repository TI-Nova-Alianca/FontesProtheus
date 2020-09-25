//  Programa...: ML_DOCTRANS
//  Autor......: Catia Cardoso
//  Data.......: 14/09/2015
//  Descricao..: Documentos emitidos para Cooperativa que ainda não foi dado entrada no sistema - ja temos o XML e nao no SF1 
// 
//  Historico de alterações
//  

#include "rwmake.ch"
#include "VA_INCLU.prw"

User function ML_DOCTRANS()

   	// seleciona clientes com dta de vencimento de credito igual informada no parametro 01 
   	_sQuery := " "
   	_sQuery := "SELECT ZZX.ZZX_EMISSA"
	_sQuery += " 	 , ZZX.ZZX_FILIAL"
	_sQuery += " 	 , ZZX.ZZX_CLIFOR"
	_sQuery += " 	 , ZZX.ZZX_LOJA"
	_sQuery += " 	 , ZZX.ZZX_TIPONF"
	_sQuery += " 	 , ZZX.ZZX_DOC"
	_sQuery += " 	 , ZZX.ZZX_SERIE"
	_sQuery += " 	 , ZZX.ZZX_CHAVE"
  	_sQuery += "  FROM ZZX010 AS ZZX"
 	_sQuery += " WHERE D_E_L_E_T_=''"
   	_sQuery += "   AND ZZX.ZZX_DTIMP >= '20150801'" // antes disso nao interessa - inclusive pode ser diminiuido o perido de vez em quando
   	_sQuery += "   AND ZZX.ZZX_CHAVE != ''"
   	//_sQuery += "AND ZZX.ZZX_RETSEF = '100'" 
    _sQuery += "   AND NOT EXISTS (SELECT SF1.F1_DOC"
	_sQuery += "				     FROM SF1010 AS SF1"
	_sQuery += "				    WHERE SF1.D_E_L_E_T_=''"
	_sQuery += "				      AND SF1.F1_CHVNFE = ZZX.ZZX_CHAVE)"
	_sQuery += "ORDER BY ZZX_DTIMP DESC"
   	 	
    //u_showmemo (_sQuery)
    	
    _aDados := U_Qry2Array(_sQuery)
    if len(_aDados) > 0 
    	_aCols = {}
       	aadd (_aCols, {1,  "Dt.Emissao"     	   ,  30,  "@!"})
	   	aadd (_aCols, {2,  "Filial"         	   ,  10,  "@!"})
	   	aadd (_aCols, {3,  "Fornecedor/Cliente"	   ,  30,  "@D"})
	   	aadd (_aCols, {4,  "Loja"          	       ,  30,  "@!"})
	   	aadd (_aCols, {5,  "Razão Social"   	   , 100,  "@!"})
	   	aadd (_aCols, {6,  "Tipo Doc"  	  	       ,  10,  "@!"})
		aadd (_aCols, {7,  "Documento"  	  	   ,  30,  "@!"})
	   	aadd (_aCols, {8,  "Serie"          	   ,  10,  "@!"})
	   	aadd (_aCols, {9,  "Chave"  	   		   , 100,  "@!"})	
	   	
	   	U_F3Array (_aDados, "Consulta Notas X Conhecimentos", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
	else
		msgalert("Não foram encontrados dados para consulta")
	endif    		
	
return