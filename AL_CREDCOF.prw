#INCLUDE "rwmake.ch" 
// AxCadastro para os cr�ditos de COFINS

User Function AL_CREDCOF()
                                                 

Private cVldAlt := ".T."  // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
Private cVldExc := ".T."  // Validacao para permitir a exclusao.  Pode-se utilizar ExecBlock.
Private cString := "ZZW"                                        


dbSelectArea("ZZW")
dbSetOrder(1)

AxCadastro(cString,"Cr�dito de COFINS",cVldAlt,cVldExc)

Return