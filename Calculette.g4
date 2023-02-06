grammar Calculette;

@parser::members {

    private TablesSymboles tablesSymboles = new TablesSymboles();

    private int _cur_label = 1;
    /** générateur de nom d'étiquettes pour les boucles */
    private String getNewLabel() { return "Label" +(_cur_label++); }

    /* private String continueLabel = null;
    private String breakLabel = null; */

    private String evalexpression (String x, String op, String y) {
        if ( op.equals("*") || op.equals("*-")){
            return x + y + "MUL\n" ;
        } else if ( op.equals("/") || op.equals("/-")){
            return x + y + "DIV\n" ;
        } else if ( op.equals("+") ){
            return x + y + "ADD\n" ;
        } else if ( op.equals("-") || (op.equals("+-")) || (op.equals("-+")) ){
            return x + y + "SUB\n" ;
        } else if ( op.equals("==") ){
            return x + y + "EQUAL\n" ;
        } else if ( op.equals("!=") || op.equals("<>")){
            return x + y + "NEQ\n" ;
        } else if ( op.equals(">") ){
            return x + y + "SUP\n" ;
        } else if ( op.equals(">=") ){
            return x + y + "SUPEQ\n" ;
        } else if ( op.equals("<") ){
            return x + y + "INF\n" ;
        } else if ( op.equals("<=") ){
            return x + y + "INFEQ\n" ;
        }else {
           System.err.println("Opérateur arithmétique incorrect : '"+op+"'");
           throw new IllegalArgumentException("Opérateur arithmétique incorrect : '"+op+"'");
        }
    }




}


start
    : calcul EOF;



    calcul returns [ String code ]
    @init{ $code = new String(); }   // On initialise code, pour ensuite l'utiliser comme accumulateur
    @after{ System.out.println($code); }
        :   (decl { $code += $decl.code; })*
            { $code += "  JUMP Main\n"; }
            NEWLINE*
            /* (fonction { $code += $fonction.code; })* */
            NEWLINE*
            { $code += "LABEL Main\n"; }
            (instruction { $code += $instruction.code; })*

            { $code += "  HALT\n"; }
        ;

    instruction returns [ String code ]
        : expression finInstruction
            {
              $code = $expression.code;
            }
        | assignation finInstruction
            {
    		      $code = $assignation.code;
            }
        | bloc finInstruction
            {
              $code = $bloc.code;
            }
        | boucle
            {
              $code = $boucle.code;
            }

        /* | condition finInstruction
            {
              $code = $condition.code;
            } */
        | branchement
            {
              $code = $branchement.code;
            }
        /* | BREAK finInstruction
            {
              $code = "JUMP " + breakLabel + "\n";
            }
        | CONTINUE finInstruction
            {
              $code = "JUMP " + continueLabel + "\n";
            } */
        | finInstruction
            {
              $code= "";
            }
        ;

    finInstruction : ( NEWLINE | ';' )+ ;

    expression returns [ String code, String type ]


            : '(' e=expression ')'
            {
              $code = $e.code;
              $type = $e.type;

            }
            | op=('+-'|'-+') e=expression
            {
              if(AdresseType.getSize($e.type) == 1){
                $code = evalexpression("PUSHI 0\n",$op.text,$e.code);

              }else{
                $code = evalexpression("PUSHF 0.0\n",$op.text,$e.code);
              }


            }
            | op=('+'|'-') e=expression
            {
              //System.out.println("hh"+$op.text)
              if(AdresseType.getSize($e.type) == 1){
                $code = evalexpression("PUSHI 0\n",$op.text,$e.code);
              }else{
                $code = evalexpression("PUSHF 0.0\n",$op.text,$e.code);
              }


            }

            | a=expression op=('*'|'/'|'/-'|'*-') b=expression
            {
              if($a.type.equals($b.type)){
                $code = evalexpression($a.code,$op.text,$b.code);
                $type = $a.type;
              }else{
                System.err.println("types incompatibles");
              }
              //System.out.println($code);
            }
            | a=expression op=('+'|'-'|'-+'|'+-') b=expression
            {
              if($a.type.equals($b.type)){
                $code = evalexpression($a.code,$op.text,$b.code);
                $type = $a.type;
              }else{
                System.err.println("types incompatibles");
              }
              //System.out.println($code);
            }
            | ENTIER
            {
              $code = "PUSHI " + $ENTIER.text + "\n";
              $type = "int";
              //System.out.println($code);
            }
            | DOUBLE
            {
              $code = "PUSHF " + $DOUBLE.text + "\n";
              $type = "double";
              //System.out.println($code);
            }
            | IDENTIFIANT
            {
            	AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);
            	$code = "PUSHG "+ at.adresse + "\n";
              $type = at.type;

              if( at.type.equals("double") ){
            		$code += "PUSHG "+ (at.adresse + 1) + "\n";
          		}

            }
            /* | IDENTIFIANT '(' args ')'                  // appel de fonction
            {

            } */
            ;



    decl returns [ String code ]
    :
        'var' IDENTIFIANT ':' TYPE finInstruction
        {
          if($TYPE.text.equals("int")){

            $code = "PUSHI 0 \n";

          }else if($TYPE.text.equals("double")){

            $code = "PUSHF 0.0 \n";

          }

          tablesSymboles.putVar($IDENTIFIANT.text,$TYPE.text);

        }
        | 'var' IDENTIFIANT ':' TYPE  '=' expression finInstruction
        {
          if($TYPE.text.equals($expression.type) == false ){

        		System.err.println("types incompatibles");

        	}else{

        		tablesSymboles.putVar($IDENTIFIANT.text,$TYPE.text);

        		AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);

        		if($TYPE.text.equals("int")){

        		  $code = "PUSHI 0 \n" + $expression.code + "STOREG " + at.adresse + "\n";

            }else if($TYPE.text.equals("double")){

              $code = "PUSHF 0.0 \n" + $expression.code + "STOREG " + at.adresse + "\n"+ "STOREG "+ (at.adresse + 1) + "\n";

            }

          }

        }

    ;

    assignation returns [ String code ]
        : IDENTIFIANT '=' expression
            {
                AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);

                if( at.type.equals($expression.type)){

                	$code = $expression.code + "STOREG " + at.adresse + "\n";

                }else{

                	System.err.println("types incompatibles");

                }

            }

        | IDENTIFIANT '+=' e=expression
            {

              AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);

              if( at.type.equals($expression.type)){

                $code =  "PUSHG "+ at.adresse + "\n" + $expression.code + "ADD\n" + "STOREG " + at.adresse + "\n";

              }else{

                System.err.println("types incompatibles");

              }

            }

        | READ '(' IDENTIFIANT ')'
            {

              AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);

              if(at.type.equals("int")){

            		$code = "READ \n" + "STOREG " + at.adresse + "\n";

            	}else if(at.type.equals("double")){

            		$code = "READF \n" +  "STOREG " + (at.adresse+1) + "\n" + "STOREG "+ at.adresse+ "\n";

              }

            }

        | WRITE '(' expression ')'
            {

              if($expression.type.equals("int")){

        				$code = $expression.code + "WRITE\n" + "POP\n";

              }else if($expression.type.equals("double")){

                $code = $expression.code + "WRITEF\n" + "POP\n" + "POP\n";

              }


            }
        ;


    bloc returns [String code]
    @init{ $code = new String(); }
       : '{' (instruction { $code += $instruction.code; })* '}' NEWLINE*
       ;

    condition returns [String code]
       : 'true'
       {
         $code = "PUSHI 1\n";
       }
       | 'false'
       {
         $code = "PUSHI 0\n";
       }
       | e1=expression op=('=='|'!='|'<>'|'>'|'>='|'<'|'<=') e2=expression
       {
         $code = evalexpression($e1.code,$op.text,$e2.code);
       }
       | '!' c=condition
       {
         $code = $c.code + "PUSHI 0\n" + "EQUAL\n";
       }
       | c1=condition '&&' c2=condition
       {
         $code  = $c1.code + $c2.code + "MUL\n";
       }
       | c1=condition '||' c2=condition
       {
         $code = $c1.code + $c2.code + "ADD\n";
       }
       ;

     boucle returns [String code]
       :
          'while' '(' c=condition ')' i=instruction
         {
           String startWhile = getNewLabel();
           String endWhile = getNewLabel();

           /* continueLabel = startWhile;
           breakLabel = endWhile; */

           $code = "LABEL " + startWhile + "\n" + $c.code + "JUMPF " + endWhile + "\n" + $i.code + "JUMP " + startWhile + "\n" + "LABEL " + endWhile + "\n";
         }
         | 'for' '(' a1=assignation ';' c=condition ';' a2=assignation ')' i=instruction
         {
           String startFor = getNewLabel();
           String endFor = getNewLabel();

           /* continueLabel = startFor;
           breakLabel = endFor; */

           $code = $a1.code + "LABEL " + startFor + "\n" + $c.code + "JUMPF " + endFor + "\n" + $i.code + $a2.code + "JUMP " + startFor + "\n" + "LABEL " + endFor + "\n";
         }
         | 'repeat' i=instruction 'until' '(' c=condition ')'
         {


           String startUntil = getNewLabel();

           $code = "LABEL " + startUntil + "\n" + $i.code + $c.code + "JUMPF " + startUntil + "\n";
         }
       ;

    branchement returns [String code]
       :'if' '(' c=condition ')' i=instruction
       {
         String labelName = getNewLabel();
         $code = $c.code + "JUMPF " + labelName + "\n" + $i.code + "LABEL "+ labelName + "\n";
       }
       |'if' '(' c=condition ')' a=instruction 'else' b=instruction
       {
         String labelElse = getNewLabel();
         String labelEnd = getNewLabel();
         $code = $c.code + "JUMPF " + labelElse + "\n" + $a.code + "JUMP " + labelEnd + "\n" +  "LABEL "+ labelElse + "\n" + $b.code + "LABEL "+ labelEnd + "\n";
       }
       ;

    /* fonction returns [ String code ]
     @init{  tablesSymboles.newTableLocale(); } // instancier la table locale
     @after{ tablesSymboles.dropTableLocale(); } // détruire la table locale
            : 'fun' IDENTIFIANT ':' TYPE
                {
                    //  truc à faire par rapport au "type" de la fonction et code pour la "variable" de retour
                    if ($TYPE.equals("int")){
                        $code = "PUSHI 0";
                    }else if($TYPE.equals("double")){
                        $code = "PUSHF 0.0";
                    }
        	      }
                '('  params ? ')' bloc
                {
                    // corps de la fonction
                    $code += $bloc.code;
                }
            ;


        params
            : TYPE IDENTIFIANT
                {
                    // code java gérant une variable locale (arg0)
                    tablesSymboles.putVar($IDENTIFIANT.text,$TYPE.text);
                }
                ( ',' TYPE IDENTIFIANT
                    {
                        // code java gérant une variable locale (argi)
                        tablesSymboles.putVar($IDENTIFIANT.text,$TYPE.text);
                    }
                )*
            ;

         // init nécessaire à cause du ? final et donc args peut être vide (mais $args sera non null)
        args returns [ String code, int size] @init{ $code = new String(); $size = 0; }
            : ( expression
            {
                // code java pour première expression pour arg
                $code .= $expression.code;
                $size += 1;
            }
            ( ',' expression
            {
                // code java pour expression suivante pour arg
                $code .= $expression.code;
                $size += 1;
            }
            )*
              )?
            ;

        expr returns [ String code, String type ]
            :
            //...
            | IDENTIFIANT '(' args ')'                  // appel de fonction
                {

                }

            ;
 */




// lexer


NEWLINE : '\r'? '\n';

WS :   (' '|'\t')+ -> skip  ;

ENTIER : ('0'..'9')+  ;

DOUBLE : ('0'..'9')+'.'('0'..'9')+;

COMMENTAIRE : ('%'~('\n')* | '/*'.*?'*/') -> skip ;

TYPE : 'int' | 'double' ;

READ : 'read' ;

WRITE : 'write';

BREAK: 'break';

CONTINUE: 'continue';

IDENTIFIANT : ('a'..'z'|'A'..'Z')('a'..'z'|'A'..'Z'|'0'..'9')*;
