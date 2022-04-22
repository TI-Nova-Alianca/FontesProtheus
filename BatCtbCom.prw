// Programa...: BatCtbCom
// Autor......: Cláudia Lionço
// Data.......: 20/04/2022
// Descricao..: Lança na contabilidade os valores referente a compra de funcionarios e associados nas lojas
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Batch
// #Descricao         #Lança na contabilidade os valores referente a compra de funcionarios e associados nas lojas
// #PalavasChave      #Ctb #cupons #associados #funcionarios 
// #TabelasPrincipais #SL1 
// #Modulos   		  #CTB 
//
// Historico de alteracoes:
// 20/04/2022 - Claudia - Migrado o batch batcomfun (que contabilizada apenas funcionarios) 
//                        para esse novo batch. GLPI: 
//
// --------------------------------------------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "Totvs.ch"
#Include "TbiConn.ch"

User Function BatCtbCom()
    Local _oSQL     := ClsSQL ():New ()
    Local _nQtdDias := 30
    Local _dDtIni   := dtos(DaySub(Date(), _nQtdDias))
    Local _dDtFim   := dtos(Date())
    Local _x         := 0

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
                If _sFilvend != _sFilfunc
                    lMsErroAuto := .F.
                    lMsHelpAuto := .T.

                    _aAutoCT2C := {}
                    AADD(_aAutoCT2C,  {'DDATALANC'     , _sData         , NIL} )
                    AADD(_aAutoCT2C,  {'CLOTE'         ,'555555'        , NIL} )
                    AADD(_aAutoCT2C,  {'CSUBLOTE'      ,'001'           , NIL} )
                    AADD(_aAutoCT2C,  {'CDOC'          ,_sDoc           , NIL} )
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
                EndIf

                DbSelectArea("SL1")
                DbSetOrder(1)
                if DbSeek(_sFilvend + _nNum ,.F.)
                    reclock("SL1", .F.)
                        SL1->L1_INDCTB := _sIndCtb 
                    MsUnLock()
                endif        		
            Next
	    EndIf	

        // LE VENDAS DE CUPONS DAS LOJAS - PARA ASSOCIADOS QUE ESTA RODANDO O BATH
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += " 	   SL1.L1_FILIAL "
        _oSQL:_sQuery += "    ,SL1.L1_EMISNF "
        _oSQL:_sQuery += "    ,SL4.L4_VALOR "
        _oSQL:_sQuery += "    ,SL1.L1_CONTATO "
        _oSQL:_sQuery += "    ,SL1.L1_VACGC "
        _oSQL:_sQuery += "    ,SL1.L1_DOC "
        _oSQL:_sQuery += "    ,SL1.L1_NUM "
        _oSQL:_sQuery += " FROM " + RetSQLName ("SL1") + " SL1 "
        _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SL4") + " SL4 "
        _oSQL:_sQuery += " 	ON (SL4.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 			AND SL4.L4_FILIAL = SL1.L1_FILIAL "
        _oSQL:_sQuery += " 			AND SL4.L4_NUM    = SL1.L1_NUM "
        _oSQL:_sQuery += " 			AND SL4.L4_FORMA  = 'CO' "
        _oSQL:_sQuery += " 			AND SL4.L4_ADMINIS LIKE '%800%') "
        _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF2") + " SF2 "
        _oSQL:_sQuery += " 	ON (SF2.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 			AND SF2.F2_FILIAL  = L1_FILIAL "
        _oSQL:_sQuery += " 			AND SF2.F2_DOC     = L1_DOC "
        _oSQL:_sQuery += " 			AND SF2.F2_SERIE   = L1_SERIE "
        _oSQL:_sQuery += " 			AND SF2.F2_EMISSAO = L1_EMISNF) "
        _oSQL:_sQuery += " WHERE SL1.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND SL1.L1_FILIAL = '" + xFilial("SL1") + "'" 
        _oSQL:_sQuery += " AND SL1.L1_EMISNF BETWEEN '" + _dDtIni + "' AND '" + _dDtFim + "'"
        _oSQL:_sQuery += " AND SL1.L1_DOC != '' "
        _oSQL:_sQuery += " AND SL1.L1_INDCTB = '' "
        _oSQL:_sQuery += " ORDER BY SL1.L1_EMISNF "
        _oSQL:Log()
        _aDados := aclone(_oSQL:Qry2Array ())

        If len(_aDados) > 0  
	        For _x := 1 to len(_aDados)
                _sFilAssoc:= '01' // só contabiliza na matriz
                _sData    := _aDados[_x,2]
                _nValor   := _aDados[_x,3]
                _sHist    := "ADTO COMPRAS ASSOC.LOJA - " + _aDados[_x,5] 
                _sDoc     := _aDados[_x,6]
                _nNum     := _aDados[_x,7]
                _sIndCtb  := 'N'

                lMsErroAuto := .F.
                lMsHelpAuto := .T.

                _aAutoCT2C := {}
                AADD(_aAutoCT2C,  {'DDATALANC'     , _sData         , NIL} )
                AADD(_aAutoCT2C,  {'CLOTE'         ,'555555'        , NIL} )
                AADD(_aAutoCT2C,  {'CSUBLOTE'      ,'001'           , NIL} )
                AADD(_aAutoCT2C,  {'CDOC'          ,_sDoc           , NIL} )
                AADD(_aAutoCT2C,  {'CPADRAO'       ,''              , NIL} )
                AADD(_aAutoCT2C,  {'NTOTINF'       ,0               , NIL} )
                AADD(_aAutoCT2C,  {'NTOTINFLOT'    ,0               , NIL} )
                _aAutoCT2I := {}
                _aLinhaCT2 := {}
                AADD(_aLinhaCT2,  {'CT2_FILIAL'     , _sFilAssoc     , NIL})
                AADD(_aLinhaCT2,  {'CT2_LINHA'      , '001'          , NIL})
                AADD(_aLinhaCT2,  {'CT2_MOEDLC'     , '01'           , NIL})
                AADD(_aLinhaCT2,  {'CT2_DC'         , '3'            , NIL})
                AADD(_aLinhaCT2,  {'CT2_DEBITO'     , '101020101002' , NIL})
                AADD(_aLinhaCT2,  {'CT2_CREDIT'     , '101010201099' , NIL})
                AADD(_aLinhaCT2,  {'CT2_VALOR'      , _nValor        , NIL})
                AADD(_aLinhaCT2,  {'CT2_ORIGEM'     , 'BATCTBCOM'    , NIL})
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
                    _oEvento:Texto   = "BatCtbCom - Lcto contabil gerado com sucesso "+ _aDados[_x,5]
                    _oEvento:CodEven = "BAT001"
                    _oEvento:Grava()
                EndIf

                DbSelectArea("SL1")
                DbSetOrder(1)
                If DbSeek(_sFilvend + _nNum ,.F.)
                    reclock("SL1", .F.)
                        SL1->L1_INDCTB := _sIndCtb 
                    MsUnLock()
                EndIf        		
            Next
        EndIf	
    EndIf
Return 
