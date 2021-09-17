//  Programa...: BATCOMPASSOC
//  Autor......: Catia Cardoso
//  Data.......: 08/02/2018
//  Descricao..: Gera titulos no conta corrente / financeiro referente a compra de associados nas lojas
//
//  Tags para automatizar catalogo de customizacoes:
//  #TipoDePrograma    #batch
//  #Descricao         #Gera titulos no conta corrente / financeiro referente a compra de associados nas lojas
//  #PalavasChave      #associados #venda #conta_corrente 
//  #TabelasPrincipais #SA2 #SL1 
//  #Modulos 		  #LOJA 
//
//  Historico de alteracoes:
//  16/19/2021 - Claudia - Alterado o TM de 23 para 04. GLPI: 10948
//
//---------------------------------------------------------------------------------------------------------------

#include "rwmake.ch"

#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function BATCOMPASSOC()
    Local i:= 0
	
	// LE VENDAS DE CUPONS DAS LOJAS - PARA ASSOCIADOS
    _sSQL := " "
    _sSQL += " SELECT"
    _sSQL += " 	   SA2.A2_COD"
    _sSQL += "    ,SA2.A2_LOJA"
    _sSQL += "    ,L1_EMISNF"
    _sSQL += "    ,L4_VALOR"
    _sSQL += "    ,L1_DOC"
    _sSQL += "    ,L1_SERIE"
    _sSQL += "    ,L1_FILIAL"
    _sSQL += "    ,SL1.R_E_C_N_O_"
    _sSQL += " FROM SL1010 AS SL1"
    _sSQL += " INNER JOIN SL4010 AS SL4"
    _sSQL += " 	ON (SL4.D_E_L_E_T_ = ''"
    _sSQL += " 			AND SL4.L4_FILIAL = SL1.L1_FILIAL"
    _sSQL += " 			AND SL4.L4_NUM = SL1.L1_NUM"
    _sSQL += " 			AND SL4.L4_FORMA = 'CO'"
    _sSQL += " 			AND SL4.L4_ADMINIS LIKE '%800%')"
    _sSQL += " INNER JOIN SA2010 AS SA2"
    _sSQL += " 	ON (SA2.D_E_L_E_T_ = ''"
    _sSQL += " 			AND SA2.A2_CGC = SL1.L1_CGCCLI"
    _sSQL += " 			AND SL1.L1_CGCCLI <> ''"
    _sSQL += " 			AND SA2.A2_LOJA = SL1.L1_LOJA)"
    _sSQL += " WHERE SL1.D_E_L_E_T_ = ''"
    _sSQL += " AND SL1.L1_EMISNF > '20190201'"
    _sSQL += " AND SL1.L1_DOC != ''"
    _sSQL += " AND SL1.L1_SERIE != '999'"
    _sSQL += " AND SL1.L1_INDCTB = ''"
    _sSQL += " ORDER BY SL1.L1_EMISNF"

    //u_showmemo(_sSQL)
	_atitger := U_Qry2Array(_sSQL)
	if len(_aTitger) > 0
		for i=1 to len(_atitger)
			// grava conta corrente e financeiro dos associados
			_oCtaCorr := ClsCtaCorr():New ()
			_oCtaCorr:Assoc    = _aTitger[i,1]
			_oCtaCorr:Loja     = _aTitger[i,2]
			_oCtaCorr:TM       = '04'
			_oCtaCorr:DtMovto  = _aTitger[i,3]
			_oCtaCorr:Valor    = _aTitger[i,4]
			_oCtaCorr:SaldoAtu = _aTitger[i,4]
			_oCtaCorr:Usuario  = cUserName
			_oCtaCorr:Histor   = "VENDA PROD.REUNIAO DE NUCLEO"
			_oCtaCorr:MesRef   = strzero(month(_oCtaCorr:DtMovto),2)+strzero(year(_oCtaCorr:DtMovto),4)
			_oCtaCorr:Doc      = _aTitger[i,5]
			_oCtaCorr:Serie    = "INS"
			_oCtaCorr:Origem   = "BATCOMPASSOC"
			_oCtaCorr:Parcela  = ''
			_lContinua         = .T.
			//
			if _oCtaCorr:PodeIncl ()
				//u_help("VOLTOU DO PODE INCLUIR")
				if  _oCtaCorr:Grava (.F., .F.)
					//u_help("VOLTOU DA ROTINA DE GRAVACAO")
					DbSelectArea("SL1")
					dbgoto( _aTitger[i,8] ) // RECNO DO SL1
	        		reclock("SL1", .F.)
	        			SL1->L1_INDCTB := 'S' 
	        		MsUnLock()
	        	endif
	        endif		        			
		next
	endif								
return
