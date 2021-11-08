//  Programa.: MNTA435N
//  Autor....: Andre Alves
//  Data.....: 14/02/2019
//  Descricao: PE para valida��o no Retorno Mod 2
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #PE para valida��o no Retorno Mod 2
// #PalavasChave      #validacao #manutencao #modelo_II #ordem_de_producao
// #TabelasPrincipais #STL #ST9
// #Modulos           #EST
//
//  Historico de alteracoes:
//  24/06/2019 - Andre   - Adicionado valida��o para que teste insumos ja gravados na ordem antes de finalizar ordem.
//  18/10/2021 - Claudia - Adicionada valida��o para produtos MC. GLPI: 10765
//
//  ---------------------------------------------------------------------------------------------------------------------

#include 'protheus.ch'

User Function MNTA435N()
     
    Local aArea     := GetArea()
    Local cId       := PARAMIXB[1] //Indica o momento da chamada do PE
    Local aDadosOS  := {}
    Local aInsumos  := {} //Array de insumos realizados
    Local nOrdem
    Local nInsumo
    Local nPosTipReg := aScan(aHoBrw2,{|x| Trim(Upper(x[2])) == "TL_TIPOREG"})
    Local nPosDtInic := aScan(aHoBrw2,{|x| Trim(Upper(x[2])) == "TL_DTINICI"})
    Local nPosSeqD3  := aScan(aHoBrw2,{|x| Trim(Upper(x[2])) == "TL_NUMSEQ"})
    Local nPosProd   := aScan(aHoBrw2,{|x| Trim(Upper(x[2])) == "TL_CODIGO"})
    Local nCodBem    := ''
    Local nOS		 := ''
    local nCC		 := ''
    
    u_logIni ()
	u_log ("Iniciando em", date (), time ())

    If cId == "VALID_CONFIRM"

        u_log ("VALID_CONFIRM")
        //Array com os dados das ordens de servi�o
        aDadosOS := ParamIXB[2]
     
        //Percorre o array de ordens
        For nOrdem := 1 To Len( aDadosOS )
            u_log ("Ordem")
            //Verifica se h� insumos realizados
            If ValType( aDadosOS[ nOrdem, 5 ] ) == "A"
                aInsumos := aClone( aDadosOS[ nOrdem, 5 ] )
             
                //Percorre o array de insumos realizados
                For nInsumo := 1 to Len( aInsumos )
                    u_log ("Insumos")
                    If !aTail( aInsumos[ nInsumo ] );                       //Verifica se n�o est� deletado
                        .And. aInsumos[ nInsumo, nPosTipReg ] == "M";       //Verifica se � insumo do tipo MDO
                        .And. aInsumos[ nInsumo, nPosDtInic ] < Date() -3;  // Nao permite data menor que 3 dias da data atual
                        .And. aInsumos[ nInsumo, nPosDtInic ] > Date ();    // Nao permite data maior que a data atual
                        .And. empty (aInsumos[ nInsumo, nPosSeqD3 ])        // Insumo j� gravado n�o testa data atual. 
                        //Apresenta para o usu�rio o n�mero da OS que h� uma inconsist�ncia
                        MsgAlert( "Ordem " + aDadosOS[ nOrdem, 1 ] +  ": a data dos insumos tipo m�o de obra, n�o pode ser menor que tr�s dias retroativos.")
                         
                        //Quando h� problema, deve retornar falso
                        RestArea( aArea )
                        Return .F.           
                    EndIf
                    
                    //Verifica se n�o est� deletado e Verifica se � insumo do tipo BEM
                    If !aTail( aInsumos[ nInsumo ] ) .and. aInsumos[ nInsumo, nPosTipReg ] == "P"                            
                        nOs := aDadosOS[ nOrdem, 1 ]
                        nCodBem := fbuscacpo ("STJ",1,xFilial("STJ")+nOs, "TJ_CODBEM")
                        nCC :=  fbuscacpo ("ST9",1,xFilial("ST9")+nCodBem, "T9_CCUSTO")

                        if substr(nCC,1,2) != cFilAnt
                        	//Apresenta para o usu�rio o n�mero da OS que h� uma inconsist�ncia
                        	MsgAlert( "Ordem " + aDadosOS[ nOrdem, 1 ] +  ": o bem" + nCodBem + " desta manutencao nao pertence a esta filial")
                        	RestArea( aArea )
                        	Return .F.
                        endif 
                    EndIf

                    //If !aTail(aInsumos[nInsumo]) .and. aInsumos[nInsumo, nPosTipReg] == "P"   
                        sProduto := aInsumos[ nInsumo, nPosProd]
                        sTipo    := fbuscacpo("SB1",1,xfilial("SB1") + sProduto,"B1_TIPO")
                        nOs      := aDadosOS[ nOrdem, 1 ]
                        nCodBem  := fbuscacpo("STJ",1,xFilial("STJ") + nOs, "TJ_CODBEM")
                        nCC      := fbuscacpo("ST9",1,xFilial("ST9") + nCodBem, "T9_CCUSTO")

                        u_log ("Produto:" + sProduto + " Tipo:" + sTipo + " CC:" + nCC)

                        if alltrim(sTipo) $ 'MC' .and. !(alltrim(nCC) $ alltrim('011404/011405'))
                            u_log ("Produtos MC devem ser lan�ados nos centro de custo da Tetra Pak (011404/011405)")

                        	MsgAlert( "Produtos MC devem ser lan�ados nos centro de custo da Tetra Pak (011404/011405)")
                        	RestArea( aArea )
                        	Return .F.
                        endif 
                    //EndIf                     
                Next nInsumo 
            EndIf
        Next nOrdem
        //Quando n�o houver problema retorna sucesso na valida��o
        RestArea( aArea )
        Return .T.
    EndIf  
    u_logFim ()
Return
