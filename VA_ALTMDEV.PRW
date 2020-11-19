//  Programa...: VA_ALTMDEV
//  Autor......: Catia Cardoso
//  Data.......: 13/0/2017
//  Descricao..: Altera motivos de devolucao 66  
// 
//  Historico de alterações
//
//  06/09/2017 - Catia   - inner join no SA2 e deveria ser no SA1 - ai nao mostrava notas para alterar
//  10/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - Arquivo de trabalho
//
// -----------------------------------------------------------------------------------------------------
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_ALTMDEV()

	//Local cArqTRB  	:= ""
	//Local cInd1    	:= ""
	//Local nI       	:= 0
	Local aStruct  	:= {}
	Local aHead 	:= {}
	Local I			:= 0
	
	if ! u_zzuvl ('078', __cUserId, .T.)
		return
	endif
	
	AAdd( aHead, { "Documento"           ,{|| TRB->DOC}       ,"C", 09 , 0, "" } )
	AAdd( aHead, { "Serie"               ,{|| TRB->SERIE}     ,"C", 03 , 0, "" } )
	AAdd( aHead, { "Dt.Emissao"          ,{|| TRB->EMIS}      ,"C", 10 , 0, "" } )
	AAdd( aHead, { "Dt.Digitaçao"        ,{|| TRB->DIGIT}     ,"C", 10 , 0, "" } )
	AAdd( aHead, { "Cliente"             ,{|| TRB->FORNECE}   ,"C", 06 , 0, "" } )
	AAdd( aHead, { "Razao Social"        ,{|| TRB->NOME}      ,"C", 40 , 0, "" } )
	AAdd( aHead, { "Produto"             ,{|| TRB->PRODCOD}   ,"C", 15 , 0, "" } )
	AAdd( aHead, { "Descricao"           ,{|| TRB->PRODDESC}  ,"C", 60 , 0, "" } )
	AAdd( aHead, { "Quantidade"          ,{|| TRB->QUANT}     ,"N", 12 , 2, "@E 9,999,999.99" } )
	AAdd( aHead, { "Mot.Devolucao"       ,{|| TRB->MOTDEV}    ,"C", 02 , 0, "" } )
	AAdd( aHead, { "Descricao Mot."      ,{|| TRB->MOTDEVD}   ,"C", 25 , 0, "" } )
	
	// define estrutura do arquivo de trabalho	
	AAdd( aStruct, { "DOC"       , "C", 09, 0 } )
	AAdd( aStruct, { "SERIE"     , "C", 03, 0 } )
	AAdd( aStruct, { "EMIS"      , "C", 10, 0 } )
	AAdd( aStruct, { "DIGIT"     , "C", 10, 0 } )
	AAdd( aStruct, { "FORNECE"   , "C", 06, 0 } )
	AAdd( aStruct, { "NOME"      , "C", 40, 0 } )
	AAdd( aStruct, { "PRODCOD"   , "C", 15, 0 } )
	AAdd( aStruct, { "PRODDESC"  , "C", 60, 2 } )
	AAdd( aStruct, { "QUANT"     , "N", 12, 2 } )
	AAdd( aStruct, { "MOTDEV"    , "C", 02, 0 } )
	AAdd( aStruct, { "MOTDEVD"   , "C", 25, 0 } )
	AAdd( aStruct, { "LOJA"      , "C", 02, 0 } )
	AAdd( aStruct, { "ITEM"      , "C", 04, 0 } )
	
//	// cria arquivo de trabalho
//	cArqTRB := CriaTrab( aStruct, .T. )
//	dbUseArea( .T., __LocalDriver, cArqTRB, "TRB", .F., .F. )
//	cInd1 := Left( cArqTRB, 7 ) + "1"
//	IndRegua( "TRB", cInd1, "DOC", , , "Criando índices...")
//	
//	dbClearIndex()
//	dbSetIndex( cInd1 + OrdBagExt() )
	
	// cria arquivo de trabalho
	_aArqTrb  := {}
	U_ArqTrb ("Cria", "TRB", aStruct, {"DOC"}, @_aArqTrb)
	
	_sQuery := ""		
	_sQuery += " SELECT SD1.D1_DOC, SD1.D1_SERIE, dbo.VA_DTOC(SD1.D1_EMISSAO), dbo.VA_DTOC(SD1.D1_DTDIGIT)"
	_sQuery += "      , SD1.D1_FORNECE, SA1.A1_NOME, SD1.D1_COD, SB1.B1_DESC"
	_sQuery += "      , SD1.D1_QUANT"
	_sQuery += "      , SD1.D1_MOTDEV"
	_sQuery += "      , SD1.D1_ITEM, SD1.D1_LOJA"
	_sQuery += "	  , ZX502.ZX5_02DESC
	_sQuery += "	  , ZX502.ZX5_02RESP
	_sQuery += "   FROM " + RetSQLName ("SD1") + " SD1 "
	_sQuery += "	  INNER JOIN SA1010 AS SA1"
	_sQuery += "		ON (SA1.D_E_L_E_T_  = ''"
	_sQuery += "			AND SA1.A1_COD  = SD1.D1_FORNECE"
	_sQuery += "			AND SA1.A1_LOJA = SD1.D1_LOJA)"
	_sQuery += "	  INNER JOIN SB1010 AS SB1"
	_sQuery += "		ON (SB1.D_E_L_E_T_ = ''"
	_sQuery += "			AND SB1.B1_COD = SD1.D1_COD)"
	_sQuery += "	  INNER JOIN ZX5010 AS ZX502"
	_sQuery += "		ON (ZX502.ZX5_TABELA = '02'"
	_sQuery += "			AND ZX502.ZX5_02MOT = SD1.D1_MOTDEV)"
	_sQuery += "  WHERE SD1.D_E_L_E_T_ = ''"
	_sQuery += "    AND SD1.D1_FILIAL  = '" + xFilial("SD1") + "'"
	_sQuery += "    AND SD1.D1_TIPO    = 'D'"
	_sQuery += "    AND SD1.D1_MOTDEV  = '66'"
	_sQuery += "    AND SD1.D1_DTDIGIT >= '20170601'"

    _aDados := U_Qry2Array(_sQuery)
	
    if len (_aDados) > 0
		for I=1 to len(_aDados)
			DbSelectArea("TRB")
	        RecLock("TRB",.T.)
	        	TRB->DOC       = _aDados[I,1]
	        	TRB->SERIE     = _aDados[I,2]
	        	TRB->EMIS      = _aDados[I,3]
	        	TRB->DIGIT     = _aDados[I,4]
	        	TRB->FORNECE   = _aDados[I,5]
	        	TRB->NOME      = _aDados[I,6]
	        	TRB->PRODCOD   = _aDados[I,7]
	        	TRB->PRODDESC  = _aDados[I,8]
	        	TRB->QUANT     = _aDados[I,9]
	        	TRB->MOTDEV    = _aDados[I,10]
	        	TRB->ITEM      = _aDados[I,11]
    	        TRB->LOJA      = _aDados[I,12]
	        	TRB->MOTDEVD   = _aDados[I,13]
			MsUnLock()		        
		next
	endif

	Private aRotina   := {}
	private cCadastro := "Altera Motivo de Devolução"
	private _sArqLog  := iif (type ("_sArqLog") == "C", _sArqLog, U_Nomelog ())
	
	aadd (aRotina, {"&Altera Mot.Devolucao" ,"U_ALTMOV()" , 0, 2})
	
	Private cDelFunc := ".T."
	private _sArqLog := U_NomeLog ()
	u_logId ()
	
	dbSelectArea("TRB")
	dbSetOrder(1)
	    
	mBrowse(,,,,"TRB",aHead,,,,,)
	
	TRB->(dbCloseArea())
	u_arqtrb ("FechaTodos",,,, @_aArqTrb) 
Return
//
// --------------------------------------------------------------------------------
User function ALTMOV()
	local _lRet := .T.
	// solicita novo motivo

	if _lRet
		_sOldMOT = TRB->MOTDEV
		_sNewMOT = U_Get ("Motivo Devolução", "C", 3, "@!", "ZX502" , _sOldMot, .F., '.T.')
		
		if _lRet
			reclock ("TRB", .F.)
				TRB->MOTDEV  = _sNewMOT
				
				_sQuery  = ""
				_sQuery += " SELECT ZX5_02DESC"
  				_sQuery += "   FROM ZX5010"
 				_sQuery += "  WHERE ZX5_TABELA = '02'"
   				_sQuery += "    AND ZX5_02MOT  = '" + _sNewMOT + "'" 
				
				_aDados := U_Qry2Array(_sQuery)
     
     			TRB->MOTDEVD = ""
    			if len (_aDados) > 0
    				TRB->MOTDEVD = _aDados[1,1]
    			endif    				 
			msunlock ()      
		endif
		
		// atualiza o arquivo das notas
		DbSelectArea("SD1")
		DbSetOrder(1)
		if DbSeek( xfilial("SD1") + TRB->DOC + TRB->SERIE + TRB->FORNECE + TRB->LOJA + TRB->PRODCOD + TRB->ITEM, .F.)
			reclock ("SD1", .F.)
				SD1 -> D1_MOTDEV = _sNewMOT
			msunlock ()
		endif
	endif
Return
