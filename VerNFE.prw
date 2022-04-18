// Programa.:  VerNFe
// Autor....:  Robert Koch
// Data.....:  18/06/2008
// Descricao:  Verificacoes para envio de NF eletronica.
//             A intencao eh detectar alguns problemas antes do envio para a SEFAZ.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Validacao
// #Descricao         #Validacoes diversas de campos de cadastro que costumar dar problema para autorizar notas na SEFAZ.
// #PalavasChave      #auxiliar #validacao
// #TabelasPrincipais #SA1 #SA2 #SB1 #SF4
// #Modulos           #FAT

// Historico de alteracoes:
// 15/07/2008 - Robert - Criada verificacao do SA2.
// 22/07/2009 - Robert - Passa a usar a funcao U_Help para as mensagens.
// 19/08/2009 - Robert - Criado tratamento para campo A1_VAMDANF
// 13/10/2010 - Robert - Criado tratamento para campo B1_POSIPI.
// 15/03/2011 - Robert - Validacao dos e-mails passa a ser feita pela funcao U_MailOK ().
// 17/03/2011 - Robert - Melhorada validacao do endereco de clientes e fornecedores.
// 24/03/2011 - Robert - Melhorada verificacao do telefone, para XML versao 2.0.
// 27/04/2011 - Robert - Criada verificacao de pais.
// 12/05/2011 - Robert - Criada verificacao de transportadora (por enquanto somente e-mail).
// 24/10/2011 - Robert - Passa a verificar o campo B1_VAEANUN.
// 30/04/2013 - Robert - Verifica se trata-se de cli/forn. do exterior para testes de inscr.est.
//                     - Incluido teste de preenchimento do CEP.
// 31/07/2015 - Robert - Verifica existencia do caracter & em alguns campos do cadastro.
// 04/12/2015 - Catia  - Validação da inscricao estadual nos clientes.
// 13/01/2016 - Robert - Permite inscricao vazia para consumidor nao final quando o mesmo for MEI.
// 22/11/2018 - Catia  - Validacao inscricao estadual
// 27/11/2018 - Catia  - Tiradas as validacoes da inscricao estadual do cliente - Katia vai passar nova regra
// 26/07/2019 - Robert - Desabilitadas verificacoes de codigo EAN (vamos usar campos padrao do sistema) - GLPI 6335.
// 06/05/2020 - Robert - Desabilitado envio de e-mail para liane.lenzi
// 19/10/2020 - Robert - Desabilitada validacao de endereco quando cliente do exterior.
//                     - Incluidas tags para catalogo de fontes.
// 18/04/2022 - Claudia - Incluida exceção no endereço do cliente '44807036000157'.
//
// --------------------------------------------------------------------------
user function VerNFe (_sOnde)
	local _lRet      := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _nLinCols  := 0
	private _sMsg    := ""
	
	do case
		case _sOnde == "PV"  // Pedido de venda
			if m->c5_tipo $ "DB"
				_VerSA2 (m->c5_cliente, m->c5_lojacli)
			else
				_VerSA1 (m->c5_cliente, m->c5_lojacli)
			endif
			for _nLinCols = 1 to len (aCols)
				if ! GDDeleted (_nLinCols)
					_VerSB1 (GDFieldGet ("C6_PRODUTO", _nLinCols))
					_VerSF4 (GDFieldGet ("C6_TES", _nLinCols))
				endif
			next
			if ! empty (m->c5_transp)
				_VerSA4 (m->c5_transp)
			endif
		case _sOnde == "NFS"  // NF saida
			if sf2 -> f2_tipo $ "BD"
				_VerSA2 (sf2 -> f2_cliente, sf2 -> f2_loja)
			else
				_VerSA1 (sf2 -> f2_cliente, sf2 -> f2_loja)
			endif
			_sChaveSD2 := SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA
			sd2 -> (DbSetOrder(3))
			sd2 -> (DbSeek(xFilial("SD2")+_sChaveSD2))
			Do While !sd2 -> (Eof()) .And. xFilial("SD2")==SD2->D2_FILIAL .And. _sChaveSD2 == SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA
				_VerSB1 (sd2 -> d2_cod)
				_VerSF4 (sd2 -> d2_tes)
				_VerSD2 ()
				sd2 -> (DbSkip())
			Enddo
	endcase
	
	if ! empty (_sMsg)
		_lRet = .F.
		u_help ("Verificacao para NF-e:" + chr (13) + chr (10) + _sMsg, procname (), .t.)
	endif
	
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return _lRet
//
// --------------------------------------------------------------------------
// Verifica cadastro do cliente
static function _VerSA1 (_sCliente, _sLoja)
	local _sEMail := ""

	sa1 -> (dbsetorder (1))

	if sa1 -> (dbseek (xfilial ("SA1") + _sCliente + _sLoja, .F.))
		if empty (sa1 -> a1_bairro) .or. alltrim (sa1 -> a1_bairro) == "."
			_sMsg += "Bairro nao informado ou invalido no cliente. (CNPJ: " + sa1 -> a1_cgc + ")" + chr (13) + chr (10)
		endif
		if sa1 -> a1_est != "EX"
			if empty (sa1 -> a1_cep) .or. alltrim (sa1 -> a1_cep) == "."
				_sMsg += "CEP nao informado ou invalido no cliente. (CNPJ: " + sa1 -> a1_cgc + ")" + chr (13) + chr (10)
			endif
		else
			if empty (sa1 -> a1_cep) .or. alltrim (sa1 -> a1_cep) == "."
				_sMsg += "CEP nao deve ser informado para clientes do exterior." + chr (13) + chr (10)
			endif
		endif
		_sEMail = iif (empty (sa1 -> a1_vamdanf), SA1->A1_EMAIL, sa1 -> a1_vamdanf)
		if empty (_sEMail) .or. ! U_MailOk (_sEMail)
			_sMsg += "E-Mail '" + _sEMail + "' nao informado ou invalido no cliente. (CNPJ: " + sa1 -> a1_cgc + ")" + chr (13) + chr (10)
		endif
		if empty (sa1 -> a1_cod_mun)
			_sMsg += "Codigo de municipio nao informado ou invalido no cliente. (CNPJ: " + sa1 -> a1_cgc + ")" + chr (13) + chr (10)
		endif
		if sa1 -> a1_est != "EX"
			if empty (sa1 -> a1_end) .or. alltrim (sa1 -> a1_end) == "." .or. len (StrTokArr (alltrim (sa1 -> a1_end), ' ')) <= 1 .or. IsDigit (left (sa1 -> a1_end, 1)) .and. !alltrim(sa1 -> a1_cgc) $ GETMV("VA_VERNFE") 
				_sMsg += "Endereco nao informado ou invalido no cliente. (CNPJ: " + sa1 -> a1_cgc + "). Estaria faltando um espaco entre o nome da rua e o numero da casa?" + chr (13) + chr (10)
			endif
		endif
		if empty (sa1 -> a1_est)
			_sMsg += "Estado (UF) nao informado ou invalido no cliente. (CNPJ: " + sa1 -> a1_cgc + ")" + chr (13) + chr (10)
		endif
		if sa1 -> a1_est == "EX"
			if !empty (sa1 -> a1_inscr)
				_sMsg += "Inscricao estadual NAO DEVE ser informada para cliente do exterior. (Cod.cli.: " + sa1 -> a1_cod + ")" + chr (13) + chr (10)
			endif
		endif	
		if empty (sa1 -> a1_pais)
			_sMsg += "Codigo de pais nao informado ou invalido no cliente. (CNPJ: " + sa1 -> a1_cgc + ")" + chr (13) + chr (10)
		endif
		if len (alltrim (sa1 -> a1_cep)) < 8
			_sMsg += "CEP nao informado ou incompleto no cliente. (CNPJ: " + sa1 -> a1_cgc + ")" + chr (13) + chr (10)
		endif
		_VerTel (sa1 -> a1_tel)
		if "&" $ sa1 -> a1_nome .or. "&" $ sa1 -> a1_bairro .or. "&" $ sa1 -> a1_end
			_sMsg += "Cadastro de clientes: O caracter '&' nao deve ser usado. Verifique campos como NOME, BAIRRO, ENDERECO, etc. (CNPJ: " + sa1 -> a1_cgc + ")" + chr (13) + chr (10)
		endif
	endif
return
//
// --------------------------------------------------------------------------
// Verifica cadastro do fornecedor
static function _VerSA2 (_sCliente, _sLoja)
	local _sEMail := ""

	sa2 -> (dbsetorder (1))

	if sa2 -> (dbseek (xfilial ("sa2") + _sCliente + _sLoja, .F.))
		if empty (sa2 -> a2_bairro) .or. alltrim (sa2 -> a2_bairro) == "."
			_sMsg += "Bairro nao informado ou invalido no fornecedor." + chr (13) + chr (10)
		endif
		if empty (sa2 -> a2_cep) .or. alltrim (sa2 -> a2_cep) == "."
			_sMsg += "CEP nao informado ou invalido no fornecedor." + chr (13) + chr (10)
		endif
		_sEMail = iif (empty (sa2 -> a2_vamdanf), SA2->A2_EMAIL, sa2 -> a2_vamdanf)
		if empty (_sEMail) .or. ! U_MailOk (_sEMail)
			_sMsg += "E-Mail '" + _sEMail + "' nao informado ou invalido no cliente. (CNPJ: " + sa2 -> a2_cgc + ")" + chr (13) + chr (10)
		endif
		if empty (sa2 -> a2_cod_mun)
			_sMsg += "Codigo de municipio nao informado ou invalido no fornecedor." + chr (13) + chr (10)
		endif
		if empty (sa2 -> a2_end) .or. alltrim (sa2 -> a2_end) == "." .or. len (StrTokArr (alltrim (sa2 -> a2_end), ' ')) <= 1 .or. IsDigit (left (sa2 -> a2_end, 1))
			_sMsg += "Endereco nao informado ou invalido no fornecedor. Estaria faltando um espaco entre o nome da rua e o numero da casa?" + chr (13) + chr (10)
		endif
		if empty (sa2 -> a2_est)
			_sMsg += "Estado (UF) nao informado ou invalido no fornecedor." + chr (13) + chr (10)
		endif
		if sa2 -> a2_est == "EX"
			if !empty (sa2 -> a2_inscr)
				_sMsg += "Inscricao estadual NAO DEVE ser informada para fornecedor do exterior. (Cod.forn.: " + sa2 -> a2_cod + ")" + chr (13) + chr (10)
			endif
		else
			if empty (sa2 -> a2_inscr)  .and. sa2 -> a2_tipo != 'F'
				_sMsg += "Inscricao estadual nao informada ou invalida no fornecedor." + chr (13) + chr (10)
			endif
		endif
		if empty (sa2 -> a2_pais)
			_sMsg += "Codigo de pais nao informado ou invalido no fornecedor. (CNPJ: " + sa2 -> a2_cgc + ")" + chr (13) + chr (10)
		endif
		if len (alltrim (sa2 -> a2_cep)) < 8
			_sMsg += "CEP nao informado ou incompleto no fornecedor. (CNPJ: " + sa2 -> a2_cgc + ")" + chr (13) + chr (10)
		endif
		_VerTel (sa2 -> a2_tel)
		if "&" $ sa2 -> a2_nome .or. "&" $ sa2 -> a2_bairro .or. "&" $ sa2 -> a2_end
			_sMsg += "Cadastro de clientes: O caracter '&' nao deve ser usado. Verifique campos como NOME, BAIRRO, ENDERECO, etc. (CNPJ: " + sa2 -> a2_cgc + ")" + chr (13) + chr (10)
		endif
	endif
return
//
// --------------------------------------------------------------------------
// Verifica cadastro da transportadora.
static function _VerSA4 (_sTransp)

	sa4 -> (dbsetorder (1))

	if sa4 -> (dbseek (xfilial ("SA4") + _sTransp, .F.))
		if "&" $ sa4 -> a4_nome .or. "&" $ sa4 -> a4_bairro .or. "&" $ sa4 -> a4_end
			_sMsg += "Cadastro de transportadoras: O caracter '&' nao deve ser usado. Verifique campos como NOME, BAIRRO, ENDERECO, etc." + chr (13) + chr (10)
		endif
	endif
return
//
// --------------------------------------------------------------------------
// Verifica telefone
static function _VerTel (_sTel)
	local _i := 0

	_sTel = rtrim (_sTel)

	if len (_sTel) < 6 .or. len (_sTel) > 14
		_sMsg += "Telefone invalido: '" + _sTel + "'. O mesmo deve ter entre 6 e 14 digitos" + chr (13) + chr (10)
	endif
	for _i = 1 to len (_sTel)
		if ! IsDigit (substr (_sTel, _i, 1))
			_sMsg += "Telefone invalido: '" + _sTel + "'. O mesmo deve conter apenas numeros (remova pontos, tracos e espacos em branco no inicio ou no meio)." + chr (13) + chr (10)
			exit
		endif
	next
return
//
// --------------------------------------------------------------------------
// Verifica produto
static function _VerSB1 (_sProduto)
	sb1 -> (dbsetorder (1))
	if sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
		if empty (sb1 -> b1_origem)
			_sMsg += "Origem nao informada no produto " + sb1 -> b1_cod + chr (13) + chr (10)
		endif
		if empty (sb1 -> b1_posipi)
			_sMsg += "Posicao de IPI nao informada no produto " + sb1 -> b1_cod + chr (13) + chr (10)
		endif
	endif
return
//
// --------------------------------------------------------------------------
// Verifica TES
static function _VerSF4 (_sTES)

	sf4 -> (dbsetorder (1))

	if sf4 -> (dbseek (xfilial ("SF4") + _sTES, .F.))
		if empty (sf4 -> f4_sittrib)
			_sMsg += "Situacao trib. ICMS nao informada no TES " + sf4 -> f4_codigo + chr (13) + chr (10)
		endif
		if empty (sf4 -> f4_CTIPI)
			_sMsg += "Cod.Trib.IPI nao informado no TES " + sf4 -> f4_codigo + chr (13) + chr (10)
		endif
		if empty (sf4 -> f4_CSTPIS)
			_sMsg += "Sit.Trib.PIS nao informada no TES " + sf4 -> f4_codigo + chr (13) + chr (10)
		endif
		if empty (sf4 -> f4_CSTCOF)
			_sMsg += "Sit.Trib.COF nao informada no TES " + sf4 -> f4_codigo + chr (13) + chr (10)
		endif
	endif
return
//
// --------------------------------------------------------------------------
// Verifica Itens da nota
static function _VerSD2 ()
	if len (alltrim (sd2 -> d2_clasfis)) < 3
		_sMsg += "Situacao trib. ICMS ficou incompleta para o produto " + sd2 -> d2_cod + chr (13) + chr (10)
	endif
return
