//  Programa...: VA_ZA4
//  Autor......: Catia Cardoso
//  Data.......: 13/04/2015
//  Descricao..: Controle de Verbas - Movimentação de Verbas
//
// Tags para automatizar catalogo de customizacoes:>
// #TipoDePrograma    #atualizacao #manutencao_de_registros
// #Descricao         #Controle de Verbas - Movimentação de Verbas
// #PalavasChave      #verbas #manutencao_de_verbas
// #TabelasPrincipais #ZA4 #ZA5
// #Modulos 		  #FAT 
//
//  28/04/2015 - Catia  - estava validando o nro do documento sempre
//  14/05/2015 - Catia  - criada opcao de verbas eventuais e acordos comerciais
//  10/06/2015 - Catia  - na geracao da NCC - gravar o vencimento e o historico que nao estava gravando
//  10/06/2015 - Catia  - ao digitar verbas eventuais previstas em contrato nao estava 
//                        validando correto o nro de lojas
//  15/06/2015 - Catia  - forçar a contabilização na liberacao por boleto/deposito quando gera a NCC
//  22/06/2015 - Catia  - nao estava gravando corretamente o indicador de contabilização
//  09/07/2015 - Catia  - restrição para aceitar no codigo do carrefour a verba de campanha 
//                       de vendas maior que o nro de lojas
//  23/07/2015 - Catia  - caso das verbas de campanha do carrefour - que tem todo mes pra todas as lojas 
//				          e que pode ter mais de uma campanha de vendas.
//  09/10/2015 - Catia  - tirado o teste de cliente ativo para contas as lojas do cliente
//  08/02/2016 - Catia  - verifica se eh uma verba do tipo multa - ai nao limita ao nro de lojas
//  21/06/2016 - Catia  - validar para que so sejam incluidas verbas para o cliente matriz ou cliente base
//  15/12/2017 - Robert - Criada opcao de recalcular saldos (ajusta status) da verba.
//  09/08/2018 - Catia  - teste se eh possivel colocar uma verba num codigo de cliente 
//                        que nao seja o codigo matriz
//  08/04/2019 - Catia  - include TbiConn.ch
//  09/05/2019 - Catia  - solicitar tipo de liberacao e data de vencimento ainda na inclusao
//             - Catia  - liberação por permissao agora so o coordenador e o gerente comercial liberarm 
//  14/08/2019 - Andre  - Removido validação que conta quantidade de verbas para o mesmo cliente.
//  10/10/2019 - Sandra/Andre - Criada opção para validar liberação verba sem vendedor
//  12/08/2020 - Cláudia - Edição/alteração de verbas. GLPI: 8210
//  19/08/2020 - Cláudia - Ajuste de exclusão de verbas tipo boleto/depósito. GLPI: 8350 
//  15/09/2020 - Cláudia - Alteração de verbas tipo boleto/deposito. GLPI: 8479
//  03/12/2021 - Claudia - BLoqueada a rotina para incluir verbas nas filiais. GLPI:11306
//  27/01/2022 - Claudia - Incluida validação de usuário para excluir verbas e retirada 
//                         rotina de alteração. GLPI: 11537
//  11/04/2024 - Claudia - Incluido status no estorno de verba. GLPI: 15225
//
//
// ------------------------------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"
#include "VA_Inclu.prw"

User Function VA_ZA4()
	local _aAreaAnt  := U_ML_SRArea()
	private cCadastro  := "Movimentação de Verbas"
	private cString    := "ZA4"
	private aRotina    := {}
	private _sarqlog   := U_NomeLog ()
	private _sQuery    := ""
	private _aDados    := {}
	Private _aCores    := {}
	
    u_logId ()
	
	If cFilAnt <> '01'
		u_help("Não é permitido incluir verbas em filiais, apenas na matriz. Operação cancelada!")
	Else
		// Menu principal
		aadd(aRotina, {"&Pesquisar"          , "AxPesqui"		, 0,1})
		aadd(aRotina, {"&Visualizar"         , "AxVisual"		, 0,2})
		aadd(aRotina, {"&Incluir"   		  , "U_ZA4_I()" 	, 0,3})
		aadd(aRotina, {"&Liberar"            , "U_ZA4_L" 		, 0,4})
		aadd(aRotina, {"&Estornar"           , "U_ZA4_EL" 		, 0,4})
		aadd(aRotina, {"&Excluir"            , "U_ZA4_EX" 		, 0,4})
		aadd(aRotina, {"&Cancelar"           , "U_ZA4_CAN" 		, 0,4})
		aadd(aRotina, {"&Alterar"            , "U_ZA4_AL"   	, 0,4})
		aadd(aRotina, {"&Produtos"           , "U_ZA4_PROPER()" , 0,4})
		aadd(aRotina, {"&Exp.Produtos"       , "U_ZA4_PROEXP()" , 0,6})
		aadd(aRotina, {"&Legenda"        	 , "U_ZA4_LGD(.F.)" , 0,5})
		aadd(aRotina, {"&Verbas em andamento", "U_ZA4_APRMER()" , 0,6})
		aadd(aRotina, {"&Últimas importadas ", "U_ZA4_ULTMER()" , 0,6})
		aadd(aRotina, {"&Erros Importacao"   , "U_ZA4_ERRMER()" , 0,6})

		AADD(_aCores,{ "ZA4_STATUS == 'I'", 'BR_VERDE'    }) // importado
		AADD(_aCores,{ "ZA4_STATUS == 'A'", 'BR_AMARELO'  }) // alterado
		AADD(_aCores,{ "ZA4_STATUS == 'L'", 'BR_VERMELHO' }) // liberado
		AADD(_aCores,{ "ZA4_STATUS == 'C'", 'BR_PRETO'    }) // cancelados
	
		dbselectarea(cString)
		dbSetOrder (1)
		mBrowse(,,,,cString,,,,,2,_aCores)

	EndIf
    U_ML_SRArea(_aAreaAnt)
Return
//
// --------------------------------------------------------------------------
// Retorna Legenda
User function Za4_LGD(_lRetCores)
	local aCores  := {}
	local aCores2 := {}
	local _i       := 0
	
	aadd (aCores, {"ZA4->ZA4_STATUS=='I'", 'BR_VERDE'   , 'Reg.Importados'	})
	aadd (aCores, {"ZA4->ZA4_STATUS=='A'", 'BR_AMARELO'	, 'Reg.Alterados'	})
	aadd (aCores, {"ZA4->ZA4_STATUS=='L'", 'BR_VERMELHO', 'Reg.Liberados'	})
	aadd (aCores, {"ZA4->ZA4_STATUS=='C'", 'BR_PRETO'   , 'Reg.Cancelados'	})


	if ! _lRetCores
		for _i = 1 to len (aCores)
			aadd (aCores2, {aCores [_i, 2], aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", aCores2)
	else
		for _i = 1 to len (aCores)
			aadd (aCores2, {aCores [_i, 1], aCores [_i, 2]})
		next
		return aCores
	endif
	
return
// 
// -------------------------------------------------------------------------
// Inclusao
User Function ZA4_I()
	Local aArea       := FWGetArea()
    Local aAreaZA4    := ZA4->(FWGetArea())
	private _wfiltro := '9' // acordos comerciais
    //Private cCadastro := "Inclusão"
     
	If AxInclui("ZA4", 0, 3, NIL, NIL, NIL, "U_ZA4_VI()",,,) == 1 
		RecLock("ZA4",.F.)
			za4 -> za4_uger = alltrim(cUserName)
			za4 -> za4_dger = date()
			za4 -> za4_sger = '2'
			za4 -> za4_sutl = '0'
			za4 -> za4_ctb  = fBuscaCpo('ZA3', 1, xfilial('ZA3') + za4-> za4_cod, "ZA3_CTB")
		MsUnLock()
	EndIf
     
    FWRestArea(aAreaZA4)
    FWRestArea(aArea)
Return
//
// --------------------------------------------------------------------------
// Liberacao
User Function ZA4_L()
	local _lRet		:= .T.
	private altera  := .T.
    private inclui  := .F.
 	private aGets   := {}
	private aTela   := {}
	public _lRetFin := .F.
	
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

		// Gera o financeiro
		if za4->za4_tlib == '3' .or. za4->za4_tlib == '4'
			_lRet := U_ZA4_G_FIN()
		endif

		if _lRet
			RecLock("ZA4",.F.)
				za4 -> za4_ulib   = alltrim(cUserName)
				za4 -> za4_slib   = '1'
				za4 -> za4_dlib   = date()
				za4 -> za4_status = 'L'
			MsUnLock()

			if za4 -> za4_tlib !='5'
				// manda email para o financeiro após a liberação da verba pelo comercial
				_aCols = {}
				aadd(_aCols, {'Razão Social'          ,    'left'  ,  ''})
				aadd(_aCols, {'Cliente'               ,    'left'  ,  ''})
				aadd(_aCols, {'Loja'                  ,    'left'  ,  ''})
				aadd(_aCols, {'Descricao'             ,    'left'  ,  ''})
				aadd(_aCols, {'Numero'                ,    'left'  ,  ''})
				aadd(_aCols, {'Valor'                 ,    'right' ,  ''})
				aadd(_aCols, {'Dt.Liberacao'          ,    'left'  ,  ''})
				aadd(_aCols, {'Responsavel Liberacao' ,    'left'  ,  ''})
				aadd(_aCols, {'Tipo Liberacao'        ,    'left'  ,  ''})

				if za4 -> za4_tlib ='3' .or. za4 -> za4_tlib ='4' .or. za4 -> za4_tlib ='2'
					aadd(_aCols, {'Vencimento'            ,    'left'  ,  ''})
				endif
				if za4 -> za4_tlib ='4'
					aadd(_aCols, {'Dados Bancarios'       ,    'left'  ,  ''})
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
				
				u_log(_oSQL:_sQuery)
				if len(_oSQL:Qry2Array (.T., .F.)) > 0
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
    
    u_logIni()
    RegToMemory("ZA4", inclui, .T.)
    
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
    if axaltera("ZA4", za4 -> (recno()), 4, NIL, NIL, NIL, NIL, "U_ZA4_VE(1)") == 1
        RecLock("ZA4",.F.)
			za4 -> za4_ulib   = ''
			za4 -> za4_slib   = ''
			za4 -> za4_dlib   = ctod("")
			za4 -> za4_hl_cod = ''
			za4 -> za4_hl_obs = ''
			za4 -> za4_status = 'A'

        MsUnLock()
	    
		// manda email para o financeiro após a liberação da verba pelo comercial
		_aCols = {}
		aadd(_aCols, {'Razão Social'          ,    'left'  ,  ''})
		aadd(_aCols, {'Cliente'               ,    'left'  ,  ''})
		aadd(_aCols, {'Loja'                  ,    'left'  ,  ''})
		aadd(_aCols, {'Descricao'             ,    'left'  ,  ''})
		aadd(_aCols, {'Numero'                ,    'left'  ,  ''})
	    aadd(_aCols, {'Valor'                 ,    'right' ,  ''})
	    	    
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
	
		u_log(_oSQL:_sQuery)
	   	if len(_oSQL:Qry2Array (.T., .F.)) > 0
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
	     		U_ZZUNU({_wrotina}, "ESTORNO de Liberação de Verba - " + _wmens + " - Cliente : "+ fBuscaCpo ('SA1', 1, xfilial('SA1') + za4 -> za4_cli + za4 -> za4_loja, "A1_NOME"), _sMsg, .F., cEmpAnt, cFilAnt, "") // Financeiro
	        endif	
	   	endif
    	u_logFim()
    endif
Return
//
// --------------------------------------------------------------------------
// Excluir
User Function ZA4_EX()
    private altera   := .F.
    private inclui   := .F.
    private aGets    := {}
    private aTela    := {}
    
	u_logIni()
	RegToMemory("ZA4", inclui, .T.)

	// so é permitido exclusao de verba manual e que nao tenha sido liberada ainda.
	If !empty(m->za4_dlib)
		u_help("Verba já liberada! Não pode ser excluida.")
	Else 
		_lContinua := U_ZA4_VE(2)
		If _lContinua == .T.
			AxDeleta("ZA4", za4 -> (recno()), 5)
		Else
			u_help("A verba não pode ser excluída!")
		EndIf  
	Endif

	u_logFim()
Return
//
// --------------------------------------------------------------------------
// cancelar
User Function ZA4_CAN()
    private altera   := .F.
    private inclui   := .F.
    private aGets    := {}
    private aTela    := {}
    
	u_logIni()
	RegToMemory("ZA4", inclui, .T.)

	// so é permitido cancelamento de verba manual e que nao tenha sido liberada ainda.
	If !empty(m->za4_dlib)
		u_help("Verba já liberada! Não pode ser excluida.")
	Else 
		RecLock("ZA4",.F.)
			za4 -> za4_status := 'C'
		MsUnLock()
	Endif

	u_logFim()
Return
//
// --------------------------------------------------------------------------
// Valida inclusao
User Function ZA4_VI()
    local _lRet     := .T.
    
   	// obriga que a verba seja digitada no codigo matriz do cliente.
   	_wcbase = fBuscaCpo('SA1', 1, xfilial('SA1') + m-> za4_cli + m-> za4_loja, "A1_VACBASE")
   	
    if _wcbase != m-> za4_cli
   		u_help("Código Cliente não eh codigo base ou codigo matriz. Verifique codigo correto do cliente para digitação da verba.")
        _lRet = .F.
        return _lRet
   	endif
   	
    if _lRet .and. empty(m->za4_hg_obs)
       u_help("Obrigatório informar Histórico")
       _lRet = .F.
       return _lRet
    endif
 
	_wtipover :=fbuscacpo ("ZA3", 1, xfilial ("ZA3") + m->za4_cod,  "ZA3_IND")
	if  _wtipover !='9'
		u_help("Só é possível incluir verbas do tipo ACORDO COMERCIAL")
		_lRet = .F.
		return _lRet
	endif             
    
    // // valida documento do cliente
    // if _lRet .and. !empty(m->za4_doc)
    // 	DbSelectArea("ZA4")
    //     DbSetOrder(4)
    //     if DbSeek(xFilial("ZA4")+m->za4_cli+m->za4_loja+m->za4_doc,.F.)
    //         u_help("Nro de documento ja informado para este cliente.")    
    //         _lRet = .F.
    //     endif
    // endif
    
    if empty(m->za4_vencto)
       	u_help("Obrigatório informar Data de Vencimento")
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
    			u_help("Obrigatório informar dados bancarios para deposito.")
    			_lRet = .F.
    		endif

       case m->za4_tlib == '5'
            _lRet = .T.

       otherwise
            u_help("Obrigatório informar o tipo de liberação.")
            _lRet = .F.
    endcase
  
Return _lRet
//
// --------------------------------------------------------------------------
// Valida liberacao - Realiza todas as validações para liberação já que verbas 
// do Mercanet não passam por validações de inclusão
User Function ZA4_VL()
    local _lRet := .T.
    
	_lRet := U_ZA4_VI() 

	if _lRet == .F.
		u_help(" Liberação não autorizada!")
	endif

return _lRet
//
// --------------------------------------------------------------------------
// Valida estorno _nTipo = 1 (estorno) _nTipo = 2 (exclusão)
User Function ZA4_VE(_nTipo)
	local _x	:= 0
	local _lRet := .T.
    
	if ! u_zzuvl('136', __cUserId, .T.)
    	_lRet := .F.
    	return
	endif
	
    if m->za4_tlib =='3' .or. m->za4_tlib =='4' // exclui titulo do contas a receber
        DbSelectArea("SE1")
        se1 -> (dbsetorder(2))

        _wchave := xFilial("SE1")+m->za4_cli+m->za4_loja+'CV '+m->za4_num+'   1'+'NCC'

        if ! se1 -> (dbSeek( _wchave ,.F.))
        	u_help("Titulo nao encontrado no financeiro")
        	If _nTipo == 2
        		_lRet := .T.
        	EndIf
        else
            reclock("SE1", .F.)
            	SE1 -> (dbdelete())
            msunlock("SE1")
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
User Function ZA4_G_FIN()
    _lRetFin := .T.
     
    if  za4->za4_tlib == '3' .or. za4->za4_tlib == '4'

		_aDados := {}
		_sQuery := ""
		_sQuery += " SELECT COUNT(*) "
		_sQuery += " FROM " +  RetSQLName ("SE1")
		_sQuery += " WHERE D_E_L_E_T_=''"
		_sQuery += " AND E1_NUM     = '" + za4->za4_num + "'"
		_sQuery += " AND E1_CLIENTE = '" + za4->za4_cli + "'"
		_sQuery += " AND E1_LOJA    = '" + za4->za4_loja+ "'"
		_sQuery += " AND E1_TIPO    = 'NCC'"
		_sQuery += " AND E1_ORIGEM  = 'VERBAS'"
		_aDados := U_Qry2Array(_sQuery)

		if _aDados[1,1] == 0 
			// força parametro de contabilização on-line como SIM
			U_GravaSX1('FIN040', "01", 1)
			// gera NCC contas a receber
			_aAutoSE1 := {}
			
			aAdd(_aAutoSE1, {"E1_FILIAL"    , xfilial ("SE1") 		, Nil})
			aAdd(_aAutoSE1, {"E1_PREFIXO"   , "CV "           		, Nil})
			aAdd(_aAutoSE1, {"E1_NUM"       , za4->za4_num    		, Nil})
			aAdd(_aAutoSE1, {"E1_PARCELA"   , '1'             		, Nil})
			aAdd(_aAutoSE1, {"E1_CLIENTE"   , za4->za4_cli    		, Nil})
			aAdd(_aAutoSE1, {"E1_LOJA"      , za4->za4_loja   		, Nil})
			AAdd(_aAutoSE1, {"E1_TIPO"      , 'NCC'           		, Nil})
			AAdd(_aAutoSE1, {"E1_NATUREZ"   , 'VERBAS'        		, Nil})
			AAdd(_aAutoSE1, {"E1_EMISSAO"   , DATE()          		, Nil})
			AAdd(_aAutoSE1, {"E1_VENCTO"    , za4->za4_vencto 		, Nil})
			AAdd(_aAutoSE1, {"E1_VALOR"     , za4->za4_vlr    		, Nil})
			AAdd(_aAutoSE1, {"E1_ORIGEM"    , 'VERBAS'        		, Nil})
			AAdd(_aAutoSE1, {"E1_HIST"      , IIF(za4->za4_tlib='3'	,'BOLETO','DEPOSITO'), Nil}) 
		
			// Inclui titulo a receber via rotina automatica.
			lMsHelpAuto := .T.  // se .T. direciona as mensagens de help
			lMsErroAuto := .F.  // necessario a criacao

			DbSelectArea("SE1")
			dbsetorder (1)

			MsExecAuto({|x,y|FINA040(x,y)},_aAutoSE1,3)

			If lMsErroAuto
			if empty(NomeAutoLog())
				_sErro = "Nao foi possivel ler o arquivo de log de erros."
			else
				_sErro = memoread(NomeAutoLog())
			endif

			u_help(_sErro)
			_lRetFin = .F.
			endif
		endif
	endif
    
Return _lRetFin
//
// --------------------------------------------------------------------------
// Altera registro de verba
User Function ZA4_AL()
	local _lRet    := .T.
	local  nReg    := m->( Recno())
	local _aDados  := {}
	local _aCampos := {}
	local _sStatus := ''
 	local _nTemZA5 := 0
 	private inclui := .F.
	private altera := .T.

	if !empty(za4 -> za4_slib) 
		u_help("Verba já liberada! Não será possível sua alteração.")
		return
	endif
 	
 	RegToMemory("ZA4", inclui, .T.)
 	
	If  m->za4_tlib == '3' .or. m->za4_tlib == '4'
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 	* "
		_oSQL:_sQuery += " FROM " +  RetSQLName("SE1")
		_oSQL:_sQuery += " WHERE E1_FILIAL = '01' "
		_oSQL:_sQuery += " AND E1_NATUREZ  = 'VERBAS' "
		_oSQL:_sQuery += " AND E1_TIPO     = 'NCC' "
		_oSQL:_sQuery += " AND E1_NUM      = '" + m->za4_num + "'"
		_aTit := aclone(_oSQL:Qry2Array())

		if len(_aTit) > 0
			_lRet := .F.
			u_help("Verbas de boleto e deposito não podem ser alteradas devido aos titulos gerados no financeiro. Essas verbas precisam ser ser excluidas!")
		endif
	Endif

	If _lRet
		// verifica registros na ZA5
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 		ZA5_DOC, ZA5_PREFIX, ZA5_TIPO "
		_oSQL:_sQuery += " FROM " +  RetSQLName("ZA5")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_=''"
		_oSQL:_sQuery += " AND ZA5_NUM = '" + za4->za4_num + "'"
		_aDados := aclone(_oSQL:Qry2Array())
					
		If Len(_aDados) > 0 
			_nTemZA5 := 1
		EndIf
		
		If _nTemZA5 == 0 // Não foi usado ainda e pode ser alterado   
			aadd(_aCampos, "ZA4_CONT"	)
			aadd(_aCampos, "ZA4_SEQCON"	)
			aadd(_aCampos, "ZA4_VLR"	)
			aadd(_aCampos, "ZA4_TLIB"	)
			aadd(_aCampos, "ZA4_VENCTO"	)
			aadd(_aCampos, "ZA4_DOC"	)
			aadd(_aCampos, "ZA4_HG_OBS"	)
			aadd(_aCampos, "ZA4_DATDEP"	)
			aadd(_aCampos, "ZA4_VEND"	)
			
			If AxAltera('ZA4', nReg,4,nil,_aCampos)	== 1
				if U_MsgYesNo("Deseja liberar para aprovação?")
					_sStatus = 'A'
				else
					_sStatus := za4->za4_status
				endif
				RecLock("ZA4",.F.)
					za4 -> za4_ulib  = ''
					za4 -> za4_slib  = ''
					za4 -> za4_dlib  = CTOD('')	
					za4 -> za4_ualt  = alltrim (cUserName)
					za4 -> za4_dalt  = date()
					za4 ->za4_status = _sStatus
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
//
// --------------------------------------------------------------------------
// Mostra registros em aprovação Mercanet
User function ZA4_APRMER()
	local   _oDlg       := NIL
	private _oTxtBrw1   := NIL
	private _oGetD1     := NIL
	private _aHeader    := {}
	private _aCols1     := {}

	_aHeader := aclone(U_GeraHead("ZZZ", .T., {}, {"ZZZ_16CODM", "ZZZ_16STAT", "ZZZ_16CLI", "ZZZ_16REP", "ZZZ_16DGER", "ZZZ_16DVCT","ZZZ_16DOC","ZZZ_16DESC"}, .T.))
    _aHead1  := aclone(_aHeader)
	_aCols1  := {} 	
	_aCols1  := _BuscaVerbas()			    // incluir os valores das colunas
	_aSize   := MsAdvSize()					// Define tamanho da tela.

	define MSDialog _oDlg from _aSize [1], _aSize [1] to _aSize [6], _aSize [5] of oMainWnd pixel title "Verbas"
	
    _oGetD1 := MsNewGetDados ():New (   40									,;		// Limite superior
		                                5									,;      // Limite esquerdo
		                                _oDlg:nClientHeight / 2 - 28		,;      // Limite inferior
		                                _oDlg:nClientWidth / 2 - 10			,;      // Limite direito    
		                                							        ,; 		// [ nStyle ]
		                                ""					                ,;  	// [ Linha OK]
		                                ""						            ,;  	// [ uTudoOk ]
		                                NIL									,; 		// [cIniCpos]
		                                NIL									,; 		// [ aAlter ]
		                                NIL									,; 		// [ nFreeze ]
		                                999									,; 		// [ nMax ]
		                                NIL									,; 		// [ cFieldOk ]
		                                NIL									,;		// [ uSuperDel ]
		                                NIL									,; 		// [ uDelOk ]
		                                _oDlg								,; 		// [ oWnd ]
		                                _aHead1								,; 		// [ ParHeader ]
		                                _aCols1						 		) 		// [ aParCols ]
    
     // Define botoes para a barra de ferramentas
	_bBotaoOK  = {|| _oDlg:End ()}
	_bBotaoCan = {|| _oDlg:End ()}
    
    activate dialog _oDlg on init (EnchoiceBar(_oDlg, _bBotaoOK, _bBotaoCan,, ), _oGetD1:oBrowse:SetFocus (), "")

return
//
// --------------------------------------------------------------------------
// Busca verbas abertas mercanet
Static Function _BuscaVerbas()
    local _aDados  := {}
    local _aDados1 := {}
    local _x       := 1

    _sLinkSrv = U_LkServer ('MERCANET')

    _oSQL := ClsSQL():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   PRC.CODIGO AS COD_MERCANET "
    _oSQL:_sQuery += "    ,PRC.SITUACAO AS ETAPA "
    _oSQL:_sQuery += "    ,RIGHT(REPLICATE('0', 6) + CONVERT(VARCHAR, PRC.CLIENTE), 6) + ' - ' + SA1.A1_NOME AS CLIENTE "
    _oSQL:_sQuery += "    ,CONVERT(VARCHAR, DB_TBREP_CODORIG) + ' - ' + SA3.A3_NOME AS REPRESENTANTE "
    _oSQL:_sQuery += "    ,PRC.DATA AS DT_GERACAO "
    _oSQL:_sQuery += "    ,PRC.DATA_1 AS DT_VENCTO "
    _oSQL:_sQuery += "    ,PRC.DOCUMENTO AS DOCUMENTO "
    _oSQL:_sQuery += "    ,CONVERT(VARCHAR(2000), PRC.DESCRICAO) AS DESCRICAO "
    _oSQL:_sQuery += " FROM "+ _sLinkSrv +".DB_OC_PRINCIPAL PRC "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_OC_ITENS ITE "
    _oSQL:_sQuery += " 	ON ITE.CODIGO_OC = 37400002 "
    _oSQL:_sQuery += " 		AND ITE.SEQUENCIA = VERBA_TIPO "
    _oSQL:_sQuery += " 		AND ITE.OPD_PERGUNTA = 105 "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_OC_ITENS ITE1 "
    _oSQL:_sQuery += " 	ON ITE1.CODIGO_OC = 37400002 "
    _oSQL:_sQuery += " 		AND ITE1.SEQUENCIA = PRC.LIBERACAO_TIPO "
    _oSQL:_sQuery += " 		AND ITE1.OPD_PERGUNTA = 106 "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_OC_ATIVIDADES ATI "
    _oSQL:_sQuery += " 	ON ATI.CODIGO_OC = PRC.CODIGO "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_CLIENTE CLI "
    _oSQL:_sQuery += " 	ON CLI.DB_CLI_CODIGO = PRC.CLIENTE "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_OC_ITENS BANCO "
    _oSQL:_sQuery += " 	ON BANCO.CODIGO_OC = 37400002 "
    _oSQL:_sQuery += " 		AND BANCO.OPD_PERGUNTA = 103 "
    _oSQL:_sQuery += " 		AND BANCO.SEQUENCIA = PRC.BANCO "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("ZA3") + " ZA3 "
    _oSQL:_sQuery += " 	ON ZA3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND ZA3.ZA3_COD = RIGHT(REPLICATE('0', 3) + CONVERT(VARCHAR, ITE.OPD_CODIGO), 3) "
    _oSQL:_sQuery += " INNER JOIN "+ _sLinkSrv +".DB_TB_REPRES "
    _oSQL:_sQuery += " 	ON DB_TBREP_CODIGO = PRC.REPRESENTANTE "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SA1") + " SA1 "
    _oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND A1_COD = RIGHT(REPLICATE('0', 6) + CONVERT(VARCHAR, PRC.CLIENTE), 6) "
    _oSQL:_sQuery += " 		AND SA1.A1_LOJA = '01' "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SA3") + " SA3 "
    _oSQL:_sQuery += " 	ON SA3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SA3.A3_COD = DB_TBREP_CODORIG "
    _oSQL:_sQuery += " WHERE PRC.TIPO = 1 "
    _oSQL:_sQuery += "      AND NOT EXISTS (SELECT "
    _oSQL:_sQuery += " 		    1 "
    _oSQL:_sQuery += " 	    FROM " + RetSQLName ("ZA4") + " ZA4 "
    _oSQL:_sQuery += " 	    WHERE ZA4.ZA4_NUMMER = PRC.CODIGO) "
    _oSQL:_sQuery += " AND PRC.SITUACAO <> 'Aprovada' "
    _oSQL:_sQuery += " ORDER BY PRC.DATA DESC "
    //u_log(_oSQL:_sQuery)
    _aDados1 := _oSQL:Qry2Array ()

    For _x :=1 to Len(_aDados1)
        aAdd(_aDados,   {   _aDados1[_x, 1] ,;
                            _aDados1[_x, 2] ,;
                            _aDados1[_x, 3] ,;
                            _aDados1[_x, 4] ,;
                            _aDados1[_x, 5] ,;
                            _aDados1[_x, 6] ,;
                            _aDados1[_x, 7] ,;
                            _aDados1[_x, 8] ,;
                                        .F.;
                        })
    Next

Return _aDados
//
// --------------------------------------------------------------------------
// Mostra erros de importação de verbas Mercanet
User Function ZA4_ERRMER()
	Local _stru		:= {}
	Local aCpoBro 	:= {}
	Local _aArqTrb  := {}
	Local _aAreaAnt := U_ML_SRArea ()
	Private lInverte:= .F.
	Private cMark   := GetMark()   
	Private oMark

	_sLinkSrv = U_LkServer ('MERCANET')

	//Cria um arquivo de Apoio
	AADD(_stru,{"OK"     	,"C"	,2		,0		})
	AADD(_stru,{"CODMER"   	,"N"	,10		,0		})
	AADD(_stru,{"CLIENTE" 	,"C"	,40		,0		})
	AADD(_stru,{"REPRES"   	,"C"	,40		,0		})
	AADD(_stru,{"DTGER" 	,"D"	,20		,0		})

	U_ArqTrb("Cria", "ARQ", _stru, {}, @_aArqTrb)	

    _oSQL := ClsSQL():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT TOP 100 "
    _oSQL:_sQuery += " 	   PRC.CODIGO AS CODMER "
    _oSQL:_sQuery += "    ,RIGHT(REPLICATE('0', 6) + CONVERT(VARCHAR, PRC.CLIENTE), 6) + ' - ' + SA1.A1_NOME AS CLIENTE "
    _oSQL:_sQuery += "    ,CONVERT(VARCHAR, DB_TBREP_CODORIG) + ' - ' + SA3.A3_NOME AS REPRES "
    _oSQL:_sQuery += "    ,PRC.DATA AS DTGER "
    _oSQL:_sQuery += " FROM "+ _sLinkSrv +".DB_OC_PRINCIPAL PRC "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_OC_ITENS ITE "
    _oSQL:_sQuery += " 	ON ITE.CODIGO_OC = 37400002 "
    _oSQL:_sQuery += " 		AND ITE.SEQUENCIA = VERBA_TIPO "
    _oSQL:_sQuery += " 		AND ITE.OPD_PERGUNTA = 105 "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_OC_ITENS ITE1 "
    _oSQL:_sQuery += " 	ON ITE1.CODIGO_OC = 37400002 "
    _oSQL:_sQuery += " 		AND ITE1.SEQUENCIA = PRC.LIBERACAO_TIPO "
    _oSQL:_sQuery += " 		AND ITE1.OPD_PERGUNTA = 106 "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_OC_ATIVIDADES ATI "
    _oSQL:_sQuery += " 	ON ATI.CODIGO_OC = PRC.CODIGO "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_CLIENTE CLI "
    _oSQL:_sQuery += " 	ON CLI.DB_CLI_CODIGO = PRC.CLIENTE "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_OC_ITENS BANCO "
    _oSQL:_sQuery += " 	ON BANCO.CODIGO_OC = 37400002 "
    _oSQL:_sQuery += " 		AND BANCO.OPD_PERGUNTA = 103 "
    _oSQL:_sQuery += " 		AND BANCO.SEQUENCIA = PRC.BANCO "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("ZA3") + " ZA3 "
    _oSQL:_sQuery += " 	ON ZA3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND ZA3.ZA3_COD = RIGHT(REPLICATE('0', 3) + CONVERT(VARCHAR, ITE.OPD_CODIGO), 3) "
    _oSQL:_sQuery += " INNER JOIN "+ _sLinkSrv +".DB_TB_REPRES "
    _oSQL:_sQuery += " 	ON DB_TBREP_CODIGO = PRC.REPRESENTANTE "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SA1") + " SA1 "
    _oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND A1_COD = RIGHT(REPLICATE('0', 6) + CONVERT(VARCHAR, PRC.CLIENTE), 6) "
    _oSQL:_sQuery += " 		AND SA1.A1_LOJA = '01' "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SA3") + " SA3 "
    _oSQL:_sQuery += " 	ON SA3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SA3.A3_COD = DB_TBREP_CODORIG "
    _oSQL:_sQuery += " WHERE PRC.TIPO = 1 "
    _oSQL:_sQuery += "      AND NOT EXISTS (SELECT "
    _oSQL:_sQuery += " 		    1 "
    _oSQL:_sQuery += " 	    FROM " + RetSQLName ("ZA4") + " ZA4 "
    _oSQL:_sQuery += " 	    WHERE ZA4.ZA4_NUMMER = PRC.CODIGO) "
    _oSQL:_sQuery += " AND PRC.SITUACAO = 'Aprovada' "
	_oSQL:_sQuery += " AND PRC.DATA   >= '20240101' "
    _oSQL:_sQuery += " ORDER BY PRC.DATA DESC "
	dbUseArea(.T., "TOPCONN", TCGenQry(,,_oSQL:_sQuery ), "TRA", .F., .T.)
	TRA->(DbGotop())	
	
	DbSelectArea("ARQ")
	DbGotop()

	While  TRA->(!Eof())	
		DbSelectArea("ARQ")	
		RecLock("ARQ",.T.)	
			
		ARQ->CODMER  :=  TRA->CODMER		
		ARQ->CLIENTE :=  TRA->CLIENTE		
		ARQ->REPRES  :=  TRA->REPRES		
		ARQ->DTGER   :=  TRA->DTGER	
		MsunLock()	
		TRA->(DbSkip())
	Enddo
	TRA->(DbCloseArea())
	
	aCpoBro	:= {{ "OK"			,, "Mark"           ,"@!"			},;			
				{ "CODMER"		,, "Cod.Mercanet"   ,"@E 9999999999"},;			
				{ "CLIENTE"		,, "Cliente"        ,"@!"			},;			
				{ "REPRES"		,, "Representante"  ,"@!"			},;			
				{ "DTGER"		,, "Dt,Geração"   	,""				}}			

	DEFINE MSDIALOG oDlg TITLE "Escolha  item para visualização" From 9,0 To 315,800 PIXEL
	
	DbSelectArea("ARQ")
	DbGotop()

	oMark := MsSelect():New("ARQ","OK","",aCpoBro,@lInverte,@cMark,{17,1,150,400})
	oMark:bMark := {|| _MarcaOpc()} 
	ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg,{|| _MostraErro()},{|| oDlg:End()})
	
	dbSelectArea("ARQ")
	ARQ->(DbCloseArea())

	u_arqtrb ("FechaTodos",,,, @_aArqTrb) 
	
	U_ML_SRArea (_aAreaAnt)
Return
//
// --------------------------------------------------------------------------
// Funcao executada ao Marcar/Desmarcar um registro.   
Static Function _MarcaOpc()
	Local _aAreaAnt := U_ML_SRArea ()
	
	RecLock("ARQ",.F.)

	If Marked("OK")	
		ARQ->OK := cMark
	Else	
		ARQ->OK := ""
	Endif   
	          
	MsUnlock()
	oMark:oBrowse:Refresh()
	
	U_ML_SRArea (_aAreaAnt)
Return
//
// --------------------------------------------------------------------------
// Busca registros de erros  
Static Function _MostraErro()
	Local _aAreaAnt  := U_ML_SRArea ()
	Local _x         := 0
	Local _aDados	 := {}
	local _aDados1   := {}

	dbSelectArea("ARQ")
	dbGotop()

	While ARQ->(!EoF())      
		If ARQ->OK == cMark
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := "" 
			_oSQL:_sQuery += " SELECT "
			_oSQL:_sQuery += " 	 	 DATA "
			_oSQL:_sQuery += " 		,HORA "
			_oSQL:_sQuery += " 		,PRODUTO "
			_oSQL:_sQuery += " 		,DESCRITIVO "
			_oSQL:_sQuery += " FROM VA_VEVENTOS "
			_oSQL:_sQuery += " WHERE CODEVENTO = 'ZA4001' "
			_oSQL:_sQuery += " AND PRODUTO = '" + alltrim(str(ARQ->CODMER)) + "' "
			_oSQL:_sQuery += " ORDER BY DATA, HORA DESC "
			_aDados1 := _oSQL:Qry2Array ()

			For _x :=1 to Len(_aDados1)
				aAdd(_aDados,   {   _aDados1[_x, 1] ,;
									_aDados1[_x, 2] ,;
									_aDados1[_x, 3] ,;
									_aDados1[_x, 4] ,;
												.F.  ;
								})
			Next
		EndIf
		
		ARQ->(dbskip())     
	EndDo
		
	oDlg:End()
	U_ML_SRArea (_aAreaAnt)

	_TelaErro(_aDados)
Return .T.
//
// --------------------------------------------------------------------------
// Mostra tela de erros
Static function _TelaErro(_aErros)
	local   _oDlg       := NIL
	private _oTxtBrw1   := NIL
	private _oGetD1     := NIL
	private _aHeader    := {}
	private _aCols1     := {}

	_aHeader   := aclone(U_GeraHead("ZZZ", .T., {}, {"ZZZ_17DATA", "ZZZ_17HORA", "ZZZ_17CODMER", "ZZZ_17ERRO"}, .T.))
    _aHead1    := aclone(_aHeader)
	_aCols1    := {} 	
	_aCols1    := _aErros			    // incluir os valores das colunas
	_aSize     := MsAdvSize()		    // Define tamanho da tela.

	define MSDialog _oDlg from _aSize [1], _aSize [1] to _aSize [6], _aSize [5] of oMainWnd pixel title "Verbas - Erros"
	
    _oGetD1 := MsNewGetDados ():New (   40									,;		// Limite superior
		                                5									,;      // Limite esquerdo
		                                _oDlg:nClientHeight / 2 - 28		,;      // Limite inferior
		                                _oDlg:nClientWidth / 2 - 10			,;      // Limite direito    
		                                							        ,; 		// [ nStyle ]
		                                ""					                ,;  	// [ Linha OK]
		                                ""						            ,;  	// [ uTudoOk ]
		                                NIL									,; 		// [cIniCpos]
		                                NIL									,; 		// [ aAlter ]
		                                NIL									,; 		// [ nFreeze ]
		                                999									,; 		// [ nMax ]
		                                NIL									,; 		// [ cFieldOk ]
		                                NIL									,;		// [ uSuperDel ]
		                                NIL									,; 		// [ uDelOk ]
		                                _oDlg								,; 		// [ oWnd ]
		                                _aHead1								,; 		// [ ParHeader ]
		                                _aCols1						 		) 		// [ aParCols ]
    
     // Define botoes para a barra de ferramentas
	_bBotaoOK  = {|| _oDlg:End ()}
	_bBotaoCan = {|| _oDlg:End ()}
    
    activate dialog _oDlg on init (EnchoiceBar(_oDlg, _bBotaoOK, _bBotaoCan,, ), _oGetD1:oBrowse:SetFocus (), "")

return
//
// --------------------------------------------------------------------------
// Mostra ultimos registros importados
User function ZA4_ULTMER()
	local   _oDlg       := NIL
	private _oTxtBrw1   := NIL
	private _oGetD1     := NIL
	private _aHeader    := {}
	private _aCols1     := {}

	_aHeader   := aclone(U_GeraHead("ZZZ", .T., {}, {"ZZZ_16CODM", "ZZZ_16PROT","ZZZ_16STAT", "ZZZ_16CLI", "ZZZ_16REP", "ZZZ_16DGER", "ZZZ_16DVCT","ZZZ_16DESC"}, .T.))
    _aHead1    := aclone(_aHeader)
	_aCols1    := {} 	
	_aCols1    := _BuscaUltImp()			    // incluir os valores das colunas
	_aSize     := MsAdvSize()					// Define tamanho da tela.

	define MSDialog _oDlg from _aSize [1], _aSize [1] to _aSize [6], _aSize [5] of oMainWnd pixel title "Verbas Importadas"
	
    _oGetD1 := MsNewGetDados ():New (   40									,;		// Limite superior
		                                5									,;      // Limite esquerdo
		                                _oDlg:nClientHeight / 2 - 28		,;      // Limite inferior
		                                _oDlg:nClientWidth / 2 - 10			,;      // Limite direito    
		                                							        ,; 		// [ nStyle ]
		                                ""					                ,;  	// [ Linha OK]
		                                ""						            ,;  	// [ uTudoOk ]
		                                NIL									,; 		// [cIniCpos]
		                                NIL									,; 		// [ aAlter ]
		                                NIL									,; 		// [ nFreeze ]
		                                999									,; 		// [ nMax ]
		                                NIL									,; 		// [ cFieldOk ]
		                                NIL									,;		// [ uSuperDel ]
		                                NIL									,; 		// [ uDelOk ]
		                                _oDlg								,; 		// [ oWnd ]
		                                _aHead1								,; 		// [ ParHeader ]
		                                _aCols1						 		) 		// [ aParCols ]
    
     // Define botoes para a barra de ferramentas
	_bBotaoOK  = {|| _oDlg:End ()}
	_bBotaoCan = {|| _oDlg:End ()}
    
    activate dialog _oDlg on init (EnchoiceBar(_oDlg, _bBotaoOK, _bBotaoCan,, ), _oGetD1:oBrowse:SetFocus (), "")

return
//
// --------------------------------------------------------------------------
// Ultimas verbas importadas
Static Function _BuscaUltImp()
    local _aDados  := {}
    local _aDados1 := {}
    local _x       := 1

    _sLinkSrv = U_LkServer ('MERCANET')

    _oSQL := ClsSQL():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT TOP 100 "
    _oSQL:_sQuery += " 	   PRC.CODIGO AS COD_MERCANET "
	_oSQL:_sQuery += "    ,ZA4.ZA4_NUM AS COD_PROTHEUS "
    _oSQL:_sQuery += "    ,PRC.SITUACAO AS ETAPA "
    _oSQL:_sQuery += "    ,RIGHT(REPLICATE('0', 6) + CONVERT(VARCHAR, PRC.CLIENTE), 6) + ' - ' + SA1.A1_NOME AS CLIENTE "
    _oSQL:_sQuery += "    ,CONVERT(VARCHAR, DB_TBREP_CODORIG) + ' - ' + SA3.A3_NOME AS REPRESENTANTE "
    _oSQL:_sQuery += "    ,PRC.DATA AS DT_GERACAO "
    _oSQL:_sQuery += "    ,PRC.DATA_1 AS DT_VENCTO "
    _oSQL:_sQuery += "    ,CONVERT(VARCHAR(2000), PRC.DESCRICAO) AS DESCRICAO "
    _oSQL:_sQuery += " FROM "+ _sLinkSrv +".DB_OC_PRINCIPAL PRC "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_OC_ITENS ITE "
    _oSQL:_sQuery += " 	ON ITE.CODIGO_OC = 37400002 "
    _oSQL:_sQuery += " 		AND ITE.SEQUENCIA = VERBA_TIPO "
    _oSQL:_sQuery += " 		AND ITE.OPD_PERGUNTA = 105 "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_OC_ITENS ITE1 "
    _oSQL:_sQuery += " 	ON ITE1.CODIGO_OC = 37400002 "
    _oSQL:_sQuery += " 		AND ITE1.SEQUENCIA = PRC.LIBERACAO_TIPO "
    _oSQL:_sQuery += " 		AND ITE1.OPD_PERGUNTA = 106 "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_OC_ATIVIDADES ATI "
    _oSQL:_sQuery += " 	ON ATI.CODIGO_OC = PRC.CODIGO "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_CLIENTE CLI "
    _oSQL:_sQuery += " 	ON CLI.DB_CLI_CODIGO = PRC.CLIENTE "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_OC_ITENS BANCO "
    _oSQL:_sQuery += " 	ON BANCO.CODIGO_OC = 37400002 "
    _oSQL:_sQuery += " 		AND BANCO.OPD_PERGUNTA = 103 "
    _oSQL:_sQuery += " 		AND BANCO.SEQUENCIA = PRC.BANCO "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("ZA3") + " ZA3 "
    _oSQL:_sQuery += " 	ON ZA3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND ZA3.ZA3_COD = RIGHT(REPLICATE('0', 3) + CONVERT(VARCHAR, ITE.OPD_CODIGO), 3) "
    _oSQL:_sQuery += " INNER JOIN "+ _sLinkSrv +".DB_TB_REPRES "
    _oSQL:_sQuery += " 	ON DB_TBREP_CODIGO = PRC.REPRESENTANTE "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SA1") + " SA1 "
    _oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND A1_COD = RIGHT(REPLICATE('0', 6) + CONVERT(VARCHAR, PRC.CLIENTE), 6) "
    _oSQL:_sQuery += " 		AND SA1.A1_LOJA = '01' "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SA3") + " SA3 "
    _oSQL:_sQuery += " 	ON SA3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SA3.A3_COD = DB_TBREP_CODORIG "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("ZA4") + " ZA4 "
	_oSQL:_sQuery += "  ON ZA4.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND ZA4.ZA4_NUMMER = PRC.CODIGO "
    _oSQL:_sQuery += " WHERE PRC.TIPO = 1 "
    _oSQL:_sQuery += " AND PRC.SITUACAO = 'Aprovada' "
    _oSQL:_sQuery += " ORDER BY PRC.DATA DESC "
    _aDados1 := _oSQL:Qry2Array ()

    For _x :=1 to Len(_aDados1)
        aAdd(_aDados,   {   _aDados1[_x, 1] ,;
                            _aDados1[_x, 2] ,;
                            _aDados1[_x, 3] ,;
                            _aDados1[_x, 4] ,;
                            _aDados1[_x, 5] ,;
                            _aDados1[_x, 6] ,;
                            _aDados1[_x, 7] ,;
                            _aDados1[_x, 8] ,;
                                        .F.;
                        })
    Next

Return _aDados
//
// --------------------------------------------------------------------------
// Produtos e %
User function ZA4_PROPER()
	local _oDlg         := NIL
	local _x            := 0
	private _oTxtBrw1   := NIL
	private _oGetD1     := NIL
	private _aHeader    := {}
	private _aCols      := {}

	if za4->za4_status == 'L'
		u_help("Verba já liberada, não é possível realizar manutenção!")
	else
		_aHeader   := aclone(U_GeraHead("ZZZ", .T., {}, {"ZZZ_18PROD", "ZZZ_18DESC","ZZZ_18PERC"}, .T.))
		_aHead1    := aclone(_aHeader)
		_aCols1    := {} 	
		_aCols1 := _BuscaProds()

		_aLinVazia := aclone(U_LinVazia(_aHeader))
		for _x:=1 to 50
			aadd (_aCols1, aclone (_aLinVazia))
		next
		//_aCols1    := _BuscaUltImp()			    // incluir os valores das colunas
		_aSize     := MsAdvSize()					// Define tamanho da tela.

		define MSDialog _oDlg from _aSize [1], _aSize [1] to _aSize [6], _aSize [5] of oMainWnd pixel title "% de produtos de verbas"
		
		_oGetD1 := MsNewGetDados ():New (   40									,;		// Limite superior
											5									,;      // Limite esquerdo
											_oDlg:nClientHeight / 2 - 28		,;      // Limite inferior
											_oDlg:nClientWidth / 2 - 10			,;      // Limite direito    
											GD_INSERT + GD_UPDATE + GD_DELETE   ,; 		// [ nStyle ]
											"AllwaysTrue ()"					,;  	// [ Linha OK]
											"AllwaysTrue ()"					,;  	// [ uTudoOk ]
											NIL									,; 		// [cIniCpos]
											NIL									,; 		// [ aAlter ]
											NIL									,; 		// [ nFreeze ]
											NIL									,; 		// [ nMax ]
											NIL									,; 		// [ cFieldOk ]
											NIL									,;		// [ uSuperDel ]
											NIL									,; 		// [ uDelOk ]
											_oDlg								,; 		// [ oWnd ]
											_aHead1								,; 		// [ ParHeader ]
											_aCols1						 		) 		// [ aParCols ]
		
		// Define botoes para a barra de ferramentas
		_bBotaoOK  = {|| processa({||_GravaZC2()}), _oDlg:End ()}
		_bBotaoCan = {|| _oDlg:End ()}
		
		activate dialog _oDlg on init (EnchoiceBar(_oDlg, _bBotaoOK, _bBotaoCan,, ), _oGetD1:oBrowse:SetFocus (), "")
	endif
return

Static Function _GravaZC2()
	local _x     := 0
	private aHeader  := aclone (_oGetD1:aHeader)
	private aCols    := aclone (_oGetD1:aCols)
	private N        := _oGetD1:nAt

	for _x = 1 to len (aCols)
		N := _x
		if !empty(aCols[_x, 1])
			_sProd := aCols[_x, 1]
			_nPerc := aCols[_x, 3]

			DbSelectArea("ZC2")
			ZC2 ->(dbsetorder(1)) // ZC2_FILIAL + ZC2_VERBA + ZC2_CLIENT + ZC2_LOJA + ZC2_PROD  

			if DbSeek(xfilial("ZC2") + ZA4->ZA4_NUM + ZA4->ZA4_CLI + ZA4->ZA4_LOJA + _sProd, .F.)
				reclock("ZC2", .F.)
				If GDDeleted()
					DBDelete()
				else 
					ZC2->ZC2_PERC := _nPerc
				endif	
				msunlock()
			Else
				reclock("ZC2", .T.)
					ZC2->ZC2_FILIAL := '  '
					ZC2->ZC2_VERBA  := ZA4->ZA4_NUM
					ZC2->ZC2_CLIENT := ZA4->ZA4_CLI
					ZC2->ZC2_LOJA   := ZA4->ZA4_LOJA
					ZC2->ZC2_PROD   := _sProd
					ZC2->ZC2_PERC   := _nPerc
					ZC2->ZC2_TIPO   := 'P'    
				msunlock()
			EndIf                                                                                        
		else
			Exit
		endif
	Next 

Return
//
// --------------------------------------------------------------------------
// Busca produtos incluidos
Static Function _BuscaProds()
    local _aDados  := {}
    local _aDados1 := {}
    local _x       := 1

    _sLinkSrv = U_LkServer ('MERCANET')

    _oSQL := ClsSQL():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += "     ZC2_PROD "
	_oSQL:_sQuery += "    ,SB1.B1_DESC "
	_oSQL:_sQuery += "    ,ZC2_PERC "
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZC2") + " ZC2 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery += " 	ON SB1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND ZC2.ZC2_PROD = SB1.B1_COD "
	_oSQL:_sQuery += " WHERE ZC2.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND ZC2.ZC2_VERBA    = '" + ZA4->ZA4_NUM  + "' "
	_oSQL:_sQuery += " AND ZC2.ZC2_CLIENT   = '" + ZA4->ZA4_CLI  + "' "
	_oSQL:_sQuery += " AND ZC2.ZC2_LOJA     = '" + ZA4->ZA4_LOJA + "' "
    _aDados1 := _oSQL:Qry2Array ()

    For _x :=1 to Len(_aDados1)
        aAdd(_aDados,   {   _aDados1[_x, 1] ,;
                            _aDados1[_x, 2] ,;
                            _aDados1[_x, 3] ,;
                                          .F.;
                        })
    Next

Return _aDados
//
// --------------------------------------------------------------------------
// Exporta tabela de percentuais
User Function ZA4_PROEXP()
	local _oSQL   := NIL
	private cPerg := "ZA4_PROEXP"
	
	_ValidPerg()
	if pergunte (cPerg, .T.)

		procregua (10)
		incproc ("Gerando arquivo")

		// Busca dados
		incproc ("Buscando dados")
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += "     ZC2_VERBA "
		_oSQL:_sQuery += "    ,ZC2_CLIENT "
		_oSQL:_sQuery += "    ,ZC2_LOJA "
		_oSQL:_sQuery += "    ,A1_NOME "
		_oSQL:_sQuery += "    ,ZC2_PROD "
		_oSQL:_sQuery += "    ,B1_DESC "
		_oSQL:_sQuery += "    ,ZC2_PERC "
		_oSQL:_sQuery += "    ,CASE "
		_oSQL:_sQuery += " 			WHEN ZC2_TIPO = 'R' THEN 'RATEIO' "
		_oSQL:_sQuery += " 			ELSE 'PRODUTO' "
		_oSQL:_sQuery += " 	   END TIPO "
		_oSQL:_sQuery += " FROM ZC2010 ZC2 "
		_oSQL:_sQuery += " INNER JOIN SA1010 SA1 "
		_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SA1.A1_COD = ZC2.ZC2_CLIENT "
		_oSQL:_sQuery += " 		AND SA1.A1_LOJA = ZC2.ZC2_LOJA "
		_oSQL:_sQuery += " INNER JOIN SB1010 SB1 "
		_oSQL:_sQuery += " 	ON SB1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SB1.B1_COD = ZC2_PROD "
		_oSQL:_sQuery += " WHERE ZC2.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " AND ZC2.ZC2_VERBA  BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
		_oSQL:_sQuery += " AND ZC2.ZC2_CLIENT BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"' "
		_oSQL:_sQuery += " AND ZC2.ZC2_PROD   BETWEEN '"+ mv_par05 +"' AND '"+ mv_par06 +"' "
		Do case
			Case mv_par07 == 1
				_oSQL:_sQuery += " ORDER BY ZC2_VERBA "
			Case mv_par07 == 2
				_oSQL:_sQuery += " ORDER BY ZC2_CLIENT "
			Case mv_par07 == 3
				_oSQL:_sQuery += " ORDER BY ZC2_PROD "
		EndCase
		
		_oSQL:ArqDestXLS = 'ZA4_PROEXP'
		_oSQL:Log ()
		_oSQL:Qry2Xls (.F., .F., .F.)
	endif
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}

	//                 Ordem Descri                  tipo tam dec valid F3     opcoes (combo)        			help
	aadd(_aRegsPerg, {01, "Verba de                ", "C", 6,  0,  "",   "ZA4", {},                   			""})
	aadd(_aRegsPerg, {02, "Verba até               ", "C", 6,  0,  "",   "ZA4", {},                   			""})
	aadd(_aRegsPerg, {03, "Cliente de              ", "C", 6,  0,  "",   "SA1", {},                   			""})
	aadd(_aRegsPerg, {04, "Cliente até             ", "C", 6,  0,  "",   "SA1", {},                   			""})
	aadd(_aRegsPerg, {05, "Produto de              ", "C", 15, 0,  "",   "SB1", {},                   			""})
	aadd(_aRegsPerg, {06, "Produto até             ", "C", 15, 0,  "",   "SB1", {},                   			""})
	aadd(_aRegsPerg, {07, "Ordenação               ", "N",  1, 0,  "",   "SB1", {"Verba","Cliente","Produto"},  ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
