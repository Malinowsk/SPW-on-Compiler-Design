%{
import java.util.ArrayList;
import java.util.Stack;
import java.util.HashMap;
%}

%token
    IF THEN ELSE ENDIF PRINT FUNC RETURN BEGIN END BREAK ULONG DOUBLE WHILE DO
    COMP_MAYOR_IGUAL COMP_MENOR_IGUAL ASIG COMP_IGUAL AND OR ID CTE_ULONG CTE_DOUBLE
    CADENA POST TRY CATCH COMP_DISTINTO CALL
 

%start programa

%%
 programa : cabecera_programa bloque_declarativo bloque_ejecutable
 ;

 cabecera_programa : ID ';' { addEstructura( "Declaracion de programa, en la linea: " + analizadorLexico.getNroLineaToken() );
 			      ambitoActual= tablaSimbolo.obtenerValor($1.ival);
 			    }
 		   | error ';' { addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", identificador de programa invalido");
 		    		 ambitoActual= "error";
 		    		}
 ;

 // gramaticas de bloque declarativo

 bloque_declarativo : sentencias_declarativas 
 ;
 
 sentencias_declarativas : sentencia_declarativa ';' sentencias_declarativas
                         | sentencia_declarativa ';'
 ;
 
 sentencia_declarativa : tipo lista_variables { addEstructura( "Declaracion de variables, en la linea: " + analizadorLexico.getNroLineaToken() ); } // declaracion de variables tipo (ULONG , DOUBLE)
                       | tipo_funcion '(' tipo ')' lista_funcion_como_variables   // declaracion de variable funcion
                       | sentencia_declarativa_funcion    // declaracion de funcion
                       | error lista_variables { addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", tipo de variable invalido"); }
                       | tipo error lista_variables { addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", declaracion invalida"); }
 ;

 tipo : ULONG {tipoActual= "ULONG"; $$.sval= "ULONG";}
      | DOUBLE {tipoActual= "DOUBLE"; $$.sval= "DOUBLE";}
 ;
       										 // declaracion de variables tipo (ULONG , DOUBLE)
 lista_variables : ID ',' lista_variables {
                        if(!tablaSimbolo.existeToken(tablaSimbolo.obtenerToken($1.ival).getLexema()+'.'+ambitoActual)){ // chekeamos que no este esa variable redefiniciendose
			    tablaSimbolo.obtenerToken($1.ival).setLexema(tablaSimbolo.obtenerToken($1.ival).getLexema()+'.'+ambitoActual);
			    tablaSimbolo.obtenerToken($1.ival).setTipo(tipoActual);
			    tablaSimbolo.obtenerToken($1.ival).setUso("variable");
			}else{ // si la variable ya esta declarada , se agrega a la lista de warning errores detectado por el parser
			    tablaSimbolo.borrarToken($1.ival);
			    addWarning("Linea " + analizadorLexico.getNroLineaToken() + ", variable redeclarada, se eliminaron las redeclaraciones pertinentes");
			}
 		 }
                 | ID{
                        if(!tablaSimbolo.existeToken(tablaSimbolo.obtenerToken($1.ival).getLexema()+'.'+ambitoActual)){
            	            tablaSimbolo.obtenerToken($1.ival).setLexema(tablaSimbolo.obtenerToken($1.ival).getLexema()+'.'+ambitoActual);
			    tablaSimbolo.obtenerToken($1.ival).setTipo(tipoActual);
			    tablaSimbolo.obtenerToken($1.ival).setUso("variable");
			}
			else{
			    tablaSimbolo.borrarToken($1.ival);
			    addWarning("Linea " + analizadorLexico.getNroLineaToken() + ", variable redeclarada, se eliminaron las redeclaraciones pertinentes");
			}
	         }
 ;
	                   				    // declaracion de variables tipo funcion
 tipo_funcion: tipo FUNC {
		tipoActualdeFuncion= $1.sval;
		addEstructura( "Declaracion de funciones como variables, en la linea: " + analizadorLexico.getNroLineaToken() );
 }
 ;

  lista_funcion_como_variables : ID ',' lista_funcion_como_variables {
                         if(!tablaSimbolo.existeToken(tablaSimbolo.obtenerToken($1.ival).getLexema()+'.'+ambitoActual)){
 			    tablaSimbolo.obtenerToken($1.ival).setLexema(tablaSimbolo.obtenerToken($1.ival).getLexema()+'.'+ambitoActual);
 			    tablaSimbolo.obtenerToken($1.ival).setTipo(tipoActualdeFuncion);
 			    tablaSimbolo.obtenerToken($1.ival).setUso("funcion designada a variable");
 			    tablaSimbolo.obtenerToken($1.ival).setTipoParametro(tipoActual);
 			}else{
 			    tablaSimbolo.borrarToken($1.ival);
 			    addWarning("Linea " + analizadorLexico.getNroLineaToken() + ", variable redeclarada, se eliminaron las redeclaraciones pertinentes");
 			}
  		 }
                  | ID{
                         if(!tablaSimbolo.existeToken(tablaSimbolo.obtenerToken($1.ival).getLexema()+'.'+ambitoActual)){
             	            tablaSimbolo.obtenerToken($1.ival).setLexema(tablaSimbolo.obtenerToken($1.ival).getLexema()+'.'+ambitoActual);
 			    tablaSimbolo.obtenerToken($1.ival).setTipo(tipoActualdeFuncion);
 			    tablaSimbolo.obtenerToken($1.ival).setUso("funcion designada a variable");
 			    tablaSimbolo.obtenerToken($1.ival).setTipoParametro(tipoActual);
 			}
 			else{
 			    tablaSimbolo.borrarToken($1.ival);
 			    addWarning("Linea " + analizadorLexico.getNroLineaToken() + ", variable redeclarada, se eliminaron las redeclaraciones pertinentes");
 			}
 	         }
  ;

	// declaracion de funcion

 sentencia_declarativa_funcion : cabecera_funcion bloque_declarativo BEGIN bloque_ejecutable_funcion retorno_funcion END {
 					crearTerceto(new ParserVal(-4), new ParserVal(-1), new ParserVal(-1));//terceto para indicar el final de una funcion
 					ambitoActual= ambitoActual.substring(0, ambitoActual.lastIndexOf('.'));
 				}
                               | cabecera_funcion bloque_declarativo BEGIN bloque_ejecutable_funcion retorno_funcion postcondicion END {
                               		crearTerceto(new ParserVal(-4), new ParserVal(-1), new ParserVal(-1));//terceto para indicar el final de una funcion
                               		ambitoActual= ambitoActual.substring(0, ambitoActual.lastIndexOf('.'));
                               }
 ;

 cabecera_funcion : tipo_funcion ID '(' parametro ')' {
			 String auxiliar = tablaSimbolo.obtenerToken($2.ival).getLexema();
			 if(!tablaSimbolo.existeToken(auxiliar + '.' + ambitoActual)){  // chekeamos que no este redeclaradose la funcion
			    tablaSimbolo.obtenerToken($2.ival).setLexema(auxiliar+'.'+ambitoActual);  // seteamos el nombre , agregandole el ambito al que pertenece
			    tablaSimbolo.obtenerToken($2.ival).setTipo(tipoActualdeFuncion); // seteamos el tipo de la funcion
			    tablaSimbolo.obtenerToken($2.ival).setUso("funcion");
			    tablaSimbolo.obtenerToken($2.ival).setTipoParametro(tablaSimbolo.obtenerToken($4.ival).getTipo()); // set al topo del parametro
			    ambitoActual= ambitoActual + '.' + auxiliar; // el ambito cambia al entrar a una declaracion de funcion
			    tablaSimbolo.obtenerToken($4.ival).setLexema(tablaSimbolo.obtenerToken($4.ival).getLexema()+'.'+ambitoActual);
			    tablaSimbolo.obtenerToken($2.ival).setParametro(tablaSimbolo.obtenerToken($4.ival).getLexema());
 			 }
 			 else
 			 {
 			     tablaSimbolo.borrarToken($2.ival);
                 	     addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", funcion redeclarada");
 			     $2.ival=tablaSimbolo.obtenerReferenciaTabla(auxiliar+'.'+ ambitoActual);
 			     ambitoActual= ambitoActual + '.' + auxiliar;
 			 }
 			 addEstructura( "Declaracion de funcion, en la linea: " + analizadorLexico.getNroLineaToken() );
			 crearTerceto(new ParserVal(FUNC), $2, new ParserVal(-1));  // terceto que indica comienzo de funcion , con su identificador en segunda posicion , el tercer lugar queda nulo
 		  }
 		  | tipo_funcion ID '(' error ')' { ambitoActual= ambitoActual + '.' + tablaSimbolo.obtenerToken($2.ival).getLexema(); addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", parametro invalido");
 		  }
 		  | tipo_funcion ID parametro ')' { ambitoActual= ambitoActual + '.' + tablaSimbolo.obtenerToken($2.ival).getLexema(); addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", falta parentesis de apertura");
 		  }
 		  | tipo_funcion ID '(' parametro { ambitoActual= ambitoActual + '.' + tablaSimbolo.obtenerToken($2.ival).getLexema(); addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", falta parentesis de cierre");
 		  }
 ;

				// paramentro de la funcion
 parametro : tipo ID {
		tablaSimbolo.obtenerToken($2.ival).setTipo(tipoActual);
		tablaSimbolo.obtenerToken($2.ival).setUso("parametro");
		$$.ival=$2.ival; // le pasamos al NT(paramentro) el valor de la clave que contiene el token identificador
	}
 ;
 
 retorno_funcion : RETURN '(' expresion_aritmetica ')' ';' {                               // ejemplo = Main.funcion1.funcion2
 				int refFuncion= tablaSimbolo.obtenerReferenciaTabla(ambitoActual.substring(ambitoActual.lastIndexOf('.')+1, ambitoActual.length())+'.'+ambitoActual.substring(0, ambitoActual.lastIndexOf('.')));

 				if(tablaSimbolo.obtenerToken(refFuncion).getTipo() != $3.sval)  // chekeo que el tipo de funcion sea el mismo que estoy retornando
 					addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", tipos incompatibles entre el retorno de la funcion y lo retornado");
 				crearTerceto(new ParserVal(RETURN), $3, new ParserVal(-1));     // terceto que indica retorno de funcion , con su valor a retornar en la segunda posicion , el tercer lugar queda nulo
 				addEstructura( "Sentencia RETURN, en la linea: " + analizadorLexico.getNroLineaToken() );
 		 }
 		 | RETURN '(' error ')' ';' { addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", expresion aritmetica invalida"); }
 		 | RETURN '(' expresion_aritmetica ';' { addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", falta parentesis de cierre"); }
 		 | RETURN expresion_aritmetica ')' ';' { addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", falta parentesis de apertura"); }

 ;

 postcondicion : POST ':' '(' condicion ')' ';' {                                          // ejemplo = Main.funcion1.funcion2
 			int refFuncion= tablaSimbolo.obtenerReferenciaTabla(ambitoActual.substring(ambitoActual.lastIndexOf('.')+1, ambitoActual.length())+'.'+ambitoActual.substring(0, ambitoActual.lastIndexOf('.')));  // obtengo la clave en la tabla de simbolos de el identificador de la funcion
 				// uso un hasmap "postcondiciones" para guardar el identif de la funcion y su condicion
 			postCondiciones.put(refFuncion, tercetos.size()-1);//Se guarda en el hashmap la posicion (indice de la lista tercetos) del terceto de la condicion (ult terceto agregado en este punto) con la clave= ID de la funcion
 			addEstructura( "Sentencia POST, en la linea: " + analizadorLexico.getNroLineaToken() );
 		}
	       | POST ':' '(' error ')' ';'  {
			int refFuncion= tablaSimbolo.obtenerReferenciaTabla(ambitoActual.substring(ambitoActual.lastIndexOf('.')+1, ambitoActual.length())+'.'+ambitoActual.substring(0, ambitoActual.lastIndexOf('.')));
			postCondiciones.put(refFuncion, 0);//Se guarda en el hashmap la posicion del terceto de condicion (ult terceto agregado en este punto) con la clave= ID de la funcion
			addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", condicion invalida");
		}
	       | POST '(' condicion ')' ';'  {
			int refFuncion= tablaSimbolo.obtenerReferenciaTabla(ambitoActual.substring(ambitoActual.lastIndexOf('.')+1, ambitoActual.length())+'.'+ambitoActual.substring(0, ambitoActual.lastIndexOf('.')));
			postCondiciones.put(refFuncion, tercetos.size()-1);//Se guarda en el hashmap la posicion del terceto de condicion (ult terceto agregado en este punto) con la clave= ID de la funcion
			addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", falta :");
		}
	       | POST condicion ')' ';' {
			int refFuncion= tablaSimbolo.obtenerReferenciaTabla(ambitoActual.substring(ambitoActual.lastIndexOf('.')+1, ambitoActual.length())+'.'+ambitoActual.substring(0, ambitoActual.lastIndexOf('.')));
			postCondiciones.put(refFuncion, tercetos.size()-1);//Se guarda en el hashmap la posicion del terceto de condicion (ult terceto agregado en este punto) con la clave= ID de la funcion
			addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", falta parentesis de apertura");
		}
	       | POST '(' condicion ';' {
			int refFuncion= tablaSimbolo.obtenerReferenciaTabla(ambitoActual.substring(ambitoActual.lastIndexOf('.')+1, ambitoActual.length())+'.'+ambitoActual.substring(0, ambitoActual.lastIndexOf('.')));
			postCondiciones.put(refFuncion, tercetos.size()-1);//Se guarda en el hashmap la posicion del terceto de condicion (ult terceto agregado en este punto) con la clave= ID de la funcion
			addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", falta parentesis de cierre");
		}
 ;


							// bloques ejecutables

 bloque_ejecutable : BEGIN sentencias_ejecutables END
 ;

 bloque_ejecutable_funcion : sentencias_ejecutables                   // no lleva ( Begin - End ) el bloque de funcion
 ;
 
 sentencias_ejecutables : sentencia_ejecutable sentencias_ejecutables
                        | sentencia_ejecutable
 ;

 sentencia_ejecutable : sentencia_asignacion        // aux:= expresion;
                      | sentencia_condicional       // IF () THEN ... ENDIF;
                      | sentencia_imprimir	    // PRINT(%...%);
                      | sentencia_iterativa	    // WHILE()DO BEGIN END
                      | sentencia_try_catch	    // TRY ... CATCH ...
 ; 

 sentencia_asignacion : ID ASIG expresion_aritmetica ';' {				// aux:= expresion;
 		       String auxiliar= ambitoActual;
 		       int ultimoPunto = 0;
 		       while( (!tablaSimbolo.existeToken(tablaSimbolo.obtenerToken($1.ival).getLexema()+'.'+auxiliar)) && (ultimoPunto>=0)){
 		       		ultimoPunto = auxiliar.lastIndexOf('.');
 		       		if(ultimoPunto>0)
 		       			auxiliar = auxiliar.substring(0, ultimoPunto);
 		       }
 		       int nuevaRef = tablaSimbolo.obtenerReferenciaTabla(tablaSimbolo.obtenerToken($1.ival).getLexema()+'.'+auxiliar);
		       if(nuevaRef == -1){
		       		addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", variable no declarada");
		       }
		       else{
		       	       tablaSimbolo.borrarToken($1.ival);//se borra de la tabla de simbolos la variable duplicada de la sentencia
		       	       $1.ival=nuevaRef;//se le asigna la referencia a la variable original en la tabla

			       if(tablaSimbolo.obtenerToken($1.ival).getUso()=="funcion")
					addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", el identificador a la izquierda de la asignacion no es una variable");

			       if(tablaSimbolo.obtenerToken($1.ival).getUso()=="funcion designada a variable"){//Solo se puede asignar una funcion
					if($3.ival<=0){//$3 no hace referencia a un identificador
						addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", solo se le puede asignar una funcion a esta variable");
					}else{
						if((tablaSimbolo.obtenerToken($3.ival).getUso()!="funcion") && (tablaSimbolo.obtenerToken($3.ival).getUso()!="funcion designada a variable")){
							addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", solo se le puede asignar una funcion a esta variable");
						}else{
							if(tablaSimbolo.obtenerToken($1.ival).getTipoParametro() != tablaSimbolo.obtenerToken($3.ival).getTipoParametro())
								addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", el parametro de la funcion es de distinto tipo que el del parametro de la variable");
							this.erroresSemanticos.remove(indiceErrorABorrar);//se borra el error ya que se hace buen uso del identificador
						}
					}
				}

			       if(tablaSimbolo.obtenerToken($1.ival).getTipo()!=$3.sval)
					addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", tipos incompatibles " + tablaSimbolo.obtenerToken($1.ival).getTipo() + " := " + $3.sval );

		       }

		       $$ = new ParserVal((double)crearTerceto(new ParserVal(ASIG), $1, $3));  // terceto que indica una asignacion (ASIG) , con su identificador a asignar en segunda posicion , y el identificador que se debe asignar en tercera posicion
		       addEstructura( "Sentencia de asignacion, en la linea: " + analizadorLexico.getNroLineaToken() );
		      }
 		      | ID error ';' { addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", sentencia invalida"); }
 		      | ID ASIG error ';' { addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", expresion aritmetica invalida"); }
              	      | error ';' { addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", sentencia invalida");}
 ;

  // llamado a funcion
 sentencia_llamado_funcion : CALL ID '(' expresion_aritmetica ')'{
                String auxiliar= ambitoActual;
                int ultimoPunto = 0;
                while( (!tablaSimbolo.existeToken(tablaSimbolo.obtenerToken($2.ival).getLexema()+'.'+auxiliar)) && (ultimoPunto>=0)){
                    ultimoPunto = auxiliar.lastIndexOf('.');
                    if(ultimoPunto>0)
                        auxiliar = auxiliar.substring(0, ultimoPunto);
                }
		int nuevaRef = tablaSimbolo.obtenerReferenciaTabla(tablaSimbolo.obtenerToken($2.ival).getLexema()+'.'+auxiliar);

		if(nuevaRef == -1){
			addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", funcion no declarada");
		}
		else{
			tablaSimbolo.borrarToken($2.ival);//se borra de la tabla de simbolos la variable duplicada de la sentencia
			$2.ival=nuevaRef;//se le asigna la referencia a la variable original en la tabla

			Token tFuncion = tablaSimbolo.obtenerToken($2.ival);
			if(tFuncion.getUso()=="funcion" || tFuncion.getUso()=="funcion designada a variable"){
			    $2.sval = tFuncion.getTipo();
				if($4.sval!= tFuncion.getTipoParametro())
					addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", Error en la invocacion a funcion : El tipo de parametro real no coincide con el formal");
			}else{
				addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", se intenta invocar una variable que no es funcion " + tFuncion.getLexema());
			}
		}

		addEstructura( "Sentencia de llamado a funcion, en la linea: " + analizadorLexico.getNroLineaToken() );
 		$$ = new ParserVal((double)crearTerceto(new ParserVal(CALL), $2, $4));
		$$.sval = tablaSimbolo.obtenerToken($2.ival).getTipo();
	   }
	   | CALL ID '(' error ')' ';'{ addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", expresion aritmetica invalida"); }
 ;

 // sentencia condicional
 sentencia_condicional : condicional bloque_ejecutable_condicional ENDIF ';' {              // IF () THEN ... ENDIF;
			 tercetos.get(pila.pop()).setT3(new ParserVal((double)tercetos.size()));//Completo el BF del if
			 tercetos.get(tercetos.size()-1).setEtiqueta();
			}	//Se modifica el BF, agregandole la referencia correspondiente al proximo terceto despues del ENDIF

		       | condicional bloque_ejecutable_condicional else bloque_ejecutable_condicional ENDIF ';'{
			 tercetos.get(pila.pop()).setT2(new ParserVal((double)tercetos.size()));//Completo el BI del else
			 tercetos.get(tercetos.size()-1).setEtiqueta();
			}	//Se modifica el BI, agregandole la referencia correspondiente al proximo terceto despues del ENDIF
 ;

 else: ELSE{
	tercetos.get(pila.pop()).setT3(new ParserVal((double)tercetos.size()+1));//Completo el BF del if
	int refTerceto =crearTerceto(new ParserVal(-2), new ParserVal(-1), new ParserVal(-1));//-2 es BI
	tercetos.get(tercetos.size()-1).setEtiqueta();
	pila.push(refTerceto);
	$$ = new ParserVal((double)refTerceto);
	}//Se modifica el BF, agregandole la referencia correspondiente al proximo terceto despues del ELSE, se crea el terceto BI y se agrega a la pila la referencia al mismo
 ;

 condicional : if '(' condicion ')' THEN {
		 int refTerceto = crearTerceto(new ParserVal(-1), $3, new ParserVal(-1));//el primer-1 es BF
		 pila.push(refTerceto);
		 $$ = new ParserVal((double)refTerceto);
		 }// se agrega el terceto BF y su referencia a la pila

		 | if '(' error ')' THEN { pila.push(0); addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", condicion invalida"); }
		 | if '(' condicion THEN { pila.push(0); addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", falta parentesis de cierre"); }
		 | if condicion ')' THEN { pila.push(0); addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", falta parentesis de apertura"); }
		 | if '(' condicion ')' error ';'{ pila.push(0); addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", sentencia condicional invalida"); }
 ;

 if : IF {addEstructura( "Sentencia IF, en la linea: " + analizadorLexico.getNroLineaToken() );
 	  $$ = $1;}
 ;

 // condicion
 condicion : expresion_booleana operacion_booleana condicion{
	  	$$ = new ParserVal((double)crearTerceto($2, $1, $3));
	  	}
           | expresion_booleana {$$ = $1;}
 ;

 expresion_booleana : expresion_aritmetica comparador expresion_aritmetica{
 			if($1.sval!=$3.sval)
				addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", tipos incompatibles en la comparacion");
			$$ = new ParserVal((double)crearTerceto($2, $1, $3));
		}
 ;

 comparador : COMP_MAYOR_IGUAL {$$.ival = COMP_MAYOR_IGUAL;}
            | COMP_MENOR_IGUAL {$$.ival = COMP_MENOR_IGUAL;}
            | COMP_IGUAL {$$.ival = COMP_IGUAL;}
            | COMP_DISTINTO {$$.ival = COMP_DISTINTO;}
            | '<' {$$.ival = '<';}
            | '>' {$$.ival = '>';}
 ;

 operacion_booleana : AND {$$.ival = AND;}
                    | OR {$$.ival = OR;}
 ;


 bloque_ejecutable_condicional : BEGIN sentencias_ejecutables END
                               | sentencia_ejecutable
 ;

 // sentencia print
 sentencia_imprimir : print '(' CADENA ')' ';' {crearTerceto($1, $3, new ParserVal(-1));}      // PRINT(%...%);
 		    | print '(' error ')' ';'{ addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", cadena invalida"); }
 		    | print '(' CADENA ';'{ addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", falta parentesis de cierre"); }
 		    | print CADENA ')' ';'{ addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", falta parentesis de apertura"); }
 		    | print error ';'{ addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", sentencia PRINT invalida"); }
 ;

 print : PRINT {
 		addEstructura( "Sentencia PRINT, en la linea: " + analizadorLexico.getNroLineaToken() );
 		$$ = new ParserVal((int)PRINT);
 		}
 ;

// sentencia while
 sentencia_iterativa : iterativo bloque_ejecutable_iterativo{   // WHILE()DO BEGIN END

 	     while(tercetos.get(pila.peek()).getT2().ival==-2)//verifico si el bloque tiene break
		    tercetos.get(pila.pop()).setT2(new ParserVal((double)tercetos.size()+1));//Completo el BI del break

	     tercetos.get(pila.pop()).setT3(new ParserVal((double)tercetos.size()+1));//Completo el BF del while
	     crearTerceto(new ParserVal(-2), new ParserVal((double)pila.pop()), new ParserVal(-1));//-2 es BI
	     tercetos.get(tercetos.size()-1).setEtiqueta();
 }
 ;

 iterativo : while '(' condicion ')' DO {
					 int refTerceto = crearTerceto(new ParserVal(-1), $3, new ParserVal(-1));//el primer-1 es BF
					 pila.push(refTerceto);
					 $$ = new ParserVal((double)refTerceto);
					}// se agrega el terceto BF y su referencia a la pila

					| while '(' condicion ')' error { pila.push(0); addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", sentencia iterativa invalida"); }
					| while '(' error ')' DO { pila.push(0); addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", condicion invalida"); }
					| while '(' condicion DO { pila.push(0); addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", falta parentesis de cierre"); }
					| while condicion ')' DO { pila.push(0); addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", falta parentesis de apertura"); }
;

 while : WHILE { addEstructura( "Sentencia WHILE, en la linea: " + analizadorLexico.getNroLineaToken() );
 		 pila.push(tercetos.size());  // agrego el indice donde salta el terceto BI que voy a crear luego
 		 tercetos.get(tercetos.size()-1).setEtiqueta();
 	         $$=$1; }
 ;

 bloque_ejecutable_iterativo : BEGIN sentencias_ejecutables_iterativas END
 			     | sentencia_ejecutable_iterativa
 ;

 sentencias_ejecutables_iterativas : sentencia_ejecutable_iterativa sentencias_ejecutables_iterativas
                        | sentencia_ejecutable_iterativa
 ;

 sentencia_ejecutable_iterativa : sentencia_asignacion
                                | sentencia_condicional
                                | sentencia_imprimir
                                | sentencia_iterativa
                                | sentencia_try_catch
                                | sentencia_break
 ;

// sentencia break
 sentencia_break : BREAK ';'{
 			addEstructura( "Sentencia BREAK, en la linea: " + analizadorLexico.getNroLineaToken() );
 			int refTerceto =crearTerceto(new ParserVal(-2), new ParserVal(-2), new ParserVal(-1));//El primer -2 es BI, el segundo es para diferenciarlo de otros BI (luego se pisa por la dir a saltar)
			pila.push(refTerceto);
 }
 ;

// sentencia conversion
 sentencia_conversion : DOUBLE '(' expresion_aritmetica ')'{
 			 addEstructura( "Sentencia de conversion a DOUBLE, en la linea: " + analizadorLexico.getNroLineaToken() );
 			 // le asigno al NT sentencia_conversion (usando el atributo dval), la posicion (indice de la lista tercetos) del terceto correspondiente al terceto conversion
 			 $$ =  new ParserVal((double)crearTerceto(new ParserVal(DOUBLE), $3, new ParserVal(-1)));  // terceto que indica una conversion (DOUBLE) , con su valor a retornar en la segunda posicion , el tercer lugar queda nulo
 			 $$.sval = "DOUBLE";  // le asigno al NT sentencia_conversion (usando el atributo sval) , el valor DOUBLE correspondiente al tipo de la expresion
 			}
 		      | DOUBLE '(' error ')' { addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", expresion aritmetica invalida"); }
 ;

// sentencia try catch
 sentencia_try_catch : bifurcacion_try bloque_ejecutable{

 		      tercetos.get(tercetos.size()-1).setEtiqueta();
 		      tercetos.get(pila.pop()).setT3(new ParserVal((double)tercetos.size()));//Completa el BT del try
		     }
 ;

 bifurcacion_try : try sentencia_asignacion CATCH {
 		  //Primero buscamos el id de la funcion invocada en el try recorriendo la lista de tercetos
		  int i = tercetos.size()-1;
		  boolean noHayCallConPost = (tercetos.get(i).getT1().ival != CALL);
		  while( noHayCallConPost && (i > ultimoTry) ){
			i--;
			if(tercetos.get(i).getT1().ival == CALL)
				noHayCallConPost= (postCondiciones.get(tercetos.get(i).getT2().ival)==null);//si el call no tiene post condicion
		  }
		  //Verificamos que haya un llamado a funcion con postcondicion
		  if(noHayCallConPost){
			addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", no se invoca funcion con post condicion dentro del TRY");
			pila.push(crearTerceto(new ParserVal(-3), new ParserVal((double)0), new ParserVal(-1)));//el primer -3 es BT, el 2do parametro es erroneo
		  }else{
			pila.push(crearTerceto(new ParserVal(-3), new ParserVal((double)postCondiciones.get(tercetos.get(i).getT2().ival)), new ParserVal(-1)));//el primer -3 es BT, el 2do parametro hace referencia a la postcondicion de la funcion invocada
		  }
		 }
 		 | try sentencia_asignacion error { pila.push(0); addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", sentencia TRY-CATCH invalida"); }
  		 | try sentencia_asignacion { pila.push(0); addErrorSintactico("Linea " + analizadorLexico.getNroLineaToken() + ", sentencia TRY-CATCH invalida"); }
 ;

 try : TRY {
 	addEstructura( "Sentencia TRY-CATCH, en la linea: " + analizadorLexico.getNroLineaToken() );
 	ultimoTry = tercetos.size()-1;//Se guarda la referencia del ultimo tercetos antes del try
 }
 ;

// expresion aritmetica
 expresion_aritmetica : expresion_aritmetica '+' termino {
                              if($1.sval!=$3.sval)
				addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", tipos incompatibles " + $1.sval + " + " + $3.sval );
			      $$ = new ParserVal((double)crearTerceto(new ParserVal((int)'+'), $1, $3));
			      $$.sval=$1.sval;
 		      }
		      | expresion_aritmetica '-' termino{
				 if($1.sval!=$3.sval)
					addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", tipos incompatibles " + $1.sval + " - " + $3.sval );
				 $$ = new ParserVal((double)crearTerceto(new ParserVal((int)'-'), $1, $3));
				 $$.sval=$1.sval;
		      }
		      | termino { $$ = $1 ; }
 ;

 termino : termino '*' factor{
             if($1.sval!=$3.sval)
                   addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", tipos incompatibles " + $1.sval + " * " + $3.sval );
	     $$ = new ParserVal((double)crearTerceto(new ParserVal((int)'*'), $1, $3));
	     $$.sval=$1.sval;
	 }
         | termino '/' factor{
                if($1.sval!=$3.sval)
                     	addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", tipos incompatibles " + $1.sval + " / " + $3.sval );
		$$ = new ParserVal((double)crearTerceto(new ParserVal((int)'/'), $1, $3));
		$$.sval=$1.sval;
	 }
         | factor {$$ = $1;}
         | '-' factor {
		      $$ = new ParserVal((double)crearTerceto(new ParserVal((int)'*'), new ParserVal(-1), $2));
		      $$.sval=$1.sval;
	 }
 ;

 factor : ID {
       String auxiliar= ambitoActual;
       int ultimoPunto = 0;
       while( (!tablaSimbolo.existeToken(tablaSimbolo.obtenerToken($1.ival).getLexema()+'.'+auxiliar)) && (ultimoPunto>=0)){
		ultimoPunto = auxiliar.lastIndexOf('.');
		if(ultimoPunto>0)
			auxiliar = auxiliar.substring(0, ultimoPunto);
       }
       int nuevaRef = tablaSimbolo.obtenerReferenciaTabla(tablaSimbolo.obtenerToken($1.ival).getLexema()+'.'+auxiliar);

       if(nuevaRef == -1){ // si la variable no fue declarada
		addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", variable no declarada");
       }
       else{ // si la variable fue declarada
		tablaSimbolo.borrarToken($1.ival);//se borra de la tabla de simbolos la variable duplicada de la sentencia
		$1.ival=nuevaRef;//se le asigna la referencia a la variable original en la tabla

		Token tVariable = tablaSimbolo.obtenerToken($1.ival);
		if(tVariable.getUso()!="variable" && tVariable.getUso()!="parametro"){
			addErrorSemantico("Linea " + analizadorLexico.getNroLineaToken() + ", mal uso del identificador " + tVariable.getLexema());//este error puede llegar a borrarse si ocurre el unico caso en el que el identificador tiene un buen uso
			indiceErrorABorrar= this.erroresSemanticos.size()-1;//se usa para borrar el error en caso de que el uso sea correcto, es decir que se asigne correctamente a una variable de funcion designada
		}
       }
       $$ = $1;   // le asigno al NT Factor (usando el atributo ival) , la clave en tabla del simbolos que contiene el Token correspondiente al identificador (que posiblemente sea variable o parametro)
       $$.sval=tablaSimbolo.obtenerToken($1.ival).getTipo(); // le asigno al NT Factor (usando el atributo sval) , el valor correspondiente al tipo que posee el identificador
     }
        | sentencia_conversion {$$ = $1;}  	// le asigno al NT Factor (usando el atributo dval) , el valor de indice de la lista(tercetos) correspondiente al terceto conversion
        | sentencia_llamado_funcion {$$ = $1;}  //le asigno al NT Factor (usando el atributo dval) , el valor de indice de la lista(tercetos) correspondiente al terceto CALL
        | CTE_ULONG {  $$ = $1;            	// le asigno al NT Factor (usando el atributo ival) , la clave en tabla del simbolos que contiene el Token correspondiente a la constante
                       $$.sval="ULONG";}   	// le asigno al NT Factor (usando el atributo sval) , el valor ULONG correspondiente al tipo de la constante
        | CTE_DOUBLE {$$ = $1;		   	// le asigno al NT Factor (usando el atributo ival) , la clave en tabla del simbolos que contiene el Token correspondiente a la constante
                      $$.sval="DOUBLE";}   	// le asigno al NT Factor (usando el atributo sval) , el valor DOUBLE correspondiente al tipo de la constante
 ;

%%

///CODIGO JAVA

private AnalizadorLexico analizadorLexico;
private TablaSimbolo tablaSimbolo;
private ArrayList<String> estructuras = new ArrayList<String>(); //Lista de las estructuras detectadas por el parser
private ArrayList<String> erroresSintacticos = new ArrayList<String>(); //Lista de errores sintacticos detectados por el parser
private ArrayList<String> erroresSemanticos = new ArrayList<String>(); //Lista de errores semanticos detectados por el parser
private int indiceErrorABorrar;//entero utilizado para indicar un error a borrar que corresponde al mal uso de un identificador, en caso de que su uso sea correcto se borrara el error (esto solo sucede cuando se hace una asignacion de una un funcion a una variable de forma correcta)
private ArrayList<String> warnings = new ArrayList<String>(); //Lista de warnings detectados por el parser

private ArrayList<Terceto> tercetos = new ArrayList<Terceto>(); //Lista de tercetos generados
private Stack<Integer> pila = new Stack<Integer>(); //Pila utilizada para los tercetos

private HashMap<Integer, Integer> postCondiciones = new HashMap<Integer, Integer>();//Hashmap utilizado para guardar el id de las funciones junto a las referencias de sus postcondicion

private String ambitoActual;
private String tipoActual; //variable para saber el ultimo tipo leido
private String tipoActualdeFuncion; //Variable para saber el ultimo tipo de funcion leido

private int ultimoTry; //variable para saber cual es el ultimo terceto antes de un try, sirve por si no se encuentra ningun CALL dentro de un TRY

public void setAnalizadorLexico(AnalizadorLexico al){
	this.analizadorLexico = al;
	tablaSimbolo= analizadorLexico.getTablaSimbolo();
}

public int crearTerceto(ParserVal t1, ParserVal t2, ParserVal t3){
	tercetos.add( new Terceto(t1, t2, t3) );
	return tercetos.size()-1;
}

//Metodo usado por el Main para imprimir los tercetos
public void imprimirTercetos(){
	tablaSimbolo= analizadorLexico.getTablaSimbolo();
	int i = 0;
	for(Terceto t : tercetos){
		System.out.println("[" + i + "]" + t.getTerceto(tablaSimbolo));
		i++;
		if(t.getEtiqueta())
			System.out.println("ETIQUETA[" + i + "]");
	}
}

private void addEstructura(String e){
	estructuras.add(e);
}

//Metodo usado por el Main para imprimir las estructuras
public void imprimirEstructuras(){
	System.out.println("Cantidad de estructuras detectadas: " + estructuras.size());
	for(String e : estructuras)
		System.out.println(e);
}

private void addErrorSintactico(String e){
	erroresSintacticos.add(e);
}

private void addErrorSemantico(String e){
	erroresSemanticos.add(e);
}

private void addWarning(String w){
	warnings.add(w);
}

//Metodo usado por el Main para imprimir los erroresSintacticos lexicos
public void imprimirErroresSintacticos(){
        System.out.println("Se detectaron " + this.erroresSintacticos.size() + " errores sintacticos en el codigo");
        for(String e: this.erroresSintacticos){
            System.out.println(" - " + e);
        }
}

//Metodo usado por el Main para imprimir los erroresSemanticos lexicos
public void imprimirErroresSemanticos(){
        System.out.println("Se detectaron " + this.erroresSemanticos.size() + " errores semanticos en el codigo");
        for(String e: this.erroresSemanticos){
            System.out.println(" - " + e);
        }
}

//Metodo utilizado por el Main para imprimir los warnings semanticos detectados
public void imprimirWarningsSemanticos(){
	System.out.println("Se detectaron " + this.warnings.size() + " warnings semanticos en el codigo");
	for(String w: this.warnings){
	    System.out.println(" - " + w);
	}
}

public boolean hayError(){
	return ((this.erroresSintacticos.size()>0) || (this.erroresSemanticos.size()>0));
}

public ArrayList<Terceto> getTercetos(){
	return tercetos;
}

private int yylex(){
	Dupla<Integer, Integer> tokenActual = analizadorLexico.nextToken();
	if(tokenActual.getSegundo() != null)
		yylval = new ParserVal((int)tokenActual.getSegundo());
	return tokenActual.getPrimero();
}

private void yyerror(String s){

}