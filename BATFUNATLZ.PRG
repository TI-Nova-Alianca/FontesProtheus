// Programa...: BATFUNATLZ
// Autor......: Catia Cardoso
// Data.......: 27/11/2015
// Descricao..: Grava Funcionarios e Associados como Clientes
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Grava Funcionarios e Associados como Clientes
// #PalavasChave      #funcionarios #associados #clientes 
// #TabelasPrincipais #VA_VFUNCIONARIOS #ZAD #SA1 #SZI
// #Modulos 		  #FAT #FIN 
//
// Historico de alteracoes:
// 21/01/2016 - alterar para que passe a gravar a data de desligamento
// 28/03/2017 - alterara a gravacao da tabela ZAD - tirada a data de desligamento e substituido pelo campo situa��o
// 02/09/2017 - Robert  - Passa a ler dados da view VA_VFUNCIONARIOS
// 11/10/2017 - Robert  - Database do Metadados migrado - alterado nome para acesso.
// 11/09/2018 - Catia   - Integracao gerando funcionarios e associados como clientes
// 19/09/2018 - Catia   - Cidades dos funcionarios tinha um GAP por causa de acentuacao e � - acertado
// 09/10/2018 - Catia   - Incluida a conta contabil nos funcionarios e associados
// 21/02/2019 - Catia   - Tratamento campos obrigat�rios A1_CNAE, A1_CONTRIB, A1_IENCONT
// 08/04/2019 - Catia   - include TbiConn.ch 
// 05/06/2019 - Catia   - alterado para atualizar sempre o cadastro quando for funcionario 
// 06/06/2019 - Catia   - estava dando erro campo A1_CDO_MUN invalido - por conta de gatilhos novos que foram criados
// 05/08/2019 - Robert  - Removido uso da tabela SZB (a ser eliminada do sistema).
//                      - Desabilitado envio dos campos A1_CNAE, A1_RISCO
//                      - Campo A1_GRPTRIB estava sendo enviado com nome A1_GRPTRIP
// 02/09/2019 - Claudia - Incluida valida��o MVC para grava��o de clientes
// 05/09/2019 - Claudia - Incluida a grava��o do campo A1_VADTINC
// 27/09/2019 - Robert  - Incluido tratamento para tetornar msg. de erro no objeto _oBatch
// 15/10/2019 - Robert  - Nao ativava objeto oModel antes da inclusao de cliente.
// 18/12/2019 - Robert  - Gravacao do campo ZAD_MATRIC
// 19/12/2019 - Robert  - Criava associados no SA1 apenas se tivessem compra de uva. Agora basta ter movto.tipo 08 (GLPI 7266)
//                        Tambem nao importa mais associados falecidos.
// 14/08/2020 - Cl�udia - Ajuste de Api em loop, conforme solicita��o da versao 25 protheus. GLPI: 7339
// 19/11/2020 - Sandra  - Ajuste do campo A1_GRPTRIB" de 001 para "003" no caso de funcionario e clientes, conforme A1_lojas
// 26/03/2021 - Robert  - Nao tinha tratamento para cidades com [til] no nome (GLPI 9706).
// 11/06/2021 - Robert  - Pequena melhoria na geracao de logs.
// 03/09/2021 - Claudia - Incluido campos obrigatorios na grava��o do cliente. GLPI: 10819
// 13/09/2021 - Robert  - Limitados tamanhos de alguns campos do SA1 (acusava erro 
//                        "String or binary data would be truncated" no SQL/DBAccess).
// 03/05/2022 - Claudia - Incluida a grava��o do campo a1_savblq. GLPI: 11922
// 07/03/2023 - Claudia - Incluido e-mail de verifica��o. GLPI: 11901
// 09/03/2023 - Claudia - Incluida regra para envio do e-mail apenas nas segundas-feiras.
// 08/03/2024 - Claudia - Ajustada a integra��o de municipios na query de funcioanrios. GLPI: 15060
// 19/03/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
// 09/04/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

// -----------------------------------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch" 

#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function BATFUNATLZ()
	local i          := 1
	local _wintegra  := 0
	local _tpMainWnd := type ("oMainWnd")
	private _sQuery  := ''
	
	u_logIni()
	u_log("Iniciando BATFUNATLZ em", date(), time ())

	_sErroAuto := ''  		// Para a funcao u_help gravar mensagens.
	_oBatch:Retorno = 'S'  	// "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente

	// PROCESSO ATUAL, SERA DESATIVADO, MAS AINDA CONTINUA 
	chkfile("ZAD")
		
	// DELETA A TABELA AUXILIAR DE FUNCIONARIOS
	_sSQL := ""
	_sSQL += "DELETE ZAD010" 
	if TCSQLExec (_sSQL) < 0
		_oBatch:Mensagens += 'Erro ao limpar tabela ZAD'
		_oBatch:Retorno = 'N'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
	else
		// GERA TABELA ATUALIZADA DE FUNCIONARIOS
		_sSQL := " "
		_sSQL += "      SELECT UNIDADE, NOME, CPF, SITUACAO, CRACHA"
		_sSQL += "      FROM LKSRV_SIRH.SIRH.dbo.VA_VFUNCIONARIOS"
		_sSQL += "      ORDER BY NOME"
		_aFuncionarios := U_Qry2Array(_sSQL)
		
		if len(_aFuncionarios) > 0
			for i=1 to len(_aFuncionarios)
				_wfilial = substr(_aFuncionarios[i,1],3,2)
				_wconta  = '101010201099'

				if _wfilial $ '03/08/10/13'
					_wconta = '101020701006'
				endif	

				_sSQL := ""
				_sSQL += " INSERT INTO ZAD010 ( ZAD_FILIAL, ZAD_FFILIA, ZAD_NOME, ZAD_CPF, ZAD_SITUA, ZAD_CONTA, R_E_C_N_O_, ZAD_MATRIC)"
				_sSQL += " VALUES ( '" + XFILIAL ("ZAD") + "' "  
				_sSQL += "        , '" + _wfilial + "'"
				_sSQL += "        , '" + UPPER (_aFuncionarios[i,2]) + "'"
				_sSQL += "        , '" + _aFuncionarios[i,3] + "'"
				_sSQL += "        , '" + _aFuncionarios[i,4] + "'"
				_sSQL += "        , '" + _wconta + "'"
				_sSQL += "        , '" + str(i,6) + "'"
				_sSQL += "        , '" + _aFuncionarios[i,5] + "'"
				_sSQL += " )"
				u_log2 ('info', _sSQL)
				
				if TCSQLExec (_sSQL) < 0
					_oBatch:Mensagens += 'Erro ao alimentar tabela ZAD'
					_oBatch:Retorno = 'N'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
				endif
			next
		endif
	endif

	// LE ASSOCIADOS E FUNCIONARIOS E GRAVA COMO CLIENTES
	for _wintegra=1 to 2 
		_sQuery := ""
		if _wintegra = 1
			_Exe1Query() // query de associados
		else
			_Exe2Query() // query de funcionarios
		endif			
		
		_aDados := U_Qry2Array(_sQuery)
 		
 		if len(_aDados) > 0
			for i=1 to len(_aDados)
			
				_wnome     := alltrim(_aDados[i,3])
				u_log2 ('info', _wnome)
				_wtipo     := _aDados[i,12]
				_wend      := alltrim(_aDados[i,4])
			    _wbairro   := alltrim(_aDados[i,5])
				_west      := _aDados[i,6]
				_wcep      := alltrim(_aDados[i,7])
				_wcidade   := alltrim(_aDados[i,8])
				_wtel      := alltrim(_aDados[i,9])
				_wemail    := alltrim(_aDados[i,10])
				_wcgc      := _aDados[i,11]
				_wcodmun   := _aDados[i,13]
				_wregiao   := u__regiao (_aDados[i,6]) //_aDados[i,15]
				_wsituacao := _aDados[i,2] 
				_wcodmun2  := _BuscaDadosMun(_wcodmun, _west, '1')
				_wDescMun  := _BuscaDadosMun(_wcodmun, _west, '2')

				if empty(_wemail)
					U_Log2 ('erro', 'E-mail nao informado no cadastro de ' + _wnome)
					loop
				endif
				if empty(_wcgc)
					_wcgc := "lixo@novaalianca.coop.br"
				endif

				if empty(_wbairro)
					_wbairro := "-"
				endif

				if _wintegra = 2	// funcionarios
					_wconta    = ALLTRIM(fBuscaCpo ('ZAD', 1, xfilial('ZAD') + _wcgc, "ZAD_CONTA"))
				else 				// associados
					_wcont = '101020101002'
				endif
				
				// testa se o cliente ja existe
				_wcontinua = .T.
				if val(fBuscaCpo ('SA1', 3, xfilial('SA1') + _wcgc , "A1_COD")) > 0
				    _wcontinua = .F.
				endif
				
				if _wcontinua // inclui o cliente
					u_log2 ('info', 'Incluindo cliente ' + _wnome)
					lMsErroAuto := .F.
					_sErroAuto  := ''			

					//Pegando o modelo de dados, setando a opera��o de inclus�o
					oModel:= FWLoadModel("MATA030")
					oModel:SetOperation(3)
					oModel:Activate()

					//Pegando o model dos campos da SA1
					oSA1Mod:= oModel:getModel("MATA030_SA1")
					
					oSA1Mod:setValue("A1_NOME"		, _wnome								)
					oSA1Mod:setValue("A1_PESSOA"	, _wtipo								)
					oSA1Mod:setValue("A1_END"		, left (_wend, tamsx3 ("A1_END")[1])	)
					oSA1Mod:setValue("A1_BAIRRO"	, _wbairro								)
					oSA1Mod:setValue("A1_EST"		, _west									)
					oSA1Mod:setValue("A1_CEP"		, left (_wcep, tamsx3 ("A1_CEP")[1])	)
					oSA1Mod:setValue("A1_TEL"		, left (_wtel, tamsx3 ("A1_TEL")[1])	)
					oSA1Mod:setValue("A1_EMAIL"		, _wemail								)
					oSA1Mod:setValue("A1_CGC"		, _wcgc									)
					oSA1Mod:setValue("A1_COD_MUN"	, _wcodmun								)
					oSA1Mod:setValue("A1_REGIAO"	, _wregiao								)
					oSA1Mod:setValue("A1_FILIAL"	, ""									)
					oSA1Mod:setValue("A1_NREDUZ"	, left (_wnome, tamsx3 ("A1_NREDUZ")[1]))
					oSA1Mod:setValue("A1_LOJA"		, "01" 									)
					oSA1Mod:setValue("A1_VEND"		, "001" 								)
					oSA1Mod:setValue("A1_MALA"		, "S" 									)
					oSA1Mod:setValue("A1_TIPO"		, "F" 									)
					oSA1Mod:setValue("A1_BCO1"		, "CX1" 								)
					oSA1Mod:setValue("A1_PAIS"		, "105" 								)
					oSA1Mod:setValue("A1_SATIV1"	, "08.04" 								)
					oSA1Mod:setValue("A1_VAMDANF"	, _wemail								)
					oSA1Mod:setValue("A1_CODPAIS"	, "01058" 								)
					oSA1Mod:setValue("A1_MSBLQL"	, "2" 									)
					oSA1Mod:setValue("A1_SIMPNAC"	, "2" 									)
					oSA1Mod:setValue("A1_VABARAP"	, "0"  									)
					oSA1Mod:setValue("A1_CONTA"		, "101020201001" 						)
					oSA1Mod:setValue("A1_COND"		, "097"									)
					oSA1Mod:setValue("A1_VAUEXPO"	, ddatabase								)
					oSA1Mod:setValue("A1_VERBA"		, "2"									)
					oSA1Mod:setValue("A1_GRPTRIB"	, "003"									)
					oSA1Mod:setValue("A1_FORMA"		, "3" 									)
					oSA1Mod:setValue("A1_CONTA"		, _wconta								)
					oSA1Mod:setValue("A1_CNAE"		, "0"  									)
					oSA1Mod:setValue("A1_CONTRIB"	, "2"									)  
					oSA1Mod:setValue("A1_IENCONT"	, "2"									)
					oSA1Mod:setValue("A1_LOJAS"		, iif(_wintegra=1,"A","F")				) 
					oSA1Mod:setValue("A1_VADTINC"	, date()								)    
					oSA1Mod:SetValue("A1_RISCO"		, "E"									)
					oSA1Mod:SetValue("A1_VAEMLF"	, _wemail								)  		
					oSA1Mod:SetValue("A1_VACGCFI"	, _wcgc									)  
					oSA1Mod:SetValue("A1_MUN"		, _wDescMun								)
					oSA1Mod:SetValue("A1_CMUN"		, _wcodmun2								)  
					oSA1Mod:SetValue("A1_SAVBLQ"	, 'S'								    )             
					
					If oModel:VldData() 		// Se conseguir validar as informa��es
					    If oModel:CommitData() 	// Tenta realizar o Commit
					        lDeuCerto := .T.
					    Else 					// Se n�o deu certo, altera a vari�vel para false
					        lDeuCerto := .F.
					    EndIf
					Else 						// Se n�o conseguir validar as informa��es, altera a vari�vel para false
					    lDeuCerto := .F.
					EndIf
					
					If lDeuCerto == .F. 		//Se n�o deu certo a inclus�o, mostra a mensagem de erro
						
						aErro := oModel:GetErrorMessage() //Busca o Erro do Modelo de Dados
						
						_sErroAuto += ("Id do formul�rio de origem:"  + ' [' + AllToChar(aErro[01]) + ']')
						_sErroAuto += ("Id do campo de origem: "      + ' [' + AllToChar(aErro[02]) + ']')
						_sErroAuto += ("Id do formul�rio de erro: "   + ' [' + AllToChar(aErro[03]) + ']')
						_sErroAuto += ("Id do campo de erro: "        + ' [' + AllToChar(aErro[04]) + ']')
						_sErroAuto += ("Id do erro: "                 + ' [' + AllToChar(aErro[05]) + ']')
						_sErroAuto += ("Mensagem do erro: "           + ' [' + AllToChar(aErro[06]) + ']')
						_sErroAuto += ("Mensagem da solu��o: "        + ' [' + AllToChar(aErro[07]) + ']')
						_sErroAuto += ("Valor atribu�do: "            + ' [' + AllToChar(aErro[08]) + ']')
						_sErroAuto += ("Valor anterior: "             + ' [' + AllToChar(aErro[09]) + ']')
						u_log2 ('erro', _sErroAuto)

						if _tpMainWnd == "O"  // Se tem interface com o usuario
							MostraErro()
						endif
					Else
						u_log2 ('Cliente incluido: ' + sa1 -> a1_cod)
					EndIf
					
					//Desativa o modelo de dados
					oModel:DeActivate()
				else
					_wlojas = iif(_wintegra=1,'A','F')

					if _wintegra = 2 								// FUNCIONARIOS
						if _wsituacao = '3' .or. _wsituacao = '4' 	// DESLIGADO - FUNCIONARIO DESLIGADO CONTINUA SENDO CLIENTE
							_wlojas   = 'S' 						// PASSA DE F PARA S - A1_LOJAS=SIM passa a ser cliente loja normal sem desconto
							_wconta   = '101020201001' 				// PASSA PARA CONTA DE CLIENTES NORMAL
						endif
					endif
					_wcodcli  = fBuscaCpo ('SA1', 3, xfilial('SA1') + _wcgc , "A1_COD")
					_wlojacli = fBuscaCpo ('SA1', 3, xfilial('SA1') + _wcgc , "A1_LOJA")
					    
				    // SE JA EXISTE O CLIENTE E O CADASTRO NAO FOI ATUALIZADO RECENTEMENTE
			        // GRAVA OS DADOS PADRAO IGUAIS AOS DOS CLIENTES NOVOS
			        _sSQL := ""
					_sSQL += " UPDATE SA1010"
					_sSQL += "    SET A1_VAUEXPO = '" + dtos(ddatabase) + "'"
					if _wintegra = 2  // SO ATUALIZA FUNCIONARIOS - VER DEPOIS SOBRE ASSOCIADOS
				        _sSQL += "      , A1_NOME    = '" + _wnome + "'"
			            _sSQL += "      , A1_PESSOA  = '" + _wtipo + "'"
			            _sSQL += "      , A1_END     = '" + left (_wend, tamsx3 ("A1_END")[1]) + "'"
			            _sSQL += "      , A1_BAIRRO  = '" + _wbairro + "'"
			            _sSQL += "      , A1_EST 	 = '" + _west + "'"
			            _sSQL += "      , A1_CEP     = '" + left (_wcep, tamsx3 ("A1_CEP")[1]) + "'"
			            _sSQL += "      , A1_TEL     = '" + left (_wtel, tamsx3 ("A1_TEL")[1]) + "'"
						_sSQL += "      , A1_EMAIL   = '" + _wemail + "'"  
						_sSQL += "      , A1_COD_MUN = '" + _wcodmun + "'"
						_sSQL += "      , A1_REGIAO  = '" + _wregiao + "'"
						_sSQL += "      , A1_NREDUZ  = '" + left (_wnome, tamsx3 ("A1_NREDUZ")[1]) + "'"
						_sSQL += "      , A1_VAMDANF = '" + _wemail + "'"
			        endif 
			        _sSQL += "      , A1_LOJAS   = '" + _wlojas + "'"
			        _sSQL += "      , A1_CONTA   = '" + _wconta + "'"
			        _sSQL += "  WHERE D_E_L_E_T_ = ''"
					_sSQL += "    AND A1_COD     = '" + _wcodcli  + "'"
					_sSQL += "    AND A1_LOJA    = '" + _wlojacli + "'"
					//_sSQL += "    AND A1_VAUEXPO < '" + dtos(ddatabase) + "'"  // Apenas 1 vez por dia
					u_log2 ('info', _sSQL)
					TCSQLExec (_sSQL)
				endif
			next
		endif
	next
	u_log2 ('debug', '_sErroAUto:')
	u_log2 ('debug', _sErroAuto)
	if ! empty (_sErroAuto)
		_oBatch:Mensagens += _sErroAuto
		_oBatch:Retorno = 'N'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
	else
		_oBatch:Retorno = 'S'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
	endif


	// verifica se funcionario gerou cliente e se este esta com e-mail
	If DOW(DATE()) == 2
		_EmailFunCli()
	EndIf

	u_logFim()
return .T.
//
// --------------------------------------------------------------------------
// Busca Associados
Static Function _Exe1Query() 

    _sQuery += " SELECT SA2.A2_COD"		// 1
    _sQuery += "	  , SA2.A2_LOJA"	// 2
	_sQuery += " 	  , SA2.A2_NOME"	// 3
	_sQuery += " 	  , SA2.A2_END"		// 4
	_sQuery += " 	  , SA2.A2_BAIRRO"	// 5
	_sQuery += " 	  , SA2.A2_EST"		// 6
	_sQuery += " 	  , SA2.A2_CEP"		// 7 
	_sQuery += " 	  , SA2.A2_MUN"		// 8
	_sQuery += " 	  , SA2.A2_TEL"		// 9
	_sQuery += " 	  , SA2.A2_EMAIL"	//10
	_sQuery += " 	  , SA2.A2_CGC"		//11
	_sQuery += " 	  , SA2.A2_TIPO"	//12
	_sQuery += " 	  , SA2.A2_COD_MUN"	//13
  	_sQuery += "   FROM SA2010 AS SA2"
  	_sQuery += "	  INNER JOIN CC2010 AS CC2"
	_sQuery += "			ON (CC2.D_E_L_E_T_ = ''"
	_sQuery += "	    		AND CC2.CC2_EST = SA2.A2_EST"
	_sQuery += "				AND CC2.CC2_CODMUN = SA2.A2_COD_MUN)"
	_sQuery += "	  INNER JOIN SZB010 AS SZB"
	_sQuery += "			ON (SZB.D_E_L_E_T_ = ''"
	_sQuery += "				AND SZB.ZB_COD = CC2.CC2_VA_SZB)"
 	_sQuery += "  WHERE SA2.D_E_L_E_T_ = ''"
 	_sQuery += "    AND SA2.A2_VADTFAL = ''"  	// Data de falecimento
 	_sQuery += "    AND SA2.A2_CGC    != '.'"  	// Alguns associados que tinham cotas, mas nao conseguimos encontrar seu cadastro na incorporacao.
 	_sQuery += "	AND EXISTS (SELECT SZI.ZI_ASSOC"
	_sQuery += "				FROM SZI010 AS SZI"
	_sQuery += "			   WHERE SZI.ZI_ASSOC    = SA2.A2_COD"
	_sQuery += "		    	 AND SZI.D_E_L_E_T_  = ''"
	_sQuery += "				 AND SZI.ZI_TM       = '08'"  // 08 = entrada do associado na cooperativa
	_sQuery += "				 AND SZI.ZI_LOJASSO  = SA2.A2_LOJA)"
	_sQuery += "	AND NOT EXISTS (SELECT SZI.ZI_ASSOC"
	_sQuery += "				    FROM SZI010 AS SZI"
	_sQuery += "			       WHERE SZI.ZI_ASSOC   = SA2.A2_COD"
	_sQuery += "				     AND SZI.D_E_L_E_T_ = ''"
	_sQuery += "		        	 AND SZI.ZI_TM      = '09'"  // 09 = desligamento do associado da cooperativa
	_sQuery += "			     	AND SZI.ZI_LOJASSO  = SA2.A2_LOJA)"
 	_sQuery += " ORDER BY SA2.A2_NOME"
 	u_log2 ('info', _sQuery)	
return	
//
// --------------------------------------------------------------------------
// Busca funcion�rios
Static Function _Exe2Query() 

	_sQuery += " SELECT FUN.UNIDADE" 			//  1
	_sQuery += "        ,FUN.SITUACAO"			//  2	
	_sQuery += " 		,UPPER(FUN.NOME)"		//	3
	_sQuery += " 		,UPPER(FUN.ENDERECO)"	//	4
	_sQuery += " 		,UPPER(FUN.BAIRRO)"		//	5
	_sQuery += " 		,FUN.UF"				//	6
	_sQuery += " 		,FUN.CEP"				//	7
	_sQuery += " 		,REPLACE(REPLACE(FUN.CIDADE,'�','c'),'�','a')"										//	8
	_sQuery += " 		,ISNULL(REPLACE(REPLACE(FUN.TELEFONE,'-',''),' ',''), '5432743400') AS TELEFONE"	//	9
	_sQuery += " 		,ISNULL(REPLACE(FUN.EMAIL,' ',''),'lixo@novaalianca.coop.br') AS EMAIL"				// 10	
	_sQuery += " 		,FUN.CPF"				// 11
	_sQuery += " 		,'F'"					// 12
	_sQuery += " 		,CC2.CC2_CODMUN" 		// 13
	_sQuery += " 		,ISNULL (FUN.CRACHA, '')"
	_sQuery += "   FROM LKSRV_SIRH.SIRH.dbo.VA_VFUNCIONARIOS AS FUN"
	_sQuery += " 		INNER JOIN CC2010 AS CC2"
	_sQuery += " 			ON (CC2.D_E_L_E_T_  = ''"
	_sQuery += " 				AND CC2.CC2_EST = FUN.UF COLLATE DATABASE_DEFAULT"
	//_sQuery += " 	    		AND CC2.CC2_MUN = UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(FUN.CIDADE,'�','c'),'�','a'),'�','a'),'�','o'),'�','i'),'�','e'),'�','u')) COLLATE DATABASE_DEFAULT ) "
	_sQuery += "                AND CC2.CC2_MUN  LIKE '%'+ UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(FUN.CIDADE,'�','c'),'�','a'),'�','a'),'�','o'),'�','i'),'�','o'),'�','e'),'�','u')) + '%' COLLATE DATABASE_DEFAULT ) "
	_sQuery += " 		INNER JOIN SZB010 AS SZB"
	_sQuery += " 			ON (SZB.D_E_L_E_T_  = ''"
	_sQuery += " 				AND SZB.ZB_COD  = CC2.CC2_VA_SZB)"
	_sQuery += " ORDER BY NOME"
	//u_log2 ('info', _sQuery)
return
//
// --------------------------------------------------------------------------
// Busca dados do municipio
Static Function  _BuscaDadosMun(_wcodmun, _west, _wTipo)
	Local _oSQL := ClsSQL ():New ()
	Local _i    := 0

	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   CC2_VA_SZB " 
	_oSQL:_sQuery += "    ,CC2_MUN "
	_oSQL:_sQuery += " FROM CC2010 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND CC2_CODMUN   = '" + _wcodmun + "'"
	_oSQL:_sQuery += " AND CC2_EST      = '" + _west    + "'"
	//u_log2 ('info', _oSQL:_sQuery)
	_aMun := aclone (_oSQL:Qry2Array (.f., .f.))

	If len(_aMun) > 0
		For _i:=1 to Len(_aMun)
			If _wTipo == '1'
				_wRet := _aMun[_i, 1]
			Else
				_wRet := _aMun[_i, 2]
			EndIf
		Next
	Else
		_wRet := ""
	EndIf 

	If _wTipo == '2' .and. empty(_wRet)
		_wRet := "-"
	EndIf
Return _wRet
//
// --------------------------------------------------------------------------
// E-mail de funcionario/cliente e email
Static Function _EmailFunCli()
	Local _aFunc     := {}	
	Local _x         := 0
	Local _i         := 0
	Local _aEmail    := {}

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	    CPF "
	_oSQL:_sQuery += "     ,NOME "
	_oSQL:_sQuery += "     ,EMAIL "
	_oSQL:_sQuery += " FROM LKSRV_SIRH.SIRH.dbo.VA_VFUNCIONARIOS "
	_oSQL:_sQuery += " WHERE SITUACAO = '1' "
	_oSQL:_sQuery += " ORDER BY NOME "
//	_aFunc := aclone(_oSQL:Qry2Array())
	_aFunc := aclone(_oSQL:Qry2Array(.f., .f.))

	For _x := 1 to Len(_aFunc)
		_sCgc  := _aFunc[_x,1]
		_sFunc := _aFunc[_x,2]
		_sEmail:= _aFunc[_x,3]

		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += "     A1_NOME "
		_oSQL:_sQuery += "    ,A1_EMAIL "
		_oSQL:_sQuery += "    ,A1_CGC "
		_oSQL:_sQuery += " FROM " + RetSQLName ("SA1")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " AND A1_CGC LIKE '%"+ _sCgc +"'"
//		_aCliente := aclone(_oSQL:Qry2Array())
		_aCliente := aclone(_oSQL:Qry2Array(.f., .f.))

		If Len(_aCliente) > 0
			// Funcionario � cliente, mas nao tem e-mail
			For _i := 1 to Len(_aCliente)
				If 'lixo' $ (_aCliente[_i,2])
					AADD(_aEmail, { _aCliente[_i, 1]    ,;
									_aCliente[_i, 3]    ,;
									'SIM'				,;
									'E-MAIL CADASTRADO COMO lixo@novaalianca.coop.br'}) 
				EndIf
			Next
		else
			// Funcionario que n�o � cliente
			If empty(_sEmail)
				_MsgEmail := "E-MAIL VAZIO NO CADASTRO"
			else
				_MsgEmail := "N�O ENCONTRADO O MUNICIPIO"
			EndIf
			AADD(_aEmail, { _sFunc 		,;
							_sCgc  		,;
							'N�O'       ,;
							_MsgEmail 	}) 
		EndIf
	Next

	If Len(_aEmail) > 0
		_sMsg := "<html>"
		_sMsg += "<h4> Verifica��o de Funcion�rios em: " + dtoc(date()) +"</h4>"
		_sMsg += "<table border='2'>"
		_sMsg += "    <tr>"
		_sMsg += "        <td>Nome</td>"
		_sMsg += "        <td>CPF</td>"
		_sMsg += "        <td>Possui Cadastro de cliente?</td>"
		_sMsg += "        <td>Erro</td>"
		_sMsg += "    </tr>"
		For _x :=1 to Len(_aEmail)
			_sMsg += "    <tr>"
			_sMsg += "        <td>"+ upper(_aEmail[_x, 1]) +"</td>"
			_sMsg += "        <td>"+ _aEmail[_x, 2]        +"</td>"
			_sMsg += "        <td>"+ _aEmail[_x, 3]        +"</td>"
			_sMsg += "        <td>"+ _aEmail[_x, 4]        +"</td>"
			_sMsg += "    </tr>"
		Next
		_sMsg += "</table>"
		_sMsg += "</html>"
		U_ZZUNU ({'110'}, "Verifica��o de Cliente-Funcion�rio", _sMsg, .F., cEmpAnt, cFilAnt, "") 
	EndIf

Return 
