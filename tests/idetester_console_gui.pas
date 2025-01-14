unit idetester_console_gui;

{
This is adapted/modified from the base FPCUnit ConsoleTestRunner. The purpose
of the modifications is to give the host more control over how the the tests
are run - e.g. to fit in with a CI Build framework
}

{
Modifications (not many) are Copyright (c) 2011+, Health Intersections Pty Ltd (http://www.healthintersections.com.au)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 * Neither the name of HL7 nor the names of its contributors may be used to
   endorse or promote products derived from this software without specific
   prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 'AS IS' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
}

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, Contnrs, dateutils, dom,
  fpcunit, testutils, testregistry, testdecorator, 
  fpcunitreport, latextestreport, xmltestreport, plaintestreport,
  idetester_console, Forms;

type

  { TIdeTesterConsoleRunner }

  TIdeTesterConsoleRunner = class(TApplication)
  private
    FShowProgress: boolean;
    FFileName: string;
    FFormat: TFormat;
    FSkipTiming : Boolean;
    FSParse: Boolean;
    FSkipAddressInfo : Boolean;
    FSuite: String;
  protected
    procedure RunSuite; virtual;
    procedure ExtendXmlDocument(Doc: TXMLDocument); virtual;
    function GetResultsWriter: TCustomResultsWriter; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DoTestRun(ATest: TTest); virtual;

    property ShowProgress: boolean read FShowProgress write FShowProgress;
    property FileName: string read FFileName write FFileName;
    property Format: TFormat read FFormat write FFormat;
    property SkipTiming : Boolean read FSkipTiming write FSkipTiming;
    property Sparse: Boolean read FSparse write FSparse;
    property SkipAddressInfo : Boolean read FSkipAddressInfo write FSkipAddressInfo;
  end;


implementation

type
  TTestDecoratorClass = Class of TTestDecorator;

  { TDecoratorTestSuite }

  TDecoratorTestSuite = Class(TTestSuite)
  public
    Destructor Destroy; override;
  end;

  { TProgressWriter }

  TProgressWriter= class(TNoRefCountObject, ITestListener)
  private
    FTotal : Integer;
    FFailed: Integer;
    FIgnored : Integer;
    FErrors : Integer;
    FQuiet : Boolean;
    fcount : integer;
    FSuccess : Boolean;
    procedure WriteChar(c: char);
  public
    Constructor Create(AQuiet : Boolean);
    destructor Destroy; override;
    Function GetExitCode : Integer;
    { ITestListener interface requirements }
    procedure AddFailure(ATest: TTest; AFailure: TTestFailure);
    procedure AddError(ATest: TTest; AError: TTestFailure);
    procedure StartTest(ATest: TTest);
    procedure EndTest(ATest: TTest);
    procedure StartTestSuite(ATestSuite: TTestSuite);
    procedure EndTestSuite(ATestSuite: TTestSuite);
    Property Total : Integer Read FTotal;
    Property Failed : Integer Read FFailed;
    Property Errors : Integer Read FErrors;
    Property Ignored : Integer Read FIgnored;
    Property Quiet : Boolean Read FQuiet;
  end;

  { TDecoratorTestSuite }

  destructor TDecoratorTestSuite.Destroy;
  begin
    OwnsTests:=False;
    inherited Destroy;
  end;

  { TProgressWriter }

  procedure TProgressWriter.WriteChar(c: char);
  begin
    write(c);
    // flush output, so that we see the char immediately, even it is written to file
    Flush(output);
  end;

  constructor TProgressWriter.Create(AQuiet: Boolean);
  begin
    FQuiet:=AQuiet;
  end;

  destructor TProgressWriter.Destroy;
  begin
    // on descruction, just write the missing line ending
    writeln;
    inherited Destroy;
  end;

  function TProgressWriter.GetExitCode: Integer;

  begin
    Result:=Ord(Failed<>0); // Bit 0 indicates fails
    if Errors<>0 then
      Result:=Result or 2;  // Bit 1 indicates errors.
  end;

  procedure TProgressWriter.AddFailure(ATest: TTest; AFailure: TTestFailure);
  begin
    FSuccess:=False;
    If AFailure.IsIgnoredTest then
    begin
      Inc(FIgnored);
      If Not Quiet then
        writechar('I');
    end
    else
    begin
      Inc(FFailed);
      If Not Quiet then
        writechar('F');
    end;
  end;

  procedure TProgressWriter.AddError(ATest: TTest; AError: TTestFailure);
  begin
    FSuccess:=False;
    Inc(FErrors);
    if not Quiet then
      writechar('E');
  end;

  procedure TProgressWriter.StartTest(ATest: TTest);
  begin
  FSuccess := true; // assume success, until proven otherwise
  end;

  procedure TProgressWriter.EndTest(ATest: TTest);
  begin
  if FSuccess and not Quiet then
    writechar('.');
  end;

  procedure TProgressWriter.StartTestSuite(ATestSuite: TTestSuite);
  begin
  // do nothing
    inc(fcount);
  end;

  procedure TProgressWriter.EndTestSuite(ATestSuite: TTestSuite);
  begin
  // do nothing
    dec(fcount);
    if fCount = 0 then
    begin
      writeln('!');
      writeln;
    end;
  end;

{ TIdeTesterConsoleRunner }

constructor TIdeTesterConsoleRunner.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  StopOnException := True;
  FFormat := DefaultFormat;
end;

destructor TIdeTesterConsoleRunner.Destroy;
begin
  inherited Destroy;
end;

procedure TIdeTesterConsoleRunner.DoTestRun(ATest: TTest);
var
  ResultsWriter: TCustomResultsWriter;
  ProgressWriter: TProgressWriter;
  TestResult: TTestResult;

begin
  ProgressWriter:=Nil;
  ResultsWriter:=Nil;
  TestResult := TTestResult.Create;
  try
    ProgressWriter:=TProgressWriter.Create(Not ShowProgress);
    TestResult.AddListener(ProgressWriter);
    ResultsWriter:=GetResultsWriter;
    ResultsWriter.Filename := FileName;
    TestResult.AddListener(ResultsWriter);
    ATest.Run(TestResult);
    ResultsWriter.WriteResult(TestResult);
  finally
    if Assigned(ProgressWriter) then
      ExitCode:=ProgressWriter.GetExitCode;
    TestResult.Free;
    ResultsWriter.Free;
    ProgressWriter.Free;
  end;
end;


procedure TIdeTesterConsoleRunner.RunSuite;
var
  I,P : integer;
  S,TN : string;
  TS : TDecoratorTestSuite;
  T : TTest;
begin
  S := FSuite;
  if S = '' then
    for I := 0 to GetTestRegistry.ChildTestCount - 1 do
      writeln(GetTestRegistry[i].TestName)
  else
    begin
      TS:=TDecoratorTestSuite.Create('SuiteList');
      try
      while Not(S = '') Do
        begin
        P:=Pos(',',S);
        If P=0 then
          P:=Length(S)+1;
        TN:=Copy(S,1,P-1);
        Delete(S,1,P);
        if (TN<>'') then
          begin
          T:=GetTestRegistry.FindTest(TN);
          if Assigned(T) then
            TS.AddTest(T);
          end;
        end;
        if (TS.CountTestCases>1) then
          DoTestRun(TS)
        else if TS.CountTestCases=1 then
          DoTestRun(TS[0])
        else
          Writeln('No tests selected.');
      finally
        TS.Free;
      end;
    end;
end;

function TIdeTesterConsoleRunner.GetResultsWriter: TCustomResultsWriter;
begin
  case Format of
    fLatex:         Result := TLatexResultsWriter.Create(nil);
    fPlain:         Result := TPlainResultsWriter.Create(nil);
    fPlainNotiming: Result := TPlainResultsWriter.Create(nil);
    fSimple:        Result := TSimpleResultsWriter.Create(nil);
  else
    begin
      Result := TXmlResultsWriter.Create(nil);
      ExtendXmlDocument(TXMLResultsWriter(Result).Document);
    end;
  end;
  Result.SkipTiming:= FSkipTiming or (format=fPlainNoTiming);
  Result.Sparse:= FSparse;
  Result.SkipAddressInfo := FSkipAddressInfo;
end;


procedure TIdeTesterConsoleRunner.ExtendXmlDocument(Doc: TXMLDocument);
var
  n: TDOMElement;
begin
  n := Doc.CreateElement('Title');
  n.AppendChild(Doc.CreateTextNode(Title));
  Doc.FirstChild.AppendChild(n);
end;


end.

