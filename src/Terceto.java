public class Terceto {

    //terminos del terceto
    private ParserVal t1 ;
    private ParserVal t2 ;
    private ParserVal t3 ;

    private boolean etiqueta; //indica si luego del terceto viene una etiqueta o no
    private String auxiliar; //nombre de la variable auxiliar que le asigna el ensamblador

    public Terceto (ParserVal t1 , ParserVal t2 , ParserVal t3){
        this.t1 = t1;
        this.t2 = t2;
        this.t3 = t3;
        this.etiqueta= false;
    }

    public ParserVal getT1(){
        return this.t1;
    }

    public ParserVal getT2(){
        return this.t2;
    }

    public ParserVal getT3(){
        return this.t3;
    }

    public void setT2(ParserVal t2) {
        this.t2 = t2;
    }

    public void setT3(ParserVal t3) {
        this.t3 = t3;
    }

    public String getTerceto(TablaSimbolo ts){
        String stringT1= ts.obtenerValor(this.t1.ival);
        String stringT2= ts.obtenerValor(this.t2.ival);
        String stringT3= ts.obtenerValor(this.t3.ival);

        if(t1.ival==-1)
            stringT1= "BF";
        if(t1.ival==-2)
            stringT1="BI";
        if(t1.ival==-3)
            stringT1="BT";
        if(t1.ival==-4)
            stringT1="ENDFUNC";

        if(t2.ival==0) {
            stringT2 = String.valueOf(this.t2.dval);
            stringT2 = '['+stringT2.substring(0, stringT2.length()-2)+']';
            if(t1.ival==-2)//BI
                stringT2 = "ETIQUETA"+ stringT2;
        }

        if(t3.ival==0) {
            stringT3 = String.valueOf(this.t3.dval);
            stringT3 = '['+stringT3.substring(0, stringT3.length()-2)+']';
            if((t1.ival==-1) || (t1.ival==-3))//BF o BT
                stringT3 = "ETIQUETA"+ stringT3;
        }

        return "( "+ stringT1 + ", " + stringT2 + ", " + stringT3 + ")";
    }

    public boolean getEtiqueta() {
        return etiqueta;
    }

    public void setEtiqueta() {
        this.etiqueta = true;
    }

    public String getAuxiliar() {
        return auxiliar;
    }

    public void setAuxiliar(String auxiliar) {
        this.auxiliar = auxiliar;
    }
}