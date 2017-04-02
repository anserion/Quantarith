unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls;

type
  tbit=(zero,one);
  tbit_vector=array of tbit;
  tbit_table=array of tbit_vector;

  { TForm1 }

  TForm1 = class(TForm)
    Button_exit: TButton;
    CheckGroupA: TCheckGroup;
    CheckGroupAminusB: TCheckGroup;
    CheckGroupAmultB: TCheckGroup;
    CheckGroupAdivB: TCheckGroup;
    CheckGroupAmodB: TCheckGroup;
    CheckGroupB: TCheckGroup;
    CheckGroupAplusB: TCheckGroup;
    Memo_help: TMemo;
    procedure Button_exitClick(Sender: TObject);
    procedure CheckGroupAItemClick(Sender: TObject; Index: integer);
    procedure CheckGroupBItemClick(Sender: TObject; Index: integer);
  private
    { private declarations }
  public
    { public declarations }
    procedure calc_a_oper_b;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

//=====================================================================
//toffoli quantum gate
//=====================================================================
procedure CCNOT_gate(x1,x2,x3:tbit; var y1,y2,y3:tbit);
begin
if (x1=zero)and(x2=zero)and(x3=zero) then begin y1:=zero; y2:=zero; y3:=zero; end;
if (x1=zero)and(x2=zero)and(x3=one) then begin y1:=zero; y2:=zero; y3:=one; end;
if (x1=zero)and(x2=one)and(x3=zero) then begin y1:=zero; y2:=one; y3:=zero; end;
if (x1=zero)and(x2=one)and(x3=one) then begin y1:=zero; y2:=one; y3:=one; end;
if (x1=one)and(x2=zero)and(x3=zero) then begin y1:=one; y2:=zero; y3:=zero; end;
if (x1=one)and(x2=zero)and(x3=one) then begin y1:=one; y2:=zero; y3:=one; end;
if (x1=one)and(x2=one)and(x3=zero) then begin y1:=one; y2:=one; y3:=one; end;
if (x1=one)and(x2=one)and(x3=one) then begin y1:=one; y2:=one; y3:=zero; end;
end;

function q_not(op1:tbit):tbit;
var g1,g2:tbit;
begin
CCNOT_gate(one,one,op1,g1,g2,q_not);
end;

function q_and(op1,op2:tbit):tbit;
var g1,g2:tbit;
begin
CCNOT_gate(op1,op2,zero,g1,g2,q_and);
end;

function q_xor(op1,op2:tbit):tbit;
var g1,g2:tbit;
begin
CCNOT_gate(op1,one,op2,g1,g2,q_xor);
end;

function q_nand(op1,op2:tbit):tbit;
var g1,g2:tbit;
begin
CCNOT_gate(op1,op2,one,g1,g2,q_nand);
end;

function q_or(op1,op2:tbit):tbit;
begin q_or:=q_nand(q_not(op1),q_not(op2)); end;

//bits cutter
function bin_cut_bits(start_pos,end_pos:integer; var x:tbit_vector):tbit_vector;
var tmp:tbit_vector; i:integer;
begin
   setlength(tmp,end_pos-start_pos+1);
   for i:=start_pos to end_pos do tmp[i-start_pos]:=x[i];
   bin_cut_bits:=tmp;
end;

//bits setter
procedure bin_ins_bits(start_pos,end_pos:integer; var src,dst:tbit_vector);
var i:integer;
begin for i:=start_pos to end_pos do dst[i]:=src[i-start_pos]; end;

procedure bin_set_bits(start_pos,end_pos:integer; value:tbit; var x:tbit_vector);
var i:integer;
begin for i:=start_pos to end_pos do x[i]:=value; end;

{half-adder}
procedure bin_half_adder(a,b:tbit; var s,c:tbit);
begin
    c:=q_and(a,b);
    s:=q_xor(a,b);
end;

{full-adder}
procedure bin_full_adder(a,b,c_in:tbit; var s,c_out:tbit);
var s1,p1,p2:tbit;
begin
    bin_half_adder(a,b,s1,p1);
    bin_half_adder(s1,c_in,s,p2);
    c_out:=q_or(p1,p2);
end;

{n-bit adder}
procedure quantum_adder(a,b:tbit_vector; var s:tbit_vector);
var i,n:integer; c:tbit_vector;
begin
n:=length(a); setlength(c,n+1);
c[0]:=zero;
for i:=0 to n-1 do bin_full_adder(a[i],b[i],c[i],s[i],c[i+1]);
setlength(c,0);
end;

{n-bit subtractor}
procedure quantum_subtractor(a,b:tbit_vector; var s:tbit_vector);
var i,n:integer; c:tbit_vector;
begin
n:=length(a); setlength(c,n+1);
c[0]:=one;
for i:=0 to n-1 do bin_full_adder(a[i],q_not(b[i]),c[i],s[i],c[i+1]);
setlength(c,0);
end;

{n-bit multiplier}
procedure quantum_multiplier(a,b:tbit_vector; var s:tbit_vector);
var i,n:integer;
    tmp_sum,tmp_op1:tbit_table;
begin
n:=length(a);
setlength(tmp_op1,n); for i:=0 to n-1 do setlength(tmp_op1[i],n);
setlength(tmp_sum,n+1); for i:=0 to n do setlength(tmp_sum[i],n+1);
for i:=0 to n-1 do tmp_sum[0,i]:=zero;
for i:=0 to n-1 do
begin
    if b[i]=one then
    begin
       bin_set_bits(0,i-1,zero,tmp_op1[i]);
       bin_ins_bits(i,n-1,a,tmp_op1[i]);
    end
    else bin_set_bits(0,n-1,zero,tmp_op1[i]);
    quantum_adder(tmp_op1[i],tmp_sum[i],tmp_sum[i+1]);
end;
bin_ins_bits(0,n-1,tmp_sum[n],s);
for i:=0 to n-1 do setlength(tmp_op1[i],0); setlength(tmp_op1,0);
for i:=0 to n do setlength(tmp_sum[i],0); setlength(tmp_sum,0);
end;

{n-bit equal compare}
procedure bin_is_equal(a,b:tbit_vector; var res:tbit);
var res_tmp:tbit_vector; i,n:integer;
begin
   n:=length(a); setlength(res_tmp,n+1);
   res_tmp[0]:=zero;
   for i:=0 to n-1 do res_tmp[i+1]:=q_or(res_tmp[i],q_xor(a[i],b[i]));
   res:=q_not(res_tmp[n]);
   setlength(res_tmp,0);
end;

{n-bit greater compare. if a>b then res:=1}
procedure bin_is_greater_than(a,b:tbit_vector; var res:tbit);
var tmp_res,tmp_carry,tmp_cmp,tmp_equ:tbit_vector;
   i,n:integer;
begin
   n:=length(a);
   setlength(tmp_res,n+1); setlength(tmp_carry,n+1);
   setlength(tmp_cmp,n); setlength(tmp_equ,n);

   tmp_res[n]:=zero;
   tmp_carry[n]:=one;
   for i:=n-1 downto 0 do
   begin
      tmp_cmp[i]:=q_and(a[i],q_not(b[i]));
      tmp_equ[i]:=q_not(q_xor(a[i],b[i]));
      tmp_carry[i]:=q_and(tmp_carry[i+1],tmp_equ[i]);
      tmp_res[i]:=q_or(tmp_res[i+1],q_and(tmp_carry[i+1],tmp_cmp[i]));
   end;

   res:=tmp_res[0];
   setlength(tmp_res,0); setlength(tmp_carry,0);
   setlength(tmp_cmp,0); setlength(tmp_equ,0);
end;

{n-bit divider}
procedure quantum_divider(a,b:tbit_vector; var q,r:tbit_vector);
var tmp_q,tmp_equal,tmp_greater: tbit_vector;
   tmp_r,tmp_b: tbit_table;
   i,n:integer;
begin
n:=length(a);
setlength(tmp_q,n); setlength(tmp_equal,n); setlength(tmp_greater,n);
setlength(tmp_r,n+1); setlength(tmp_b,n+1);
for i:=0 to n do
begin
   setlength(tmp_r[i],2*n-1);
   setlength(tmp_b[i],2*n-1);
end;

bin_set_bits(n,2*n-1,zero,tmp_r[0]);
bin_ins_bits(0,n-1,a,tmp_r[0]);
for i:=0 to n-1 do
begin
  bin_is_greater_than(bin_cut_bits(n-i-1,n+n-i-2,tmp_r[i]),b,tmp_greater[n-i-1]);
  bin_is_equal(bin_cut_bits(n-i-1,n+n-i-2,tmp_r[i]),b,tmp_equal[n-i-1]);
  tmp_q[n-i-1]:=q_or(tmp_greater[n-i-1],tmp_equal[n-i-1]);
  bin_set_bits(n+n-i-1,n+n-1,zero,tmp_b[i]);
  bin_set_bits(0,n-i-2,zero,tmp_b[i]);
  if tmp_q[n-i-1]=zero then bin_set_bits(n-i-1,n+n-i-2,zero,tmp_b[i])
                       else bin_ins_bits(n-i-1,n+n-i-2,b,tmp_b[i]);
  quantum_subtractor(tmp_r[i],tmp_b[i],tmp_r[i+1]);
end;

q:=tmp_q;
bin_ins_bits(0,n-1,tmp_r[n],r);
setlength(tmp_q,0); setlength(tmp_equal,0); setlength(tmp_greater,0);
for i:=0 to n do
begin
   setlength(tmp_r[i],0);
   setlength(tmp_b[i],0);
end;
setlength(tmp_r,0); setlength(tmp_b,0);
end;

//======================================================================

{ TForm1 }

procedure TForm1.calc_a_oper_b;
var n:integer;
    a,b,c,d:tbit_vector;
begin
//input data tuning
n:=8;
setlength(a,n); setlength(b,n); setlength(c,n); setlength(d,n);

//get input data
if CheckGroupA.Checked[7] then a[7]:=one else a[7]:=zero;
if CheckGroupA.Checked[6] then a[6]:=one else a[6]:=zero;
if CheckGroupA.Checked[5] then a[5]:=one else a[5]:=zero;
if CheckGroupA.Checked[4] then a[4]:=one else a[4]:=zero;
if CheckGroupA.Checked[3] then a[3]:=one else a[3]:=zero;
if CheckGroupA.Checked[2] then a[2]:=one else a[2]:=zero;
if CheckGroupA.Checked[1] then a[1]:=one else a[1]:=zero;
if CheckGroupA.Checked[0] then a[0]:=one else a[0]:=zero;

if CheckGroupB.Checked[7] then b[7]:=one else b[7]:=zero;
if CheckGroupB.Checked[6] then b[6]:=one else b[6]:=zero;
if CheckGroupB.Checked[5] then b[5]:=one else b[5]:=zero;
if CheckGroupB.Checked[4] then b[4]:=one else b[4]:=zero;
if CheckGroupB.Checked[3] then b[3]:=one else b[3]:=zero;
if CheckGroupB.Checked[2] then b[2]:=one else b[2]:=zero;
if CheckGroupB.Checked[1] then b[1]:=one else b[1]:=zero;
if CheckGroupB.Checked[0] then b[0]:=one else b[0]:=zero;

//summator work
quantum_adder(a,b,c);
//report
if c[7]=one then CheckGroupAplusB.Checked[7]:=true else CheckGroupAplusB.Checked[7]:=false;
if c[6]=one then CheckGroupAplusB.Checked[6]:=true else CheckGroupAplusB.Checked[6]:=false;
if c[5]=one then CheckGroupAplusB.Checked[5]:=true else CheckGroupAplusB.Checked[5]:=false;
if c[4]=one then CheckGroupAplusB.Checked[4]:=true else CheckGroupAplusB.Checked[4]:=false;
if c[3]=one then CheckGroupAplusB.Checked[3]:=true else CheckGroupAplusB.Checked[3]:=false;
if c[2]=one then CheckGroupAplusB.Checked[2]:=true else CheckGroupAplusB.Checked[2]:=false;
if c[1]=one then CheckGroupAplusB.Checked[1]:=true else CheckGroupAplusB.Checked[1]:=false;
if c[0]=one then CheckGroupAplusB.Checked[0]:=true else CheckGroupAplusB.Checked[0]:=false;

//subtractor work
quantum_subtractor(a,b,c);
//report
if c[7]=one then CheckGroupAminusB.Checked[7]:=true else CheckGroupAminusB.Checked[7]:=false;
if c[6]=one then CheckGroupAminusB.Checked[6]:=true else CheckGroupAminusB.Checked[6]:=false;
if c[5]=one then CheckGroupAminusB.Checked[5]:=true else CheckGroupAminusB.Checked[5]:=false;
if c[4]=one then CheckGroupAminusB.Checked[4]:=true else CheckGroupAminusB.Checked[4]:=false;
if c[3]=one then CheckGroupAminusB.Checked[3]:=true else CheckGroupAminusB.Checked[3]:=false;
if c[2]=one then CheckGroupAminusB.Checked[2]:=true else CheckGroupAminusB.Checked[2]:=false;
if c[1]=one then CheckGroupAminusB.Checked[1]:=true else CheckGroupAminusB.Checked[1]:=false;
if c[0]=one then CheckGroupAminusB.Checked[0]:=true else CheckGroupAminusB.Checked[0]:=false;

//multiplier work
quantum_multiplier(a,b,c);
//report
if c[7]=one then CheckGroupAmultB.Checked[7]:=true else CheckGroupAmultB.Checked[7]:=false;
if c[6]=one then CheckGroupAmultB.Checked[6]:=true else CheckGroupAmultB.Checked[6]:=false;
if c[5]=one then CheckGroupAmultB.Checked[5]:=true else CheckGroupAmultB.Checked[5]:=false;
if c[4]=one then CheckGroupAmultB.Checked[4]:=true else CheckGroupAmultB.Checked[4]:=false;
if c[3]=one then CheckGroupAmultB.Checked[3]:=true else CheckGroupAmultB.Checked[3]:=false;
if c[2]=one then CheckGroupAmultB.Checked[2]:=true else CheckGroupAmultB.Checked[2]:=false;
if c[1]=one then CheckGroupAmultB.Checked[1]:=true else CheckGroupAmultB.Checked[1]:=false;
if c[0]=one then CheckGroupAmultB.Checked[0]:=true else CheckGroupAmultB.Checked[0]:=false;

//divider work
quantum_divider(a,b,c,d);
//report
if c[7]=one then CheckGroupAdivB.Checked[7]:=true else CheckGroupAdivB.Checked[7]:=false;
if c[6]=one then CheckGroupAdivB.Checked[6]:=true else CheckGroupAdivB.Checked[6]:=false;
if c[5]=one then CheckGroupAdivB.Checked[5]:=true else CheckGroupAdivB.Checked[5]:=false;
if c[4]=one then CheckGroupAdivB.Checked[4]:=true else CheckGroupAdivB.Checked[4]:=false;
if c[3]=one then CheckGroupAdivB.Checked[3]:=true else CheckGroupAdivB.Checked[3]:=false;
if c[2]=one then CheckGroupAdivB.Checked[2]:=true else CheckGroupAdivB.Checked[2]:=false;
if c[1]=one then CheckGroupAdivB.Checked[1]:=true else CheckGroupAdivB.Checked[1]:=false;
if c[0]=one then CheckGroupAdivB.Checked[0]:=true else CheckGroupAdivB.Checked[0]:=false;

if d[7]=one then CheckGroupAmodB.Checked[7]:=true else CheckGroupAmodB.Checked[7]:=false;
if d[6]=one then CheckGroupAmodB.Checked[6]:=true else CheckGroupAmodB.Checked[6]:=false;
if d[5]=one then CheckGroupAmodB.Checked[5]:=true else CheckGroupAmodB.Checked[5]:=false;
if d[4]=one then CheckGroupAmodB.Checked[4]:=true else CheckGroupAmodB.Checked[4]:=false;
if d[3]=one then CheckGroupAmodB.Checked[3]:=true else CheckGroupAmodB.Checked[3]:=false;
if d[2]=one then CheckGroupAmodB.Checked[2]:=true else CheckGroupAmodB.Checked[2]:=false;
if d[1]=one then CheckGroupAmodB.Checked[1]:=true else CheckGroupAmodB.Checked[1]:=false;
if d[0]=one then CheckGroupAmodB.Checked[0]:=true else CheckGroupAmodB.Checked[0]:=false;

//clear memory
setlength(a,0); setlength(b,0); setlength(c,0); setlength(d,0);
end;

procedure TForm1.Button_exitClick(Sender: TObject);
begin
  close;
end;

procedure TForm1.CheckGroupAItemClick(Sender: TObject; Index: integer);
begin
  calc_a_oper_b;
end;

procedure TForm1.CheckGroupBItemClick(Sender: TObject; Index: integer);
begin
  calc_a_oper_b;
end;

end.

