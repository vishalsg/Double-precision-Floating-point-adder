
module fpadd(pushin,a,b,pushout,r);
input pushin;
input [63:0] a,b;	// the a and b inputs
output [63:0] r;	// the results from this multiply
output pushout;		// indicates we have an answer this cycle

parameter fbw=104;

reg sA,sB;		// the signs of the a and b inputs
reg [10:0] expA, expB,expR;		// the exponents of each
reg [fbw:0] fractA, fractB,fractR,fractAdd,fractPreRound,denormB,
	f2,d2;	
	// the fraction of A and B  present
reg zeroA,zeroB;	// a zero operand (special case for later)
	

reg signres;		// sign of the result
reg [10:0] expres;	// the exponent result
reg [63:0] resout;	// the output value from the always block
integer iea,ieb,ied;	// exponent stuff for difference...
integer renorm;		// How much to renormalize...
parameter [fbw:0] zero=0;
reg stopinside;

assign r=resout;
assign pushout=pushin;

always @(*) begin
  zeroA = (a[62:0]==0)?1:0;
  zeroB = (b[62:0]==0)?1:0;
  renorm=0;
  if( b[62:0] > a[62:0] ) begin
    expA = b[62:52];
    expB = a[62:52];
    sA = b[63];
    sB = a[63];
    fractA = (zeroB)?0:{ 2'b1, b[51:0],zero[fbw:54]};
    fractB = (zeroA)?0:{ 2'b1, a[51:0],zero[fbw:54]};
    signres=sA;
  end else begin
    sA = a[63];
    sB = b[63];
    expA = a[62:52];
    expB = b[62:52];
    fractA = (zeroA)?0:{ 2'b1, a[51:0],zero[fbw:54]};
    fractB = (zeroB)?0:{ 2'b1, b[51:0],zero[fbw:54]};
    signres=sA;
  end
  iea=expA;
  ieb=expB;
  ied=expA-expB;
  if(ied > 60) begin
    expR=expA;
    fractR=fractA;
  end else begin
    expR=expA;
    denormB=0;
    fractB=(ied[5])?{32'b0,fractB[fbw:32]}: {fractB};
    fractB=(ied[4])?{16'b0,fractB[fbw:16]}: {fractB};
    fractB=(ied[3])?{ 8'b0,fractB[fbw:8 ]}: {fractB};
    fractB=(ied[2])?{ 4'b0,fractB[fbw:4 ]}: {fractB};
    fractB=(ied[1])?{ 2'b0,fractB[fbw:2 ]}: {fractB};
    fractB=(ied[0])?{ 1'b0,fractB[fbw:1 ]}: {fractB};

    if(sA == sB) fractR=fractA+fractB; else fractR=fractA-fractB;
    fractAdd=fractR;
    renorm=0;
    if(fractR[fbw]) begin
      fractR={1'b0,fractR[fbw:1]};
      expR=expR+1;
    end
    if(fractR[fbw-1:fbw-32]==0) begin 
	renorm[5]=1; fractR={ 1'b0,fractR[fbw-33:0],32'b0 }; 
    end
    if(fractR[fbw-1:fbw-16]==0) begin 
	renorm[4]=1; fractR={ 1'b0,fractR[fbw-17:0],16'b0 }; 
    end
    if(fractR[fbw-1:fbw-8]==0) begin 
	renorm[3]=1; fractR={ 1'b0,fractR[fbw-9:0], 8'b0 }; 
    end
    if(fractR[fbw-1:fbw-4]==0) begin 
	renorm[2]=1; fractR={ 1'b0,fractR[fbw-5:0], 4'b0 }; 
    end
    if(fractR[fbw-1:fbw-2]==0) begin 
	renorm[1]=1; fractR={ 1'b0,fractR[fbw-3:0], 2'b0 }; 
    end
    if(fractR[fbw-1   ]==0) begin 
	renorm[0]=1; fractR={ 1'b0,fractR[fbw-2:0], 1'b0 }; 
    end
    fractPreRound=fractR;
    if(fractR != 0) begin
      if(fractR[fbw-55:0]==0 && fractR[fbw-54]==1) begin
	if(fractR[fbw-53]==1) fractR=fractR+{1'b1,zero[fbw-54:0]};
      end else begin
        if(fractR[fbw-54]==1) fractR=fractR+{1'b1,zero[fbw-54:0]};
      end
      expR=expR-renorm;
      if(fractR[fbw-1]==0) begin
       expR=expR+1;
       fractR={1'b0,fractR[fbw-1:1]};
      end
    end else begin
      expR=0;
      signres=0;
    end
  end

  resout={signres,expR,fractR[fbw-2:fbw-53]};

end

endmodule
