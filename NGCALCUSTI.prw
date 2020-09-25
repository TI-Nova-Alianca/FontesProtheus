// Programa:   NGCALCUSTI
// Autor:      Andre Alves
// Data:       29/08/2018
// Descricao:  Ponto de entrada para calculo de O.S considerar valor hora.
//

#Include 'Protheus.ch'
 
//-------------------------------------------------------------------

User Function NGCALCUSTI()
  
        Local nCustoIns := PARAMIXB[1]  // Valor de custo calculado pelo sistema referente ao insumo
        Local cCodIns   := PARAMIXB[3]  // Codigo do insumo
        Local nQuantIns := PARAMIXB[4]  // Quantidade do insumo
        Local cEmpIns   := PARAMIXB[10] // Empresa do insumo
        Local cFilIns   := PARAMIXB[11] // Filial do insumo
        Local nCustoHora
 
        Local aAreaST1
 
        // Para insumos do tipo M (Mao de obra)
        If PARAMIXB[2] == "M"
         
            // Caso o insumo seja referente à empresa logada
            If Valtype(cEmpIns) <> "C" .Or. Empty(cEmpIns) .Or. cEmpIns == FWGrpCompany()
     
                // Caso a filial não seja repassada como por parametro
                cFilIns := IIf( ValType(cFilIns) == "C" .And. Empty(cFilIns), Nil, cFilIns )
     
                aAreaST1 := ST1->( GetArea() )
                cCodIns  := SubStr( cCodIns, 1, TAMSX3("T1_CODFUNC")[1] )
 
                // Busca valor/hora do funcionário
                nCustoHora := Posicione("ST1", 1, xFilial("ST1", cFilIns) + cCodIns, "T1_SALARIO")
                nCustoIns  := nCustoHora * nQuantIns
 
                RestArea(aAreaST1)
 
            Endif
         
        EndIf
     
    Return nCustoIns
