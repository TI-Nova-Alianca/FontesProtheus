//  Programa...: BATTITBAI
//  Autor......: Cláudia Lionço
//  Data.......: 21/07/2020
//  Descricao..: Baixa de titulos de mudas de uvas para associados
// 
//  #TipoDePrograma    #Batch
//  #PalavasChave      #titulos #baixa #mudas_de_uvas #associados #venda
//  #TabelasPrincipais #SE1 #SF2 #SD2
//  #Modulos 		  #FIN 
//
//  Historico de alteracoes:
//
// ------------------------------------------------------------------------------------

#include 'protheus.ch'
#include 'parmtype.ch'

user function BATTITBAI()
	Local i        := 0 
	Local _aTitulo := {}
	
	// VERIFICA TITULOS DE VENDAS DE MUDAS PARA ASSOCIADOS PARA REALIZAR A BAIXA
	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""

	_oSQL:_sQuery += " SELECT DISTINCT"
	_oSQL:_sQuery += " 	   SE1.E1_FILIAL"
	_oSQL:_sQuery += "    ,SE1.E1_PREFIXO"
	_oSQL:_sQuery += "    ,SE1.E1_NUM"
	_oSQL:_sQuery += "    ,SE1.E1_PARCELA"
	_oSQL:_sQuery += "    ,SE1.E1_VALOR"
	_oSQL:_sQuery += "    ,SE1.E1_CLIENTE"
	_oSQL:_sQuery += "    ,SE1.E1_LOJA"
	_oSQL:_sQuery += "    ,SE1.E1_EMISSAO"
	_oSQL:_sQuery += "    ,SE1.E1_TIPO"
	_oSQL:_sQuery += "    ,SE1.E1_BAIXA"
	_oSQL:_sQuery += "    ,SE1.E1_SALDO"
	_oSQL:_sQuery += "    ,SE1.E1_STATUS "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " AS SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SD2") + " AS SD2 "
	_oSQL:_sQuery += " 	ON (SD2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND D2_COD IN ('7206', '7207')"
	_oSQL:_sQuery += " 			AND D2_FILIAL  = SE1.E1_FILIAL"
	_oSQL:_sQuery += " 			AND D2_DOC     = SE1.E1_NUM"
	_oSQL:_sQuery += " 			AND D2_SERIE   = SE1.E1_PREFIXO"
	_oSQL:_sQuery += " 			AND D2_CLIENTE = SE1.E1_CLIENTE"
	_oSQL:_sQuery += " 			AND D2_LOJA    = SE1.E1_LOJA)"
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND E1_BAIXA = ''"
	_oSQL:_sQuery += " AND E1_STATUS <> 'B'"
	_oSQL:_sQuery += " AND E1_SALDO <> 0"
     
	_aTitulo := aclone (_oSQL:Qry2Array ())
	
	If len(_aTitulo) > 0
	    
		For i:=1 to len(_aTitulo)	
			lMsErroAuto := .F.

			// executar a rotina de baixa automatica do SE1 gerando o SE5
			_aAutoSE1 := {}
			aAdd(_aAutoSE1, {"E1_FILIAL" 	, _aTitulo[i,1]	    				, Nil})
			aAdd(_aAutoSE1, {"E1_PREFIXO" 	, _aTitulo[i,2]	    				, Nil})
			aAdd(_aAutoSE1, {"E1_NUM"     	, _aTitulo[i,3]	    				, Nil})
			aAdd(_aAutoSE1, {"E1_PARCELA" 	, _aTitulo[i,4]	    				, Nil})
			aAdd(_aAutoSE1, {"E1_CLIENTE" 	, _aTitulo[i,6] 					, Nil})
			aAdd(_aAutoSE1, {"E1_LOJA"    	, _aTitulo[i,7] 					, Nil})
			aAdd(_aAutoSE1, {"E1_TIPO"    	, _aTitulo[i,9] 					, Nil})
			AAdd(_aAutoSE1, {"AUTMOTBX"		, 'DACAO'  							, Nil})
			AAdd(_aAutoSE1, {"AUTAGENCIA"  	, '.    ' 		    				, Nil})
			AAdd(_aAutoSE1, {"AUTCONTA"  	, '.         '      				, Nil})
			AAdd(_aAutoSE1, {"AUTDTBAIXA"	, _aTitulo[i,8] 					, Nil})
			AAdd(_aAutoSE1, {"AUTDTCREDITO"	, _aTitulo[i,8] 					, Nil})
			AAdd(_aAutoSE1, {"AUTHIST"   	, 'Vlr.recebido da venda de mudas'	, Nil})
			AAdd(_aAutoSE1, {"AUTDESCONT"	, 0         						, Nil})
			AAdd(_aAutoSE1, {"AUTMULTA"  	, 0         						, Nil})
			AAdd(_aAutoSE1, {"AUTJUROS"  	, 0         						, Nil})
			AAdd(_aAutoSE1, {"AUTVALREC"  	, _aTitulo[i,5] 					, Nil})
			
		   _aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))  // orderna conforme dicionário de dados
		   
		   cPerg = 'FIN070'
		   _aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
		   U_GravaSX1 (cPerg, "01", 2)
		   U_GravaSX1 (cPerg, "04", 2)
			
           MSExecAuto({|x,y| Fina070(x,y)},_aAutoSE1,3,.F.,5) // rotina automática para baixa de títulos
			
//           If lMsErroAuto
//           		MostraErro()
//           		Return()
//		   Endif  
			
		   U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina
		   
		Next
	Endif			
Return