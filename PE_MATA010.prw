// Programa...: ITEM
// Autor......: Andre Alves
// Data.......: 06/05/2019
// Descricao..: Ponto entrada na tela cadastro de Produtos.

// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto entrada na tela cadastro de Produtos.
// #PalavasChave      #ponto_de_entrada #cadastro_de_produto  #cadastro_de_produto_MVC
// #TabelasPrincipais #SB1 
// #Modulos 		  #todos

// Historico de alteracoes:
// 16/08/2019 - Robert  - Campo B1_VADUNCX substituido pelo campo B1_CODBAR.
// 20/08/2019 - Robert  - Ajustes para opcao de nao copiar determinados campos e gravacao de eventos.
// 28/08/2019 - Cláudia - Incluida validação para não permitir salvar o produto quando fator de conversão 
//                        informado no complemento e unidade DIPI não informada.
// 29/08/2019 - Andre   - Removido validação do campo CODEAN. 
// 02/09/2019 - Andre   - Campos de RASTRO e LOCALIZACAO removidos do NÃO COPIA.
// 06/03/2020 - Claudia - Ajustada a leitura do SX3/SXA conforme solicitação da R25
// 17/03/2020 - Andre   - Inserida função para não copiar campos do cadastro de PRODUTO X FORNECEDOR (SA5)
// 22/06/2020 - Robert  - Somente envia atualizacao para o Mercanet quando for item do tipo PA (GLPI 8090).
//                      - Antes de permitir a exclusao, verifica se o item existe no Mercanet, FullWMS e NaWeb.
//                      - Eliminados logs desnecessarios.
// 20/01/2021 - Cláudia - GLPI:8921 - Incluida verificação de caracteres especiais.
// 12/02/2021 - Robert  - Incluidas chamadas da funcao U_PerfMon para testes de monitoramento de 
//                        performance (GLPI 9409)
// 02/03/2021 - Sandra  - Comentariado Altera campos do modelo de dados adicionais (tabela SA5) 
//                        foi retirada do parametro mv_cadprod GLPI 8987
// 22/06/2021 - Claudia - Carregado o campo B1_VARMAAL com 000000000 na cópia de produto. GLPI: 10276
// 04/10/2021 - Claudia - Incluida validação de usuario manutenção. GLPI: 10968
// 05/10/2021 - CLaudia - Incluida a validação do docigo GNRE para PA e MR. GLPI: 11017
// 08/10/2021 - Claudia - Incluida a validação para itens MC, conforme GLPI: 10845
// 10/06/2022 - Robert  - Validacao codigo final C x tipo MC: ignora grupo 2007 (contra-rotulos) - GLPI 12190
// 19/10/2022 - Robert  - Valida duplicidade do B1_CODBAR no 'tudo ok' - GLPI 12726
//

//---------------------------------------------------------------------------------------------------------------
#Include "Protheus.ch" 
#Include "TOTVS.ch"
#Include "FWMVCDEF.ch"

User Function ITEM() 
	local oObj  := NIL
	local nOper := 0
	local _xRet := NIL

	// Sugestao para obter o conteudo de ParamIXB: habilitar o parametro IXBLOG=LOGRUN no appserver.ini e consultar o log gerado na pasta \ixbpad
	if paramixb <> NIL

		// Devido ao fato deste P.E. ser chamado mais de uma vez para cada campo da tela, optei por tratar somente os casos necessarios
		// e deixar de usar um programa mais estruturado.
		if paramixb [2] == "MODELVLDACTIVE"  // Valida a abertura da tela (executa apenas uma vez na abertura da tela)
		//	u_log2 ('debug', 'Iniciando modelo ' + paramixb [2])
			U_PerfMon ('I', 'AbrirEdicaoMATA010')  // Deixa variavel pronta para posterior medicao de tempos de execucao
			_xRet = .T.
			oObj := paramixb [1]
			nOper := oObj:nOperation
			If nOper == 5  // Exclusao
				_xRet = _ValidExcl ()
			EndIf
			if _xRet
				// Cria lista de campos que o usuario pode alterar
				public _sCposAlt := ""  // Deixar com PUBLIC para ser visivel no X3_WHEN
				_VerAcesso ()
			endif

		elseif paramixb [2] == 'BUTTONBAR'  // Chamado uma vez apos montar os campos na tela, antes de montar a barra de botoes.
		//	u_log2 ('debug', 'Iniciando modelo ' + paramixb [2])
			U_PerfMon ('F', 'AbrirEdicaoMATA010')  // Finaliza medicao de tempos de execucao
			oObj := paramixb [1]
			if oObj:IsCopy ()
				// Limpa campos que nao devem ser copiados.
				_NaoCopia()
			endif
			_xRet := {}  // Nao quero criar nenhum botao

		elseif paramixb [2] == "MODELPOS"  //Validação 'tudo OK' ao clicar no Botão Confirmar
		//	u_log2 ('debug', 'Iniciando modelo ' + paramixb [2])
			_xRet := _A010TOk () 

		elseif paramixb [2] == "MODELCOMMITNTTS"  //Commit das operações (após a gravação)
		//	u_log2 ('debug', 'Iniciando modelo ' + paramixb [2])
			oObj := paramixb [1]
			nOper := oObj:nOperation
			if nOper == 3  // Inclusao
				// Envia atualizacao para o Mercanet
				if m->b1_tipo == 'PA'  // A principio nao temos intencao de vender outros tipos de itens.
					U_AtuMerc ('SB1', sb1 -> (recno ()))
				endif
			elseif nOper == 4  // ALteracao
				_MT010Alt ()
			endif
			_xRet = NIL
			U_PerfMon ('F', 'GravarMATA010')

		elseif paramixb [2] == 'FORMPRE'  // Chamado a cada campo que tiver validacao de usuario.
			_xRet = NIL
		ElseIf paramixb [2] == "FORMPOS"  // Pós configurações do Formulário
		//	u_log2 ('debug', 'Iniciando modelo ' + paramixb [2])
			_xRet = NIL			
		ElseIf paramixb [2] == "MODELCANCEL"  // Quando o usuario cancela a edicao (tenta sair sem salvar)
			_xRet = .T.
		ElseIf paramixb [2] == "FORMCOMMITTTSPOS"  //Pós validações do Commit
		//	u_log2 ('debug', 'Iniciando modelo ' + paramixb [2])
			_xRet = NIL
		ElseIf paramixb [2] == "MODELCOMMITTTS"  //Commit das operações (antes da gravação)
		//	u_log2 ('debug', 'Iniciando modelo ' + paramixb [2])
			_xRet = NIL
			// Deixa variavel pronta para posterior medicao de tempos de execucao
			U_PerfMon ('I', 'GravarMATA010')
		ElseIf paramixb [2] == "FORMCOMMITTTSPRE"  //Pré validações do Commit
		//	u_log2 ('debug', 'Iniciando modelo ' + paramixb [2])
			_xRet = NIL
		EndIf 
	endif
Return _xRet
//
// --------------------------------------------------------------------------
// Limpa campos que nao devem ser copiados.
static function _NaoCopia ()
	Local oObj := paramixb [1]
		

	// Altera campos do modelo principal (tabela SB1)
	oModelB1 := oObj:GetModel("SB1MASTER")
	if ! U_msgnoyes ("Deseja copiar os dados de impostos?")
		oModelB1:LoadValue("B1_VALIPI",'')
		oModelB1:LoadValue("B1_VAADEIP",'')
		oModelB1:LoadValue("B1_VASTSP",'')
		oModelB1:LoadValue("B1_VLR_IPI",'')
		oModelB1:LoadValue("B1_IPI",'')
		oModelB1:LoadValue("B1_TAB_IPI",'')
	endif
	oModelB1:LoadValue("B1_CODBAR", '')
	oModelB1:LoadValue("B1_CODPAI", '')
	oModelB1:LoadValue("B1_VACUSEM", '')
	oModelB1:LoadValue("B1_OPERPAD",'')
	oModelB1:LoadValue("B1_CUSTD",'')
	oModelB1:LoadValue("B1_PRV1",'')
	oModelB1:LoadValue("B1_UPRC",'')
	oModelB1:LoadValue("B1_DATREF",'')
	oModelB1:LoadValue("B1_UCOM",'')
	oModelB1:LoadValue("B1_UREV",'')
	oModelB1:LoadValue("B1_DTREFP1",'')
	oModelB1:LoadValue("B1_CONINI",'')
	oModelB1:LoadValue("B1_REVATU",'')
	oModelB1:LoadValue("B1_UCALSTD",'')
	oModelB1:LoadValue("B1_CODBAR",'')
	oModelB1:LoadValue("B1_VARMAAL",'00000000000000') // CARREGAR PADRÃO
	oModelB1:LoadValue("B1_VAFULLW",'')
	// Atualiza campos na tela do usuario
	oView := FwViewActive()
	oView:Refresh ()


	// Altera campos do modelo de dados adicionais (tabela SB5)
	oModelB5 := oObj:GetModel("SB5DETAIL")
	oModelB5:LoadValue("B5_2CODBAR",'')
	oModelB5:LoadValue("B5_VACSD01",'')
	oModelB5:LoadValue("B5_VACSD03",'')
	oModelB5:LoadValue("B5_VACSD05",'')
	oModelB5:LoadValue("B5_VACSD06",'')
	oModelB5:LoadValue("B5_VACSD07",'')
	oModelB5:LoadValue("B5_VACSD08",'')
	oModelB5:LoadValue("B5_VACSD09",'')
	oModelB5:LoadValue("B5_VACSD10",'')
	oModelB5:LoadValue("B5_VACSD11",'')
	oModelB5:LoadValue("B5_VACSD12",'')
	oModelB5:LoadValue("B5_VACSD13",'')
	// Atualiza campos na tela do usuario
	oView := FwViewActive()
	oView:Refresh ()

	// Altera campos do modelo de dados adicionais (tabela SA5)
	//oModelA5 := oObj:GetModel("MdGridSA5"):DelAllLine()

	// Atualiza campos na tela do usuario
	//oView := FwViewActive()
	//oView:Refresh ()
	
return
//
// --------------------------------------------------------------------------
// Validação 'tudo OK' ao clicar no Botão Confirmar
static function _A010TOk ()
	local _lRet      := .T.
	local _lEhUva    := .F.
	local _aAreaSB1  := {}
	local _oEvento   := NIL
	local _oSQL      := NIL
//	static _lJahPassou := .F.

//	if ! _lJahPassou
		if m->b1_tipo $ "PA/PI/VD"
			if m->b1_litros == 0 .and. ! m->b1_grupo $ '0603/0706'
				u_help ("Campo '" + alltrim (RetTitle ("B1_LITROS")) + "' deve ser informado para este tipo de produto.")
				_lRet = .F.
			endif
		else
			if ! empty (m->b1_locprod)
				u_help ("Campo '" + alltrim (RetTitle ("B1_LOCPROD")) + "' nao deve ser informado para este tipo de produto.")
				_lRet = .F.
			endif
		endif
		
		if ! m->b1_tipo $ "PA/MR"
			if alltrim (m->b1_tipo) != alltrim (m->b1_grtrib)
				u_help ("Campo '" + alltrim (RetTitle ("B1_TIPO")) + "' nao pode ser diferente de '" + alltrim (RetTitle ("B1_GRTRIB")) + "'.")
				_lRet = .F.
			endif
		endif
		
		// Verifica se eh uva (materia prima)
		if m->b1_tipo == "MP" .and. ! alltrim (m->b1_cod) $ "9989/2852" ;  // Lenha
			.and. (! empty (m->b1_varuva) ;
			.or. m->b1_locpad == "50")
			_lEhUva = .T.
		else
			_lEhUva = .F.
		endif
		
		if _lRet .and. _lEhUva
//			if ! empty (m->b1_codbar) //b1_vaDUNCx)
//				u_help ("Este item e´ UVA: O(s) seguinte(s) campo(s) NAO deve(m) ser informado(s) ou deve(m) ficar como generico(s): " + chr (13) + chr (10) + ;
//						alltrim (RetTitle ("B1_CODBAR")))  //VADUNCX")))
//				_lRet = .F.
//			endif
			if 	empty (m->b1_VarUva)
				u_help ("Este item e´ UVA: Os seguintes campos devem ser informados: " + chr (13) + chr (10) + ;
						alltrim (RetTitle ("B1_VARUVA")))
				_lRet = .F.
			endif
			if _lRet .and. ! m->b1_vacor $ "BRT"
				u_help ("Este item e´ UVA: Campo '" + alltrim (RetTitle ("B1_VACOR")) + "' deve ser informado para este tipo de produto.")
				_lRet = .F.
			endif
		endif

		if _lRet
			if m->b1_vafullw == 'S'
				if empty (m->b1_codbar)  //vaduncx)
					u_help ("Produtos controlados pelo FullWMS (campo '" + alltrim (RetTitle ("B1_VAFULLW")) + "') devem ter codigo de barras da caixa informado, mesmo que seja ficticio, informado no campo '" + alltrim (RetTitle ("B1_CODBAR")) + "'.")  // VADUNCX")) + "'.")
					_lRet = .F.
				endif
				if ! m->b1_um $ 'GF/CX/UN/FD'
					u_help ("Unidade de medida invalida para produtos controlados pelo FullWMS (campo '" + alltrim (RetTitle ("B1_VAFULLW")) + "').")
					_lRet = .F.
				endif
			endif
		endif

		if _lRet
			if m->b1_vlr_ipi != 0 .and. m->b1_ipi != 0
				u_help ("IPI deve ser informado somente por aliquota (campo '" + alltrim (RetTitle ("B1_IPI")) + "') ou por valor absoluto (campo '" + alltrim (RetTitle ("B1_VLR_IPI")) + "'), mas nao ambos.")
				_lRet = .F.
			endif
		endif

		if _lRet .and. ! empty (m->b1_codbar)
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT RTRIM (STRING_AGG (RTRIM (B1_COD) + '-' + RTRIM (B1_DESC), '; '))"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SB1") + " SB1 "
			_oSQL:_sQuery +=  " WHERE SB1.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			_oSQL:_sQuery +=    " AND SB1.B1_CODBAR  = '" + m->b1_codbar + "'"
			_oSQL:_sQuery +=    " AND SB1.B1_COD    != '" + m->b1_cod + "'"
			_oSQL:Log ()
			_sMsg = _oSQL:RetQry (1, .f.)
			if ! empty (_sMsg)
				U_Help ("Codigo de barras ja informado para o(s) seguinte(s) produto (s): " + _sMsg,, .t.)
				_lRet = .F.
			endif
		endif

		if _lRet .and. paramixb [1]:nOperation == 4  // Se estou alterando um cadastro, gero evento de alteracao.
			_aAreaSB1 := sb1 -> (getarea ())
			sb1 -> (dbsetorder (1))
			if sb1 -> (dbseek (xfilial ("SB1") + m->b1_cod, .F.))  // SB1 chega aqui em BOF (vai entender...)
				_oEvento := ClsEvent():new ()
				_oEvento:AltCadast ("SB1", m->b1_cod, sb1 -> (recno ()), '', .F.)
			else
				u_log2 ('erro', "Nao encontrei o SB1 do produto '" + m->b1_cod + "' para gerar o evento.")
			endif
			restarea (_aAreaSB1)
		endif

//		// Marca flag como 'jah passou por este local' por que o P.E. eh chamado duas vezes.
//		_lJahPassou = .T.

//	endif
	
	if m->b5_convdip != 0 .and. empty(m->b5_umdipi)
		u_help ("Fator de conversão informado no complemento. A unidade DIPI deve ser informada no registro!")
		_lRet = .F.
	endif 

	// valida caracter espacial
	If paramixb [1]:nOperation == 3 // inclusão
		_lRet = CaracEsp(m->b1_cod)
	EndIf
	
	if _lRet
		if m->b1_tipo == 'PA' .or. m->b1_tipo == 'MR' 
			if empty(m->b5_codgnre)
				u_help("Para produtos PA e/ou MR, é obrigatório inserir o Cod.Prod (Código GNRE)")
				_lRet := .F.
			endif 
		endif
	endif

	if _lRet
		if m->b1_tipo != 'MM' .and. m->b1_tipo != 'MC'
			_oSQL:= ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT "
			_oSQL:_sQuery += " 		SETOR "
			_oSQL:_sQuery += " FROM VA_FUNCIONARIO_SETOR('" + __CUSERID + "')"
			_sDados := aclone(_oSQL:Qry2Array ())

			if Len(_sDados)> 0
				if alltrim(_sDados[1, 1]) == '2008'
					u_help("Usuário sem permissão para alterar produto tipo " + m->b1_tipo)
					_lRet := .F.
				endif
			endif
		endif
	endif

	if _lRet 
		_sCaracter := SUBSTR(alltrim(m->b1_cod), -1, 1) 

		If _sCaracter == 'C' .and. m->b1_tipo <> 'MC'
			if m->b1_grupo != '2007'  // contra-rotulos
				u_help("Produto com final C deve ser obrigatoriamente do tipo MC.")
				_lRet := .F.
			endif
		else
			if _sCaracter <> 'C' .and. m->b1_tipo == 'MC'
				u_help("Produto do tipo MC deve ter obrigatoriamente C no seu final.")
				_lRet := .F.
			endif
		endif	
	endif
return _lRet
//
// --------------------------------------------------------------------------
// validação de alteração
static function _MT010Alt()
	local _aAreaAnt  := U_ML_SRArea ()
	local _oSQL      := NIL

	if sb1 -> b1_tipo == 'PA'  // A principio nao temos intencao de vender outros tipos de itens.
		U_AtuMerc ('SB1', sb1 -> (recno ()))
	endif
	
	// Avisos para logistica
	_AvisaLog ()
	
	// Atualiza descricao do item na tabela produtos X fornecedores.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " UPDATE " + RetSQLName ("SA5")
	_oSQL:_sQuery +=    " SET A5_NOMPROD = '" + alltrim (SB1->B1_DESC) + "'"
	_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND A5_FILIAL  = '" + xfilial ("SA5") + "'"
	_oSQL:_sQuery +=    " AND A5_PRODUTO = '" + SB1->B1_COD + "'"
	_oSQL:Exec ()

	U_ML_SRArea (_aAreaAnt)
Return
//
// --------------------------------------------------------------------------
// Avisos de interesse da logistica.
static function _AvisaLog ()
	local _sMsg := ""
	if (inclui .and. m->b1_vafullw == 'S') .or. (altera .and. sb1 -> b1_vafullw != 'S' .and. m->b1_vafullw == 'S')
		_sMsg += 'Novo produto com controle pelo FullWMS: ' + alltrim (m->b1_cod) + ' - ' + alltrim (m->b1_desc)
	endif
	if altera .and. sb1 -> b1_vafullw == 'S' .and. m->b1_codbar != sb1 -> b1_codbar
		_sMsg += "Produto '" + alltrim (m->b1_cod) + "' (" + alltrim (m->b1_desc) + "): cod.barras caixa (DUN14) alterado de '" + alltrim (sb1 -> b1_codbar) + "' para '" + alltrim (m->b1_codbar) + "'. Verifique cadastro do mesmo no FullWMS."
	endif
	if ! empty (_sMsg)
		U_ZZUNU ({"007"}, "Aviso manutencao cadastro Protheus X Fullsoft", _sMsg)
	endif
return
// --------------------------------------------------------------------------
// Verifica acessos do usuario e cria variavel para ser usada no X3_WHEN
static function _VerAcesso ()
	local _sPastas   := ""
	local i			 := 1
	public _sCposAlt := ""  // Deixar com PUBLIC para ser visivel no X3_WHEN

	// Se a variavel jah existir, nao preciso releitura dos acessos.
	if empty (_sCposAlt)

		// Cria antes uma lista de pastas para diminuir o numero de leituras do ZZU.
		if U_ZZUVL('060',__CUSERID,.F.)
			_sPastas += '2/'  // Impostos
		endif
		if U_ZZUVL('061',__CUSERID,.F.)
			_sPastas += '3/'  // MRP/Suprimentos
		endif
		if U_ZZUVL('062',__CUSERID,.F.)
			_sPastas += '9/'  // Uvas / vinhos
		endif
		if U_ZZUVL('063',__CUSERID,.F.)
			_sPastas += '5/8/'  // Atendimento + garantia estendica
		endif
		if U_ZZUVL('064',__CUSERID,.F.)
			_sPastas += '1/6/7/A/ /'  // Demais abas (inclusive 'outros')
		endif
		if U_ZZUVL('065',__CUSERID,.F.)
			_sPastas += '4/'  // C.Q.
		endif

		_aCpoSX3 := FwSX3Util():GetAllFields('SB1')
		
		For i:=1 To Len(_aCpoSX3)
		    If (alltrim(GetSx3Cache(_aCpoSX3[i], 'X3_ARQUIVO')) == 'SB1')
		    	If GetSx3Cache(_aCpoSX3[i], 'X3_FOLDER') $ _sPastas
		    		_sCposAlt += GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO')
		    	EndIf
		    Endif
		Next i
	endif
Return
//
// --------------------------------------------------------------------------
// Valida se pode excluir o item.
static function _ValidExcl ()
	local _lRetExcl  := .T.
	local _oSQL      := ClsSQL ():New ()
	local _sLkSrvMer := U_LkServer ('Mercanet')
	local _sLkSrvNAW := U_LkServer ('naWeb')

	// Verifica se o item existe no Mercanet.
	_oSQL:_sQuery := "SELECT COUNT (*) FROM " + _sLkSrvMer + ".DB_PRODUTO where DB_PROD_CODIGO = '" + alltrim (sb1 -> b1_cod) + "'"
	_oSQL:Log ()
	if _oSQL:RetQry () > 0
		u_help ('Codigo nao pode ser excluido, pois existe(m) registro(s) no sistema Mercanet.',, .t.)
		_lRetExcl = .F.
	endif

	// Verifica se o item existe no Fullsoft.
	_oSQL:_sQuery := "select (select count (*) from tb_wms_entrada where coditem  = '" + alltrim (sb1 -> b1_cod) + "')
	_oSQL:_sQuery +=     " + (select count (*) from tb_wms_lotes   where cod_item = '" + alltrim (sb1 -> b1_cod) + "')"
	_oSQL:Log ()
	if _oSQL:RetQry () > 0
		u_help ('Codigo nao pode ser excluido, pois existe(m) registro(s) no sistema FullWMS.',, .t.)
		_lRetExcl = .F.
	endif

	// Verifica se o item existe no NaWeb.
	_oSQL:_sQuery := "select (select count (*) from " + _sLkSrvNAW + ".inspecaoproduto where produto_cod        = '" + alltrim (sb1 -> b1_cod) + "')
	_oSQL:_sQuery +=     " + (select count (*) from " + _sLkSrvNAW + ".ColetaProdutos  where Coleta_produto_cod = '" + alltrim (sb1 -> b1_cod) + "')"
	_oSQL:_sQuery +=     " + (select count (*) from " + _sLkSrvNAW + ".SFInspCarga     where InspCargaVariedade = '" + alltrim (sb1 -> b1_cod) + "')"
	_oSQL:_sQuery +=     " + (select count (*) from " + _sLkSrvNAW + ".Rotulo          where RotuloProduto      = '" + alltrim (sb1 -> b1_cod) + "')"
	_oSQL:_sQuery +=     " + (select count (*) from " + _sLkSrvNAW + ".Sac             where sac_codigo_produto = '" + alltrim (sb1 -> b1_cod) + "')"
	_oSQL:Log ()
	if _oSQL:RetQry () > 0
		u_help ('Codigo nao pode ser excluido, pois existe(m) registro(s) no sistema NaWeb.',, .t.)
		_lRetExcl = .F.
	endif

return _lRetExcl
//
// --------------------------------------------------------------------------
// Caracteres especiais
Static Function CaracEsp(_sCampo)
    Local _i       := 0
    Local _lRet    := .T.
    Local _nExiste := 0
    Local _aCarac  := {}

    AADD(_aCarac,{"!"})
    AADD(_aCarac,{"@"})
    AADD(_aCarac,{"#"})
    AADD(_aCarac,{"$"})
    AADD(_aCarac,{"%"})
    AADD(_aCarac,{"*"})
    AADD(_aCarac,{"/"})
    AADD(_aCarac,{"("})
    AADD(_aCarac,{")"})
    AADD(_aCarac,{"+"})
    AADD(_aCarac,{"¨"})
    AADD(_aCarac,{"="})
    AADD(_aCarac,{"~"})
    AADD(_aCarac,{"^"})
    AADD(_aCarac,{"]"})
    AADD(_aCarac,{"["})
    AADD(_aCarac,{"{"})
    AADD(_aCarac,{"}"})
    AADD(_aCarac,{";"})
    AADD(_aCarac,{":"})
    AADD(_aCarac,{">"})
    AADD(_aCarac,{"<"})
    AADD(_aCarac,{"?"})
    AADD(_aCarac,{"_"})
    AADD(_aCarac,{","})
    AADD(_aCarac,{" "})
    AADD(_aCarac,{"‘"}) 
    AADD(_aCarac,{","}) 
    AADD(_aCarac,{"Á"})
    AADD(_aCarac,{"É"})
    AADD(_aCarac,{"Í"})
    AADD(_aCarac,{"Ó"})
    AADD(_aCarac,{"Ú"})
    AADD(_aCarac,{"Â"})
    AADD(_aCarac,{"Ê"})
    AADD(_aCarac,{"Î"})
    AADD(_aCarac,{"Ô"})
    AADD(_aCarac,{"Û"})
    AADD(_aCarac,{"Ã"})
    AADD(_aCarac,{"Õ"})
    AADD(_aCarac,{"Ü"})
    AADD(_aCarac,{"Ç"})
    AADD(_aCarac,{"."})
    AADD(_aCarac,{"&"})
    AADD(_aCarac,{"|"})
    AADD(_aCarac,{"À"})
    AADD(_aCarac,{" "})

    For _i:= 1 to Len(_aCarac)
        If _aCarac[_i, 1] $ RTRIM(_sCampo) 
            _nExiste += 1
        EndIf
    Next

    If _nExiste > 0
        _lRet := .F.
        u_help("Produto "+ RTRIM(_sCampo) + " com caracteres especiais. Verifique!")
    EndIf
Return _lRet
