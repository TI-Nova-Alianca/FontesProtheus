// Programa...: MT116TOK
// Autor......: Catia Cardoso
// Data.......: 20/11/2015
// Descricao..: P.E. 'Tudo OK' da tela de Conhecimentos de Fretes
//
// Historico de alteracoes:
// 03/05/2016 - Catia  - Validar campo F4_FRETE - so podem ser usados TES com F4_FRETE = 1(SIM) nas especies CTR e CTe
// 29/11/2016 - Robert - Layout de CT-e passa a ter nova tag <procCTe>
// 07/03/2017 - Catia -  Validações no XML de CTEs
//
// --------------------------------------------------------------------------
User Function MT116TOK()
	local _aAmbAnt   := U_SalvaAmb ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _lRet      := .T.
	//local _xFim      := chr(13)+chr(10)
	//local _sQuery    := ""
	//local _nRetQry   := 0
	local _nLinha	 := 0
	private _aMatriz := {}
	public _nRegZZX  := 0  // Deixar como 'public' para ser vista em outros pontos de entrada.
    Public _vVlrTot  := 0
   	
	u_logIni ()
	
	// valida TES de FRETE apenas para documento do tipo CTE ou CTR
	For _nLinha := 1 to Len(aCols)
		_xTES     := GDFieldGet( "D1_TES"     , _nLinha )
		_wfrete = fBuscaCpo ('SF4', 1, xfilial('SF4') + _xTES, "F4_FRETE")
		if _wfrete != '1'
			u_help ("Tipo de documento é FRETE, porém TES não é de FRETE. Verifique!")
			_lRet = .F.
		endif
	next		
	
	If _lRet
	  _vVlrTot  := MaFisRet(,"NF_TOTAL") 
	endif
	
	If _lRet .and. Alltrim(cEspecie) $ "CTE"
		
		if LEN(ALLTRIM(CNFISCAL))!=tamsx3("F1_DOC")[1]
			u_help ("Numero da nota fiscal deve ser totalmente preenchido.")
			_lRet = .F.
		endif
	
		if _lRet
			_lRet = _ValChvNFe ()
		endif			
		
		if _lRet 
			_lRet = _ValXML ()
		endif			
		
	endif
	
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
	u_log (procname (), 'retornando', _lRet)
	u_logFim ()
	
Return(_lRet)
// --------------------------------------------------------------------------
// Verifica preenchimento da chave NFe.
static function _ValChvNFe ()
	//local _i         := 0
	local _lRet      := .T.
	local _oSQL      := NIL
	//local _aUF       := {}
	local _sChvNFe   := iif (type ("aNFeDANFe") == "A", aNFeDANFe [13], "")
	local _sCNPJ     := ""
	local _nTamDoc   := tamsx3 ("F1_DOC")[1]
	local _sNumNF    := ""
	local _lDeveTer  := .F.
	//local _oNFe      := NIL
	//local _aRetSEFAZ := {}
	//local _lAutSEFAZ := .F.
	//local _sCGCEmit  := ''
	//local _sFilOri   := ''
	
	_lDeveTer = .T.
	
	if _lDeveTer .and. len (alltrim (_sChvNFe)) != 44
		u_help ("Chave da CT-e incompleta ou nao informada")
		_lRet = .F.
		return _lRet
	endif

	if _lDeveTer .and. substr (_sChvNFe, 3, 4) != substr (dtos (dDEmissao), 3, 4)
		u_help ("Ano e mes (AAMM) de emissao nao conferem com a chave da CT-e (" + substr (_sChvNFe, 3, 4) + ").")
		_lRet = .F.
		return _lRet
	endif
	
	if _lDeveTer 
		_sCNPJ = fBuscaCpo ("SA2", 1, xfilial ("SA2") + cA100For + cLoja, "A2_CGC")
		
		if _sCNPJ != substr (_sChvNFe, 7, 14)
			if aviso ("Inconsistencia chave x CNPJ", ;
		              "O CNPJ do cliente/fornecedor (" + _sCNPJ + ") nao confere com o que consta na chave da CT-e (" + substr (_sChvNFe, 7, 14) + "). Isso ocorre raramente, por exemplo em casos de NF avulsa. Confirma a digitacao?", ;
		              {"Confirma", "Cancela"}, ;
		              3, ;
		              "Verificacao chave /CT-e") == 2
				_lRet = .F.
				return _lRet
			endif
		endif
	endif
	
	if _lDeveTer .and. cvaltochar (val (substr (_sChvNFe, 23, 3))) != cvaltochar (val (cSerie))
		u_help ("Serie da NF nao confere com a chave da CTe (" + cvaltochar (val (substr (_sChvNFe, 23, 3))) + ")")
		_lRet = .F.
		return _lRet
	endif
	
	if _lDeveTer 
		_sNumNF = substr (_sChvNFe, 26 + (9 - _nTamDoc), _nTamDoc)
		if _sNumNF != cNFiscal
			u_help ("Numero do Documento nao confere com o que consta na chave da CTe (" + _sNumNF + ")")
			_lRet = .F.
			return _lRet
		endif
	endif
	
	if _lDeveTer
		// Verifica existencia da chave em qualquer outra filial.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT 'Filial:' + F1_FILIAL + ' Forn/loja:' + F1_FORNECE + '/' + F1_LOJA + ' NF/serie:' + F1_DOC + '/' + F1_SERIE"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SF1")
		_oSQL:_sQuery +=  " WHERE F1_CHVNFE  = '" + _sChvNFe + "'"
		_oSQL:_sQuery +=    " AND D_E_L_E_T_ = ''"

		if ! empty (_oSQL:RetQry ())
			u_help ("Chave CT-e ja existe no banco de dados. Verifique o CTe:" + chr (13) + chr (10) + _oSQL:_xRetQry)
			_lRet = .F.
			return _lRet
		endif
	endif
	
	u_logFim ()
return _lRet
// -----------------------------------------------------------
// Verifica dados no XML do fornecedor, caso esteja disponivel
static function _ValXML ()
	local _sXML      := ""
	local cError     := ""
	local cWarning   := ""
	local _oXml      := NIL
	local _oXmlOri   := NIL
	local _sQuery    := ""
	local _nRetQry   := 0
	local _lRet      := .T.
	local _lContinua := .T.
	local _aUF       := {}
    //local _IEFor     := ''     
    //local _lRet2     := .T.        
	u_logIni ()

	// Tenta buscar pela chave da NF-e, em qualquer filial.
	if _lRet .and. type ("aNFeDANFe") == "A" .and. ! empty (aNFeDANFe [13])
		_sQuery := ""
		_sQuery += " SELECT R_E_C_N_O_"
		_sQuery +=   " FROM " + RetSQLName ("ZZX") + " ZZX "
		_sQuery +=  " WHERE D_E_L_E_T_ != '*'"
		_sQuery +=    " AND ZZX_CHAVE  = '" + alltrim (aNFeDANFe [13]) + "'"
		_sQuery +=    " AND ZZX_LAYOUT IN ('CTe', 'NFe', 'enviNFe', 'procCTe', 'procNFe')"      

		u_log (_sQuery)
		_nRetQry = U_RetSQL (_sQuery)

		// se nao encontrar o XML, nao permite continuar obriga que exista o XML na ZZX para dar entrada no documento 
		if _nRetQry = 0
			u_help ("XML da NF-e/CT-e referenciada NAO ENCONTRADA na nossa base de dados. Não é permitido incluir NF-e/CT-e sem XML. Providencie o XML")
			_lRet = .F.
			_lContinua = .F.
		endif
		// Se encontrou pela chave, verifica os demais dados.
		if _nRetQry > 0
			_nRegZZX = _nRetQry
			zzx -> (dbgoto (_nRetQry))
			if _lContinua .and. zzx -> zzx_filial != xfilial ("ZZX")
				u_help ("XML da CT-e referenciada por esta chave destina-se `a filial '" + zzx -> zzx_filial + "'")
				_lRet = .F.
				_lContinua = .F.
			endif
			
			if _lContinua .and. (zzx -> zzx_clifor != ca100for .or. zzx -> zzx_loja != cLoja)
				u_help ("XML da CT-e referenciada por esta chave destina-se ao cliente/fornecedor '" + zzx -> zzx_clifor + '/' + zzx -> zzx_loja + "' e deve ser digitada com tipo '" + zzx -> zzx_tiponf + "'.")
				_lRet = .F.
				_lContinua = .F.
			endif
			
		// Se nao encontrou pela chave da CT-e, tenta buscar pelo numero da nota, fornecedor, etc.
		else
			_sQuery := ""
			_sQuery += " SELECT R_E_C_N_O_"
			_sQuery +=   " FROM " + RetSQLName ("ZZX") + " ZZX "
			_sQuery +=  " WHERE D_E_L_E_T_ != '*'"
			_sQuery +=    " AND ZZX_FILIAL  = '" + xfilial ("ZZX") + "'"
			_sQuery +=    " AND ZZX_CLIFOR  = '" + ca100For + "'"
			_sQuery +=    " AND ZZX_LOJA    = '" + cLoja   + "'"
			_sQuery +=    " AND ZZX_DOC    like '%" + cNFiscal + "'"  // Usa 'like' para casos onde o campo F1_DOC estiver menor que o ZZX_DOC
			_sQuery +=    " AND ZZX_SERIE   = '" + cSerie  + "'"
			_sQuery +=    " AND ZZX_TIPONF  = '" + cTipo + "'"
			_nRetQry = U_RetSQL (_sQuery)
		endif
	endif

	if _nRetQry > 0 .and. _lContinua
		_nRegZZX = _nRetQry
		zzx -> (dbgoto (_nRetQry))

		// Cria objeto XML para leitura dos dados.
		_sXML = MSMM (zzx -> zzx_CodMem,,,,3)
		if empty (_sXML)
			u_help ("Nao foi possivel recuperar o XML desta nota. Verifique tabela ZZX.")
			_lRet = .F.
			_lContinua = .F.
		endif
		
		if _lContinua
			_oXmlOri := XmlParser(_sXML, "_", @cError, @cWarning)
			If !Empty (cError)
				u_help (cError)
				_lRet = .F.
				_lContinua = .F.
			EndIf
			If !Empty (cWarning)
				u_help (cWarning)
				_lRet = .F.
				_lContinua = .F.
			EndIf
			If XMLError () != 0
				u_help ("Erro na geracao do objeto XML. As validacoes do XML nao poderao ser feitas.")
				_lRet = .F.
				_lContinua = .F.
			endif
		endif
	else
		_lContinua = .F.
	endif

	// Verifica a especie digitada com o Layout do arquivo (tipo de documento XML).
	if _lContinua .and. upper (alltrim (zzx -> zzx_layout)) == "PROCCTE/CTE" .and. alltrim (cEspecie) != "CTE"
		u_help ("Layout do XML referente a este documento ('" + alltrim (zzx -> zzx_layout) + "') exige que seja usada especie 'CTE'.")
		_lRet = .F.
		_lContinua = .F.
	endif

	// Verifica o Layout (tipo de documento XML) e separa a parte do XML que interessa.
	if _lContinua
		
		do case	
			case upper (alltrim (zzx -> zzx_layout)) == "PROCCTE" //.and. valtype (XmlChildEx (_oXMLOri, '_cteProc')) == "O"
				_oXml = _oXmlOri:_cteProc:_CTe:_infCte
			//case upper (alltrim (zzx -> zzx_layout)) == "PROCCTE" .and. valtype (XmlChildEx (_oXMLOri, '_procCTe')) == "O"
				//_oXml = _oXmlOri:_procCTe:_CTe:_infCte
			case upper (alltrim (zzx -> zzx_layout)) == "CTE"
				_oXml = _oXmlOri:_CTe:_infCte
			otherwise
				u_help ("Layout de XML desconhecido na rotina " + procname () + ". As validacoes do XML nao poderao ser feitas.")
				_lContinua = .F.
				_lRet = .F.
		endcase
	endif

	if _lContinua .and. valtype (_oXml) == NIL
		u_log ("Nao foi possivel extrair dados suficientes do XML na rotina " + procname () + ". As validacoes do XML nao poderao ser feitas.")
		_lContinua = .F.
		_lRet = .F.
	endif
	
	// valida total da nota 
    if _lContinua .and. _vVlrTot != val (_oXml:_vPrest:_vTPrest:TEXT)
   		u_help ("Total do CTE: no XML consta " + cvaltochar (val (_oXml:_vPrest:_vTPrest:TEXT)) + ". Verifique!")
    	_lContinua := .F.
    	_lRet = .F.		
   	endif		   			
    
	if _lContinua
		aadd (_aUF, {"RO","11"})
		aadd (_aUF, {"AC","12"})
		aadd (_aUF, {"AM","13"})
		aadd (_aUF, {"RR","14"})
		aadd (_aUF, {"PA","15"})
		aadd (_aUF, {"AP","16"})
		aadd (_aUF, {"TO","17"})
		aadd (_aUF, {"MA","21"})
		aadd (_aUF, {"PI","22"})
		aadd (_aUF, {"CE","23"})
		aadd (_aUF, {"RN","24"})
		aadd (_aUF, {"PB","25"})
		aadd (_aUF, {"PE","26"})
		aadd (_aUF, {"AL","27"})
		aadd (_aUF, {"MG","31"})
		aadd (_aUF, {"ES","32"})
		aadd (_aUF, {"RJ","33"})
		aadd (_aUF, {"SP","35"})
		aadd (_aUF, {"PR","41"})
		aadd (_aUF, {"SC","42"})
		aadd (_aUF, {"RS","43"})
		aadd (_aUF, {"MS","50"})
		aadd (_aUF, {"MT","51"})
		aadd (_aUF, {"GO","52"})
		aadd (_aUF, {"DF","53"})
		aadd (_aUF, {"SE","28"})
		aadd (_aUF, {"BA","29"})
		aadd (_aUF, {"EX","99"})
	endif
		
	if ! GetMv("VA_VALXML")
       if _lContinua .and. ! _lRet
	      if aviso ("Inconsistencias com o XML", ;
		            "Foram encontradas inconsistencias entre os dados digitados e o XML enviado pelo emitente deste documento. Deseja inclui-lo mesmo assim?", ;
		           {"Incluir", "Corrigir"}, ;
		             3, ;
		            "Inconsistencias com o XML") == 1
			 _lRet = .T.
		  endif
	   endif
    else 
       if _lContinua .and. ! _lRet
  	      u_help ("Parametro que nao permite inclusao de documento com XML com inconsistencias esta ativo. Corrija os problemas para prosseguir.")
		  _lContinua = .F.    
  	      _lRet = .F. 
  	   endif   
    endif
	u_logFim ()
return _lRet
