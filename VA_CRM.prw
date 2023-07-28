// Programa...: VA_CRM
// Autor......: Claudia Lionco
// Data.......: 21/07/2023
// Descricao..: Integracao clientes Protheus X CRM Simples
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #integracao
// #Descricao         #Integracao clientes Protheus X CRM Simples
// #PalavasChave      #CRM #CRM_Simples 
// #TabelasPrincipais #ZD0
// #Modulos   		  #FAT 
//
// sTipo:
// C = Cliente
// N = Nota fiscal
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include 'totvs.ch'

User Function VA_CRM(_aCRM, _sTipo)
    Local _x := 0      

    aHeadOut := {} 
    cHeadRet := "" 
    sPostRet := ""       
    nTimeOut := 120  
    
    Do Case 

    // Importação de clientes
    Case _sTipo == 'C'
        If Len(_aCRM) > 0

            For _x:=1 to Len(_aCRM)
                aadd(aHeadOut,"Content-Type: application/json")
                aadd(aHeadOut,"token:145493691c04-670f-4cd6-976d-04e4eb9e534d")

                cUrl1 := ("https://api.crmsimples.com.br/API?method=saveContato")

                cJson := '{"idExterno":    "' + _aCRM[_x, 1] + '",'
                cJson += '"nome":          "' + _aCRM[_x, 2] + '",' 
                cJson += '"idDivisao":     null                ,'    
                cJson += '"tipoPessoa":    "' + _aCRM[_x, 3] + '",'  
                cJson += '"cnpjCpf":       "' + _aCRM[_x,19] + '",'  
                cJson += '"fonteContato":  "' + _aCRM[_x, 4] + '",'
                cJson += '"statusContato": "' + _aCRM[_x, 5] + '",'
                cJson += '"listEndereco": [{'
                cJson += '      "selectTipoEndereco":"' + _aCRM[_x, 6] + '",'
                cJson += '      "endereco":          "' + _aCRM[_x, 7] + '",'
                cJson += '      "bairro":            "' + _aCRM[_x, 8] + '",'
                cJson += '      "cidade":            "' + _aCRM[_x, 9] + '",'
                cJson += '      "uf":                "' + _aCRM[_x,10] + '",'
                cJson += '      "cep":               "' + _aCRM[_x,11] + '",'
                cJson += '      "pais":              "' + _aCRM[_x,20] + '"'
                cJson += '}],'
                cJson += '"listFone": [{'
                cJson += '      "descricao": "' + _aCRM[_x,12] + '",'
                cJson += '      "selectTipo":"' + _aCRM[_x,13] + '"'
                cJson += '}],'
                cJson += '"listEmail": [{'
                cJson += '"descricao":  "' + _aCRM[_x,14] + '",'
                cJson += '"selectTipo": "' + _aCRM[_x,15] + '"'
                cJson += '}],'
                cJson += '"listCampoUsuario": ['
                cJson += '    {'
                cJson += '      "nomeCampo": "' + _aCRM[_x,16] + '",'
                cJson += '      "valor":     "' + _aCRM[_x,17] + '"'
                cJson += '    },'
                cJson += '    {'
                cJson += '      "nomeCampo": "' + _aCRM[_x,21] + '",'
                cJson += '      "valor":     "' + _aCRM[_x,22] + '"'
                cJson += '    }'
                cJson += '                     ],'
                cJson += '"listIdResponsaveis": ['+ _aCRM[_x,18] +'],'
                cJson += '"listIdRepresentantes": []}'

                U_Log2 ('info', cJson)

                sPostRet := HttpPost(cUrl1,,cJson,nTimeOut,aHeadOut,@cHeadRet)
                U_Log2 ('info', sPostRet)
            Next
            //ALERT(sPostRet)
        EndIf


    // Importação de clientes em Lote
    Case _sTipo == 'L'
        If Len(_aCRM) > 0
            U_Log2 ('info', '*** QTD. REGISTROS: ' + alltrim(str(Len(_aCRM))))

            aadd(aHeadOut,"Content-Type: application/json")
            aadd(aHeadOut,"token:145493691c04-670f-4cd6-976d-04e4eb9e534d")

            cUrl1 := ("https://api.crmsimples.com.br/API?method=saveContatoLote")

            cJson := '['

            For _x:=1 to Len(_aCRM)

                cJson += '{"idExterno":    "' + _aCRM[_x, 1] + '",'
                cJson += '"nome":          "' + _aCRM[_x, 2] + '",' 
                cJson += '"idDivisao":     null                ,'    
                cJson += '"tipoPessoa":    "' + _aCRM[_x, 3] + '",'  
                cJson += '"cnpjCpf":       "' + _aCRM[_x,19] + '",'  
                cJson += '"fonteContato":  "' + _aCRM[_x, 4] + '",'
                cJson += '"statusContato": "' + _aCRM[_x, 5] + '",'
                cJson += '"listEndereco": [{'
                cJson += '      "selectTipoEndereco":"' + _aCRM[_x, 6] + '",'
                cJson += '      "endereco":          "' + _aCRM[_x, 7] + '",'
                cJson += '      "bairro":            "' + _aCRM[_x, 8] + '",'
                cJson += '      "cidade":            "' + _aCRM[_x, 9] + '",'
                cJson += '      "uf":                "' + _aCRM[_x,10] + '",'
                cJson += '      "cep":               "' + _aCRM[_x,11] + '",'
                cJson += '      "pais":              "' + _aCRM[_x,20] + '"'
                cJson += '}],'
                cJson += '"listFone": [{'
                cJson += '      "descricao": "' + _aCRM[_x,12] + '",'
                cJson += '      "selectTipo":"' + _aCRM[_x,13] + '"'
                cJson += '}],'
                cJson += '"listEmail": [{'
                cJson += '"descricao":  "' + _aCRM[_x,14] + '",'
                cJson += '"selectTipo": "' + _aCRM[_x,15] + '"'
                cJson += '}],'
                cJson += '"listCampoUsuario": ['
                cJson += '    {'
                cJson += '      "nomeCampo": "' + _aCRM[_x,16] + '",'
                cJson += '      "valor":     "' + _aCRM[_x,17] + '"'
                cJson += '    },'
                cJson += '    {'
                cJson += '      "nomeCampo": "' + _aCRM[_x,21] + '",'
                cJson += '      "valor":     "' + _aCRM[_x,22] + '"'
                cJson += '    }'
                cJson += '                     ],'
                cJson += '"listIdResponsaveis": ['+ _aCRM[_x,18] +'],'
                cJson += '"listIdRepresentantes": []}'

                If _x != Len(_aCRM)
                    cJson += ','
                EndIf
            Next

            cJson += ']'

            U_Log2 ('info', cJson)
            sPostRet := HttpPost(cUrl1,,cJson,nTimeOut,aHeadOut,@cHeadRet)
            U_Log2 ('info', sPostRet)
            
        EndIf


    // Importação de Notas Fiscais
    Case _sTipo == 'N'
        If Len(_aCRM) > 0
            aadd(aHeadOut,"Content-Type: application/json")
            aadd(aHeadOut,"token:145493691c04-670f-4cd6-976d-04e4eb9e534d")

            cUrl1 := ("https://api.crmsimples.com.br/API?method=saveNegociacao")

            cJson := '{'
            cJson += '	"idExterno": "'+_aCRM[1,1]+'",'
            cJson += '	"contato": {'
            cJson += '				 "idExterno":   "'+_aCRM[1,1]+'"'
            cJson += '			   },'
            cJson += '	"organizacao": {'
            cJson += '					"idExterno":"'+_aCRM[1,1]+'"'
            cJson += '				   },'
            cJson += '	"nome":      "'+_aCRM[1,2]+'",'
            cJson += '	"descricao": "'+_aCRM[1,3]+'",'
            cJson += '	"categoriaNegociacao": "Nota Fiscal",'
            cJson += '	"idEtapaNegociacao": 5279,'
            cJson += '	"statusNegociacao": "Ganha",'
            cJson += '	"idUsuarioConclusao": '+_aCRM[1,4]+', '
            cJson += '	"idExternoUsuarioConclusao": "", '
            cJson += '	"concluidaEm": "'+_aCRM[1,5]+'",'
            cJson += '	"motivoGanhoPerda": "", '
            cJson += '	"submotivoGanhoPerda": "", '
            cJson += '	"valor": '+str(_aCRM[1,6]) + ','
            cJson += '	"valorOutros": 0,'
            cJson += '	"moeda": "R$", '
            cJson += '	"observacoes": "",'
            cJson += '	"visivelPara": "Responsaveis",'
            cJson += '	"ranking": 0,'
            cJson += '	"idUsuarioInclusao": '+_aCRM[1,4]+','
            cJson += '	"idExternoUsuarioInclusao": "",'
            cJson += '	"criadaEm": "'+_aCRM[1,7]+'",'
            cJson += '	"listProduto": [ '
            For _x:=1 to Len(_aCRM)
                cJson += '                   {"produto": {'
                cJson += '									"idExterno": "'+ _aCRM[_x, 8] +'",'
                cJson += '									"descricao": "'+ _aCRM[_x, 9] +'"'
                cJson += '								 },'
                cJson += '					 "valorUnitario":       '+ str(_aCRM[_x,10]) +','
                cJson += '					 "quantidade":          '+ str(_aCRM[_x,11]) +','
                cJson += '					 "unidade":             "'+_aCRM[_x,12] +'",'
                cJson += '					 "percentualDesconto":  0,'
                cJson += '					 "valorTotal":          '+ str(_aCRM[_x,13]) +','
                cJson += '					 "moeda":               "R$",'
                cJson += '					 "comentarios":         "", '
                cJson += '					 "anotacao":            ""}'
                If _x != Len(_aCRM)
                    cJson += '					  ,'
                EndIf
            Next
            cJson += '                  ],'
            cJson += '	"listCampoUsuario": [{"nomeCampo": "", '
            cJson += '						  "valor": ""}],'
            cJson += '	"listIdResponsaveis": ['+_aCRM[1,4]+'], '
            cJson += '	"listIdExternoResponsaveis": ['+_aCRM[1,4]+']'
            cJson += '}'

            U_Log2 ('info', cJson)

            sPostRet := HttpPost(cUrl1,,cJson,nTimeOut,aHeadOut,@cHeadRet)
        EndIf

    EndCase
Return
