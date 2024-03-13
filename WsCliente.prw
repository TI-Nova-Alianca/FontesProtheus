//Bibliotecas
#Include "Totvs.ch"
#Include "RESTFul.ch"
#Include "TopConn.ch"

WSRESTFUL WSCliente DESCRIPTION 'Clientes'
    //Atributos
    WSDATA id         AS STRING
    WSDATA updated_at AS STRING
    WSDATA limit      AS INTEGER
    WSDATA page       AS INTEGER
 
    //Métodos
    WSMETHOD GET    ID     DESCRIPTION 'Retorna o registro pesquisado' WSSYNTAX '/WSCliente/get_id?{id}'                       PATH 'get_id'        PRODUCES APPLICATION_JSON
    WSMETHOD GET    ALL    DESCRIPTION 'Retorna todos os registros'    WSSYNTAX '/WSCliente/get_all?{updated_at, limit, page}' PATH 'get_all'       PRODUCES APPLICATION_JSON
    WSMETHOD POST   NEW    DESCRIPTION 'Inclusão de registro'          WSSYNTAX '/WSCliente/new'                               PATH 'new'           PRODUCES APPLICATION_JSON
    WSMETHOD PUT    UPDATE DESCRIPTION 'Atualização de registro'       WSSYNTAX '/WSCliente/update'                            PATH 'update'        PRODUCES APPLICATION_JSON
    WSMETHOD DELETE ERASE  DESCRIPTION 'Exclusão de registro'          WSSYNTAX '/WSCliente/erase'                             PATH 'erase'         PRODUCES APPLICATION_JSON
END WSRESTFUL
//
// --------------------------------------------------------------------------------------
// WSMETHOD GET ID - Busca registro via ID
// @param id, Caractere, String que será pesquisada através do MsSeek
WSMETHOD GET ID WSRECEIVE id WSSERVICE WSCliente
    Local lRet       := .T.
    Local jResponse  := JsonObject():New()
    Local cAliasWS   := 'SA1'

    //Se o id estiver vazio
    If Empty(::id)
        //SetRestFault(500, 'Falha ao consultar o registro') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
        Self:setStatus(500) 
        jResponse['errorId']  := 'ID001'
        jResponse['error']    := 'ID vazio'
        jResponse['solution'] := 'Informe o ID'
    Else
        DbSelectArea(cAliasWS)
        (cAliasWS)->(DbSetOrder(1))

        //Se não encontrar o registro
        If ! (cAliasWS)->(MsSeek(FWxFilial(cAliasWS) + ::id))
            //SetRestFault(500, 'Falha ao consultar ID') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
            Self:setStatus(500) 
            jResponse['errorId']  := 'ID002'
            jResponse['error']    := 'ID não encontrado'
            jResponse['solution'] := 'Código ID não encontrado na tabela ' + cAliasWS
        Else
            //Define o retorno
            jResponse['filial'] := (cAliasWS)->A1_FILIAL 
            jResponse['msblql'] := (cAliasWS)->A1_MSBLQL 
            jResponse['cod'] := (cAliasWS)->A1_COD 
            jResponse['loja'] := (cAliasWS)->A1_LOJA 
            jResponse['nome'] := (cAliasWS)->A1_NOME 
            jResponse['pessoa'] := (cAliasWS)->A1_PESSOA 
            jResponse['tipo'] := (cAliasWS)->A1_TIPO 
            jResponse['nreduz'] := (cAliasWS)->A1_NREDUZ 
            jResponse['end'] := (cAliasWS)->A1_END 
            jResponse['est'] := (cAliasWS)->A1_EST 
            jResponse['cod_mun'] := (cAliasWS)->A1_COD_MUN 
            jResponse['bairro'] := (cAliasWS)->A1_BAIRRO 
            jResponse['cep'] := (cAliasWS)->A1_CEP 
            jResponse['tel'] := (cAliasWS)->A1_TEL 
            //jResponse['fax'] := (cAliasWS)->A1_FAX 
            jResponse['contato'] := (cAliasWS)->A1_CONTATO 
            jResponse['cgc'] := (cAliasWS)->A1_CGC 
            jResponse['inscr'] := (cAliasWS)->A1_INSCR 
            jResponse['vend'] := (cAliasWS)->A1_VEND 
            jResponse['bco1'] := (cAliasWS)->A1_BCO1 
            jResponse['forma'] := (cAliasWS)->A1_FORMA 
            jResponse['ultvis'] := (cAliasWS)->A1_ULTVIS 
            jResponse['cxposta'] := (cAliasWS)->A1_CXPOSTA 
            jResponse['endcob'] := (cAliasWS)->A1_ENDCOB 
            jResponse['bairroc'] := (cAliasWS)->A1_BAIRROC 
            jResponse['cepc'] := (cAliasWS)->A1_CEPC 
            jResponse['munc'] := (cAliasWS)->A1_MUNC 
            jResponse['estc'] := (cAliasWS)->A1_ESTC 
            jResponse['email'] := (cAliasWS)->A1_EMAIL 
            jResponse['vamdanf'] := (cAliasWS)->A1_VAMDANF 
            jResponse['hpage'] := (cAliasWS)->A1_HPAGE 
            jResponse['vauser'] := (cAliasWS)->A1_VAUSER 
            jResponse['vacanal'] := (cAliasWS)->A1_VACANAL 
            jResponse['sativ1'] := (cAliasWS)->A1_SATIV1 
            jResponse['simpnac'] := (cAliasWS)->A1_SIMPNAC 
            jResponse['vabarap'] := (cAliasWS)->A1_VABARAP 
            jResponse['vadtinc'] := (cAliasWS)->A1_VADTINC 
            jResponse['iencont'] := (cAliasWS)->A1_IENCONT 
            jResponse['contrib'] := (cAliasWS)->A1_CONTRIB 
            jResponse['cnae'] := (cAliasWS)->A1_CNAE 
            jResponse['contat3'] := (cAliasWS)->A1_CONTAT3 
            jResponse['telcob'] := (cAliasWS)->A1_TELCOB 
            jResponse['vaemlf'] := (cAliasWS)->A1_VAEMLF 
            jResponse['vabcof'] := (cAliasWS)->A1_VABCOF 
            jResponse['vaagfin'] := (cAliasWS)->A1_VAAGFIN 
            jResponse['vactafn'] := (cAliasWS)->A1_VACTAFN 
            jResponse['vacgcfi'] := (cAliasWS)->A1_VACGCFI 
            jResponse['vamdanf'] := (cAliasWS)->A1_VAMDANF 
            jResponse['savblq'] := (cAliasWS)->A1_SAVBLQ 
        EndIf
    EndIf

    //Define o retorno
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())
Return lRet
//
// --------------------------------------------------------------------------------------
// WSMETHOD GET ALL - Busca todos os registros através de paginação
//@param updated_at, Caractere, Data de alteração no formato string 'YYYY-MM-DD' (somente se tiver o campo USERLGA / USERGA na tabela)
//@param limit, Numérico, Limite de registros que irá vir (por exemplo trazer apenas 100 registros)
//@param page, Numérico, Número da página que irá buscar (se existir 1000 registros dividido por 100 terá 10 páginas de pesquisa)

WSMETHOD GET ALL WSRECEIVE updated_at, limit, page WSSERVICE WSCliente
    Local lRet       := .T.
    Local jResponse  := JsonObject():New()
    Local cQueryTab  := ''
    Local nTamanho   := 10
    Local nTotal     := 0
    Local nPags      := 0
    Local nPagina    := 0
    Local nAtual     := 0
    Local oRegistro
    Local cAliasWS   := 'SA1'

    //Efetua a busca dos registros
    cQueryTab := " SELECT " + CRLF
    cQueryTab += "     TAB.R_E_C_N_O_ AS TABREC " + CRLF
    cQueryTab += " FROM " + CRLF
    cQueryTab += "     " + RetSQLName(cAliasWS) + " TAB " + CRLF
    cQueryTab += " WHERE " + CRLF
    cQueryTab += "     TAB.D_E_L_E_T_ = '' " + CRLF
    If ! Empty(::updated_at)
        cQueryTab += "     AND ((CASE WHEN SUBSTRING(A1_USERLGA, 03, 1) != ' ' THEN " + CRLF
        cQueryTab += "        CONVERT(VARCHAR,DATEADD(DAY,((ASCII(SUBSTRING(A1_USERLGA,12,1)) - 50) * 100 + (ASCII(SUBSTRING(A1_USERLGA,16,1)) - 50)),'19960101'),112) " + CRLF
        cQueryTab += "        ELSE '' " + CRLF
        cQueryTab += "     END) >= '" + StrTran(::updated_at, '-', '') + "') " + CRLF
    EndIf
    cQueryTab += " ORDER BY " + CRLF
    cQueryTab += "     TABREC " + CRLF
    TCQuery cQueryTab New Alias 'QRY_TAB'

    //Se não encontrar registros
    If QRY_TAB->(EoF())
        //SetRestFault(500, 'Falha ao consultar registros') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
        Self:setStatus(500) 
        jResponse['errorId']  := 'ALL003'
        jResponse['error']    := 'Registro(s) não encontrado(s)'
        jResponse['solution'] := 'A consulta de registros não retornou nenhuma informação'
    Else
        jResponse['objects'] := {}

        //Conta o total de registros
        Count To nTotal
        QRY_TAB->(DbGoTop())

        //O tamanho do retorno, será o limit, se ele estiver definido
        If ! Empty(::limit)
            nTamanho := ::limit
        EndIf

        //Pegando total de páginas
        nPags := NoRound(nTotal / nTamanho, 0)
        nPags += Iif(nTotal % nTamanho != 0, 1, 0)
        
        //Se vier página
        If ! Empty(::page)
            nPagina := ::page
        EndIf

        //Se a página vier zerada ou negativa ou for maior que o máximo, será 1 
        If nPagina <= 0 .Or. nPagina > nPags
            nPagina := 1
        EndIf

        //Se a página for diferente de 1, pula os registros
        If nPagina != 1
            QRY_TAB->(DbSkip((nPagina-1) * nTamanho))
        EndIf

        //Adiciona os dados para a meta
        jJsonMeta := JsonObject():New()
        jJsonMeta['total']         := nTotal
        jJsonMeta['current_page']  := nPagina
        jJsonMeta['total_page']    := nPags
        jJsonMeta['total_items']   := nTamanho
        jResponse['meta'] := jJsonMeta

        //Percorre os registros
        While ! QRY_TAB->(EoF())
            nAtual++
            
            //Se ultrapassar o limite, encerra o laço
            If nAtual > nTamanho
                Exit
            EndIf

            //Posiciona o registro e adiciona no retorno
            DbSelectArea(cAliasWS)
            (cAliasWS)->(DbGoTo(QRY_TAB->TABREC))
            
            oRegistro := JsonObject():New()
            oRegistro['filial'] := (cAliasWS)->A1_FILIAL 
            oRegistro['msblql'] := (cAliasWS)->A1_MSBLQL 
            oRegistro['cod'] := (cAliasWS)->A1_COD 
            oRegistro['loja'] := (cAliasWS)->A1_LOJA 
            oRegistro['nome'] := (cAliasWS)->A1_NOME 
            oRegistro['pessoa'] := (cAliasWS)->A1_PESSOA 
            oRegistro['tipo'] := (cAliasWS)->A1_TIPO 
            oRegistro['nreduz'] := (cAliasWS)->A1_NREDUZ 
            oRegistro['end'] := (cAliasWS)->A1_END 
            oRegistro['est'] := (cAliasWS)->A1_EST 
            oRegistro['cod_mun'] := (cAliasWS)->A1_COD_MUN 
            oRegistro['bairro'] := (cAliasWS)->A1_BAIRRO 
            oRegistro['cep'] := (cAliasWS)->A1_CEP 
            oRegistro['tel'] := (cAliasWS)->A1_TEL 
            //oRegistro['fax'] := (cAliasWS)->A1_FAX 
            oRegistro['contato'] := (cAliasWS)->A1_CONTATO 
            oRegistro['cgc'] := (cAliasWS)->A1_CGC 
            oRegistro['inscr'] := (cAliasWS)->A1_INSCR 
            oRegistro['vend'] := (cAliasWS)->A1_VEND 
            oRegistro['bco1'] := (cAliasWS)->A1_BCO1 
            oRegistro['forma'] := (cAliasWS)->A1_FORMA 
            oRegistro['ultvis'] := (cAliasWS)->A1_ULTVIS 
            oRegistro['cxposta'] := (cAliasWS)->A1_CXPOSTA 
            oRegistro['endcob'] := (cAliasWS)->A1_ENDCOB 
            oRegistro['bairroc'] := (cAliasWS)->A1_BAIRROC 
            oRegistro['cepc'] := (cAliasWS)->A1_CEPC 
            oRegistro['munc'] := (cAliasWS)->A1_MUNC 
            oRegistro['estc'] := (cAliasWS)->A1_ESTC 
            oRegistro['email'] := (cAliasWS)->A1_EMAIL 
            oRegistro['vamdanf'] := (cAliasWS)->A1_VAMDANF 
            oRegistro['hpage'] := (cAliasWS)->A1_HPAGE 
            oRegistro['vauser'] := (cAliasWS)->A1_VAUSER 
            oRegistro['vacanal'] := (cAliasWS)->A1_VACANAL 
            oRegistro['sativ1'] := (cAliasWS)->A1_SATIV1 
            oRegistro['simpnac'] := (cAliasWS)->A1_SIMPNAC 
            oRegistro['vabarap'] := (cAliasWS)->A1_VABARAP 
            oRegistro['vadtinc'] := (cAliasWS)->A1_VADTINC 
            oRegistro['iencont'] := (cAliasWS)->A1_IENCONT 
            oRegistro['contrib'] := (cAliasWS)->A1_CONTRIB 
            oRegistro['cnae'] := (cAliasWS)->A1_CNAE 
            oRegistro['contat3'] := (cAliasWS)->A1_CONTAT3 
            oRegistro['telcob'] := (cAliasWS)->A1_TELCOB 
            oRegistro['vaemlf'] := (cAliasWS)->A1_VAEMLF 
            oRegistro['vabcof'] := (cAliasWS)->A1_VABCOF 
            oRegistro['vaagfin'] := (cAliasWS)->A1_VAAGFIN 
            oRegistro['vactafn'] := (cAliasWS)->A1_VACTAFN 
            oRegistro['vacgcfi'] := (cAliasWS)->A1_VACGCFI 
            oRegistro['vamdanf'] := (cAliasWS)->A1_VAMDANF 
            oRegistro['savblq'] := (cAliasWS)->A1_SAVBLQ 
            aAdd(jResponse['objects'], oRegistro)

            QRY_TAB->(DbSkip())
        EndDo
    EndIf
    QRY_TAB->(DbCloseArea())

    //Define o retorno
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())
Return lRet
//
// --------------------------------------------------------------------------------------
// WSMETHOD POST NEW - Cria um novo registro na tabela

/*    Abaixo um exemplo do JSON que deverá vir no body
    * 1: Para campos do tipo Numérico, informe o valor sem usar as aspas
    * 2: Para campos do tipo Data, informe uma string no padrão 'YYYY-MM-DD'

    {
        "filial": "conteudo",
        "msblql": "conteudo",
        "cod": "conteudo",
        "loja": "conteudo",
        "nome": "conteudo",
        "pessoa": "conteudo",
        "tipo": "conteudo",
        "nreduz": "conteudo",
        "end": "conteudo",
        "est": "conteudo",
        "cod_mun": "conteudo",
        "bairro": "conteudo",
        "cep": "conteudo",
        "tel": "conteudo",
        "fax": "conteudo",
        "contato": "conteudo",
        "cgc": "conteudo",
        "inscr": "conteudo",
        "vend": "conteudo",
        "bco1": "conteudo",
        "forma": "conteudo",
        "ultvis": "conteudo",
        "cxposta": "conteudo",
        "endcob": "conteudo",
        "bairroc": "conteudo",
        "cepc": "conteudo",
        "munc": "conteudo",
        "estc": "conteudo",
        "email": "conteudo",
        "vamdanf": "conteudo",
        "hpage": "conteudo",
        "vauser": "conteudo",
        "vacanal": "conteudo",
        "sativ1": "conteudo",
        "simpnac": "conteudo",
        "vabarap": "conteudo",
        "vadtinc": "conteudo",
        "iencont": "conteudo",
        "contrib": "conteudo",
        "cnae": "conteudo",
        "contat3": "conteudo",
        "telcob": "conteudo",
        "vaemlf": "conteudo",
        "vabcof": "conteudo",
        "vaagfin": "conteudo",
        "vactafn": "conteudo",
        "vacgcfi": "conteudo",
        "vamdanf": "conteudo",
        "savblq": "conteudo"
    }
    */

WSMETHOD POST NEW WSRECEIVE WSSERVICE WSCliente
    Local lRet              := .T.
    Local aDados            := {}
    Local jJson             := Nil
    Local cJson             := Self:GetContent()
    Local cError            := ''
    Local nLinha            := 0
    Local cDirLog           := '\x_logs\'
    Local cArqLog           := ''
    Local cErrorLog         := ''
    Local aLogAuto          := {}
    Local nCampo            := 0
    Local jResponse         := JsonObject():New()
    Local cAliasWS          := 'SA1'
    Private lMsErroAuto     := .F.
    Private lMsHelpAuto     := .T.
    Private lAutoErrNoFile  := .T.
 
    //Se não existir a pasta de logs, cria
    IF ! ExistDir(cDirLog)
        MakeDir(cDirLog)
    EndIF    

    //Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
    Self:SetContentType('application/json')
    jJson  := JsonObject():New()
    cError := jJson:FromJson(cJson)
 
    //Se tiver algum erro no Parse, encerra a execução
    IF ! Empty(cError)
        //SetRestFault(500, 'Falha ao obter JSON') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
        Self:setStatus(500) 
        jResponse['errorId']  := 'NEW004'
        jResponse['error']    := 'Parse do JSON'
        jResponse['solution'] := 'Erro ao fazer o Parse do JSON'

    Else
		DbSelectArea(cAliasWS)
       
		//Adiciona os dados do ExecAuto
		aAdd(aDados, {'A1_FILIAL',   jJson:GetJsonObject('filial'),   Nil})
		aAdd(aDados, {'A1_MSBLQL',   jJson:GetJsonObject('msblql'),   Nil})
		aAdd(aDados, {'A1_COD',   jJson:GetJsonObject('cod'),   Nil})
		aAdd(aDados, {'A1_LOJA',   jJson:GetJsonObject('loja'),   Nil})
		aAdd(aDados, {'A1_NOME',   jJson:GetJsonObject('nome'),   Nil})
		aAdd(aDados, {'A1_PESSOA',   jJson:GetJsonObject('pessoa'),   Nil})
		aAdd(aDados, {'A1_TIPO',   jJson:GetJsonObject('tipo'),   Nil})
		aAdd(aDados, {'A1_NREDUZ',   jJson:GetJsonObject('nreduz'),   Nil})
		aAdd(aDados, {'A1_END',   jJson:GetJsonObject('end'),   Nil})
		aAdd(aDados, {'A1_EST',   jJson:GetJsonObject('est'),   Nil})
		aAdd(aDados, {'A1_COD_MUN',   jJson:GetJsonObject('cod_mun'),   Nil})
		aAdd(aDados, {'A1_BAIRRO',   jJson:GetJsonObject('bairro'),   Nil})
		aAdd(aDados, {'A1_CEP',   jJson:GetJsonObject('cep'),   Nil})
		aAdd(aDados, {'A1_TEL',   jJson:GetJsonObject('tel'),   Nil})
		//aAdd(aDados, {'A1_FAX',   jJson:GetJsonObject('fax'),   Nil})
		aAdd(aDados, {'A1_CONTATO',   jJson:GetJsonObject('contato'),   Nil})
		aAdd(aDados, {'A1_CGC',   jJson:GetJsonObject('cgc'),   Nil})
		aAdd(aDados, {'A1_INSCR',   jJson:GetJsonObject('inscr'),   Nil})
		aAdd(aDados, {'A1_VEND',   jJson:GetJsonObject('vend'),   Nil})
		aAdd(aDados, {'A1_BCO1',   jJson:GetJsonObject('bco1'),   Nil})
		aAdd(aDados, {'A1_FORMA',   jJson:GetJsonObject('forma'),   Nil})
		aAdd(aDados, {'A1_ULTVIS',   jJson:GetJsonObject('ultvis'),   Nil})
		aAdd(aDados, {'A1_CXPOSTA',   jJson:GetJsonObject('cxposta'),   Nil})
		aAdd(aDados, {'A1_ENDCOB',   jJson:GetJsonObject('endcob'),   Nil})
		aAdd(aDados, {'A1_BAIRROC',   jJson:GetJsonObject('bairroc'),   Nil})
		aAdd(aDados, {'A1_CEPC',   jJson:GetJsonObject('cepc'),   Nil})
		aAdd(aDados, {'A1_MUNC',   jJson:GetJsonObject('munc'),   Nil})
		aAdd(aDados, {'A1_ESTC',   jJson:GetJsonObject('estc'),   Nil})
		aAdd(aDados, {'A1_EMAIL',   jJson:GetJsonObject('email'),   Nil})
		aAdd(aDados, {'A1_VAMDANF',   jJson:GetJsonObject('vamdanf'),   Nil})
		aAdd(aDados, {'A1_HPAGE',   jJson:GetJsonObject('hpage'),   Nil})
		aAdd(aDados, {'A1_VAUSER',   jJson:GetJsonObject('vauser'),   Nil})
		aAdd(aDados, {'A1_VACANAL',   jJson:GetJsonObject('vacanal'),   Nil})
		aAdd(aDados, {'A1_SATIV1',   jJson:GetJsonObject('sativ1'),   Nil})
		aAdd(aDados, {'A1_SIMPNAC',   jJson:GetJsonObject('simpnac'),   Nil})
		aAdd(aDados, {'A1_VABARAP',   jJson:GetJsonObject('vabarap'),   Nil})
		aAdd(aDados, {'A1_VADTINC',   jJson:GetJsonObject('vadtinc'),   Nil})
		aAdd(aDados, {'A1_IENCONT',   jJson:GetJsonObject('iencont'),   Nil})
		aAdd(aDados, {'A1_CONTRIB',   jJson:GetJsonObject('contrib'),   Nil})
		aAdd(aDados, {'A1_CNAE',   jJson:GetJsonObject('cnae'),   Nil})
		aAdd(aDados, {'A1_CONTAT3',   jJson:GetJsonObject('contat3'),   Nil})
		aAdd(aDados, {'A1_TELCOB',   jJson:GetJsonObject('telcob'),   Nil})
		aAdd(aDados, {'A1_VAEMLF',   jJson:GetJsonObject('vaemlf'),   Nil})
		aAdd(aDados, {'A1_VABCOF',   jJson:GetJsonObject('vabcof'),   Nil})
		aAdd(aDados, {'A1_VAAGFIN',   jJson:GetJsonObject('vaagfin'),   Nil})
		aAdd(aDados, {'A1_VACTAFN',   jJson:GetJsonObject('vactafn'),   Nil})
		aAdd(aDados, {'A1_VACGCFI',   jJson:GetJsonObject('vacgcfi'),   Nil})
		aAdd(aDados, {'A1_VAMDANF',   jJson:GetJsonObject('vamdanf'),   Nil})
		aAdd(aDados, {'A1_SAVBLQ',   jJson:GetJsonObject('savblq'),   Nil})
		
		//Percorre os dados do execauto
		For nCampo := 1 To Len(aDados)
			//Se o campo for data, retira os hifens e faz a conversão
			If GetSX3Cache(aDados[nCampo][1], 'X3_TIPO') == 'D'
				aDados[nCampo][2] := StrTran(aDados[nCampo][2], '-', '')
				aDados[nCampo][2] := sToD(aDados[nCampo][2])
			EndIf
		Next

		//Chama a inclusão automática
		MsExecAuto({|x, y| MATA030(x, y)}, aDados, 3)

		//Se houve erro, gera um arquivo de log dentro do diretório da protheus data
		If lMsErroAuto
			//Monta o texto do Error Log que será salvo
			cErrorLog   := ''
			aLogAuto    := GetAutoGrLog()
			For nLinha := 1 To Len(aLogAuto)
				cErrorLog += aLogAuto[nLinha] + CRLF
			Next nLinha

			//Grava o arquivo de log
			cArqLog := 'WSCliente_New_' + dToS(Date()) + '_' + StrTran(Time(), ':', '-') + '.log'
			MemoWrite(cDirLog + cArqLog, cErrorLog)

			//Define o retorno para o WebService
			//SetRestFault(500, cErrorLog) //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
           Self:setStatus(500) 
			jResponse['errorId']  := 'NEW005'
			jResponse['error']    := 'Erro na inclusão do registro'
			jResponse['solution'] := 'Nao foi possivel incluir o registro, foi gerado um arquivo de log em ' + cDirLog + cArqLog + ' '
			lRet := .F.

		//Senão, define o retorno
		Else
			jResponse['note']     := 'Registro incluido com sucesso'
		EndIf

    EndIf

    //Define o retorno
    Self:SetResponse(jResponse:toJSON())
Return lRet
//
// --------------------------------------------------------------------------------------
// WSMETHOD PUT UPDATE - Atualiza o registro na tabela
// @param id, Caractere, String que será pesquisada através do MsSeek
/*
    Abaixo um exemplo do JSON que deverá vir no body
    * 1: Para campos do tipo Numérico, informe o valor sem usar as aspas
    * 2: Para campos do tipo Data, informe uma string no padrão 'YYYY-MM-DD'

    {
        "filial": "conteudo",
        "msblql": "conteudo",
        "cod": "conteudo",
        "loja": "conteudo",
        "nome": "conteudo",
        "pessoa": "conteudo",
        "tipo": "conteudo",
        "nreduz": "conteudo",
        "end": "conteudo",
        "est": "conteudo",
        "cod_mun": "conteudo",
        "bairro": "conteudo",
        "cep": "conteudo",
        "tel": "conteudo",
        "fax": "conteudo",
        "contato": "conteudo",
        "cgc": "conteudo",
        "inscr": "conteudo",
        "vend": "conteudo",
        "bco1": "conteudo",
        "forma": "conteudo",
        "ultvis": "conteudo",
        "cxposta": "conteudo",
        "endcob": "conteudo",
        "bairroc": "conteudo",
        "cepc": "conteudo",
        "munc": "conteudo",
        "estc": "conteudo",
        "email": "conteudo",
        "vamdanf": "conteudo",
        "hpage": "conteudo",
        "vauser": "conteudo",
        "vacanal": "conteudo",
        "sativ1": "conteudo",
        "simpnac": "conteudo",
        "vabarap": "conteudo",
        "vadtinc": "conteudo",
        "iencont": "conteudo",
        "contrib": "conteudo",
        "cnae": "conteudo",
        "contat3": "conteudo",
        "telcob": "conteudo",
        "vaemlf": "conteudo",
        "vabcof": "conteudo",
        "vaagfin": "conteudo",
        "vactafn": "conteudo",
        "vacgcfi": "conteudo",
        "vamdanf": "conteudo",
        "savblq": "conteudo"
    }
*/

WSMETHOD PUT UPDATE WSRECEIVE id WSSERVICE WSCliente
    Local lRet              := .T.
    Local aDados            := {}
    Local jJson             := Nil
    Local cJson             := Self:GetContent()
    Local cError            := ''
    Local nLinha            := 0
    Local cDirLog           := '\x_logs\'
    Local cArqLog           := ''
    Local cErrorLog         := ''
    Local aLogAuto          := {}
    Local nCampo            := 0
    Local jResponse         := JsonObject():New()
    Local cAliasWS          := 'SA1'
    Private lMsErroAuto     := .F.
    Private lMsHelpAuto     := .T.
    Private lAutoErrNoFile  := .T.

    //Se não existir a pasta de logs, cria
    IF ! ExistDir(cDirLog)
        MakeDir(cDirLog)
    EndIF    

    //Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
    Self:SetContentType('application/json')
    jJson  := JsonObject():New()
    cError := jJson:FromJson(cJson)

    //Se o id estiver vazio
    If Empty(::id)
        //SetRestFault(500, 'Falha ao consultar o registro') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
        Self:setStatus(500) 
        jResponse['errorId']  := 'UPD006'
        jResponse['error']    := 'ID vazio'
        jResponse['solution'] := 'Informe o ID'
    Else
        DbSelectArea(cAliasWS)
        (cAliasWS)->(DbSetOrder(1))

        //Se não encontrar o registro
        If ! (cAliasWS)->(MsSeek(FWxFilial(cAliasWS) + ::id))
            //SetRestFault(500, 'Falha ao consultar ID') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
            Self:setStatus(500) 
            jResponse['errorId']  := 'UPD007'
            jResponse['error']    := 'ID não encontrado'
            jResponse['solution'] := 'Código ID não encontrado na tabela ' + cAliasWS
        Else
 
            //Se tiver algum erro no Parse, encerra a execução
            If ! Empty(cError)
                //SetRestFault(500, 'Falha ao obter JSON') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
                Self:setStatus(500) 
                jResponse['errorId']  := 'UPD008'
                jResponse['error']    := 'Parse do JSON'
                jResponse['solution'] := 'Erro ao fazer o Parse do JSON'

            Else
		         DbSelectArea(cAliasWS)
                
		         //Adiciona os dados do ExecAuto
		         aAdd(aDados, {'A1_FILIAL',   jJson:GetJsonObject('filial'),   Nil})
		         aAdd(aDados, {'A1_MSBLQL',   jJson:GetJsonObject('msblql'),   Nil})
		         aAdd(aDados, {'A1_COD',   jJson:GetJsonObject('cod'),   Nil})
		         aAdd(aDados, {'A1_LOJA',   jJson:GetJsonObject('loja'),   Nil})
		         aAdd(aDados, {'A1_NOME',   jJson:GetJsonObject('nome'),   Nil})
		         aAdd(aDados, {'A1_PESSOA',   jJson:GetJsonObject('pessoa'),   Nil})
		         aAdd(aDados, {'A1_TIPO',   jJson:GetJsonObject('tipo'),   Nil})
		         aAdd(aDados, {'A1_NREDUZ',   jJson:GetJsonObject('nreduz'),   Nil})
		         aAdd(aDados, {'A1_END',   jJson:GetJsonObject('end'),   Nil})
		         aAdd(aDados, {'A1_EST',   jJson:GetJsonObject('est'),   Nil})
		         aAdd(aDados, {'A1_COD_MUN',   jJson:GetJsonObject('cod_mun'),   Nil})
		         aAdd(aDados, {'A1_BAIRRO',   jJson:GetJsonObject('bairro'),   Nil})
		         aAdd(aDados, {'A1_CEP',   jJson:GetJsonObject('cep'),   Nil})
		         aAdd(aDados, {'A1_TEL',   jJson:GetJsonObject('tel'),   Nil})
		         //aAdd(aDados, {'A1_FAX',   jJson:GetJsonObject('fax'),   Nil})
		         aAdd(aDados, {'A1_CONTATO',   jJson:GetJsonObject('contato'),   Nil})
		         aAdd(aDados, {'A1_CGC',   jJson:GetJsonObject('cgc'),   Nil})
		         aAdd(aDados, {'A1_INSCR',   jJson:GetJsonObject('inscr'),   Nil})
		         aAdd(aDados, {'A1_VEND',   jJson:GetJsonObject('vend'),   Nil})
		         aAdd(aDados, {'A1_BCO1',   jJson:GetJsonObject('bco1'),   Nil})
		         aAdd(aDados, {'A1_FORMA',   jJson:GetJsonObject('forma'),   Nil})
		         aAdd(aDados, {'A1_ULTVIS',   jJson:GetJsonObject('ultvis'),   Nil})
		         aAdd(aDados, {'A1_CXPOSTA',   jJson:GetJsonObject('cxposta'),   Nil})
		         aAdd(aDados, {'A1_ENDCOB',   jJson:GetJsonObject('endcob'),   Nil})
		         aAdd(aDados, {'A1_BAIRROC',   jJson:GetJsonObject('bairroc'),   Nil})
		         aAdd(aDados, {'A1_CEPC',   jJson:GetJsonObject('cepc'),   Nil})
		         aAdd(aDados, {'A1_MUNC',   jJson:GetJsonObject('munc'),   Nil})
		         aAdd(aDados, {'A1_ESTC',   jJson:GetJsonObject('estc'),   Nil})
		         aAdd(aDados, {'A1_EMAIL',   jJson:GetJsonObject('email'),   Nil})
		         aAdd(aDados, {'A1_VAMDANF',   jJson:GetJsonObject('vamdanf'),   Nil})
		         aAdd(aDados, {'A1_HPAGE',   jJson:GetJsonObject('hpage'),   Nil})
		         aAdd(aDados, {'A1_VAUSER',   jJson:GetJsonObject('vauser'),   Nil})
		         aAdd(aDados, {'A1_VACANAL',   jJson:GetJsonObject('vacanal'),   Nil})
		         aAdd(aDados, {'A1_SATIV1',   jJson:GetJsonObject('sativ1'),   Nil})
		         aAdd(aDados, {'A1_SIMPNAC',   jJson:GetJsonObject('simpnac'),   Nil})
		         aAdd(aDados, {'A1_VABARAP',   jJson:GetJsonObject('vabarap'),   Nil})
		         aAdd(aDados, {'A1_VADTINC',   jJson:GetJsonObject('vadtinc'),   Nil})
		         aAdd(aDados, {'A1_IENCONT',   jJson:GetJsonObject('iencont'),   Nil})
		         aAdd(aDados, {'A1_CONTRIB',   jJson:GetJsonObject('contrib'),   Nil})
		         aAdd(aDados, {'A1_CNAE',   jJson:GetJsonObject('cnae'),   Nil})
		         aAdd(aDados, {'A1_CONTAT3',   jJson:GetJsonObject('contat3'),   Nil})
		         aAdd(aDados, {'A1_TELCOB',   jJson:GetJsonObject('telcob'),   Nil})
		         aAdd(aDados, {'A1_VAEMLF',   jJson:GetJsonObject('vaemlf'),   Nil})
		         aAdd(aDados, {'A1_VABCOF',   jJson:GetJsonObject('vabcof'),   Nil})
		         aAdd(aDados, {'A1_VAAGFIN',   jJson:GetJsonObject('vaagfin'),   Nil})
		         aAdd(aDados, {'A1_VACTAFN',   jJson:GetJsonObject('vactafn'),   Nil})
		         aAdd(aDados, {'A1_VACGCFI',   jJson:GetJsonObject('vacgcfi'),   Nil})
		         aAdd(aDados, {'A1_VAMDANF',   jJson:GetJsonObject('vamdanf'),   Nil})
		         aAdd(aDados, {'A1_SAVBLQ',   jJson:GetJsonObject('savblq'),   Nil})
		         
		         //Percorre os dados do execauto
		         For nCampo := 1 To Len(aDados)
		         	//Se o campo for data, retira os hifens e faz a conversão
		         	If GetSX3Cache(aDados[nCampo][1], 'X3_TIPO') == 'D'
		         		aDados[nCampo][2] := StrTran(aDados[nCampo][2], '-', '')
		         		aDados[nCampo][2] := sToD(aDados[nCampo][2])
		         	EndIf
		         Next

		         //Chama a atualização automática
		         MsExecAuto({|x, y| MATA030(x, y)}, aDados, 4)

		         //Se houve erro, gera um arquivo de log dentro do diretório da protheus data
		         If lMsErroAuto
		         	//Monta o texto do Error Log que será salvo
		         	cErrorLog   := ''
		         	aLogAuto    := GetAutoGrLog()
		         	For nLinha := 1 To Len(aLogAuto)
		         		cErrorLog += aLogAuto[nLinha] + CRLF
		         	Next nLinha

		            //Grava o arquivo de log
		            cArqLog := 'WSCliente_New_' + dToS(Date()) + '_' + StrTran(Time(), ':', '-') + '.log'
		            MemoWrite(cDirLog + cArqLog, cErrorLog)

		            //Define o retorno para o WebService
		            //SetRestFault(500, cErrorLog) //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
		            Self:setStatus(500) 
		            jResponse['errorId']  := 'UPD009'
		            jResponse['error']    := 'Erro na atualização do registro'
		            jResponse['solution'] := 'Nao foi possivel incluir o registro, foi gerado um arquivo de log em ' + cDirLog + cArqLog + ' '
		            lRet := .F.

		         //Senão, define o retorno
		         Else
		         	jResponse['note']     := 'Registro incluido com sucesso'
		         EndIf

		     EndIf
		 EndIf
    EndIf

    //Define o retorno
    Self:SetResponse(jResponse:toJSON())
Return lRet
//
// --------------------------------------------------------------------------------------
// WSMETHOD DELETE ERASE - Apaga o registro na tabela
// @param id, Caractere, String que será pesquisada através do MsSeek
/*
    Abaixo um exemplo do JSON que deverá vir no body
    * 1: Para campos do tipo Numérico, informe o valor sem usar as aspas
    * 2: Para campos do tipo Data, informe uma string no padrão 'YYYY-MM-DD'

    {
        "filial": "conteudo",
        "msblql": "conteudo",
        "cod": "conteudo",
        "loja": "conteudo",
        "nome": "conteudo",
        "pessoa": "conteudo",
        "tipo": "conteudo",
        "nreduz": "conteudo",
        "end": "conteudo",
        "est": "conteudo",
        "cod_mun": "conteudo",
        "bairro": "conteudo",
        "cep": "conteudo",
        "tel": "conteudo",
        "fax": "conteudo",
        "contato": "conteudo",
        "cgc": "conteudo",
        "inscr": "conteudo",
        "vend": "conteudo",
        "bco1": "conteudo",
        "forma": "conteudo",
        "ultvis": "conteudo",
        "cxposta": "conteudo",
        "endcob": "conteudo",
        "bairroc": "conteudo",
        "cepc": "conteudo",
        "munc": "conteudo",
        "estc": "conteudo",
        "email": "conteudo",
        "vamdanf": "conteudo",
        "hpage": "conteudo",
        "vauser": "conteudo",
        "vacanal": "conteudo",
        "sativ1": "conteudo",
        "simpnac": "conteudo",
        "vabarap": "conteudo",
        "vadtinc": "conteudo",
        "iencont": "conteudo",
        "contrib": "conteudo",
        "cnae": "conteudo",
        "contat3": "conteudo",
        "telcob": "conteudo",
        "vaemlf": "conteudo",
        "vabcof": "conteudo",
        "vaagfin": "conteudo",
        "vactafn": "conteudo",
        "vacgcfi": "conteudo",
        "vamdanf": "conteudo",
        "savblq": "conteudo"
    }
*/

WSMETHOD DELETE ERASE WSRECEIVE id WSSERVICE WSCliente
    Local lRet              := .T.
    Local aDados            := {}
    Local jJson             := Nil
    Local cJson             := Self:GetContent()
    Local cError            := ''
    Local nLinha            := 0
    Local cDirLog           := '\x_logs\'
    Local cArqLog           := ''
    Local cErrorLog         := ''
    Local aLogAuto          := {}
    Local nCampo            := 0
    Local jResponse         := JsonObject():New()
    Local cAliasWS          := 'SA1'
    Private lMsErroAuto     := .F.
    Private lMsHelpAuto     := .T.
    Private lAutoErrNoFile  := .T.

    //Se não existir a pasta de logs, cria
    IF ! ExistDir(cDirLog)
        MakeDir(cDirLog)
    EndIF    

    //Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
    Self:SetContentType('application/json')
    jJson  := JsonObject():New()
    cError := jJson:FromJson(cJson)

    //Se o id estiver vazio
    If Empty(::id)
        //SetRestFault(500, 'Falha ao consultar o registro') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
        Self:setStatus(500) 
        jResponse['errorId']  := 'DEL010'
        jResponse['error']    := 'ID vazio'
        jResponse['solution'] := 'Informe o ID'
    Else
        DbSelectArea(cAliasWS)
        (cAliasWS)->(DbSetOrder(1))

        //Se não encontrar o registro
        If ! (cAliasWS)->(MsSeek(FWxFilial(cAliasWS) + ::id))
            //SetRestFault(500, 'Falha ao consultar ID') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
            Self:setStatus(500) 
            jResponse['errorId']  := 'DEL011'
            jResponse['error']    := 'ID não encontrado'
            jResponse['solution'] := 'Código ID não encontrado na tabela ' + cAliasWS
        Else
 
            //Se tiver algum erro no Parse, encerra a execução
            If ! Empty(cError)
                //SetRestFault(500, 'Falha ao obter JSON') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
                Self:setStatus(500) 
                jResponse['errorId']  := 'DEL012'
                jResponse['error']    := 'Parse do JSON'
                jResponse['solution'] := 'Erro ao fazer o Parse do JSON'

            Else
		         DbSelectArea(cAliasWS)
                
		         //Adiciona os dados do ExecAuto
		         aAdd(aDados, {'A1_FILIAL',   jJson:GetJsonObject('filial'),   Nil})
		         aAdd(aDados, {'A1_MSBLQL',   jJson:GetJsonObject('msblql'),   Nil})
		         aAdd(aDados, {'A1_COD',   jJson:GetJsonObject('cod'),   Nil})
		         aAdd(aDados, {'A1_LOJA',   jJson:GetJsonObject('loja'),   Nil})
		         aAdd(aDados, {'A1_NOME',   jJson:GetJsonObject('nome'),   Nil})
		         aAdd(aDados, {'A1_PESSOA',   jJson:GetJsonObject('pessoa'),   Nil})
		         aAdd(aDados, {'A1_TIPO',   jJson:GetJsonObject('tipo'),   Nil})
		         aAdd(aDados, {'A1_NREDUZ',   jJson:GetJsonObject('nreduz'),   Nil})
		         aAdd(aDados, {'A1_END',   jJson:GetJsonObject('end'),   Nil})
		         aAdd(aDados, {'A1_EST',   jJson:GetJsonObject('est'),   Nil})
		         aAdd(aDados, {'A1_COD_MUN',   jJson:GetJsonObject('cod_mun'),   Nil})
		         aAdd(aDados, {'A1_BAIRRO',   jJson:GetJsonObject('bairro'),   Nil})
		         aAdd(aDados, {'A1_CEP',   jJson:GetJsonObject('cep'),   Nil})
		         aAdd(aDados, {'A1_TEL',   jJson:GetJsonObject('tel'),   Nil})
		         //aAdd(aDados, {'A1_FAX',   jJson:GetJsonObject('fax'),   Nil})
		         aAdd(aDados, {'A1_CONTATO',   jJson:GetJsonObject('contato'),   Nil})
		         aAdd(aDados, {'A1_CGC',   jJson:GetJsonObject('cgc'),   Nil})
		         aAdd(aDados, {'A1_INSCR',   jJson:GetJsonObject('inscr'),   Nil})
		         aAdd(aDados, {'A1_VEND',   jJson:GetJsonObject('vend'),   Nil})
		         aAdd(aDados, {'A1_BCO1',   jJson:GetJsonObject('bco1'),   Nil})
		         aAdd(aDados, {'A1_FORMA',   jJson:GetJsonObject('forma'),   Nil})
		         aAdd(aDados, {'A1_ULTVIS',   jJson:GetJsonObject('ultvis'),   Nil})
		         aAdd(aDados, {'A1_CXPOSTA',   jJson:GetJsonObject('cxposta'),   Nil})
		         aAdd(aDados, {'A1_ENDCOB',   jJson:GetJsonObject('endcob'),   Nil})
		         aAdd(aDados, {'A1_BAIRROC',   jJson:GetJsonObject('bairroc'),   Nil})
		         aAdd(aDados, {'A1_CEPC',   jJson:GetJsonObject('cepc'),   Nil})
		         aAdd(aDados, {'A1_MUNC',   jJson:GetJsonObject('munc'),   Nil})
		         aAdd(aDados, {'A1_ESTC',   jJson:GetJsonObject('estc'),   Nil})
		         aAdd(aDados, {'A1_EMAIL',   jJson:GetJsonObject('email'),   Nil})
		         aAdd(aDados, {'A1_VAMDANF',   jJson:GetJsonObject('vamdanf'),   Nil})
		         aAdd(aDados, {'A1_HPAGE',   jJson:GetJsonObject('hpage'),   Nil})
		         aAdd(aDados, {'A1_VAUSER',   jJson:GetJsonObject('vauser'),   Nil})
		         aAdd(aDados, {'A1_VACANAL',   jJson:GetJsonObject('vacanal'),   Nil})
		         aAdd(aDados, {'A1_SATIV1',   jJson:GetJsonObject('sativ1'),   Nil})
		         aAdd(aDados, {'A1_SIMPNAC',   jJson:GetJsonObject('simpnac'),   Nil})
		         aAdd(aDados, {'A1_VABARAP',   jJson:GetJsonObject('vabarap'),   Nil})
		         aAdd(aDados, {'A1_VADTINC',   jJson:GetJsonObject('vadtinc'),   Nil})
		         aAdd(aDados, {'A1_IENCONT',   jJson:GetJsonObject('iencont'),   Nil})
		         aAdd(aDados, {'A1_CONTRIB',   jJson:GetJsonObject('contrib'),   Nil})
		         aAdd(aDados, {'A1_CNAE',   jJson:GetJsonObject('cnae'),   Nil})
		         aAdd(aDados, {'A1_CONTAT3',   jJson:GetJsonObject('contat3'),   Nil})
		         aAdd(aDados, {'A1_TELCOB',   jJson:GetJsonObject('telcob'),   Nil})
		         aAdd(aDados, {'A1_VAEMLF',   jJson:GetJsonObject('vaemlf'),   Nil})
		         aAdd(aDados, {'A1_VABCOF',   jJson:GetJsonObject('vabcof'),   Nil})
		         aAdd(aDados, {'A1_VAAGFIN',   jJson:GetJsonObject('vaagfin'),   Nil})
		         aAdd(aDados, {'A1_VACTAFN',   jJson:GetJsonObject('vactafn'),   Nil})
		         aAdd(aDados, {'A1_VACGCFI',   jJson:GetJsonObject('vacgcfi'),   Nil})
		         aAdd(aDados, {'A1_VAMDANF',   jJson:GetJsonObject('vamdanf'),   Nil})
		         aAdd(aDados, {'A1_SAVBLQ',   jJson:GetJsonObject('savblq'),   Nil})
		         
		         //Percorre os dados do execauto
		         For nCampo := 1 To Len(aDados)
		         	//Se o campo for data, retira os hifens e faz a conversão
		         	If GetSX3Cache(aDados[nCampo][1], 'X3_TIPO') == 'D'
		         		aDados[nCampo][2] := StrTran(aDados[nCampo][2], '-', '')
		         		aDados[nCampo][2] := sToD(aDados[nCampo][2])
		         	EndIf
		         Next

		         //Chama a exclusão automática
		         MsExecAuto({|x, y| MATA030(x, y)}, aDados, 5)

		         //Se houve erro, gera um arquivo de log dentro do diretório da protheus data
		         If lMsErroAuto
		         	//Monta o texto do Error Log que será salvo
		         	cErrorLog   := ''
		         	aLogAuto    := GetAutoGrLog()
		         	For nLinha := 1 To Len(aLogAuto)
		         		cErrorLog += aLogAuto[nLinha] + CRLF
		         	Next nLinha

		            //Grava o arquivo de log
		            cArqLog := 'WSCliente_New_' + dToS(Date()) + '_' + StrTran(Time(), ':', '-') + '.log'
		            MemoWrite(cDirLog + cArqLog, cErrorLog)

		            //Define o retorno para o WebService
		            //SetRestFault(500, cErrorLog) //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
		            Self:setStatus(500) 
		            jResponse['errorId']  := 'DEL013'
		            jResponse['error']    := 'Erro na exclusão do registro'
		            jResponse['solution'] := 'Nao foi possivel incluir o registro, foi gerado um arquivo de log em ' + cDirLog + cArqLog + ' '
		            lRet := .F.

		         //Senão, define o retorno
		         Else
		         	jResponse['note']     := 'Registro incluido com sucesso'
		         EndIf

		     EndIf
		 EndIf
    EndIf

    //Define o retorno
    Self:SetResponse(jResponse:toJSON())
Return lRet
