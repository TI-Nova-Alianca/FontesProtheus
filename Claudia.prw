#include 'protheus.ch'
#include 'parmtype.ch'

User Function claudia ()
	if ! alltrim(upper(cusername)) $ 'CLAUDIA.LIONCO/ADMINISTRADOR'
		msgalert ('Daqui vc nao passa :P', procname ())
		return
	endif

	u_help("Nada para executar")

	//U_BatVerbas(2, '01')

	//u_LOG("TESTE")

	//_sTeste:= Encode64('claudia.lionco'+':'+ 'Tim3M@chin3')

	//u_help("reservas")
	//U_BatReserva()

	//u_help("pESO")
	//_impPESO()

	//u_help("Ajusta SF4")
	//_ajustaSF4()

	//u_help("CRM delete")
	//_aCRM := {}
	//_deletaContatos()

	//u_help("TELA CRM")
	//U_ZCA()
	
	//u_help("IMPORTACAO CRM")
	//u_va_crmimp()

	//u_help("RAPEL")
	//U_VA_RAPCAD()
	//AxCadastro("ZBG","% de Contrato Rapel",,)

	//u_help("SAFRA")
	//_SimulaSafra23()

	//u_help("ajustes katia")
	//U_AjFiscal()

	//u_help("INCLUI COD MATRIZ ZAX")
	//_CODMATZAX()

	//u_help("Produtos enologicos")
	//_ProdEnologicos()

	//u_help("Produtos enologicos no SB5")
	//_ProdSB5()

	//u_help("Gera ZC1")
	//_GeraZC1()

	//u_help("saldo")
	//_saldo()

	//u_help("Peso")
	//_PesoProd()

	// u_help('Envia clientes para mercanet')
	// _enviaClientes()

	//u_help("verbas")
	//U_BatZA4()

	//u_help("ZC2")
	//U_ZC2()

	//u_help("CTB")
	//U_BACACTB()

	//u_help("custo ST")
	//_GLPI15288 ()

    //u_help("teste relatorio")
    //_GLPI15199()

    u_help("OP")
    u_va_xls67()

Return

static function _GLPI15199()
    u_va_xls66()
Return
// --------------------------------------------------------------------------
// Atualiza custo standard cfe planilha (inclusive itens filhos (unitarios)
static function _GLPI15288 ()
    local _aDados    := {}
    local _nDado     := 0
    local _nCustD    := 0
    local _aCSV      := {}
    local _nCSV      := 0
    local _aFilhos   := {}
    local _nFilho    := 0
    local _oSQL      := NIL
    local _nDecCustD := tamsx3 ("B1_CUSTD")[2]

    _aCSV = U_LeCSV ('c:\temp\GLPI_15288.csv', ';')
    for _nCSV = 1 to len (_aCSV)
        _aCSV [_nCSV, 3] = round (val (strtran (strtran (_aCSV [_nCSV, 3], '"', ''), ',', '.')), _nDecCustD)
    next
    U_Log2 ('debug', _aCSV)

    // Usuario deseja atualizar tambem o cadastro das unidades. Para isso
    // vou procurar os filhos de cada item do arquivo CSV (que tem somente
    // as caixas) e acrescentar esses filhos na array de dados que vai ser
    // usada para alterar os cadastros.
    sb1 -> (dbsetorder (1))
    for _nCSV = 1 to len (_aCSV)

        if ! sb1 -> (dbseek (xfilial ("SB1") + U_TamFixo (_aCSV [_nCSV, 1], 15, ' '), .F.))
            U_Log2 ('erro', '[' + procname () + ']Nao encontrado no SB1: ' + _aCSV [_nCSV, 1])
        else

            // Adiciona o pai (que estava no CSV original)
            aadd (_aDados, {_aCSV [_nCSV, 1], _aCSV [_nCSV, 2], _aCSV [_nCSV, 3]})

            // Adiciona os (se existirem) filhos dele.
            _oSQL := ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += "SELECT B1_COD, B1_DESC"
            _oSQL:_sQuery +=  " FROM " + RetSQLName ("SB1") + " SB1"
            _oSQL:_sQuery += " WHERE SB1.D_E_L_E_T_ = ''"
            _oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
            _oSQL:_sQuery +=   " AND SB1.B1_CODPAI  = '" + _aCSV [_nCSV, 1] + "'"
            _aFilhos := _oSQL:Qry2Array (.f., .f.)
            for _nFilho = 1 to len (_aFilhos)
                aadd (_aDados, {_aFilhos [_nFilho, 1], _aFilhos [_nFilho, 2], _aCSV [_nCSV, 3] / sb1 -> b1_qtdemb})
            next
        endif
    next
    U_Log2 ('debug', _aDados)

    sb1 -> (dbsetorder (1))
    sb5 -> (dbsetorder (1))
    for _nDado = 1 to len (_aDados)
        if len (_aDados [_nDado]) < 3
            U_Log2 ('erro', '[' + procname () + ']Sem custo para ' + _aDados [_nDado, 1] + ' ' + _aDados [_nDado, 2])
        else
            if ! sb1 -> (dbseek (xfilial ("SB1") + U_TamFixo (_aDados [_nDado, 1], 15, ' '), .F.))
                U_Log2 ('erro', '[' + procname () + ']Nao encontrado no SB1: ' + _aDados [_nDado, 1])
            else
                if ! sb5 -> (dbseek (xfilial ("SB5") + sb1 -> b1_cod, .F.))
                    u_log2 ('ERRO', 'Nao encontrei SB5 para o produto ' + sb1 -> b1_cod)
                else
                //  u_log2 ('info', 'Verificando item ' + sb1 -> b1_cod + SB1 -> B1_DESC)

                    _nCustD = _aDados [_nDado, 3]
                    if _nCustD == 0
                        U_Log2 ('aviso', '[' + procname () + ']'+ sb1 -> b1_cod + SB1 -> B1_DESC + ' custo zerado na planilha. Nao vou alterar.')
                    else
                        if sb1 -> b1_custd != _nCustD .or. sb1 -> B1_DATREF != date ()

                            u_log2 ('info', 'Alterando custo ' + sb1 -> b1_cod + SB1 -> B1_DESC + ' de ' + transform (sb1 -> b1_custd, '@E 999,999.9999') + ' para ' + transform (_nCustD, '@E 999,999.9999'))

                            // Cria variaveis para uso na gravacao do evento de alteracao
                            regtomemory ("SB1", .F., .F.)
                            //regtomemory ("SB5", .F., .F.)
                            //m->b5_vasisde = 'S'
                            m->b1_custd  = _nCustD
                            m->B1_DATREF = date ()

                            // Grava evento de alteracao
                            _oEvento := ClsEvent():new ()
                            _oEvento:AltCadast ("SB1", m->b1_cod, sb1 -> (recno ()), 'GLPI 15288 - ajustar B1_CUSTD', .F.)
                            reclock ("SB1", .f.)
                            sb1 -> B1_custd  = m->b1_custd
                            SB1 -> B1_DATREF = m->B1_DATREF
                            msunlock ()
                            U_AtuMerc ("SB1", sb1 -> (recno ()))

                            // Cai fora no primeiro, para testes.
                        //  exit

                        else
                            U_Log2 ('debug', '[' + procname () + ']Dados jah estavam corretos')
                        endif
                    endif
                endif
            endif
        endif
    next
return
// // ------------------------------------------------------------------------------------
// Static Function _enviaClientes()

// 	dbselectarea("SA1")
// 	sa1 -> (dbsetorder(1))
// 	sa1 -> (dbgotop())
// 	do while ! sa1 -> (eof()) 
// 		if sa1-> a1_msblql=='2'
// 			U_AtuMerc ("SA1", sa1 -> (recno ()))
// 			u_log2('info', 'Atualizado cliente:'+ sa1->a1_cod +'-'+ sa1->a1_nome)
// 		endif
// 		sa1 -> (dbskip ())
// 	enddo

// 	u_help("Atualizado!")
// Return

// // -----------------------------------------------------------------------------------
// Static Function _PesoProd()
// 	Local _aDados 	:= {}
// 	Local _i 		:= 0

// 	u_help("Ajusta Peso")
// 	_aDados = U_LeCSV('C:\Temp\peso.csv', ';')

// 	for _i := 1 to len(_aDados)
// 		_sCod   := alltrim(_aDados[_i, 1])
// 		_sPeso  := alltrim(_aDados[_i, 5])

// 		//_sPeso := strtran(_sPeso, '"', '')
//     	//_sPeso := strtran(_sPeso, ",", ".")
//     	_nPeso := val(_sPeso) 

// 		DbSelectArea("SB1")
// 		DbSetOrder(1)
// 		if DbSeek(xFilial("SB1")+ alltrim(_sCod),.F.)
// 			// Grava evento de alteracao
// 			_oEvento := ClsEvent():new ()
// 			_oEvento:Alias    = 'SB1'
// 			_oEvento:Texto    = " Peso alterado de " +  alltrim(str(sb1->b1_pesbru)) + " para " + _sPeso
// 			_oEvento:CodEven  = "SB1001"
// 			_oEvento:Produto  = sb1 -> b1_cod
// 			_oEvento:Grava() 

// 			reclock("SB1", .F.)
// 				sb1->b1_pesbru := _nPeso
// 			MsUnLock()

// 		endif	
// 	Next
// 	u_help("Atualizado!")

// Return



// Static Function _saldo()
// 	Local _nLctoCC := 0
// 	local _sError    := ''
// 	local _sWarning  := ''
// 	private _oXMLFech  := NIL 
// 	_oAssoc := ClsAssoc ():New ('002382', '01')

// 	_oAssoc:FSLctosCC = .T.
// 	_oAssoc:FSSafra      = '2023'
// 	_sXmlFech = _oAssoc:FechSafra ()
// 	_oXMLFech := XmlParser (_sXmlFech, "_", @_sError, @_sWarning)
// 	for _nLctoCC = 1 to len(_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem)

// 	next
// Return
// Static Function _GeraZC1()
// 	mBrowse(,,,,"ZC1",,,,,,,,,,,,,,)
// Return

// Static Function _ProdSB5()
// 	Local _aDados 	:= {}
//  	Local _i 		:= 0
// 	Local _x        := 0

// 	_aDados = U_LeCSV ('C:\Temp\produtos_protheusxsisdevin.csv', ';')

// 	for _i := 1 to len(_aDados)
// 		_sCodSis := PADL(alltrim(_aDados[_i,1]),3,'0')
// 		_aProd   := U_SeparaCpo(alltrim(_aDados[_i,2]), ",") 
		
// 		DbSelectArea("SB5")
// 		DbSetOrder(1)

// 		for _x:=1 to Len(_aProd)
// 			if DbSeek(xFilial("SB5") + alltrim(_aProd[_x]))	
// 				reclock("SB5", .F.)
// 					SB5->B5_VAPENO := _sCodSis
// 				MsUnLock()
// 			endif
// 		next
// 	Next
// 	u_help("finalizou")
// Return

// Static Function _ProdEnologicos()
//  	Local _aDados 	:= {}
//  	Local _i 		:= 0
// 	Local _sUM      := ''

// 	_aDados = U_LeCSV ('C:\Temp\produtos_enologicos.csv', ';')
// 	for _i := 1 to len(_aDados)
// 		_sCod   := PADL(alltrim(_aDados[_i,1]),3,'0')
// 		_sDesc  := upper(alltrim(_aDados[_i,2]))
// 		_sUM    := alltrim(_aDados[_i,3])
// 		_sValor := alltrim(_aDados[_i,4])
// 		_sEnv   := alltrim(_aDados[_i,5])

// 		_sValor := strtran(_sValor, '"', '')
//     	_sValor := strtran(_sValor, ",", ".")
//     	_nFatC  := val(_sValor) 

// 		_sChave := PADL(alltrim(str(_i)),2,'0')

// 		reclock("ZX5", .t.)
// 			zx5->zx5_tabela := '58'
// 			zx5->zx5_chave  := _sChave
// 			zx5->zx5_58cod  := _sCod
// 			zx5->zx5_58desc := _sDesc
// 			zx5->zx5_58um   := _sUM
// 			zx5->zx5_58con  := _nFatC
// 			zx5->zx5_58env  := _sEnv
// 		msunlock()

// 	Next
// 	u_help("finalizou")
// Return 

// Static Function _CODMATZAX()
// 	Local _x := 0

// 	_oSQL:= ClsSQL ():New ()
// 	_oSQL:_sQuery := ""
// 	_oSQL:_sQuery += " SELECT "
// 	_oSQL:_sQuery += " 	   ZAX.ZAX_CLIENT "
// 	_oSQL:_sQuery += "    ,ZAX.ZAX_LOJA "
// 	_oSQL:_sQuery += "	  ,ZAX_LINHA "
// 	_oSQL:_sQuery += "    ,ZAX_ITEM "
// 	_oSQL:_sQuery += "    ,SA1.A1_VACBASE "
// 	_oSQL:_sQuery += " FROM ZAX010 ZAX "
// 	_oSQL:_sQuery += " INNER JOIN SA1010 SA1 "
// 	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
// 	_oSQL:_sQuery += " 		AND SA1.A1_COD = ZAX.ZAX_CLIENT "
// 	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = ZAX.ZAX_LOJA "
// 	_oSQL:_sQuery += " WHERE ZAX.D_E_L_E_T_ = '' "
// 	_aDados := aclone(_oSQL:Qry2Array())

// 	For _x:=1 to Len(_aDados)

// 		DbSelectArea("ZAX")
// 		DbSetOrder(3) // ZAX_FILIAL+ZAX_CLIENT+ZAX_LOJA+ZAX_LINHA+ZAX_ITEM 
// 		if DbSeek(xFilial("ZAX") + _aDados[_x,1] + _aDados[_x,2] + _aDados[_x,3] + _aDados[_x,4] ,.F.)
// 			reclock ("ZAX", .f.)
// 				ZAX -> ZAX_CODMAT := _aDados[_x,5]
// 				ZAX -> ZAX_LOJMAT := '01'
// 			msunlock ()
// 		endif	
// 	Next

// Return

// Static Function _deletaContatos()
//  	Local _aDados 	:= {}
//  	Local _i 		:=0

// 	_aDados = U_LeCSV ('C:\Temp\deleta.csv', ';')
// 	for _i := 1 to len(_aDados)
// 		_sIdExt := _aDados[_i,1]
// 		_sIdErp := ''//iif(empty(_aDados[_i,2]),'',_aDados[_i,2])

// 		U_VA_CRM(_aCRM, 'D', _sIdExt, _sIdErp)

// 	next
// Return
// //
// // -----------------------------------------------------------------------------------
// Static Function _ajustaSF4()
// 	Local _aDados 	:= {}
// 	Local _i 		:=0

// 	u_help("SF4")
// 	_aDados = U_LeCSV ('C:\Temp\impSF4.csv', ';')

// 	DbSelectArea("SF4")
// 	DbSetOrder(1)

// 	for _i := 1 to len(_aDados)
// 		_sTES   := PADL(alltrim(_aDados[_i, 1]),3,'0')
// 		_sCod   := PADL(alltrim(_aDados[_i, 2]),2,'0')

// 		If DbSeek(xFilial("SF4") + _sTES)
// 			_sCodOld := sf4->f4_vasito
// 			RecLock("SF4",.F.)
// 				sf4->f4_vasito := _sCod
// 			msunlock()

// 			_oEvento := ClsEvent():new ()
// 			_oEvento:Alias    = "SF4"
// 			_oEvento:Texto    = "TES: " + _sTES + " Campo f4_vasito de: " + _sCodOld + " para " + _sCod
// 			_oEvento:CodEven  = "SF4001"
// 			_oEvento:Grava() 
// 		Endif
// 		sf4 -> (dbskip ())
// 	Next
// 	u_help("Atualizado!")

// Return
// //
// // -----------------------------------------------------------------------------------
// Static Function _ajustaSA5()
// 	local _aDados    := {}
// 	local _x         := 0

// 	_oSQL:= ClsSQL ():New ()
// 	_oSQL:_sQuery := ""
// 	_oSQL:_sQuery += " SELECT "
// 	_oSQL:_sQuery += " 		A5_PRODUTO, A5_FORNECE, A5_LOJA "
// 	_oSQL:_sQuery += " FROM SA5010 "
// 	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
// 	_oSQL:_sQuery += " AND A5_CODPRF = '' "
// 	_oSQL:_sQuery += " AND A5_FORNECE IN ('003114','000021','001369','003108','003111','003150','003195','003209', "
// 	_oSQL:_sQuery += " '003266','003402','004565','004734','012774','001369') "
// 	_aDados := aclone(_oSQL:Qry2Array())

// 	for _x := 1 to len (_aDados)
// 		//Posiciona
// 		DbSelectArea("SA5")
// 		DbSetOrder(2)

// 		If SA5->(DbSeek(xFilial("SA5") + _aDados[_x,1] + _aDados[_x,2] + _aDados[_x,3])) // A5_FILIAL+A5_PRODUTO+A5_FORNECE+A5_LOJA
// 			reclock("SA5", .F.)
// 				sa5 -> A5_CODPRF := _aDados[_x,1] 
// 			msunlock()

// 			_oEvento := ClsEvent():New ()
// 			_oEvento:Alias     = 'SA5'
// 			_oEvento:Texto     = "Produto fornecedor Transf. GLPI 13859 " + chr (13) + chr (10) + " "
// 			_oEvento:CodEven   = 'SA5001'  //"SA5010"
// 			_oEvento:Produto   = alltrim(_aDados[_x,1])
// 			_oEvento:Fornece   = alltrim(_aDados[_x,2])
// 			_oEvento:LojaFor   = alltrim(_aDados[_x,3])
// 			_oEvento:Grava()	 
// 		endif
//  		sa5 -> (dbskip ())
//  	Next

// 	u_help("Finalizado!")
// Return
//
// -----------------------------------------------------------------------------------
// Static Function _verifProd()
// 	Local _aDados 	:= {}
// 	Local _i 		:=0

// 	u_help("verifica PA VD")
// 	_aDados = U_LeCSV ('C:\Temp\impPAVD.csv', ';')

// 	for _i := 1 to len(_aDados)
// 		_sCod   := alltrim(_aDados[_i, 1])

// 		DbSelectArea("SB1")
// 		DbSetOrder(1)
// 		if DbSeek(xFilial("SB1")+ alltrim(_sCod),.F.)
// 			// Grava evento de alteracao
// 			_oEvento := ClsEvent():new ()
// 			_oEvento:Alias    = 'SB1'
// 			_oEvento:Texto    = sb1 -> b1_cc
// 			_oEvento:CodEven  = "SB1001"
// 			_oEvento:Produto  = sb1 -> b1_cod
// 			_oEvento:Grava() 
// 		endif	
// 	Next
// 	u_help("Atualizado!")

// Return
//
// -----------------------------------------------------------------------------------
// Static Function _impVAVD()
// 	Local _aDados 	:= {}
// 	Local _i 		:=0

// 	u_help("Limpar va vd")
// 	_aDados = U_LeCSV ('C:\Temp\impPAVD.csv', ';')

// 	for _i := 1 to len(_aDados)
// 		_sCod   := alltrim(_aDados[_i, 1])

// 		DbSelectArea("SB1")
// 		DbSetOrder(1)
// 		if DbSeek(xFilial("SB1")+ alltrim(_sCod),.F.)
// 			reclock ("SB1", .f.)
// 				SB1 -> B1_CC := ''
// 			msunlock ()

// 			// Grava evento de alteracao
// 			_oEvento := ClsEvent():new ()
// 			_oEvento:Alias    = 'SB1'
// 			_oEvento:Texto    = 'GLPI:13788 e 13789 - Limpar CC'
// 			_oEvento:CodEven  = "SB1001"
// 			_oEvento:Produto  = sb1 -> b1_cod
// 			_oEvento:Grava() 
// 		endif	
// 	Next
// 	u_help("Atualizado!")

// Return
//
// -----------------------------------------------------------------------------------
// Static Function _impPESO()
// 	Local _aDados 	:= {}
// 	Local _i 		:=0

// 	u_help("Atualiza peso")
// 	_aDados = U_LeCSV ('C:\Temp\impPeso.csv', ';')

// 	for _i := 1 to len(_aDados)
// 		_sCod  := alltrim(_aDados[_i, 1])
// 		_nPeso := val(_aDados[_i, 2])

// 		DbSelectArea("SB1")
// 		DbSetOrder(1)
// 		if DbSeek(xFilial("SB1")+ alltrim(_sCod),.F.)
// 			reclock ("SB1", .f.)
// 				SB1 -> B1_PESBRU   := _nPeso
// 			msunlock ()

// 			// Grava evento de alteracao
// 			_oEvento := ClsEvent():new ()
// 			_oEvento:Alias    = 'SB1'
// 			_oEvento:Texto    = 'GLPI:13816 - Ajusta PESO'
// 			_oEvento:CodEven  = "SB1001"
// 			_oEvento:Produto  = sb1 -> b1_cod
// 			_oEvento:Grava() 
// 		endif	
// 	Next
// 	u_help("Atualizado!")
// Return
//
// -----------------------------------------------------------------------------------
// Static Function _impSisDeclara()
// 	Local _aDados 	:= {}
// 	Local _i 		:=0

// 	_aDados = U_LeCSV ('C:\Temp\TO.csv', ';')

// 	for _i := 1 to len(_aDados)
// 		_sCod   := PADL(ALLTRIM(_aDados[_i, 1]),2,'0')
// 		_sDesc  := alltrim(_aDados[_i, 2])

// 			reclock("ZX5", .t.)
// 				zx5->zx5_tabela := '57'
// 				zx5->zx5_chave  := _sCod
// 				zx5->zx5_57cod  := _sCod
// 				zx5->zx5_57desc := _sDesc
				
// 				msunlock()
// 	Next
// 	u_help("Atualizado!")
// Return
// //
// // ----------------------------------------------------------------------------
// // verifica duplicidade de fornecedor em Prod x fornece
// Static Function _ProdForDupl()
// 	Local _x := 0
// 	Local _y := 0

// 	nHandle := FCreate("c:\temp\log.csv")
// 	_sLinha := " PRODUTO;FORNECEDOR;QTD DUPLICIDADE"
// 	FWrite(nHandle, _sLinha)

// 	_oSQL:= ClsSQL ():New ()
// 	_oSQL:_sQuery := ""
// 	_oSQL:_sQuery += " SELECT "
// 	_oSQL:_sQuery += " 	DISTINCT "
// 	_oSQL:_sQuery += " 		A5_PRODUTO "
// 	_oSQL:_sQuery += " FROM SA5010 "
// 	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
// 	_oSQL:_sQuery += " ORDER BY A5_PRODUTO "
// 	_aSA5 := aclone(_oSQL:Qry2Array())

// 	For _x:=1 to Len(_aSA5)
// 		_oSQL:= ClsSQL ():New ()
// 		_oSQL:_sQuery := ""
// 		_oSQL:_sQuery += " SELECT "
// 		_oSQL:_sQuery += "       A5_PRODUTO "
// 		_oSQL:_sQuery += " 		,A5_FORNECE "
// 		_oSQL:_sQuery += "    	,COUNT(*) "
// 		_oSQL:_sQuery += " FROM SA5010 "
// 		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
// 		_oSQL:_sQuery += " AND A5_PRODUTO = '"+_aSA5[_x, 1] +"' "
// 		_oSQL:_sQuery += " GROUP BY A5_FORNECE, A5_PRODUTO "
// 		_oSQL:_sQuery += " HAVING COUNT(*) > 1 "
// 		_aDados := aclone(_oSQL:Qry2Array())

// 		For _y:=1 to Len(_aDados)
// 			_sLinha := _aDados[_y, 1] + ";"+_aDados[_y, 2] + ";"+alltrim(str(_aDados[_y, 3])) + CHR(13)+CHR(10)
// 			FWrite(nHandle, _sLinha)
// 		Next
// 	Next
// 	FClose(nHandle)
// Return 
// //
// // ----------------------------------------------------------------------------
// //Atualiza nome de produtos
// static function _AtuProd()
// 	Local _aDados 	:= {}
// 	Local _i 		:=0

// 	u_help("Atualiza acabados")
// 	_aDados = U_LeCSV ('C:\Temp\produtos.csv', ';')

// 	for _i := 1 to len(_aDados)
// 		_sCod  := _aDados[_i, 1]
// 		DbSelectArea("SB1")
// 		DbSetOrder(1)
// 		if DbSeek(xFilial("SB1")+ alltrim(_sCod),.F.)
// 			reclock ("SB1", .f.)
// 				sb1 -> b1_desc  := alltrim(_aDados[_i, 3])
// 			msunlock ()

// 			// Grava evento de alteracao
// 			_oEvento := ClsEvent():new ()
// 			_oEvento:Alias    = 'SB1'
// 			_oEvento:Texto    = 'GLPI: 13467 - Ajusta nome de produto'
// 			_oEvento:CodEven  = "SB1001"
// 			_oEvento:Produto  = sb1 -> b1_cod
// 			_oEvento:Grava() 
// 		endif	
// 	Next
// 	u_help("Atualizado!")
// return
// //
// // ----------------------------------------------------------------------------
// //Atualiza nome de produtos
// static function _AtuSemiAcab()
// 	Local _aDados 	:= {}
// 	Local _i 		:=0

// 	u_help("Atualiza semi acabados")
// 	_aDados = U_LeCSV ('C:\Temp\SEMIACABADO.csv', ';')

// 	for _i := 1 to len(_aDados)
// 		_sCod  := _aDados[_i, 1]
// 		DbSelectArea("SB1")
// 		DbSetOrder(1)
// 		if DbSeek(xFilial("SB1")+ alltrim(_sCod),.F.)
// 			reclock ("SB1", .f.)
// 				sb1 -> b1_desc  := alltrim(_aDados[_i, 3])
// 			msunlock ()

// 			// Grava evento de alteracao
// 			_oEvento := ClsEvent():new ()
// 			_oEvento:Alias    = 'SB1'
// 			_oEvento:Texto    = 'GLPI: 13467 - Ajusta nome de produto'
// 			_oEvento:CodEven  = "SB1001"
// 			_oEvento:Produto  = sb1 -> b1_cod
// 			_oEvento:Grava() 
// 		endif	
// 	Next
// 	u_help("Atualizado!")
// return
//
//
//
// Static function _AtualizaSA2()

// 	sa2 -> (dbsetorder (1))
// 	sa2 -> (dbgotop ())
// 	//
// 	do while ! sa2 -> (eof ())
// 		u_log ('Ajustando item', sa2 -> a2_cod)
// 			// Cria variaveis para uso na gravacao do evento de alteracao
// 			regtomemory ("SA2", .F., .F.)
			
// 			// Grava evento de alteracao
// 			_oEvento := ClsEvent():new ()
// 			_oEvento:Alias   = 'SA2'
//             _oEvento:Texto   = "Alteracao no campo <A2_DEDBSPC> de " + sa2->A2_DEDBSPC + " para 3"
// 			_oEvento:CodEven = "SA2001"
// 			_oEvento:Fornece = sa2->a2_cod
//             _oEvento:LojaFor = sa2->a2_loja
// 			_oEvento:Grava()
		
// 			reclock ("SA2", .f.)
// 				SA2 -> A2_DEDBSPC  := '3'
// 			msunlock ()
			
// 			u_log ('alterado')
			
// 		sa2 -> (dbskip ())
// 	enddo
// Return


// //
// // ------------------------------------------------------------------------------------
// static function _IncManut()
// 	local _sFilial   	:= ""
// 	local _sCodBem   	:= ""
// 	local _sNomeBem  	:= ""
// 	local _sCC       	:= ""
// 	local _sData     	:= ""
// 	local _sHora     	:= ""
// 	local _sUsuario  	:= ""
// 	local _sRamal    	:= ""
// 	local _sSituacao 	:= ""
// 	local _sServico  	:= ""
// 	local _sTpServ   	:= ""
// 	local _sNomeServ 	:= ""
// 	local _sCodSolic 	:= ""
// 	local _sNomeSolic  	:= "" 
// 	local _sEmailSolic 	:= ""
// 	local _sBemParado  	:= ""
// 	local _sOrigem      := ""
// 	local _sErroWS      := ""
// 	local _aSolic		:= {}

// 	u_logIni ()

// 	If empty(_sErroWS)
// 		_sFilial   	:= '01'
// 		_sCodBem   	:= 'ACC-058-27-0001'
// 		_sNomeBem  	:= 'COFRE DE ACO IMCAL  0,60X0,60X1,40' 
// 		_sCC       	:= '012006'
// 		_sData     	:= date()
// 		_sHora     	:= '10:36'
// 		_sUsuario  	:= 'claudia.lionco' 
// 		_sRamal    	:= '3466' 
// 		_sSituacao 	:= 'A'
// 		_sServico  	:= 'cc 012006'
// 		_sTpServ   	:= '006'
// 		_sNomeServ 	:= 'MANUTENCAO AUTONOMA'
// 		_sCodSolic 	:= '000622'
// 		_sNomeSolic := 'Cláudia Lionço'
// 		_sEmailSolic:= 'claudia.lionco@novaalianca.coop.br'
// 		_sBemParado := 'S'
// 		_sOrigem    := 'NAWEB'
// 	endif

// 	If empty(_sErroWS)
		 
// 		_aSolic := {{"TQB_FILIAL", _sFilial		,Nil},;  
// 					{"TQB_CODBEM", _sCodBem		,Nil},; 
// 					{"TQB_CCUSTO", _sCC			,Nil},; 
// 					{"TQB_DTABER", date()		,Nil},; 
// 					{"TQB_HOABER", _sHora		,Nil},; 
// 					{"TQB_USUARI", _sUsuario	,Nil},; 
// 					{"TQB_RAMAL ", _sRamal		,Nil},; 
// 					{"TQB_SOLUCA", _sSituacao	,Nil},; 
// 					{"TQB_DESCSS", _sServico	,Nil},; 
// 					{"TQB_CDSERV", _sTpServ		,Nil},; 
// 					{"TQB_NMSERV", _sNomeServ	,Nil},; 
// 					{"TQB_CDSOLI", _sCodSolic	,Nil},; 
// 					{"TQB_EMSOLI", _sEmailSolic ,Nil},; 
// 					{"TQB_ORIGEM", _sOrigem		,Nil},; 
// 					{"TQB_PARADA", _sBemParado	,Nil} } 

// 		Private lMSHelpAuto := .t. // Nao apresenta erro em tela
// 		Private lMSErroAuto := .f. // Caso a variavel torne-se .T. apos MsExecAuto, apresenta erro em tela

// 		MSExecAuto( {|x,z,y,w| MNTA280(x,z,y,w)}, , , _aSolic )

// 		If lMsErroAuto
// 			Mostraerro()
// 		else
// 			u_help("feito!")
// 		Endif

// 	endif

// 	u_logFim ()
// return
//
// ------------------------------------------------------------------------------------
// Static Function _AtuClientes()
// 	Local _aDados 	:= {}
// 	Local _i 		:=0

// 	_aDados = U_LeCSV ('C:\Temp\clientes.csv', ';')

// 	for _i := 1 to len (_aDados)
// 		_sCod  := PADL(_aDados[_i, 1],6,'0')

// 		DbSelectArea("SA1")
// 		DbSetOrder(1)
// 		if DbSeek(xFilial("SA1")+ _sCod,.F.)
// 			U_AtuMerc ("SA1", sa1 -> (recno ())) // manda p mercanet
// 		endif	
// 	Next
// 	u_help("Atualizado!")
// Return

// // --------------------------------------------------------------------------
// //
// static function _GLPI12948 ()
// 	local _aDados    := {}
// 	local _x         := 0

// 	_oSQL:= ClsSQL ():New ()
// 	_oSQL:_sQuery := ""
// 	_oSQL:_sQuery += " SELECT "
// 	_oSQL:_sQuery += " 	A5_PRODUTO, A5_FORNECE, A5_LOJA "
// 	_oSQL:_sQuery += " FROM SA5010 SA5 "
// 	_oSQL:_sQuery += " INNER JOIN SB1010 SB1 
// 	_oSQL:_sQuery += " 	ON SA5.A5_PRODUTO = SB1.B1_COD "
// 	_oSQL:_sQuery += " 		AND B1_TIPO = 'GG' "
// 	_aDados := aclone(_oSQL:Qry2Array())

// 	for _x := 1 to len (_aDados)
// 		//Posiciona
// 		DbSelectArea("SA5")
// 		DbSetOrder(2)

// 		If SA5->(DbSeek(xFilial("SA5") + _aDados[_x,1] + _aDados[_x,2] + _aDados[_x,3])) // A5_FILIAL+A5_PRODUTO+A5_FORNECE+A5_LOJA
// 			reclock("SA5", .F.)
// 				sa5 -> (dbdelete())
// 			msunlock()
// 		endif
//  		sa5 -> (dbskip ())
//  	Next
// return
// --------------------------------------------------------------------------
//
// static function _GLPI12952 ()
// 	local _lContinua := .T.

// 	DbSelectArea("SB1")
// 	sb1 -> (dbsetorder (1))
// 	sb1 -> (dbgotop ())
// 	do while _lContinua .and. ! sb1 -> (eof ())
	
// 		if _lContinua .and. sb1->b1_tipo='ME'
// 			u_log2 ('info', 'Verificando item ' + sb1 -> b1_cod + SB1 -> B1_DESC)

// 			// Grava evento de alteracao
// 			_oEvento := ClsEvent():new ()
// 			_oEvento:Alias    = 'SB1'
// 			_oEvento:Texto    = 'GLPI: 12952 - Ajusta segunda unidade ME'
// 			_oEvento:CodEven  = "SB1001"
// 			_oEvento:Produto  = sb1 -> b1_cod
// 			_oEvento:Grava() 

// 			reclock ("SB1", .f.)
// 				sb1 -> b1_segum  := 'MI'
// 				sb1 -> b1_conv   := 1000
// 				sb1 -> b1_tipconv :='D'
// 			msunlock ()
// 		endif
// 		sb1 -> (dbskip ())
// 	enddo
// return

// // --------------------------------------------------------------------------
// //
// static function _AtuTES ()
// 	local _lContinua := .T.

// 	DbSelectArea("SB1")
// 	sb1 -> (dbsetorder (1))
// 	sb1 -> (dbgotop ())
// 	do while _lContinua .and. ! sb1 -> (eof ())
	
// 		if _lContinua
// 			u_log2 ('info', 'Verificando item ' + sb1 -> b1_cod + SB1 -> B1_DESC)

// 			// Grava evento de alteracao
// 			_oEvento := ClsEvent():new ()
// 			_oEvento:Alias    = 'SB1'
// 			_oEvento:Texto    = 'GLPI: Ajusta b1_te para vazio'
// 			_oEvento:CodEven  = "SB1001"
// 			_oEvento:Produto  = sb1 -> b1_cod
// 			_oEvento:Grava() 

// 			reclock ("SB1", .f.)
// 				sb1 -> b1_te = ''
// 			msunlock ()
// 		endif
// 		sb1 -> (dbskip ())
// 	enddo
// return
// //
// // ----------------------------------------------------------------------
// // Altera grupo TI de produtos
// Static Function _GrupoTIB1()
//     Local oModel        := Nil
// 	Local _x            := 0
// 	Local _aSucos       := {}
// 	//lOCAL _aNectar      := {}
//     Private lMsErroAuto := .F.
     
// 	// //Suco grupo 0004
// 	// _oSQL:= ClsSQL ():New ()
// 	// _oSQL:_sQuery := ""
// 	// _oSQL:_sQuery += " SELECT "
// 	// _oSQL:_sQuery += "       B1_COD "
// 	// _oSQL:_sQuery += " 		,B1_DESC "
// 	// _oSQL:_sQuery += " 		,B1_POSIPI "
// 	// _oSQL:_sQuery += " FROM SB1010 "
// 	// _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
// 	// _oSQL:_sQuery += " AND B1_POSIPI = '20096100' "
//     // _aSucos := aclone(_oSQL:Qry2Array())

//     // for _x := 1 to len (_aSucos)
// 	// 	_sProd   := _aSucos[_x, 1]

// 	// 	//Posiciona
// 	// 	DbSelectArea("SB1")
// 	// 	DbSetOrder(1)

// 	// 	u_log("Produto " + _sProd)
// 	// 	If SB1->(DbSeek(xFilial("SB1") + _sProd))
// 	// 		_sGrpTIOld := SB1->B1_GRPTI
// 	// 		_sGrupoTI  := '0004'    

// 	// 		oModel:= FwLoadModel ("MATA010")
// 	// 		oModel:SetOperation(4)
// 	// 		oModel:Activate()
			
// 	// 		// inclui os cmapos para alteração
// 	// 		oModel:SetValue("SB1MASTER","B1_GRPTI",_sGrupoTI)
			
// 	// 		If oModel:VldData()
// 	// 			oModel:CommitData()

// 	// 			_oEvento := ClsEvent():new ()
// 	// 			_oEvento:Alias    = 'SB1'
// 	// 			_oEvento:Texto    = "B1_GRPTI DE " + _sGrpTIOld + " PARA " + _sGrupoTI 
// 	// 			_oEvento:CodEven  = "SB1001"
// 	// 			_oEvento:Produto  = _sProd
// 	// 			_oEvento:Grava() 

// 	// 			u_log("Registro ALTERADO!")
// 	// 		Else
// 	// 			VarInfo("",oModel:GetErrorMessage())
// 	// 			u_log("Deu erro")
// 	// 		EndIf

// 	// 		oModel:DeActivate()
// 	// 	endif
// 	// Next 
// 	//u_help("Finalizou grupo 0004") 

// 	//
// 	//
// 	//---------------------------------------------------------------------------------------

// 	// // Nectar grupo 0005
// 	// _oSQL:= ClsSQL ():New ()
// 	// _oSQL:_sQuery := ""
// 	// _oSQL:_sQuery += " SELECT "
// 	// _oSQL:_sQuery += "       B1_COD "
// 	// _oSQL:_sQuery += " 		,B1_DESC "
// 	// _oSQL:_sQuery += " 		,B1_POSIPI "
// 	// _oSQL:_sQuery += " FROM SB1010 "
// 	// _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
// 	// _oSQL:_sQuery += " AND B1_POSIPI = '22029900' "
// 	// _oSQL:_sQuery += " AND B1_VAATO = 'S' "
//     // _aNectar := aclone(_oSQL:Qry2Array())

//     // for _x := 1 to len (_aNectar)
// 	// 	_sProd   := _aNectar[_x, 1]

// 	// 	//Posiciona
// 	// 	DbSelectArea("SB1")
// 	// 	DbSetOrder(1)

// 	// 	u_log("Produto " + _sProd)
// 	// 	If SB1->(DbSeek(xFilial("SB1") + _sProd))
// 	// 		_sGrpTIOld := SB1->B1_GRPTI
// 	// 		_sGrupoTI  := '0005'    

// 	// 		oModel:= FwLoadModel ("MATA010")
// 	// 		oModel:SetOperation(4)
// 	// 		oModel:Activate()
			
// 	// 		// inclui os cmapos para alteração
// 	// 		oModel:SetValue("SB1MASTER","B1_GRPTI",_sGrupoTI)
			
// 	// 		If oModel:VldData()
// 	// 			oModel:CommitData()

// 	// 			_oEvento := ClsEvent():new ()
// 	// 			_oEvento:Alias    = 'SB1'
// 	// 			_oEvento:Texto    = "B1_GRPTI DE " + _sGrpTIOld + " PARA " + _sGrupoTI 
// 	// 			_oEvento:CodEven  = "SB1001"
// 	//          _oEvento:Produto  = _sProd
// 	// 			_oEvento:Grava() 

// 	// 			u_log("Registro ALTERADO!")
// 	// 		Else
// 	// 			VarInfo("",oModel:GetErrorMessage())
// 	// 			u_log("Deu erro")
// 	// 		EndIf

// 	// 		oModel:DeActivate()
// 	// 	endif
// 	// Next 


// 	// // u_help("finalizou")
// 	// u_help("Finalizou grupo 0005") 

// 	// //GRUPO IPI
// 	// _oSQL:= ClsSQL ():New ()
// 	// _oSQL:_sQuery := ""
// 	// _oSQL:_sQuery += " SELECT "
// 	// _oSQL:_sQuery += "       B1_COD "
// 	// _oSQL:_sQuery += " 		,B1_DESC "
// 	// _oSQL:_sQuery += " 		,B1_POSIPI "
// 	// _oSQL:_sQuery += " FROM SB1010 "
// 	// _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
// 	// _oSQL:_sQuery += " AND B1_IPI > 0"
// 	// _oSQL:_sQuery += " AND B1_TIPO NOT IN ('PA','MR') "
// 	// _oSQL:_sQuery += " AND B1_GRPTI <> '0001'"
//     // _aSucos := aclone(_oSQL:Qry2Array())

//     // for _x := 1 to len (_aSucos)
// 	// 	_sProd   := _aSucos[_x, 1]

// 	// 	//Posiciona
// 	// 	DbSelectArea("SB1")
// 	// 	DbSetOrder(1)

// 	// 	u_log("Produto " + _sProd)
// 	// 	If SB1->(DbSeek(xFilial("SB1") + _sProd))
// 	// 		_sGrpTIOld := SB1->B1_GRPTI
// 	// 		_sGrupoTI  := '0001'    

// 	// 		oModel:= FwLoadModel ("MATA010")
// 	// 		oModel:SetOperation(4)
// 	// 		oModel:Activate()
			
// 	// 		// inclui os cmapos para alteração
// 	// 		oModel:SetValue("SB1MASTER","B1_GRPTI",_sGrupoTI)
			
// 	// 		If oModel:VldData()
// 	// 			oModel:CommitData()

// 	// 			_oEvento := ClsEvent():new ()
// 	// 			_oEvento:Alias    = 'SB1'
// 	// 			_oEvento:Texto    = "B1_GRPTI DE " + _sGrpTIOld + " PARA " + _sGrupoTI 
// 	// 			_oEvento:CodEven  = "SB1001"
// 	// 			_oEvento:Produto  = _sProd
// 	// 			_oEvento:Grava() 

// 	// 			u_log("Registro ALTERADO!")
// 	// 		Else
// 	// 			VarInfo("",oModel:GetErrorMessage())
// 	// 			u_log("Deu erro")
// 	// 		EndIf

// 	// 		oModel:DeActivate()
// 	// 	endif
// 	// Next 
// 	// u_help("Finalizou") 

// Return 
//
//
//
// Static Function _ProdXFornece()
// 	local _aDados := {}
// 	local _x      := 0

// 	_oSQL:= ClsSQL ():New ()
// 	_oSQL:_sQuery := ""
// 	_oSQL:_sQuery += " SELECT "
// 	_oSQL:_sQuery += " 	   A5_FILIAL "
// 	_oSQL:_sQuery += "    ,A5_FORNECE "
// 	_oSQL:_sQuery += "    ,A5_LOJA "
// 	_oSQL:_sQuery += "    ,A5_PRODUTO "
// 	_oSQL:_sQuery += " FROM SA5010 "
// 	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
// 	_oSQL:_sQuery += " AND A5_CODPRF = '' "
// 	_oSQL:_sQuery += " AND A5_NOMEFOR LIKE '%COOP.%' "
// 	_aDados := aclone(_oSQL:Qry2Array())

// 	For _x:=1 to Len(_aDados)
		
// 		DbSelectArea("SA5")
// 		DbSetOrder(1) // filial + fornece +loja + produto
// 		if DbSeek(_aDados[_x,1] + _aDados[_x,2] +_aDados[_x,3] +_aDados[_x,4] ,.F.)
// 			reclock("SA5", .F.)
// 				SA5->A5_CODPRF := _aDados[_x,4]
// 			MsUnLock()

// 			_oEvento := ClsEvent():new ()
// 			_oEvento:Alias    = 'SA5'
// 			_oEvento:Texto    = "Inclusão de produto em produto X fornecedor " 
// 			_oEvento:CodEven  = "SA5004"
// 			_oEvento:Produto  = _aDados[_x,4]
// 			_oEvento:Grava() 
// 		endif	
// 	Next
// 	u_help("Feito")
// Return

// Static Function _RotinaUsada()
// 	Local _i := 0
// 	Local _x := 0

//     // Le planilha .csv
//     _aDados = U_LeCSV ('C:\Temp\rotinas.csv', ';')
     
// 	nHandle := FCreate("c:\temp\logRotinas.csv")

//     For _i := 1 to len (_aDados)
// 		_sRotina := UPPER(ALLTRIM(_aDados[_i, 1]))

// 		_oSQL:= ClsSQL ():New ()
// 		_oSQL:_sQuery := ""
// 		_oSQL:_sQuery += " SELECT 
// 		_oSQL:_sQuery += " 	MAX(CAST(ENTRADA AS DATE)) "
// 		_oSQL:_sQuery += "    ,ROTINA "
// 		_oSQL:_sQuery += " FROM VA_USOROT "
// 		_oSQL:_sQuery += " WHERE ENTRADA >= '20200101'"
// 		_oSQL:_sQuery += " AND UPPER(ROTINA) IN ('"+_sRotina+"')"
// 		_oSQL:_sQuery += " GROUP BY ROTINA "
// 		_oSQL:_sQuery += " ORDER BY ROTINA "
// 		_aRot := aclone(_oSQL:Qry2Array())

// 		If len(_aRot) > 0
// 			For _x := 1 to len(_aRot)
// 				_sRet := _sRotina +";"+dtoc(_aRot[_x,1]) + chr (13) + chr (10)
// 			Next
// 		else
// 			_oSQL:= ClsSQL ():New ()
// 			_oSQL:_sQuery := ""
// 			_oSQL:_sQuery += "  SELECT * FROM SX3010 "
// 			_oSQL:_sQuery += " 	WHERE D_E_L_E_T_ = '' "
// 			_oSQL:_sQuery += " 	AND X3_VALID <> '' "
// 			_oSQL:_sQuery += " 	AND UPPER(X3_VALID) LIKE '%"+_sRotina+"%'"
// 			_aSX3 := aclone(_oSQL:Qry2Array())

// 			If len(_aSX3) > 0
// 				_sRet := _sRotina + ';SX3' + chr (13) + chr (10)
// 			else
// 				_oSQL:= ClsSQL ():New ()
// 				_oSQL:_sQuery := ""
// 				_oSQL:_sQuery += "  SELECT * FROM SX7010 "
// 				_oSQL:_sQuery += "  WHERE D_E_L_E_T_ = '' "
// 				_oSQL:_sQuery += "  AND UPPER(X7_REGRA) LIKE '%"+_sRotina+"%'"
// 				_aSX7 := aclone(_oSQL:Qry2Array())

// 				If len(_aSX7) > 0
// 					_sRet := _sRotina + ';SX7' + chr (13) + chr (10)
// 				else
// 					_sRet := _sRotina + chr (13) + chr (10)
// 				EndIf
// 			EndIf
// 		EndIf
// 		FWrite(nHandle,_sRet )
// 	Next
// 	U_HELP("FEITO!")
// 	FClose(nHandle)
// Return
// //
// //
// User Function SaldosIniciais()
// 	Local _i := 0

//     // Le planilha .csv
//     _aDados = U_LeCSV ('C:\Temp\saldosiniciais.csv', ';')
     
//     For _i := 1 to len (_aDados)
// 		_sRede   := _aDados[_i, 1]
// 		_sLoja   := _aDados[_i, 2]
// 		_nValor  := val(_aDados[_i, 4])

// 		Reclock("ZC0",.T.)
// 			zc0 -> zc0_filial := '01'
// 			zc0 -> zc0_codred := _sRede
// 			zc0 -> zc0_lojred := _sLoja
// 			zc0 -> zc0_tm     := '01'
// 			zc0 -> zc0_data   := STOD('20221130')
// 			zc0 -> zc0_hora   := Time()
// 			zc0 -> zc0_user   := 'administrador'
// 			zc0 -> zc0_histor := 'INCLUSAO DE SALDO INICIAL'
// 			zc0 -> zc0_seq    := '000001'
// 			zc0 -> zc0_rapel  := _nValor
// 			zc0 ->zc0_origem  := 'BACA'
// 		ZC0->(MsUnlock())
// 	Next
// 	U_HELP("FEITO!")
// Return
// //
// // altera B1 para manutenção
// User Function ALTERASB1()
//     Local oModel        := Nil
// 	Local _i            := 0
//     Private lMsErroAuto := .F.
     
//     // Le planilha .csv
//     _aDados = U_LeCSV ('C:\Temp\manutencao.csv', ';')
     
//     for _i := 1 to len (_aDados)
// 		_sProd   := _aDados[_i, 1]
// 		_sGrupo  := _aDados[_i, 2]

// 		//Posiciona
// 		DbSelectArea("SB1")
// 		DbSetOrder(1)

// 		u_log("Produto " + _sProd)
// 		If SB1->(DbSeek(xFilial("SB1") + _sProd))
// 			_sGrpOld := SB1->B1_GRUPO
			
// 			if alltrim(_sGrupo) <> alltrim(_sGrpOld)
// 				oModel:= FwLoadModel ("MATA010")
// 				oModel:SetOperation(4)
// 				oModel:Activate()
			
// 				// inclui os cmapos para alteração
// 				oModel:SetValue("SB1MASTER","B1_GRUPO",_sGrupo)
			
// 				If oModel:VldData()
// 					oModel:CommitData()

// 					_oEvento := ClsEvent():new ()
// 					_oEvento:Alias    = 'SB1'
// 					_oEvento:Texto    = "B1_GRUPO DE " + _sGrpOld + " PARA " + _sGrupo 
// 					_oEvento:CodEven  = "SB1001"
// 					_oEvento:Grava() 

// 					u_log("Registro ALTERADO!")
// 				Else
// 					VarInfo("",oModel:GetErrorMessage())
// 					u_log("Deu erro")
// 				EndIf

// 				oModel:DeActivate()
// 			endif
// 		Else
// 			u_log("Registro NAO LOCALIZADO!")
// 		EndIf
// 	Next 
// 	u_help("Finalizou") 
// Return 
 
// //
// // ------------------------------------------------------------------------------------
// Static Function _AtuSB1()
// 	Local _aDados 	:= {}
// 	Local _i 		:=0

// 	_aDados = U_LeCSV ('C:\Temp\sb1.csv', ';')

// 	for _i := 1 to len (_aDados)
// 		_sProd   := _aDados[_i, 1]
// 		_sDesc   := _aDados[_i, 7]
// 		_sLinha  := _aDados[_i, 8]
// 		_sEnvase := _aDados[_i, 9]

// 		DbSelectArea("SB1")
// 		DbSetOrder(1)
// 		if DbSeek(xFilial("SB1")+ _sProd,.F.)
// 			_sDescOld   := sb1->b1_desc
// 			_sLinhaOld  := sb1->b1_codlin
// 			_sEnvaseOld := sb1->b1_valinen

// 			reclock("SB1", .F.)
// 				SB1->B1_B1_DESC := _sDesc
// 				SB1->B1_CODLIN  := _sLinha
// 				SB1->B1_VALINEN := _sEnvase
// 			MsUnLock()

// 			_oEvento := ClsEvent():new ()
// 			_oEvento:Alias    = 'SB1'
// 			_oEvento:Texto    = " B1_B1_DESC DE " + _sDescOld + " PARA " + _sDesc + chr (13) + chr (10) + ;
// 								" B1_CODLIN DE " + _sLinhaOld + " PARA " + _sLinha + chr (13) + chr (10) + ;
// 								" B1_VALINEN DE " + _sEnvaseOld +" PARA " + _sEnvase 
// 			_oEvento:CodEven  = "SB1010"
// 			_oEvento:Grava() 
// 		endif	
	
// 	Next
// 	u_help("Feito!")
// Return
//
// ------------------------------------------------------------------------------------
// Static Function _AtuRepre()
// 	Local _aDados 	:= {}
// 	Local _i 		:=0

// 	_aDados = U_LeCSV ('C:\Temp\representante.csv', ';')

// 	for _i := 1 to len (_aDados)
// 		_sCod  := PADL(_aDados[_i, 1],6,'0')
// 		_sVend := PADL(_aDados[_i, 2],3,'0')
// 		_sFil  := _aDados[_i, 3]

// 		DbSelectArea("SA1")
// 		DbSetOrder(1)
// 		if DbSeek(xFilial("SA1")+ _sCod,.F.)
// 			_sVendOld   := sa1->a1_vend
// 			_sFilialOld := sa1->a1_vafilat

// 			reclock("SA1", .F.)
// 				SA1->A1_VEND    := _sVend
// 				SA1->A1_VAFILAT := _sFil
// 			MsUnLock()

// 			U_AtuMerc ("SA1", sa1 -> (recno ())) // manda p mercanet

// 			_oEvento := ClsEvent():new ()
// 			_oEvento:Alias    = 'SA1'
// 			_oEvento:Texto    = " A1_VEND DE " + _sVendOld + " PARA " + _sVend + chr (13) + chr (10) + ;
// 								" A1_VAFILAT DE " + _sFilialOld + " PARA " + _sFil 
// 			_oEvento:CodEven  = "SA1001"
// 			_oEvento:Cliente  = _sCod
// 			_oEvento:Grava() 
// 		endif	
	
// 	Next
// 	u_help("Atualizado!")
// Return
// //
// //
// // ----------------------------------------------------------------------------------------
// Static Function _RapelExclui()
// 	_sQuery := ""
// 	_sQuery += " SELECT R_E_C_N_O_"
// 	_sQuery += " FROM " + RetSQLName ("ZC0") + " ZC0 "
// 	_sQuery += " WHERE D_E_L_E_T_ = ''"
// 	_nRetQry = U_RetSQL (_sQuery)
// 	if _nRetQry > 0
// 		_oCtaRapel = ClsCtaRap():New (_nRetQry)
// 		if !_oCtaRapel:Exclui ()
// 			u_help("Nao foi possivel excluir o registro.")
// 		else
// 			u_help("Registro excluido")
// 		endif
// 	endif
// Return 
// //
// // Atualiza IPI
// Static Function AltIPI()
//     sb1 -> (dbsetorder (1))
//     sb1 -> (dbgotop ())
//     do while ! sb1 -> (eof ())
//         if alltrim (sb1 -> b1_posipi) $ '22042100/22041090/22043000/22021000/22042100/22060090/22082000'
// 			u_log2 ('info', 'Verificando item ' + sb1 -> b1_cod + SB1 -> B1_DESC)

// 			// Cria variaveis para uso na gravacao do evento de alteracao
// 			regtomemory ("SB1", .F., .F.)
// 			m->b1_ipi = sb1 -> b1_ipi
// 			do case
// 				case sb1 -> b1_posipi = '22042100' .and. sb1 -> b1_ipi != 7.5
// 					m->b1_ipi = 7.5
// 				

// 				case sb1 -> b1_posipi = '22042100' .and. sb1 -> b1_ipi != 7.5
// 					m->b1_ipi = 7.5
// 				case sb1 -> b1_posipi = '22060090' .and. sb1 -> b1_ipi != 7.5
// 					m->b1_ipi = 7.5
// 				case sb1 -> b1_posipi = '22082000' .and. sb1 -> b1_ipi != 22.5
// 					m->b1_ipi = 22.5
// 			endcase
// 			if m->b1_ipi != sb1 -> b1_ipi
// 				U_Log2 ('info', sb1 -> b1_posipi + ' alterando de ' + transform (sb1->b1_ipi, "@E 999.99") + ' para ' + transform (m->b1_ipi, "@E 999.99") + ' ' + ' ' + sb1 -> b1_cod + ' ' + sb1 -> b1_desc)
// 				// Grava evento de alteracao
// 				_oEvento := ClsEvent():new ()
// 				_oEvento:AltCadast ("SB1", m->b1_cod, sb1 -> (recno ()), 'GLPI 11681 - novas aliq.IPI', .F.)

// 				reclock ("SB1", .f.)
// 				sb1 -> B1_ipi = m->b1_ipi
// 				msunlock ()
// 			endif
// 		endif
//         sb1 -> (dbskip ())
//     enddo
// Return
// //
// // Atualiza representantes inativos
// Static Function RepInativos()
// 	Local _aDados := {}
// 	Local _x      := 0

// 	_oSQL := ClsSQL():New ()  
// 	_oSQL:_sQuery := "" 		
// 	_oSQL:_sQuery += " SELECT "
// 	_oSQL:_sQuery += " 		SA3.R_E_C_N_O_ "
// 	_oSQL:_sQuery += " FROM SA3010 SA3 "
// 	_oSQL:_sQuery += " LEFT JOIN LKSRV_MERCANETPRD.MercanetPRD.dbo.DB_TB_REPRES REP "
// 	_oSQL:_sQuery += " 		ON DB_TBREP_CODORIG = A3_COD "
// 	_oSQL:_sQuery += " WHERE SA3.D_E_L_E_T_ = '' "
// 	_oSQL:_sQuery += " AND SA3.A3_ATIVO = 'N' "  // BLOQUEADOS
// 	_oSQL:_sQuery += " AND DB_TBREP_SIT_VENDA<>2 " // 1 = ATIVO/ 2 = INATIVO
// 	_oSQL:_sQuery += " ORDER BY A3_COD "

// 	_aDados := aclone (_oSQL:Qry2Array ())

// 	For _x := 1 to Len(_aDados)
// 		U_AtuMerc ("SA3", _aDados[_x,1])
// 	Next

// Return
// //
// // Atualiza clientes inativos protheus-> Mercanet
// Static Function ClientesInativos()
// 	Local _aDados := {}
// 	Local _x      := 0

// 	_oSQL := ClsSQL():New ()  
// 	_oSQL:_sQuery := "" 		
// 	_oSQL:_sQuery += " WITH C "
// 	_oSQL:_sQuery += " AS "
// 	_oSQL:_sQuery += " (SELECT "
// 	_oSQL:_sQuery += " 		SA1.R_E_C_N_O_ "
// 	_oSQL:_sQuery += " 	   ,A1_COD AS COD_PROTHEUS "
// 	_oSQL:_sQuery += " 	   ,A1_NOME AS NOME_PROTHEUS "
// 	_oSQL:_sQuery += " 	   ,A1_CGC AS CGC_PROTHEUS "
// 	_oSQL:_sQuery += " 	   ,A1_MSBLQL AS SITUACAO_PROTHEUS "
// 	_oSQL:_sQuery += " 	   ,DB_CLI_CODIGO AS COD_MERC "
// 	_oSQL:_sQuery += " 	   ,DB_CLI_NOME AS NOME_MERC "
// 	_oSQL:_sQuery += " 	   ,DB_CLI_CGCMF AS CGC_MERC "
// 	_oSQL:_sQuery += " 	   ,DB_CLI_SITUACAO AS SITUACAO_MERC "
// 	_oSQL:_sQuery += " 	FROM SA1010 SA1 "
// 	_oSQL:_sQuery += " 	LEFT JOIN LKSRV_MERCANETPRD.MercanetPRD.dbo.DB_CLIENTE CLI "
// 	_oSQL:_sQuery += " 		ON CLI.DB_CLI_CGCMF COLLATE Latin1_General_CI_AI = A1_CGC COLLATE Latin1_General_CI_AI "
// 	_oSQL:_sQuery += " 	WHERE SA1.D_E_L_E_T_ = '' "
// 	_oSQL:_sQuery += " 	AND A1_MSBLQL <> '1') "
// 	_oSQL:_sQuery += " SELECT "
// 	_oSQL:_sQuery += " 	* "
// 	_oSQL:_sQuery += " FROM C "
// 	_oSQL:_sQuery += " WHERE SITUACAO_MERC = 3 "
// 	_oSQL:_sQuery += " ORDER BY COD_PROTHEUS "
// 	_aDados := aclone (_oSQL:Qry2Array ())

// 	For _x := 1 to Len(_aDados)
// 		U_AtuMerc ("SA1", _aDados[_x,1])
// 	Next

// Return

// Static Function TelaTeste()
// 		_aBoletos := {}
// 		aadd (_aBoletos, {.T.,"teste","3333","44444"})


// 		_aColunas = {}
// 		aadd (_aColunas, {2, "Serie",  45, "@!"})
// 		aadd (_aColunas, {3, "Numero", 65, "@!"})
// 		aadd (_aColunas, {4, "Banco",  45, "@!"})
		
// 		// Markbrowse para o usuario selecionar os boletos
// 		U_MBArray (@_aBoletos, "Selecione boletos a imprimir", _aColunas, 1, 600, 400)
		
// Return
// //
// // --------------------------------------------------------------------------
// // Grava retorno da margem contribuicao
// User Function EnvMargem ()
// 	local _wFilial 	 := "01"
// 	local _wPedido	 := "279710"
// 	local _wCliente  := "017532"
// 	local _wLoja 	 := "01"
// 	local _aNaWeb    := {}
// 	local _sErros    := ""
// 	local _XmlRet    := ""
// 	local _x         := 0
// 	//local _y         := 0

// 	u_logIni ()

// 	If empty(_sErros)
// 		sa1 -> (dbsetorder(1)) // A1_FILIAL + A1_COD + A1_LOJA
// 		DbSelectArea("SA1")
// 		If ! dbseek(xFilial("SA1") + _wCliente + _wLoja, .F.)
// 			_sErros := " Cliente " + _wCliente +"/"+ _wLoja +" não encontrado. Verifique!"
// 		Else
// 			_wNomeCli := sa1->a1_nome
// 		EndIf
// 	EndIf
// 	If empty(_sErros)
// 		sc5 -> (dbsetorder(3)) // C5_FILIAL + C5_CLIENTE + C5_LOJACLI + C5_NUM
// 		DbSelectArea("SC5")
		
// 		If dbseek(_wFilial + _wCliente + _wLoja + _wPedido, .F.)
// 			_oSQL := ClsSQL():New ()  
// 			_oSQL:_sQuery := "" 		
// 			_oSQL:_sQuery += " SELECT "
// 			_oSQL:_sQuery += " 	 	DESCRITIVO "
// 			_oSQL:_sQuery += " FROM VA_VEVENTOS "
// 			_oSQL:_sQuery += " WHERE CODEVENTO  = 'SC5009' "
// 			_oSQL:_sQuery += " AND FILIAL       = '" + _wFilial  + "' "
// 			_oSQL:_sQuery += " AND CLIENTE      = '" + _wCliente + "' "
// 			_oSQL:_sQuery += " AND LOJA_CLIENTE = '" + _wLoja    + "' "
// 			_oSQL:_sQuery += " AND PEDVENDA     = '" + _wPedido  + "' "
// 			_oSQL:_sQuery += " ORDER BY HORA, DESCRITIVO" 
// 			_aItem := aclone (_oSQL:Qry2Array ())

// 			_XmlRet := "<BuscaItensPedBloq>"
// 			For _x:=1 to Len(_aItem)
// 				_aNaWeb := STRTOKARR(_aItem[_x,1],"|")

// 				_XmlRet += "<BuscaItensPedBloqItem>"
// 				_XmlRet += "<Filial>"        + _wFilial 	  + "</Filial>"
// 				_XmlRet += "<Pedido>"		 + _wPedido       + "</Pedido>"
// 				_XmlRet += "<Cliente>" 		 + _wCliente 	  + "</Cliente>" 
// 				_XmlRet += "<Nome>"			 + _wNomeCli	  + "</Nome>"   
// 				_XmlRet += "<Loja>"			 + _wLoja 		  + "</Loja>"	 
// 				_XmlRet += "<Produto>" 		 + alltrim(_aNaWeb[ 2]) + "</Produto>"
// 				_XmlRet += "<Quantidade>" 	 + alltrim(_aNaWeb[ 3]) + "</Quantidade>"
// 				_XmlRet += "<PrcVenda>" 	 + alltrim(_aNaWeb[ 4]) + "</PrcVenda>"
// 				_XmlRet += "<PrcCusto>" 	 + alltrim(_aNaWeb[ 5]) + "</PrcCusto>"
// 				_XmlRet += "<Comissao>" 	 + alltrim(_aNaWeb[ 6]) + "</Comissao>"
// 				_XmlRet += "<ICMS>" 		 + alltrim(_aNaWeb[ 7]) + "</ICMS>"
// 				_XmlRet += "<PISCOF>" 		 + alltrim(_aNaWeb[ 8]) + "</PISCOF>"
// 				_XmlRet += "<Rapel>" 		 + alltrim(_aNaWeb[ 9]) + "</Rapel>"
// 				_XmlRet += "<Frete>" 		 + alltrim(_aNaWeb[10]) + "</Frete>"
// 				_XmlRet += "<Financeiro>" 	 + alltrim(_aNaWeb[11]) + "</Financeiro>"
// 				_XmlRet += "<MargemVlr>" 	 + alltrim(_aNaWeb[12]) + "</MargemVlr>"
// 				_XmlRet += "<MargemPercent>" + alltrim(_aNaWeb[13]) + "</MargemPercent>"
// 				_XmlRet += "</BuscaItensPedBloqItem>"
// 			Next
// 			_XmlRet += "</BuscaItensPedBloq>"
// 			u_log2 ('info', _XmlRet)
// 		Else
// 			_sErros := "Pedido " + _wPedido + " não encontrado para o cliente "	+ _wCliente +"/"+ _wLoja 		
// 		EndIf		
// 	EndIf
// 	 nHandle := FCreate("c:\temp\logXML.txt")
// 	FWrite(nHandle,_XmlRet )
// 	FClose(nHandle)

// 	u_logFim ()
// Return
// //
// // ------------------------------------------------------------------
// Static Function _AtuGNRE()
// 	Local _x    := 0
// 	Local _aSB5 := {}

// 	_oSQL := ClsSQL():New ()
// 	_oSQL:_sQuery := ""
// 	_oSQL:_sQuery += "	SELECT "
// 	_oSQL:_sQuery += "		 B1_COD AS PRODUTO "
// 	_oSQL:_sQuery += "		,B1_GRTRIB AS GRTRIB "
// 	_oSQL:_sQuery += "		,B1_TIPO AS TIPO "
// 	_oSQL:_sQuery += "		,CASE "
// 	_oSQL:_sQuery += "				WHEN B1_GRTRIB IN ('005', '006', '007') THEN 68 "
// 	_oSQL:_sQuery += "				WHEN B1_GRTRIB IN ('001', '002', '003', '004', '008', '009', '010', '011', '012', '013', '014', '015', '016', '017') THEN 81 "
// 	_oSQL:_sQuery += "				ELSE " 
// 	_oSQL:_sQuery += "				'' "
// 	_oSQL:_sQuery += "			END AS CODGNRE "
// 	_oSQL:_sQuery += "		FROM SB1010 SB1 "
// 	_oSQL:_sQuery += "		LEFT JOIN SB5010 SB5 "
// 	_oSQL:_sQuery += "			ON SB5.D_E_L_E_T_ = '' "
// 	_oSQL:_sQuery += "				AND SB5.B5_COD = B1_COD "
// 	_oSQL:_sQuery += "		WHERE SB1.D_E_L_E_T_ = '' "
// 	_oSQL:_sQuery += "		AND B1_TIPO IN ('PA', 'MR') "
// 	_oSQL:Log ()
// 	_aSB5:= _oSQL:Qry2Array ()
	
	
//  	nHandle := FCreate("c:\temp\GNRE_SB5.txt")
// 	DbSelectArea("SB5")
// 	DbSetOrder(1)
//  	For _x := 1 to Len(_aSB5)
//  		if DbSeek(xFilial("SB5") + _aSB5[_x, 1])	
// 			reclock("SB5", .F.)
// 				SB5->B5_CODGNRE := _aSB5[_x, 4]
// 			MsUnLock()
// 			_sTexto := "Produto: "+ _aSB5[_x, 1] + " Cod GNRE: " + str(_aSB5[_x, 4]) + Chr(13) + Chr(10)
// 			FWrite(nHandle,_sTexto )
// 		endif
//  	Next
// 	FClose(nHandle)
// Return


//
// ------------------------------------------------------------------
// Static Function Almox1()
// 	// Ajusta cadastro produtos em lote

// 	sb1 -> (dbsetorder (1))
// 	sb1 -> (dbgotop ())

// 	do while !sb1 -> (eof ())
// 		if sb1 -> b1_tipo = 'MM'
// 			regtomemory ("SB1", .F., .F.)
			
// 			// Grava evento de alteracao
// 			_oEvento := ClsEvent():new ()
// 			_oEvento:AltCadast ("SB1", m->b1_cod, sb1 -> (recno ()), 'GLPI:10102 - AJUSTA LOCPAD DE 60 PARA 02', .F.)

// 			reclock ("SB1", .f.)
// 				sb1 -> B1_LOCPAD = '02'
// 			msunlock ()
// 		endif
// 		sb1 -> (dbskip ())
// 	enddo
// Return
//
// ------------------------------------------------------------------
// Static Function Almox2()
// 	local _x := 0

// 	U_help("Exec Almox 2 14/07/2021")
// 	_oSQL := ClsSQL():New ()
// 	_oSQL:_sQuery := ""
// 	_oSQL:_sQuery += " SELECT "
// 	_oSQL:_sQuery += " 	  SB1.B1_COD "
// 	_oSQL:_sQuery += " FROM SB1010 SB1 "
// 	_oSQL:_sQuery += " INNER JOIN SB2010 SB2 "
// 	_oSQL:_sQuery += " 	ON SB2.D_E_L_E_T_ = '' "
// 	_oSQL:_sQuery += " 		AND B2_COD = B1_COD "
// 	_oSQL:_sQuery += " 		AND SB2.B2_QATU > 0
// 	_oSQL:_sQuery += " WHERE SB1.D_E_L_E_T_ = '' "
// 	_oSQL:_sQuery += "  AND SB1.B1_COD IN ('602129','606305','606317','606320','606321','606322','606323','606325','606327','606328','606329','606331','606332')"
// 	_oSQL:_sQuery += " AND SB1.B1_TIPO in ('MM','MC')  "
// 	_oSQL:Log ()
// 	_aSB1:= _oSQL:Qry2Array ()
	
// 	For _x := 1 to Len(_aSB1)
// 		CriaSB2 (_aSB1[_x, 1], '02')
// 	Next

// Return
//
// ------------------------------------------------------------------
// Static Function BaixaAut()
// 	Local x := 0

// 	// Busca dados do título para fazer a baixa
// 	_oSQL:= ClsSQL ():New ()
// 	_oSQL:_sQuery := ""
// 	_oSQL:_sQuery += " SELECT "
// 	_oSQL:_sQuery += " 	   SE1.E1_FILIAL"	// 01
// 	_oSQL:_sQuery += "    ,SE1.E1_PREFIXO"	// 02
// 	_oSQL:_sQuery += "    ,SE1.E1_NUM"		// 03
// 	_oSQL:_sQuery += "    ,SE1.E1_PARCELA"	// 04
// 	_oSQL:_sQuery += "    ,SE1.E1_VALOR"	// 05
// 	_oSQL:_sQuery += "    ,SE1.E1_CLIENTE"	// 06
// 	_oSQL:_sQuery += "    ,SE1.E1_LOJA"		// 07
// 	_oSQL:_sQuery += "    ,SE1.E1_EMISSAO"	// 08
// 	_oSQL:_sQuery += "    ,SE1.E1_TIPO"		// 09
// 	_oSQL:_sQuery += "    ,SE1.E1_BAIXA"	// 10
// 	_oSQL:_sQuery += "    ,SE1.E1_SALDO"	// 11
// 	_oSQL:_sQuery += "    ,SE1.E1_STATUS "	// 12
// 	_oSQL:_sQuery += "    ,SE1.E1_ADM "	    // 13
// 	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " AS SE1 "
// 	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
// 	_oSQL:_sQuery += " AND SE1.E1_FILIAL  = '10'"
// 	_oSQL:_sQuery += " AND SE1.E1_BAIXA   = ''"
// 	_oSQL:_sQuery += " AND SE1.E1_EMISSAO ='20210614'"
// 	_oSQL:_sQuery += " AND SE1.E1_TIPO IN ('CC','CD')"
// 	_oSQL:Log ()

// 	_aTitulo := aclone (_oSQL:Qry2Array ())

// 	If len(_aTitulo) <= 0
// 		u_log("TÍTULO NÃO ENCONTRADO")
// 	Else
// 		For x:=1 to len(_aTitulo)	
// 			lMsErroAuto := .F.				
// 			// Cupom lojas e NF Lojas
// 			_sMotBaixa := 'DEBITO CC' 
// 			_sHist     := 'Baixa Cielo'	
// 			_nVlrLiq   := _aTitulo[x,5]
// 			//_nVlrAcr   := 0.01
// 			//_nVlrDec   := 0
// 			_sBanco    := '041'
// 			_sAgencia  := '0568 '
// 			_sConta    := '0606136809'


// 			//executar a rotina de baixa automatica do SE1 gerando o SE5 - DO VALOR LÍQUIDO
// 			_aAutoSE1 := {}
// 			aAdd(_aAutoSE1, {"E1_FILIAL" 	, _aTitulo[x,1]	    				, Nil})
// 			aAdd(_aAutoSE1, {"E1_PREFIXO" 	, _aTitulo[x,2]	    				, Nil})
// 			aAdd(_aAutoSE1, {"E1_NUM"     	, _aTitulo[x,3]	    				, Nil})
// 			aAdd(_aAutoSE1, {"E1_PARCELA" 	, _aTitulo[x,4]	    				, Nil})
// 			aAdd(_aAutoSE1, {"E1_CLIENTE" 	, _aTitulo[x,6] 					, Nil})
// 			aAdd(_aAutoSE1, {"E1_LOJA"    	, _aTitulo[x,7] 					, Nil})
// 			aAdd(_aAutoSE1, {"E1_TIPO"    	, _aTitulo[x,9] 					, Nil})
// 			AAdd(_aAutoSE1, {"AUTMOTBX"		, _sMotBaixa  						, Nil})
// 			AAdd(_aAutoSE1, {"AUTBANCO"  	, _sBanco 							, Nil})  	
// 			AAdd(_aAutoSE1, {"AUTAGENCIA"   , _sAgencia	    				    , Nil})  
// 			AAdd(_aAutoSE1, {"AUTCONTA"  	, _sConta							, Nil})
// 			AAdd(_aAutoSE1, {"AUTDTBAIXA"	, dDataBase   		 				, Nil})
// 			AAdd(_aAutoSE1, {"AUTDTCREDITO"	, dDataBase		 					, Nil})
// 			AAdd(_aAutoSE1, {"AUTHIST"   	, _sHist    					    , Nil})
// 			AAdd(_aAutoSE1, {"AUTJUROS"  	, 0         						, Nil})
// 			AAdd(_aAutoSE1, {"AUTDESCONT"	, 0         					    , Nil})
// 		    AAdd(_aAutoSE1, {"AUTMULTA"  	, 0         						, Nil})
// 			//AAdd(_aAutoSE1, {"AUTACRESC" 	, _nVlrAcr							, Nil})
// 	        //AAdd(_aAutoSE1, {"AUTDECRESC" 	, _nVlrDec							, Nil})
// 			AAdd(_aAutoSE1, {"AUTVALREC"  	, _nVlrLiq							, Nil})
		
// 			_aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))  // orderna conforme dicionário de dados

// 			 cPerg = 'FIN070'
// 			 _aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
// 			 U_GravaSX1 (cPerg, "01", 1)    // testar mostrando o lcto contabil depois pode passar para nao
// 			 U_GravaSX1 (cPerg, "04", 1)    // esse movimento tem que contabilizar
// 			 U_GravaSXK (cPerg, "01", "1", 'G' )
// 			 U_GravaSXK (cPerg, "04", "1", 'G' )

// 			MSExecAuto({|x,y| Fina070(x,y)},_aAutoSE1,3,.F.,5) // rotina automática para baixa de títulos

// 			If lMsErroAuto
// 				u_log(memoread (NomeAutoLog ()))
// 				u_log("IMPORTAÇÃO NÃO REALIZADA")
// 			Else
// 				u_log("IMPORTAÇÃO REALIZADA")
// 			Endif
			
// 			U_GravaSXK (cPerg, "01", "1", 'D' )
// 			U_GravaSXK (cPerg, "04", "1", 'D' )

// 			U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina  
// 		Next
// 	EndIf
// Return
//
// ------------------------------------------------------------------
//
// Static Function Coordenadores()
// 	Local _aDados 	:= {}
// 	Local _i 		:=0

// 	_aDados = U_LeCSV ('C:\Temp\coordenadores.csv', ';')

// 	for _i := 1 to len (_aDados)
// 		_sCliente := _aDados[_i, 1]
// 		_sLoja    := _aDados[_i, 2]
// 		_sVend    := _aDados[_i, 3]
// 		_sGerente := _aDados[_i, 4]

// 		If dbSeek(xFilial("AI0") + _sCliente + _sLoja ) 
// 			Reclock("AI0",.F.)
//                 AI0->AI0_VAGERE := alltrim(_sGerente)
//             AI0->(MsUnlock())
// 		Else
// 			Reclock("AI0",.T.)
// 				AI0->AI0_CODCLI := _sCliente
// 				AI0->AI0_LOJA   := _sLoja
// 				AI0->AI0_VAGERE := alltrim(_sGerente)
// 			AI0->(MsUnlock())

// 		EndIf
// 	Next
// 	u_help("Feito!")
// Return
//
// ------------------------------------------------------------------
// Bandeira/parcela/NSU/Vlr.Bruto/Vlr,Liq.
// Static Function Cielo()
// 	Local _aDados 	:= {}
// 	Local _aTexto   := {}
// 	Local _i 		:= 0
// 	Local _x        := 0

// 	nHandle := FCreate("c:\temp\titulos_cielo.csv")
// 	_aDados = U_LeCSV ('C:\Temp\cielo.csv', ';')

// 	_sTexto := " FILIAL; TITULO; PREFIXO; PARCELA;CLIENTE;LOJA;NSU;AUTORIZACAO;BANDEIRA;VALOR TITULO; VLR.BRUTO CIELO;VLR.LIQ CIELO"+ chr (13) + chr (10)
// 	FWrite(nHandle,_sTexto )

// 	for _i := 1 to len (_aDados)
// 		_sBandeira := _aDados[_i, 1]
// 		_sParc     := _aDados[_i, 2]
// 		_sNSU      := _aDados[_i, 3]
// 		_VlrBrt    := _aDados[_i, 4]
// 		_VlrLiq    := _aDados[_i, 5]

// 		_oSQL := ClsSQL():New ()
// 		_oSQL:_sQuery := ""
// 		_oSQL:_sQuery += " SELECT "
// 		_oSQL:_sQuery += " 	   E1_FILIAL "
// 		_oSQL:_sQuery += "    ,E1_NUM "
// 		_oSQL:_sQuery += "    ,E1_PREFIXO "
// 		_oSQL:_sQuery += "    ,E1_PARCELA "
// 		_oSQL:_sQuery += "    ,E1_CLIENTE "
// 		_oSQL:_sQuery += "    ,E1_LOJA "
// 		_oSQL:_sQuery += "    ,E1_NSUTEF "
// 		_oSQL:_sQuery += "    ,E1_CARTAUT "
// 		_oSQL:_sQuery += "    ,E1_VALOR "
// 		_oSQL:_sQuery += " FROM " + RetSqlName("SE1")
// 		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
// 		_oSQL:_sQuery += " AND E1_NSUTEF    = '"+ alltrim(_sNSU)  +"' "
// 		_oSQL:_sQuery += " AND E1_PARCELA   = '"+ alltrim(_sParc) +"' "
// 		_oSQL:Log ()
// 		_aTexto:= _oSQL:Qry2Array ()

// 		For _x := 1 to Len(_aTexto)
// 			_sFilial := _aTexto[_x, 1]
// 			_sNum    := _aTexto[_x, 2]
// 			_sPrefix := _aTexto[_x, 3]
// 			_sParc   := _aTexto[_x, 4]
// 			_sCliente:= _aTexto[_x, 5]
// 			_sLoja   := _aTexto[_x, 6]
// 			_sNsu    := _aTexto[_x, 7]
// 			_sAut    := _aTexto[_x, 8]
// 			_nValor  := _aTexto[_x, 9]

// 			_sTexto := _sFilial +";"+ _sNum +";"+ _sPrefix +";"+ _sParc +";"+ _sCliente +";"+ _sLoja +";"+ _sNsu +";"+ _sAut +";"+ _sBandeira +";"+ str(_nValor) +";"+ _VlrBrt +";"+ _VlrLiq + chr (13) + chr (10)
// 			FWrite(nHandle,_sTexto )
// 		Next

// 	Next
// 	FClose(nHandle)
// Return
//
// ------------------------------------------------------------------
// Static Function Solicitante()
// 	Local _aDados 	:= {}
// 	Local _i 		:=0

// 	_aDados = U_LeCSV ('C:\Temp\solicitante.csv', ';')

// 	for _i := 1 to len (_aDados)
// 		_sFilial  := _aDados[_i, 1]
// 		_sNumero  := _aDados[_i, 2]
// 		_sFornec  := _aDados[_i, 3]
// 		_dEmissao := _aDados[_i, 4]
// 		_sSolicit := _aDados[_i, 5]

// 		_oSQL := ClsSQL():New ()
// 		_oSQL:_sQuery := ""
// 		_oSQL:_sQuery += " UPDATE  " + RetSqlName("SC7")
// 		_oSQL:_sQuery += " 		SET C7_SOLICIT = '" + _sSolicit +"'"
// 		_oSQL:_sQuery += " WHERE C7_FILIAL = '" + _sFilial  + "'"
// 		_oSQL:_sQuery += " AND C7_NUM      = '" + _sNumero  + "'" 
// 		_oSQL:_sQuery += " AND C7_FORNECE  = '" + _sFornec  + "'" 
// 		_oSQL:_sQuery += " AND C7_EMISSAO  = '" + _dEmissao + "'" 
// 		_oSQL:Exec ()
// 	Next
// return
//
// User function ClauBatVerbas(_nTipo, _sFilial)
// 	Local _aDados   := {}
// 	Local _aVend    := {}
// 	Local _x		:= 0
// 	Local _i		:= 0
// 	Private cPerg   := "BatVerbas"
	
// 	_dDtaIni := STOD('20160101')
// 	_dDtaFin  := LastDate ( _dDtaIni)
	
// 	While _dDtaIni <= STOD('20201231')
// 		u_logIni ()
// 		_sErroAuto := ''  // Para a funcao u_help gravar mensagens
// 		u_log ( DTOS(_dDtaIni) +'-' + DTOS(_dDtaFin))
// 		_sSQL := " DELETE FROM ZB0010" 
// 		_sSQL += " WHERE ZB0_FILIAL= '" +_sFilial +"' AND ZB0_DATA BETWEEN '" + DTOS(_dDtaIni) + "' AND '" + DTOS(_dDtaFin) + "'"
// 		u_log (_sSQL)
		
// 		If TCSQLExec (_sSQL) < 0
// 			if type ('_oBatch') == 'O'
// 				_oBatch:Mensagens += 'Erro ao limpar tabela ZB0010'
// 				_oBatch:Retorno = 'N'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
// 			else
// 				u_help ('Erro ao limpar tabela ZB0010',, .t.)
// 			endif
// 		Else
// 			_oSQL:= ClsSQL ():New ()
// 			_oSQL:_sQuery := ""
// 			_oSQL:_sQuery += " SELECT DISTINCT
// 			_oSQL:_sQuery += " 	   E3_VEND AS VENDEDOR
// 			_oSQL:_sQuery += "    ,A3_NOME AS NOM_VEND
// 			_oSQL:_sQuery += "    FROM " + RetSQLName ("SE3") + " AS SE3 "
// 			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA3") + " AS SA3 "
// 			_oSQL:_sQuery += " 	ON (SA3.D_E_L_E_T_ = ''"
// 			//_oSQL:_sQuery += "              AND SA3.A3_COD IN('205','299')"
// 			//_oSQL:_sQuery += " 			AND SA3.A3_MSBLQL != '1'
// 			//_oSQL:_sQuery += " 			AND SA3.A3_ATIVO != 'N'
// 			_oSQL:_sQuery += " 			AND SA3.A3_COD = SE3.E3_VEND)
// 			_oSQL:_sQuery += " WHERE E3_FILIAL = '" + xFilial('SE3') + "' "   
// 			_oSQL:_sQuery += " AND E3_VEND BETWEEN ' ' and 'ZZZ'"
// 			_oSQL:_sQuery += " AND E3_EMISSAO BETWEEN '" + dtos (_dDtaIni) + "' AND '" + dtos (_dDtaFin) + "'"
// 			_oSQL:_sQuery += " AND E3_BAIEMI = 'B'
// 			_oSQL:_sQuery += " AND SE3.D_E_L_E_T_ = ''

// 			_oSQL:Log ()
// 			_aVend := _oSQL:Qry2Array ()
			
// 			For _i := 1 to Len(_aVend)
// 				_aDados := U_VA_COMVERB(_dDtaIni, _dDtaFin, _aVend[_i,1], 3, _sFilial)
				
// 				u_log ( DTOS(_dDtaIni) +'-' + DTOS(_dDtaFin) +'/'+_aVend[_i,1])
// 				For _x := 1 to Len(_aDados)
// 					If alltrim(_aDados[_x,17]) == ''
// 						_dDtPgto := STOD('19000101')
// 					Else
// 						_dDtPgto := STOD(_aDados[_x,17])
// 					EndIf
// 					dbselectArea("ZB0")
// 					RecLock("ZB0",.T.)
// 						ZB0 -> ZB0_FILIAL	:= _aDados[_x,14]		
// 						ZB0 -> ZB0_NUM		:= _aDados[_x,4]	
// 						ZB0 -> ZB0_SEQ		:= _aDados[_x,15]		                                      
// 						ZB0 -> ZB0_DATA		:= stod(_aDados[_x,16])	
// 						ZB0 -> ZB0_TIPO		:= _aDados[_x,13]
// 						ZB0 -> ZB0_ACRDES   := _aDados[_x,12]
// 						ZB0 -> ZB0_VENDCH   := _aVend[_i,1]
// 						ZB0 -> ZB0_VENVER  	:= _aDados[_x,2]
// 						ZB0 -> ZB0_VENNF 	:= _aDados[_x,3]
// 						ZB0 -> ZB0_DOC		:= _aDados[_x,5]	
// 						ZB0 -> ZB0_PREFIX	:= _aDados[_x,6]
// 						ZB0 -> ZB0_CLI		:= _aDados[_x,7]
// 						ZB0 -> ZB0_LOJA		:= _aDados[_x,8]
// 						ZB0 -> ZB0_VLBASE	:= _aDados[_x,10]
// 						ZB0 -> ZB0_VLCOMS  	:= _aDados[_x,11]
// 						ZB0 -> ZB0_PERCOM   := _aDados[_x,9]
// 						ZB0 -> ZB0_DTAPGT   := _dDtPgto 

// 					MsUnLock() 
// 				Next
// 			Next
// 		EndIf
// 		_dDtaIni  := MonthSum(_dDtaIni,1)
// 		_dDtaFin  := LastDate(_dDtaIni)
// 	EndDo 

// 	u_help("Processo finalizado com sucesso")
// Return

// static function comissoes()
// 	Local _aDados 	:= {}
// 	Local _aCom     := {}
// 	Local i 		:= 0
// 	Local _x        := 0
// 	Local _oSQL  := ClsSQL ():New ()

// 	 nHandle := FCreate("c:\temp\retorComissao.csv")

// 	_sLinha := 'VEND;FILIAL;DOCUMENTO;SERIE;PARCELA;CLIENTE;LOJA;TOTAL_NF;IPI_NF;ST_NF;FRETE_NF;BASE_TIT;VALOR_TIT;VLR_DESCONTO;VLR_RECEBIDO;QTD_PARCELAS;BASE;MEDIA_COMISSAO;COMISSAO' + chr (13) + chr (10)
// 	FWrite(nHandle,_sLinha )

// 	_aDados = U_LeCSV ('C:\Temp\comissao.csv', ';')

// 	For i:=1 to Len(_aDados)
// 		_sFilial 	:= _aDados[i,1]
// 		_sDocumento := _aDados[i,2]
// 		_sSerie 	:= _aDados[i,3]
// 		_sParc 		:= _aDados[i,4]
// 		_sCliente 	:= _aDados[i,5]
// 		_sLoja 		:= _aDados[i,6]

// 		_oSQL:_sQuery := ""
// 		_oSQL:_sQuery += " WITH C"
// 		_oSQL:_sQuery += " AS"
// 		_oSQL:_sQuery += " (SELECT"
// 		_oSQL:_sQuery += " 		SF2.F2_VEND1 AS VEND"
// 		_oSQL:_sQuery += " 	   ,SE1.E1_FILIAL AS FILIAL"
// 		_oSQL:_sQuery += " 	   ,SE1.E1_NUM AS DOCUMENTO"
// 		_oSQL:_sQuery += " 	   ,SE1.E1_PREFIXO AS SERIE"
// 		_oSQL:_sQuery += " 	   ,SE1.E1_PARCELA AS PARCELA"
// 		_oSQL:_sQuery += " 	   ,SE1.E1_CLIENTE AS CLIENTE"
// 		_oSQL:_sQuery += " 	   ,SE1.E1_LOJA AS LOJA"
// 		_oSQL:_sQuery += " 	   ,F2_VALBRUT AS TOTAL_NF"
// 		_oSQL:_sQuery += " 	   ,F2_VALIPI AS IPI_NF"
// 		_oSQL:_sQuery += " 	   ,F2_ICMSRET AS ST_NF"
// 		_oSQL:_sQuery += " 	   ,F2_FRETE AS FRETE_NF"
// 		_oSQL:_sQuery += " 	   ,E1_BASCOM1 AS BASE_TIT"
// 		_oSQL:_sQuery += " 	   ,E1_VENCTO AS VENCIMENTO"
// 		_oSQL:_sQuery += " 	   ,E1_VALOR AS VALOR_TIT"
// 		_oSQL:_sQuery += " 	   ,ISNULL((SELECT"
// 		_oSQL:_sQuery += " 				ROUND(SUM(E5_VALOR), 2)"
// 		_oSQL:_sQuery += " 			FROM SE5010 AS SE52"
// 		_oSQL:_sQuery += " 			WHERE SE52.E5_FILIAL = E5_FILIAL"
// 		_oSQL:_sQuery += " 			AND SE52.D_E_L_E_T_ != '*'"
// 		_oSQL:_sQuery += " 			AND SE52.E5_RECPAG = 'R'"
// 		_oSQL:_sQuery += " 			AND SE52.E5_SITUACA != 'C'"
// 		_oSQL:_sQuery += " 			AND SE52.E5_NUMERO = SE1.E1_NUM"
// 		_oSQL:_sQuery += " 			AND (SE52.E5_TIPODOC = 'DC'"
// 		_oSQL:_sQuery += " 			OR (SE52.E5_TIPODOC = 'CP'"
// 		_oSQL:_sQuery += " 			AND SE52.E5_DOCUMEN NOT LIKE '% RA %'))"
// 		_oSQL:_sQuery += " 			AND SE52.E5_PREFIXO = SE1.E1_PREFIXO"
// 		_oSQL:_sQuery += " 			AND SE52.E5_PARCELA = SE1.E1_PARCELA"
// 		_oSQL:_sQuery += " 			GROUP BY SE52.E5_FILIAL"
// 		_oSQL:_sQuery += " 					,SE52.E5_RECPAG"
// 		_oSQL:_sQuery += " 					,SE52.E5_NUMERO"
// 		_oSQL:_sQuery += " 					,SE52.E5_PARCELA"
// 		_oSQL:_sQuery += " 					,SE52.E5_PREFIXO)"
// 		_oSQL:_sQuery += " 		, 0) AS VLR_DESCONTO"
// 		_oSQL:_sQuery += " 	   ,ISNULL((SELECT"
// 		_oSQL:_sQuery += " 				ROUND(SUM(E5_VALOR), 2)"
// 		_oSQL:_sQuery += " 			FROM SE5010 AS SE53"
// 		_oSQL:_sQuery += " 			WHERE SE53.E5_FILIAL = SE1.E1_FILIAL"
// 		_oSQL:_sQuery += " 			AND SE53.D_E_L_E_T_ != '*'"
// 		_oSQL:_sQuery += " 			AND SE53.E5_RECPAG = 'R'"
// 		_oSQL:_sQuery += " 			AND SE53.E5_NUMERO = E1_NUM"
// 		_oSQL:_sQuery += " 			AND (SE53.E5_TIPODOC = 'VL'"
// 		_oSQL:_sQuery += " 			OR (SE53.E5_TIPODOC = 'CP'"
// 		_oSQL:_sQuery += " 			AND SE53.E5_DOCUMEN LIKE '% RA %'))"
// 		_oSQL:_sQuery += " 			AND SE53.E5_PREFIXO = SE1.E1_PREFIXO"
// 		_oSQL:_sQuery += " 			AND SE53.E5_PARCELA = SE1.E1_PARCELA"
// 		_oSQL:_sQuery += " 			GROUP BY SE53.E5_FILIAL"
// 		_oSQL:_sQuery += " 					,SE53.E5_RECPAG"
// 		_oSQL:_sQuery += " 					,SE53.E5_NUMERO"
// 		_oSQL:_sQuery += " 					,SE53.E5_PARCELA"
// 		_oSQL:_sQuery += " 					,SE53.E5_PREFIXO)"
// 		_oSQL:_sQuery += " 		, 0) AS VLR_RECEBIDO"
// 		_oSQL:_sQuery += "	,(SELECT"
// 		_oSQL:_sQuery += "		count(SE12.E1_PARCELA)"
// 		_oSQL:_sQuery += "	FROM SE1010 SE12"
// 		_oSQL:_sQuery += "	WHERE SE12.D_E_L_E_T_=''"
// 		_oSQL:_sQuery += "  AND SE12.E1_FILIAL  = '" + _sFilial + "'"
// 		_oSQL:_sQuery += "	AND SE12.E1_NUM     = '" + _sDocumento + "'"
// 		_oSQL:_sQuery += "	AND SE12.E1_PREFIXO = '" + _sSerie + "'" 
// 		//_oSQL:_sQuery += "	AND SE12.E1_PARCELA = '" + _sParc + "'"
// 		_oSQL:_sQuery += "  AND SE12.E1_CLIENTE = '" + _sCliente + "'"
// 		_oSQL:_sQuery += "  AND SE12.E1_LOJA    = '" + _sLoja + "'"
// 		_oSQL:_sQuery += "	) AS QTD_PARC"
// 		_oSQL:_sQuery += "	,SE1.E1_COMIS1 AS E1_COM "
// 		_oSQL:_sQuery += " 	FROM SE1010 SE1"
// 		_oSQL:_sQuery += " 	LEFT JOIN SF2010 AS SF2"
// 		_oSQL:_sQuery += " 		ON (SF2.D_E_L_E_T_ = ''"
// 		_oSQL:_sQuery += " 		AND SF2.F2_FILIAL = SE1.E1_FILIAL"
// 		_oSQL:_sQuery += " 		AND SF2.F2_DOC = SE1.E1_NUM"
// 		_oSQL:_sQuery += " 		AND SF2.F2_SERIE = SE1.E1_PREFIXO"
// 		_oSQL:_sQuery += " 		AND SF2.F2_CLIENTE = SE1.E1_CLIENTE"
// 		_oSQL:_sQuery += " 		AND SF2.F2_LOJA = SE1.E1_LOJA)"
// 		_oSQL:_sQuery += " 	WHERE SE1.D_E_L_E_T_ = ''"
// 		_oSQL:_sQuery += " 	AND E1_FILIAL IN ('01', '16'))"
// 		_oSQL:_sQuery += " SELECT"
// 		_oSQL:_sQuery += " 	    VEND"
// 		_oSQL:_sQuery += " 	   ,FILIAL"
// 		_oSQL:_sQuery += " 	   ,DOCUMENTO"
// 		_oSQL:_sQuery += " 	   ,SERIE"
// 		_oSQL:_sQuery += " 	   ,PARCELA"
// 		_oSQL:_sQuery += "	   ,CLIENTE"
// 		_oSQL:_sQuery += " 	   ,LOJA"
// 		_oSQL:_sQuery += "     ,TOTAL_NF"
// 		_oSQL:_sQuery += "     ,IPI_NF"
// 		_oSQL:_sQuery += "     ,ST_NF"
// 		_oSQL:_sQuery += "     ,FRETE_NF"
// 		_oSQL:_sQuery += "     ,BASE_TIT"
// 		_oSQL:_sQuery += "     ,VALOR_TIT"
// 		_oSQL:_sQuery += "     ,VLR_DESCONTO"
// 		_oSQL:_sQuery += "     ,VLR_RECEBIDO"
// 		_oSQL:_sQuery += "     ,QTD_PARC"
//    		_oSQL:_sQuery += "     ,(VLR_RECEBIDO -(IPI_NF/QTD_PARC) - (ST_NF/QTD_PARC) -(FRETE_NF/QTD_PARC)) AS BASE_LIB"
//    		_oSQL:_sQuery += "     ,E1_COM AS MEDIA_COMISSAO"
//    		_oSQL:_sQuery += "     ,(VLR_RECEBIDO -(IPI_NF/QTD_PARC) - (ST_NF/QTD_PARC) -(FRETE_NF/QTD_PARC)) * (E1_COM) / 100 AS COMISSAO"
// 		_oSQL:_sQuery += " FROM C"
// 		_oSQL:_sQuery += " WHERE FILIAL  = '" + _sFilial + "'"
// 		_oSQL:_sQuery += " AND DOCUMENTO = '" + _sDocumento + "'"
// 		_oSQL:_sQuery += " AND SERIE     = '" + _sSerie + "'"
// 		_oSQL:_sQuery += " AND PARCELA   = '" + _sParc + "'"
// 		_oSQL:_sQuery += " AND CLIENTE   = '" + _sCliente + "'"
// 		_oSQL:_sQuery += " AND LOJA      = '" + _sLoja + "'"
// 		_oSQL:_sQuery += " GROUP BY VEND"
// 		_oSQL:_sQuery += " 	    ,FILIAL"
// 		_oSQL:_sQuery += " 	    ,DOCUMENTO"
// 		_oSQL:_sQuery += " 	    ,SERIE"
// 		_oSQL:_sQuery += " 	    ,PARCELA"
// 		_oSQL:_sQuery += "	    ,CLIENTE"
// 		_oSQL:_sQuery += " 	    ,LOJA"
// 		_oSQL:_sQuery += " 		,TOTAL_NF"
// 		_oSQL:_sQuery += " 		,IPI_NF"
// 		_oSQL:_sQuery += " 		,ST_NF"
// 		_oSQL:_sQuery += " 		,FRETE_NF"
// 		_oSQL:_sQuery += " 		,BASE_TIT"
// 		_oSQL:_sQuery += " 		,VALOR_TIT"
// 		_oSQL:_sQuery += " 		,VLR_DESCONTO"
// 		_oSQL:_sQuery += " 		,VLR_RECEBIDO"
// 		_oSQL:_sQuery += " 		,QTD_PARC"
// 		_oSQL:_sQuery += "		,E1_COM"
// 		_aCom := aclone (_oSQL:Qry2Array ())


// 		For _x:=1 to Len(_aCom)
// 			_sLinha := alltrim(_aCom[_x,1]) +';' 
// 			_sLinha += alltrim(_aCom[_x,2]) +';' 
// 			_sLinha += alltrim(_aCom[_x,3]) +';' 
// 			_sLinha += alltrim(_aCom[_x,4]) +';' 
// 			_sLinha += alltrim(_aCom[_x,5]) +';' 
// 			_sLinha += alltrim(_aCom[_x,6]) +';' 
// 			_sLinha += alltrim(_aCom[_x,7]) +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x, 8])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x, 9])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,10])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,11])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,12])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,13])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,14])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,15])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,16])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,17])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,18])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,19])),'.',',') + chr (13) + chr (10)
			
// 			FWrite(nHandle,_sLinha )
// 		Next
// 	Next
// 	FClose(nHandle)
// return

// // INSERE DESCRICAO CC NO SC7
// Static function descCC()
// 	Local _aDados := {}
// 	Local i       := 0

// 	u_help('começa')

// 	_oSQL := ClsSQL():New ()
// 	_oSQL:_sQuery := ""
// 	_oSQL:_sQuery += " SELECT"
// 	_oSQL:_sQuery += " 	   C7_FILIAL"
// 	_oSQL:_sQuery += "    ,C7_NUM"
// 	_oSQL:_sQuery += "    ,C7_ITEM"
// 	_oSQL:_sQuery += "    ,C7_SEQUEN"
// 	_oSQL:_sQuery += "    ,CTT_DESC01"
// 	_oSQL:_sQuery += " FROM SC7010"
// 	_oSQL:_sQuery += " INNER JOIN CTT010 CTT"
// 	_oSQL:_sQuery += " 	ON (CTT.D_E_L_E_T_ = ''"
// 	_oSQL:_sQuery += " 			AND C7_CC = CTT_CUSTO)"
// 	_oSQL:_sQuery += " WHERE C7_EMISSAO >= '20201201'"
// 	_oSQL:_sQuery += " AND C7_CC <> ''"
// 	_oSQL:_sQuery += " AND C7_VACCDES = ''"
// 	_oSQL:_sQuery += " ORDER BY C7_FILIAL, C7_EMISSAO "
// 	_aDados := _oSQL:Qry2Array ()


// 	For i:=1 to Len(_aDados)
// 			dbSelectArea("SC7")
// 			dbSetOrder(1) // c7_filial, c7_num, c7_item, c7_sequen                                                                                                                                  
// 			dbSeek(_aDados[i,1] + _aDados[i,2]  + _aDados[i,3] + _aDados[i,4] )
			
// 			If Found() // Avalia o retorno da pesquisa realizada
// 				RECLOCK("SC7", .F.)
				
// 				SC7->C7_VACCDES := _aDados[i,5] 
				
// 				MSUNLOCK()     // Destrava o registro
// 			EndIf		
// 	Next
// Return
// // ----------------------------------------------------------------------------
// // Importa CSV obs financeiro
//
// static Function ImpOBSFin()
// Local _aDados 	:= {}
// Local _i 		:=0
// local _oEvento 	:= NIL

// 	_aDados = U_LeCSV ('C:\Temp\obs.csv', ';')

// 	//u_log (len(_aDados))

// 	for _i := 1 to len (_aDados)

// 		If Len(alltrim(_aDados [_i, 1])) <= 6
// 			_oEvento    := NIL

// 			_oEvento := ClsEvent():new ()
// 			_oEvento:CodEven   = "SA1004"
// 			_oEvento:DtEvento  = date()
// 			_oEvento:Texto	   = _aDados [_i, 3]
// 			_oEvento:Cliente   = PADL(_aDados [_i, 1],6,'0')
// 			_oEvento:LojaCli   = PADL(_aDados [_i, 2],2,'0')
// 			_oEvento:Grava ()

// 			_Cliente := PADL(_aDados [_i, 2],2,'0')
// 		else
// 			u_log ("---AJUSTE:" +alltrim(_Cliente) + alltrim(_aDados [_i, 1]))
// 		EndIf
// 	Next
// return
//
//Static Function _ajusteZA5()
//	local _i := 0
//	
//	cQuery := " SELECT"
//	cQuery += " 	ZA5_FILIAL"
//	cQuery += "    ,ZA5_NUM"
//	cQuery += "    ,ZA5_SEQ"
//	cQuery += "    ,ZA5_DOC"
//	cQuery += "    ,ZA5_PREFIX"
//	cQuery += "    ,ZA5_CLI
//	cQuery += "    ,ZA5_LOJA"
//	cQuery += "    ,ZA5_VENVER"
//	cQuery += "    ,ZA5_VENNF"
//	cQuery += " FROM ZA5010"
//	cQuery += " WHERE D_E_L_E_T_ = ''"
//	cQuery += " AND ZA5_VENVER = ''"
//	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
//	
//	TRA->(DbGotop())
//	While TRA->(!Eof())
//		
//		if alltrim( TRA->ZA5_PREFIX) == ''
//			_serie := '10'
//		else
//			_serie := TRA->ZA5_PREFIX
//		EndIf
//		
//		_oSQL:= ClsSQL ():New ()
//		_oSQL:_sQuery := ""
//		_oSQL:_sQuery += " SELECT F2_VEND1 FROM SF2010"
//		_oSQL:_sQuery += " WHERE F2_DOC		='"+ TRA->ZA5_DOC +"'"
//		_oSQL:_sQuery += " AND F2_SERIE		='"+ _serie +"'"
//		_oSQL:_sQuery += " AND F2_CLIENTE	='"+ TRA->ZA5_CLI +"'"
//		_oSQL:_sQuery += " AND F2_LOJA		='"+ TRA->ZA5_LOJA +"'"
//		_aVend := _oSQL:Qry2Array ()
//				
//		For _i := 1 to Len(_aVend)
//		
//			dbSelectArea("ZA5")
//			dbSetOrder(1) // ZA5_FILIAL+ZA5_NUM+ZA5_SEQ                                                                                                                                      
//			dbSeek( tra-> ZA5_FILIAL + tra->ZA5_NUM + alltrim(str(tra->ZA5_SEQ)))
//			
//			If Found() // Avalia o retorno da pesquisa realizada
//				RECLOCK("ZA5", .F.)
//				
//				ZA5->ZA5_VENVER := _aVend[_i,1]
//				ZA5->ZA5_VENNF  := _aVend[_i,1]
//				
//				MSUNLOCK()     // Destrava o registro
//			EndIf		
//		Next
//				
//		DBSelectArea("TRA")
//		dbskip()
//	Enddo
//Return
//	local _oSQL     := NIL
//	
//	u_help ("Atualiza comprador")
//	
//	cQuery := " SELECT C7_FILIAL, C7_USER, C7_NUM, C7_FORNECE, C7_EMISSAO "
//	cQuery += " FROM " + RetSqlName("SC7")"
//	cQuery += " WHERE D_E_L_E_T_=''"
//	cQuery += " AND C7_EMISSAO>='20190101'"
//	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
//	
//	TRA->(DbGotop())
//	
//	While TRA->(!Eof())	
//		_oSQL := ClsSQL():New ()
//		_oSQL:_sQuery := ""
//		_oSQL:_sQuery += " UPDATE  " + RetSqlName("SC7")
//		_oSQL:_sQuery +=   " SET C7_COMNOM = '" + UsrFullName(tra -> c7_user) +"'"
//		_oSQL:_sQuery += " WHERE C7_FILIAL = '" +  tra->c7_filial + "'"
//		_oSQL:_sQuery += " AND C7_NUM = '"+ tra -> c7_num +"'" 
//		_oSQL:_sQuery += " AND C7_FORNECE = '"+ tra -> c7_fornece +"'" 
//		_oSQL:_sQuery += " AND C7_EMISSAO = '"+ tra -> c7_emissao +"'" 
//		_oSQL:Exec ()
//		
//		DBSelectArea("TRA")
//		dbskip()
//	Enddo
//	
//	TRA->(DbCloseArea())
//	u_help("Compradores atualizados")
//
//	if type ('__cUserId') == 'U' .or. type ('cUserName') == 'U'
//		u_log ('Preparando ambiente')
//		prepare environment empresa '01' filial '01' modulo '05'
//		private cModulo   := 'FAT'
//		private __cUserId := "000210"
//		private cUserName := "claudia.lionco"
//		private __RelDir  := "c:\temp\spool_protheus\"
//		set century on
//	endif
//	//
//	if ! alltrim(upper(cusername)) $ 'ROBERT.KOCH/ADMINISTRADOR/CATIA.CARDOSO/ANDRE.ALVES/CLAUDIA.LIONCO'
//		msgalert ('Nao te conheco, nao gosto de ti e nao vou te deixar continuar. Vai pra casa.', procname ())
//		return
//	endif
//	//
//	private _sArqLog := procname () + "_" + alltrim (cUserName) + cEmpAnt + ".log"
//	delete file (_sArqLog)
//	u_logId ()
//	if U_Semaforo (procname ()) == 0
//		u_help ('Bloqueio de semaforo na funcao ' + procname ())
//	else
//		PtInternal (1, 'U_Claudia')
//		U_UsoRot ('I', procname (), '')
//		
//		processa ({|| _AndaLogo ()})
//		u_logDH ('Processo finalizado')
//		
//		U_UsoRot ('F', procname (), '')
//	endif
//return

// --------------------------------------------------------------------------
//static function _AndaLogo ()
//	local _sQuery    := ""
//	local _sAliasQ   := ""
//	local _oEvento   := NIL
//	local _aArqTrb   := {}
//	local _aRetSQL   := {}
//	local _nRetSQL   := 0
//	local _sCRLF     := chr (13) + chr (10)
//	local _oSQL      := NIL
//	local _lContinua := .T.
//	local _aDados    := {}
//	PRIVATE _oBatch  := ClsBatch():New ()  // Deixar definido para quando testar rotinas em batch.
//	procregua (100)
//	incproc ()
//	
//	//processa ({|| _AtualizaProduto ()})
//	
//	//processa ({|| _AtualizaRepresentante()})
//	
//	//processa ({|| _AtualizaMercanet()})
//	
//	u_help ("Nada definido", procname ())
//return
//-------------------------------------------------------------------------------------------------
//Static function _AtualizaMercanet()
//
//	_oSQL := ClsSQL ():New ()
//	_oSQL:_sQuery := ""
//	_oSQL:_sQuery += " SELECT R_E_C_N_O_ "
//	_oSQL:_sQuery += " FROM " + RetSQLName ("SA1")
//	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
//	_oSQL:_sQuery += " AND A1_FILIAL = '" + xfilial ("SA1") + "'"  // Deixar esta opcao para poder ler os campos memo.
//	_oSQL:_sQuery += " AND A1_VEND = '317'"
//	_oSQL:Log ()
//	_aDados = aclone (_oSQL:Qry2Array ())
//	
//	For _nLinha := 1 To Len(_aDados)
//		sa1 -> (dbgoto (_aDados [_nLinha, 1]))
//		U_LOG (SA1 -> A1_COD)
//		U_AtuMerc ("SA1", sa1 -> (recno ()))
//	next
//	
//Return
//-------------------------------------------------------------------------------------------------
//Static function _AtualizaRepresentante ()
//
//	u_help ("Alterar comissão do vendedor 317")
//	// Ajusta vendedor de 258 para 317
//	sa1 -> (dbsetorder (1))
//	sa1 -> (dbgotop ())
//	//
//	do while ! sa1 -> (eof ())
//		u_log ('Verificando item', sa1 -> a1_vend)
//		if alltrim(sa1 -> a1_vend) == '317'
//			//u_help ('Verificando item '+ sa1 -> a1_vend + '-'+ sa1 -> a1_cod)
//			// Cria variaveis para uso na gravacao do evento de alteracao
//			regtomemory ("SA1", .F., .F.)
//			sComissao := 5
//			
//			// Grava evento de alteracao
//			_oEvento := ClsEvent():new ()
//			_oEvento:AltCadast ("SA1", sComissao, sa1 -> (recno ()), '', .F.)
//			_oEvento:Grava()
//			
//			U_AtuMerc ("SA1", sa1 -> (recno ()))
//			
//			reclock ("SA1", .f.)
//				sa1 -> a1_comis = sComissao
//			msunlock ()
//			
//			u_log ('alterado')
//			
//			//exit
//		else
//			u_log ('Nada a alterar')
//		endif
//		//
//		sa1 -> (dbskip ())
//	enddo
//Return


////-------------------------------------------------------------------------------------------------
//Static function _AtualizaProduto ()
//	// Ajusta cadastro produtos em lote (altera codigos de barras itens que NAO TEM codigo EAN)
//	sb1 -> (dbsetorder (1))
//	sb5 -> (dbsetorder (1))
//	sb1 -> (dbgotop ())
//	//
//	do while ! sb1 -> (eof ())
//		u_log ('Verificando item', sb1 -> b1_cod, SB1 -> B1_DESC)
//		if sb1->B1_PESBRU != sb1->b1_pesbru
//		
//			// Cria variaveis para uso na gravacao do evento de alteracao
//			regtomemory ("SB1", .F., .F.)
//			m->b1_pesbru := sb1->B1_PESBRU
//			
//			// Grava evento de alteracao
//			_oEvento := ClsEvent():new ()
//			_oEvento:AltCadast ("SB1", m->b1_cod, sb1 -> (recno ()), '', .F.)
//	
//			reclock ("SB1", .f.)
//			sb1 -> b1_pesbru = m->b1_pesbru
//			msunlock ()
//			//exit
//		else
//			u_log ('nada a alterar')
//		endif
//		//
//		sb1 -> (dbskip ())
//	enddo
//
//Return
//-------------------------------------------------------------------------------------------------
// Static function _AtuISENTO ()

// 	u_help ("Alterar ISENTO")
// 	sa1 -> (dbsetorder (1))
// 	sa1 -> (dbgotop ())
// 	//
// 	do while ! sa1 -> (eof ())
// 		u_log ('Verificando item', sa1 -> a1_inscr)
// 		if alltrim(sa1 -> a1_inscr) == 'ISENTO' .or. alltrim(sa1 -> a1_inscr) == 'ISENTA'
// 			// Cria variaveis para uso na gravacao do evento de alteracao
// 			regtomemory ("SA1", .F., .F.)
			
// 			// Grava evento de alteracao
// 			_oEvento := ClsEvent():new ()
// 			_oEvento:AltCadast ("SA1", "ISENTO", sa1 -> (recno ()), '', .F.)
// 			_oEvento:Grava()
			
// 			U_AtuMerc ("SA1", sa1 -> (recno ()))
			
// 			reclock ("SA1", .f.)
// 				sa1 -> a1_inscr = ''
// 			msunlock ()
			
// 			u_log ('alterado')
			
// 			//exit
// 		else
// 			u_log ('Nada a alterar')
// 		endif
// 		sa1 -> (dbskip ())
// 	enddo
// Return
//-----------------------------------------------------------------------------------


// // --------------------------------------------------------------------------
// // Simulacoes safra 2023 durante reuniao.
// static function _SimulaSafra23 ()
// 	local _sParcel   := 'M'
// 	local _nRecCount := 0
// 	local _nRecAtu   := 0
// 	local _aRetPrc   := {}

// 	dbselectarea ("ZZ9")
// 	set filter to zz9_safra = '2023' .and. zz9_parcel = _sParcel
// 	count to _nRecCount
// 	zz9 -> (dbgotop ())
// 	_nRecAtu = 0
// 	do while ! zz9 -> (eof ())
// 		incproc ()
// 		if zz9 -> zz9_safra == '2023' .and. zz9 -> zz9_parcel == _sParcel
// 			_sClasFina = ''
// 			if zz9 -> zz9_conduc == 'L'
// 				_sClasFina = zz9 -> zz9_clabd
// 			else
// 				_sClasFina = zz9 -> zz9_classe
// 			endif
// 			if ++_nRecAtu % 100 == 0
// 				u_log2 ('info', '[' + cvaltochar (_nRecAtu) + ' de ' + cvaltochar (_nRecCount) + ']Produto ' + alltrim (zz9 -> zz9_produt) + ' gr.' + zz9 -> zz9_grau + ' ' + _sClasFina)
// 			endif
// 			_oSQL := ClsSQL ():New ()
// 			_oSQL:_sQuery := "SELECT VUNIT_EFETIVO"
// 			_oSQL:_sQuery +=  " FROM VA_VPRECO_EFETIVO_SAFRA P"
// 			_oSQL:_sQuery += " WHERE P.SAFRA      = '" + zz9 -> zz9_safra + "'"
// 			_oSQL:_sQuery +=   " AND P.FILIAL     = '" + zz9 -> zz9_filial + "'"
// 			_oSQL:_sQuery +=   " AND P.ASSOCIADO  = '" + zz9 -> zz9_fornec + "'"
// 			_oSQL:_sQuery +=   " AND P.LOJA_ASSOC = '" + zz9 -> zz9_loja + "'"
// 			_oSQL:_sQuery +=   " AND P.DOC        = '" + zz9 -> zz9_nfori + "'"
// 			_oSQL:_sQuery +=   " AND P.SERIE      = '" + zz9 -> zz9_serior + "'"
// 			_oSQL:_sQuery +=   " AND P.ITEM_NOTA  = '" + zz9 -> zz9_itemor + "'"
// 			_nVUnOld = _oSQL:RetQry (1, .f.)

// 			_aRetPrc = aclone (U_PrcUva23 (zz9 -> zz9_filial, zz9 -> zz9_produt, val (zz9 -> zz9_grau), _sClasFina, zz9 -> zz9_conduc, .F., .F.))

// 			reclock ("ZZ9", .F.)
// 			zz9 -> zz9_vunold = _nVUnOld
// 			zz9 -> zz9_vunit  = _aRetPrc [2]
// 			zz9 -> zz9_obs    = _aRetPrc [3]  // Observacoes geradas pelo prog. de calculo do preco
// 			zz9 -> zz9_nfcomp = iif (zz9 -> zz9_vunit <= zz9 -> zz9_vunold, 'VLR_MENOR', '')  // Para evitar que posteriormente o programa VA_GNF2 tente gerar nota para este registro.
// 			zz9 -> zz9_sercom = ''
// 			msunlock ()
// 		endif
// 		zz9 -> (dbskip ())
// 	enddo
// return


// User Function AjFiscal()
//     Local _oSQL := ClsSQL ():New ()
//     Local _x    := 0
//     Private cPerg   := "AjFiscal"
    
// 	_ValidPerg()
// 	If Pergunte(cPerg,.T.)

//         // NOTAS 50 PARA 56
//         _oSQL:_sQuery := ""
//         _oSQL:_sQuery += " SELECT " 
//         _oSQL:_sQuery += " 	   D1_FILIAL "  // 1
//         _oSQL:_sQuery += "    ,D1_SERIE "   // 2
//         _oSQL:_sQuery += "    ,D1_DOC "     // 3
//         _oSQL:_sQuery += "    ,D1_FORNECE " // 4
//         _oSQL:_sQuery += "    ,D1_LOJA "    // 5
//         _oSQL:_sQuery += "    ,D1_ITEM "    // 6
//         _oSQL:_sQuery += "    ,D1_COD "     // 7
//         _oSQL:_sQuery += "    ,D1_TES "     // 8
//         _oSQL:_sQuery += "    ,F4_CSTPIS "  // 9
//         _oSQL:_sQuery += "    ,F4_CSTCOF "  // 10
//         _oSQL:_sQuery += " FROM SD1010 SD1 "
//         _oSQL:_sQuery += " INNER JOIN SF4010 SF4 "
//         _oSQL:_sQuery += " 	ON SF4.F4_CODIGO = D1_TES "
//         _oSQL:_sQuery += " 		AND SF4.F4_CSTPIS = '56' "
//         _oSQL:_sQuery += " 		AND SF4.F4_CSTCOF = '56' "
//         _oSQL:_sQuery += " WHERE SD1.D_E_L_E_T_ = '' "
//         _oSQL:_sQuery += " AND D1_DTDIGIT BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"' "
//         _aSD1 := aclone(_oSQL:Qry2Array (.F., .F.))

//         For _x:=1 to Len(_aSD1)
//             DbSelectArea("SFT")
//             DbSetOrder(1)
//             If SFT->(DbSeek(_aSD1[_x,1] + 'E' + _aSD1[_x,2] + _aSD1[_x,3] + _aSD1[_x,4] + _aSD1[_x,5] + _aSD1[_x,6] + _aSD1[_x,7]))  // FT_FILIAL+FT_TIPOMOV+FT_SERIE+FT_NFISCAL+FT_CLIEFOR+FT_LOJA+FT_ITEM+FT_PRODUTO
//                 RecLock("SFT",.F.)
//                     SFT->FT_CSTPIS := _aSD1[_x, 9]
//                     SFT->FT_CSTCOF := _aSD1[_x,10]
//                 MsUnLock()
//                 _sChave := _aSD1[_x,1] + 'E' + _aSD1[_x,2] + _aSD1[_x,3] + _aSD1[_x,4] + _aSD1[_x,5] + _aSD1[_x,6] + _aSD1[_x,7]

//                 // grava log de alteração
//                 _oEvento:= ClsEvent():new ()
//                 _oEvento:CodEven   = "ALT001"
//                 _oEvento:Texto	   = "Alterado CST PIS/COFINS de 50 para 56. CHAVE:" + _sChave
//                 _oEvento:Alias     = "SFT"
//                 _oEvento:ChaveNFe  = _sChave
//                 _oEvento:Grava ()
//             EndIf
//         Next


//         //  // NOTAS 64 PARA 98
//         // _oSQL:_sQuery := ""
//         // _oSQL:_sQuery += " SELECT " 
//         // _oSQL:_sQuery += " 	   D1_FILIAL "  // 1
//         // _oSQL:_sQuery += "    ,D1_SERIE "   // 2
//         // _oSQL:_sQuery += "    ,D1_DOC "     // 3
//         // _oSQL:_sQuery += "    ,D1_FORNECE " // 4
//         // _oSQL:_sQuery += "    ,D1_LOJA "    // 5
//         // _oSQL:_sQuery += "    ,D1_ITEM "    // 6
//         // _oSQL:_sQuery += "    ,D1_COD "     // 7
//         // _oSQL:_sQuery += "    ,D1_TES "     // 8
//         // _oSQL:_sQuery += "    ,F4_CSTPIS "  // 9
//         // _oSQL:_sQuery += "    ,F4_CSTCOF "  // 10
//         // _oSQL:_sQuery += " FROM SD1010 SD1 "
//         // _oSQL:_sQuery += " INNER JOIN SF4010 SF4 "
//         // _oSQL:_sQuery += " 	ON SF4.F4_CODIGO = D1_TES "
//         // _oSQL:_sQuery += " 		AND SF4.F4_CSTPIS = '98' "
//         // _oSQL:_sQuery += " 		AND SF4.F4_CSTCOF = '98' "
//         // _oSQL:_sQuery += " WHERE SD1.D_E_L_E_T_ = '' "
//         // _oSQL:_sQuery += " AND D1_DTDIGIT BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"' "
//         // _aSD1 := aclone(_oSQL:Qry2Array (.F., .F.))

//         // For _x:=1 to Len(_aSD1)
//         //     DbSelectArea("SFT")
//         //     DbSetOrder(1)
//         //     If SFT->(DbSeek(_aSD1[_x,1] + 'E' + _aSD1[_x,2] + _aSD1[_x,3] + _aSD1[_x,4] + _aSD1[_x,5] + _aSD1[_x,6] + _aSD1[_x,7]))  // FT_FILIAL+FT_TIPOMOV+FT_SERIE+FT_NFISCAL+FT_CLIEFOR+FT_LOJA+FT_ITEM+FT_PRODUTO
//         //         RecLock("SFT",.F.)
//         //             SFT->FT_CSTPIS := _aSD1[_x, 9]
//         //             SFT->FT_CSTCOF := _aSD1[_x,10]
//         //         MsUnLock()
//         //         _sChave := _aSD1[_x,1] + 'E' + _aSD1[_x,2] + _aSD1[_x,3] + _aSD1[_x,4] + _aSD1[_x,5] + _aSD1[_x,6] + _aSD1[_x,7]

//         //         // grava log de alteração
//         //         _oEvento:= ClsEvent():new ()
//         //         _oEvento:CodEven   = "ALT001"
//         //         _oEvento:Texto	   = "Alterado CST PIS/COFINS de 64 para 98. CHAVE:" + _sChave
//         //         _oEvento:Alias     = "SFT"
//         //         _oEvento:ChaveNFe  = _sChave
//         //         _oEvento:Grava ()
//         //     EndIf
//         // Next

//         // CD2
//         For _x:=1 to Len(_aSD1)
//             DbSelectArea("CD2")
//             DbSetOrder(1)
//             If CD2->(DbSeek(_aSD1[_x,1] + 'E' + _aSD1[_x,2] + _aSD1[_x,3] + _aSD1[_x,4] + _aSD1[_x,5] + _aSD1[_x,6]+ _aSD1[_x,7]))  // CD2_FILIAL+CD2_TPMOV+CD2_SERIE+CD2_DOC+CD2_CODCLI+CD2_LOJCLI+CD2_ITEM+CD2_CODPRO+CD2_IMP
//                 RecLock("CD2",.F.)
//                     CD2->CD2_CST := _aSD1[_x, 9]
//                 MsUnLock()

//                 _sChave := _aSD1[_x,1] + 'E' + _aSD1[_x,3] + _aSD1[_x,2] 
//                 // grava log de alteração
//                 _oEvento:= ClsEvent():new ()
//                 _oEvento:CodEven   = "ALT001"
//                 _oEvento:Texto	   = "Alterado CST PIS/COFINS de 50 para 56. CHAVE:" + _sChave
//                 _oEvento:Alias     = "CD2"
//                 _oEvento:ChaveNFe  = _sChave
//                 _oEvento:Grava ()
//             EndIf
//         Next


//         // ATIVO
//         _oSQL:_sQuery := ""
//         _oSQL:_sQuery += " SELECT N1_FILIAL, N1_CBASE, N1_ITEM  FROM SN1010 "
//         _oSQL:_sQuery += " WHERE D_E_L_E_T_= '' "
//         _oSQL:_sQuery += " AND N1_CSTPIS   = '50'"
//         _oSQL:_sQuery += " AND N1_CSTCOFI  = '50'"
//         _oSQL:_sQuery += " AND N1_AQUISIC BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"' "
//         _aSN1 := aclone(_oSQL:Qry2Array (.F., .F.))

//         For _x:=1 to Len(_aSN1)
//             DbSelectArea("SN1")
//             DbSetOrder(1)
//             If SN1->(DbSeek(_aSN1[_x, 1] + _aSN1[_x, 2] + _aSN1[_x, 3]))  // N1_FILIAL+N1_CBASE+N1_ITEM
//                 RecLock("SN1",.F.)
//                     SN1->N1_CSTPIS  := '56'
//                     SN1->N1_CSTCOFI := '56'
//                 MsUnLock()

//                 _sChave := _aSN1[_x, 1] + _aSN1[_x, 2] + _aSN1[_x, 3]
//                 // grava log de alteração
//                 _oEvento:= ClsEvent():new ()
//                 _oEvento:CodEven   = "ALT001"
//                 _oEvento:Texto	   = "Alterado CST PIS/COFINS de 50 para 56. CHAVE:" + _sChave
//                 _oEvento:Alias     = "SN1"
//                 _oEvento:ChaveNFe  = _sChave
//                 _oEvento:Grava ()
//             EndIf
//         Next

//         _oSQL:_sQuery := ""
//         _oSQL:_sQuery += " SELECT "
//         _oSQL:_sQuery += " 	   CF8_FILIAL "
//         _oSQL:_sQuery += "    ,CF8_CODIGO "
//         _oSQL:_sQuery += " FROM CF8010 "
//         _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
//         _oSQL:_sQuery += " AND CF8_DTOPER BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"' "
//         _oSQL:_sQuery += " AND CF8_CSTPIS = '50' "
//         _oSQL:_sQuery += " AND CF8_CSTCOF = '50' "
//         _aCF8 := aclone(_oSQL:Qry2Array (.F., .F.))

//         For _x:=1 to Len(_aCF8)
//             DbSelectArea("CF8")
//             DbSetOrder(1)
//             If CF8->(DbSeek(_aCF8[_x, 1] + _aCF8[_x, 2] ))  // CF8_FILIAL+CF8_CODIGO
//                 RecLock("CF8",.F.)
//                     CF8->CF8_CSTPIS := '56'
//                     CF8->CF8_CSTCOF := '56'
//                 MsUnLock()

//                 _sChave := _aCF8[_x, 1] + _aCF8[_x, 2]
//                 // grava log de alteração
//                 _oEvento:= ClsEvent():new ()
//                 _oEvento:CodEven   = "ALT001"
//                 _oEvento:Texto	   = "Alterado CST PIS/COFINS de 50 para 56. CHAVE:" + _sChave
//                 _oEvento:Alias     = "CF8"
//                 _oEvento:ChaveNFe  = _sChave
//                 _oEvento:Grava ()
//             EndIf
//         Next
//     EndIf
// Return

// //
// // --------------------------------------------------------------------------
// // Cria Perguntas no SX1
// Static Function _ValidPerg ()
// 	local _aRegsPerg := {}
// 	local _aDefaults := {}

// 	//                 Ordem Descri                          tipo tam           dec          valid    F3     opcoes (combo)                                 help
// 	aadd (_aRegsPerg, {01, "Data Inicial ", "D", 8,  0,  "",   "   ", {},                   	""})
// 	aadd (_aRegsPerg, {02, "Data Final   ", "D", 8,  0,  "",   "   ", {},                   	""})
// 	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
// Return

// User Function BACACTB (_lAuto)
//     Local _x        := 0

//         _oSQL:= ClsSQL ():New ()
//         _oSQL:_sQuery := ""
//         _oSQL:_sQuery += " SELECT DISTINCT "
//         _oSQL:_sQuery += "	    D1_DOC "
//         _oSQL:_sQuery += " FROM SD1010 "
//         _oSQL:_sQuery += " WHERE D1_DTDIGIT BETWEEN '20230101' AND '20231231' "
//         _oSQL:_sQuery += " AND (D1_VALIPI > 0 "
//         _oSQL:_sQuery += " OR D1_ICMSRET > 0) "
//         _oSQL:_sQuery += " AND D1_CF IN ('1201', '2201', '2410', '1410') "
//         _oSQL:_sQuery += " AND D1_DOC NOT IN ( "
//         _oSQL:_sQuery += "  '000003052', "
//         _oSQL:_sQuery += "  '000019343', "
//         _oSQL:_sQuery += "  '000020362', "
//         _oSQL:_sQuery += "  '000020720', "
//         _oSQL:_sQuery += "  '005509465' "
//         _oSQL:_sQuery += ") "
//         _aCTB := aclone(_oSQL:Qry2Array (.F., .F.))

//         For _x:=1 to Len(_aCTB)

//             _mv01 := 1
//             _mv02 := stod('20230101')
//             _mv03 := stod('20231231')
//             _mv04 := _aCTB[_x, 1]
//             _mv05 := _aCTB[_x, 1]
//             _mv06 := ''
//             _mv07 :='ZZZ'
//             _mv08 :=''
//             _mv09 :='ZZZ'
//             _mv10 :=''
//             _mv11 :='ZZZ'
//             _mv12 := 3
//             _mv13 := 2

//             Processa( { |lEnd| _GeraCTB(_mv01,_mv02,_mv03,_mv04,_mv05,_mv06,_mv07,_mv08,_mv09,_mv10,_mv11, _mv12, _mv13) } )

//             u_log('Ajustando item ', _mv04)
//         Next

// return
	
// // --------------------------------------------------------------------------
// Static Function _GeraCTB(_mv01,_mv02,_mv03,_mv04,_mv05,_mv06,_mv07,_mv08,_mv09,_mv10,_mv11, _mv12, _mv13)
// 	local _oEvento := NIL
// 	local _sNick   := ""
// 	local _nAlter  := 0
// 	local _sIdFKA  := ''

// 	procregua (1000)

// 	do case
// 	case _mv01 == 1
// 		_sNick = "F1_DTDIGIT"
// 		if U_TemNick ("SF1", _sNick)
// 			sf1 -> (dbOrderNickName (_sNick))  // F1_FILIAL+DTOS(F1_DTDIGIT)
// 			sf1 -> (dbseek (xfilial ("SF1") + dtos (_mv02), .T.))
// 			do while ! sf1 -> (eof ()) .and. sf1 -> f1_filial == xfilial ("SF1") .and. sf1 -> f1_dtdigit <= _mv03
// 				incproc (cvaltochar (sf1 -> f1_dtdigit))
// 				if sf1 -> f1_doc >= _mv04 .and. sf1 -> f1_doc <= _mv05 .and. ! empty (sf1 -> f1_dtlanc)
// 					if _mv13 == 2  // Executar
// 						_oEvento := ClsEvent():new ()
// 						_oEvento:CodEven   = "SF1010"
// 						_oEvento:Texto     = "Alterando data contabilizacao de '" + dtoc (sf1 -> f1_dtlanc) + "' para ' / / '"
// 						_oEvento:NFEntrada = sf1 -> f1_doc
// 						_oEvento:SerieEntr = sf1 -> f1_serie
// 						_oEvento:Fornece   = sf1 -> f1_fornece
// 						_oEvento:LojaFor   = sf1 -> f1_loja
// 						_oEvento:Grava ()
// 						reclock ("SF1", .F.)
// 						sf1 -> f1_dtlanc = ctod ("")
// 						msunlock ()
// 					endif
// 					_nAlter ++
// 				endif
// 				sf1 -> (dbskip ())
// 			enddo
// 		else
// 			u_help ("Indice '" + _sNick + "' nao existe.")
// 		endif

// 	case _mv01 == 2
// 		_sNick = "F2_EMISSAO"
// 		if U_TemNick ("SF2", _sNick)
// 			sf2 -> (dbOrderNickName (_sNick))  // f2_FILIAL+DTOS(F2_EMISSAO)
// 			sf2 -> (dbseek (xfilial ("SF2") + dtos (_mv02), .T.))
// 			do while ! sf2 -> (eof ()) .and. sf2 -> f2_filial == xfilial ("SF2") .and. sf2 -> f2_emissao <= _mv03
// 				incproc (cvaltochar (sf2 -> f2_emissao))
// 				if sf2 -> f2_doc >= _mv04 .and. sf2 -> f2_doc <= _mv05 .and. ! empty (sf2 -> f2_dtlanc)
// 					if _mv13 == 2  // Executar
// 						_oEvento := ClsEvent():new ()
// 						_oEvento:CodEven   = "SF2010"
// 						_oEvento:Texto     = "Alterando data contabilizacao de '" + dtoc (sf2 -> f2_dtlanc) + "' para ' / / '"
// 						_oEvento:NFSaida   = sf2 -> f2_doc
// 						_oEvento:SerieSaid = sf2 -> f2_serie
// 						_oEvento:Cliente   = sf2 -> f2_cliente
// 						_oEvento:LojaCli   = sf2 -> f2_loja
// 						_oEvento:Grava ()
// 						reclock ("SF2", .F.)
// 						sf2 -> f2_dtlanc = ctod ("")
// 						msunlock ()
// 					endif
// 					_nAlter ++
// 				endif
// 				sf2 -> (dbskip ())
// 			enddo
// 		else
// 			u_help ("Indice '" + _sNick + "' nao existe.")
// 		endif

// 	case _mv01 == 3
// 		se5 -> (dbsetorder (1)) // E5_FILIAL+DTOS(E5_DATA)+E5_BANCO+E5_AGENCIA+E5_CONTA+E5_NUMCHEQ
// 		se5 -> (dbseek (xfilial ("SE5") + dtos (_mv02), .T.))
// 		do while ! se5 -> (eof ()) .and. se5 -> e5_filial == xfilial ("SE5") .and. se5 -> e5_data <= _mv03
// 			incproc (cvaltochar (se5 -> e5_data))
// 			if alltrim (se5 -> e5_la)   == "S" ;
// 					.and. se5 -> e5_banco   >= _mv06 .and. se5 -> e5_banco   <= _mv07 ;
// 					.and. se5 -> e5_agencia >= _mv08 .and. se5 -> e5_agencia <= _mv09 ;
// 					.and. se5 -> e5_conta   >= _mv10 .and. se5 -> e5_conta   <= _mv11 ;
// 					.and. se5 -> e5_numero  >= _mv04 .and. se5 -> e5_numero  <= _mv05
// 				if (_mv12 == 1 .and. empty (se5 -> e5_arqcnab)) .or. (_mv12 == 2 .and. !empty (se5 -> e5_arqcnab))
// 					se5 -> (dbskip ())
// 					loop
// 				endif
// 				if _mv13 == 2  // Executar
// 				//	if ! "TESTE" $ upper (GetEnvServer ())  // Por questao de performance
// 					if ! U_AmbTeste ()
// 						_oEvento := ClsEvent():new ()
// 						_oEvento:CodEven   = "SE5001"
// 						_oEvento:Texto     = "Limpando campo E5_LA"
// 						_oEvento:Recno     = se5 -> (recno ())
// 						_oEvento:Alias     = 'SE5'
// 						_oEvento:CodAlias  = se5 -> e5_prefixo + se5 -> e5_numero + se5 -> e5_parcela
// 						_oEvento:Grava ()
// 					endif
// 					reclock ("SE5", .F.)
// 					se5 -> e5_la = ""
// 					msunlock ()
// 				endif	

// 				// Se encontrar relacionamento nas novas tabelas do financeiro, limpa tambem.
// 				if ! empty (se5 -> e5_idorig)
// 					// PROVAVELMENTE PRECISE FAZER A MESMA COISA NO FK1, MAS NO MOMENTO TO COM PRESSA... ROBERT, 03/08/2021 (GLPI 10644)
// 					fk2 -> (dbsetorder (1))  // FK2_FILIAL, FK2_IDFK2, R_E_C_N_O_, D_E_L_E_T_
// 					if fk2 -> (dbseek (xfilial ("FK2") + se5 -> e5_idorig, .F.))
// 						if _mv13 == 2  // Executar
// 							U_Log2 ('debug', 'Encontrei FK2')
// 						//	if ! "TESTE" $ upper (GetEnvServer ())  // Por questao de performance
// 							if ! U_AmbTeste ()
// 								_oEvento := ClsEvent():new ()
// 								_oEvento:CodEven   = "FK2001"
// 								_oEvento:Texto     = "Limpando campo FK2_LA"
// 								_oEvento:Recno     = fk2 -> (recno ())
// 								_oEvento:Alias     = 'FK2'
// 								_oEvento:CodAlias  = fk2 -> fk2_idfk2
// 								_oEvento:Grava ()
// 							endif
// 							reclock ("FK2", .f.)
// 							fk2 -> fk2_la = ''
// 							msunlock ()
// 						endif
					
// 						fka -> (dbsetorder (3))  // FKA_FILIAL, FKA_TABORI, FKA_IDORIG, R_E_C_N_O_, D_E_L_E_T_
// 						if fka -> (dbseek (xfilial ("FKA") + 'FK2' + fk2 -> fk2_idfk2, .F.))
// 							U_Log2 ('debug', 'Encontrei FKA')
// 							_sIdFKA = fka -> fka_idproc
// 							fka -> (dbsetorder (2))  // FKA_FILIAL, FKA_IDPROC, FKA_IDORIG, FKA_TABORI, R_E_C_N_O_, D_E_L_E_T_
// 							fka -> (dbseek (xfilial ("FKA") + _sIdFKA, .T.))
// 							do while ! fka -> (eof ()) .and. fka -> fka_filial == xfilial ("FKA") .and. fka -> fka_idproc == _sIdFKA
// 								if fka -> fka_tabori == 'FK5'
// 									U_Log2 ('debug', 'Procurando FK5 com ID = ' + fka -> fka_idorig)
// 									fk5 -> (dbsetorder (1))  // FK5_FILIAL, FK5_IDMOV, R_E_C_N_O_, D_E_L_E_T_
// 									if fk5 -> (dbseek (xfilial ("FK5") + fka -> fka_idorig, .F.))
// 										U_Log2 ('debug', 'Encontrei FK5')
// 										if _mv13 == 2  // Executar
// 										//	if ! "TESTE" $ upper (GetEnvServer ())  // Por questao de performance
// 											if ! U_AmbTeste ()
// 												_oEvento := ClsEvent():new ()
// 												_oEvento:CodEven   = "FK5001"
// 												_oEvento:Texto     = "Limpando campo FK5_LA"
// 												_oEvento:Recno     = fk5 -> (recno ())
// 												_oEvento:Alias     = 'FK5'
// 												_oEvento:CodAlias  = fk5 -> fk5_idmov
// 												_oEvento:Grava ()
// 											endif
// 											reclock ("FK5", .f.)
// 											fk5 -> fk5_la = ''
// 											msunlock ()
// 										endif
// 									endif
// 								endif
// 								fka -> (dbskip ())
// 							enddo
// 						endif
// 					endif
// 				endif
// 				_nAlter ++
// 			endif
// 			se5 -> (dbskip ())
// 		enddo
// 	endcase

// 	u_help ("Processo concluido. " + cvaltochar (_nAlter) + " documento(s) " + iif (_mv13 == 1, "teria(m) sido ", "") + "alterado(s).")
// return
