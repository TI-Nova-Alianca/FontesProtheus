// Programa:   VA_PROCST
// Autor:      Elaine Ballico
// Data:       09/05/2013
// Cliente:    Nova Alianca
// Descricao:  Processa chamada do calculo da ST - unificar rotinas (chamadas do VA_GAT -pedido e lista e chamada do VA_RSTTP)
//                                                                                                                                                            
// Historico de alteracoes:
// 10/12/2013 - Robert - Novo parametro (simples nacional) na funcao CALCST3.
// 25/06/2014 - Catia  - Recalculo e Gatilho da ST - alterada prioridade da UF. Usa DA1_ESTADO e depois DA0_UF

// --------------------------------------------------------------------------
user function VA_PROCST(_pQual, _pCliente, _pLoja, _pTpPed, _pProd, _pTes, _pCFOP, _pQte, _pPreco, _pValor, _pVlrIPI, _pUF, _pPercICM, _pCodTab, _pItem, _sSimples)
	local _aAreaAnt := U_ML_SRArea ()
    Local _sIE      := ""  
    Local _sMEI     := ""
    Local _cQuery   := ""
    Local _sNCM     := ""
    Local _sDados   := ""
    Local _sUF      := ""
    Local _sProduto := ""
    Local _sPreco   := ""
    Local _sVlrIPI  := ""
    //Local _sPerICMP := ""
    //Local _sPerICMF := ""
    Local _sTpCli   := ""
    Local _sTES     := ""              
    Local _sCFOP    := ""   
    Local _sValICM  := ""
    Local _aRet     := {}        
                                 
	U_AvisaTI ('Programa ' + procname () + ', colocado na lista de fuzilamento em 12/09/2015, acaba de ser foi executado por ' + alltrim (cUserName) + '. Reveja sua lista!')
	
	if _pQual == 'P'  // Pedido de Venda
       _cQuery := "  "
       _cQuery += " SELECT A1_INSCR INSCR, A1_VAMEI MEI, A1_TIPO TPCLI, A1_EST UF "
       _cQuery += " FROM "+RetSqlName("SA1")+ " SA1 "
       _cQuery += "  WHERE A1_COD = '" + _pCliente + "'"
       _cQuery += "    AND A1_LOJA = '" + _pLoja + "'"
       _cQuery += "    AND SA1.D_E_L_E_T_ = ' ' " 
   

 	   _sDados = GetNextAlias ()

       DbUseArea(.t.,'TOPCONN',TcGenQry(,,_cQuery), _sDados,.F.,.F.)   
       if !(_sDados) -> (eof ())                           
          _sIE    := (_sDados) -> INSCR
          _sMEI   := (_sDados) -> MEI
          _sTpCli := (_sDados) -> TPCLI
          _sUF    := (_sDados) -> UF
       
       endif
       (_sDados) -> (dbclosearea ())

       if ! _pTpPed $ "BD" .and. (alltrim (upper (_sIE)) != "ISENTO" .or. _sMEI == 'S') .and. cEmpAnt != "02"  // Na Vinicola nao deve calcular.

     	   // Inicializa funcao para buscar valores de impostos.
    	   MaFisIni(_pCliente,;							            // 1-Codigo Cliente/Fornecedor
	                _pLoja,;		                             	// 2-Loja do Cliente/Fornecedor
		            "C",;	                                        // 3-C:Cliente , F:Fornecedor
		            _pTpPed,;	                        			// 4-Tipo da NF
		            _sTpCli,;	                            		// 5-Tipo do Cliente/Fornecedor
		            MaFisRelImp("MT100",{"SF2","SD2"}),;	        // 6-Relacao de Impostos que suportados no arquivo
			                        ,;								// 7-Tipo de complemento
			                        ,;					    		// 8-Permite Incluir Impostos no Rodape .T./.F.
		                       "SB1",;				    			// 9-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
		                       "MATA410")							// 10-Nome da rotina que esta utilizando a funcao
	
    		// Alimenta valores para calculo de impostos
	    	MaFisAdd (_pProd,;                       	  // 1-Codigo do Produto ( Obrigatorio )
		              _pTes,;	                		  // 2-Codigo do TES ( Opcional )
		              _pQte,;                    		  // 3-Quantidade ( Obrigatorio )
		              _pPreco,;		                      // 4-Preco Unitario ( Obrigatorio )
		              0,;                                 // 5-Valor do Desconto ( Opcional )
		              NIL,;		                          // 6-Numero da NF Original ( Devolucao/Benef )
		              NIL,;		                          // 7-Serie da NF Original ( Devolucao/Benef )
		              NIL,;			                      // 8-RecNo da NF Original no arq SD1/SD2
		              0,;					    		  // 9-Valor do Frete do Item ( Opcional )
		              0,;						    	  // 10-Valor da Despesa do item ( Opcional )
		              0,;            				      // 11-Valor do Seguro do item ( Opcional )     
     		          0,;							      // 12-Valor do Frete Autonomo ( Opcional )
	     	          _pValor,;                           // 13-Valor da Mercadoria ( Obrigatorio )
		              0,;							      // 14-Valor da Embalagem ( Opiconal )
		              0,;		     				      // 15-RecNo do SB1
		              0) 							      // 16-RecNo do SF4


    	   _aRet := aclone (U_CalcST3 (_pProd, _sUF, (_pPreco * _pQte), mafisret (1, "IT_VALIPI"), mafisret (1, "IT_VALICM"), dDatabase, _pQte, _pCFOP, _pTES, _sIE, _sMEI, _sSimples))
	
           // Limpa variaveis da rotina de calculo de impostos.
	       MaFisEnd()
       endif                                                                                       
	   



	elseif _pQual $ 'LR' // Lista de Preco                                                                      
        if _pQual == 'R'	    
           _cQuery := "  "
           _cQuery := "SELECT DA1_FILIAL FIL, DA1_CODPRO PROD, DA1_CODTAB TAB, DA1_ITEM IT," 
           _cQuery += "        DA1_ESTADO, DA1_ICMS, DA0_VAUF, DA0_ICMS, DA1_PRCVEN PRECO,"
	        _cQuery += "        DA1_IPI VLRIPI, DA0.R_E_C_N_O_,"
	        _cQuery += "        B1_POSIPI NCM "
	        _cQuery += " FROM  " + RetSQLName ("DA1") + " DA1, " 
	        _cQuery += + RetSQLName ("DA0") + " DA0, " 
	        _cQuery += + RetSQLName ("SB1") + " SB1 "
	        _cQuery += " WHERE DA1_CODTAB = '" + _pCodTab + "'"
	        _cQuery += "   AND DA1_ITEM = '" + _pItem + "'"
	        _cQuery += "   AND DA1.DA1_FILIAL = '" + xfilial ("DA1") + "'"
	        _cQuery += "   AND DA0.DA0_FILIAL = '" + xfilial ("DA0") + "'"
	        _cQuery += "   AND DA0.DA0_FILIAL = DA1.DA1_FILIAL "
	        _cQuery += "   AND DA1.DA1_CODPRO = SB1.B1_COD "
	        _cQuery += "   AND DA1.D_E_L_E_T_ = ' ' "
	        _cQuery += "   AND DA0.D_E_L_E_T_ = ' ' "
	        _cQuery += "   AND SB1.D_E_L_E_T_ = ' ' "
	        _cQuery += "   AND DA1_CODTAB = DA0_CODTAB "

 	       _sDados = GetNextAlias ()

           DbUseArea(.t.,'TOPCONN',TcGenQry(,,_cQuery), _sDados,.F.,.F.)   

           if !(_sDados) -> (eof ())
              // usa UF e %ICMS da linha de ITENS                         
              _sUF      := (_sDados) -> DA1_ESTADO
              _sPerICM  := (_sDados) -> DA1_ICMS
              // se nao tiver a UF informada na linha de itens - usa UF e %ICMS do cabeçalho da tabela
              if empty(_sUF)
                 _sUF      := (_sDados) -> DA0_VAUF
                 _sPerICM  := (_sDados) -> DA0_ICMS
              endif
              _sProduto := (_sDados) -> PROD
              _sPreco   := (_sDados) -> PRECO
              _sVlrIPI  := iif(_pVlrIPI >0, _pVlrIPI, (_sDados) -> VLRIPI)
              _sNCM     := (_sDados) -> NCM
           endif
           (_sDados) -> (dbclosearea ())

    	    
        else   // _pQual == "L"
           _cQuery := "  "
           _cQuery := "SELECT B1_POSIPI NCM "
	       _cQuery += "   FROM  " + RetSQLName ("SB1") + " SB1 "
	       _cQuery += "  WHERE B1_COD = '" + _pProd + "'"
	       _cQuery += "    AND B1_FILIAL = '" + xfilial ("SB1") + "'"
	       _cQuery += "    AND SB1.D_E_L_E_T_ = ' ' "

 	       _sDados = GetNextAlias ()

           DbUseArea(.t.,'TOPCONN',TcGenQry(,,_cQuery), _sDados,.F.,.F.)   
           if !(_sDados) -> (eof ())                         
              _sNCM     := (_sDados) -> NCM
           endif
           (_sDados) -> (dbclosearea ())
        
           _sUF      := _pUF
           _sProduto := _pProd
           _sPreco   := _pPreco
           _sVlrIPI  := _pVlrIPI
           _sPerICM  := _pPercICM       

        endif   

      // bloco comum ao recalculo e ao gatilho por lista
	   if !empty(_sUF) .and. ! empty(_sProduto) .and. _sPreco > 0
                                                                   
		  if _sVlrIPI  == 0
 		     _sTES := "807"
		  else
 		     _sTES := "801"
		  endif                                                   
        
		  if _sUF == 'PR' .and. !substr(_sNCM,1,4) $ '2009'  // Se lista for do Parana e produto diferente de suco, usa TES especifica
		     _sTES := "902"
       endif

       DbSelectArea("SF4")
       DbSetOrder(1)
       DbSeek(xFilial("SF4")+_sTES,.F.)
       If Found()
 	       _sCFOP := SF4->F4_CF
       Else
  	       _sCFOP := ""
       Endif


       if _sUF == 'EX'
          _sCFOP := "7" + substr(_sCFOP,2,3)
       elseif GetMv("mv_estado") <> _sUF
          _sCFOP := "6" + substr(_sCFOP,2,3)
       endif
		  _sValICM = _sPreco * _sPerICM / 100
		  _aRet := aclone (U_CalcST3 (_sProduto, _sUF, _sPreco, _sVlrIPI, _sValICM, dDatabase, 1, _sCFOP, _sTES, '', '', _sSimples))

    endif
	
	endif

	U_ML_SRArea (_aAreaAnt)
	//u_logFim ()
return _aRet
