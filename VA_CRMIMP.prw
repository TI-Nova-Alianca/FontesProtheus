// Programa...: VA_CRMIMP
// Autor......: Claudia Lionco
// Data.......: 21/07/2023
// Descricao..: Importação de clientes Protheus X CRM Simples
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Importação de clientes Protheus X CRM Simples
// #PalavasChave      #CRM #CRM_Simples 
// #TabelasPrincipais #ZD0
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include 'totvs.ch'

User Function VA_CRMIMP()
    Local _aDados := {}
    Local _aCRM   := {}
    Local _aResp  := {}
    Local _x      := 0

    cPerg   := "VA_CRMIMP"
	_ValidPerg ()
	If ! pergunte (cPerg, .T.)
		return
	Endif

    _oSQL := ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   A1_COD "
    _oSQL:_sQuery += "    ,A1_NOME "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		    WHEN A1_PESSOA = 'F' THEN 'Física' "
    _oSQL:_sQuery += " 		    ELSE 'Jurídica' "
    _oSQL:_sQuery += " 	    END PESSOA "
    _oSQL:_sQuery += "    ,'ERP Protheus' "
    _oSQL:_sQuery += "    ,'Cliente' "
    _oSQL:_sQuery += "    ,'Trabalho' "
    _oSQL:_sQuery += "    ,A1_END "
    _oSQL:_sQuery += "    ,A1_BAIRRO "
    _oSQL:_sQuery += "    ,A1_MUN "
    _oSQL:_sQuery += "    ,A1_EST "
    _oSQL:_sQuery += "    ,A1_CEP "
    _oSQL:_sQuery += "    ,A1_TEL "
    _oSQL:_sQuery += "    ,'Trabalho' "
    _oSQL:_sQuery += "    ,A1_EMAIL "
    _oSQL:_sQuery += "    ,'Trabalho' "
    _oSQL:_sQuery += "    ,'IE' "
    _oSQL:_sQuery += "    ,A1_INSCR "
    _oSQL:_sQuery += "    ,A1_CGC "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		    WHEN A1_PAIS = '105' THEN 'Brasil' "
    _oSQL:_sQuery += " 		    ELSE 'EX' "
    _oSQL:_sQuery += " 	    END "
    _oSQL:_sQuery += "    ,'Ativo/Inativo' "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		WHEN A1_MSBLQL = '2' THEN 'Ativo' "
    _oSQL:_sQuery += " 		ELSE 'Inativo' "
    _oSQL:_sQuery += " 	END "
    _oSQL:_sQuery += " FROM SA1010 "
    _oSQL:_sQuery += " WHERE D_E_L_E_T_='' "
    _oSQL:_sQuery += " AND A1_VEND ='"+ mv_par01 +"'" 
    _oSQL:_sQuery += " ORDER BY A1_NOME"

    _aDados := aclone (_oSQL:Qry2Array ())

    _aCRM   := {}

    For _x:=1 to Len(_aDados)
        _oSQL := ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += " 		 ZCA_CODRES "
        _oSQL:_sQuery += " FROM " + RetSQLName ("ZCA")
        _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND ZCA_CODREP   = '" + mv_par01 + "' "
        _aResp := aclone (_oSQL:Qry2Array ())

        If len(_aResp) > 0
            _sResp     := _aResp[1,1]

            If !empty(_sResp)

                aadd(_aCRM,{	_aDados[_x, 1] 			,; // idExterno
                                _aDados[_x, 2]			,; // nome
                                _aDados[_x, 3]			,; // tipoPessoa
                                _aDados[_x, 4]  		,; // fonteContato
                                _aDados[_x, 5]			,; // statusContato
                                _aDados[_x, 6]			,; // selectTipoEndereco
                                alltrim(_aDados[_x, 7])	,; // endereco
                                alltrim(_aDados[_x, 8])	,; // bairro
                                alltrim(_aDados[_x, 9])	,; // cidade
                                _aDados[_x,10]  		,; // uf
                                _aDados[_x,11]			,; // cep
                                alltrim(_aDados[_x,12])	,; // descricao (telefone)
                                _aDados[_x,13]			,; // selectTipo
                                alltrim(_aDados[_x,14])	,; // descricao (email)
                                _aDados[_x,15]			,; // selectTipo
                                _aDados[_x,16]			,; // listCampoUsuario - nomeCampo
                                alltrim(_aDados[_x,17])	,; // valor
                                _sResp	 				,; // listIdResponsaveis
                                _aDados[_x,18]          ,; // CPF/CNPJ
                                _aDados[_x,19]			,; // Pais
                                _aDados[_x,20]          ,; // Ativo/Inativo
                                _aDados[_x,21]          }) // Ativo/Inativo

            EndIf
        EndIf
    Next
    U_VA_CRM(_aCRM,'L')
    
Return
//
// --------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      			Help
    aadd (_aRegsPerg, {01, "Vendedor          ", "C", 6, 0,  "",  "SA3", {},                         				""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
