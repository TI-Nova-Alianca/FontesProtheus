// Programa.: VA_PEDMRG
// Autor....: Cláudia Lionço
// Data.....: 18/12/2023
// Descricao: Cálculo de margem de contribuicao no pedido de venda.
//            Definições baseadas no programa VA_MCPED.prw
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Cálculo de margem de contribuicao no pedido de venda.
// #PalavasChave      #margem #pedido_de_venda
// #TabelasPrincipais #SC5 #SC6
// #Modulos           #FAT 
//
// Historico de alteracoes:
// 18/01/2024 - Claudia - Alterada a filial para a filial atendida. GLPI 14643
// 26/01/2024 - Claudia - Alterada rotina de frete. GLPI: 14811
// 29/02/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
// 20/05/2024 - Claudia - Ajustado calculo de rapel para MG. GLPI: 15491
// 10/06/2024 - Claudia - Ajustado os tipos de pedidos que calculam margem. 
// 01/07/2024 - Claudia - Gravação de total de frete. GLPI: 15648
//
// ------------------------------------------------------------------------------------------------------------------------
#include "VA_Inclu.prw"
#include "rwmake.ch"

User function VA_PEDMRG(_sPrgName)
	local _aAmbAnt  := U_SalvaAmb ()
	local _aAreaAnt := U_ML_SRArea ()
	
	u_log2('info', 'Iniciando calculo de margem para o pedido ' + m->c5_num)

    // Verifica se pedido já faturado ou eliminado residuo 
    // Caso positivo, não será mais gravado registros de margens para o mesmo
    if !empty(m->c5_nota) 
        u_log2('info', 'Pedido ' + m->c5_num + " ja faturado ou fechado! Não será mais calculados registros de margens! Nota:"+ m->c5_nota)
    else
        if alltrim(m->c5_tipo) $ ('D/P/I/B')
            u_log2('info', 'Pedido ' + m->c5_num + " tipo D/P/I/B! Nota:"+ m->c5_nota)
        else
            _CalcMargem(_sPrgName)
        endif
    endif

	U_ML_SRArea(_aAreaAnt)
	U_SalvaAmb(_aAmbAnt)
Return
//
// --------------------------------------------------------------------------
// Calculo de margem contribuição
static function _CalcMargem(_sPrgName)
    local _nPosPrcVen   := aScan(aHeader, {|x| AllTrim(x[2])=="C6_PRCVEN"   })
    local _nPosValor    := aScan(aHeader, {|x| AllTrim(x[2])=="C6_VALOR"    })
    local _nPosTes      := aScan(aHeader, {|x| AllTrim(x[2])=="C6_TES"      })
    local _nPosprd      := aScan(aHeader, {|x| AllTrim(x[2])=="C6_PRODUTO"  })
    local _nPosqtd      := aScan(aHeader, {|x| AllTrim(x[2])=="C6_QTDVEN"   })
    local _nPosunit     := aScan(aHeader, {|x| AllTrim(x[2])=="C6_PRUNIT"   })
    local _nPoscomis1   := aScan(aHeader, {|x| AllTrim(x[2])=="C6_COMIS1"   })
    local _nPosBlq      := aScan(aHeader, {|x| AllTrim(x[2])=="C6_BLQ"      })
    local _nPosOper     := aScan(aHeader, {|x| AllTrim(x[2])=="C6_VAOPER"   })
    local _nPosItem     := aScan(aHeader, {|x| AllTrim(x[2])=="C6_ITEM"     })
    local _sBaseRapel   := fBuscaCpo("SA1",1, xfilial("SA1") + m->c5_cliente + m->c5_lojacli, "A1_VABARAP")  // 0= nao tem rapel  1= total da nota   2 = total da mercadoria
    local _nPISCOF      := 9.25  // A cooperativa tem reducao de base de calculo
    //local _nVFrete      := 0
    local _x            := 0
    local _nTotQtd      := 0
    local _nTotPreco    := 0
    local _nTotVenda    := 0
    local _nTotCusto    := 0
    local _nTotComis    := 0
    local _nTotICMS     := 0
    local _nTotPisCof   := 0
    local _nTotRapel    := 0
    local _nTotFrete    := 0
    local _nTotFinan    := 0
    local _nTotMargem   := 0 
    local _nTotPRap     := 0
    local _aZC1         := {}    

    _sFilial := fbuscacpo("SA1",1,xFilial("SA1")+ m->c5_cliente + m->c5_lojacli,"A1_VAFILAT")

    // Busca nome do usuário de execução
    PsWorder(1)         // Ordena arquivo de senhas por ID do usuario
	PswSeek(__cUserID)  // Pesquisa usuario corrente
	_sUserName := alltrim(PswRet(1) [1, 2])

    // Busca Sequencial para ZC1
    _sSeq := _BuscaSequencial(_sFilial, m->c5_cliente, m->c5_lojacli, m->c5_num)

    // Calcula Frete e Meses para financeiro
    _nPFrete  := _CalcFrete(_sFilial)
    _nQtdDias := _CalcMeses() 
    
    MaFisEnd()  // Limpa variaveis da rotina para valor liquido dos itens do pedido

                // Inicializa para buscar valor liquido do item no pedido
    MaFisIni(   m->c5_cliente                       ,;	// 1-Codigo Cliente/Fornecedor
                m->c5_lojacli                       ,;	// 2-Loja do Cliente/Fornecedor
                IIf(m->c5_tipo $ 'DB',"F","C")      ,;	// 3-C:Cliente , F:Fornecedor
                m->c5_tipo                          ,;	// 4-Tipo da NF
                m->c5_tipocli                       ,;	// 5-Tipo do Cliente/Fornecedor
                MaFisRelImp("MT100",{"SF2","SD2"})  ,;	// 6-Relacao de Impostos que suportados no arquivo
                                                    ,;	// 7-Tipo de complemento
                                                    ,;	// 8-Permite Incluir Impostos no Rodape .T./.F.
                "SB1"                               ,;	// 9-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
                "MATA410"                           )	// 10-Nome da rotina que esta utilizando a funcao
    
    _nitem := 0
    
    for _x := 1 to Len(aCols)
        // Valida se a Linha Nao estiver deletada
        _sInclui := type("Inclui")   
        _sAltera := type("Altera")
        
        if (_sInclui == "L" .and. Inclui ) .or. (_sAltera == "L" .and. Altera)  
            _lOk := !aCols[_x, Len(aHeader) + 1]
        else
            _lOk := .T.
        endif

        // Verifica bloqueio de residuo
        if  aCols[_x, _nPosBlq] = "R"
            u_log2 ('debug', 'Bloqueio por residuo na linha ' + cvaltochar (_x))
            _lOk := .F.
        endif
        
        if _lOk
            MaFisAdd(   aCols[_x,_nPosprd]  ,;  // 1-Codigo do Produto ( Obrigatorio )
                        aCols[_x,_nPosTes]  ,;  // 2-Codigo do TES ( Opcional )
                        aCols[_x,_nPosqtd]  ,;  // 3-Quantidade ( Obrigatorio )
                        aCols[_x,_nPosunit] ,;  // 4-Preco Unitario ( Obrigatorio )
                        0                   ,;  // 5-Valor do Desconto ( Opcional )
                        NIL                 ,;	// 6-Numero da NF Original ( Devolucao/Benef )
                        NIL                 ,;	// 7-Serie da NF Original ( Devolucao/Benef )
                        NIL                 ,;	// 8-RecNo da NF Original no arq SD1/SD2
                        0                   ,;	// 9-Valor do Frete do Item ( Opcional )
                        0                   ,;	// 10-Valor da Despesa do item ( Opcional )
                        0                   ,;  // 11-Valor do Seguro do item ( Opcional )
                        0                   ,;	// 12-Valor do Frete Autonomo ( Opcional )
                        aCols[_x,_nPosvalor],;  // 13-Valor da Mercadoria ( Obrigatorio )
                        0                   ,;	// 14-Valor da Embalagem ( Opiconal )
                        0                   ,;	// 15-RecNo do SB1
                        0                    ) 	// 16-RecNo do SF4
            
            _nitem ++
            
            _sProduto := alltrim(aCols[_x,_nPosprd])
            _nQtd     := aCols[_x,_nPosqtd]
            _nVVenda  := aCols[_x,_nPosValor]
            _nVCusto  := (_nQtd * FBUSCACPO('SB1', 1, xFilial('SB1') + _sProduto,'SB1->B1_CUSTD'))
            _nVComis  := (_nVVenda * aCols[_x,_nPosComis1])/100
            _nVICMS   := mafisret(_nitem, "IT_VALICM")
            _nVPisCof := (_nVVenda * _nPISCOF)/100
            _nVRapel  := _CalcRapel(_sBaseRapel, _sProduto, m->c5_cliente, m->c5_lojacli, _nVVenda)
            _nVFreteT := iif(_nPFrete <> 0,(_nVVenda * _nPFrete)/100,0)
            _nParcFin := 0.05 * _nQtdDias           // 0,05% por dia, após os 30 primeiros
            _nVFinan  := (_nVVenda * _nParcFin)/100
            _nVMargem := _nVVenda - (_nVCusto + _nVComis + _nVPisCof + _nVICMS + _nVRapel + _nVFreteT + _nVFinan)
            _nPMargem := (_nVMargem / _nVVenda) * 100
            _nTxRapel := u_va_rapel(m->c5_cliente, m->c5_lojacli, _sProduto) // Busca Rapel do cliente

            if FBuscaCpo("SF4",1,XFILIAL("SF4")+aCols[_x,_nPosTes],"F4_DUPLIC") <> "N"

                // Campos ZC1
                aadd(_aZC1, {   _sFilial                        ,;  // ZC1_FILIAL
                                'VD'                            ,;  // ZC1_TIPO
                                m->c5_cliente                   ,;  // ZC1_CLI 
                                m->c5_lojacli                   ,;  // ZC1_LOJA
                                m->c5_num                       ,;  // ZC1_PED
                                aCols[_x,_nPosOper]             ,;  // ZC1_OPER 
                                alltrim(aCols[_x,_nPosItem])    ,;  // ZC1_ITEM
                                _sProduto                       ,;  // ZC1_PROD 
                                _sSeq                           ,;  // ZC1_SEQ
                                _nQtd                           ,;  // ZC1_QTD 
                                aCols[_x,_nPosPrcVen]           ,;  // ZC1_PRC
                                _nVVenda                        ,;  // ZC1_VVEN 
                                _nVCusto                        ,;  // ZC1_VCUS
                                (_nVCusto/_nVVenda) * 100       ,;  // ZC1_PCUS
                                _nVComis                        ,;  // ZC1_VCOM 
                                (_nVComis/_nVVenda) * 100       ,;  // ZC1_PCOM
                                _nVICMS                         ,;  // ZC1_VICMS 
                                (_nVICMS/_nVVenda) * 100        ,;  // ZC1_PICMS
                                _nVPisCof                       ,;  // ZC1_VPC
                                (_nVPisCof/_nVVenda) * 100      ,;  // ZC1_PPC 
                                _nVRapel                        ,;  // ZC1_VRAP
                                _nTxRapel                       ,;  // ZC1_PRAP 
                                _nVFreteT                       ,;  // ZC1_VFRE
                                (_nVFreteT/_nVVenda) * 100      ,;  // ZC1_PFRE
                                _nVFinan                        ,;  // ZC1_VFIN 
                                (_nVFinan/_nVVenda) * 100       ,;  // ZC1_PFIN
                                _nVMargem                       ,;  // ZC1_VMAR 
                                _nPMargem                       ,;  // ZC1_PMAR
                                date()                          ,;  // ZC1_DATA
                                time()                          ,;  // ZC1_HORA
                                _sUserName                      ,;  // ZC1_USER
                                _sPrgName                       })  // ZC1_PRG

                // Totalizadores do pedido
                _nTotQtd    += _nQtd
                _nTotPreco  += aCols[_x,_nPosPrcVen]
                _nTotVenda  += _nVVenda
                _nTotCusto  += _nVCusto
                _nTotComis  += _nVComis
                _nTotICMS   += _nVICMS
                _nTotPisCof += _nVPisCof
                _nTotRapel  += _nVRapel
                //_nTotPRap   += _nTxRapel
                _nTotFrete  += _nVFreteT
                _nTotFinan  += _nVFinan
                _nTotMargem += _nVMargem 
            endif
        endif
    next

    // Limpa variaveis da rotina para valor liquido dos itens do pedido
    MaFisEnd()

    // Imprime totalizador de pedido
    if len(_aZC1) > 0
        aadd(_aZC1, {   _sFilial                    ,;  // ZC1_FILIAL
                        'TP'                        ,;  // ZC1_TIPO
                        m->c5_cliente               ,;  // ZC1_CLI 
                        m->c5_lojacli               ,;  // ZC1_LOJA
                        m->c5_num                   ,;  // ZC1_PED
                        '00'                        ,;  // ZC1_OPER 
                        '99'                        ,;  // ZC1_ITEM
                        ''                          ,;  // ZC1_PROD 
                        _sSeq                       ,;  // ZC1_SEQ
                        _nTotQtd                    ,;  // ZC1_QTD 
                        _nTotPreco                  ,;  // ZC1_PRC
                        _nTotVenda                  ,;  // ZC1_VVEN 
                        _nTotCusto                  ,;  // ZC1_VCUS
                        (_nTotCusto/_nTotVenda)*100 ,;  // ZC1_PCUS
                        _nTotComis                  ,;  // ZC1_VCOM 
                        (_nTotComis/_nTotVenda)*100 ,;  // ZC1_PCOM
                        _nTotICMS                   ,;  // ZC1_VICMS 
                        (_nTotICMS/_nTotVenda)*100  ,;  // ZC1_PICMS
                        _nTotPisCof                 ,;  // ZC1_VPC
                        (_nTotPisCof/_nTotVenda)*100,;  // ZC1_PPC 
                        _nTotRapel                  ,;  // ZC1_VRAP
                        _nTotPRap                   ,;  // ZC1_PRAP 
                        _nTotFrete                  ,;  // ZC1_VFRE
                        (_nTotFrete/_nTotVenda)*100 ,;  // ZC1_PFRE
                        _nTotFinan                  ,;  // ZC1_VFIN 
                        (_nTotFinan/_nTotVenda)*100 ,;  // ZC1_PFIN
                        _nTotMargem                 ,;  // ZC1_VMAR 
                        (_nTotMargem/_nTotVenda)*100,;  // ZC1_PMAR
                        date()                      ,;  // ZC1_DATA
                        time()                      ,;  // ZC1_HORA
                        _sUserName                  ,;  // ZC1_USER
                        _sPrgName                   })  // ZC1_PRG

    endif
    
    // Calcula total da margem do pedido e grava no pedido de venda
	m->c5_vaMCont := (_nTotMargem/_nTotVenda) * 100 
    u_log2('info', 'Margem calculada: ' + cvaltochar(m->c5_vaMCont))

    // Grava total do frete
    m->c5_mvfre := _nTotFrete // _nVFreteT
    u_log2('info', 'Frete calculado: ' + cvaltochar(m->c5_vaMCont))

    // Grava campos quando pedido já em tabela -> 
    // feito porque caso o ususario não salve o pedido, os itens não estavam sendo atualizados
    _GravaCampos(_sFilial)

    // Grava dados na ZC1
    _GravaZC1(_aZC1)
Return 
//
// ----------------------------------------------------------------------------------------------------
// Retorna sequencial ZC1
Static Function _BuscaSequencial(_sFilial, _sCliente, _sLoja, _sPedido)
    local _sSeq := ""
    local _aSeq := {}
    local _x    := 0

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	    CASE "
    _oSQL:_sQuery += " 		    WHEN MAX(ZC1_SEQ) IS NULL THEN 1 "
    _oSQL:_sQuery += " 		    ELSE CAST(MAX(ZC1_SEQ) + 1 AS NUMERIC)  "
    _oSQL:_sQuery += " 	    END AS SEQ "
    _oSQL:_sQuery += " FROM ZC1010 "
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND ZC1_FILIAL   = '"+ _sFilial  +"' "
    _oSQL:_sQuery += " AND ZC1_CLI      = '"+ _sCliente +"' "
    _oSQL:_sQuery += " AND ZC1_LOJA     = '"+ _sLoja    +"' "
    _oSQL:_sQuery += " AND ZC1_PED      = '"+ _sPedido  +"' "
    _aSeq := aclone(_oSQL:Qry2Array(.f., .f.))

    For _x := 1 to Len(_aSeq)
        _sSeq := PADL(alltrim(str(_aSeq[_x, 1])),3,'0')
    Next
Return _sSeq
//
// ----------------------------------------------------------------------------------------------------
// Retorna % do frete
Static Function _CalcFrete(_sFilial)
    local _oSQL      := NIL
    local _x	     := 0
    local _aGU9      := {}
    local _nPerFrete := 0

        // Considera frete zerado
    if M->C5_TPFRETE $ 'FTDS'  // C=CIF;F=FOB;T=Por conta terceiros;R=Por conta remetente;D=Por conta destinatário;S=Sem frete                                    
		_nPerFrete  := 0
	else
        // Busca o % frete do cabeçalho
        _oSQL := ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += " 		GU9_VAPFRE "
        _oSQL:_sQuery += " FROM " + RetSQLName ("GU9") 
        _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
        _oSQL:_sQuery += " AND GU9_FILIAL   = '" + _sFilial     + "'"
        _oSQL:_sQuery += " AND GU9_CDUF     = '" + m->c5_vaest  + "'"
        _oSQL:_sQuery += " AND GU9_SIT      = '1'"
        _aGU9:= aclone(_oSQL:Qry2Array(.f., .f.))

        for _x:=1 to Len(_aGU9)
            _nPerFrete := _aGU9[_x, 1]
        next

        if _nPerFrete == 0
            // sem percentual de frete
            _oEvento := ClsEvent():New()
            _oEvento:Alias     = 'GU9'
            _oEvento:Texto     = "Não encontrado % de frete para filial:" + _sFilial + " estado:" + m->c5_vaest
            _oEvento:CodEven   = "GU9001"
            _oEvento:PedVenda  = m->c5_num
            _oEvento:Cliente   = m->c5_cliente
            _oEvento:LojaCli   = m->c5_lojacli
            _oEvento:Grava()
        endif
    endif
    // u_log2('info', 'Valor frete pós calculo: ' + cvaltochar(m->c5_mvfre))

Return _nPerFrete
//
// ----------------------------------------------------------------------------------------------------
// Calcula quantidade de 'meses completos' para aplicar % de acrescimo financeiro a cada 30 dias
Static Function _CalcMeses()
    local _nDataIni  := 0
	local _nDataFim  := 0
	local _nQtdDias  := 0
    local _sDataInfo := 'N'
	
	if .not. Empty(M->C5_DATA1)
		_sDataInfo = 'S'
		_nDataIni = (M->C5_DATA1)
		_nDataFim = (M->C5_DATA1)
	endif

	if .not. Empty(M->C5_DATA2)
		_sDataInfo = 'S'
		_nDataFim = (M->C5_DATA2)
	endif

	if .not. Empty(M->C5_DATA3)
		_sDataInfo = 'S'
		_nDataFim = (M->C5_DATA3)
	endif

	if .not. Empty(M->C5_DATA4)
		_sDataInfo = 'S'
		_nDataFim = (M->C5_DATA4)
	endif

	if .not. Empty(M->C5_DATA5)
		_sDataInfo = 'S'
		_nDataFim = (M->C5_DATA5)
	endif

	if .not. Empty(M->C5_DATA6)
		_sDataInfo = 'S'
		_nDataFim = (M->C5_DATA6)
	endif

	if .not. Empty(M->C5_DATA7)
		_sDataInfo = 'S'
		_nDataFim = (M->C5_DATA7)
	endif

	if .not. Empty(M->C5_DATA8)
		_sDataInfo = 'S'
		_nDataFim = (M->C5_DATA8)
	endif

	if .not. Empty(M->C5_DATA9)
		_sDataInfo = 'S'
		_nDataFim = (M->C5_DATA9)
	endif

	if .not. Empty(M->C5_DATAA)
		_sDataInfo = 'S'
		_nDataFim = (M->C5_DATAA)
	endif

	if .not. Empty(M->C5_DATAB)
		_sDataInfo = 'S'
		_nDataFim = (M->C5_DATAB)
	endif

	if .not. Empty(M->C5_DATAC)
		_sDataInfo = 'S'
		_nDataFim = (M->C5_DATAC)
	endif

	if _sDataInfo = 'N'
		_aVctos = aclone (Condicao(1000, m->c5_condpag,, date()))
	else
		_aVctos := {}
		AADD(_aVctos,{_nDataIni,1})
		AADD(_aVctos,{_nDataFim,1})
	endif
	
	// Se nao gera duplicata, assume a data atual.
	if len(_aVctos) == 0
		u_log2 ('info', "Condicao de pagamento nao gerou nenhuma parcela. Assumindo data atual.")
		_nDataIni := date()
		_nDataFim := date()
	else
		_nDataIni := _aVctos[1,1]
		_nDataFim := _aVctos[Len(_aVctos),1]
	endif
	
	if _sDataInfo = 'N'
		_nDias := _BuscaDiasMedio(m->c5_condpag)
		if _nDias > 30
			_nQtdDias = _nDias
		endif
	else
		if m->c5_condpag != '007' .and. _nDataIni >= DATE() + 30 
			_nQtdDias = ((_nDataIni - DATE() + _nDataFim - DATE()) / 2 )
		endif
	endif
Return _nQtdDias
//
// ----------------------------------------------------------------------------------------------------
// Calcula valor de rapel 
Static Function _CalcRapel(_sBaseRapel, _sProduto, _sCliente, _sLoja, _nVVenda)
    local _nTxRapel := 0
    local _sEst     := ""
    

    if val(_sBaseRapel) > 0  
        _nTxRapel := u_va_rapel(_sCliente, _sLoja, _sProduto)                            // Busca Rapel do cliente
        _sEst     := Posicione("SA1",1, xFilial("SA1") + _sCliente + _sLoja, "A1_EST")   // Estado do cliente
        _nValIpi  := MaFisRet(_nitem, "IT_VALIPI")   // IPI
		_nValSt   := MaFisRet(_nitem, "IT_VALSOL")   // ST

        do case 
            case _sBaseRapel == '1' // 1= base nota (merc + st + ipi)
                if _sEst $ 'MG' // MG a guia e paga pela empresa
                    _nVlrRapel := ((_nVVenda + _nValIpi) * _nTxRapel)/100
                else
                    _nVlrRapel := ((_nVVenda + _nValIpi + _nValSt) * _nTxRapel)/100
                endif
                
            case _sBaseRapel == '2' // 2 = base mecadoria									
                _nVlrRapel := (_nVVenda * _nTxRapel)/100

            case _sBaseRapel == '3' // 3 = total nf - st			
                _nVlrRapel := ((_nVVenda + _nValIpi )* _nTxRapel)/100

        endcase
    else
        _nVlrRapel := 0
    endif	
Return _nVlrRapel
//
// ----------------------------------------------------------------------------------------------------
// Calcula dias medios para pagamento
Static Function _BuscaDiasMedio(_sCondPgto)
	local _aData := {}	
	local _x     := 0
	local _nSoma := 0

	_sCond := Posicione("SE4",1,'  ' + _sCondPgto,"E4_COND")
	_aData := StrToKarr( _sCond , ',')

	If Len(_aData) > 0
		for _x:=1  to Len(_aData)
			_nSoma += val(_aData[_x])
		next
		_nDiasMedios := _nSoma/Len(_aData)
	else
		_nDiasMedios := 1
	EndIf
Return _nDiasMedios
//
// ----------------------------------------------------------------------------------------------------
// Grava campos na tabela
Static Function _GravaCampos(_sFilial)
    local _x := 0

    _oSQL := ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	    COUNT(*) "
    _oSQL:_sQuery += " FROM SC5010 "
    _oSQL:_sQuery += " WHERE C5_FILIAL = '" + _sFilial      + "' "
    _oSQL:_sQuery += " AND C5_NUM      = '" + m->c5_num     + "' "
    _oSQL:_sQuery += " AND C5_CLIENTE  = '" + m->c5_cliente + "' "
    _oSQL:_sQuery += " AND C5_LOJACLI  = '" + m->c5_lojacli + "' "
    _aPed:= aclone(_oSQL:Qry2Array(.f., .f.))

    For _x := 1 to Len(_aPed)
        if _aPed[_x, 1] > 0 // ja gravado no protheus
            _oSQL := ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " UPDATE SC5010 "
            _oSQL:_sQuery += " 	    SET C5_MVFRE = " + cvaltochar(m-> c5_mvfre) + ", C5_VAMCONT= " + cvaltochar(round(m-> c5_vaMCont,2)) 
            _oSQL:_sQuery += " FROM SC5010 "
            _oSQL:_sQuery += " WHERE C5_FILIAL = '" + _sFilial      + "' "
            _oSQL:_sQuery += " AND C5_NUM      = '" + m->c5_num     + "' "
            _oSQL:_sQuery += " AND C5_CLIENTE  = '" + m->c5_cliente + "' "
            _oSQL:_sQuery += " AND C5_LOJACLI  = '" + m->c5_lojacli + "' "
            _oSQL:Exec()
        endif
    next
Return
//
// ----------------------------------------------------------------------------------------------------
// Grava dados na ZC1
Static Function _GravaZC1(_aZC1)
    local _x := 0

    for _x:=1 to Len(_aZC1)

        RecLock("ZC1", .T.)
            ZC1 -> ZC1_FILIAL   := _aZC1[_x, 1] 	// Filial
            ZC1 -> ZC1_TIPO     := _aZC1[_x, 2]     // Tipo V-venda; B=Bonificação; T=Total	
            ZC1 -> ZC1_CLI 	    := _aZC1[_x, 3]     // Cliente
            ZC1 -> ZC1_LOJA     := _aZC1[_x, 4]     // Loja
            ZC1 -> ZC1_PED      := _aZC1[_x, 5]     // Num.Pedido
            ZC1 -> ZC1_OPER     := _aZC1[_x, 6]     // Tipo Operação
            ZC1 -> ZC1_ITEM 	:= _aZC1[_x, 7]     // Item
            ZC1 -> ZC1_PROD	    := _aZC1[_x, 8]     // Produto
            ZC1 -> ZC1_SEQ		:= _aZC1[_x, 9]     // Sequencial
            ZC1 -> ZC1_QTD		:= _aZC1[_x,10]     // Quantidade item
            ZC1 -> ZC1_PRC		:= _aZC1[_x,11]     // Vlr. Produto
            ZC1 -> ZC1_VVEN	    := _aZC1[_x,12]     // Valor Venda
            ZC1 -> ZC1_VCUS 	:= _aZC1[_x,13]     // Valor Custo Reposição
            ZC1 -> ZC1_PCUS 	:= _aZC1[_x,14]     // % Custo Reposição
            ZC1 -> ZC1_VCOM	    := _aZC1[_x,15]     // Valor comissao
            ZC1 -> ZC1_PCOM	    := _aZC1[_x,16]     // % comissão
            ZC1 -> ZC1_VICMS	:= _aZC1[_x,17]     // Valor ICMS
            ZC1 -> ZC1_PICMS	:= _aZC1[_x,18]     // % ICMS
            ZC1 -> ZC1_VPC		:= _aZC1[_x,19]     // Valor PIS/COFINS
            ZC1 -> ZC1_PPC		:= _aZC1[_x,20]     // % PIS/COFINS
            ZC1 -> ZC1_VRAP	    := _aZC1[_x,21]     // Valor Rapel
            ZC1 -> ZC1_PRAP	    := _aZC1[_x,22]     // % Rapel
            ZC1 -> ZC1_VFRE	    := _aZC1[_x,23]     // Valor Frete
            ZC1 -> ZC1_PFRE	    := _aZC1[_x,24]     // % Frete _pFrete
            ZC1 -> ZC1_VFIN	    := _aZC1[_x,25]     // Valor Financeiro
            ZC1 -> ZC1_PFIN	    := _aZC1[_x,26]     // % Financeiro
            ZC1 -> ZC1_VMAR	    := _aZC1[_x,27]     // Valor Margem
            ZC1 -> ZC1_PMAR	    := _aZC1[_x,28]     // % Margem _pMargem
            ZC1 -> ZC1_DATA	    := _aZC1[_x,29]     // Data Inclusao
            ZC1 -> ZC1_HORA	    := _aZC1[_x,30]     // Hora Inclusao
            ZC1 -> ZC1_USER	    := _aZC1[_x,31]     // Usuario Inclusao
            ZC1 -> ZC1_PRG	    := _aZC1[_x,32]     // Programa da chamada

        MsUnlock()
    next
Return
