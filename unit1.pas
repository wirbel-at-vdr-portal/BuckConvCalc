unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    Edit10: TEdit;
    Edit11: TEdit;
    Edit12: TEdit;
    Edit13: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    Edit8: TEdit;
    Edit9: TEdit;
    Image1: TImage;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure Edit2Change(Sender: TObject);
    procedure Edit3Change(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

  Vin, Vout, Iout, Pout: double;
  fsw:double;
  Ioutmin:double;
  Vripple, Iripple:double;
  VF,VR,Irms,Iavg:double;
  RDSON,Vds,Ipeak:double;
  VRDSON:double;
  Pcond:double;
  dutycycle:double;
  period:double;
  ton:double;
  Lmin:double;
  Estored:double;
  Cout, Irmscout, Coutesr, Coutesrmax:double;
  Coutbank:double;
  VppCap,VppEsr,VppTotal: double;
  VrippleIn:double;
  Cin, Cinbank, CinEsr, CinEsrMax: double;
  VppCapIn,VppEsrIn,VppInTotal: double;
  Pin,EffMax,Pdiode,Pcin,Pcout:double;

implementation

{$R *.lfm}

function DblToStr(d: double):string;
begin
  result := FloatToStrF(d, ffFixed, 8, 3);
end;

function StrToDbl(s: string):double;
var
  comma,dot : TFormatSettings;
begin
  comma := FormatSettings;
  dot   := FormatSettings;

  comma.DecimalSeparator := ',';
  dot.DecimalSeparator := '.';

  if not TryStrToFloat(s, Result, comma) then
    Result := StrToFloat(s, dot);
end;

procedure TForm1.Edit1Change(Sender: TObject);
begin
  try
  Vripple:=StrToDbl(Edit1.Text) * 0.01;
  Edit8.Text:=FloatToStr(Vripple);
  finally
  end;
end;

procedure TForm1.Edit2Change(Sender: TObject);
begin
  try
  VrippleIn:=StrToDbl(Edit2.Text) * 0.05;
  Edit11.Text:=FloatToStr(VrippleIn);
  finally
  end;
end;

procedure TForm1.Edit3Change(Sender: TObject);
begin
  try
  Ioutmin:= StrToDbl(Edit3.Text) * 0.1;
  Edit7.Text:=FloatToStr(Ioutmin);
  finally
  end;
end;


procedure TForm1.Button1Click(Sender: TObject);
begin
  memo1.clear;
  memo1.Color := clDefault;
  try
  Vin := StrToDbl(Edit2.Text);
  Vout:= StrToDbl(Edit1.Text);
  Iout:= StrToDbl(Edit3.Text);
  Ioutmin:= StrToDbl(Edit7.Text);
  fsw:=StrToDbl(Edit4.Text);
  Vripple:=StrToDbl(Edit8.Text);
  VF:=StrToDbl(Edit5.Text);
  RDSON:=StrToDbl(Edit6.Text);
  Coutbank:=StrToDbl(Edit9.Text);
  Coutesr:=StrToDbl(Edit10.Text) / 1000;
  VrippleIn:=StrToDbl(Edit11.Text);
  Cinbank:=StrToDbl(Edit12.Text);
  CinEsr:=StrToDbl(Edit13.Text)/1000;

  Pout    := Vout * Iout;
  VRDSON  := RDSON * Iout;
  Iripple := Ioutmin * 2;
  Ipeak   := Ioutmin + Iout;
  Irms    := sqrt((Vout+VF)/(Vin-VRDSON)*(Ipeak*Ipeak-(Ipeak*Iripple)+(Iripple*Iripple)/3));
  Pcond   := RDSON * Irms * Irms;
  if (Vout >= Vin) then
     begin
     memo1.Lines.Add('Vout MUST be less than Vin.');
     memo1.Color := clRed;
     exit;
     end;

  if (Vout+VF >= Vin-VRDSON) then
     begin
     memo1.Lines.Add('The voltage drop across RDSON is too high.');
     memo1.Lines.Add('Select a MOSFET with lower RDSON.');
     memo1.Color := clRed;
     exit;
     end;

  if (Pcond >= 0.1*Pout) then
     begin
     memo1.Lines.Add('The conduction losses exceed 10% of output power.');
     memo1.Lines.Add('Select a MOSFET with lower RDSON');
     memo1.Color := clRed;
     exit;
     end;

  dutycycle := (Vout+VF)/(Vin-VRDSON);
  period    := 1e3/fsw;
  ton       := dutycycle * period;
  Lmin      := ((Vin - Vout - VRDSON)*ton)/Iripple;
  Estored   := Lmin * (Iout + Ioutmin)*(Iout + Ioutmin)/2;
  Iavg      := Iout * (1 - dutycycle);
  Vds       := (Vin + Vf) + 5.0;
  Irmscout  := Iripple/sqrt(12);
  Cout      := (Iripple * period) / (8*Vripple);
  VppCap    := (Iripple * period) / (8*Coutbank);
  VppEsr    := Iripple * Coutesr;
  VppTotal  := sqrt(VppCap*VppCap + VppEsr*VppEsr);
  Cin       := (Ipeak*period) / (8*VrippleIn);
  VppCapIn  := (Ipeak*period) / (8*Cinbank);
  VppEsrIn  := Ipeak * CinEsr;
  VppInTotal:= sqrt(VppCapIn*VppCapIn + VppEsrIn*VppEsrIn);
  Pdiode    := Iavg * VF;
  Pcin      := VppEsrIn * Ipeak;
  Pcout     := VppEsr * Iripple;
  Pin       := Pout + Pcond + Pdiode + Pcin + Pcout;
  EffMax    := Pout / Pin;


  if ((-(Iripple*Iripple)*(period*period))+(64*(Vripple  *Vripple  )*(Coutbank*Coutbank)))/(8*Coutbank*Iripple) < 0 then
     begin
     memo1.Lines.Add('The output capacitance is too low.');
     memo1.Lines.Add('Choose a larger output cap.');
     memo1.Color := clRed;
     exit;
     end;

  if ((-(Ipeak  *Ipeak  )*(period*period))+(64*(VrippleIn*VrippleIn)*(Cinbank *Cinbank )))/(8*Cinbank *Ipeak  ) < 0 then
     begin
     memo1.Lines.Add('The input capacitance is too low.');
     memo1.Lines.Add('Choose a larger input cap.');
     memo1.Color := clRed;
     exit;
     end;

  Coutesrmax := sqrt((-(Iripple*Iripple)*(period*period))+(64*(Vripple  *Vripple  )*(Coutbank*Coutbank)))/(8*Coutbank*Iripple);
  CinEsrMax  := sqrt((-(Ipeak  *Ipeak  )*(period*period))+(64*(VrippleIn*VrippleIn)*(Cinbank *Cinbank )))/(8*Cinbank *Ipeak  );


  if (Cout >= Coutbank) then
     begin
     memo1.Lines.Add('The output capacitance is too low.');
     memo1.Lines.Add('Choose a larger output cap.');
     memo1.Color := clRed;
     exit;
     end;

  if (Coutesr >= Coutesrmax) then
     begin
     memo1.Lines.Add('The output capacitance ESR is too high.');
     memo1.Lines.Add('Choose a output cap w. lower ESR or parallel caps.');
     memo1.Color := clRed;
     exit;
     end;

  if (Cin >= Cinbank) then
     begin
     memo1.Lines.Add('The input capacitance is too low.');
     memo1.Lines.Add('Choose a larger input cap.');
     memo1.Color := clRed;
     exit;
     end;


  if (Cinesr >= CinEsrMax) then
     begin
     memo1.Lines.Add('The input capacitance ESR is too high.');
     memo1.Lines.Add('Choose a input cap w. lower ESR or parallel caps.');
     memo1.Color := clRed;
     exit;
     end;





  memo1.Lines.Add('Output power of the converter: ' + DblToStr(Pout)    + ' W');
  memo1.Lines.Add('Voltage drop across RDSON    : ' + DblToStr(VRDSON)  + ' V');
  memo1.Lines.Add('Peak-to-peak ripple current  : ' + DblToStr(Iripple) + ' A');
  memo1.Lines.Add('Peak switch current          : ' + DblToStr(Ipeak)   + ' A');
  memo1.Lines.Add('RMS current                  : ' + DblToStr(Irms)    + ' A');
  memo1.Lines.Add('Conduction losses of switch  : ' + DblToStr(Pcond)   + ' W');
  memo1.Lines.Add('Duty cycle                   : ' + DblToStr(dutycycle*100) + ' %');
  memo1.Lines.Add('Switching period             : ' + DblToStr(period)  + ' µs');
  memo1.Lines.Add('On-time of the switch        : ' + DblToStr(ton)     + ' µs');
  memo1.Lines.Add('Minimum inductor value       : ' + DblToStr(Lmin)    + ' µH');
  memo1.Lines.Add('Inductor stored energy       : ' + DblToStr(Estored) + ' µJ');
  memo1.Lines.Add('Min Diode reverse voltage    : ' + DblToStr(Vin)     + ' V');
  memo1.Lines.Add('Min Diode average current    : ' + DblToStr(Iavg)    + ' A');
  memo1.Lines.Add('Diode power loss             : ' + DblToStr(Pdiode)  + ' W');
  memo1.Lines.Add('Min MOSFET VDS               : ' + DblToStr(Vds)     + ' V');
  memo1.Lines.Add('Cout Iripple                 : ' + DblToStr(Irmscout)+ ' A');
  if (Irmscout > 1) then
     begin
     memo1.Lines.Add('   HINT: choose a output cap which can handle this');
     memo1.Lines.Add('         ripple current, or, parallel multiple caps.');
     end;
  memo1.Lines.Add('Min output capacitance       : ' + DblToStr(Cout)    + ' µF');
  if (Coutbank/Cout < 5) then
     memo1.Lines.Add('   HINT: usually, we take a much larger/multiple caps here: 10x(+)');
  memo1.Lines.Add('Max output cap bank esr      : ' + DblToStr(1000*Coutesrmax) + ' mOhm');
  memo1.Lines.Add('Act output cap bank esr      : ' + DblToStr(1000*Coutesr) + ' mOhm');
  memo1.Lines.Add('Vripple due to Cout capacity : ' + DblToStr(VppCap) + ' V');
  memo1.Lines.Add('Vripple due to Cout esr      : ' + DblToStr(VppEsr) + ' V');
  memo1.Lines.Add('Vripple total                : ' + DblToStr(VppTotal) + ' V');
  if VppTotal > Vripple then
     begin
     memo1.Color := clYellow;
     memo1.Lines.Add('WARN: The output cap bank doesnt fit.');
     if (VppCap > VppEsr) then
        begin
        memo1.Lines.Add('The output capacitance value is too low.');
        memo1.Lines.Add('Increase the actual Cout capacity.');
        end
     else
        begin
        memo1.Lines.Add('The output capacitance ESR value is too high.');
        memo1.Lines.Add('Choose a cap with lower ESR, or, parallel multiple caps.');
        end;
     end;

  memo1.Lines.Add('Cin Iripple                  : ' + DblToStr(Irms)+ ' A');
  memo1.Lines.Add('Min input capacitance        : ' + DblToStr(Cin) + ' µF');
  memo1.Lines.Add('Min input capacitance esr    : ' + DblToStr(1000*CinEsrMax) + ' mOhm');
  memo1.Lines.Add('Act input cap bank esr       : ' + DblToStr(1000*Cinesr) + ' mOhm');
  memo1.Lines.Add('VrippleIn due to Cin capacity: ' + DblToStr(VppCapIn) + ' V');
  memo1.Lines.Add('VrippleIn due to Cin esr     : ' + DblToStr(VppEsrIn) + ' V');
  memo1.Lines.Add('VrippleIn total              : ' + DblToStr(VppInTotal) + ' V');

  memo1.Lines.Add('efficiency will be lower than: ' + DblToStr(EffMax*100) + ' %');

  finally
  end;
end;


end.

