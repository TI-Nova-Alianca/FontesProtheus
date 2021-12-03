//  Programa...: VA_ZA4
//  Autor......: Catia Cardoso
//  Data.......: 13/04/2015
//  Descricao..: Controle de Verbas - Movimentação de Verbas
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao #manutencao_de_registros
// #Descricao         #Controle de Verbas - Movimentação de Verbas
// #PalavasChave      #verbas #manutencao_de_verbas
// #TabelasPrincipais #ZA4 #ZA5
// #Modulos 		  #FAT 
//
//  28/04/2015 - Catia - estava validando o nro do documento sempre
//  14/05/2015 - Catia - criada opcao de verbas eventuais e acordos comerciais
//  10/06/2015 - Catia - na geracao da NCC - gravar o vencimento e o historico que nao estava gravando
//  10/06/2015 - Catia - ao digitar verbas eventuais previstas em contrato nao estava validando correto o nro de lojas
//  15/06/2015 - Catia - forçar a contabilização na liberacao por boleto/deposito quando gera a NCC
//  22/06/2015 - Catia - nao estava gravando corretamente o indicador de contabilização
//  09/07/2015 - Catia - restrição para aceitar no codigo do carrefour a verba de campanha de vendas maior que o nro de lojas
//  23/07/2015 - Catia - caso das verbas de campanha do carrefour - que tem todo mes pra todas as lojas 
//				 e que pode ter mais de uma campanha de vendas.
//  09/10/2015 - Catia - tirado o teste de cliente ativo para contas as lojas do cliente
//  08/02/2016 - Catia - verifica se eh uma verba do tipo multa - ai nao limita ao nro de lojas
//  21/06/2016 - Catia - validar para que so sejam incluidas verbas para o cliente matriz ou cliente base
//  15/12/2017 - Robert - Criada opcao de recalcular saldos (ajusta status) da verba.
//  09/08/2018 - Catia  - teste se eh possivel colocar uma verba num codigo de cliente que nao seja o codigo matriz
//  08/04/2019 - Catia  - include TbiConn.ch
//  09/05/2019 - Catia  - solicitar tipo de liberacao e data de vencimento ainda na inclusao
//             - Catia  - liberação por permissao agora so o coordenador e o gerente comercial liberarm 
//  14/08/2019 - Andre  - Removido validação que conta quantidade de verbas para o mesmo cliente.
//  10/10/2019 - Sandra/Andre - Criada opção para validar liberação verba sem vendedor
//  12/08/2020 - Cláudia - Edição/alteração de verbas. GLPI: 8210
//  19/08/2020 - Cláudia - Ajuste de exclusão de verbas tipo boleto/depósito. GLPI: 8350 
//  15/09/2020 - Cláudia - Alteração de verbas tipo boleto/deposito. GLPI: 8479
//  03/12/2021 - Claudia - BLoqueada a rotina para incluir verbas nas filiais. GLPI:11306
//
// ---------------------------------------------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"
#include "VA_Inclu.prw"

User Function VA_ZA4()
	private cCadastro  := "Movimentação de Verbas"
	private cString    := "ZA4"
	private aRotina    := {}
	private _sarqlog   := U_NomeLog ()
	private _sQuery    := ""
	private _aDados    := {}
	
    u_logId ()
	
	If cFilAnt <> '01'
		u_help("Não é permitido incluir verbas em filiais, apenas na matriz. Operação cancelada!")
	Else
		// Menu principal
		aadd (aRotina, {"&Pesquisar"          , "AxPesqui"		, 0,1})
		aadd (aRotina, {"&Visualizar"         , "AxVisual"		, 0,2})
		aadd (aRotina, {"&Acordos Isolados"   , "U_ZA4_I('2')" 	, 0,3})
		aadd (aRotina, {"&Eventuais Contratos", "U_ZA4_I('1')" 	, 0,3})
		aadd (aRotina, {"&Liberar"            , "U_ZA4_L" 		, 0,4})
		aadd (aRotina, {"&Estornar"           , "U_ZA4_EL" 		, 0,4})
		aadd (aRotina, {"&Excluir"            , "U_ZA4_EX" 		, 0,4})
		aadd (aRotina, {"&Alterar"            , "U_ZA4_AL"   	, 0,4})
		
		dbselectarea (cString)
		dbSetOrder (1)
		mBrowse(,,,,cString,,,,,2)
	EndIf
    
Return
//
// -------------------------------------------------------------------------
// Inclusao
User Function ZA4_I (_wtipoinclusao)
//	local _oCtaCorr  := NIL
    private altera   := .F.
    private inclui   := .T.
    private aGets    := {}
    private aTela    := {}
    private _wfiltro := iif(_wtipoinclusao='1','5','9') 
    
    u_logIni ()
    RegToMemory ("ZA4", inclui, inclui)
	
	if axinclui ("ZA4", za4 -> (recno ()), 3, NIL, NIL, NIL, "U_ZA4_VI(" + _wtipoinclusao +")") == 1
    
        RecLock ("ZA4",.F.)
        za4 -> za4_uger = alltrim (cUserName)
        za4 -> za4_dger = date()
        za4 -> za4_sger = '2'
        za4 -> za4_sutl = '0'
        za4 -> za4_ctb  = fBuscaCpo ('ZA3', 1, xfilial('ZA3') + za4-> za4_cod, "ZA3_CTB")
        MsUnLock()
        
        MBrChgLoop(.F.) 
    else
    	ROLLBACKSXE()
    endif

    u_logFim ()
Return
//
// --------------------------------------------------------------------------
// Liberacao
User Function ZA4_L()
	private altera   := .T.
    private inclui   := .F.
 	private aGets    := {}
	private aTela    := {}
	public _lRetFin  := .F.
	
	if ! u_zzuvl ('037', __cUserId, .T.) .and. ! EMPTY (ZA4 -> ZA4_VEND)  
		return
	endif

    u_logIni ()
	RegToMemory ("ZA4", inclui, .T.)
	
	if !empty(za4 -> za4_dlib)
	   u_help ("Dados de Liberação já informados")
       return      
	endif
	
	// Apos a alteracao do registro, faz os tratamentos necessarios.
    if axaltera ("ZA4", za4 -> (recno ()), 4, NIL, NIL, NIL, NIL, "U_ZA4_VL()") == 1
        RecLock ("ZA4",.F.)
        za4 -> za4_ulib = alltrim (cUserName)
        za4 -> za4_slib = '1'
        za4 -> za4_dlib = date()
        MsUnLock()

     	if za4 -> za4_tlib !='5'
    		// manda email para o financeiro após a liberação da verba pelo comercial
    		_aCols = {}
	    	aadd (_aCols, {'Razão Social'          ,    'left'  ,  ''})
	    	aadd (_aCols, {'Cliente'               ,    'left'  ,  ''})
	    	aadd (_aCols, {'Loja'                  ,    'left'  ,  ''})
	    	aadd (_aCols, {'Descricao'             ,    'left'  ,  ''})
	    	aadd (_aCols, {'Numero'                ,    'left'  ,  ''})
		    aadd (_aCols, {'Valor'                 ,    'right' ,  ''})
		    aadd (_aCols, {'Dt.Liberacao'          ,    'left'  ,  ''})
		    aadd (_aCols, {'Responsavel Liberacao' ,    'left'  ,  ''})
		    aadd (_aCols, {'Tipo Liberacao'        ,    'left'  ,  ''})

		    if za4 -> za4_tlib ='3' .or. za4 -> za4_tlib ='4' .or. za4 -> za4_tlib ='2'
		    	aadd (_aCols, {'Vencimento'            ,    'left'  ,  ''})
		    endif
		    if za4 -> za4_tlib ='4'
		    	aadd (_aCols, {'Dados Bancarios'       ,    'left'  ,  ''})
		    endif
		   	_oSQL := ClsSQL():New ()
		   	_oSQL:_sQuery := ""
		   	_oSQL:_sQuery += " SELECT SA1.A1_NOME"
		   	_oSQL:_sQuery += "      , SA1.A1_COD"
		   	_oSQL:_sQuery += "      , SA1.A1_LOJA"
		   	_oSQL:_sQuery += "      , ZA3.ZA3_DES"
		   	_oSQL:_sQuery += "      , ZA4.ZA4_NUM"
		   	_oSQL:_sQuery += "		, dbo.FormataValor(ZA4.ZA4_VLR, 2, 18)"
	       	_oSQL:_sQuery += "	  	, dbo.VA_DTOC(ZA4.ZA4_DLIB)"
	       	_oSQL:_sQuery += "      , ZA4.ZA4_ULIB"
	       	_oSQL:_sQuery += "      , CASE WHEN ZA4.ZA4_TLIB= '1' THEN 'Bonificacao' WHEN ZA4.ZA4_TLIB= '2' THEN 'Desconto Financeiro' WHEN ZA4.ZA4_TLIB='3' THEN 'Boleto' WHEN ZA4.ZA4_TLIB='4' THEN 'Deposito' ELSE '' END AS LIBERACAO"
	       	if za4 -> za4_tlib ='3' .or. za4 -> za4_tlib ='4' .or. za4 -> za4_tlib ='2'
		    	_oSQL:_sQuery += "      , ZA4.ZA4_VENCTO"
	       	endif
		    if za4 -> za4_tlib ='4'
		    	_oSQL:_sQuery += "      , ZA4.ZA4_DADDEP"
		    endif	

	       	_oSQL:_sQuery += "   FROM " + RetSQLName ("ZA4") + " AS ZA4 "
	   		_oSQL:_sQuery += "	INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
	   		_oSQL:_sQuery += "          ON (SA1.D_E_L_E_T_ = '' "
	   		_oSQL:_sQuery += "              AND SA1.A1_COD     = '" + za4 -> za4_cli + "'"
	   		_oSQL:_sQuery += "				AND SA1.A1_LOJA    = '" + za4 -> za4_loja + "')"
	   		_oSQL:_sQuery += "	INNER JOIN " + RetSQLName ("ZA3") + " AS ZA3 "
	   		_oSQL:_sQuery += "          ON (ZA3.D_E_L_E_T_ = '' "
	   		_oSQL:_sQuery += "              AND ZA3.ZA3_COD   = '" + za4 -> za4_cod + "')"
		   	_oSQL:_sQuery += "   WHERE ZA4.ZA4_FILIAL = '" + xFilial('ZA4') + "'"
		   	_oSQL:_sQuery += "     AND ZA4.ZA4_NUM    = '" + za4 -> za4_num + "'"
		   	
			//u_showmemo(_oSQL:_sQuery)
	   		u_log (_oSQL:_sQuery)
		   	if len (_oSQL:Qry2Array (.T., .F.)) > 0
		   		_wrotina = ''
				if za4 -> za4_tlib ='2'
					_wmens = "Descont Financeiro"
					_wrotina = '036'
				elseif za4 -> za4_tlib ='3'
					_wmens = "Boleto"
					_wrotina = '036' 		   
				elseif za4 -> za4_tlib ='4'
					_wmens = "Deposito"
					_wrotina = '036'
				elseif za4 -> za4_tlib ='1'
					_wmens = "Bonificacao"
					_wrotina = '037'
				endif
				if _wrotina !=''	
		        	_sMsg = _oSQL:Qry2HTM ("Liberacao de Verba - " + _wmens + " - Cliente : " + fBuscaCpo ('SA1', 1, xfilial('SA1') + za4 -> za4_cli + za4 -> za4_loja, "A1_NOME"), _aCols, "", .F.)
		     		U_ZZUNU ({_wrotina}, "Liberacao de Verba - " + _wmens + " - Cliente : "+ fBuscaCpo ('SA1', 1, xfilial('SA1') + za4 -> za4_cli + za4 -> za4_loja, "A1_NOME"), _sMsg, .F., cEmpAnt, cFilAnt, "")
	            endif	
		   	endif
		endif
	endif			   	
    u_logFim ()
Return
//
// --------------------------------------------------------------------------
// Estorno de Liberacao
User Function ZA4_EL()
    private altera   := .F.
    private inclui   := .F.
    private aGets    := {}
    private aTela    := {}
    
    u_logIni ()
    RegToMemory ("ZA4", inclui, .T.)
    
    if empty(za4 -> za4_dlib)
       u_help ("Verba não liberada, não pode ser estornada.")
       return      
    endif
    	
	if val(za4 -> za4_sutl) > 0
       u_help ("Verba já utilizada, não pode ser estornada.")
       return      
    endif
    
	_tlibAnt = za4 -> za4_tlib
        
    // Apos a alteracao do registro, faz os tratamentos necessarios.
    if axaltera ("ZA4", za4 -> (recno ()), 4, NIL, NIL, NIL, NIL, "U_ZA4_VE(1)") == 1
        RecLock ("ZA4",.F.)
        za4 -> za4_ulib   = ''
        za4 -> za4_slib   = ''
        za4 -> za4_dlib   = ctod("")
        za4 -> za4_hl_cod = ''
        za4 -> za4_hl_obs = ''
        MsUnLock()
	    
		// manda email para o financeiro após a liberação da verba pelo comercial
		_aCols = {}
		aadd (_aCols, {'Razão Social'          ,    'left'  ,  ''})
		aadd (_aCols, {'Cliente'               ,    'left'  ,  ''})
		aadd (_aCols, {'Loja'                  ,    'left'  ,  ''})
		aadd (_aCols, {'Descricao'             ,    'left'  ,  ''})
		aadd (_aCols, {'Numero'                ,    'left'  ,  ''})
	    aadd (_aCols, {'Valor'                 ,    'right' ,  ''})
	    	    
	   	_oSQL := ClsSQL():New ()
	   	_oSQL:_sQuery := ""
	   	_oSQL:_sQuery += " SELECT SA1.A1_NOME"
	   	_oSQL:_sQuery += "      , SA1.A1_COD"
	   	_oSQL:_sQuery += "      , SA1.A1_LOJA"
	   	_oSQL:_sQuery += "      , ZA3.ZA3_DES"
	   	_oSQL:_sQuery += "      , ZA4.ZA4_NUM"
	   	_oSQL:_sQuery += "		, dbo.FormataValor(ZA4.ZA4_VLR, 2, 18)"
	   	_oSQL:_sQuery += "   FROM " + RetSQLName ("ZA4") + " AS ZA4 "
		_oSQL:_sQuery += "	INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
		_oSQL:_sQuery += "          ON (SA1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += "              AND SA1.A1_COD     = '" + za4 -> za4_cli + "'"
		_oSQL:_sQuery += "				AND SA1.A1_LOJA    = '" + za4 -> za4_loja + "')"
		_oSQL:_sQuery += "	INNER JOIN " + RetSQLName ("ZA3") + " AS ZA3 "
		_oSQL:_sQuery += "          ON (ZA3.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += "              AND ZA3.ZA3_COD   = '" + za4 -> za4_cod + "')"
	   	_oSQL:_sQuery += "   WHERE ZA4.ZA4_FILIAL = '" + xFilial('ZA4') + "'"
	   	_oSQL:_sQuery += "     AND ZA4.ZA4_NUM    = '" + za4 -> za4_num + "'"
	   	
	    //u_showmemo(_oSQL:_sQuery)
	
		u_log (_oSQL:_sQuery)
	   	if len (_oSQL:Qry2Array (.T., .F.)) > 0
	   		_wrotina = ''
			if _tlibAnt ='2'
				_wmens = "Desconto Financeiro"
				_wrotina = '036'
			elseif _tlibAnt ='3'
				_wmens = "Boleto"
				_wrotina = '036' 		   
			elseif _tlibAnt ='4'
				_wmens = "Deposito"
				_wrotina = '036'
			elseif _tlibAnt ='1'
				_wmens = "Bonificacao"
				_wrotina = '037'
			endif
			if _wrotina !=''	
	        	_sMsg = _oSQL:Qry2HTM ("ESTONO de Liberacao de Verba - " + _wmens + " - Cliente : " + fBuscaCpo ('SA1', 1, xfilial('SA1') + za4 -> za4_cli + za4 -> za4_loja, "A1_NOME"), _aCols, "", .F.)
	     		U_ZZUNU ({_wrotina}, "ESTORNO de Liberação de Verba - " + _wmens + " - Cliente : "+ fBuscaCpo ('SA1', 1, xfilial('SA1') + za4 -> za4_cli + za4 -> za4_loja, "A1_NOME"), _sMsg, .F., cEmpAnt, cFilAnt, "") // Financeiro
	        endif	
	   	endif
    	u_logFim ()
    endif
Return
//
// --------------------------------------------------------------------------
// Excluir
User Function ZA4_EX()
//	local  _aDados   := {}
    private altera   := .F.
    private inclui   := .F.
    private aGets    := {}
    private aTela    := {}
    
    u_logIni ()
    RegToMemory ("ZA4", inclui, .T.)

    // so é permitido exclusao de verba manual e que nao tenha sido liberada ainda.
    If !empty(m->za4_dlib)
       u_help ("Verba já liberada! Não pode ser excluida.")
    Else
        if m->za4_sger='1'
            u_help ("Verba gerada por contrato. Não pode ser excluida.")
        else   
            _lContinua := U_ZA4_VE (2)
            If _lContinua == .T.
             	AxDeleta ("ZA4", za4 -> (recno ()), 5)
            Else
            	u_help("A verba não pode ser excluída!")
            EndIf
        endif    
    Endif
    u_logFim ()
Return
//
// --------------------------------------------------------------------------
// Valida inclusao
User Function ZA4_VI(_wtipo)
    local _lRet     := .T.
    local _lRetFin  := .T.
    
   	// obriga que a verba seja digitada no codigo matriz do cliente.
   	_wcbase = fBuscaCpo ('SA1', 1, xfilial('SA1') + m-> za4_cli + m-> za4_loja, "A1_VACBASE")
   	
    if _wcbase != m-> za4_cli
   		u_help ("Código Cliente não eh codigo base ou codigo matriz. Verifique codigo correto do cliente para digitação da verba.")
        _lRet = .F.
        return _lRet
   	endif
   	
    if _lRet .and. empty(m->za4_hg_obs)
       u_help ("Obrigatório informar Histórico")
       _lRet = .F.
       return _lRet
    endif
 
    // verifica se a verba que esta sendo incluida
    // é do tipo 9 = ACORDO COMERCIAL
    if _lRet .and. _wtipo=2
        _wtipover :=fbuscacpo ("ZA3", 1, xfilial ("ZA3") + m->za4_cod,  "ZA3_IND")
        if  _wtipover !='9'
            u_help ("Só é possível incluir verbas do tipo ACORDO COMERCIAL")
            _lRet = .F.
            return _lRet
        endif             
    endif   
    
    //validacoes para inclusao de verbas EVENTUAIS
    if _lRet .and. _wtipo=1
    
    	if empty(m->za4_cont)
       		u_help ("Obrigatório informar Contrato do Cliente para verbas Eventuais.")
       		_lRet = .F.
       		return _lRet
    	endif
    	
    	if empty(m->za4_seqcon)
       		u_help ("Obrigatório informar Vigencia do Contrato do Cliente para verbas Eventuais.")
       		_lRet = .F.
       		return _lRet
    	endif
    
    	// esta no contrato do cliente (TEM QUE ESTAR PREVISTA NO CONTRATO)
        DbSelectArea("ZA6")
        DbSetOrder(1)
        if ! DbSeek(xFilial("ZA6")+m->za4_cli+m->za4_loja+m->za4_cont+m->za4_cod,.F.)
            u_help ("Verba Eventual não prevista no contrato do cliente.")    
            _lRet = .F.
            DbSelectArea("ZA4")
            return _lRet
        endif
        
    	//valida contrato vigente
        _wvigent :=fbuscacpo ("ZA7", 1, xFilial("ZA7")+m->za4_cli+m->za4_loja+m->za4_cont+m->za4_seqcon,"ZA7_VIGENT")
        if _wvigent = '2'
            u_help ("Contrato não esta vigente.")    
            _lRet = .F.
            DbSelectArea("ZA4")
            return _lRet
        endif
        
        // valida o tipo da verba no contrato tem que ser  VALOR
        _wtipo :=fbuscacpo ("ZA6", 1, xfilial ("ZA6")+m->za4_cli+m->za4_loja+m->za4_cont+m->za4_cod,"ZA6_TP")
        if _wtipo = '2'
            u_help ("No contrato essa verba é do tipo PERCENTUAL. Não pode ser informada como valor.")    
            _lRet = .F.
            DbSelectArea("ZA4")
            return _lRet
        endif
        
        /* 
        // não pode ter mais de uma vez a verba no contrato/sequencia
        // desconsidera carrefour e a verba de campanha de vendas, pq posso ter mais de uma campanha no mesmo contrato
        if (m->za4_cli != '016088' .and. m->za4_cod !='020')
        	// verifica se eh uma verba do tipo multa - ai nao limita ao nro de lojas
			_wtipoverba = fBuscaCpo ('ZA3', 1, xfilial('ZA3') + m->za4_cod, "ZA3_CTB")
			if _wtipoverba != '6' 	         	
	            DbSelectArea("ZA4")
		        DbSetOrder(3)
		        if DbSeek(xFilial("ZA4")+m->za4_cli+m->za4_loja+m->za4_cont+m->za4_seqcon+m->za4_cod,.F.)
		        	// conta quantas verbas ja tem cadastrada
		        	_sQuery := ""
		        	_sQuery += " SELECT COUNT(*)"
		        	_sQuery += "   FROM " + RetSQLName ("ZA4") + " ZA4"
		        	_sQuery += "  WHERE ZA4.D_E_L_E_T_ != '*'"
		        	_sQuery += "    AND ZA4_CLI         = "+ m->za4_cli  
		        	_sQuery += "    AND ZA4_LOJA        = "+ m->za4_loja
		        	_sQuery += "    AND ZA4_COD         = "+ m->za4_cod
		        	_sQuery += "    AND ZA4_CONT        = "+ m->za4_cont
		        	_sQuery += "    AND ZA4_SEQCON      = "+ m->za4_seqcon
		        	_aDados := U_Qry2Array (_sQuery)
		        	_wqtdever = 0
		        	if len(_aDados) > 0
						_wqtdever = _aDados[1,1]             	    
		        	endif
		        	// conta quantidade de lojas no CNPJ matriz
		        	_sQuery := ""
		        	_sQuery += " SELECT COUNT(*)"
		        	_sQuery += "   FROM " + RetSQLName ("SA1") + " SA1"
		        	_sQuery += "  WHERE SA1.D_E_L_E_T_ != '*'"
		        	_sQuery += "    AND SA1.A1_VACBASE  = "+ m->za4_cli  
		        	//_sQuery += "    AND SA1.A1_MSBLQL   = 2"
		        	_aDados := U_Qry2Array (_sQuery)
		        	_wqtdlojas = 0
		        	if len(_aDados) > 0
						_wqtdlojas = _aDados[1,1]             	    
		        	endif
		        	// valida quandidade de verbas que podem ser liberada conforme quantidade de lojas
		        	if _wqtdever > _wqtdlojas
		            	u_help ("Verba informada excede o nro de verbas permitidas conforme contrato/lojas")    
		            	_lRet = .F.
		            	DbSelectArea("ZA4")
		            	return _lRet
					endif            	 	
		        endif
			endif						        
        endif */
    endif
    
    // valida documento do cliente
    if _lRet .and. empty(m->za4_doc)
    	DbSelectArea("ZA4")
        DbSetOrder(4)
        if DbSeek(xFilial("ZA4")+m->za4_cli+m->za4_loja+m->za4_doc,.F.)
            u_help ("Nro de documento ja informado para este cliente.")    
            _lRet = .F.
        endif
    endif
    
    if empty(m->za4_vencto)
       	u_help ("Obrigatório informar Data de Vencimento")
       	_lRet = .F.
       	return _lRet
    endif
    
    do case
       case m->za4_tlib == '1'
            _lRet = .T.
       case m->za4_tlib == '2'
            _lRet = .T.
       case m->za4_tlib == '3' .or. m->za4_tlib == '4'
       		if m->za4_tlib == '4' .and. empty(m->za4_daddep)
    			u_help ("Obrigatório informar dados bancarios para deposito.")
    			_lRet = .F.
    			return _lRet
    		endif
    		U_ZA4_G_FIN()
       		if _lRetFin
               _lRet = .T.
            endif
       case m->za4_tlib == '5'
            _lRet = .T.
       otherwise
            u_help ("Obrigatório informar o tipo de liberação.")
            _lRet = .F.
    endcase
  
Return _lRet
//
// --------------------------------------------------------------------------
// Valida liberacao
User Function ZA4_VL ()
    local _lRet := .T.
    
	if empty(m->za4_hl_obs)
       u_help ("Obrigatório informar Histórico de Liberação")
       _lRet = .F.
    endif

return _lRet
//
// --------------------------------------------------------------------------
// Valida estorno _nTipo = 1 (estorno) _nTipo = 2 (exclusão)
User Function ZA4_VE (_nTipo)
	local _x	:= 0
	local _lRet := .T.
    
    if ! u_zzuvl ('037', __cUserId, .T.)
    	_lRet := .F.
    	return
	endif
	
    if m->za4_tlib =='3' .or. m->za4_tlib =='4'
        // exclui titulo do contas a receber
        DbSelectArea("SE1")
        se1 -> (dbsetorder (2))
        _wchave = xFilial("SE1")+m->za4_cli+m->za4_loja+'CV '+m->za4_num+'   1'+'NCC'
        if ! se1 -> (dbSeek( _wchave ,.F.))
        	u_help ("Titulo nao encontrado no financeiro")
        	If _nTipo == 2
        		_lRet := .T.
        	EndIf
        else
            reclock ("SE1", .F.)
            	SE1 -> (dbdelete ())
            msunlock ("SE1")
            _lRet := .T.
        endif
    endif
    
    _aDados := {}
    _sQuery := ""
	_sQuery += " SELECT ZA5_DOC, ZA5_PREFIX, ZA5_TIPO "
	_sQuery += " FROM " +  RetSQLName ("ZA5")
	_sQuery += " WHERE D_E_L_E_T_=''"
	_sQuery += " AND ZA5_NUM = '" + m->za4_num + "'"
	_aDados := U_Qry2Array(_sQuery)
				
	If Len(_aDados) > 0 
		For _x:=1 to Len(_aDados)
			u_help(" A verba foi utilizada. Dessa forma não poderá ser excluida/estornada") 
			u_help(" Verba:" + m->za4_num + " Doc."  + _aDados[_x,1] + " Série:" + _aDados[_x,2] + " Tipo:" + _aDados[_x,3] )
		Next
		_lRet := .F.
	EndIf
	
Return _lRet
//
// --------------------------------------------------------------------------
// Gera financeiro
User Function ZA4_G_FIN ()
    _lRetFin := .T.
     
    if  m->za4_tlib == '3' .or. m->za4_tlib == '4'
    	// força parametro de contabilização on-line como SIM
    	U_GravaSX1 ('FIN040', "01", 1)
		// gera NCC contas a receber
        _aAutoSE1 := {}
        
        aAdd(_aAutoSE1, {"E1_FILIAL"    , xfilial ("SE1") , Nil})
        aAdd(_aAutoSE1, {"E1_PREFIXO"   , "CV "           , Nil})
        aAdd(_aAutoSE1, {"E1_NUM"       , m->za4_num      , Nil})
        aAdd(_aAutoSE1, {"E1_PARCELA"   , '1'             , Nil})
        aAdd(_aAutoSE1, {"E1_CLIENTE"   , m->za4_cli      , Nil})
        aAdd(_aAutoSE1, {"E1_LOJA"      , m->za4_loja     , Nil})
        AAdd(_aAutoSE1, {"E1_TIPO"      , 'NCC'           , Nil})
        AAdd(_aAutoSE1, {"E1_NATUREZ"   , 'VERBAS'        , Nil})
        AAdd(_aAutoSE1, {"E1_EMISSAO"   , DATE()          , Nil})
        AAdd(_aAutoSE1, {"E1_VENCTO"    , m->za4_vencto   , Nil})
        AAdd(_aAutoSE1, {"E1_VALOR"     , m->za4_vlr      , Nil})
        AAdd(_aAutoSE1, {"E1_ORIGEM"    , 'VERBAS'        , Nil})
        AAdd(_aAutoSE1, {"E1_HIST"      , IIF(m->za4_tlib='3','BOLETO','DEPOSITO'), Nil}) 
       // AAdd(_aAutoSE1, {"E1_CODVERB"   , m->za4_cod       , Nil})
       
        // Inclui titulo a receber via rotina automatica.
        lMsHelpAuto := .T.  // se .T. direciona as mensagens de help
        lMsErroAuto := .F.  // necessario a criacao
        DbSelectArea("SE1")
        dbsetorder (1)
        MsExecAuto({|x,y|FINA040(x,y)},_aAutoSE1,3)
        //MsExecAuto({ |x, y, z, a, b| FINA040(x, y, z, a, b)}, aCab, 3, NIL, aRatEvEz)
        If lMsErroAuto
           if empty (NomeAutoLog ())
              _sErro = "Nao foi possivel ler o arquivo de log de erros."
           else
              _sErro = memoread (NomeAutoLog ())
           endif
           u_help (_sErro)
           _lRetFin = .F.
        endif
    endif
    
Return _lRetFin
//
// --------------------------------------------------------------------------
// Altera registro de verba
User Function ZA4_AL()
	local  nReg    := m->( Recno() )
	local _aDados  := {}
	local _aCampos := {}
 	local _nTemZA5 := 0
 	private inclui := .F.
	private altera := .T.
 	
 	RegToMemory ("ZA4", inclui, .T.)
 	
	If  m->za4_tlib == '3' .or. m->za4_tlib == '4'
		u_help("Verbas de boleto e deposito não podem ser alteradas devido aos titulos gerados no financeiro. Essas verbas precisam ser ser excluidas!")
	Else
		// verifica registros na ZA5
		_sQuery := ""
		_sQuery += " SELECT ZA5_DOC, ZA5_PREFIX, ZA5_TIPO "
		_sQuery += " FROM " +  RetSQLName ("ZA5")
		_sQuery += " WHERE D_E_L_E_T_=''"
		_sQuery += " AND ZA5_NUM = '" + za4->za4_num + "'"
		_aDados := U_Qry2Array(_sQuery)
					
		If Len(_aDados) > 0 
			_nTemZA5 := 1
		EndIf
		
		If _nTemZA5 == 0 // Não foi usado ainda e pode ser alterado   
			aadd (_aCampos, "ZA4_CONT")
			aadd (_aCampos, "ZA4_SEQCON")
			aadd (_aCampos, "ZA4_VLR")
			aadd (_aCampos, "ZA4_TLIB")
			aadd (_aCampos, "ZA4_VENCTO")
			aadd (_aCampos, "ZA4_DOC")
			aadd (_aCampos, "ZA4_HG_OBS")
			aadd (_aCampos, "ZA4_DATDEP")
			aadd (_aCampos, "ZA4_VEND")
			
			If AxAltera('ZA4', nReg,4,nil,_aCampos)	== 1
				RecLock ("ZA4",.F.)
					za4 -> za4_ulib = ''
					za4 -> za4_slib = ''
					za4 -> za4_dlib = CTOD('')	
					za4 -> za4_ualt = alltrim (cUserName)
					za4 -> za4_dalt = date()
				MsUnLock()
				u_help("Registro alterado com sucesso!")
				
			Else
				u_help("Registro NÃO alterado com sucesso!")
			EndIf
		Else
			u_help("O registro não pode ser alterado pois já está em uso!")
		EndIf
	EndIf
Return


