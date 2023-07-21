// Programa...: VA_CRM
// Autor......: Cláudia Lionço
// Data.......: 21/07/2023
// Descricao..: Integração clientes Protheus X CRM Simples
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #integracao
// #Descricao         #Integração clientes Protheus X CRM Simples
// #PalavasChave      #CRM #CRM_Simples 
// #TabelasPrincipais #ZD0
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include 'totvs.ch'

User Function VA_CRM(_aCRM)
    aHeadOut := {} 
    cHeadRet := "" 
    sPostRet := ""       
    nTimeOut := 120             

    If Len(_aCRM) > 0
        aadd(aHeadOut,"Content-Type: application/json")
        aadd(aHeadOut,"token:145493691c04-670f-4cd6-976d-04e4eb9e534d")

        cUrl1 := ("https://api.crmsimples.com.br/API?method=saveContato")

        cJson := '{"idExterno":    "' + _aCRM[1,1] + '",'
        cJson += '"nome":          "' + _aCRM[1,2] + '",' 
        cJson += '"idDivisao":     null                ,'    
        cJson += '"tipoPessoa":    "' + _aCRM[1,3] + '",'  
        cJson += '"fonteContato":  "' + _aCRM[1,4] + '",'
        cJson += '"statusContato": "' + _aCRM[1,5] + '",'
        cJson += '"listEndereco": [{'
        cJson += '      "selectTipoEndereco":"' + _aCRM[1,6] + '",'
        cJson += '      "endereco":          "' + _aCRM[1,7] + '",'
        cJson += '      "cidade":            "' + _aCRM[1,8] + '",'
        cJson += '      "uf":                "' + _aCRM[1,9] + '"'
        cJson += '}],'
        cJson += '"listFone": [{'
        cJson += '      "descricao": "' + _aCRM[1,10] + '",'
        cJson += '      "selectTipo":"' + _aCRM[1,11] + '"'
        cJson += '}],'
        cJson += '"listEmail": [{'
        cJson += '"descricao":  "' + _aCRM[1,12] + '",'
        cJson += '"selectTipo": "' + _aCRM[1,13] + '"'
        cJson += '}],'
        cJson += '"listCampoUsuario": [{'
        cJson += '      "nomeCampo": "' + _aCRM[1,14] + '",'
        cJson += '      "valor":     "' + _aCRM[1,15] + '"'
        cJson += '}],'
        cJson += '"listIdResponsaveis": ['+ _aCRM[1,16] +'],'
        cJson += '"listIdRepresentantes": []}'


        sPostRet := HttpPost(cUrl1,,cJson,nTimeOut,aHeadOut,@cHeadRet)

        ALERT(sPostRet)
    EndIf
Return
