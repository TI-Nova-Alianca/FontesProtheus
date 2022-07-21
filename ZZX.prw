// Programa...: ZZX
// Autor......: Robert Koch
// Data.......: 29/05/2011
// Descricao..: Manutencao de arquivos XML de NF-e recebidos de fornecedores.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao
// #Descricao         #Manutencao de arquivos XML de notas de entrada
// #PalavasChave      #XML NF_eletronica #chaves
// #TabelasPrincipais #ZZX
// #Modulos           #COM #FAT

// Historico de alteracoes:
// 19/08/2011 - Robert  - Tratamento para importacao de XML destinado a outras filiais.
//                      - Tratamento para NF de retorno deposito (especifico filial 04 Coop.Alianca).
//                      - Melhorada leitura de XML de cancelamentos de notas.
// 05/09/2011 - Robert  - Nao preenchia completamente o campo ZZX_DOC quando havia poucas posicoes no XML.
// 06/12/2011 - Robert  - Importava tags cNF e cCT como numero da nota, quando o correto eh usar as tags nNF e nCT.
//                      - Verifica se o layout 'enviNFe' contem a tag 'infNFe' (alguns XML parecem nao conter esse nivel).
//                      - Conversao para UTF8 eventualmente gera caracteres especiais no inicio da string do XML.
// 25/06/2012 - Robert  - Implementada funcionalidade de importacao automatica (batch)
//                      - Criado tratamento para tag TOMA03 em conhecimentos de frete.
//                      - Criado envio de e-mail de aviso de importacao cd XML de cancelamento.
// 04/07/2012 - Robert  - Criado envio de e-mail de aviso de importacao cd XML de devolucao.
// 01/09/2012 - Robert  - Apos importar arquivo jah faz a consulta da chave na SEFAZ.
// 31/10/2012 - Robert  - Passa a aceitar retorno 150 (NF-e autorizada fora do prazo).
// 12/02/2013 - Elaine  - Trata a variavel _F1CHVNFE como private, setando-a antes de ir para as consistencias da geracao da NF, para o MT100TOK
//                        saber qual é a chave
// 16/05/2013 - Robert  - Tratamento para quando o tomador do servico de frete eh um CPF e nao CNPJ.
// 20/06/2013 - Elaine  - Inclui rotina para inclusao de ZZX por baixa de anexos por email
// 23/08/2013 - Robert  - Passa a verificar se deve gerar nota tipo 'B'.
// 30/08/2013 - Leandro	- Considerar e importar também cancelamentos por evento e carta de correção. Foram criados campos para diferenciar estes 2 eventos.
// 06/09/2013 - Leandro - Considera os 3 layouts diferentes para eventos (cancelamento ou carta de correção) e grava motivo ou justificativa na SYD
// 20/08/2014 - Robert  - Passa a trabalhar com as classes ClsNFe e ClsXmlNF.
// 08/09/2014 - Catia   - Revalidacao, se retorno de cancelamento do SEFA exclui registro da ZZX
// 05/02/2015 - Catia   - Ao revalidar XML, se o retorno for 101 = CANCELADO e ja estiver no sistema, manda email pro FISCAL avisando
// 19/02/2015 - Robert  - Revalidação - acertado que estava zerando o XML 
// 21/02/2015 - Catia   - Alerado para que use as rotinas de usuario do DEPTO FISCAL para mandar EMAIL quando retorno de cancelamento do SEFAZ
// 12/03/2015 - Robert  - Criada mensagem "XXXXX - Sem retorno da consulta `a SEFAZ."
// 24/03/2015 - Robert  - Passa a mostrar em tela os avisos gerados na interpretacao do XML.
//                      - Criada opcao de visualizacao dos itens da nota do XML.
//                      - Criada opcao de ajustes manuais (apenas alguns campos).
// 16/06/2015 - Robert  - Nao consulta mais a chave durante a revalidacao (migrado para PowerShell por que o Protheus nao da mais suporte).
//                      - Revalidacao permite exclusao do registro quando destina-se a outra empresa.
// 03/07/2015 - Robert  - Revalidacao exclui registro quando for emitido em ambiente de homologacao.
// 01/10/2015 - Robert  - Ajustes visualizacao itens NFe.
// 15/10/2015 - Robert  - Grava campo ZZX_CNPJEM.
// 28/10/2015 - Robert  - Pode receber o conteudo do XML por parametro na funcao ZZXI (nao precisa ler de nenhum arquivo).
// 27/11/2015 - Catia   - Opcao Revalidar - alterado para que verifique o STATUS
// 06/01/2015 - Catia   - Não permitir excluir XML de documentos que estejam lançados no sistema
// 28/01/2015 - Catia   - Alterado teste para verificar se ja existe XML lançado (CHAVE + LAYOUT)
// 14/04/2016 - Robert  - Leitura de arquivo via MemoRead mudada para FT_ReadLn por que ficava limitada a 64 Kb.
// 18/04/2016 - Catia   - Testes - não estava deletando o arquivo depois de importar e mover para a pasta correta
// 02/05/2016 - Robert  - Nao fechava o arquivo (FT_FUSE) apos importacao e nao deixava apagar do disco.
// 07/07/2016 - Catia   - Desabilitada funcao - Consulta de Chave - que nao estava funcionando e dava erro
// 07/07/2016 - Catia   - Desabilitada funcao - Identifica DOC - não tem mais necessidade
// 15/07/2016 - Robert  - Grava valor de ICMS e valor total quando CTe.
// 06/12/2016 - Catia   - alterado perguntas inicias para filtro na tabela de XML's de entrada
// 12/12/2016 - Catia   - Na opção de visualizar os itens - incluida a NCM conforme está no XML
// 15/12/2016 - Catia   - parametro para filtrar fornecedor/cliente
// 10/05/2017 - Catia   - ajustes dados de devolucao
// 11/08/2017 - Catia   - tratamento de não aceite da operacao
// 18/09/2017 - Catia   - alterada a opcao revalida
// 10/01/2018 - Catia   - tratamento na opcao de dados de devolução para poder digitar parcialmente os dados da devolucao
// 11/01/2018 - Catia   - permitir consultar os dados de devolução com o documento já lançado no sistema
// 17/01/2018 - Catia   - estava dando erro na linha 814 - quando testava se ja existia o usuario ZAJ
// 21/03/2018 - Catia   - criada opcao de consultar as notas referenciadas em um XML
// 21/03/2018 - Catia   - manutencao na opcao de gerar documento de entrada de CTE referente a notas de saidas com mais de uma nota referenciada
// 04/04/2018 - Catia   - conversao de unidade de medida na geracao do documento de entrada ou pre nota
// 17/04/2018 - Catia   - retirado o tratamento do parametro MV_TESPCNF que foi desativado e passou a ser feito via ponto de entrada
// 18/04/2018 - Catia   - ao buscar a ordem de compra item, nao estava desconsiderando os itens que tinham sido eliminado residuo
// 20/04/2018 - Catia   - alterado query do SC7 para que considere tambem a quantidade a classificar do item
// 25/04/2018 - Catia   - ajuste conversao unidade de medida - testar a unidade do XML contra a unidade de estoque
// 15/05/2018 - Catia   - nos dados de devolução, incluido o vendedor para a devolucao
// 21/06/2018 - Catia   - alterado para que na opção revalida seja possivel excluir os XMLS em branco e que se destinam a outro CNPJ
// 21/06/2018 - Catia   - nos dados de devolucao nao estava gravando o vendedor da nota original e nem o vendedor que deve considera a nf de devolucao
// 22/06/2018 - Catia   - estava dando mensagem de motivo de devolucao inativo
// 13/08/2018 - Catia   - alterado para que na geracao da pre-nota o sistema permita visualizar o documento
// 14/08/2018 - Catia   - na opcao de gerar documento de entrada referente a devolucoes - buscar o almox conf. o indicador de retorno Sím ou Nao
// 14/08/2018 - Catia   - na opcao de gerar documento de entrada referente a devolucoes - trazer o valor do item da nota fiscal original
// 20/11/2018 - Catia   - tratamento para importar as notas de transferencias entre filiais
// 29/11/2018 - Catia   - tratamento para mais um tipo de importacao de XML INTPROTHEUS - notas de trasnferencia
// 03/12/2018 - Catia   - alterado o TES padrao do tipo de produto ME que estava caindo no 081 e o correto é o 057 
// 18/02/2019 - Catia   - tratamento no codigo de produto que vem no XML para quando tem letras transformar tudo para maiusculo - UPPER 
// 26/03/2019 - Catia   - rotina automatica da pre-nota e da nota nao estavam abrindo o documento para inclusao - acusava erro D1_ITEMORIG
// 29/03/2019 - Catia   - rotina automatica da geracao da nota de entrada estava dando erro - porem nao dava mensagem - campo D1_CF
// 07/05/2019 - Catia   - tratamento para notas com retorno 150 e 100 (150 = autorizado fora do prazo)
// 16/05/2019 - Catia   - tratamento para importar o peso liquido e peso bruto no XML
// 17/05/2019 - Catia   - desconsiderar as notas serie 2 emitidas pela cooperativa no filtro principal
// 26/06/2019 - Catia   - dados de devolucao da logistica
// 28/06/2019 - Catia   - forçar o campo zzx_retsef como 100 na importacao do XML
// 01/07/2019 - Catia   - o comercial nao consegui consultar os dados de devolucao da logistica
// 11/07/2019 - Catia   - validar NCM do XML com a NCM do cadastro do item
// 29/08/2019 - Robert  - Criada opcao de abrir a tela com filtros ou mbrowse simples.
// 09/09/2019 - Claudia - Incluida chamada para impressão de romaneio de entrada.
// 20/12/2019 - Claudia - Incluida a rotina VA_CPORT no menu.
// 07/01/2020 - Andre   - Quando for nota de transferencia para filial 16 e PA, TES = 255.
// 23/01/2020 - Robert  - Melhorada mensagem de diferenca NCM com cadastro do produto.
// 29/01/2020 - Claudia - Incluída a impressão dos dados: Imp.Dados Devolução GLPI 7389
// 05/03/2020 - Sandra  - Retirado validação da legenda 6 em informar os dados de devolucao do comercial
// 30/03/2020 - Claudia - Verificado fonte conforme GLPI: 7739. Não foi necessário alterações.
// 31/03/2020 - Claudia - Alterada a validação de quantidade conforme GLPI: 7748
// 02/04/2020 - Claudia - Voltada alteração GLPI: 7748
// 03/04/2020 - Claudia - Ajustada validação de linha e gravação, conforme GLPI: 7762
// 22/07/2020 - Robert  - Verificacao de acesso dados devol.logistica: passa a validar acesso 112 e nao mais 030.
//                      - Inseridas tags para catalogacao de fontes
// 24/08/2020 - Cláudia - Ajuste na validação de quantidades. GLPI: 8358
// 28/09/2020 - Robert  - Nao localizava NF de venda pela chave pois o sistema padrao mudou a ordem dos indices (GLPI 8569).
// 05/05/2021 - Robert  - Alterada regra geracao TES entrada transf.filiais tipo prod.RE do TES 234 para 151 (GLPI 7916).
// 25/08/2021 - Robert  - Manda uma copia do XML para o importador da TRS (GLPI projeto 15).
// 14/04/2022 - Claudia - Criado novo menu para exporta dados. GLPI: 11889
// 20/07/2022 - Robert  - Gravacao de eventos temporarios para rastreio de import/export. XML (GLPI 12336)
//

// ----------------------------------------------------------------------------------------------------------------------------------
#include "colors.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"
#include "VA_INCLU.prw"

User Function ZZX ()
	local _aCores     := U_ZZXLEG(.T.)
	local _aIndBrw    := {}
	Private aRotina   := {}
	private cCadastro := "Manutenção XML's"
	Private cString   := "ZZX"
	
	// verifica parametros usados no programa para geracao de CTE's
	_xTES_c_ICMS := GetMv("ML_CTRTCIC")   // TES c/ ICMS para CTE's
	if _xTES_c_ICMS = ' '
    	u_help ("Parametro ML_CTRTCIC, referente ao TES com ICMS, não informado no sistema.")
    	return    
	endif

	_xTES_s_ICMS := GetMv("ML_CTRTSIC")   // TES s/ ICMS para CTE's
	if _xTES_s_ICMS = ' '
    	u_help ("Parametro ML_CTRTCIC, referente ao TES sem ICMS, não informado no sistema.")
    	return    
	endif

	_xPRODUTO    := Left(GetMv("ML_CTRPROD")+Space(15),15)   // Codigo do Produto  FRETE para CTE's
	if _xPRODUTO = ' '
    	u_help ("Parametro ML_CTRPROD, referente ao PRODUTO de frete, não informado no sistema.")
    	return    
	endif
	
	//_xTESnaoOC    := Left(GetMv("MV_TESPCNF")+Space(15),15)   // Codigos de TES que não obrigam ordem de compra

	// Submenu de rotinas adicionais
	aadd (aRotina, {"&Pesquisar"           , "AxPesqui"         ,   0, 1})
	aadd (aRotina, {"&Visualizar"          , "AxVisual"         ,   0, 2})
	aadd (aRotina, {"&Ajuste manual"       , "AxAltera"         ,   0, 4})
	aadd (aRotina, {"&Importar XML"        , "U_ZZXI ()"        ,   0, 3})
	aadd (aRotina, {"Revalida XML"         , "U_ZZXR (.T.)"     ,   0, 2})
	aadd (aRotina, {"Vizualiza XML"        , "U_ZZXV (1)"       ,   0, 2})
	aadd (aRotina, {"Itens do XML"         , "U_ZZXV (2)"       ,   0, 2})
	aadd (aRotina, {"Dados Adic.do XML"    , "U_ZZXV (3)"       ,   0, 2})
	aadd (aRotina, {"&CTEs - Verifica NFs" , "U_ZZXVNFS()"      ,   0, 4})
	aadd (aRotina, {"&Gera DOC.ENTR."      , "U_ZZXG ()"        ,   0, 3})
	aadd (aRotina, {"&Gera PRE-NOTA"       , "U_ZZXG (1)"       ,   0, 4})
	aadd (aRotina, {"&Excluir"             , "U_ZZXE (.F.)"     ,   0, 5})
	aadd (aRotina, {"&Marcar Contra Nota"  , "U_ZZXM ()"        ,   0, 4})
	aadd (aRotina, {"&Desconsiderar"       , "U_ZZXN ()"        ,   0, 4})
	aadd (aRotina, {"&Não Aceite Operação" , "U_ZZXO ()"        ,   0, 4})
	aadd (aRotina, {"&Solicitar Dados Dev.Logistica", "U_ZZXS ()"      ,   0, 4})
	aadd (aRotina, {"&Dados Devolução - COM", "U_ZZXD (1)"      ,   0, 4})
	aadd (aRotina, {"&Dados Devolução - LOG", "U_ZZXD (2)"      ,   0, 4})
	aadd (aRotina, {"Imp.Dados Devolução"   , "U_ZZXIMP ()"     ,   0, 4})
	aadd (aRotina, {"Exporta Dados"         , "U_ZZXEXP ()"     ,   0, 4})
	aadd (aRotina, {"&Controle de Portaria ", "U_VA_CPORT ()"   ,   0, 4})
	aadd (aRotina, {"&Legenda"              , "U_ZZXLEG(.F.)"   ,   0 ,5})

	cPerg   := "ZZX"
	_ValidPerg()
	if U_MsgYesNo ("Aplicar filtros?")
		if Pergunte(cPerg,.T.) 

			dbSelectArea("ZZX")
			DbSetOrder(5)

			_cCondicao :=" ZZX_FILIAL = '" + xfilial("ZZX") + "'"
			_cCondicao +=" .AND. (ZZX_RETSEF     = '100' .OR. ZZX_RETSEF     = '150')
			_cCondicao +=" .AND. ZZX_LAYOUT     != 'ConsNFSeRps'"
			_cCondicao +=" .AND. ZZX_LAYOUT     != 'ConsultaNFS-e'"
			_cCondicao +=" .AND. ZZX_LAYOUT     != 'procEventoNFe'"
			// considera parametros de tela
			if mv_par01 == 1
				_cCondicao +=" .AND. ZZX_STATUS     != '1'"  // documento lançado
				_cCondicao +=" .AND. ZZX_STATUS     != '4'"  // contra nota
				_cCondicao +=" .AND. ZZX_STATUS     != '5'"  // desconsiderado
				_cCondicao +=" .AND. ZZX_STATUS     != '8'"  // nao aceite de operacao
			endif
			
			if mv_par02 == 2 // cte = NAO
				_cCondicao += " .AND. ZZX_LAYOUT != 'procCTe'" 
				_cCondicao += " .AND. ZZX_LAYOUT != 'CTe'"
			endif			

			do case
				case mv_par03 == 1 // SIM - todas as notas 
				case mv_par03 == 2 // Nao
					_cCondicao += " .AND. ZZX_LAYOUT != 'procNFe'"
					_cCondicao += " .AND. ZZX_LAYOUT != 'NFS-e'"        
				case mv_par03 == 3 // devoluçao
					_cCondicao += " .AND. ZZX_TIPONF = 'D'"
				case mv_par03 == 4 // normal
					// testar esse parametro para ver como fica
					_cCondicao += " .AND. (ZZX_TIPONF = 'N' .AND. ZZX_LAYOUT != 'NFS-e')"  // desconsidera notas de serviço
					_cCondicao += " .AND. (ZZX_TIPONF = 'N' .AND. ZZX_TRANSF != 'S')"      // desconsidera notas de transferencia
					_cCondicao +="  .AND. ZZX_CONTRA != 'S'" // desconsidera contra notas SEMPRE
				case mv_par03 == 5 // outras
					_cCondicao += " .AND. ZZX_TIPONF != 'D'" // desconsidera notas de devolução
					_cCondicao += " .AND. (ZZX_LAYOUT = 'NFS-e' .OR. ZZX_TRANSF = 'S' .OR. ZZX_TIPONF = 'B' .OR. ZZX_CONTRA = 'S')"
			endcase
			
			if val(mv_par04) > 0  // seleciona o fornecedor
				_cCondicao += " .AND. ZZX_CLIFOR = '" + mv_par04 + "'"
				_cCondicao += " .AND. (ZZX_TIPONF != 'D' .AND. ZZX_TIPONF != 'B')"
			endif
								
			if val(mv_par05) > 0 // seleciona o cliente
				_cCondicao += " .AND. ZZX_CLIFOR = '" + mv_par05 + "'"
				_cCondicao += " .AND. (ZZX_TIPONF = 'D' .OR. ZZX_TIPONF = 'B')"
			endif
			
			// desconsiderar as serie 20 emitidas pela cooperativa
			_cCondicao += " .AND. .NOT. (ZZX_SERIE ='20' .AND. SUBSTRING(ZZX_CNPJEM,1,8) = '88612486')" // desconsidera notas de complemento
			_bFilBrw := {|| FilBrowse('ZZX',@_aIndBrw,@_cCondicao) }
			Eval(_bFilBrw)
			DbSelectArea('ZZX')
			mBrowse(,,,,'ZZX',,,,,2, _aCores)
			EndFilBrw('ZZX',_aIndBrw)
			DbSelectArea('ZZX')
			DbSetOrder(5) // ordenar por data de emissao
			Eval(_bFilBrw)
			DbClearFilter()
		endif
	else
		mBrowse(,,,,'ZZX',,,,,2, _aCores)
	endif
Return
// ------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function ZZXLEG (_lRetCores)
	local _i       := 0
    local _aCores  := {}
	local _aCores2 := {}
	aadd (_aCores, {"ZZX->ZZX_TIPONF = 'B' .AND. ZZX->ZZX_LAYOUT = 'procNFe'"										  , 'BR_VERMELHO', 'NFe Beneficiamento'})
	aadd (_aCores, {"ZZX->ZZX_TIPONF = 'D' .AND. ZZX->ZZX_RESSAR = '1'"                  							  , 'BR_PINK'    , 'NFe Ressarcimento Imp.'})
	aadd (_aCores, {"ZZX->ZZX_TIPONF = 'D' .AND. ZZX->ZZX_RESSAR != '1' .AND. ZZX->ZZX_IND = '1'"                     , 'BR_MARRON'  , 'NFe Devolução - (Avaria)'})
	aadd (_aCores, {"ZZX->ZZX_TIPONF = 'D' .AND. ZZX->ZZX_RESSAR != '1' .AND. ZZX->ZZX_IND != '1'"       			  , 'BR_AMARELO' , 'NFe Devolução'})
	aadd (_aCores, {"ZZX->ZZX_TIPONF = 'N' .AND. ZZX->ZZX_LAYOUT = 'procNFe' .AND. ZZX->ZZX_TRANSF != 'S'" 			  , 'BR_VERDE'   , 'NFe Normal'})
	aadd (_aCores, {"ZZX->ZZX_TIPONF = 'N' .AND. ZZX->ZZX_LAYOUT !='procNFe' .AND. ZZX->ZZX_CHAVE = 'Nao se aplica'"  , 'BR_AZUL'    , 'NFe Serviço'})
	aadd (_aCores, {"ZZX->ZZX_TIPONF = 'N' .AND. ZZX->ZZX_TRANSF = 'S'"        									      , 'BR_BRANCO'  , 'NFe Transferencia'})
	aadd (_aCores, {"ZZX->ZZX_LAYOUT = 'procCTe'"                            										  , 'BR_LARANJA' , 'CTe'})
	
	if ! _lRetCores
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 2], _aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", _aCores2)
	else
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 1], _aCores [_i, 2]})
		next
		return _aCores
	endif
return
// --------------------------------------------------------------------------
// Vizualizar dados.
user function ZZXV (_nOQueVer)
	local _lContinua := .T.
	local _sNomeArq  := CriaTrab ({}, .F.)
	local _sArq      := ""  // MsDocPath () + "\" + _sNomeArq + ".XML"
	local _sTmpPath  := AllTrim (GetTempPath ())
	local _nHdl      := 0
	local _sArqProg  := ""
	local _sXML      := ""
	local _nOpcao    := 0
	local _oXMLSEF   := NIL
	local _nErro     := 0
	local _nAviso    := 0
	//local _nNota     := 0
	//local _oXMLNota  := NIL
	local _nItem     := 0
	local _aItens    := {}
	local _aCols     := {}
	private altera   := .F.
	private inclui   := .F.
	private aGets    := {}
	private aTela    := {}

	do case
	case _nOQueVer == 1  // Visualizar XML
		_nOpcao = aviso ("Selecione visualizador", ;
			"Selecione o visualizador a ser usado: padrao do sistema operacional ou visualizador do SEFAZ (cfe. infomado nos parametros)", ;
			{"Padrao", "SEFAZ", "Cancelar"}, ;
			3)
	
		if _nOpcao == 2
			if _lContinua .and. empty (mv_par02)
				_Msg ("Configure o caminho do visualizador nos parametros da rotina.")
				_lContinua := .F.
			endif
			_sArqProg = alltrim (mv_par02)
			if _lContinua .and. ! file (_sArqProg)
				_Msg ("Programa '" + _sArqProg + "' nao encontrado. Verifique os parametros da rotina.")
				_lContinua := .F.
			endif
		elseif _nOpcao == 3
			_lContinua := .F.
		endif
	
		// Extrai o XML do arquivo de memos, grava em arquivo temporario, copia esse arquivo
		// para a pasta temporaria da estacao e deleta-o da pasta de documentos
		if _lContinua
			CursorWait ()
			_sXML = MSMM (zzx -> zzx_CodMem,,,,3)
			_sArq = MsDocPath () + "\" + iif (empty (_sNomeArq), CriaTrab ({}, .F.), _sNomeArq) + ".XML"
			_nHdl := MsfCreate (_sArq, 0)
			if fWrite (_nHdl, _sXML) == 0
				_Msg ("Erro na criacao de arquivo temporario para gravacao do XML")
				_lContinua := .F.
			endif
			fClose (_nHdl)
		endif
		if _lContinua
			CpyS2T (_sArq, _sTmpPath, .T.)
			delete file (_sArq)
			CursorArrow ()
			if _nOpcao == 1  // Visualizador padrao da estacao.
				winexec ("cmd /c start " + _sTmpPath + _sNomeArq + ".xml")
			elseif _nOpcao == 2  // Visualizador da SEFAZ.
				winexec ("cmd /c start " + _sArqProg + " -a " + _sTmpPath + _sNomeArq + ".xml")
			endif
		endif
	
	case _nOQueVer == 2  // CFOPs constantes no XML
		_sXML = MSMM (zzx -> zzx_CodMem,,,,3)
		_oXMLSEF := ClsXMLSEF ():New ()
		_oXMLSEF:LeXML (_sXML)
		
		for _nErro = 1 to len (_oXMLSEF:Erros)
			u_help (_oXMLSEF:Erros [_nErro])
		next
		
		for _nAviso = 1 to len (_oXMLSEF:Avisos)
			u_help (_oXMLSEF:Avisos [_nAviso])
		next
		
		if valtype (_oXMLSEF:NFe) == 'O'
			// Monta array com dados dos itens.
			_aItens := {}
			for _nItem = 1 to len (_oXMLSEF:NFe:ItCFOP)
			    _wxmlpro = UPPER(_oXMLSEF:NFe:ItCprod [_nItem])
			    // A5_FILIAL, A5_FORNECE, A5_LOJA, A5_CODPRF, R_E_C_N_O_, D_E_L_E_T_
				_wcodpro = fbuscacpo ("SA5", 14, xfilial ("SA5") + zzx -> zzx_clifor + zzx -> zzx_loja + _wxmlpro,  "A5_PRODUTO") // codigo interno
				aadd (_aItens, {'','','','',0,0,'','','','','','','',''})
				_aItens [_nItem, 1] = _oXMLSEF:NFe:ItCFOP [_nItem] + ' - ' + Tabela ('13', _oXMLSEF:NFe:ItCFOP [_nItem])
				_aItens [_nItem, 2] = _oXMLSEF:NFe:ItDescri [_nItem]
				_aItens [_nItem, 3] = fbuscacpo ("SB1", 1, xfilial ("SB1") + _wcodpro,  "B1_DESC") // descricao interna
				_aItens [_nItem, 4] = _oXMLSEF:NFe:ItXPed  [_nItem]
				_aItens [_nItem, 5] = _oXMLSEF:NFe:ItQuant [_nItem]
				_aItens [_nItem, 6] = _oXMLSEF:NFe:ItVlTot [_nItem]
				_aItens [_nItem, 7] = _wxmlpro
				_aItens [_nItem, 8] = _wcodpro 
				_aItens [_nItem, 9] = _oXMLSEF:NFe:ItuCom [_nItem]
				_aItens [_nItem,10] = fbuscacpo ("SB1", 1, xfilial ("SB1") + _wcodpro,  "B1_UM") // UM interna
				
				if _aItens [_nItem, 9] != _aItens [_nItem, 10]
					_wfator =  fbuscacpo ("SB1", 1, xfilial ("SB1") + _wcodpro,  "B1_CONV") // fator de conversao
					if _wfator > 0 
						_wconversao := 'OK'
					else
						_wconversao := 'NAO INFORMADA'
					endif																	
				else
					_wconversao := "MESMA UNIDADE"
				endif
				_aItens [_nItem,11] = _wconversao 
				_aItens [_nItem,12] = _oXMLSEF:NFe:ItNCM [_nItem]
				_aItens [_nItem,13] = fbuscacpo ("SB1", 1, xfilial ("SB1") + _wcodpro,  "B1_POSIPI") // NCM interna
			next
			
			aadd (_aCols, { 1, 'CFOP',                    40, ''})
			aadd (_aCols, { 2, 'Descricao Item XML',     150, ''})
			aadd (_aCols, { 3, 'Descricao Item Interna', 150, ''})
			aadd (_aCols, { 4, 'Ordem de Compra',         50, ''})
			aadd (_aCols, { 5, 'Quantidade',  		      50, '@E 9,999,999.9999'})
			aadd (_aCols, { 6, 'Vl.total',    		      50, '@E 999,999,999.99'})
			aadd (_aCols, { 7, 'Item XML',    		      70, ''})
			aadd (_aCols, { 8, 'Cod.Interno', 		      40, ''})
			aadd (_aCols, { 9, 'UM XML',     		      30, ''})
			aadd (_aCols, {10, 'UM Interna' ,		      30, ''})
			aadd (_aCols, {11, 'Conversao' ,		      50, ''})
			aadd (_aCols, {12, 'NCM XML',     		      40, ''})
			aadd (_aCols, {13, 'NCM Interna' ,		      40, ''})
			
			u_F3Array (_aItens, 'Itens da nota', _aCols)
		else
			u_help ("Nao encontrei dados de NFe neste XML")
		endif
	case _nOQueVer == 3  // Dados Adicionais da nota - constantes no XML
		_sXML = MSMM (zzx -> zzx_CodMem,,,,3)
		_oXMLSEF := ClsXMLSEF ():New ()
		_oXMLSEF:LeXML (_sXML)
		for _nErro = 1 to len (_oXMLSEF:Erros)
			u_help (_oXMLSEF:Erros [_nErro])
		next
		for _nAviso = 1 to len (_oXMLSEF:Avisos)
			u_help (_oXMLSEF:Avisos [_nAviso])
		next
		if valtype (_oXMLSEF:NFe) == 'O'
			_wdadosaidc = _oXMLSEF:NFe:DadosAdic
			u_showmemo (_wdadosaidc)
		endif			
	endcase
return
// ------------------------------------------------------------------------------------------------------
// CTEs verifica NOTAS
user function ZZXVNFS()
	//local _lContinua := .T.
	local _nErro  := 0
	local _nAviso := 0
	local _nNotas := 0
	
	if alltrim (ZZX->ZZX_LAYOUT) != "procCTe" .and. alltrim (ZZX->ZZX_LAYOUT) != "CTe"  
		u_help("XML selecionado não é de um CTE")
		return
	endif	
	
	// le XML - para buscar a que notas se refere o conhecimento de frete
    _sXML = MSMM (zzx -> zzx_CodMem,,,,3)
	_oXMLSEF := ClsXMLSEF ():New ()
	_oXMLSEF:LeXML (_sXML)
	for _nErro = 1 to len (_oXMLSEF:Erros)
		u_help (_oXMLSEF:Erros [_nErro])
	next
	for _nAviso = 1 to len (_oXMLSEF:Avisos)
		u_help (_oXMLSEF:Avisos [_nAviso])
	next
	
	// busca notas refenciadas e ve se existem no sistema e identifica se sao de entrada ou saida
	_aNotas = {}
	for _nNotas = 1 to len (_oXMLSEF:CTe:ChaveRel)
		_wchave   = _oXMLSEF:CTe:ChaveRel [_nNotas]
		aadd (_aNotas, {'', '', '', '', '', '','','',''})
		// verifica se a chave corresponde a uma nota de saida
		_aNotas [_nNotas, 1] = _wchave
		_wnumnota = fbuscacpo ("SF2", 19, _wchave,  "F2_DOC")
		if val(_wnumnota) > 0
			_aNotas [_nNotas, 2] = fbuscacpo ("SF2", 19, _wchave,  "F2_FILIAL")
			_aNotas [_nNotas, 3] = _wnumnota
			_aNotas [_nNotas, 4] = fbuscacpo ("SF2", 19, _wchave,  "F2_SERIE")
			_aNotas [_nNotas, 5] = fbuscacpo ("SF2", 19, _wchave,  "F2_EMISSAO")
			_wcliente = fbuscacpo ("SF2", 19, _wchave,  "F2_CLIENTE")
			_wcnpj = fbuscacpo ("SA1", 1, xfilial("SA1") + _wcliente + '01',  "A1_CGC")
			_aNotas [_nNotas, 6] = _wcliente + '-' + fbuscacpo ("SA1", 1, xfilial("SA1") + _wcliente + '01',  "A1_NOME")
			_aNotas [_nNotas, 7] = fbuscacpo ("SA1", 1, xfilial("SA1") + _wcliente + '01',  "A1_EST")
			_aNotas [_nNotas, 8] = 'SAIDA'
			_wobs = ''
			if left(_wcnpj,8) = '88612486'  // notas de transferencia
				_wobs = 'NF DE TRANSFERENCIA'
			endif
			_aNotas [_nNotas, 9] = _wobs
			/*
			if left(_wcnpj,8) = '88612486'  // notas de transferencia
				// busca nota de entrada com a mesma chave
				_wnumnota = fbuscacpo ("SF1", 13, _wchave,  "F1_DOC")
				if val(_wnumnota) > 0
					aadd (_aNotas, {'', '', '', '', '', '','','',''})
					_nNotas++
					_aNotas [_nNotas, 1] = _wchave
					_aNotas [_nNotas, 2] = fbuscacpo ("SF1", 13, _wchave,  "F1_FILIAL")
					_aNotas [_nNotas, 3] = _wnumnota
					_aNotas [_nNotas, 4] = fbuscacpo ("SF1", 13, _wchave,  "F1_SERIE")
					_aNotas [_nNotas, 5] = fbuscacpo ("SF1", 13, _wchave,  "F1_EMISSAO")
					_wfornece = fbuscacpo ("SF1", 13, _wchave,  "F1_FORNECE")
					_aNotas [_nNotas, 6] = _wfornece + '-' + fbuscacpo ("SA2", 1, xfilial("SA2") + _wfornece + '01',  "A2_NOME")
					_aNotas [_nNotas, 7] = fbuscacpo ("SA2", 1, xfilial("SA2") + _wfornece + '01',  "A2_EST")
					_wcnpj = fbuscacpo ("SA2", 1, xfilial("SA2") + _wfornece + '01',  "A2_CGC")
					_aNotas [_nNotas, 8] = 'ENTRADA'
					_aNotas [_nNotas, 9] = 'NF DE TRANSFERENCIA'
				endif					
			endif
			*/
		else // verifica nota de entrada			
			_wnumnota = fbuscacpo ("SF1", 13, _wchave,  "F1_DOC")
			if val(_wnumnota) > 0
				_aNotas [_nNotas, 2] = fbuscacpo ("SF1", 13, _wchave,  "F1_FILIAL")
				_aNotas [_nNotas, 3] = _wnumnota
				_aNotas [_nNotas, 4] = fbuscacpo ("SF1", 13, _wchave,  "F1_SERIE")
				_aNotas [_nNotas, 5] = fbuscacpo ("SF1", 13, _wchave,  "F1_EMISSAO")
				_wfornece = fbuscacpo ("SF1", 13, _wchave,  "F1_FORNECE")
				_wtipo = fbuscacpo ("SF1", 13, _wchave,  "F1_TIPO")
				_wobs = ''
				if _wtipo = "D"
					_aNotas [_nNotas, 6] = _wfornece + '-' + fbuscacpo ("SA1", 1, xfilial("SA1") + _wfornece + '01',  "A1_NOME")
					_aNotas [_nNotas, 7] = fbuscacpo ("SA1", 1, xfilial("SA1") + _wfornece + '01',  "A1_EST")
					_aNotas [_nNotas, 8] = 'ENTRADA'
					_wobs = 'DEVOLUCAO'
				else						
					_aNotas [_nNotas, 6] = _wfornece + '-' + fbuscacpo ("SA2", 1, xfilial("SA2") + _wfornece + '01',  "A2_NOME")
					_aNotas [_nNotas, 7] = fbuscacpo ("SA2", 1, xfilial("SA2") + _wfornece + '01',  "A2_EST")
					_wcnpj = fbuscacpo ("SA2", 1, xfilial("SA2") + _wfornece + '01',  "A2_CGC")
					_aNotas [_nNotas, 8] = 'ENTRADA'
					if left(_wcnpj,8) = '88612486'  // notas de transferencia
						_wobs = 'NF DE TRANSFERENCIA'
					endif
				endif					
				_aNotas [_nNotas, 9] = _wobs	
			else
				// seta como NF nao encontrada
				_aNotas [_nNotas, 2] = ''
				_aNotas [_nNotas, 3] = ''
				_aNotas [_nNotas, 4] = ''
				_aNotas [_nNotas, 5] = ''
				_aNotas [_nNotas, 6] = 'NAO IDENTIFICADO'
				_aNotas [_nNotas, 7] = ''
				_aNotas [_nNotas, 8] = 'NAO IDENTIFICADO'
				_aNotas [_nNotas, 9] = 'NF NAO ENCONTRADA NO SISTEMA'
			endif
		endif
	next				
	
	if len(_aNotas) > 0
		_aCols = {}	
		aadd (_aCols, { 1, 'Chave NF',      	 80, ''})
		aadd (_aCols, { 2, 'Filial',      	     40, ''})			
		aadd (_aCols, { 3, 'Numero NF',     	 50, ''})
		aadd (_aCols, { 4, 'Serie',         	 20, ''})
		aadd (_aCols, { 5, 'Emissao',       	 50, ''})
		aadd (_aCols, { 6, 'Cliente/Fornecedor', 70, ''})
		aadd (_aCols, { 7, 'UF',            	 20, ''})
		aadd (_aCols, { 8, 'Tipo',         		 40, ''})
		aadd (_aCols, { 9, 'Observação',   		 70, ''})
		
		u_F3Array (_aNotas, 'Notas Relacionadas no XML de CTE', _aCols)
	else
		u_help ("Nao foi possivel ler a TAG de notas relacionadas deste XML")
	endif
return
// ------------------------------------------------------------------------------------------------------
// Exclusao
user function ZZXE (_lAuto)
	local _lContinua := .T.
	local _sCodmemo  := zzx -> zzx_CodMem
	local _sCodm2    := zzx -> zzx_CodM2
	local _oEvento   := NIL
	local _sChave    := zzx -> zzx_chave
	private altera   := .F.
	private inclui   := .F.
	private aGets    := {}
	private aTela    := {}

	if ! _lAuto
		if  ! u_zzuvl ('025', __cUserId, .T.)  // se vem direto do menu testa as permissoes pra excluir
//			return
			_lContinua = .F.
		endif
	endif
	
	if _lContinua .and. ! _lAuto 
		sf1 -> (dbsetorder (8))  // F1_FILIAL+F1_CHAVE
		if sf1 -> (dbseek (xfilial ("SF1") + zzx -> zzx_chave, .F.))
			u_help ("Existe no sistema a nota fiscal referente a este XML. Exclusão não permitida.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		if _lAuto
			reclock ("ZZX", .F.)
			zzx -> (dbdelete ())
			msunlock ()
		else
			// Cria variaveis M->... para a enchoice (a funcao nao cria sozinha)
			RegToMemory ("ZZX", inclui, inclui)

			if AxDeleta ("ZZX", zzx -> (recno ()), 5) != 2
				_lContinua = .F.
			endif
		endif

		// Exclui campos memo.
		if _lContinua .and. ! empty (_sCodMemo)
			msmm (_sCodMemo,,,, 2,,, "ZZX", "ZZX_CODMEM")
		endif
		if _lContinua .and. ! empty (_sCodM2)
			msmm (_sCodM2  ,,,, 2,,, "ZZX", "ZZX_CODM2")
		endif

		// Grava evento temporario
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven   = "ZZX002"
		_oEvento:Texto     = "Finalizada exclusao do ZZX"
		_oEvento:Alias     = "ZZX"
		_oEvento:Recno     = zzx -> (recno ())
		_oEvento:ChaveNFe  = cvaltochar (_sChave)
		_oEvento:DiasValid = 60  // Manter o evento por alguns dias, depois disso vai ser deletado.
		_oEvento:Grava ()
	endif
return
// ------------------------------------------------------------------------------------------------------
// Marca como Contra Nota
user function ZZXM ()
	
	if zzx -> zzx_tiponf = 'D'
		u_help ("XML selecionado é referente a uma nota de devolução. Opção não permitida.")
		return
	endif

	_lRet = U_MsgNoYes ("Marca XML como Contra Nota ?")
	if _lRet = .F.
		return
	endif
	
	reclock("ZZX", .F.)
	   	ZZX->ZZX_CONTRA  = 'S'
	   	ZZX->ZZX_AJMAN   = 'S'
	   	ZZX->ZZX_STATUS  = '4'
	   	ZZX->ZZX_CSTAT   = dtoc(date()) + ' - ' + time() + ' - ' + substr (cUserName ,1,15)
	   	ZZX->ZZX_JUSTAJ  = 'Conta Nota - ' +  alltrim (cUserName) + ' - ' + substr (dtos (date ()),7,2) + '/' + substr (dtos (date ()),5,2) + '/' + substr (dtos (date ()),1,4) 
	MsUnLock()
	
return
// ------------------------------------------------------------------------------------------------------
// Desconsidera NF de Serviço
user function ZZXN ()
	
	if zzx -> zzx_tiponf = 'D'
		u_help ("XML selecionado é referente a uma nota de devolução. Opção não permitida.")
		return
	endif
	
	_lRet = U_MsgNoYes ("Desconsidera XML Pendente - NF Serviço ?")
	if _lRet = .F.
		return
	endif
	
	reclock("ZZX", .F.)
	   	ZZX->ZZX_CONTRA  = 'S'
	   	ZZX->ZZX_AJMAN   = 'S'
	   	ZZX->ZZX_STATUS  = '5'
	   	ZZX->ZZX_CSTAT   = dtoc(date()) + ' - ' + time() + ' - ' + substr (cUserName ,1,15)
	   	ZZX->ZZX_JUSTAJ  = 'NF Serviço - ' +  alltrim (cUserName) + ' - ' + substr (dtos (date ()),7,2) + '/' + substr (dtos (date ()),5,2) + '/' + substr (dtos (date ()),1,4) 
	MsUnLock()
return
// ------------------------------------------------------------------------------------------------------
// Não aceite de operação
user function ZZXO ()
	_lRet = .T.
	
	_lRet = U_MsgNoYes ("Confirma Não Aceite da Operação ?")
	if _lRet = .F.
		return
	endif
	
	_wprotocolo = U_Get ("Informe o ID do Evento de Não Aceite da Operação:", 'C', 54, '', '', space(54), .F., '.T.')
	if empty(_wprotocolo) 
		msgalert("Deve ser informado o ID do Evento.","AVISO")
		_lRet = .F.
	endif
	if _lRet .and. len(alltrim(_wprotocolo)) != 54
		msgalert("Protocolo Invalido, deve conter 54 caracteres","AVISO")
		_lRet = .F.
	endif
	if _lRet .and. substr(_wprotocolo,1,2) != 'ID'
		msgalert("Protocolo Invalido, deve iniciar com ID","AVISO")
		_lRet = .F.
	endif
	
	if _lRet
		reclock("ZZX", .F.)
	   		ZZX->ZZX_AJMAN   = 'S'
	   		ZZX->ZZX_STATUS  = '8'
	   		ZZX->ZZX_CSTAT   = dtoc(date()) + ' - ' + time() + ' - ' + substr (cUserName ,1,15)
	   		ZZX->ZZX_ERRO    = _wprotocolo
	   		ZZX->ZZX_JUSTAJ  = 'Não Aceite de Operação - ' +  alltrim (cUserName) + ' - ' + substr (dtos (date ()),7,2) + '/' + substr (dtos (date ()),5,2) + '/' + substr (dtos (date ()),1,4)
	   	MsUnLock()
	endif			   	
return
// ------------------------------------------------------------------------------------------------------
// Informa dados referentes a devolução
user function ZZXD (_wtpdados)

	//local _lContinua   := .T.
	//local _sArq        := "" 
	//local _sTmpPath    := AllTrim (GetTempPath ())
	//local _nHdl        := 0
	//local _sArqProg    := ""
	local _sXML        := ""
	local _oXMLSEF     := NIL
	//local _nNota       := 0
	//local _oXMLNota    := NIL
	local _nItem       := 0
	local _aItens      := {}
	//local _aCols       := {}
	local _bBotaoOK    := {|| NIL}
	local _bBotaoCan   := {|| NIL}
	local _aBotAdic    := {}
	local _aSize       := {}
	local _aHead1      := {}
	//local _aCampos     := {}
	//local _aArqTrb     := {}
	local _oDlg        := NIL
	local _oCour24     := TFont():New("Courier New",,24,,.T.,,,,,.F.)
    //local _sQuery      := ""
	//local _sAliasQ     := ""
	//local _aRetQry     := {}
	local _nErro	   := 0
	local _nAviso	   := 0
	//local _nItem       := 0
	//local _n		   := 1
	private _oTxtBrw1  := NIL
	private _oGetD1    := NIL
	private aHeader    := {}
	private aCols      := {}
	private _aCols1    := {}
	private N          := 1
	private aGets      := {}
	private aTela      := {}
	private aRotina    := {{"BlaBlaBla", "allwaystrue ()", 0, 1}, ;
	                      {"BlaBlaBla", "allwaystrue ()", 0, 2}, ;
	                      {"BlaBlaBla", "allwaystrue ()", 0, 3}, ;
	                      {"BlaBlaBla", "allwaystrue ()", 0, 4}}  // aRotina eh exigido pela MSGetDados!!!
		
	if zzx -> zzx_tiponf != 'D'
		u_help ("XML selecionado não é referente a uma nota de devolução.")
		return
	endif
	
	if _wtpdados = 1
		// informar os dados de devolucao do comercial
		if zzx -> zzx_status = 'A' 
			u_help ("Status aguardando retorno da logistica; não é possivel informar dados devolução")
			return
		endif
		
		//if val(zzx -> zzx_status) > 0 .and. val(zzx -> zzx_status) <> 6 .and. val(zzx -> zzx_status) <> 9 .and. val(zzx -> zzx_status) <> 3 .and. val(zzx -> zzx_status) <> 1 
		  if val(zzx -> zzx_status) > 0 .and. val(zzx -> zzx_status) <> 6 .and. val(zzx -> zzx_status) <> 9 .and. val(zzx -> zzx_status) <> 3 
		   	u_help ("Status não permite alterar/informar dados devolução")
			return
		endif
		
		//if ! u_zzuvl ('088', __cUserId, .T.)
			//return
		//endif
		
		aHeader = aclone (U_GeraHead ("ZZZ", .T., {}, {"ZZZ_12XIT", "ZZZ_12XPRO", "ZZZ_12XDES", "ZZZ_12XUN", "ZZZ_12XQUA", "ZZZ_12CPRO", "ZZZ_12DESC", "ZZZ_12UN", "ZZZ_12QUAN", "ZZZ_12MDEV", "ZZZ_12NFOR", "ZZZ_12NIOR", "ZZZ_12RET", "ZZZ_12TES", ,"ZZZ_12VORI","ZZZ_12VDEV","ZZZ_12USER", "ZZZ_12DATA", "ZZZ_12HORA"}, .T.))
		_aHead1 := aclone (aHeader)
		_aCols1 = {}
		_aLinVazia := aclone (U_LinVazia (aHeader))
		
		_sXML = MSMM (zzx -> zzx_CodMem,,,,3)
		_oXMLSEF := ClsXMLSEF ():New ()
		_oXMLSEF:LeXML (_sXML)
		for _nErro = 1 to len (_oXMLSEF:Erros)
			u_help (_oXMLSEF:Erros [_nErro])
		next
		for _nAviso = 1 to len (_oXMLSEF:Avisos)
			u_help (_oXMLSEF:Avisos [_nAviso])
		next
		
		if valtype (_oXMLSEF:NFe) == 'O'
			// Monta array com dados dos itens.
			_aItens = {}
			for _nItem = 1 to len (_oXMLSEF:NFe:ItCFOP)
				aCols = {}
	            aadd (aCols, aclone (_aLinVazia))
	            
	            DbSelectArea("ZAJ")
				DbSetOrder(1)
	            if ! DbSeek( ZZX -> ZZX_FILIAL + ZZX -> ZZX_CHAVE + strzero(_nItem,4), .F.)
	            	GDFieldPut ("ZZZ_12XIT" , strzero(_nItem,4))
	            	GDFieldPut ("ZZZ_12XPRO", UPPER(_oXMLSEF:NFe:ItCprod  [_nItem] ))
	            	GDFieldPut ("ZZZ_12XDES", _oXMLSEF:NFe:ItDescri [_nItem])
	            	GDFieldPut ("ZZZ_12XUN" , _oXMLSEF:NFe:ItuCom   [_nItem])
	            	GDFieldPut ("ZZZ_12XQUA", _oXMLSEF:NFe:ItQuant  [_nItem])
	            	GDFieldPut ("ZZZ_12CPRO", space(15))
	            	GDFieldPut ("ZZZ_12DESC", space(40))
	            	GDFieldPut ("ZZZ_12UN"  , space(2))
	            	GDFieldPut ("ZZZ_12QUAN", 0)
	            	GDFieldPut ("ZZZ_12MDEV", space(2))
	            	GDFieldPut ("ZZZ_12NFOR", space(9))
	            	GDFieldPut ("ZZZ_12NIOR", space(4))
	            	GDFieldPut ("ZZZ_12TES" , SPACE(3))
	            	GDFieldPut ("ZZZ_12RET" , SPACE(1))
	            	GDFieldPut ("ZZZ_12USER", cusername)
	            	GDFieldPut ("ZZZ_12DATA", date() )
	            	GDFieldPut ("ZZZ_12HORA", time() )
	            	GDFieldPut ("ZZZ_12VORI" , SPACE(6))
	            	GDFieldPut ("ZZZ_12VDEV" , SPACE(6))
				else
					// le dados de devolucao ja informados
					DbSelectArea("ZAJ")
					DbSetOrder(1)
					if DbSeek( ZZX -> ZZX_FILIAL + ZZX -> ZZX_CHAVE + strzero(_nItem,4), .F.)
						GDFieldPut ("ZZZ_12XIT" , ZAJ -> ZAJ_XITEM)
	            		GDFieldPut ("ZZZ_12XPRO", ZAJ -> ZAJ_XPROD)
	            		GDFieldPut ("ZZZ_12XDES", ZAJ -> ZAJ_XDESC)
	            		GDFieldPut ("ZZZ_12XUN" , ZAJ -> ZAJ_XUN)
	            		GDFieldPut ("ZZZ_12XQUA", ZAJ -> ZAJ_XQUANT)
	            		GDFieldPut ("ZZZ_12CPRO", ZAJ -> ZAJ_CPROD)
	            		GDFieldPut ("ZZZ_12DESC", fbuscacpo ("SB1", 1, xfilial ("SB1") + ZAJ -> ZAJ_CPROD,  "B1_DESC"))
	            		GDFieldPut ("ZZZ_12UN"  , ZAJ -> ZAJ_UN)
	            		GDFieldPut ("ZZZ_12QUAN", ZAJ -> ZAJ_QUANT)
	            		GDFieldPut ("ZZZ_12MDEV", ZAJ -> ZAJ_MOTDEV)
	            		GDFieldPut ("ZZZ_12NFOR", ZAJ -> ZAJ_NFORIG)
	            		GDFieldPut ("ZZZ_12NIOR", ZAJ -> ZAJ_ITORIG)
	            		GDFieldPut ("ZZZ_12RET" , ZAJ -> ZAJ_RETOR)
	            		GDFieldPut ("ZZZ_12TES" , ZAJ -> ZAJ_TES)
	            		GDFieldPut ("ZZZ_12USER", ZAJ -> ZAJ_USER)
	            		GDFieldPut ("ZZZ_12DATA", ZAJ -> ZAJ_DATA)
	            		GDFieldPut ("ZZZ_12HORA", ZAJ -> ZAJ_HORA)
	            		GDFieldPut ("ZZZ_12VORI", ZAJ -> ZAJ_VEND)
	            		GDFieldPut ("ZZZ_12VDEV", ZAJ -> ZAJ_VENDDV)
	            	endif
				endif            	
				aadd (_aCols1, aclone (aCols [1]))
				
			next
			// Define tamanho da tela.
	        _aSize := MsAdvSize()
	
	        define MSDialog _oDlg from _aSize [1], _aSize [1] to _aSize [6], _aSize [5] of oMainWnd pixel title "Dados Devolução"
	
	        //                        Linha                         Coluna                      bTxt oWnd   pict oFont     ?    ?    ?    pixel corTxt    corBack larg                          altura
	        _oTxtBrw1 := tSay ():New (15,                           7,                          NIL, _oDlg, NIL, _oCour24, NIL, NIL, NIL, .T.,  CLR_BLUE, NIL,    _oDlg:nClientWidth / 2 - 90,  25)
	        _oGetD1 := MsNewGetDados ():New (40, ;                // Limite superior
	                                    5, ;                     // Limite esquerdo
	                                    _oDlg:nClientHeight / 2 - 28, ;      // Limite inferior
	                                    _oDlg:nClientWidth / 2 - 10, ;       // Limite direito    // _oDlg:nClientWidth / 5 - 5, ;                     // Limite direito
	                                    GD_UPDATE, ; // [ nStyle ]
	                                    "U_ValLinDev (1)", ;  // Linha OK
	                                    "AllwaysTrue ()", ;  //[ uTudoOk ]
	                                    NIL, ; //[cIniCpos]
	                                    NIL,; //[ aAlter ]
	                                    NIL,; // [ nFreeze ]
	                                    len (_aCols1),; // [ nMax ]
	                                    NIL,; // [ cFieldOk ]
	                                    NIL,; // [ uSuperDel ]
	                                    NIL,; // [ uDelOk ]
	                                    _oDlg,; // [ oWnd ]
	                                    _aHead1,; // [ ParHeader ]
	                                    _aCols1) // [ aParCols ]
	        
	         // Define botoes para a barra de ferramentas
	        
	        _bBotaoOK  = {|| processa ({||_Grava (1)}), _oDlg:End ()}
	        
			_bBotaoCan = {|| _oDlg:End ()}
	        
	        activate dialog _oDlg on init (EnchoiceBar (_oDlg, _bBotaoOK, _bBotaoCan,, _aBotAdic), _oGetD1:oBrowse:SetFocus (), "")
	
	    endif
	else
		// informar os dados de devolucao da logistica
		if zzx -> zzx_status = '6' .or. zzx -> zzx_status = '9'  
			u_help ("Status não permite alterar/informar dados devolução da logistica")
			return
		endif
		
		//aHeader = aclone (U_GeraHead ("ZZZ", .T., {}, {"ZZZ_12LUSE", "ZZZ_12LDAT", "ZZZ_12LHR","ZZZ_12LMOV", "ZZZ_12DESM", "ZZZ_12LAVA", "ZZZ_12LFM", "ZZZ_12LRM", "ZZZ_12PRM"}, .T.))
		aHeader = aclone (U_GeraHead ("ZZZ", .T., {}, {"ZZZ_12LUSE", "ZZZ_12LDAT", "ZZZ_12LHR","ZZZ_12LMOV", "ZZZ_12LAVA", "ZZZ_12LFM", "ZZZ_12LRM", "ZZZ_12PRM", "ZZZ_12CTRN"}, .T.))
		_aHead1 := aclone (aHeader)
		_aCols1 = {}
		_aLinVazia := aclone (U_LinVazia (aHeader))
		
		for _nItem = 1 to 1
			aCols = {}
	        aadd (aCols, aclone (_aLinVazia))
	        
		    DbSelectArea("ZAJ")
			DbSetOrder(1)
		    if ! DbSeek( ZZX -> ZZX_FILIAL + ZZX -> ZZX_CHAVE + 'L001', .F.) // ITEM UNICO PARA OS DADOS DA LOGISTICA
		    	GDFieldPut ("ZZZ_12LUSE" , cusername)
		    	GDFieldPut ("ZZZ_12LDAT" , date() )
		    	GDFieldPut ("ZZZ_12LHR" , time() )
		    	GDFieldPut ("ZZZ_12LMOV"  , space(2))
		    	//GDFieldPut ("ZZZ_12DESM"  , space(30))
		    	GDFieldPut ("ZZZ_12LAVA"  , space(1))
		    	GDFieldPut ("ZZZ_12LFM"   , space(1))
		    	GDFieldPut ("ZZZ_12LRM"   , SPACE(1))
		    	GDFieldPut ("ZZZ_12PRM"   , DATE() + 4)
		    	GDFieldPut ("ZZZ_12CTRN"   , SPACE(1))
			else
				// le dados de devolucao ja informados
				DbSelectArea("ZAJ")
				DbSetOrder(1)
				if DbSeek( ZZX -> ZZX_FILIAL + ZZX -> ZZX_CHAVE + 'L001', .F.)
					GDFieldPut ("ZZZ_12LUSE" , ZAJ -> ZAJ_LUSER)
		    		GDFieldPut ("ZZZ_12LDAT" , ZAJ -> ZAJ_LDATA)
		    		GDFieldPut ("ZZZ_12LHR"  , ZAJ -> ZAJ_LHORA)
					GDFieldPut ("ZZZ_12LMOV" , ZAJ -> ZAJ_LMOV)
					//GDFieldPut ("ZZZ_12DESM" , left( fBuscaCpo ("ZX5", 1, xfilial ("ZX5") + '02' + GDFieldGet ("ZZZ_12LMOV") , "ZX5_02DESC") ,23) )
		    		GDFieldPut ("ZZZ_12LAVA" , ZAJ -> ZAJ_LAVA)
		    		GDFieldPut ("ZZZ_12LFM"  , ZAJ -> ZAJ_LFM)
		    		GDFieldPut ("ZZZ_12LRM"  , ZAJ -> ZAJ_LRM)
		    		GDFieldPut ("ZZZ_12PRM"  , ZAJ -> ZAJ_LPRM)
		    		GDFieldPut ("ZZZ_12CTRN" , ZAJ -> ZAJ_CTRN)
		    	endif
			endif            	
		
			aadd (_aCols1, aclone (aCols [1]))
		next		
				
		// Define tamanho da tela.
        _aSize := MsAdvSize()

        define MSDialog _oDlg from _aSize [1], _aSize [1] to _aSize [6], _aSize [5] of oMainWnd pixel title "Dados Devolução"

        //                        Linha                         Coluna                      bTxt oWnd   pict oFont     ?    ?    ?    pixel corTxt    corBack larg                          altura
        _oTxtBrw1 := tSay ():New (15,                           7,                          NIL, _oDlg, NIL, _oCour24, NIL, NIL, NIL, .T.,  CLR_BLUE, NIL,    _oDlg:nClientWidth / 2 - 90,  25)
        _oGetD1 := MsNewGetDados ():New (40, ;                // Limite superior
                                    5, ;                     // Limite esquerdo
                                    _oDlg:nClientHeight / 2 - 28, ;      // Limite inferior
                                    _oDlg:nClientWidth / 2 - 10, ;       // Limite direito    // _oDlg:nClientWidth / 5 - 5, ;                     // Limite direito
                                    GD_UPDATE, ; // [ nStyle ]
                                    "U_ValLinDev (2)", ;  // Linha OK
                                    "AllwaysTrue ()", ;  //[ uTudoOk ]
                                    NIL, ; //[cIniCpos]
                                    NIL,; //[ aAlter ]
                                    NIL,; // [ nFreeze ]
                                    len (_aCols1),; // [ nMax ]
                                    NIL,; // [ cFieldOk ]
                                    NIL,; // [ uSuperDel ]
                                    NIL,; // [ uDelOk ]
                                    _oDlg,; // [ oWnd ]
                                    _aHead1,; // [ ParHeader ]
                                    _aCols1) // [ aParCols ]
        
         // Define botoes para a barra de ferramentas
        
        _bBotaoOK  = {|| processa ({||_Grava (2)}), _oDlg:End ()}
        
		_bBotaoCan = {|| _oDlg:End ()}
        
        activate dialog _oDlg on init (EnchoiceBar (_oDlg, _bBotaoOK, _bBotaoCan,, _aBotAdic), _oGetD1:oBrowse:SetFocus (), "")

    endif
return
// ------------------------------------------------------------------------------------------------------
//
user function ValLinDev (_wtpdados)
	local i 	:= 0
	_lcontinua  := .T.

	if _wtpdados = 1

		if val(GDFieldGet ("ZZZ_12NFOR")) = 0
			msgalert("Informar a NF original, referente a venda do item devolvido.","AVISO")
			_lcontinua = .F.
		endif
		
		if val(GDFieldGet ("ZZZ_12NIOR")) = 0
			msgalert("Informar o item da NF original, referente a venda do item devolvido.","AVISO")
			_lcontinua = .F.
		endif
		
		if val(GDFieldGet ("ZZZ_12CPRO")) = 0
			msgalert("Informar o codigo interno do item que esta sendo devolvido.","AVISO")
			_lcontinua = .F.
		endif
		
		if val(GDFieldGet ("ZZZ_12MDEV")) = 0
			msgalert("Informar o motivo da devolução.","AVISO")
			_lcontinua = .F.
		endif
		
		if GDFieldGet ("ZZZ_12QUAN") = 0
			msgalert("Informar quantidade devolvida.","AVISO")
			_lcontinua = .F.
		endif
		
		if val(GDFieldGet ("ZZZ_12VDEV")) = 0
			msgalert("Deve ser informado o vendedor para a devolução.","AVISO")
			_lcontinua = .F.
		endif
		// VERIFICAR SE O MOTIVO DE DEVOLUCAO ESTA ATIVO
		if _lcontinua 
			_sQuery := ""
			_sQuery += "SELECT ZX5_02ATIV
	  		_sQuery += "  FROM ZX5010
	 		_sQuery += " WHERE ZX5_TABELA = '02'
	   		_sQuery += "   AND ZX5_02MOT = '" + GDFieldGet ("ZZZ_12MDEV") + "'"
			_aDados := U_Qry2Array(_sQuery)
			if len (_aDados) = 1
				if _aDados[1,1] != 'S'
		    		msgalert("Motivo de devolucao inativo.","AVISO")
		    		_lcontinua = .F.
				endif	    		
		    endif
	    endif
		
		// valida se o produto x nota x item
		if _lcontinua 
			_sQuery := ""
		    _sQuery += "SELECT D2_ITEM, D2_QTDEDEV, D2_QUANT, D2_PRCVEN"
		  	_sQuery += "  FROM SD2010
		 	_sQuery += " WHERE D2_FILIAL  = '" + ZZX->ZZX_FILIAL + "'"
		   	_sQuery += "   AND D2_CLIENTE = '" + ZZX->ZZX_CLIFOR + "'"
		   	_sQuery += "   AND D2_DOC     = '" + GDFieldGet ("ZZZ_12NFOR") + "'"
		   	_sQuery += "   AND D2_COD     = '" + GDFieldGet ("ZZZ_12CPRO") + "'"
		   	_sQuery += "   AND D2_ITEM    = '" + GDFieldGet ("ZZZ_12NIOR") + "'"

		   	_aDados := U_Qry2Array(_sQuery)
			if len (_aDados) = 0
		    	msgalert("Produto x Item x Nota não conferem. Verifique!","AVISO")
		    	_lcontinua = .F.
		    endif
	    endif
	    if _lcontinua
	    	for i=1 to len(_aDados)
				if _aDados[i,1] = GDFieldGet ("ZZZ_12NIOR")
//					if _aDados[i,2] >= GDFieldGet ("ZZZ_12QUAN")
//						msgalert("Quantidade já devolvida maior ou igual a quantidade que consta na nota de devolução. Verifique!")
//						_lcontinua = .F.	 
//					endif
					//if _aDados[i,3] >= GDFieldGet ("ZZZ_12QUAN")
					//if GDFieldGet ("ZZZ_12QUAN") >= _aDados[i,3]	
					if GDFieldGet ("ZZZ_12QUAN") > _aDados[i,3]			
						msgalert("Quantidade que consta na nota de devolução, maior que a quantidade faturada na nota original referenciada. Verifique!","AVISO")
						_lcontinua = .F.	 
					endif
					if (_aDados[i,2] + GDFieldGet ("ZZZ_12QUAN")) > _aDados[i,3] 
						msgalert("Já existe quantidade devolvida. A soma da qtde ja devolvida com essa nota de devolução seria maior que a quantidade faturada da nota original referenciada. Verifique!","AVISO")
						_lcontinua = .F.	 
					endif
				endif
				exit
			next
		endif
	else
		if val(GDFieldGet ("ZZZ_12LMOV")) = 0
			msgalert("Informar o motivo da devolução.","AVISO")
			_lcontinua = .F.
		endif
		
		// VERIFICAR SE O MOTIVO DE DEVOLUCAO ESTA ATIVO
		if _lcontinua 
			_sQuery := ""
			_sQuery += "SELECT ZX5_02ATIV
	  		_sQuery += "  FROM ZX5010
	 		_sQuery += " WHERE ZX5_TABELA = '02'
	   		_sQuery += "   AND ZX5_02MOT = '" + GDFieldGet ("ZZZ_12LMOV") + "'"
			_aDados := U_Qry2Array(_sQuery)
			if len (_aDados) = 1
				if _aDados[1,1] != 'S'
		    		msgalert("Motivo de devolucao inativo.","AVISO")
		    		_lcontinua = .F.
				endif	    		
		    endif
	    endif
	    
	    if _lcontinua .and. val(GDFieldGet ("ZZZ_12LPRM")) < date()
			msgalert("Data de Previsão de Retorno Invalida","AVISO")
			_lcontinua = .F.
		endif
	
	endif
	
return _lcontinua		
// ------------------------------------------------------------------------------------------------------
// Gravacao dos dados.
static function _Grava (_wtpdados)
	local i  := 0
	local _n := 1
	
	aHeader := aclone (_oGetD1:aHeader)
	aCols   := aclone (_oGetD1:aCols)
	_lcontinua := .T.
	
	CursorWait ()
	
	if _wtpdados = 1
	
		if ! u_zzuvl ('088', __cUserId, .T.)
			return
		endif
	
		_wavaria  = '0'
		_wparcial = 0
		
		for _n = 1 to len (aCols)
			N := _n
			// verifica se informou os dados de devolucao do item
			if val(GDFieldGet ("ZZZ_12CPRO")) = 0 .and. val(GDFieldGet ("ZZZ_12MDEV")) = 0
				_wparcial := 1
				loop
			endif
			
		    // refaz as validações
			if val(GDFieldGet ("ZZZ_12NFOR")) = 0
				msgalert("Informar a NF original, referente a venda do item devolvido.","AVISO")
				_lcontinua := .F.
			endif
		
			if val(GDFieldGet ("ZZZ_12NIOR")) = 0
				msgalert("Informar o item da NF original, referente a venda do item devolvido.","AVISO")
				_lcontinua := .F.
			endif
		
			
			if GDFieldGet ("ZZZ_12QUAN") = 0
				msgalert("Informar quantidade devolvida.","AVISO")
				_lcontinua := .F.
			endif
			
			if val(GDFieldGet ("ZZZ_12VDEV")) = 0
				msgalert("Informar quantidade devolvida.","AVISO")
				_lcontinua := .F.
			endif
			
			// VERIFICAR SE O MOTIVO DE DEVOLUCAO ESTA ATIVO
			if _lcontinua 
				_sQuery := ""
				_sQuery += "SELECT ZX5_02ATIV
		  		_sQuery += "  FROM ZX5010
		 		_sQuery += " WHERE ZX5_TABELA = '02'
		   		_sQuery += "   AND ZX5_02MOT = '" + GDFieldGet ("ZZZ_12MDEV") + "'"
				_aDados := U_Qry2Array(_sQuery)
				if len (_aDados) = 1
					if _aDados[1,1] != 'S'
			    		msgalert("Motivo de devolucao inativo.","AVISO")
			    		_lcontinua := .F.
					endif	    		
			    endif
		    endif
						
			// valida se o produto x nota x item
			if _lcontinua 
				_sQuery := ""
			    _sQuery += "SELECT D2_ITEM, D2_QTDEDEV, D2_QUANT, D2_PRCVEN"
			  	_sQuery += "  FROM SD2010"
			 	_sQuery += " WHERE D2_FILIAL  = '" + ZZX-> ZZX_FILIAL + "'"
			   	_sQuery += "   AND D2_CLIENTE = '" + ZZX-> ZZX_CLIFOR + "'"
			   	_sQuery += "   AND D2_DOC     = '" + GDFieldGet ("ZZZ_12NFOR") + "'"
			   	_sQuery += "   AND D2_COD     = '" + GDFieldGet ("ZZZ_12CPRO") + "'"
			   	_sQuery += "   AND D2_ITEM    = '" + GDFieldGet ("ZZZ_12NIOR") + "'"	

			   	_aDados := U_Qry2Array(_sQuery)
				if len (_aDados) = 0
			    	msgalert("Produto x Item x Nota não conferem. Verifique!","AVISO")
			    	_lcontinua := .F.
			    endif
		    endif
		    // valida quantidade já devolvida
		    if _lcontinua
		    	for i=1 to len(_aDados)
					if _aDados[i,1] = GDFieldGet ("ZZZ_12NIOR")
//						if _aDados[i,2] >= GDFieldGet ("ZZZ_12QUAN")
//							msgalert("Quantidade já devolvida maior ou igual a quantidade que consta na nota de devolução. Verifique!")
//							_lcontinua = .F.	 
//						endif
						//if _aDados[i,3] >= GDFieldGet ("ZZZ_12QUAN")
						if GDFieldGet ("ZZZ_12QUAN") > _aDados[i,3]	
							msgalert("Quantidade que consta na nota de devolução, maior que a quantidade faturada na nota original referenciada. Verifique!","AVISO")
							_lcontinua = .F.	 
						endif
						if (_aDados[i,2] + GDFieldGet ("ZZZ_12QUAN")) > _aDados[i,3] 
							msgalert("Já existe quantidade devolvida. A soma da qtde ja devolvida com essa nota de devolução seria maior que a quantidade faturada da nota original referenciada. Verifique!","AVISO")
							_lcontinua = .F.	 
						endif
					endif
					exit
				next		
			endif
			
			if _lcontinua
				// grava na tabela ZAJ
				DbSelectArea("ZAJ")
				DbSetOrder(1)
				if DbSeek( ZZX -> ZZX_FILIAL + ZZX -> ZZX_CHAVE + GDFieldGet ("ZZZ_12XIT"),.F.)
					RecLock("ZAJ", .F.)
				else
					RecLock("ZAJ", .T.)
				endif			
				ZAJ->ZAJ_FILIAL = ZZX -> ZZX_FILIAL
				ZAJ->ZAJ_CHAVE  = ZZX -> ZZX_CHAVE
				ZAJ->ZAJ_XITEM  = GDFieldGet ("ZZZ_12XIT")
				ZAJ->ZAJ_XPROD  = alltrim(GDFieldGet ("ZZZ_12XPRO"))
				ZAJ->ZAJ_XDESC  = alltrim(GDFieldGet ("ZZZ_12XDES"))
				ZAJ->ZAJ_XQUANT = GDFieldGet ("ZZZ_12XQUA")
				ZAJ->ZAJ_XUN    = GDFieldGet ("ZZZ_12XUN")
				ZAJ->ZAJ_NFORIG = GDFieldGet ("ZZZ_12NFOR")
				ZAJ->ZAJ_SORIG  = '10 '
				ZAJ->ZAJ_ITORIG = GDFieldGet ("ZZZ_12NIOR")
				ZAJ->ZAJ_CPROD  = GDFieldGet ("ZZZ_12CPRO")
				ZAJ->ZAJ_QUANT  = GDFieldGet ("ZZZ_12QUAN")
				ZAJ->ZAJ_UN     = GDFieldGet ("ZZZ_12UN")
				ZAJ->ZAJ_MOTDEV = GDFieldGet ("ZZZ_12MDEV")
				ZAJ->ZAJ_USER   = GDFieldGet ("ZZZ_12USER")
				ZAJ->ZAJ_TES    = GDFieldGet ("ZZZ_12TES")
				ZAJ->ZAJ_RETOR  = GDFieldGet ("ZZZ_12RET")
				ZAJ->ZAJ_TESDEV = fbuscacpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("ZZZ_12TES"), "F4_TESDV")
				ZAJ->ZAJ_VEND       = GDFieldGet ("ZZZ_12ORI")
				ZAJ->ZAJ_VENDDV     = GDFieldGet ("ZZZ_12VDEV") 

				if ZAJ->ZAJ_USER = ''
					// se ja existiam os dados de devolução e atualizou - altera usuario/data e hora
					ZAJ->ZAJ_USER   = cusername
					ZAJ->ZAJ_DATA   = date()
					ZAJ->ZAJ_HORA   = substr(time(),1,5)
				else
					ZAJ->ZAJ_DATA   = GDFieldGet ("ZZZ_12DATA")
					ZAJ->ZAJ_HORA   = substr(GDFieldGet ("ZZZ_12HORA"),1,5)
				endif
					
				MsUnLock()
			endif
			if GDFieldGet ("ZZZ_12RET") = '2'
				_wavaria = '1'	// se nao retorna consideramos avaria	
			endif
		next
		// altera status ZZX
		// informados em alguns itens apenas os dados de devolucao - grava como dados de devolucao PARCIAL
		// informados em todos os itens - os dados de devolucao - grava como dados de devolucao OK
		if _wparcial = 0
			_wstatus = '6' // Dados Dev OK
		else
			_wstatus = '9' // Dados Dev PAR
		endif	
	    DbSelectArea("ZZX")
		RecLock("ZZX", .F.)
	    	ZZX->ZZX_STATUS = _wstatus
	    	ZZX->ZZX_CSTAT  = dtoc(date()) + ' - ' + time() + ' - ' + substr (cUserName ,1,15)
	    	ZZX->ZZX_IND    = _wavaria  // para poder mudar a cor da bolinha das notas que nao retornam
	    MsUnLock()
	else
	
	//	if ! u_zzuvl ('030', __cUserId, .T.)
		if ! u_zzuvl ('112', __cUserId, .T.)
			return
		endif
		
		for _n = 1 to len (aCols)
			N := _n
			// verifica se informou os dados de devolucao do item
			if val(GDFieldGet ("ZZZ_12LMOV")) = 0
				_lcontinua = .F.
			endif
			
		    // VERIFICAR SE O MOTIVO DE DEVOLUCAO ESTA ATIVO
			if _lcontinua 
				_sQuery := ""
				_sQuery += "SELECT ZX5_02ATIV
		  		_sQuery += "  FROM ZX5010
		 		_sQuery += " WHERE ZX5_TABELA = '02'
		   		_sQuery += "   AND ZX5_02MOT = '" + GDFieldGet ("ZZZ_12LMOV") + "'"
				_aDados := U_Qry2Array(_sQuery)
				if len (_aDados) = 1
					if _aDados[1,1] != 'S'
			    		msgalert("Motivo de devolucao inativo.","AVISO")
			    		_lcontinua = .F.
					endif	    		
			    endif
		    endif
			
			if _lcontinua
				// grava na tabela ZAJ
				DbSelectArea("ZAJ")
				DbSetOrder(1)
				if DbSeek( ZZX -> ZZX_FILIAL + ZZX -> ZZX_CHAVE + "L001",.F.)
					RecLock("ZAJ", .F.)
				else
					RecLock("ZAJ", .T.)
				endif			
				ZAJ->ZAJ_FILIAL = ZZX -> ZZX_FILIAL
				ZAJ->ZAJ_CHAVE  = ZZX -> ZZX_CHAVE
				ZAJ->ZAJ_XITEM  = "L001"
				ZAJ->ZAJ_LMOV   = GDFieldGet ("ZZZ_12LMOV")
				ZAJ->ZAJ_LAVA   = GDFieldGet ("ZZZ_12LAVA")
				ZAJ->ZAJ_LFM    = GDFieldGet ("ZZZ_12LFM")
				ZAJ->ZAJ_LRM    = GDFieldGet ("ZZZ_12LRM")
				ZAJ->ZAJ_lPRM   = GDFieldGet ("ZZZ_12PRM")
				ZAJ->ZAJ_CTRN   = GDFieldGet ("ZZZ_12CTRN")
				if ZAJ->ZAJ_LUSER != ''
					// se ja existiam os dados de devolução e atualizou - altera usuario/data e hora
					ZAJ->ZAJ_LUSER  = cusername
					ZAJ->ZAJ_LDATA  = date()
					ZAJ->ZAJ_LHORA  = substr(time(),1,5)
				else
					ZAJ->ZAJ_LUSER   = GDFieldGet ("ZZZ_12LUSE")
					ZAJ->ZAJ_LDATA   = GDFieldGet ("ZZZ_12LDAT")
					ZAJ->ZAJ_LHORA   = substr(GDFieldGet ("ZZZ_12LHR"),1,5)
				endif
				
				MsUnLock()
			endif
		next
		// altera status ZZX
		// informados em alguns itens apenas os dados de devolucao - grava como dados de devolucao PARCIAL
		// informados em todos os itens - os dados de devolucao - grava como dados de devolucao OK
	    DbSelectArea("ZZX")
		RecLock("ZZX", .F.)
	    	ZZX->ZZX_STATUS = 'B'
	    	ZZX->ZZX_CSTAT  = dtoc(date()) + ' - ' + time() + ' - ' + substr (cUserName ,1,15)
	    MsUnLock()
	
	endif    
	CursorArrow ()
return
// ------------------------------------------------------------------------------------------------------
// Solicita dados de devolucao para logistica
user function ZZXS ()

	if zzx -> zzx_ressar = '1'
		msgalert("XML selecionado não requer dados da logistica. Trata-se de um ressarcimento de impostos.","AVISO")
		return
	endif
	
	if zzx -> zzx_tiponf != 'D'
		msgalert("XML selecionado não é referente a uma nota de devolução.","AVISO")
		return
	endif
	
	if zzx -> zzx_status = 'A'  
		msgalert("Já foram solicitados dados de devolução para a logistica. Aguarde retorno no sistema","AVISO")
		return
	endif
	/*
	if zzx -> zzx_status = 'B'  
		msgalert("Dados de devolução de logistica já informados")
		return
	endif
	*/
	
	if val(zzx -> zzx_status) > 0 .and.  val(zzx -> zzx_status) <> 3 .and. val(zzx -> zzx_status) <> 7
	    msgalert("Status não permite solicitar dados de devolução para a logistica","AVISO")
		return
	endif
	    
	_wconfirma = msgyesno ("Confirma solicitação dados de logistica","AVISO")
	
	if _wconfirma
		_aCols = {}
		aadd (_aCols, {'Documento'         ,    'left'  ,  ''})
		aadd (_aCols, {'Serie'             ,    'left'  ,  ''})
		aadd (_aCols, {'Dt.Emissao'        ,    'left'  ,  ''})
		aadd (_aCols, {'Cliente'           ,    'left'  ,  ''})
		aadd (_aCols, {'Razao Social'      ,    'left'  ,  ''})
		aadd (_aCols, {'UF'                ,    'left'  ,  ''})
		aadd (_aCols, {'Valor da NF'       ,    'left'  ,  ''})
		aadd (_aCols, {'Solicitado por'    ,    'left'  ,  ''})
		
		// Avisa Ambiental - Produtos Controlados pela Policia Federal
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT ZZX.ZZX_DOC, ZZX.ZZX_SERIE, ZZX.ZZX_EMISSA"
		_oSQL:_sQuery += "		, ZZX.ZZX_CLIFOR"
		_oSQL:_sQuery += "		, SA1.A1_NOME"
		_oSQL:_sQuery += "		, SA1.A1_EST"
		_oSQL:_sQuery += "		, ROUND(ZZX.ZZX_VLNF,2)"
		_oSQL:_sQuery += "		, '" + cUserName + "' AS USUARIO"
		_oSQL:_sQuery += "	 FROM ZZX010 AS ZZX"
		_oSQL:_sQuery += "		INNER JOIN SA1010 AS SA1"
		_oSQL:_sQuery += "			ON (SA1.A1_COD = ZZX.ZZX_CLIFOR"
		_oSQL:_sQuery += "				AND SA1.A1_LOJA = ZZX.ZZX_LOJA)"
		_oSQL:_sQuery += "	WHERE ZZX.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "	  AND ZZX.ZZX_TIPONF = 'D'"
		_oSQL:_sQuery += "    AND ZZX.ZZX_STATUS <> '1'"
		_oSQL:_sQuery += "    AND ZZX.ZZX_CHAVE = '" + ZZX->ZZX_CHAVE + "'"
		
		if len (_oSQL:Qry2Array (.T., .F.)) > 0
			_sMens = _oSQL:Qry2HTM ("Solicitados Dados de Devolução para LOGISTICA - Favor responder essa solicitação no Protheus", _aCols, "", .F.)
	        U_ZZUNU ({'030'}, "Solicitados Dados de Devolução para LOGISTICA - Favor responder essa solicitação no Protheus", _sMens, .F., cEmpAnt, cFilAnt, "") // Catia
		endif
		
		// atualiza o status no sistema
		reclock("ZZX", .F.)
			ZZX->ZZX_STATUS = 'A'
			ZZX->ZZX_CSTAT   = dtoc(date()) + ' - ' + time() + ' - ' + substr (cUserName ,1,15)
		MsUnLock()
		
	endif
return
// ------------------------------------------------------------------------------------------------------
// Revalida arquivo XML.
user function ZZXR (_lAvisos)
	local _lContinua := .T.
	//local _sFilDest  := ""
	//local _sFilAnt   := ""
	local _sXML      := ""
	local _oXMLSEF   := NIL
	//local _nAviso    := 0
	//local _sMemo1    := ""
	//local _sMemo2    := ""
	local _wcgc		 := "88612486"
	local _nItem	 := 0
	local i			 := 0

	DbSelectArea("ZZX")
	reclock("ZZX", .F.)
	   	ZZX->ZZX_STATUS  = ''
	 	ZZX->ZZX_CSTAT   = ''
	MsUnLock()
	// verifica se o XML ja esta digitado
	_sSQL := ""
    _sSQL += " SELECT F1_CHVNFE, dbo.VA_DTOC(F1_VADTINC), F1_VAHRINC, F1_VAUSER"
    _sSQL += "   FROM SF1010"
    _sSQL += "  WHERE F1_CHVNFE = '" + alltrim(zzx -> zzx_chave) + "'"
    _sSQL += "    AND D_E_L_E_T_ = ''"
    
    aDados := U_Qry2Array(_sSQL)
    
	if len (aDados) > 0
		DbSelectArea("ZZX")
		reclock("ZZX", .F.)
			ZZX->ZZX_STATUS = '1'
			ZZX->ZZX_CSTAT  = aDados[1,2] + ' - ' + aDados[1,3] + ' - ' + substr (aDados[1,4] ,1,15)
		MsUnLock()		
		
    else
    	if ZZX->ZZX_LAYOUT != 'procCTe'  
	    	// se nao encontrou pela chave... procura como pre-nota
	    	_sSQL := ""
	    	_sSQL += " SELECT F1_DOC, dbo.VA_DTOC(F1_VADTINC), F1_VAHRINC, F1_VAUSER""
	    	_sSQL += "   FROM SF1010"
	    	_sSQL += "  WHERE F1_CHVNFE  = ''" 
	    	_sSQL += "    AND D_E_L_E_T_ = ''"
	    	_sSQL += "    AND F1_DOC     = '" + alltrim(zzx -> zzx_doc) + "'" 
	    	_sSQL += "    AND F1_FORNECE = '" + alltrim(zzx -> zzx_clifor) + "'"
	    	aDados1 := U_Qry2Array(_sSQL)
	    	
	    	if len (aDados1) > 0
	    		DbSelectArea("ZZX")
	    		reclock("ZZX", .F.)
	    			ZZX->ZZX_STATUS  = '2'
	    			ZZX->ZZX_CSTAT   = aDados1[1,2] + ' - ' + aDados1[1,3] + ' - ' + substr (aDados1[1,4] ,1,15)
				MsUnLock()		
			endif
		endif		
    endif
    
    if ! empty (zzx -> zzx_ajman) .and. zzx -> zzx_ajman != 'N'
		u_help ("Este registro ja' sofreu ajustes manuais. Revalidacao nao sera' feita.")
		_lContinua = .F.
	endif

	if _lContinua
		_sXML = MSMM (zzx -> zzx_CodMem,,,,3)
	endif

	// Nao adianta guardar XML vazios.
	if _lContinua .and. empty (_sXML)
		u_help ("XML vazio. Registro nao serah mantido na base de dados.")
		U_ZZXE (.T.)
		_lContinua = .F.
	endif

	// Interpreta dados do XML e grava em variaveis private para uso posterior (inicializadores de campos, etc).
	if _lContinua
		_oXMLSEF := ClsXMLSEF ():New ()
		_oXMLSEF:LeXML (_sXML)

		// Mostra avisos e erros.
		if len (_oXMLSEF:Avisos) > 0
			U_F3Array (_oXMLSEF:Avisos, 'Avisos gerados durante a leitura do XML:')
		endif
		if len (_oXMLSEF:Erros) > 0
			U_F3Array (_oXMLSEF:Erros, 'Erros gerados durante a leitura do XML:')
			_lContinua = .F.
		endif
	endif
	
	if _lContinua .and. _oXMLSEF:XMLLayout == 'cancNFe'
		u_help ('Falta tratamento para cancelamentos')
		_lContinua = .F.
	endif

	// Nao adianta guardar XML emitidos em homologacao.
	if _lContinua .and. _oXMLSEF:Ambiente == '2'
		u_help ("XML emitido em ambiente de homologacao. Nao sera´ mantido na base de dados.")
		U_ZZXE (.T.)
		_lContinua = .F.
	endif

	// se nao tem nota e nem pre nota --- verifica dados de devolução
	if ZZX->ZZX_TIPONF = 'D'	        
    	if ZZX->ZZX_STATUS !='1' .AND. ZZX->ZZX_STATUS !='2'
    		
	    	// cont o numero de itens que tem no XML
	    	_wtotitensXML = 0
	    	for _nItem = 1 to len (_oXMLSEF:NFe:ItCFOP)
	    		_wtotitensXML = _nItem 
	    	next
			
			// verifica se o XML ja esta digitado
			_sSQL := ""
		    _sSQL += " SELECT COUNT (ZAJ_CHAVE)"
		    _sSQL += "   FROM ZAJ010"
		    _sSQL += "  WHERE ZAJ_CHAVE = '" + alltrim(zzx -> zzx_chave) + "'"
		    _sSQL += "    AND D_E_L_E_T_ = ''"
		    
		    aDados := U_Qry2Array(_sSQL)
		    
		    _wstatus = ''
		    if len (aDados) > 0
		    	if aDados[1,1] > 0 
		    		if aDados[1,1] <> _wtotitensXML
						_wstatus = '9'
					else
						_wstatus = '6'																
					endif						
				endif
			endif
			// verifica se tem dados de DEV ok ou se tem dados parciais apenas
			_sSQL := ""
		    _sSQL += " SELECT TOP 1 dbo.VA_DTOC(ZAJ_DATA), ZAJ_HORA, ZAJ_USER"
		    _sSQL += "   FROM ZAJ010"
		    _sSQL += "  WHERE ZAJ_CHAVE = '" + alltrim(zzx -> zzx_chave) + "'"
		    _sSQL += "    AND D_E_L_E_T_ = ''"
		    
		    aDados := U_Qry2Array(_sSQL)
		    if len (aDados) > 0
				DbSelectArea("ZZX")
				reclock("ZZX", .F.)
				   	ZZX->ZZX_STATUS  = _wstatus
			   		ZZX->ZZX_CSTAT   = aDados[1,1] + ' - ' + aDados[1,2] + ' - ' + substr (aDados[1,3] ,1,15)
				MsUnLock()
			endif	
		endif					
	endif
	
	// se for CTE - verifica as notas referenciadas para revalidar o TIPONF
	if zzx -> zzx_layout $ 'CTE'
		_wTipoNF = 'N' // em teoria temos mais fretes sobre saidas
		// le XML - para buscar a que notas se refere o conhecimento de frete
	    // verifica notas referenciadas para verificar se eh um frete sobre compras
		for i = 1 to len (_oXMLSEF:CTe:ChaveRel)
		_wchave  = _oXMLSEF:CTe:ChaveRel [i]
			if ! _wcgc $ _wchave 
				_wTipoNF = 'C'
				exit
			endif			
		next
		if ZZX->ZZX_TIPONF != _wTipoNF 
			DbSelectArea("ZZX")
			reclock("ZZX", .F.)
				ZZX->ZZX_TIPONF = _wTipoNF
			MsUnLock()
	    endif		
	endif
				    
	if _lContinua
		_lContinua = _GravaZZX ("A", _oXMLSEF, _sXML)
	endif
return
// ------------------------------------------------------------------------------------------------------
// Importacao de arquivo XML
user function ZZXI (_sArqImp, _sXML)
	local _lAutoZZXI   := (_sArqImp != NIL .or. _sXML != NIL)
	local _oXMLSEF     := NIL
	local _sArqOrig    := ""
	local _sDrvRmt     := ""
	local _sDirRmt     := ""
	local _ZZXXML      := ""
	local _sFldImpor   := "Importados"  // Pasta para arquivos ignorados.
	local _sFldIgnor   := "Ignorados"  // Pasta para arquivos ignorados.
	local _lContinua   := .T.
	local _oEvento     := NIL
	
	// Se recebeu um nome de arquivo a importar, nao precisa abrir tela para o usuario.
	if _lAutoZZXI
		_sArqOrig = _sArqImp
		do case 
			case "_XXX" $ _sArqImp
				_worigem = "ESPIAO"
		    case "INTPROTHEUS" $ _sArqImp
		    	_worigem = "INTPROTHEUS"
		    otherwise
		    	_worigem = "EMAIL"
		endcase
	else
		_sArqOrig = cGetFile ("XML|*.XML", "Selecione arquivo", 0, alltrim (mv_par01), .T., GETF_LOCALFLOPPY + GETF_LOCALHARD + GETF_NETWORKDRIVE)
		_worigem = "MANUAL"
	endif

	if _lContinua

		// Se recebeu string com o conteudo do XML, nao precisa ler arquivo nenhum.
		if valtype (_sXML) == "C"
			if empty (_sXML)
			 	u_help ("String vazia (deveria ter dados em XML).")
				_lContinua = .F.
			else
				_ZZXXML = _sXML
			endif
		else
		
			// Se tem nome de arquivo definido, importa-o.
			if ! empty (_sArqOrig)
	
// perguntas foram mudadas.				// Guarda caminho para usar na proxima execucao, sem a barra final, pois ela atrapalha no cGetFile.
// perguntas foram mudadas.				// Na execucao via batch nao tem necessidade de perder tempo atualizando o SX1;
// perguntas foram mudadas.				if ! _lAutoZZXI
// perguntas foram mudadas.					U_GravaSX1 (cPerg, '01', substr (_sDrvRmt + _sDirRmt, 1, len (alltrim (_sDrvRmt + _sDirRmt)) - 1))
// perguntas foram mudadas.				endif
			
				if ! file (_sArqOrig)
					u_help ("Arquivo '" + _sArqOrig + "' nao encontrado.",, .t.)
				else

					// Manda uma copia para o importador da TRS (por enquanto... a intencao eh ficar somente o da TRS) Robert, 24/08/2021
					_CopiaTRS (_sArqOrig)

					// Leitura trocada de MemoRead () para FT_ReadLn () por que a memoread limita-se a 64Kb.
					_ZZXXML = ""
					FT_FUSE(_sArqOrig)
					FT_FGOTOP()
					While !FT_FEOF()
						_ZZXXML += FT_FREADLN ()
						FT_FSKIP()
					EndDo
					if empty (_ZZXXML)
					 	u_help ("Arquivo vazio.")
						_lContinua = .F.
					endif
					FT_FUSE()  // Fecha o arquivo
				endif
			endif
		endif
	endif

	// Interpreta dados do XML e grava em variaveis private para uso posterior (inicializadores de campos, etc).
	if _lContinua
		_oXMLSEF := ClsXMLSEF ():New ()
		_oXMLSEF:LeXML (_ZZXXML)
		
		// Mostra avisos e erros.
		if len (_oXMLSEF:Avisos) > 0
			U_F3Array (_oXMLSEF:Avisos, 'Avisos gerados durante a leitura do XML:')
		endif
		if len (_oXMLSEF:Erros) > 0
			U_F3Array (_oXMLSEF:Erros, 'Erros gerados durante a leitura do XML:')
			
			// Grava evento temporario
			_oEvento := ClsEvent():new ()
			_oEvento:CodEven   = "ZZX002"
			_oEvento:Texto     = "Erros leitura XML: " + cvaltochar (_oXMLSEF:Erros)
			_oEvento:ChaveNFe  = cvaltochar (_oXMLSEF:Chave)
			_oEvento:DiasValid = 60  // Manter o evento por alguns dias, depois disso vai ser deletado.
			_oEvento:Grava ()

			// Move arquivo para o diretorio temporario de erros
			_Move (_sArqOrig, "Erros")
//			return

			_lContinua = .F.
		endif
	endif
	// Se conseguiu interpretar o XML sem gerar erros, pode gravar.
	if _lContinua
		if _GravaZZX ("I", _oXMLSEF, _ZZXXML, _worigem)
			u_help ("XML importado com sucesso" + iif (zzx -> zzx_filial != cFilAnt, " (na filial '" + zzx -> zzx_filial + "').", '.') + " Chave: " + zzx -> zzx_chave)
		else
			_lContinua = .F.
		endif
	endif

	// Move o arquivo para outro diretorio, conforme o resultado da importacao.
	if _lContinua
		if ! empty (_sArqOrig)
			_Move (_sArqOrig, _sFldImpor)
		endif
	else
		if ! empty (_sArqOrig)
			_Move (_sArqOrig, _sFldIgnor)
		endif
	endif
return _lContinua


// ------------------------------------------------------------------------------------------------------
// Manda uma copia para o importador da TRS (por enquanto... a intencao eh ficar somente o da TRS) Robert, 24/08/2021
static function _CopiaTRS (_sArqTRS)
	local _sDrvRmt := ""
	local _sDirRmt := ""
	local _sArqRmt := ""
	local _sExtRmt := ""
	local _sDestTRS := ''

	// Separa drive, diretorio, nome e extensao.
	SplitPath (_sArqTRS, @_sDrvRmt, @_sDirRmt, @_sArqRmt, @_sExtRmt )
	_sDestTRS = '\\192.168.1.3\Siga\Protheus12\protheus_data\xmlnfe\' + _sArqRmt + _sExtRmt

	// Copia o arquivo e depois deleta do local original.
	U_Log2 ('debug', 'Copiando para TRS: de >>' + _sDrvRmt + _sDirRmt + _sArqRmt + _sExtRmt + '<< para >>' + _sDestTRS + '<<')
	copy file (_sDrvRmt + _sDirRmt + _sArqRmt + _sExtRmt) to (_sDestTRS)
return

// ------------------------------------------------------------------------------------------------------
// Grava dados no arquivo ZZX.
static function _GravaZZX (_sQueFazer, _oXMLSEF, _sXML, _worigem)
	local _lContinua := .T.
	local _sFilAnt   := ""
	local _sMemo1    := ""
	local _sMemo2    := ""
	local _nItemNF   := 0
	local _oEvento   := NIL

	// Verifica se destina-se a outra empresa.
	if _lContinua
		if ! empty (_oXMLSEF:CNPJDestin) .and. left (_oXMLSEF:CNPJDestin, 8) != left (sm0 -> m0_cgc, 8)
			U_Help ("XML nao sera mantido na base de dados, pois destina-se a outro CNPJ (" + _oXMLSEF:CNPJDestin + ").")
			if _sQueFazer == 'A'

				// Grava evento temporario
				_oEvento := ClsEvent():new ()
				_oEvento:CodEven   = "ZZX002"
				_oEvento:Texto     = "XML nao sera mantido na base de dados, pois destina-se a outro CNPJ (" + _oXMLSEF:CNPJDestin + ").
				_oEvento:ChaveNFe  = cvaltochar (_oXMLSEF:Chave)
				_oEvento:DiasValid = 60  // Manter o evento por alguns dias, depois disso vai ser deletado.
				_oEvento:Grava ()

				U_ZZXE (.T.)
			endif
			_lContinua = .F.
		endif
	endif

	// Verifica se a chave jah existe na tabela (verifica layout por que notas de servico, por exemplo, nao tem chave e apareceriam como duplicadas).
	if _lContinua .and. _sQueFazer == 'I' .and. ! empty (_oXMLSEF:Chave) .and. ! _oXMLSEF:XMLLayout $ 'procEventoNfe'
		zzx -> (dbsetorder (4))
		if zzx -> (dbseek (_oXMLSEF:Chave + _oXMLSEF:XMLLayout, .F.))
			u_help ("Chave '" + _oXMLSEF:Chave + "' ja existe no arquivo ZZX com layout '" + _oXMLSEF:XMLLayout + "'. Importacao cancelada.")
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. empty (_oXMLSEF:FilDest)
		u_help ("Filial destino deste XML nao foi identificada. Cancelando gravacao.")
		_lContinua = .F.
	endif
	
	if _lContinua
		reclock ("ZZX", iif (_sQueFazer == 'I', .T., .F.))
		if _sQueFazer == 'I'
			zzx -> zzx_filial = _oXMLSEF:FilDest
			zzx -> zzx_dtimp  = date ()
			zzx -> zzx_user   = cUserName
			zzx -> zzx_retsef = '100'  /// como ta importando fixa o retorno como autorizada, depois o sistema vai validar a chave
		endif
		
		zzx -> zzx_Layout = _oXMLSEF:XMLLayout
		zzx -> zzx_Versao = _oXMLSEF:XMLVersao
		zzx -> zzx_Chave  = _oXMLSEF:Chave
		zzx -> zzx_CNPJEm = _oXMLSEF:CNPJEmiten
		zzx -> zzx_vlNF  = 0 
		zzx -> zzx_vlIPI = 0
		zzx -> zzx_vlICM = 0
		
		zzx -> zzx_arqXML = _worigem
		
		// Grava, se ocorreu, o primeiro erro/aviso do XML
		if len (_oXMLSEF:Erros) >= 1 .and. ! empty (_oXMLSEF:Erros [1])
			zzx -> zzx_erro = alltrim (_oXMLSEF:Erros [1])
		else
			if len (_oXMLSEF:Avisos) >= 1 .and. ! empty (_oXMLSEF:Avisos [1])
				zzx -> zzx_erro = alltrim (_oXMLSEF:Avisos [1])
			endif
		endif
		
		 _wstatus = ''
		 _wressarcimento = '2'

		if valtype (_oXMLSEF:NFe) == 'O'
			zzx -> zzx_TipoNF = _oXMLSEF:NFe:TipoNF
			zzx -> zzx_Doc    = _oXMLSEF:NFe:Doc
			zzx -> zzx_Serie  = _oXMLSEF:NFe:Serie
			zzx -> zzx_CliFor = _oXMLSEF:NFe:CliFor
			zzx -> zzx_Loja   = _oXMLSEF:NFe:Loja
			zzx -> zzx_emissa = _oXMLSEF:NFe:DtEmissao
			zzx -> zzx_transf = _oXMLSEF:NFe:Transfer
			for _nItemNF = 1 to len (_oXMLSEF:NFe:ItCFOP)
				zzx -> zzx_vlNF  += _oXMLSEF:NFe:ItVlTot [_nItemNF] 
				zzx -> zzx_vlIPI += _oXMLSEF:NFe:ItVlIPI [_nItemNF]
				zzx -> zzx_vlICM += _oXMLSEF:NFe:ItVlICM [_nItemNF]
				// verifica se existe amarracao produto x fornecedor
				if zzx -> zzx_TipoNF = 'N'
					if substr (_oXMLSEF:NFe:ItCFOP [_nItemNF], 2, 3) $ "101/102"
						_witem = UPPER(_oXMLSEF:NFe:ItCprod [_nItemNF])
						if val(fbuscacpo ("SA5", 14, xfilial ("SA5") + zzx -> zzx_clifor + zzx -> zzx_loja + _witem,  "A5_PRODUTO")) = 0
							// não existe a amaração produto x fornecedor
							_wstatus = '7'					
						endif
					endif					
				elseif zzx -> zzx_TipoNF = 'D'
				    if substr (_oXMLSEF:NFe:ItCFOP [_nItemNF], 2, 3) = "603"
						_wressarcimento = '1'
					endif										
				endif
			next
			zzx -> zzx_vlNF  += zzx -> zzx_vlIPI // o IPI faz parte do total da nota

		elseif valtype (_oXMLSEF:CTe) == 'O'
			zzx -> zzx_TipoNF = _oXMLSEF:CTe:TipoNF
			zzx -> zzx_Doc    = _oXMLSEF:CTe:Doc
			zzx -> zzx_Serie  = _oXMLSEF:CTe:Serie
			zzx -> zzx_CliFor = _oXMLSEF:CTe:CliFor
			zzx -> zzx_Loja   = _oXMLSEF:CTe:Loja
			zzx -> zzx_emissa = _oXMLSEF:CTe:DtEmissao
			for _nItemNF = 1 to len (_oXMLSEF:CTe:ItCFOP)
				zzx -> zzx_vlNF  += _oXMLSEF:CTe:ItVlTot [_nItemNF]
				zzx -> zzx_vlICM += _oXMLSEF:CTe:ItVlICM [_nItemNF]
			next

		elseif valtype (_oXMLSEF:EventoNFe) == 'O'
			zzx -> zzx_doc    = _oXMLSEF:EventoNFe:doc
			zzx -> zzx_serie  = _oXMLSEF:EventoNFe:serie
			zzx -> zzx_clifor = _oXMLSEF:EventoNFe:CliFor
			zzx -> zzx_loja   = _oXMLSEF:EventoNFe:Loja
			zzx -> zzx_emissa = _oXMLSEF:EventoNFe:DtEmissao
			zzx -> zzx_tpeven = _oXMLSEF:EventoNFe:TipoEvento
			zzx -> zzx_seqevt = _oXMLSEF:EventoNFe:SeqEvt
			zzx -> zzx_protoc = _oXMLSEF:EventoNFe:Protocolo
			
			// Se consultar posteriormente pela chave, recebe-se apenas a autorizacao da NFe, e nao o retorno 'Evento vinculado a NFe'. Por isso gravo agora.
			//zzx -> zzx_retsef = _oXMLSEF:EventoNFe:RetSEFAZ
            
		elseif valtype (_oXMLSEF:NFSe) == 'O'
			zzx -> zzx_TipoNF = _oXMLSEF:NFSe:TipoNF
			zzx -> zzx_doc    = _oXMLSEF:NFSe:doc
			zzx -> zzx_serie  = _oXMLSEF:NFSe:serie
			zzx -> zzx_clifor = _oXMLSEF:NFSe:CliFor
			zzx -> zzx_loja   = _oXMLSEF:NFSe:Loja
			zzx -> zzx_emissa = _oXMLSEF:NFSe:DtEmissao

		endif
	
		zzx -> zzx_ressar = _wressarcimento
		msunlock ()
		
		// Se incluiu o registro na tabela ZZX, faz a gravacao dos campos memo.
		if _sQueFazer == 'I'
			_sFilAnt = cFilAnt

			// Altera filial destino para gravacao do memo, se for o caso.
			if ! empty (_oXMLSEF:FilDest) .and. _oXMLSEF:FilDest != cFilAnt
				cFilAnt = _oXMLSEF:FilDest
			endif
	
			// Grava campos memo.
			msmm (,,, _SXML,  1,,, "ZZX", "ZZX_CODMEM")
	
			cFilAnt = _sFilAnt
		endif

		// Tratamento para casos em que o XML se destina a outra filial.
		if _sQueFazer == 'a' .and. zzx -> zzx_filial != _oXMLSEF:FilDest .and. ! empty (_oXMLSEF:FilDest)
			_sFilAnt = cFilAnt

			// Backup dos campos memo
			_sMemo1 = MSMM (zzx -> zzx_codmem,,,,3)
			_sMemo2 = MSMM (zzx -> zzx_codm2,,,,3)
			//
			// Exclui campos memo da filial anterior
			msmm (zzx -> zzx_codmem,,,, 2,,, "ZZX", "ZZX_CODMEM")
			msmm (zzx -> zzx_codm2 ,,,, 2,,, "ZZX", "ZZX_CODM2")
			//
			// Altera filial do ZZX
			reclock ("ZZX", .F.)
			zzx -> zzx_filial = _oXMLSEF:FilDest
			msunlock ()
			//
			// Regrava campos memo na nova filial
			cFilAnt = _oXMLSEF:FilDest
			msmm (,,, _sMemo1, 1,,, "ZZX", "ZZX_CODMEM")
			msmm (,,, _sMemo2, 1,,, "ZZX", "ZZX_CODM2")
			cFilAnt = _sFilAnt
		endif
	
		// Grava evento temporario
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven   = "ZZX002"
		_oEvento:Texto     = "Finalizada gravacao na tabela ZZX"
		_oEvento:Alias     = "ZZX"
		_oEvento:Recno     = zzx -> (recno ())
		_oEvento:ChaveNFe  = cvaltochar (_oXMLSEF:Chave)
		_oEvento:DiasValid = 60  // Manter o evento por alguns dias, depois disso vai ser deletado.
		_oEvento:Grava ()

	endif
return _lContinua
// ------------------------------------------------------------------------------------------------------
// Move o arquivo importado para uma subpasta, para evitar nova tentativa de importacao.
Static Function _Move (_sArq, _sDest)
	local _sDrvRmt := ""
	local _sDirRmt := ""
	local _sArqRmt := ""
	local _sExtRmt := ""
	//local _sPath   := ""

	// Separa drive, diretorio, nome e extensao.
	SplitPath (_sArq, @_sDrvRmt, @_sDirRmt, @_sArqRmt, @_sExtRmt )

	// Cria diretorio, caso nao exista
	makedir (_sDrvRmt + _sDirRmt + _sDest)

	// Copia o arquivo e depois deleta do local original.
	copy file (_sDrvRmt + _sDirRmt + _sArqRmt + _sExtRmt) to (_sDrvRmt + _sDirRmt + _sDest + "\" + _sArqRmt + _sExtRmt)
	if ! file (_sDrvRmt + _sDirRmt + _sDest + "\" + _sArqRmt + _sExtRmt)
		u_help ("Arquivo nao foi copiado para a pasta " + _sDest + ". Nao sera´ removido da pasta origem.")
	else
		delete file (_sDrvRmt + _sDirRmt + _sArqRmt + _sExtRmt)
	endif
return
// ------------------------------------------------------------------------------------------------------
// Geracao de NF de entrada no sistema
user function ZZXG (_wprenota)
	local _lContinua    := .T.
	//local _nTamDoc      := TamSX3("F1_DOC")[1] 							//TAMANHO DO DOCUMENTO DEFINIDO NO SX3
	local _nTamSerie	:= tamsx3("F1_SERIE")[1]						//TAMANHO DA SERIE DO DOCUMENTO DEFINIDO NO SX3
	local _sDoc			:= ZZX->ZZX_DOC									//DOCUMENTO
	local _sSerie		:= PADL ( ZZX->ZZX_SERIE, _nTamSerie , ' ')		//SERIE
	local _sCNPJE		:= alltrim(ZZX->ZZX_CNPJEM)						//CNPJ DO CLIENTE/FORNECEDOR 
	local _sCNPJCte		:= alltrim(ZZX->ZZX_CNPJEM)                     //CNPJ DO EMITENTE - TRANSPORTADORA - CTE
	local _sTpNf		:= alltrim(ZZX->ZZX_TIPONF)						//TIPO DO DOCUMENTO
	local _sDtEmissao	:= DTOS(ZZX->ZZX_EMISSA)						//DATA DE EMISSAO
	local _sChaveNF		:= alltrim(ZZX->ZZX_CHAVE)						//CHAVE DA NOTA FISCAL
	local _aLinha		:= {}
	Local _aAutoSF1 	:= {}											//ARRAY COM OS DADOS DO CABEÇALHO DA NOTA -SF1
	local _aAutoSD1  	:= {}											//ARRAY COM DADOS DOS ITENS DA NOTA - SD1
	local _sForCli		:= " "											//DEFINE SE É FORNECEDOR = 'F' OU CLIENTE 'C'
	local _aProdSD1		:= {}											//ARRAY COM DADOS DO ITENS PESQUISADOS NAS AMARRAÇÕES + PRODUTO GENÉRICO
	local _aRetQry   	:= {}											//ARRAY PARA ARMAZENAGEM DAS QUERYS DA FUNÇÃO
	//local _lCompra      := .F.											//VERIRIFCA SE É DE COMPRA (GABRIEL 10-10-2015)
	local _sCondPag     := ""
	local _nPesoL       := 0
	local _nPesoB       := 0
	local _nErro		:= 0
	local _nAviso		:= 0
	local _nItem		:= 0
	local i				:= 0
	local _n			:= 0
	local _nChvRel      := 0
	local _oSQLNfOri    := NIL
	local _aNfOri       := {}
	private lMsHelpAuto := .F. 											//SE .T. DIRECIONA AS MENSAGENS DO HELP
	private lMsErroAuto := .F.

	if ZZX->ZZX_STATUS = '1'
		msgalert("Documento de entrada já gerado.","AVISO")
		return
	endif
	
	if ZZX->ZZX_STATUS = '2'
		msgalert("Pre-nota já gerada.","AVISO")
		return
	endif
	
	if ZZX->ZZX_TIPONF = 'D'
		// VERIFICA DADOS DE DEVOLUCAO
		if ZZX->ZZX_STATUS = '9'
			msgalert("Não foram informados em todos os itens, os dados de devolução para este documento.","AVISO")
			_lContinua = .F.
		else //ZZX->ZZX_STATUS = '6'
			_sSQL := ""
	    	_sSQL += " SELECT ZAJ_CHAVE"
	  	  	_sSQL += "   FROM ZAJ010"
	 	 	_sSQL += "  WHERE ZAJ_CHAVE = '" + ZZX->ZZX_CHAVE + "'"
	   	  	_sSQL += " 	AND D_E_L_E_T_ = ''"
	   	  	_aDev := U_Qry2Array(_sSQL)
			if len(_adev)=0	
				msgalert("Não existem dados de devolução informados para este documento.","AVISO")
				DbSelectArea("ZZX")
				reclock("ZZX", .F.)
					ZZX->ZZX_STATUS = ''
				MsUnLock()
				return
			endif
		endif
	endif

	if _lContinua 	
		if ZZX->ZZX_VLNF = 0
			U_ZZXR (.T.)  // relvalida o registro primeiro, pq precisa do valor para gerar o documento de entrada
		endif
		
		// Verifica o Layout (tipo de documento XML) e separa a parte do XML que interessa para a importacao.
		Do Case
			Case alltrim (ZZX->ZZX_LAYOUT) == "procNFe" .AND. alltrim(ZZX->ZZX_VERSAO) $ '3.10/4.00'
				_tpDoc := 1
			Case alltrim (ZZX->ZZX_LAYOUT) == "procCTe"
				_tpDoc := 2
			Otherwise
				MSGALERT ("Layout/Versão de XML não suportado: " + alltrim(ZZX->ZZX_LAYOUT) +"/"+alltrim(ZZX->ZZX_VERSAO),"AVISO")
				_lContinua = .F.
		EndCase
	endif
	
	if _lContinua
		If _tpDoc == 1   //---------------------------------- CLIENTE/FORNECEDOR NFE
			If _sTpNf == 'N'
				DbSelectArea("SA2")
				DbSetOrder(3)		//A2_FILIAL+A2_CGC
				DbSeek(xFilial("SA2") + _sCNPJE )
				
				If Found()
					_sCodCF   := SA2->A2_COD
					_sLojaCF  := SA2->A2_LOJA
					_sUF      := SA2->A2_EST
					_sCondPag := SA2->A2_COND
					_sForCli  := 'F'
				Else
					MSGALERT ("Fornecedor CNPJ "+_sCNPJE+" não cadastrado no sistema. O documento não será gerado!","AVISO")
					_lContinua    := .F.
				Endif
				if _sCondPag = ''
					MSGALERT ("Condição de Pagamento não cadastrada pra esse Fornecedor. O documento não será gerado!","AVISO")
					_lContinua    := .F.				
				endif
				
			Elseif _sTpNf == 'D'
				
				DbSelectArea("SA1")
				DbSetOrder(3)		//A1_FILIAL+A1_CGC
				DbSeek(xFilial("SA1") + _sCNPJE )
				If Found()
					_sCodCF   := SA1->A1_COD
					_sLojaCF  := SA1->A1_LOJA
					_sUF      := SA1->A1_EST
					_sCondPag := SA1->A1_COND
					_sForCli  := 'C'
				Else
					MSGALERT ("Cliente CNPJ "+_sCNPJE+" não cadastrado no sistema. O documento não será gerado!","AVISO")
					_lContinua    := .F.
				Endif
				if val(_sCondPag) = 0
					_sCondPag = '001'
					//MSGALERT ("Condição de Pagamento não cadastrada pra esse Cliente. O documento não será gerado!")
					//_lContinua    := .F.				
				endif
				
			Elseif _sTpNf == 'B' .OR. _sTpNf == 'P' .OR. _sTpNf == 'I' .OR. _sTpNf == 'C' .OR. _sTpNf == 'A' //TIPOS NÃO VALIDADOS PELA ROTINA hoje 
				
				if _sTpNf == 'B'
					_sDescTpNf := "BENEFICIAMENTO"
				elseif _sTpNf == 'P'
					_sDescTpNf := "COMPLEMENTO IPI"
				elseif _sTpNf == 'I'
					_sDescTpNf := "COMPLEMENTO ICMS"
				elseif _sTpNf == 'C'
					_sDescTpNf := "COMPLEMENTO PREÇO/IF"
				elseif _sTpNf == 'A'
					_sDescTpNf := "TIPO A"
				endif
				
				MSGALERT ("Tipo de Nota " +_sDescTpNf + " não suportado pelo sistema ","AVISO")
				_lContinua    := .F.
				
			Endif 
			
		Else //---------------------------------- CLIENTE/FORNECEDOR CTE
			If _sTpNf == 'N' .or. _sTpNf == 'C' // conhecimento de frete de entradas é tipo C = COMPLEMENTO DE PREÇO
				
				DbSelectArea("SA2")
				DbSetOrder(3)		//A2_FILIAL+A2_CGC
				DbSeek(xFilial("SA2") + _sCNPJCte )
				
				If Found()
					_sCodCF   := SA2->A2_COD
					_sLojaCF  := SA2->A2_LOJA
					_sUF      := SA2->A2_EST
					_sCondPag := SA2->A2_COND
					_sForCli  := 'F'
				Else
					MSGALERT ("Fornecedor CNPJ "+_sCNPJCte+" não cadastrado no sistema. O documento não será gerado!","AVISO")
					
					_lContinua    := .F.
				Endif
				if _sCondPag = ''
					MSGALERT ("Condição de Pagamento não cadastrada pra esse Fornecedor. O documento não será gerado!","AVISO")
					_lContinua    := .F.				
				endif
			else
				MSGALERT ("Tipo de Nota " +_sTpNf + " não suportado pelo sistema ","AVISO")
				_lContinua    := .F.
			Endif
		Endif
	Endif
	// Pesquisa no SF1 para verificar existencia da nota no sistema
	if _lContinua
		
		DbSelectArea("SF1")
		DbSetOrder(1) //FILIAL+DOC+SERIE+FORNECE+LOJA+TIPO
		IF DbSeek( xFilial("SF1") + _sDoc + _sSerie + _sCodCF + _sLojaCF + _sTpNf)
			MSGALERT("Documento já existe no sistema. Verifique !","AVISO")
			_lContinua    := .F.		
		Endif
	Endif
	//-------------------------------- TRATAMENTOS PARA NOTAS NFE	_tpDoc := 1
	If _lContinua .AND. _tpDoc == 1
		
		// Gera o Array com os dados necessarios para o cabeçalho da nota - SF1 PARA NFE
		AADD( _aAutoSF1, { "F1_DOC"      	, _sDoc					, NIL } ) 
		AADD( _aAutoSF1, { "F1_SERIE"    	, _sSerie				, NIL } )
		AADD( _aAutoSF1, { "F1_TIPO"     	, _sTpNf				, NIL } )
		AADD( _aAutoSF1, { "F1_FORMUL"   	, "N"					, Nil } )
		AADD( _aAutoSF1, { "F1_EMISSAO"  	, StoD(_sDtEmissao)		, NIL } )
		AADD( _aAutoSF1, { "F1_FORNECE"  	, _sCodCF      			, NIL } )
		AADD( _aAutoSF1, { "F1_LOJA"     	, _sLojaCF				, NIL } )
		AADD( _aAutoSF1, { "F1_EST"      	, _sUF					, NIL } )
		AADD( _aAutoSF1, { "F1_ESPECIE"  	, "SPED"				, NIL } )
		AADD( _aAutoSF1, { "F1_CHVNFE"   	, _sChaveNF 		    , NIL } )
		AADD( _aAutoSF1, { "F1_COND"     	, _sCondPag				, NIL } )
		AADD( _aAutoSF1, { "F1_VAUSER"     	, alltrim(cUserName)	, NIL } )
		AADD( _aAutoSF1, { "F1_VADTINC"    	, date ()				, NIL } )
		AADD( _aAutoSF1, { "F1_VAHRINC"    	, time ()				, NIL } )
		
		//Gera o Array com os dados necessarios para os itens da nota - SD1 PARA NFE
		_sXML = MSMM (zzx -> zzx_CodMem,,,,3)
		_oXMLSEF := ClsXMLSEF ():New ()
		_oXMLSEF:LeXML (_sXML)
		for _nErro = 1 to len (_oXMLSEF:Erros)
			u_help (_oXMLSEF:Erros [_nErro])
		next
		for _nAviso = 1 to len (_oXMLSEF:Avisos)
			u_help (_oXMLSEF:Avisos [_nAviso])
		next
		
		if valtype (_oXMLSEF:NFe) == 'O'
			// atribui o peso liquido e bruto que consta no XML da nota
			_nPesoL = _oXMLSEF:NFe:PesoL
			_nPesoB = _oXMLSEF:NFe:PesoB
		endif
		AADD( _aAutoSF1, { "F1_PLIQUI"    	, _nPesoL				, NIL } )
		AADD( _aAutoSF1, { "F1_PBRUTO"    	, _nPesoB				, NIL } )
		
		if valtype (_oXMLSEF:NFe) == 'O'
			// Monta array com dados dos itens.
			_aItens = {}
			for _nItem = 1 to len (_oXMLSEF:NFe:ItCFOP)
				aadd (_aItens, {'', 0 , 0, 0, '', '','',''})
				_aItens [_nItem, 1] = UPPER(_oXMLSEF:NFe:ItCprod [_nItem])    // CODIGO DO ITEM - XML
				_aItens [_nItem, 2] = _oXMLSEF:NFe:ItVlTot [_nItem]    // VALOR TOTAL
				_aItens [_nItem, 3] = _oXMLSEF:NFe:ItQuant [_nItem]    // QUANTIDADE
				_aItens [_nItem, 4] = _oXMLSEF:NFe:ItVunCom [_nItem]   // VLR UNIT
				_aItens [_nItem, 5] = _oXMLSEF:NFe:ItXped [_nItem]     // PEDIDO DE COMPRA
				_aItens [_nItem, 6] = _oXMLSEF:NFe:ItnItemPed [_nItem] // ITEM DO PEDIDO DE COMPRA
				_aItens [_nItem, 7] = _oXMLSEF:NFe:ItuCom [_nItem]     // UNIDADE DE MEDIDA NO XML 
				_aItens [_nItem, 8] = _oXMLSEF:NFe:ItNCM [_nItem]      // NCM DO ITEM NO XML
			next
			
			IF _sForCli == 'F'  	//AMARRAÇÃO PRODUTO X FORNECEDOR SA5
				for i=1 to len(_aItens)
					
					if ZZX->ZZX_TRANSF != 'S'
						cQuery2 := " SELECT TOP 1 SB1.B1_COD, SB1.B1_DESC"
						cQuery2 += "      , SB1.B1_UM , SB1.B1_TIPO, SB1.B1_LOCPAD, SB1.B1_TE, SB1.B1_SEGUM, SB1.B1_CONV, SB1.B1_TIPCONV"
						cQuery2 += "      , SB1.B1_POSIPI"
						cQuery2 += "   FROM SA5010 AS SA5"
						cQuery2 += "  	INNER JOIN SB1010 AS SB1"
						cQuery2 += "  		ON (SB1.B1_COD = SA5.A5_PRODUTO)"
						cQuery2 += "  WHERE SA5.D_E_L_E_T_ = ''"
						cQuery2 += "    AND SA5.A5_FORNECE = '" + _sCodCF 	+ "'"
						cQuery2 += "    AND SA5.A5_LOJA    = '" + _sLojaCF 	+ "'"
						cQuery2 += "    AND SA5.A5_CODPRF  = '" + _aItens [i, 1] + "'"
						
					else
						cQuery2 := " SELECT TOP 1 SB1.B1_COD, SB1.B1_DESC"
						cQuery2 += "      , SB1.B1_UM , SB1.B1_TIPO, SB1.B1_LOCPAD, SB1.B1_TE, SB1.B1_SEGUM, SB1.B1_CONV, SB1.B1_TIPCONV"
						cQuery2 += "      , SB1.B1_POSIPI"
						cQuery2 += "   FROM SB1010 AS SB1"
						cQuery2 += "  WHERE SB1.D_E_L_E_T_ = ''"
						cQuery2 += "    AND SB1.B1_COD     = '" + _aItens [i, 1] + "'"
					
					endif
					
					_aRetQry := U_Qry2Array (cQuery2)
					
					if Len(_aRetQry) = 1
						_wItemOC = ''
						_wNumOC  = ''
						
						if _aRetQry[1,10] != _aItens [i, 8] // NCM
						//	MSGALERT ("NCM do iten que cosnta no XML difere da NCM do cadastro do item. Verificar item: " + alltrim(_aRetQry[1,1]) )
							u_help ("NCM do item que consta no XML (" + _aItens [i, 8] + ") difere da NCM do cadastro do item (" + _aRetQry[1,10] + "). Verifique cadastro do produto " + alltrim(_aRetQry[1,1]),, .t.)
							_lContinua := .F.
						endif
						
						if val(_aRetQry[1,6]) = 0 // TES PADRAO ITEM
							u_help ("TES Padrão de entrada, não informado para o item " + alltrim(_aRetQry[1,1]) + ". O documento não será gerado!",, .t.)
							_lContinua := .F.	
						endif
						if _aRetQry[1,3] != _aItens [i, 7] // UNIDADES DIFERENTES
							if  _aRetQry[1,8] = 0    //  FATOR DE CONVERSAO NA CADASTRADO
								u_help ("Fator de conversão, não informado para o item " + alltrim(_aRetQry[1,1]) + ". O documento não será gerado!",, .t.)
								_lContinua := .F.
							endif	
						endif
						if _lContinua 
							if val(_aItens [i, 5]) > 0 // identifica o item da ordem de compra pela ordem de compra do item no XML
								// valida a OC do XML - verifica se existe o produto nessa OC
								cQuery  = ""
								cQuery += " SELECT 1"
								cQuery += "	  FROM SC7010"
								cQuery += "	 WHERE D_E_L_E_T_ = ''"
								cQuery += "	   AND C7_FILIAL  = '" + xfilial ("SC7") + "'" 
								cQuery += "	   AND C7_FORNECE = '" + _sCodCF + "'"
								cQuery += "	   AND C7_LOJA    = '" + _sLojaCF + "'"
								cQuery += "	   AND C7_NUM     = '" + _aItens [i, 5] + "'"
								cQuery += "	   AND C7_PRODUTO = '" + _aRetQry [1, 1] + "'"
								_aRetOc := U_Qry2Array (cQuery)
								if  Len(_aRetOc) > 0
									_wNumOC = _aItens [i, 5]
								endif
								// valida a OC do XML - busca o item correspondente
								if val(_wNumOC) > 0
									cQuery  = ""
									cQuery += " SELECT TOP 1 C7_ITEM"
									cQuery += "	  FROM SC7010"
									cQuery += "	 WHERE D_E_L_E_T_ = ''"
									cQuery += "	   AND C7_FILIAL  = '" + xfilial ("SC7") + "'" 
									cQuery += "	   AND C7_FORNECE = '" + _sCodCF + "'"
									cQuery += "	   AND C7_LOJA    = '" + _sLojaCF + "'"
									cQuery += "	   AND C7_PRODUTO = '" + _aRetQry [1, 1] + "'"
									cQuery += "	   AND C7_NUM     = '" + _aItens [i, 5] + "'"
									cQuery += "	   AND C7_RESIDUO != 'S'"
									cQuery += "	   AND C7_QUANT    > (C7_QUJE + C7_QTDACLA)"
									if val(_aItens [i, 6]) > 0
										cQuery += "	   AND C7_ITEM    = '" + strzero (val(_aItens [i, 6]),4) + "'"
									endif										
									cQuery += " ORDER BY C7_DATPRF, C7_ITEM"		
									_aRetItOc := U_Qry2Array (cQuery)
									if  Len(_aRetItOc) = 1 
										_wItemOC = _aRetItOc [1,1] 
									endif
								endif		
							endif
						_wquant = _aItens [i, 3]
						_wtotal = _aItens [i, 2]
						_wvalor = _aItens [i, 4] 	
						endif
						if _lContinua
							if _aRetQry[1,3] != _aItens [i, 7] // UNIDADES DIFERENTES
								if _aRetQry[1,9] = 'D' // PARECE ERRADO MAS EH A LOGICA DO SISTEMA
									_wquant = _wquant * _aRetQry[1,8]   // fator de conversação
									_wvalor = round(_wvalor / _aRetQry[1,8],8)   // fator de conversação
								elseif _aRetQry[1,9] = 'M'
									_wquant = _wquant / _aRetQry[1,8]   // fator de conversação
									_wvalor = round(_wvalor * _aRetQry[1,8],8)   // fator de conversação
								endif
							_wtotal = round(_wquant * _wvalor,2)							
							endif
							
							// -- SE NF DE TRANSFERENCIA - SETA O TES CORRETO PARA TRANSFENCIA - conforme o produto
							_wtes = _aRetQry[1,6]
							if ZZX->ZZX_TRANSF = 'S'
								_wtpprod = _aRetQry[1,4]
								do case 
									// case _wtpprod = 'GG'
									case _wtpprod = 'GG' .or. _wtpprod ='RE'
										_wtes = '151'
									case _wtpprod = 'AI' .or. _wtpprod = 'AT'
										_wtes = '081'
									// case _wtpprod = 'UC' .or. _wtpprod ='CL' .or. _wtpprod ='EP' .or. _wtpprod ='CF' .or. _wtpprod ='MB' .or. _wtpprod ='ML' .or. _wtpprod ='MM' .or. _wtpprod ='MT' .or. _wtpprod ='MX' .or. _wtpprod ='RE' 
									case _wtpprod = 'UC' .or. _wtpprod ='CL' .or. _wtpprod ='EP' .or. _wtpprod ='CF' .or. _wtpprod ='MB' .or. _wtpprod ='ML' .or. _wtpprod ='MM' .or. _wtpprod ='MT' .or. _wtpprod ='MX' //.or. _wtpprod ='RE'
										_wtes = '234'
									case _wtpprod = 'PA' .and. cfilant == '16'
										_wtes = '255'
									otherwise
										_wtes = '057' // AP, BN, II, MA, MP, MR, PA, PI. PP, PS, SP, VA, VD, ME
								end case
							endif
							AADD( _aProdSD1, { _aRetQry[1,1], _aRetQry[1,2], _wtotal, _aRetQry[1,3], _aRetQry[1,4], _aRetQry[1,5], _wquant, _wvalor, _wtes, _wNumOC, _wItemOC } )
						endif							
	
					else // problemas com a amarração produto x fornecedor
						u_help ("Problema com a amarração produto x fornecedor. O codigo '" + _aItens [i, 1] + "' (de uso do fornecedor '" + _sCodCF + '/' + _sLojaCF + "') nao foi encontrado amarrado a nenhum codigo nosso.",, .t.)
						_lContinua := .F.				
					Endif
				next
			
			Elseif _sForCli == 'C'
				 
				if zzx -> zzx_tiponf = 'D'
					for i=1 to len(_aItens)
						cQuery3 := " SELECT ZAJ.ZAJ_CPROD, SB1.B1_DESC"
	     				cQuery3 += " 	 , SB1.B1_UM, SB1.B1_TIPO"
	     				cQuery3 += " 	 , CASE WHEN ZAJ_RETOR = '1' THEN '91' ELSE '93' END AS LOCAL"
	     				cQuery3 += " 	 , ZAJ.ZAJ_TESDEV"
	     				cQuery3 += " 	 , ZAJ.ZAJ_NFORIG"
	     				cQuery3 += " 	 , ZAJ.ZAJ_SORIG"
	     				cQuery3 += " 	 , ZAJ.ZAJ_ITORIG"
	     				cQuery3 += " 	 , ZAJ.ZAJ_MOTDEV"
	     				cQuery3 += " 	 , ZAJ.ZAJ_QUANT"
	     				cQuery3 += "     , (SELECT SD2.D2_PRCVEN"
			 			cQuery3 += "          FROM SD2010 AS SD2"
	        			cQuery3 += "         WHERE D2_FILIAL = ZAJ.ZAJ_FILIAL"
			  			cQuery3 += "           AND D2_DOC    = ZAJ.ZAJ_NFORIG"
	          			cQuery3 += "           AND D2_SERIE  = ZAJ.ZAJ_SORIG"
			  			cQuery3 += "           AND D2_ITEM   = ZAJ.ZAJ_ITORIG ) AS VLR_NF_ORIGINAL"
	  					cQuery3 += "  FROM ZAJ010 AS ZAJ"
						cQuery3 += "		INNER JOIN SB1010 AS SB1"
						cQuery3 += "			ON (SB1.B1_COD = ZAJ.ZAJ_CPROD)"
	 					cQuery3 += " WHERE ZAJ.D_E_L_E_T_ = ''"
	 					cQuery3 += "   AND ZAJ.ZAJ_CHAVE  = '" + ZZX-> ZZX_CHAVE + "'"
	 					cQuery3 += "   AND ZAJ.ZAJ_XPROD  = '" + _aItens [i, 1] + "'"
	 					
						_aRetQry := U_Qry2Array (cQuery3)
						
						if  Len(_aRetQry) > 0 //adiciona dados da DEVOLUCAO
							for _n=1 to len (_aRetQry)	
								N := _n					
								if val(_aRetQry[N,6]) = 0 // TES DE DEVOLUÇÃO
									MSGALERT ("TES de Devolução, não informado para o item " + alltrim(_aRetQry[1,1]) + ". O documento não será gerado!","AVISO")
									_lContinua := .F.		
								endif
								if _lContinua
									AADD( _aProdSD1, { _aRetQry[N,1], _aRetQry[N,2], _aItens [i, 2], _aRetQry[N,3], _aRetQry[N,4], _aRetQry[N,5], _aRetQry[N,11], _aRetQry[N,12] , _aRetQry[N,6], _aItens [i, 5], '', '', _aRetQry[N,7], _aRetQry[N,8], _aRetQry[N,9], _aRetQry[N,10] } )
									//AADD( _aProdSD1, { _aRetQry[n,1], _aRetQry[n,2], _aItens [i, 2], _aRetQry[n,3], _aRetQry[n,4], _aRetQry[n,5], _aRetQry[n,11], _aRetQry[n,12] , _aRetQry[n,6], _aItens [i, 5], '', '', _aRetQry[n,7], _aRetQry[n,8], _aRetQry[n,9], _aRetQry[n,10] } )
									//AADD( _aProdSD1, { _aRetQry[n,1], _aRetQry[n,2], _aItens [i, 2], _aRetQry[n,3], _aRetQry[n,4], _aRetQry[n,5], _aRetQry[n,11], _aItens [i, 4] , _aRetQry[n,6], _aItens [i, 5], '', '', _aRetQry[n,7], _aRetQry[n,8], _aRetQry[n,9], _aRetQry[n,10] } )
								endif
							next															
						else 
							MSGALERT ("Problema com os dados de devolução. O documento não será gerado!","AVISO")
							_lContinua    := .F.						
						Endif
					next
				else	
					for i=1 to len(_aItens)
						
						cQuery3 := " SELECT SB1.B1_COD, SB1.B1_DESC"
						cQuery3 += "      , SB1.B1_UM, SB1.B1_TIPO, SB1.B1_LOCPAD, SB1.B1_TE"
						cQuery3 += "   FROM SA7010 AS SA7"
						cQuery3 += "  	INNER JOIN SB1010 AS SB1"
						cQuery3 += "  		ON (SB1.B1_COD = SA7.A7_PRODUTO)"
						cQuery3 += "  WHERE SA7.D_E_L_E_T_ = ''"
						cQuery3 += "    AND SA7.A7_CLIENTE = '" + _sCodCF+ "'"
						cQuery3 += "    AND SA7.A7_LOJA    = '" + _sLojaCF + "'"
						cQuery3 += "    AND SA7.A7_CODCLI  = '" + _aItens [i, 1] + "'"
						_aRetQry := U_Qry2Array (cQuery3)
						
						if  Len(_aRetQry) = 1 //adiciona dados da amarração
							if val(_aRetQry[1,6]) = 0 // TES PADRAO ITEM
								MSGALERT ("TES Padrão de entrada, não informado para o item " + alltrim(_aRetQry[1,1]) + ". O documento não será gerado!","AVISO")
								_lContinua := .F.		
							endif
							if _lContinua
								AADD( _aProdSD1, { _aRetQry[1,1], _aRetQry[1,2], _aItens [i, 2], _aRetQry[1,3], _aRetQry[1,4], _aRetQry[1,5], _aItens [i, 3], _aItens [i, 4] , _aRetQry[1,6], _aItens [i, 5], '' } )
							endif							
						else 
							MSGALERT ("Problema com a amarração produto x cliente. O documento não será gerado!","AVISO")
							_lContinua    := .F.						
						Endif
						
					next
				endif					
			Endif
		endif
		
		if Len (_aProdSD1) > 0
		
			//u_showarray(_aProdSD1)
			
			For i:=1 to Len (_aProdSD1)
				_aLinha  := {}
				
				AADD(_aLinha , {"D1_COD"     , 	 _aProdSD1[i,1]  								, NIL } )
				AADD(_aLinha , {"D1_DESCRI"  , 	 _aProdSD1[i,2]  								, NIL } )
				AADD(_aLinha , {"D1_QUANT"   ,  _aProdSD1[i,7]									, NIL } )
				AADD(_aLinha , {"D1_VUNIT"   ,  _aProdSD1[i,8]	, NIL } )
				AADD(_aLinha , {"D1_TOTAL"   ,  _aProdSD1[i,3]	, NIL } )
				AADD(_aLinha , {"D1_UM"      , 	 _aProdSD1[i,4]  								, NIL } )
				AADD(_aLinha , {"D1_TP"      , 	 _aProdSD1[i,5]  								, NIL } )
				AADD(_aLinha , {"D1_LOCAL"   , 	 _aProdSD1[i,6]  								, NIL } )
				AADD(_aLinha , {"D1_CF"      , fBuscaCpo ("SF4", 1, xfilial ("SF4") + _aProdSD1[i,9] , "F4_CF"), Nil } )
				if _wprenota != 1
					AADD(_aLinha , {"D1_TES"     , 	 _aProdSD1[i,9]  								, NIL } )
				endif
				
				// seta dados de devolução
				if ZZX->ZZX_TIPONF = 'D'
					AADD(_aLinha , {"D1_NFORI"   ,   _aProdSD1[i,13] 								, Nil } )
					AADD(_aLinha , {"D1_SERIORI" , 	 _aProdSD1[i,14]  								, Nil } )
					AADD(_aLinha , {"D1_ITEMORI" , 	 _aProdSD1[i,15]  								, '.T.' } )
					AADD(_aLinha , {"D1_MOTDEV"  , 	 _aProdSD1[i,16]  								, Nil } )
				else
					if val(_aProdSD1[i,10]) > 0
						AADD(_aLinha , {"D1_PEDIDO"  ,   _aProdSD1[i,10]                   				, Nil } )
					endif
					if val(_aProdSD1[i,11]) > 0
						AADD(_aLinha , {"D1_ITEMPC"  ,   _aProdSD1[i,11]                   				, Nil } )
					endif
				endif					
				AADD(_aAutoSD1, aClone (U_OrdAuto (_aLinha)))
			Next
		Else
			MSGALERT("Erro ao buscar os itens. Arquivo não importado.","AVISO")
			_lContinua    := .F.
		Endif
	Endif
	//-------------------------------- TRATAMENTOS PARA NOTAS CTE	_tpDoc := 2
	If _lContinua .AND. _tpDoc == 2
		_aAutoSF1   := {}
		_aAutoSD1	:= {}
		
		AADD( _aAutoSF1, { "F1_DOC"      , _sDoc				,  	Nil } )
		AADD( _aAutoSF1, { "F1_SERIE"    , _sSerie   			,   Nil } )
		AADD( _aAutoSF1, { "F1_TIPO"     , "N"					,	Nil } )  // POR ENQUANTO ENTRA TODOS COMO NORMAL - DEPOIS FALTA VER FRETES SOBRE COMPRAS
		AADD( _aAutoSF1, { "F1_FORMUL"   , "N"					,   Nil } )
		AADD( _aAutoSF1, { "F1_EMISSAO"  , StoD(_sDtEmissao)	,   Nil } )
		AADD( _aAutoSF1, { "F1_FORNECE"  , _sCodCF				,   Nil } )
		AADD( _aAutoSF1, { "F1_LOJA"     , _sLojaCF				,   Nil } )
		AADD( _aAutoSF1, { "F1_EST"      , _sUF                 ,   Nil } )
		AADD( _aAutoSF1, { "F1_ESPECIE"  , "CTE"				,   Nil } )
		AADD( _aAutoSF1, { "F1_CHVNFE"   , _sChaveNF			,   Nil } )
		AADD( _aAutoSF1, { "F1_COND"     , _sCondPag            ,   Nil } )
		AADD( _aAutoSF1, { "F1_DTDIGIT"  , ddatabase       		, 	Nil } )
		AADD( _aAutoSF1, { "F1_VAUSER"   , alltrim(cUserName)	, 	NIL } )
		AADD( _aAutoSF1, { "F1_VADTINC"  , date ()				, 	NIL } )
		AADD( _aAutoSF1, { "F1_VAHRINC"  , time ()				, 	NIL } )
		AADD( _aAutoSF1, { "F1_TPCTE"    , "N"				    , 	NIL } )
		
	 
		_aAutoSF1 := aclone (U_OrdAuto (_aAutoSF1))
	
		_aAutoSD1 := {}
		_aLinhas  := {}
		
		AADD(_aLinhas , {"D1_ITEM"    , StrZero(1,4)                , Nil } )
		AADD(_aLinhas , {"D1_COD"     , _xPRODUTO                   , Nil } ) 
		AADD(_aLinhas , {"D1_UM"      , fbuscacpo ("SB1", 1, xfilial ("SB1") + _xPRODUTO,  "B1_UM")    , Nil } )
		AADD(_aLinhas , {"D1_TP"      , fbuscacpo ("SB1", 1, xfilial ("SB1") + _xPRODUTO,  "B1_TIPO")  , Nil } )
		//AADD(_aLinhas , {"D1_LOCAL"   , fbuscacpo ("SB1", 1, xfilial ("SB1") + _xPRODUTO,  "B1_LOCPAD"), Nil } )
		AADD(_aLinhas , {"D1_QUANT"   , 1                           , Nil } )
		AADD(_aLinhas , {"D1_VUNIT"   , ZZX-> ZZX_VLNF              , Nil } )
		AADD(_aLinhas , {"D1_TOTAL"   , ZZX-> ZZX_VLNF              , Nil } )
		AADD(_aLinhas , {"D1_TES"     , iif(ZZX-> ZZX_VLICM>0,_xTES_c_ICMS, _xTES_s_ICMS) , Nil } )
		AADD(_aLinhas , {"D1_VALICM"  , ZZX-> ZZX_VLICM             , Nil } )
		AADD(_aLinhas , {"D1_CF"      , fBuscaCpo ("SF4", 1, xfilial ("SF4") + iif(ZZX-> ZZX_VLICM>0,_xTES_c_ICMS, _xTES_s_ICMS), "F4_CF"), Nil } )
		
		_aLinhas := aclone (U_OrdAuto (_aLinhas))
		AADD( _aAutoSD1, aClone( _aLinhas ) )
		
		u_log2 ('debug', 'Criando objeto para fretes')
		public _oClsFrtFr := ClsFrtFr():New ()
		public _CA100For := _sCodCF
	    public _cLoja    := _sLojaCF
	    
		_oClsFrtFr:_sFornece  = _sCodCF
	    _oClsFrtFr:_sLoja     = _sLojaCF
	    
	    // le XML - para buscar a que notas se refere o conhecimento de frete
	    _sXML = MSMM (zzx -> zzx_CodMem,,,,3)
		_oXMLSEF := ClsXMLSEF ():New ()
		_oXMLSEF:LeXML (_sXML)
		for _nErro = 1 to len (_oXMLSEF:Erros)
			u_help (_oXMLSEF:Erros [_nErro])
		next
		for _nAviso = 1 to len (_oXMLSEF:Avisos)
			u_help (_oXMLSEF:Avisos [_nAviso])
		next
		
		// busca notas refenciadas e ve se existem no sistema
		u_log2 ('debug', 'Chaves relacionadas a este CTe:')
		u_log2 ('debug', _oXMLSEF:CTe:ChaveRel)
		_oSQLNfOri := CLSSQL ():New ()
		for _nChvRel = 1 to len (_oXMLSEF:CTe:ChaveRel)
			_wchave   = _oXMLSEF:CTe:ChaveRel [_nChvRel]
			u_log2 ('debug', 'chave relacionada ' + cvaltochar (_nChvRel) + ': ' + _wchave)
//			_wnumnota = fbuscacpo ("SF2", 19, _wchave,  "F2_DOC")
//			_wserie   = fbuscacpo ("SF2", 19, _wchave,  "F2_SERIE")
//			u_log2 ('debug', 'nota e serie pelo indice 19: ' + _wnumnota + ' ' + _wserie)
//			_wnumnota = fbuscacpo ("SF2", 20, _wchave,  "F2_DOC")
//			_wserie   = fbuscacpo ("SF2", 20, _wchave,  "F2_SERIE")
//			u_log2 ('debug', 'nota e serie pelo indice 20: ' + _wnumnota + ' ' + _wserie)
			_oSQLNfOri:_sQuery := "SELECT F2_DOC, F2_SERIE"
			_oSQLNfOri:_sQuery +=  " FROM " + RetSQLName ("SF2") + " SF2 "
			_oSQLNfOri:_sQuery += " WHERE SF2.D_E_L_E_T_ != '*'"
			_oSQLNfOri:_sQuery +=   " AND SF2.F2_FILIAL   = '" + xfilial ("SF2") + "'"
			_oSQLNfOri:_sQuery +=   " AND SF2.F2_CHVNFE   = '" + _wchave + "'"
			_oSQLNfOri:_sQuery +=   " AND SF2.F2_TIPO     = 'N'"
			_oSQLNfOri:_sQuery +=   " AND EXISTS (SELECT *"  // Nao quero notas de transferencia entre filiais.
			_oSQLNfOri:_sQuery +=                 " FROM " + RetSQLName ("SA1") + " SA1 "
			_oSQLNfOri:_sQuery +=                " WHERE SA1.D_E_L_E_T_ != '*'"
			_oSQLNfOri:_sQuery +=                  " AND SA1.A1_FILIAL   = '" + xfilial ("SA1") + "'"
			_oSQLNfOri:_sQuery +=                  " AND SA1.A1_COD      = SF2.F2_CLIENTE"
			_oSQLNfOri:_sQuery +=                  " AND SA1.A1_LOJA     = SF2.F2_LOJA"
			_oSQLNfOri:_sQuery +=                  " AND SA1.A1_FILTRF   = '')"
			_oSQLNfOri:Log ()
			_aNfOri = aclone (_oSQLNfOri:Qry2Array (.F., .F.))
			if len (_aNfOri) == 0
				u_log2 ('info', 'Chave ' + _wchave + ' referenciada no CTe ' + _sDoc + '/' + _sSerie + ' do fornecedor/loja ' + _sCodCF + '/' + _sLojaCF + ' nao consta como uma de nossas notas de venda.')
			elseif len (_aNfOri) == 1  // Deve encontrar somente uma nota
				_wnumnota = _aNfOri [1, 1]
				_wserie   = _aNfOri [1, 2]
				aadd (_oClsFrtFr:_aNaoPrev, array (3))
//				_oClsFrtFr:_aNaoPrev [ _nChvRel, 1] = _wnumnota
//				_oClsFrtFr:_aNaoPrev [ _nChvRel, 2] = _wserie 
//				_oClsFrtFr:_aNaoPrev [ _nChvRel, 3] = '1'
				_oClsFrtFr:_aNaoPrev [len (_oClsFrtFr:_aNaoPrev), .FrtNaoPrevDoc]         = _wnumnota
				_oClsFrtFr:_aNaoPrev [len (_oClsFrtFr:_aNaoPrev), .FrtNaoPrevSerie]       = _wserie
				_oClsFrtFr:_aNaoPrev [len (_oClsFrtFr:_aNaoPrev), .FrtNaoPrevTipoServico] = '1'  // Aqui estou assumindo sempre como 'frete' por que nao tenho (ainda) como saber se eh reentrega, paletizacao, etc...
			elseif len (_aNfOri) > 1
				u_help ('Chave ' + _wchave + ' referenciada no CTe ' + _sDoc + '/' + _sSerie + ' do fornecedor/loja ' + _sCodCF + '/' + _sLojaCF + ' nao poderia ter sido encontrada em mais de uma de nossas notas de saida. Verifique!',, .t.)
			endif
		next

	Endif
	//-------------------------------- FIM TRATAMENTOS PARA NOTAS CTE	_tpDoc := 2
	
	//-------------------------------- GERAÇÃO DA NOTA FISCAL POR EXECAUTO SF1-SD1
	
	If _lContinua
		_aAmbAnt    := U_SalvaAmb ()  				// As rotinas automaticas alteram o conteudo das variaveis mv_par.
		lMsErroAuto := .F.
		DbSelectArea("SF1")
		
		If _wprenota == 1
			// inclui como pre-nota 
			MsExecAuto({|x,y,z,a,b| MATA140(x,y,z,a,b)},_aAutoSF1,_aAutoSD1,3,,1)
		Else	
			// inclui como documento normal	
			//u_showarray (_aAutoSF1)
			//u_showarray (_aAutoSD1)
			//u_help ("Envia para rotina automatica")
			MATA103 (_aAutoSF1, _aAutoSD1, 3, .T.) // Abre tela do doc. entrada (parametro .T.) para possibilitar conferencia e manutencao do usuario.
			//u_help ("Retorno da rotina automatica")
		EndIf			
		//
		If lMsErroAuto
			MostraErro()
		Else
			//Verifica gravação da nota(usuario pode ter cancelado no final)
			DbSelectArea("SF1")
			DbSetOrder(1) //FILIAL+DOC+SERIE+FORNECE+LOJA
			
			if DbSeek(xFilial("SF1") + _sDoc + _sSerie + _sCodCF + _sLojaCF ,.F.)
				
				// atualiza SF1
	            DbSelectArea("SF1")
	            RecLock("SF1",.F.)
	          	   SF1->F1_VAFLAG   := 'X' // Flag Importacao
	            MsUnLock()
				
				DbSelectArea("ZZX")
				reclock ("ZZX", .F.)
				if _wprenota == 1
					ZZX->ZZX_STATUS = '2'  /// Pré-Nota Gerada
					ZZX->ZZX_CSTAT   = dtoc(date()) + ' - ' + time() + ' - ' + substr (cUserName ,1,15)
				else
					ZZX->ZZX_STATUS = '1'  /// Documento Lançado
					ZZX->ZZX_CSTAT   = dtoc(date()) + ' - ' + time() + ' - ' + substr (cUserName ,1,15)
				endif						
				msunlock ()
				
				// corrige SFT - via rotina automatica não esta gravando o FT_ITEM = D1_ITEM
	            // erro no produto - porem o suporte nao reproduziu e por isso nao vai corrigir
	            DbSelectArea("SFT")
	            DbSetOrder(6)
	    		if DbSeek(xFilial("SFT") + 'E' + _sDoc + _sSerie,.F.)
	    		  	 RecLock("SFT",.F.)
	               		SFT->FT_ITEM := '0001' // sempre 0001
	               	 MsUnLock()
				endif
				MSGALERT("Documento "+_sDoc+" "+_sSerie+" gerado com sucesso!","AVISO")
				//	
			Else
				MSGALERT("Não foi possível a geração do documento "+_sDoc+" "+_sSerie+".","AVISO")
				_lContinua    := .F.
			Endif
			//
		endif
		// Imprime romaneio de entrada
		DbSelectArea("SF1")
		DbSetOrder(1) //FILIAL+DOC+SERIE+FORNECE+LOJA
		If DbSeek(xFilial("SF1") + _sDoc + _sSerie + _sCodCF + _sLojaCF ,.F.)
			DbSelectArea("SF1")
		    if cEmpAnt + cFilAnt == '0101' .and. SF1->F1_ESPECIE !='CTR' .and. SF1->F1_ESPECIE !='CTE' 
		    	if U_MsgYesNo ("Deseja imprimir o romaneio de entrada?")
		    		U_RomEntr (sf1 -> f1_fornece, sf1 -> f1_loja, sf1 -> f1_doc, sf1 -> f1_serie)
				endif
			endif
		Else
			MSGALERT("Não foi possível imprimir o romaneio. Documento: "+_sDoc+" "+_sSerie+" não localizado.","AVISO")
			_lContinua    := .F.
		EndIf
	endif
return
// ------------------------------------------------------------------------------------------------------
// Trata avisos e erros encontrados no processamento.
Static Function _Msg (_sMsg, _lImportOK)
	static _sCompleto := ""
	// Acumula todas as mensagens.
	_sCompleto += _sMsg + chr (13) + chr (10)

	u_help (_sMsg)
return
// ------------------------------------------------------------------------------------------------------
//
user function VA_EstXML ( _wclifor, _wtiponf, _wchave)
	_west := ""
	if val(_wclifor) > 0
		if _wtiponf $ 'BD'
			_west = fbuscacpo ("SA1", 1, xfilial ("SA1") + _wclifor,  "A1_EST") 
		else
			_west = fbuscacpo ("SA2", 1, xfilial ("SA2") + _wclifor,  "A2_EST")
		endif
	else
		// busca o estado conforme o XML
		if val(_wchave) > 0
			_west = substr (alltrim(_wchave),1,2)	
			do case
				case _west = '11'
					_west = "RO"
				case _west = '12'
					_west = "AC"
				case _west ='13'
					_west = "AM"
				case _west ='14'
					_west = "RR"
				case _west ='15'
					_west = "PA"
				case _west ='16'
					_west = "AP"
				case _west ='17'
					_west = "TO"
				case _west ='21'
					_west = "MA"
				case _west ='22'
					_west = "PI"
				case _west ='23'
					_west = "CE"
				case _west ='24'
					_west = "RN"
				case _west ='25'
					_west = "PB"
				case _west ='26'
					_west =	"PE"
				case _west ='27'
					_west = "AL"
				case _west ='31'
					_west = "MG"
				case _west ='32'
					_west = "ES"
				case _west ='33'
					_west = "RJ"
				case _west ='35'
					_west = "SP"
				case _west ='41'
					_west = "PR"
				case _west ='42'
					_west =	"SC"
				case _west ='43'
					_west = "RS"
				case _west ='50'
					_west = "MS"
				case _west ='51'
					_west = "MT"
				case _west ='52'
					_west = "GO"
				case _west ='53'
					_west = "DF"
				case _west ='28'
					_west = "SE"
				case _west ='29'
					_west = "BA"
				case _west ='99'
					_west = "EX"
			endcase
		endif					
	endif
return _wEst
// ------------------------------------------------------------------------------------------------------
//
user function status_ZZX(_wstatus)
	_xRet   := ""

	do case
		case _wstatus ='1' 
			_xRet = 'Lançado'
		case _wstatus = '2' 
			_xRet = 'Pre-NF OK'
		case _wstatus = '3'
			_xRet = 'Doc.Excluido'
		case _wstatus = '4'
			_xRet = 'Contra Nota'
		case _wstatus = '5'
			_xRet = 'Desconsiderado'
		case _wstatus = '6'
			_xRet = 'Dados Dev.OK'
		case _wstatus = '7'
			_xRet = 'Sem Amarracao'
		case _wstatus = '8'
			_xRet = 'Nao Aceite'
		case _wstatus = '9'
			_xRet = 'Dados Dev.PARC'
		case _wstatus = 'A'
			_xRet = 'Solic.Dados LOG'
		case _wstatus = 'B'
			_xRet = 'Dados LOG OK'	
	endcase		
return _xRet
// ------------------------------------------------------------------------------------------------------
//
User Function ZZXIMP()
	Private oReport
	Private cPerg   := "ZZXIMP"
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
// --------------------------------------------------------------------------------------------------------------
//
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	Local oSection2:= Nil
	//Local oFunction
	//Local oBreak1
	//Local oBreak2

	oReport := TReport():New("ZZXIMP","Manutenção de XML - Dados de devolução",cPerg,{|oReport| PrintReport(oReport)},"Manutenção de XML - Dados de devolução")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	//SESSÃO 1 NOTAS
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.T.,.F.) 
	
	// COMERCIAL
	oSection1:SetTotalInLine(.F.)	
	TRCell():New(oSection1,"COLUNA0", 	" ","Tipo"		    ,	    			, 6,/*lPixel*/,{||	},"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA1", 	" ","Item XML"		,	    			, 6,/*lPixel*/,{||	},"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA2", 	" ","Prod.XML"		,       			,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA3", 	" ","Desc.XML"		,    				,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA4", 	" ","UN XML"		,					, 5,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA5", 	" ","Qnt.XML"		,"@E 999,999.99"    ,15,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"COLUNA6", 	" ","Cód.Produto"	,					,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA7", 	" ","Desc.Interna"	,					,30,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA8", 	" ","UN"			,					, 5,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA9", 	" ","Qnt."			,"@E 999,999.99"    ,15,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"COLUNA10", 	" ","Motivo"		,					,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA11", 	" ","Retorno"		,					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA12", 	" ","NF Origem"		,					,12,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA13", 	" ","Item NF Origem",					,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA14", 	" ","TES"			,					, 5,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA15", 	" ","Vend.NF Origem",					,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA16", 	" ","Vend.NF Dev."	,					,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA17", 	" ","Usuário"		,					,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA18", 	" ","Data"			,					,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA19", 	" ","Hora"			,					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	
	//SESSÃO 2 - LOGISTICA
	oSection2 := TRSection():New(oReport,,{}, , , , , ,.F.,.T.,.F.) 
	
	// COMERCIAL
	oSection2:SetTotalInLine(.F.)	
	TRCell():New(oSection2,"COLUNA0", 	" ","Tipo"		,	    					, 6,/*lPixel*/,{||	},"LEFT",,,,,,,,.T.)
	TRCell():New(oSection2,"COLUNA1", 	" ","Motivo Dev"		,	    			,15,/*lPixel*/,{||	},"LEFT",,,,,,,,.T.)
	TRCell():New(oSection2,"COLUNA2", 	" ","Avaria"			,	    			,15,/*lPixel*/,{||	},"LEFT",,,,,,,,.T.)
	TRCell():New(oSection2,"COLUNA3", 	" ","Faltou Merc."		,       			,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection2,"COLUNA4", 	" ","Merc.Retorna"		,    				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.T.)
	TRCell():New(oSection2,"COLUNA5", 	" ","Previsão Retorno"	,					,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection2,"COLUNA6", 	" ","Usuário"			,					,25,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection2,"COLUNA7", 	" ","Data"				,					,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection2,"COLUNA8", 	" ","Hora"				,					,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection2,"COLUNA9", 	" ","Cob.Transp."		,					,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	
Return(oReport)
// --------------------------------------------------------------------------------------------------------------
//
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local oSection2 := oReport:Section(2)
	Local _oSQL     := NIL
	Local _sAliasQ  := ""

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " SELECT "
	_oSQL:_sQuery += " 	CASE"
	_oSQL:_sQuery += " 	WHEN ZAJ_XITEM = 'L001' THEN 'LOG'"
	_oSQL:_sQuery += " 		ELSE 'COM'"
	_oSQL:_sQuery += " 	END TP"
	_oSQL:_sQuery += "    ,ZAJ_XITEM"
	_oSQL:_sQuery += "    ,ZAJ_XPROD"
	_oSQL:_sQuery += "    ,ZAJ_XDESC"
	_oSQL:_sQuery += "    ,ZAJ_XUN"
	_oSQL:_sQuery += "    ,ZAJ_XQUANT"
	_oSQL:_sQuery += "    ,ZAJ_CPROD"
	_oSQL:_sQuery += "    ,B1_DESC"
	_oSQL:_sQuery += "    ,ZAJ_UN"
	_oSQL:_sQuery += "    ,ZAJ_QUANT"
	_oSQL:_sQuery += "    ,ZAJ_MOTDEV"
	_oSQL:_sQuery += "    ,ZAJ_RETOR"
	_oSQL:_sQuery += "    ,ZAJ_NFORIG"
	_oSQL:_sQuery += "    ,ZAJ_ITORIG"
	_oSQL:_sQuery += "    ,ZAJ_TES"
	_oSQL:_sQuery += "    ,ZAJ_VEND"
	_oSQL:_sQuery += "    ,ZAJ_VENDDV"
	_oSQL:_sQuery += "    ,ZAJ_USER"
	_oSQL:_sQuery += "    ,ZAJ_DATA"
	_oSQL:_sQuery += "    ,ZAJ_HORA"
	_oSQL:_sQuery += "	  ,ZAJ_LMOV"
	_oSQL:_sQuery += " 	,CASE"
	_oSQL:_sQuery += " 	WHEN ZAJ_LAVA = 1 THEN 'Sim'"
	_oSQL:_sQuery += " 		ELSE 'Não'"
	_oSQL:_sQuery += " 	END ZAJ_LAVA"
	_oSQL:_sQuery += " 	,CASE"
	_oSQL:_sQuery += " 	WHEN ZAJ_LFM = 1 THEN 'Sim'"
	_oSQL:_sQuery += " 		ELSE 'Não'"
	_oSQL:_sQuery += " 	END ZAJ_LFM"
	_oSQL:_sQuery += " 	,CASE"
	_oSQL:_sQuery += " 	WHEN ZAJ_LRM = 1 THEN 'Sim'"
	_oSQL:_sQuery += " 		ELSE 'Não'"
	_oSQL:_sQuery += " 	END ZAJ_LRM"
	_oSQL:_sQuery += " 	  ,ZAJ_LPRM"
	_oSQL:_sQuery += " 	  ,ZAJ_LUSER"
	_oSQL:_sQuery += "    ,ZAJ_LDATA"
	_oSQL:_sQuery += "    ,ZAJ_LHORA"
	_oSQL:_sQuery += " 	,CASE"
	_oSQL:_sQuery += " 	WHEN ZAJ_CTRN = 1 THEN 'Sim'"
	_oSQL:_sQuery += " 		ELSE 'Não'"
	_oSQL:_sQuery += " 	END ZAJ_CTRN"
	_oSQL:_sQuery += " FROM " + RetSqlName("ZAJ") + " ZAJ " 
	_oSQL:_sQuery += " LEFT JOIN " + RetSqlName("SB1") + " SB1 " 
	_oSQL:_sQuery += " 		ON (SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND ZAJ.ZAJ_CPROD = SB1.B1_COD)"
	_oSQL:_sQuery += " WHERE ZAJ.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND ZAJ_FILIAL = '" + ZZX -> ZZX_FILIAL + "'"
	_oSQL:_sQuery += " AND ZAJ_CHAVE  = '" + ZZX -> ZZX_CHAVE  + "'"
	_oSQL:_sQuery += " ORDER BY ZAJ_XITEM,ZAJ_DATA "
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	_sAlias1 = _oSQL:Qry2Trb ()
	
	oSection1:Init()
	oSection2:Init()
	
	While (_sAliasQ)  -> (!Eof())
		
		If (_sAliasQ) -> TP == 'COM'
			_dt := DTOC(STOD((_sAliasQ) ->ZAJ_DATA))	
			oSection1:Cell("COLUNA0"):SetValue((_sAliasQ) -> TP)
			oSection1:Cell("COLUNA1"):SetValue((_sAliasQ) -> ZAJ_XITEM)
			oSection1:Cell("COLUNA2"):SetValue((_sAliasQ) -> ZAJ_XPROD)		
			oSection1:Cell("COLUNA3"):SetValue((_sAliasQ) -> ZAJ_XDESC)	
			oSection1:Cell("COLUNA4"):SetValue((_sAliasQ) -> ZAJ_XUN)
			oSection1:Cell("COLUNA5"):SetValue((_sAliasQ) -> ZAJ_XQUANT)	
			oSection1:Cell("COLUNA6"):SetValue((_sAliasQ) -> ZAJ_CPROD)	
			oSection1:Cell("COLUNA7"):SetValue((_sAliasQ) -> B1_DESC)	
			oSection1:Cell("COLUNA8"):SetValue((_sAliasQ) -> ZAJ_UN)	
			oSection1:Cell("COLUNA9"):SetValue((_sAliasQ) -> ZAJ_QUANT)		
			oSection1:Cell("COLUNA10"):SetValue((_sAliasQ) -> ZAJ_MOTDEV)
			oSection1:Cell("COLUNA11"):SetValue((_sAliasQ) -> ZAJ_RETOR)		
			oSection1:Cell("COLUNA12"):SetValue((_sAliasQ) -> ZAJ_NFORIG)	
			oSection1:Cell("COLUNA13"):SetValue((_sAliasQ) -> ZAJ_ITORIG)
			oSection1:Cell("COLUNA14"):SetValue((_sAliasQ) -> ZAJ_TES)	
			oSection1:Cell("COLUNA15"):SetValue((_sAliasQ) -> ZAJ_VEND)	
			oSection1:Cell("COLUNA16"):SetValue((_sAliasQ) -> ZAJ_VENDDV)	
			oSection1:Cell("COLUNA17"):SetValue((_sAliasQ) -> ZAJ_USER)	
			oSection1:Cell("COLUNA18"):SetValue(_dt)
			oSection1:Cell("COLUNA19"):SetValue((_sAliasQ) -> ZAJ_HORA)	
			oSection1:Printline()
		Else
			_dt  := DTOC(STOD((_sAliasQ) ->ZAJ_LDATA))
			_dt1 := DTOC(STOD((_sAliasQ) ->ZAJ_LPRM))	
			oSection2:Cell("COLUNA0"):SetValue((_sAliasQ) -> TP)
			oSection2:Cell("COLUNA1"):SetValue((_sAliasQ) -> ZAJ_LMOV)
			oSection2:Cell("COLUNA2"):SetValue((_sAliasQ) -> ZAJ_LAVA)
			oSection2:Cell("COLUNA3"):SetValue((_sAliasQ) -> ZAJ_LFM)		
			oSection2:Cell("COLUNA4"):SetValue((_sAliasQ) -> ZAJ_LRM)	
			oSection2:Cell("COLUNA5"):SetValue(_dt1)
			oSection2:Cell("COLUNA6"):SetValue((_sAliasQ) -> ZAJ_LUSER)	
			oSection2:Cell("COLUNA7"):SetValue(_dt)	
			oSection2:Cell("COLUNA8"):SetValue((_sAliasQ) -> ZAJ_LHORA)	
			oSection2:Cell("COLUNA9"):SetValue((_sAliasQ) -> ZAJ_CTRN)	
			oSection2:Printline()
		EndIf
		
	(_sAliasQ) -> (dbskip ())
	EndDo
	
	oSection1:Finish()
	oSection2:Finish()
Return
// ------------------------------------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	aadd (_aRegsPerg, {01, "XML's c/Lançamento  Pendente ?", "N", 1, 0,  "",   "   ", {"Sim", "Todos"}, ""})
	aadd (_aRegsPerg, {02, "Lista CT-e                   ?", "N", 1, 0,  "",   "   ", {"Sim", "Nao"}  , ""})
	aadd (_aRegsPerg, {03, "Lista NF-e                   ?", "N", 1, 0,  "",   "   ", {"Sim","Nao","Devolucao","Normal","Outras"}, ""})
	aadd (_aRegsPerg, {04, "Fornecedor                   ?", "C", 6, 0,  "",   "SA2", {}, "Código do Fornecedor"})
	aadd (_aRegsPerg, {05, "Cliente                      ?", "C", 6, 0,  "",   "SA1", {}, "Codigo do Cliente"})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
