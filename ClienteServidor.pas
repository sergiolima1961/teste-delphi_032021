unit ClienteServidor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Datasnap.DBClient, Data.DB;

type
  TServidor = class
  private
    FPath: AnsiString;
  public
    constructor Create;
    // Tipo do parâmetro não pode ser alterado
    function SalvarArquivos(AData: OleVariant): Boolean;
  end;

  TfClienteServidor = class(TForm)
    ProgressBar: TProgressBar;
    btEnviarSemErros: TButton;
    btEnviarComErros: TButton;
    btEnviarParalelo: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btEnviarSemErrosClick(Sender: TObject);
    procedure btEnviarComErrosClick(Sender: TObject);
  private
    FPath: AnsiString;
    FServidor: TServidor;

    function InitDataset: TClientDataset;
  public
  end;

var
  fClienteServidor: TfClienteServidor;

const
  QTD_ARQUIVOS_ENVIAR = 100;

implementation

uses
  IOUtils;

{$R *.dfm}

procedure TfClienteServidor.btEnviarComErrosClick(Sender: TObject);
var
  cds: TClientDataset;
  i: Integer;
begin
  cds := InitDataset;
  for i := 0 to QTD_ARQUIVOS_ENVIAR do
  begin
    cds.Append;
    TBlobField(cds.FieldByName('Arquivo')).LoadFromFile(FPath);
    cds.Post;

{$REGION Simulação de erro, não alterar}
    if i = (QTD_ARQUIVOS_ENVIAR / 2) then
      FServidor.SalvarArquivos(NULL);
{$ENDREGION}
  end;

  FServidor.SalvarArquivos(cds.Data);
end;

procedure TfClienteServidor.btEnviarSemErrosClick(Sender: TObject);
var
  cds: TClientDataset;
  i: Integer;
  carga: TMemoryStream;
  Coluna: TBlobField;
  caminho, destino: string;

  procedure salva;
  begin

    caminho := destino + formatfloat('0##', i) + '.pdf';
    //
    if TFile.Exists(caminho) then
      TFile.Delete(caminho);
    //
    TBlobField(cds.FieldByName('Arquivo')).SaveToFile(caminho);

  end;

begin

  destino := ExtractFilePath(ParamStr(0)) + 'Servidor\';

  ProgressBar.Max := QTD_ARQUIVOS_ENVIAR;
  ProgressBar.Position := 0;
  Application.ProcessMessages;

  for i := 0 to QTD_ARQUIVOS_ENVIAR do
  begin
    try
      carga := TMemoryStream.Create;
      //
      carga.LoadFromFile(TFileName(FPath));
      //
      Coluna := TBlobField.Create(nil);
      //
      ProgressBar.Position := i;
      //
      cds := InitDataset;
      cds.Append;
      Coluna := cds.FieldByName('Arquivo') as TBlobField;
      Coluna.LoadFromStream(carga);
      cds.Post;
      //
      salva;
    finally
      //
      FreeAndNil(carga);
      FreeAndNil(cds);
    end;
  end;
  //
  ShowMessage(' Concluido Processado ' + IntToStr(ProgressBar.Position));
  ProgressBar.Position := 0;
end;

procedure TfClienteServidor.FormCreate(Sender: TObject);
begin
  inherited;
  FPath := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0))) + 'pdf.pdf';
  FServidor := TServidor.Create;
end;

function TfClienteServidor.InitDataset: TClientDataset;
begin
  Result := TClientDataset.Create(nil);
  Result.FieldDefs.Add('Arquivo', ftBlob);
  Result.CreateDataSet;
end;

{ TServidor }

constructor TServidor.Create;
begin
  FPath := ExtractFilePath(ParamStr(0)) + 'Servidor\';
end;

function TServidor.SalvarArquivos(AData: OleVariant): Boolean;
var
  cds: TClientDataset;
  FileName: string;
begin
  try
    cds := TClientDataset.Create(nil);
    cds.Data := AData;

{$REGION Simulação de erro, não alterar}
    if cds.RecordCount = 0 then
      Exit;
{$ENDREGION}
    cds.First;

    while not cds.Eof do
    begin
      FileName := FPath + cds.RecNo.ToString + '.pdf';
      if TFile.Exists(FileName) then
        TFile.Delete(FileName);

      TBlobField(cds.FieldByName('Arquivo')).SaveToFile(FileName);
      cds.Next;
    end;

    Result := True;
  except
    Result := false;
    raise;
  end;
end;

end.
