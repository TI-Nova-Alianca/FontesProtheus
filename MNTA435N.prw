//  Programa  : MNTA435N
//  Autor     : Andre Alves
//  Data      : 14/02/2019
//  Descricao : PE para validação no Retorno Mod 2
// 
//  Historico de alteracoes:
//  24/06/2019 - Andre  - Adicionado validação para que teste insumos ja gravados na ordem antes de finalizar ordem.
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
    Local nCodBem    := ''
    Local nOS		 := ''
    local nCC		 := ''
      
    If cId == "VALID_CONFIRM"
        //Array com os dados das ordens de serviço
        aDadosOS := ParamIXB[2]
     
        //Percorre o array de ordens
        For nOrdem := 1 To Len( aDadosOS )
             
            //Verifica se há insumos realizados
            If ValType( aDadosOS[ nOrdem, 5 ] ) == "A"
                aInsumos := aClone( aDadosOS[ nOrdem, 5 ] )
             
                //Percorre o array de insumos realizados
                For nInsumo := 1 to Len( aInsumos )
                    
                    If !aTail( aInsumos[ nInsumo ] ); //Verifica se não está deletado
                        .And. aInsumos[ nInsumo, nPosTipReg ] == "M"; //Verifica se é insumo do tipo MDO
                        .And. aInsumos[ nInsumo, nPosDtInic ] < Date() -3; // Nao permite data menor que 3 dias da data atual
                        .And. aInsumos[ nInsumo, nPosDtInic ] > Date (); // Nao permite data maior que a data atual
                        .And. empty (aInsumos[ nInsumo, nPosSeqD3 ]) // Insumo já gravado não testa data atual. 
                        //Apresenta para o usuário o número da OS que há uma inconsistência
                        MsgAlert( "Ordem " + aDadosOS[ nOrdem, 1 ] +  ": a data dos insumos tipo mão de obra, não pode ser menor que três dias retroativos.")
                         
                        //Quando há problema, deve retornar falso
                        RestArea( aArea )
                        Return .F.           
                    EndIf
                    
                    If !aTail( aInsumos[ nInsumo ] ); //Verifica se não está deletado
                        .And. aInsumos[ nInsumo, nPosTipReg ] == "P" //Verifica se é insumo do tipo BEM
                        nOs := aDadosOS[ nOrdem, 1 ]
                        nCodBem := fbuscacpo ("STJ",1,xFilial("STJ")+nOs, "TJ_CODBEM")
                        nCC :=  fbuscacpo ("ST9",1,xFilial("ST9")+nCodBem, "T9_CCUSTO")
                        if substr(nCC,1,2) != cFilAnt
                        	//Apresenta para o usuário o número da OS que há uma inconsistência
                        	MsgAlert( "Ordem " + aDadosOS[ nOrdem, 1 ] +  ": o bem" + nCodBem + " desta manutencao nao pertence a esta filial")
                        	RestArea( aArea )
                        	Return .F.
                        endif 
                    EndIf
                     
                Next nInsumo
 
            EndIf
        Next nOrdem
        //Quando não houver problema retorna sucesso na validação
        RestArea( aArea )
        Return .T.
    EndIf
  
Return