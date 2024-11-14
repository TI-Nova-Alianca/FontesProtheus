// Programa.: CUSTOMERVENDOR
// Autor....: Andre Alves
// Data.....: 06/05/2019
// Descricao: Ponto entrada na tela cadastro de Fornecedores.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada generico no cadastro de fornecedores.
// #PalavasChave      #ponto_entrada
// #TabelasPrincipais #SA2
// #Modulos           #COM #EST #COOP
//
// Historico de alteracoes:
// 15/07/2022 - Robert  - Impede exclusao se tiver movimentacao na conta corrente de associados.
// 01/08/2023 - Robert  - Guardar motivo de alt.dados banc.assoc - GLPI 14026
//                      - Validacao 'tudo OK' passada do MODELPOS para FORMPOS (executava 2 vezes)
//                      - Botao consulta eventos do fornecedor
// 09/10/2024 - Claudia - Criada a função _AlteraNAWeb para envio de dados do fornecedor
//                        associado para NAWEB. GLPI: 10138
// 14/10/2024 - Claudia - Alterada avalidação para inclusão de fornecedor-associado. GLPI: 16239
// 14/11/2024 - Claudia - Alterada chamada da rotina para retornar data de entrada/saida de associados
//
// --------------------------------------------------------------------------------------------------
#include "protheus.ch"
#include "parmtype.ch"

user Function CUSTOMERVENDOR()
	Local aParam   := PARAMIXB
	Local _xRet    := .T.
	Local oObj     := ""
	Local cIdPonto := ""
	Local cIdModel := ""
	Local _lIsGrid := .F.
	local _nOper   := 0
	private _sMotAltBc := space(200)

	If aParam <> NIL
		// Habilitar somente para debug --> U_Log2 ('debug', '[' + procname () + ']cIdPonto: ' + cIdPonto + '  cIdModel: ' + cIdModel)
		oObj := aParam[1]
		cIdPonto := aParam[2]
		cIdModel := aParam[3]  // SA2MASTER = tela principal; SA2KDE = complemento fornecedor
		_lIsGrid := (Len(aParam) > 3)

		If cIdPonto == "MODELPOS"  // Chamada na validação total do modelo (tela inteira)
			_nOper := oObj:nOperation
			if _xRet .and. _nOper == 5  // Exclusao
				_xRet = _PodeExcl()
			endif

		ElseIf cIdPonto == "FORMPOS"  // Chamada na validação total do formulário
			if cIdModel == 'SA2MASTER'
				_xRet := MA020TDOK()
				if _xRet
					_GeraLog()
					_AlteraNAWeb()
				endif
			endif

		ElseIf cIdPonto == "FORMLINEPRE"  // Chamada na pré validação da linha do formulário
			_xRet := .T.

		ElseIf cIdPonto == "FORMLINEPOS"  // Chamada na validação da linha do formulário
			_xRet := .T.

		ElseIf cIdPonto == "MODELCOMMITTTS"  // Chamada após a gravação total do modelo e dentro da transação
			_xRet = NIL

		ElseIf cIdPonto == "MODELCOMMITNTTS"  // Chamada após a gravação total do modelo e fora da transação
			_xRet = NIL

		ElseIf cIdPonto == "FORMCOMMITTTSPRE"  // Chamada após a gravação da tabela do formulário
			_xRet = NIL

		ElseIf cIdPonto == "FORMCOMMITTTSPOS"  // Chamada após a gravação da tabela do formulário
			_xRet = NIL

		ElseIf cIdPonto == "MODELCANCEL"  // "Deseja realmente sair?"
			_xRet := .T.

		ElseIf cIdPonto == "BUTTONBAR"  // Adicionar botoes
			_xRet := {{"Alianca-Eventos", "EVENTOS", {||U_VA_SZNC('ALIAS_CHAVE', 'SA2', sa2 -> a2_cod + sa2 -> a2_loja)}}}

		EndIf
	EndIf
Return _xRet
//
//
// --------------------------------------------------------------------------------------------------
static function _GeraLog()
	local _oEvento  := NIL

	//	 Grava log de evento em caso de alteracao de cadastro.
	if altera
		_oEvento := ClsEvent():new ()
		_oEvento:AltCadast ("SA2", m->a2_cod + m->a2_loja, sa2 -> (recno ()), iif (! empty (_sMotAltBc), 'Motivo alt.dados banc.:' + _sMotAltBc, ''))
	endif
return
//
//
// --------------------------------------------------------------------------------------------------
Static Function MA020TDOK()
	Local _aArea    := GetArea()
	Local _aAreaSA2 := SA2->(GetArea())
	Local _xFim     := chr(13)+chr(10)
	Local _lRet     := .T.
	Local _xCOD     := M->A2_COD
	Local _xLOJA    := M->A2_LOJA
	Local _xNOME    := M->A2_NOME
	Local _xEST     := M->A2_EST
	Local _xTIPO    := M->A2_TIPO
	Local _xCGC     := M->A2_CGC
	Local _nInd     := 0

	// Consiste Estado com Tipo do Fornecedor (Critica Importacao)
	If _lRet
		If ( _xEST == "EX" .And. _xTIPO <> "X" ) .Or. ( _xEST <> "EX" .And. _xTIPO == "X" )
			MsgInfo("Fornecedor: "+Trim(_xCOD)+"/"+Trim(_xLOJA)+" - "+_xNOME+_xFim+;
			"Verifique o campo ESTADO e o Campo TIPO pois existe incoerencia."+_xFim;
			,"Atencao !!!  Incoerencia entre o Campo ESTADO e TIPO.")
			_lRet := .F.
		Endif
	Endif
	
	// Consiste !Importacao X Preenchimento do CNPJ / CPF
	If _lRet
		If  ( _xEST <> "EX" .And. _xTIPO <> "X" ) .And. Empty(_xCGC)
			MsgInfo("Fornecedor: "+Trim(_xCOD)+"/"+Trim(_xLOJA)+" - "+_xNOME+_xFim+;
			"Verifique o campo CNPJ / CPF. O mesmo deve estar Preenchido."+_xFim;
			,"Atencao !!!  Obrigatorio CNPJ / CPF.")
			_lRet := .F.
		Endif
		If  ( _xEST <> "EX" .And. _xTIPO <> "X" ) .And. _xCGC == "00000000000000"
			MsgInfo("Fornecedor: "+Trim(_xCOD)+"/"+Trim(_xLOJA)+" - "+_xNOME+_xFim+;
			"Verifique o campo CNPJ / CPF. O mesmo deve estar Preenchido."+_xFim;
			,"Atencao !!!  Nao preencher CNPJ / CPF com zero.")
			_lRet := .F.
		Endif
	Endif

	// Verifico se todos os caracteres do Codigo sao numeros                    
	If _lRet
		For _nInd := 1 To Len(_xCOD)
			_cChar := Substr(_xCOD,_nInd,1)
			If IsAlpha(_cChar)
				MsgInfo("O Codigo so permite Campos Numericos."+_xFim;
				,"Atencao !!!  Codigo Invalido.")
				_lRet := .F.
				Exit
			Endif
		Next
	Endif
	
	// Consistencias para associados.
	if (empty (m->a2_vaCBase) .and. ! empty (m->a2_vaLBase)) .or. (!empty (m->a2_vaCBase) .and. empty (m->a2_vaLBase))
		u_help ("Os campos '" + alltrim (RetTitle ("A2_VACBASE")) + "' e '" + alltrim (RetTitle ("A2_VALBASE")) + "' devem ser ambos informados ou deixados em branco.")
		_lRet = .F.
	endif

	if _lRet .and. (m->a2_banco != sa2 -> a2_banco .or. m->a2_agencia != sa2 -> a2_agencia .or. m->a2_numcon != sa2 -> a2_numcon)
		do while .t.
			_sMotAltBc = U_Get ("Motivo alteracao dados bancarios", 'C', len (_sMotAltBc), '@!', '', _sMotAltBc, .f., '.t.')
			if ! empty (_sMotAltBc)
				exit
			endif
			if valtype (_sMotAltBc) == 'U'  // Usuario pressionou ESC
				_sMotAltBc = space (200)
			endif
		enddo
	endif

	RestArea(_aAreaSA2)
	RestArea(_aArea)
	
Return(_lRet)
//
//
// --------------------------------------------------------------------------------------------------
static function _PodeExcl()
	local _lRet := .T.

	szi -> (dbsetorder (1))  // ZI_FILIAL, ZI_ASSOC, ZI_LOJASSO, ZI_DATA, ZI_TM, R_E_C_N_O_, D_E_L_E_T_
	if szi -> (dbseek (xfilial ("SZI") + m->a2_cod + m->a2_loja, .T.))
		u_help ("Fornecedor tem movimentacao na conta corrente de associados. Exclusao nao permitida.",, .t.)
		_lRet = .F.
	endif
return _lRet
//
//
// --------------------------------------------------------------------------------------------------
Static Function _AlteraNAWeb()
    Local _x         := 0
    Local _sEntrada  := ""
    Local _sSaida    := ""
    Local _sSituacao := ""
    Local _oWSNaWeb  := NIL

    _oSQL := ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += "       dbo.VA_ASSOC_DT_ENTRADA_SAIDA('"+ M->A2_COD +"', '"+ M->A2_LOJA +"', FORMAT(GETDATE(), 'yyyyMMdd'),'E') AS ENTRADA " 
    _oSQL:_sQuery += "      ,dbo.VA_ASSOC_DT_ENTRADA_SAIDA('"+ M->A2_COD +"', '"+ M->A2_LOJA +"', FORMAT(GETDATE(), 'yyyyMMdd'),'S') AS SAIDA "
    _oSQL:_sQuery += "      ,CASE
	_oSQL:_sQuery += "	        WHEN SUBSTRING(dbo.VA_FTIPO_FORNECEDOR_UVA('"+ M->A2_COD +"', '"+ M->A2_LOJA +"', FORMAT(GETDATE(), 'yyyyMMdd')), 1, 1)  = '1' THEN 1 " //'ASSOCIADO'
	_oSQL:_sQuery += "	        WHEN SUBSTRING(dbo.VA_FTIPO_FORNECEDOR_UVA('"+ M->A2_COD +"', '"+ M->A2_LOJA +"', FORMAT(GETDATE(), 'yyyyMMdd')), 1, 1)  = '2' THEN 2 " //'FORNECEDOR/NÃO ASSOCIADO'   
	_oSQL:_sQuery += "	        WHEN SUBSTRING(dbo.VA_FTIPO_FORNECEDOR_UVA('"+ M->A2_COD +"', '"+ M->A2_LOJA +"', FORMAT(GETDATE(), 'yyyyMMdd')), 1, 1)  = '3' THEN 3 " //'EX ASSOCIADO'  
	_oSQL:_sQuery += "	        WHEN SUBSTRING(dbo.VA_FTIPO_FORNECEDOR_UVA('"+ M->A2_COD +"', '"+ M->A2_LOJA +"', FORMAT(GETDATE(), 'yyyyMMdd')), 1, 1)  = '4' THEN 4 " //'PROD. PROPRIA'  
	_oSQL:_sQuery += "	        WHEN SUBSTRING(dbo.VA_FTIPO_FORNECEDOR_UVA('"+ M->A2_COD +"', '"+ M->A2_LOJA +"', FORMAT(GETDATE(), 'yyyyMMdd')), 1, 1)  = '5' THEN 5 " //'NÃO ASSOC INATIVO'  
	_oSQL:_sQuery += "	        WHEN SUBSTRING(dbo.VA_FTIPO_FORNECEDOR_UVA('"+ M->A2_COD +"', '"+ M->A2_LOJA +"', FORMAT(GETDATE(), 'yyyyMMdd')), 1, 1)  = '6' THEN 6 " //'NÃO FORNECE UVA' 
	_oSQL:_sQuery += "       END TIPO "
    _aRet := aclone(_oSQL:Qry2Array())

    For _x :=1 to Len(_aRet)
        _sEntrada := _aRet[_x,1]
        _sSaida   := _aRet[_x,2]
        _sSituacao:= str(_aRet[_x,3])
    Next

    If (alltrim(_sSituacao) $ ('1/2/3/4')) .or. (alltrim(M->A2_NATUREZ) == '120201' .and. alltrim(M->A2_CONTA) == '201030101001')

		_sEmail :=	M->A2_EMAIL +';'+ M->A2_VAMDANF

        _sXML := '<?xml version="1.0" encoding="utf-8"?>'
        _sXML += '<SDT_AssociadoNovo>'
        _sXML +=    '<Item>'
        _sXML +=        '<A2_CGC>'       + M->A2_CGC            +'</A2_CGC>'
        _sXML +=        '<A2_NOME>'      + M->A2_NOME           +'</A2_NOME>'
        _sXML +=        '<A2_VARG>'      + M->A2_VARG           +'</A2_VARG>' 
        _sXML +=        '<A2_VADTNAS>'   + DTOS(M->A2_VADTNAS)  +'</A2_VADTNAS>' 
        _sXML +=        '<A2_TIPO>'      + M->A2_TIPO           +'</A2_TIPO>' 
        _sXML +=        '<A2_VASEXO>'    + M->A2_VASEXO         +'</A2_VASEXO>'
        _sXML +=        '<A2_VAMDANF>'   + _sEmail              +'</A2_VAMDANF>' 
        _sXML +=        '<A2_END>'       + M->A2_END            +'</A2_END>' 
        _sXML +=        '<A2_CEP>'       + M->A2_CEP            +'</A2_CEP>'
        _sXML +=        '<A2_INSCR>'     + M->A2_INSCR          +'</A2_INSCR>' 
        _sXML +=        '<A2_LOJA>'      + M->A2_LOJA           +'</A2_LOJA>' 
        _sXML +=        '<A2_CONTA>'     + M->A2_NUMCON         +'</A2_CONTA>' 
        _sXML +=        '<A2_AGENCIA>'   + M->A2_AGENCIA        +'</A2_AGENCIA>' 
        _sXML +=        '<A2_BANCO>'     + M->A2_BANCO          +'</A2_BANCO>' 
        _sXML +=        '<A2_TEL>'       + M->A2_TEL            +'</A2_TEL>' 
        _sXML +=        '<A2_VACELUL>'   + M->A2_VACELUL        +'</A2_VACELUL>' 
        _sXML +=        '<A2_COD>'       + M->A2_COD            +'</A2_COD>' 
        _sXML +=    	'<A2_DATENT>'    + _sEntrada            +'</A2_DATENT>' 
        _sXML +=    	'<A2_DATSAI>'    + _sSaida              +'</A2_DATSAI>' 
        _sXML +=    	'<A2_SITUACAO>'  + _sSituacao           +'</A2_SITUACAO>'
        _sXML +=    '</Item>
        _sXML += '</SDT_AssociadoNovo>

        _oWSNaWeb := WSCadastroAssociadosWS():New()
		_oWSNaWeb:cEntrada := _sXML
		_oWSNaWeb:Execute()
		
		If cvaltochar(_oWSNaWeb:cSaida) == 'OK'
			u_log2('info',"Associado " + alltrim(M->A2_COD) + alltrim(M->A2_NOME) + " enviado com sucesso para NAWeb!")
		Else
			u_help("Algumas informações do associado " + alltrim(M->A2_NOME) + " podem não ter sido gravadas no cadastro NAWEB. Verifique!" + cvaltochar(_oWSNaWeb:cSaida))
			u_log2('erro',"Envio de associado para NAWeb com ERRO: " + cvaltochar(_oWSNaWeb:cSaida))
			_lContinua = .F.
		EndIf
    EndIf
Return

