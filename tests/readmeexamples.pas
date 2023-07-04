unit ReadmeExamples;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, commontestbase, SynCommons, SynMustache;

type

  { TReadmeExamples }

  TReadmeExamples = class(TCommonTestSuite)
  private
    mustache: TSynMustache;
  public
    constructor Create; override;
    procedure SetUp; override;
    procedure SetUpEach; override;
    procedure TearDownEach; override;
    procedure TearDown; override;
  end;

  { TReadmeExampleHelloName }

  TReadmeExampleHelloName = class(TCommonTestSuiteCase)
  public
    procedure TestCase(name : String); override;
  end;

  { TReadmeExampleHelloNameRenderJson }

  TReadmeExampleHelloNameRenderJson = class(TCommonTestSuiteCase)
  public
    procedure TestCase(name : String); override;
  end;

  { TReadmeExampleHelloNameRenderJsonWithVariables }

  TReadmeExampleHelloNameRenderJsonWithVariables = class(TCommonTestSuiteCase)
  public
    procedure TestCase(name : String); override;
  end;

  { TReadmeExampleSections }

  TReadmeExampleSections = class(TCommonTestSuiteCase)
  public
    procedure TestCase(name : String); override;
  end;

var
  ReadmeExamplesTest: TReadmeExamples;

procedure RegisterTests;

implementation

uses
  testregistry;

procedure RegisterTests;
begin
  ReadmeExamplesTest := TReadmeExamples.Create;
  RegisterTest('Test examples from README', ReadmeExamplesTest);
end;

{ TReadmeExampleSections }

procedure TReadmeExampleSections.TestCase(name: String);
begin
  ReadmeExamplesTest.mustache := TSynMustache.Parse('Shown.{{#person}}As {{name}}!{{/person}}end{{name}}');
  AssertEquals('it should render the template with the data',
    'Shown.As toto!end',
    ReadmeExamplesTest.mustache.RenderJSON('{person:{age:?,name:?}}',[],[10,'toto'])
  );
end;

{ TReadmeExampleHelloNameRenderJsonWithVariables }

procedure TReadmeExampleHelloNameRenderJsonWithVariables.TestCase(name: String);
begin
  ReadmeExamplesTest.mustache := TSynMustache.Parse(
    'Hello {{name}}'#13#10+
    'You have just won {{value}} dollars!'
  );
  AssertEquals('it should render the template with the data',
    'Hello Chris'#13#10'You have just won 10000 dollars!',
    ReadmeExamplesTest.mustache.RenderJSON('{name:?,value:?}',[],['Chris',10000])
  );
end;

{ TReadmeExampleHelloNameRenderJson }

procedure TReadmeExampleHelloNameRenderJson.TestCase(name: String);
begin
  ReadmeExamplesTest.mustache := TSynMustache.Parse(
    'Hello {{value.name}}'#13#10+
    'You have just won {{value.value}} dollars!'
  );
  AssertEquals('it should render the template with the data',
    'Hello Chris'#13#10'You have just won 10000 dollars!',
    ReadmeExamplesTest.mustache.RenderJSON('{value:{name:"Chris",value:10000}}')
  );
end;

{ TReadmeExampleHelloName }

procedure TReadmeExampleHelloName.TestCase(name: String);
var
  input: Variant;
begin
  ReadmeExamplesTest.mustache := TSynMustache.Parse(
    'Hello {{name}}'#13#10+
    'You have just won {{value}} dollars!'
  );
  input := _ObjFast(['name','Chris','value',10000]);
  AssertEquals('it should render the template with the data',
    'Hello Chris'#13#10'You have just won 10000 dollars!',
    ReadmeExamplesTest.mustache.Render(input)
  );
end;

{ TReadmeExamples }

constructor TReadmeExamples.Create;
begin
  inherited Create;
  AddTest(TReadmeExampleHelloName.Create('Hello {name}'));
  AddTest(TReadmeExampleHelloNameRenderJson.Create('Hello {name} (render JSON)'));
  AddTest(TReadmeExampleHelloNameRenderJsonWithVariables.Create('Hello {name} (render JSON with variables)'));
  AddTest(TReadmeExampleSections.Create('Sections are handled as expected'));
end;

procedure TReadmeExamples.SetUp;
begin
  inherited SetUp;
end;

procedure TReadmeExamples.SetUpEach;
begin
  inherited SetUpEach;
end;

procedure TReadmeExamples.TearDownEach;
begin
  inherited TearDownEach;
end;

procedure TReadmeExamples.TearDown;
begin
  inherited TearDown;
end;

end.

