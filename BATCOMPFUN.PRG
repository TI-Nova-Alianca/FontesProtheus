// Programa...: BATCOMPFUN
// Autor......: Catia Cardoso
// Data.......: 14/10/2015
// Cliente....: Alianca
// Descricao..: lança na contabilidade - os valores referente a compra de funcionarios nas lojas
//
// Escopo: Le arquivo de cupons, seleciona o que for condição 997 = Desconto em folha
//          Esse programa roda por bat. Roda uma vez para cada filial por conta do lcto da CTB
//          e, verifica pra filial que esta lendo compras em todas as lojas 08, 10 e 13
//
// Historico de alteracoes:
// 
// 24/10/2016 - Catia   - Alterada Query de L1_EMISSAO para L1_EMISNF - por conta de cupom com data de orçamento diferente da data de emissao da NF
// 28/03/2017 - Catia   - Verificada alteracao prevendo o camp novo da situacao ao inves da data de desligamento
// 25/10/2018 - Catia   - Alterada integracao que considere a reimplantação das lojas - cond 997 e forma de pagamento
// 08/04/2019 - Catia   - include TbiConn.ch 
// 02/05/2022 - Claudia - Ajustada query para contabilidade de compras de funcionarios.
// 30/06/2022 - Claudia - Retirada CDOC do execauto e validação de filial. GLPI: 12294
//
// ------------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "Totvs.ch"
#Include "TbiConn.ch"

User Function BATCOMPFUN()
    Local _oSQL     := ClsSQL ():New ()
    Local _nQtdDias := 15
    Local _dDtIni   := dtos(DaySub(Date(), _nQtdDias))
    Local _dDtFim   := dtos(Date())
    //Local _dDtIni   := dtos(ddatabase)
    //Local _dDtFim   := dtos(ddatabase)
    Local _x         := 0

    //u_help(_dDtIni)

    If dtos(ddatabase) > '20220420' // Implantação da contabilização de associados
        
        // VERIFICA SE TODOS CUPONS POSSUEM CPF
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += " 	   SL1.L1_CLIENTE "
        _oSQL:_sQuery += "    ,SL1.L1_LOJA "
        _oSQL:_sQuery += "    ,SL1.L1_FILIAL "
        _oSQL:_sQuery += "    ,SL1.L1_NUM "
        _oSQL:_sQuery += "    ,SL4.L4_ADMINIS "
        _oSQL:_sQuery += " FROM " + RetSQLName ("SL4") + " SL4 "
        _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SL1") + " SL1 "
        _oSQL:_sQuery += " 	ON (SL1.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 			AND SL1.L1_FILIAL = SL4.L4_FILIAL "
        _oSQL:_sQuery += " 			AND SL1.L1_NUM    = SL4.L4_NUM "
        _oSQL:_sQuery += " 			AND SL1.L1_VACGC  = '') "
        _oSQL:_sQuery += " WHERE SL4.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND SL4.L4_DATA BETWEEN '" + _dDtIni + "' AND '" + _dDtFim + "'"
        _oSQL:_sQuery += " AND SL4.L4_FORMA = 'CO' "
        _oSQL:_sQuery += " AND (SL4.L4_ADMINIS LIKE '%900%' " // FUNCIONARIOS
        _oSQL:_sQuery += " OR SL4.L4_ADMINIS LIKE '%800%') "  // ASSOCIADOS
	    _oSQL:Log()
		_aDados := aclone(_oSQL:Qry2Array ())

		If len(_aDados) > 0
			For _x := 1 to len(_aDados)
				DbSelectArea("SL1")
				DbSetOrder(1)
				If DbSeek(_aDados[_x,3] + _aDados[_x,4],.F.)
					reclock("SL1", .F.)
						_sCgc = fBuscaCpo('SA1', 1, xfilial('SA1') + _aDados[_x,1] + _aDados[_x,2], "A1_CGC")
						SL1->L1_VACGC  := _sCgc  
		        		SL1->L1_CGCCLI := _sCgc 
		        	MsUnLock()
		        EndIf	
	        Next	
		EndIf

        // LE VENDAS DE CUPONS DAS LOJAS - PARA FUNCIONARIOS QUE ESTA RODANDO O BATH
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += " 	   SL1.L1_FILIAL "
        _oSQL:_sQuery += "    ,SL1.L1_EMISNF "
        _oSQL:_sQuery += "    ,SL4.L4_VALOR "
        _oSQL:_sQuery += "    ,SL1.L1_CONTATO "
        _oSQL:_sQuery += "    ,SL1.L1_VACGC "
        _oSQL:_sQuery += "    ,ZAD.ZAD_FFILIA "
        _oSQL:_sQuery += "    ,ZAD.ZAD_NOME "
        _oSQL:_sQuery += "    ,SL1.L1_DOC "
        _oSQL:_sQuery += "    ,SL1.L1_NUM "
        _oSQL:_sQuery += " FROM " + RetSQLName ("SL1") + " SL1 "
        _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SL4") + " SL4 "
        _oSQL:_sQuery += " 	ON (SL4.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 			AND SL4.L4_FILIAL = SL1.L1_FILIAL "
        _oSQL:_sQuery += " 			AND SL4.L4_NUM    = SL1.L1_NUM "
        _oSQL:_sQuery += " 			AND SL4.L4_FORMA  = 'CO' "
        _oSQL:_sQuery += " 			AND SL4.L4_ADMINIS LIKE '%900%') "
        _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF2") + " SF2 "
        _oSQL:_sQuery += " 	ON (SF2.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 			AND SF2.F2_FILIAL  = L1_FILIAL "
        _oSQL:_sQuery += " 			AND SF2.F2_DOC     = L1_DOC "
        _oSQL:_sQuery += " 			AND SF2.F2_SERIE   = L1_SERIE "
        _oSQL:_sQuery += " 			AND SF2.F2_EMISSAO = L1_EMISNF) "
        _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("ZAD") + " ZAD "
        _oSQL:_sQuery += " 	ON (ZAD.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 			AND ZAD.ZAD_FFILIA = '"+xFilial("SL1")+"'" 
        _oSQL:_sQuery += " 			AND ZAD.ZAD_CPF = L1_CGCCLI) "
        _oSQL:_sQuery += " WHERE SL1.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND SL1.L1_EMISNF BETWEEN '" + _dDtIni + "' AND '" + _dDtFim + "'"
        _oSQL:_sQuery += " AND SL1.L1_DOC != '' "
        _oSQL:_sQuery += " AND SL1.L1_INDCTB = '' "
        //_oSQL:_sQuery += " AND SL1.L1_INDCTB = 'N' "
        _oSQL:_sQuery += " ORDER BY SL1.L1_EMISNF "
        _oSQL:Log()
        _aDados := aclone(_oSQL:Qry2Array ())

        If len(_aDados) > 0  
            For _x := 1 to len(_aDados)
                _sFilvend := _aDados[_x,1]
                _sData    := _aDados[_x,2]
                _nValor   := _aDados[_x,3]
                _sHist    := "ADTO COMPRAS LOJA - " + _aDados[_x,7] 
                _sData    := _aDados[_x,2]
                _sFilfunc := _aDados[_x,6]
                _sDoc     := _aDados[_x,8]
                _nNum     := _aDados[_x,9]
                _sIndCtb  := 'N'

                // Define contas
                //If _sFilvend != _sFilfunc
                    lMsErroAuto := .F.
                    lMsHelpAuto := .T.

                    _aAutoCT2C := {}
                    AADD(_aAutoCT2C,  {'DDATALANC'     , _sData         , NIL} )
                    AADD(_aAutoCT2C,  {'CLOTE'         ,'555555'        , NIL} )
                    AADD(_aAutoCT2C,  {'CSUBLOTE'      ,'001'           , NIL} )
                    //AADD(_aAutoCT2C,  {'CDOC'          ,_sDoc           , NIL} )
                    AADD(_aAutoCT2C,  {'CPADRAO'       ,''              , NIL} )
                    AADD(_aAutoCT2C,  {'NTOTINF'       ,0               , NIL} )
                    AADD(_aAutoCT2C,  {'NTOTINFLOT'    ,0               , NIL} )
                    _aAutoCT2I := {}
                    _aLinhaCT2 := {}
                    AADD(_aLinhaCT2,  {'CT2_LINHA'      , '001'          , NIL})
                    AADD(_aLinhaCT2,  {'CT2_MOEDLC'     , '01'           , NIL})
                    AADD(_aLinhaCT2,  {'CT2_DC'         , '3'            , NIL})
                    AADD(_aLinhaCT2,  {'CT2_DEBITO'     , '101020701006' , NIL})
                    AADD(_aLinhaCT2,  {'CT2_CREDIT'     , '101010201099' , NIL})
                    AADD(_aLinhaCT2,  {'CT2_VALOR'      , _nValor        , NIL})
                    AADD(_aLinhaCT2,  {'CT2_ORIGEM'     , 'BATCOMPFUN'   , NIL})
                    AADD(_aLinhaCT2,  {'CT2_HIST'       , _sHist         , NIL})
                    AADD(_aAutoCT2I, aclone (_aLinhaCT2))

                    MSExecAuto({|x, y,z| CTBA102(x,y,z)}, _aAutoCT2C ,_aAutoCT2I, 3)

                    If lMSErroAuto
                        _sErro := memoread (NomeAutoLog ())
                        u_help (_sErro)

                        _oEvento := ClsEvent():New ()
                        _oEvento:Alias   = "BAT"
                        _oEvento:Texto   = "ERRO: BatCtbCom - Lcto contabil gerado com sucesso " + _aDados[_x,5] 
                        _oEvento:CodEven = "BAT002"
                        _oEvento:Grava()
                    Else
                        u_log ('lcto contabil gerado')
                        _sIndCtb := 'S'

                        _oEvento := ClsEvent():New ()
                        _oEvento:Alias   = "BAT"
                        _oEvento:Texto   = "BatCtbCom - Lcto contabil gerado com sucesso " + _aDados[_x,5] 
                        _oEvento:CodEven = "BAT001"
                        _oEvento:Grava()
                    EndIf                    
                //EndIf

                DbSelectArea("SL1")
                DbSetOrder(1)
                if DbSeek(_sFilvend + _nNum ,.F.)
                    reclock("SL1", .F.)
                        SL1->L1_INDCTB := _sIndCtb 
                    MsUnLock()
                endif        		
            Next
	    EndIf	
    EndIf
Return 

// #include "colors.ch"
// #Include "Protheus.ch"
// #Include "RwMake.ch"
// #Include "TbiConn.ch"

// #IFNDEF WINDOWS
//     #DEFINE PSAY SAY
// #ENDIF

// User function BATCOMPFUN()
// Local i := 0

// 	if dtos(ddatabase) > '20181031'  // PALEATIVO PARA GARANTIR QUE TODAS AS VENDAS DE FUNCIONARIO TERAO CPF
// 		_sSQL := " "
// 		_sSQL += " 	SELECT SL1.L1_CLIENTE, SL1.L1_LOJA, SL1.L1_FILIAL, SL1.L1_NUM"
// 		_sSQL += "    FROM SL4010 AS SL4"
// 		_sSQL += " 		INNER JOIN SL1010 AS SL1"
// 		_sSQL += " 			ON (SL1.D_E_L_E_T_ = ''"
// 		_sSQL += " 				AND SL1.L1_FILIAL = SL4.L4_FILIAL"
// 		_sSQL += " 				AND SL1.L1_NUM    = SL4.L4_NUM"
// 		_sSQL += " 				AND SL1.L1_VACGC  = '')"
// 		_sSQL += "  WHERE SL4.D_E_L_E_T_ = ''"
// 		_sSQL += " 	  AND SL4.L4_DATA    = '" + dtos(ddatabase) + "'" 
// 	    _sSQL += "    AND SL4.L4_FORMA   = 'CO'"
// 	    _sSQL += "    AND SL4.L4_ADMINIS LIKE '%900%'"
	    
// 	    _aDados := U_Qry2Array(_sSQL)
// 		if len(_aDados) > 0
// 			for i=1 to len(_aDados)
// 				DbSelectArea("SL1")
// 				DbSetOrder(1)
// 				if DbSeek(_aDados[i,3] + _aDados[i,4],.F.)
// 					reclock("SL1", .F.)
// 						_wcgc = fBuscaCpo ('SA1', 1, xfilial('SA1') + _aDados[i,1] + _aDados[i,2], "A1_CGC")
// 						SL1->L1_VACGC  := _wcgc  
// 		        		SL1->L1_CGCCLI := _wcgc 
// 		        	MsUnLock()
// 		        endif	
// 	        next	
// 		endif
// 	endif
// 	// LE VENDAS DE CUPONS DAS LOJAS - PARA FUNCIONARIOS DA FILIAL DO MENU OU QUE ESTA RODANDO O BATH
// 	_sSQL := " "
// 	_sSQL += " SELECT SL1.L1_FILIAL"
//     _sSQL += "      , SL1.L1_EMISNF"
//     if dtos(ddatabase) > '20181031'
//     	_sSQL += "      , SL4.L4_VALOR"
//     else
//     	_sSQL += "      , SL1.L1_VLRTOT"
//     endif	
//     _sSQL += "      , SL1.L1_CONTATO"
//     _sSQL += "      , SL1.L1_VACGC"
//     _sSQL += "      , ZAD.ZAD_FFILIA"
//     _sSQL += "      , ZAD.ZAD_NOME"
//     _sSQL += "      , SL1.L1_DOC"
//     _sSQL += "      , SL1.L1_NUM"
//   	_sSQL += "   FROM SL1010 AS SL1"
//   	if dtos(ddatabase) > '20181031'
//   	 	_sSQL += " 		INNER JOIN SL4010 AS SL4"
// 		_sSQL += " 			ON (SL4.D_E_L_E_T_ = ''"
// 		_sSQL += " 				AND SL4.L4_FILIAL  = SL1.L1_FILIAL"
// 		_sSQL += " 				AND SL4.L4_NUM     = SL1.L1_NUM"
// 		_sSQL += " 				AND SL4.L4_FORMA   = 'CO'"
// 		_sSQL += " 				AND SL4.L4_ADMINIS LIKE '%900%' )"
//   	endif  	
//     _sSQL += "  	INNER JOIN SF2010 AS SF2" // padrao
//  	_sSQL += "			ON (SF2.D_E_L_E_T_ = ''"
//  	_sSQL += "				AND SF2.F2_FILIAL  = L1_FILIAL"
//  	_sSQL += "				AND SF2.F2_DOC     = L1_DOC"
//  	_sSQL += "				AND SF2.F2_SERIE   = L1_SERIE"
//  	_sSQL += "				AND SF2.F2_EMISSAO = L1_EMISNF)"
//  	_sSQL += "  	INNER JOIN ZAD010 AS ZAD"
//  	_sSQL += "			ON (ZAD.D_E_L_E_T_ = ''"
//  	_sSQL += "				AND ZAD.ZAD_FFILIA = '"+xFilial("SL1")+"'" 
//  	_sSQL += "				AND ZAD.ZAD_CPF    =  L1_CGCCLI)"
// 	_sSQL += " WHERE SL1.D_E_L_E_T_  =''"
//     _sSQL += "   AND SL1.L1_EMISNF  > '20180101'"
//    	_sSQL += "   AND SL1.L1_DOC     !=''"
//    	if dtos(ddatabase) <= '20181031'
//    		_sSQL += "   AND SL1.L1_CONDPG = '997'"
//     endif
//     _sSQL += "   AND SL1.L1_INDCTB = ''"
//     _sSQL += " ORDER BY SL1.L1_EMISNF"

//     //u_showmemo(_sSQL)
// 	_aDados := U_Qry2Array(_sSQL)
// 	if len(_aDados) > 0
				    
// 		for i=1 to len(_aDados)
// 			_wfilvend   = _aDados[i,1]
// 			_wdata      = _aDados[i,2]
// 			_wvalor     = _aDados[i,3]
// 			_whistorico = "ADTO COMPRAS LOJA - " + _aDados[i,7] 
// 			_wdata      = _aDados[i,2]
// 			_wfilfunc   = _aDados[i,6]
// 			_wdoc       = _aDados[i,8]
// 			_wnum       = _aDados[i,9]
// 			_windctb = 'N'
// 			// define contas
// 			if _wfilvend != _wfilfunc
// 				_aAutoCT2C := {}
// 				aAdd (_aAutoCT2C,  {'DDATALANC'     , _wdata         ,NIL} )
// 				aAdd (_aAutoCT2C,  {'CLOTE'         ,'555555'        ,NIL} )
// 				aAdd (_aAutoCT2C,  {'CSUBLOTE'      ,'001'           ,NIL} )
// 				aAdd (_aAutoCT2C,  {'CDOC'          ,_wDoc           ,NIL} )
// 				aAdd (_aAutoCT2C,  {'CPADRAO'       ,''              ,NIL} )
// 				aAdd (_aAutoCT2C,  {'NTOTINF'       ,0               ,NIL} )
// 				aAdd (_aAutoCT2C,  {'NTOTINFLOT'    ,0               ,NIL} )
// 				_aAutoCT2I := {}
// 				_aLinhaCT2 := {}
// 				aAdd (_aLinhaCT2,  {'CT2_LINHA'      , '001'          , NIL})
// 			    aAdd (_aLinhaCT2,  {'CT2_MOEDLC'     , '01'           , NIL})
// 			    aAdd (_aLinhaCT2,  {'CT2_DC'         , '3'            , NIL})
// 			    aAdd (_aLinhaCT2,  {'CT2_DEBITO'     , '101020701006' , NIL})
// 			    aAdd (_aLinhaCT2,  {'CT2_CREDIT'     , '101010201099' , NIL})
// 			    aAdd (_aLinhaCT2,  {'CT2_VALOR'      , _wvalor        , NIL})
// 			    aAdd (_aLinhaCT2,  {'CT2_ORIGEM'     , 'BATCOMPFUN'   , NIL})
// 			    aAdd (_aLinhaCT2,  {'CT2_HIST'       , _whistorico    , NIL})
// 			    aAdd (_aAutoCT2I, aclone (_aLinhaCT2))
// 				lMsErroAuto := .F.
// 				lMsHelpAuto := .T.
// 				MSExecAuto({|x, y,z| CTBA102(x,y,z)}, _aAutoCT2C ,_aAutoCT2I, 3)
// 		    	if lMSErroAuto
// 					_sErro := memoread (NomeAutoLog ())
// 					u_help (_sErro)
// 				else
// 					u_log ('lcto contabil gerado')
// 				endif
// 				_windctb = 'S'
// 			endif
// 			// atualiza SL1
// 			DbSelectArea("SL1")
// 			DbSetOrder(1)
//         	if DbSeek(_wfilvend + _wnum ,.F.)
//         		reclock("SL1", .F.)
//         			SL1->L1_INDCTB := _windctb 
//         		MsUnLock()
// 			endif        		
// 		next
// 	endif								
// return
